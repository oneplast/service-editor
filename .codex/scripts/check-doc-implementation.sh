#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# shellcheck source=.codex/scripts/gate-common.sh
source .codex/scripts/gate-common.sh

change_kind=""
scope_file=""
followup_file=""
result_file=""
run_mode=false
dry_run=false

while [ $# -gt 0 ]; do
  case "$1" in
    --change-kind)
      change_kind="$2"
      shift 2
      ;;
    --scope-file)
      scope_file="$2"
      shift 2
      ;;
    --followup-file)
      followup_file="$2"
      shift 2
      ;;
    --result-file)
      result_file="$2"
      shift 2
      ;;
    --run)
      run_mode=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    *)
      printf '알 수 없는 옵션: %s\n' "$1" >&2
      exit 64
      ;;
  esac
done

changed_files=$(gate_load_changed_files "$scope_file") || exit $?
mapfile -t scope_paths < <(printf '%s\n' "$changed_files" | sed '/^$/d')
scope_fingerprint=$(gate_fingerprint_lines "${scope_paths[@]}")

has_changed() {
  local pattern=$1
  printf '%s\n' "$changed_files" | grep -E -q "$pattern"
}

resolve_followup_file() {
  if [ -n "$followup_file" ]; then
    printf '%s\n' "$followup_file"
  elif [ -n "$scope_file" ] && printf '%s' "$scope_file" | grep -Eq '^docs/followup/active/.*\.scope$'; then
    printf '%s\n' "${scope_file%.scope}.md"
  fi
}

resolve_verification_stage() {
  local resolved_followup
  resolved_followup=$(resolve_followup_file)
  if [ -n "$resolved_followup" ] && [ -f "$resolved_followup" ]; then
    sed -n 's/^- 검증 단계:[[:space:]]*//p' "$resolved_followup" | head -n 1 | tr -d '\r'
  fi
}

module_tasks=()
reasons=()
dependency_paths=()
dependency_patterns=()
require_check=false
full_test=false
excluded_boot_test='com.documents.api.resource.ResourceAccessAndLifecycleIntegrationTest'
boot_test_classes=(
  'com.documents.api.block.AdminBlockApiIntegrationTest'
  'com.documents.api.block.BlockAttachmentApiIntegrationTest'
  'com.documents.api.block.DocumentBlocksApiIntegrationTest'
  'com.documents.api.document.DocumentApiIntegrationTest'
  'com.documents.api.document.DocumentSnapshotApiIntegrationTest'
  'com.documents.api.editor.EditorOperationApiIntegrationTest'
  'com.documents.api.editor.EditorOperationConcurrencyIntegrationTest'
  'com.documents.boot.DocumentsOperationalConfigurationTest'
  'com.documents.boot.PersistenceSchemaIntegrationTest'
)

add_once() {
  local value=$1
  local array_name=$2
  local -n values_ref=$array_name
  local existing
  for existing in "${values_ref[@]:-}"; do
    if [ "$existing" = "$value" ]; then
      return
    fi
  done
  values_ref+=("$value")
}

add_matching_dependencies() {
  local pattern=$1
  local path
  while IFS= read -r path; do
    [ -n "$path" ] && add_once "$path" dependency_paths
  done < <(printf '%s\n' "$changed_files" | grep -E "$pattern" || true)
}

if has_changed '^documents-api/src/|^documents-api/build\.gradle$'; then
  require_check=true
  reasons+=('documents-api 코드 또는 빌드 변경')
  add_once ':documents-api:test' module_tasks
  add_once '^documents-api/src/|^documents-api/build\.gradle$' dependency_patterns
  add_matching_dependencies '^documents-api/src/|^documents-api/build\.gradle$'
fi
if has_changed '^documents-core/src/|^documents-core/build\.gradle$'; then
  require_check=true
  reasons+=('documents-core 코드 또는 빌드 변경')
  add_once ':documents-core:test' module_tasks
  add_once '^documents-core/src/|^documents-core/build\.gradle$' dependency_patterns
  add_matching_dependencies '^documents-core/src/|^documents-core/build\.gradle$'
