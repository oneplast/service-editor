#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

runbook_path=""
label="verification-failure"
scope_file=""
followup_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --runbook)
      runbook_path="$2"
      shift 2
      ;;
    --label)
      label="$2"
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
    *)
      printf '알 수 없는 옵션: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

safe_label=$(printf '%s' "$label" | tr -c 'A-Za-z0-9._-' '_')

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

is_doc_governance_failure() {
  has_changed '^AGENTS\.md$|^docs/README\.md$|^docs/followup/|^prompts/topics/|^\.codex/'
}

is_implementation_failure() {
  has_changed '^documents-(api|core|infrastructure|boot)/src/|^build\.gradle$|^settings\.gradle$|^gradlew$|^docs/REQUIREMENTS\.md$|^docs/guides/|^docs/decisions/'
}

resolve_route_kind() {
  if [ -n "$runbook_path" ]; then
    printf 'explicit\n'
    return
  fi

  local doc_flag impl_flag
  doc_flag=false
  impl_flag=false
  if is_doc_governance_failure; then doc_flag=true; fi
  if is_implementation_failure; then impl_flag=true; fi

  if [ "$doc_flag" = true ] && [ "$impl_flag" = false ]; then
    printf 'doc-governance-failure\n'
    return
  fi

  if [ "$impl_flag" = true ] && [ "$doc_flag" = false ]; then
    printf 'implementation-verification-failure\n'
    return
  fi

  printf 'ambiguous\n'
}

resolve_default_runbook() {
  if [ -n "$runbook_path" ]; then
    printf '%s\n' "$runbook_path"
    return
  fi

  case "$(resolve_route_kind)" in
    doc-governance-failure)
      printf 'docs/runbook/ai-doc-workflow-recovery.md\n'
      ;;
    implementation-verification-failure)
      printf 'docs/runbook/test-verification-recovery.md\n'
      ;;
    *)
      printf '\n'
      ;;
  esac
}

print_route_options() {
  printf '[INFO] 실패 축 자동 분류가 애매합니다. 아래 안 중 하나를 선택해야 합니다.\n'
  printf '1. ai-doc-workflow-recovery.md 에 추가\n'
  printf '   이유: 문서 체계, followup, prompts, .codex 절차 변경이 함께 보입니다.\n'
  printf '2. test-verification-recovery.md 에 추가 (추천)\n'
  printf '   이유: 코드/계약/빌드 변경이 섞여 있거나 구현 검증 실패와 연결될 가능성이 큽니다.\n'
  printf '3. 자동 기록하지 않고 새 runbook 축 여부를 결정\n'
  printf '   이유: 기존 축 중 어느 쪽에도 명확히 속하지 않을 수 있습니다.\n'
}

record_failure_case() {
  local failed_check summary ts resolved_runbook route_kind
  failed_check="$1"
  summary="$2"
  ts=$(date '+%Y-%m-%d')
  route_kind=$(resolve_route_kind)
  resolved_runbook=$(resolve_default_runbook)

  if [ "$route_kind" = 'ambiguous' ] && [ -z "$runbook_path" ]; then
    print_route_options >&2
    printf '%s\n' ""
    return
  fi

  mkdir -p "$(dirname "$resolved_runbook")"
  if [ ! -f "$resolved_runbook" ]; then
    printf '# %s\n\n## 자동 기록된 실패 케이스\n' "$label" > "$resolved_runbook"
  elif ! rg -n '^## 자동 기록된 실패 케이스$' "$resolved_runbook" >/dev/null 2>&1; then
    printf '\n## 자동 기록된 실패 케이스\n' >> "$resolved_runbook"
  fi

  cat <<EOF_RUNBOOK >> "$resolved_runbook"

### ${ts} ${label}

- 실패 검증: ${failed_check}
- 기록 시점: 첫 확인 즉시
- 요약: ${summary}
- 후속 조치: 실패 원인 분류 후 기존 케이스 보강 또는 새 runbook 주제 검토
EOF_RUNBOOK

  printf '%s\n' "$resolved_runbook"
}

if is_in_progress_stage; then
  if [ -n "$scope_file" ]; then
    printf '검증 범위 파일: %s\n' "$scope_file"
  fi
  if [ -n "$followup_file" ]; then
    printf 'followup 파일: %s\n' "$followup_file"
  fi
  printf '[INFO] followup 검증 단계: 진행 중\n'
  printf '[FAIL] followup 검증 단계가 진행 중이므로 verify-and-retry를 실행할 수 없습니다. `검증 단계: 검증 대기`로 바꾼 뒤 다시 실행하세요.\n' >&2
  exit 1
fi

printf '[INFO] 검증 시도 시작\n'
if [ -n "$scope_file" ]; then
  printf '검증 범위 파일: %s\n' "$scope_file"
fi
if [ -n "$followup_file" ]; then
  printf 'followup 파일: %s\n' "$followup_file"
fi
if is_in_progress_stage; then
  printf '[INFO] followup 검증 단계: 진행 중\n'
elif is_verification_ready_stage; then
  printf '[INFO] followup 검증 단계: 검증 대기\n'
fi

scope_args=()
if [ -n "$scope_file" ]; then
  scope_args+=(--scope-file "$scope_file")
fi
if [ -n "$followup_file" ]; then
  scope_args+=(--followup-file "$followup_file")
fi

if ! VERIFY_AND_RETRY_ACTIVE=1 ./.codex/scripts/check-doc-governance.sh "${scope_args[@]}" >/tmp/verify-governance.out 2>&1; then
  cat /tmp/verify-governance.out
  routed_runbook=$(record_failure_case 'check-doc-governance.sh' '문서 거버넌스 검증 실패 확인')
  if [ -n "$routed_runbook" ]; then
    printf '[FAIL] 문서 거버넌스 실패. 실패 케이스를 %s 에 기록했습니다.\n' "$routed_runbook" >&2
  else
    printf '[FAIL] 문서 거버넌스 실패. 실패 축이 애매해 자동 기록하지 않았고 사용자 확인이 필요합니다.\n' >&2
  fi
  exit 1
fi

if ! ./.codex/scripts/check-doc-implementation.sh --strict "${scope_args[@]}" >/tmp/verify-implementation.out 2>&1; then
  cat /tmp/verify-implementation.out
  if ! ./.codex/scripts/check-doc-implementation.sh --run "${scope_args[@]}" >/tmp/verify-implementation-run.out 2>&1; then
    cat /tmp/verify-implementation-run.out
    routed_runbook=$(record_failure_case 'check-doc-implementation.sh' '구현 검증 실패 확인')
    if [ -n "$routed_runbook" ]; then
      printf '[FAIL] 구현 검증 실패. 실패 케이스를 %s 에 기록했습니다.\n' "$routed_runbook" >&2
    else
      printf '[FAIL] 구현 검증 실패. 실패 축이 애매해 자동 기록하지 않았고 사용자 확인이 필요합니다.\n' >&2
    fi
    exit 1
  fi
fi

printf '[PASS] 모든 검증 통과\n'
