#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

run_mode=false
strict_mode=false
scope_file=""
followup_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --run)
      run_mode=true
      shift
      ;;
    --strict)
      strict_mode=true
      shift
      ;;
    --scope-file)
      scope_file="$2"
      shift 2
      ;;
    --followup-file)
      followup_file="$2"
      shift 2
      ;;
    *)
      printf '알 수 없는 옵션: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -n "$scope_file" ]; then
  changed_files=$(grep -v '^\s*$' "$scope_file" | sed 's#^./##')
else
  changed_files=$(git status --short --untracked-files=all | awk '{print $2}')
  printf '[INFO] scope-file 없이 git status 전체를 검증 범위로 사용합니다. 긴 작업이면 followup과 scope를 먼저 고정하세요.\n'
fi

resolve_followup_file() {
  if [ -n "$followup_file" ]; then
    printf '%s\n' "$followup_file"
    return
  fi
  if [ -n "$scope_file" ] && printf '%s' "$scope_file" | grep -Eq '^docs/followup/active/.*\.scope$'; then
    printf '%s\n' "${scope_file%.scope}.md"
    return
  fi
  printf '\n'
}

resolve_verification_stage() {
  local resolved_followup
  resolved_followup=$(resolve_followup_file)
  if [ -z "$resolved_followup" ] || [ ! -f "$resolved_followup" ]; then
    printf '\n'
    return
  fi

  sed -n 's/^- 검증 단계:[[:space:]]*//p' "$resolved_followup" | head -n 1 | tr -d '\r'
}

is_in_progress_stage() {
  local stage
  stage=$(resolve_verification_stage)
  [ "$stage" = '진행 중' ] || [ "$stage" = 'in_progress' ]
}

is_verification_ready_stage() {
  local stage
  stage=$(resolve_verification_stage)
  [ "$stage" = '검증 대기' ] || [ "$stage" = 'ready_for_verification' ]
}

has_changed() {
  local pattern=$1
  printf '%s\n' "$changed_files" | grep -E -q "$pattern"
}

has_non_readme_runbook_change() {
  printf '%s\n' "$changed_files" | grep -E '^docs/runbook/[^/]+\.md$' | grep -F -v 'docs/runbook/README.md' >/dev/null 2>&1
}

module_tasks=()
reasons=()
require_check=false
full_test=false
runbook_only_notice=false

add_task_once() {
  local task=$1
  local existing
  for existing in "${module_tasks[@]:-}"; do
    if [ "$existing" = "$task" ]; then
      return
    fi
  done
  module_tasks+=("$task")
}

if has_changed '^documents-api/src/|^documents-api/build\.gradle$'; then
  require_check=true
  reasons+=('documents-api 코드 또는 빌드 변경')
  add_task_once ':documents-api:test'
fi

if has_changed '^documents-core/src/|^documents-core/build\.gradle$'; then
  require_check=true
  reasons+=('documents-core 코드 또는 빌드 변경')
  add_task_once ':documents-core:test'
fi

if has_changed '^documents-infrastructure/src/|^documents-infrastructure/build\.gradle$'; then
  require_check=true
  reasons+=('documents-infrastructure 코드 또는 빌드 변경')
  add_task_once ':documents-infrastructure:test'
fi

if has_changed '^documents-boot/src/|^documents-boot/build\.gradle$'; then
  require_check=true
  reasons+=('documents-boot 코드 또는 빌드 변경')
  add_task_once ':documents-boot:test'
fi

if has_changed '^build\.gradle$|^settings\.gradle$|^gradlew$'; then
  require_check=true
  full_test=true
  reasons+=('루트 Gradle 설정 변경')
fi

if has_changed '^docs/REQUIREMENTS\.md$'; then
  require_check=true
  full_test=true
  reasons+=('REQUIREMENTS 변경')
fi

if has_changed '^docs/guides/' ; then
  require_check=true
  full_test=true
  reasons+=('guide 계약 변경 가능성')
fi

if has_changed '^docs/decisions/' ; then
  require_check=true
  full_test=true
  reasons+=('ADR 또는 정책 변경')
fi

if has_non_readme_runbook_change; then
  runbook_only_notice=true
  reasons+=('runbook 절차 변경 여부 확인 필요')
fi

if [ "$full_test" = true ] || [ ${#module_tasks[@]} -gt 1 ]; then
  module_tasks=('test')
fi

if [ "$require_check" = false ] && [ "$runbook_only_notice" = false ]; then
  printf '[PASS] 구현 검증 불필요\n'
  printf '사유: 코드 변경이나 구현 의미 변경 문서가 감지되지 않았습니다.\n'
  exit 0
fi

printf '[INFO] 구현 검증 검토 필요\n'
if [ -n "$scope_file" ]; then
  printf '검증 범위 파일: %s\n' "$scope_file"
fi
if [ -n "$followup_file" ]; then
  printf 'followup 파일: %s\n' "$followup_file"
fi
if is_in_progress_stage; then
  printf 'followup 검증 단계: 진행 중\n'
elif is_verification_ready_stage; then
  printf 'followup 검증 단계: 검증 대기\n'
fi
printf '사유:\n'
for reason in "${reasons[@]}"; do
  printf -- '- %s\n' "$reason"
done

if [ "$require_check" = true ]; then
  printf '기본 테스트 태스크: %s\n' "${module_tasks[*]}"
else
  printf '기본 테스트 태스크: 없음\n'
  printf '주의: runbook 변경은 실제 명령, 엔드포인트, 설정 키, 기대 결과가 바뀐 경우에만 테스트를 강제한다.\n'
fi

if [ "$run_mode" = true ]; then
  if [ "$require_check" = false ]; then
    printf '[PASS] 자동 실행할 Gradle 테스트 태스크 없음\n'
    exit 0
  fi
  printf 'Gradle 테스트 실행: ./gradlew %s\n' "${module_tasks[*]}"
  ./gradlew "${module_tasks[@]}"
  exit $?
fi

if [ "$strict_mode" = true ] && [ "$require_check" = true ]; then
  if is_in_progress_stage; then
    printf '[INFO] followup 검증 단계가 진행 중이므로 강한 구현 검증을 아직 강제하지 않습니다.\n'
    exit 0
  fi
  printf '[FAIL] 구현 검증이 필요한 변경입니다. `./.codex/scripts/verify-and-retry.sh --scope-file <path> --followup-file <path> --label <task>` 또는 적절한 Gradle 테스트를 실행하세요.\n' >&2
  exit 1
fi

exit 0