fi
if has_changed '^documents-infrastructure/src/|^documents-infrastructure/build\.gradle$'; then
  require_check=true
  reasons+=('documents-infrastructure 코드 또는 빌드 변경')
  add_once ':documents-infrastructure:test' module_tasks
  add_once '^documents-infrastructure/src/|^documents-infrastructure/build\.gradle$' dependency_patterns
  add_matching_dependencies '^documents-infrastructure/src/|^documents-infrastructure/build\.gradle$'
fi
if has_changed '^documents-boot/src/|^documents-boot/build\.gradle$'; then
  require_check=true
  reasons+=('documents-boot 코드 또는 빌드 변경')
  add_once ':documents-boot:test' module_tasks
  add_once '^documents-boot/src/|^documents-boot/build\.gradle$' dependency_patterns
  add_matching_dependencies '^documents-boot/src/|^documents-boot/build\.gradle$'
fi
if has_changed '^build\.gradle$|^settings\.gradle$|^gradlew$'; then
  require_check=true
  full_test=true
  reasons+=('루트 Gradle 설정 변경')
  add_once '^build\.gradle$|^settings\.gradle$|^gradlew$' dependency_patterns
  add_matching_dependencies '^build\.gradle$|^settings\.gradle$|^gradlew$'
fi
if has_changed '^docs/REQUIREMENTS\.md$|^docs/guides/|^docs/decisions/'; then
  reasons+=('구현 의미를 가질 수 있는 계약 문서 변경')
  add_once '^docs/REQUIREMENTS\.md$|^docs/guides/|^docs/decisions/' dependency_patterns
  add_matching_dependencies '^docs/REQUIREMENTS\.md$|^docs/guides/|^docs/decisions/'
fi

implementation_candidate=false
if [ "$require_check" = true ] || has_changed '^docs/REQUIREMENTS\.md$|^docs/guides/|^docs/decisions/|^docs/runbook/[^/]+\.md$'; then
  implementation_candidate=true
fi

if [ -z "$change_kind" ]; then
  if [ "$implementation_candidate" = false ]; then
    gate_write_result "$result_file" implementation-verification PASS not-applicable "$scope_fingerprint" EMPTY complete \
      '구현 검증 후보 변경 없음'
    printf '[PASS] 구현 검증 후보 변경 없음\n'
    exit 0
  fi

  gate_print_unclassified \
    '구현 변경 성격' \
    '구현 검증 후보 경로가 있지만 명시된 변경 성격이 없습니다.' \
    'implementation-change | contract-change | verification-only | non-contract-doc' \
    '사용자 요청과 현재 scope diff' \
    'change-kind 입력'
  gate_write_result "$result_file" implementation-verification UNCLASSIFIED unknown "$scope_fingerprint" "$scope_fingerprint" \
    'change-kind 입력' '구현 변경 성격 미확정' "${scope_paths[@]}"
  exit 2
fi

case "$change_kind" in
  non-contract-doc|workflow-implementation-change|content-only)
    gate_write_result "$result_file" implementation-verification PASS "$change_kind" "$scope_fingerprint" EMPTY complete \
      '구현 의미 변경이 아니므로 게이트 비활성'
    printf '[PASS] 구현 검증 게이트 비활성\n'
    exit 0
    ;;
  implementation-change)
    if [ "$require_check" = false ]; then
      gate_print_unclassified \
        '구현 변경 성격과 scope' \
        'implementation-change 입력과 구현 경로 후보가 일치하지 않습니다.' \
        'implementation-change | non-contract-doc' \
        '현재 scope diff' \
        'change-kind 입력'
      gate_write_result "$result_file" implementation-verification UNCLASSIFIED "$change_kind" "$scope_fingerprint" "$scope_fingerprint" \
        'change-kind 입력' '구현 변경 성격과 scope 불일치' "${scope_paths[@]}"
      exit 2
    fi
    ;;
  verification-only)
    if [ "$require_check" = false ]; then
      gate_print_unclassified \
        '검증 전용 변경 범위' \
        'verification-only 입력과 테스트 또는 검증 대상 경로가 일치하지 않습니다.' \
        'verification-only | non-contract-doc' \
        '현재 scope diff' \
        'change-kind 입력'
      gate_write_result "$result_file" implementation-verification UNCLASSIFIED "$change_kind" "$scope_fingerprint" "$scope_fingerprint" \
        'change-kind 입력' '검증 전용 변경 성격과 scope 불일치' "${scope_paths[@]}"
      exit 2
    fi
    ;;
  contract-change)
    require_check=true
    full_test=true
    add_once '^documents-(api|core|infrastructure|boot)/src/|^documents-[^/]+/build\.gradle$|^build\.gradle$|^settings\.gradle$|^gradlew$|^docs/REQUIREMENTS\.md$|^docs/guides/|^docs/decisions/' dependency_patterns
    ;;
  *)
    gate_print_unclassified \
      '구현 변경 성격' \
      "지원하지 않는 변경 성격입니다: $change_kind" \
      'implementation-change | contract-change | verification-only | non-contract-doc' \
      '변경 성격 입력' \
      'change-kind 입력'
    gate_write_result "$result_file" implementation-verification UNCLASSIFIED "$change_kind" "$scope_fingerprint" "$scope_fingerprint" \
      'change-kind 입력' '지원하지 않는 구현 변경 성격' "${scope_paths[@]}"
    exit 2
    ;;
esac

if [ "$full_test" = true ] || [ ${#module_tasks[@]} -gt 1 ]; then
  module_tasks=('test')
fi
if [ ${#module_tasks[@]} -eq 0 ]; then
  module_tasks=('test')
fi
if [ ${#dependency_paths[@]} -eq 0 ]; then
  dependency_paths=("${scope_paths[@]}")
fi

printf '[PLAN] 구현 검증 필요\n'
printf '변경 성격: %s\n' "$change_kind"
printf '기본 테스트 태스크: %s\n' "${module_tasks[*]}"
printf '사유:\n'
printf -- '- %s\n' "${reasons[@]:-명시된 구현 변경 성격}"

stage=$(resolve_verification_stage)
if [ "$run_mode" = true ] && { [ "$stage" = '진행 중' ] || [ "$stage" = 'in_progress' ]; }; then
  printf '[FAIL] 진행 중 단계에서는 최종 구현 검증을 실행할 수 없습니다. 검증 대기로 전환하세요.\n' >&2
  exit 1
fi

if [ "$dry_run" = true ] || [ "$run_mode" = false ]; then
  printf '[PLAN] 테스트는 실행하지 않았습니다.\n'
  exit 0
fi

run_gradle_verification() {
  local task has_boot_test
  local regular_tasks=()
  local test_args=()
  has_boot_test=false

  for task in "$@"; do
    case "$task" in
      test)
        add_once ':documents-api:test' regular_tasks
        add_once ':documents-core:test' regular_tasks
        add_once ':documents-infrastructure:test' regular_tasks
        has_boot_test=true
        ;;
      :documents-boot:test)
        has_boot_test=true
        ;;
      *)
        add_once "$task" regular_tasks
        ;;
    esac
  done

  if [ ${#regular_tasks[@]} -gt 0 ]; then
    printf 'Gradle 테스트 실행: ./gradlew %s\n' "${regular_tasks[*]}"
    if ! ./gradlew "${regular_tasks[@]}"; then
      return 1
    fi
  fi
  if [ "$has_boot_test" = true ]; then
    printf '[INFO] 제외 테스트: %s\n' "$excluded_boot_test"
    test_args=(':documents-boot:test')
    for task in "${boot_test_classes[@]}"; do
      test_args+=(--tests "$task")
    done
    if ! ./gradlew "${test_args[@]}"; then
      return 1
    fi
  fi

  return 0
}

dependency_fingerprint=$(gate_fingerprint_lines "${dependency_paths[@]}")
if run_gradle_verification "${module_tasks[@]}"; then
  gate_write_result "$result_file" implementation-verification PASS "$change_kind" "$scope_fingerprint" "$dependency_fingerprint" complete \
    "구현 검증 통과: ${module_tasks[*]}" "${dependency_paths[@]}"
  gate_append_dependency_patterns "$result_file" "${dependency_patterns[@]}"
  printf '[PASS] 구현 검증 통과\n'
  exit 0
fi

gate_write_result "$result_file" implementation-verification FAIL "$change_kind" "$scope_fingerprint" "$dependency_fingerprint" \
  '구현 검증 재실행' "구현 검증 실패: ${module_tasks[*]}" "${dependency_paths[@]}"
gate_append_dependency_patterns "$result_file" "${dependency_patterns[@]}"
printf '[FAIL] 구현 검증 실패\n' >&2
exit 1
