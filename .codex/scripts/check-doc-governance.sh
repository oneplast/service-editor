#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

failures=0
forced_work_type=""
scope_file=""
followup_file=""
search_excludes_file=".codex/config/doc-governance-search-excludes.txt"
search_exclude_args=()

while [ $# -gt 0 ]; do
  case "$1" in
    --scope-file)
      scope_file="$2"
      shift 2
      ;;
    --followup-file)
      followup_file="$2"
      shift 2
      ;;
    --work-type)
      forced_work_type="$2"
      shift 2
      ;;
    *)
      if [ -z "$forced_work_type" ]; then
        forced_work_type="$1"
        shift
      else
        printf '알 수 없는 옵션: %s\n' "$1" >&2
        exit 2
      fi
      ;;
  esac
done

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  failures=$((failures + 1))
}

if [ -n "$scope_file" ]; then
  changed_files=$(grep -v '^\s*$' "$scope_file" | sed 's#^./##')
else
  changed_files=$(git status --short --untracked-files=all | awk '{print $2}')
  printf '[INFO] scope-file 없이 git status 전체를 검증 범위로 사용합니다. 긴 작업이면 followup과 scope를 먼저 고정하세요.\n'
fi

if [ ! -f "$search_excludes_file" ]; then
  printf '[FAIL] 금지 참조 검사 제외 glob 설정 파일이 없습니다: %s\n' "$search_excludes_file" >&2
  exit 1
fi

while IFS= read -r exclude_glob; do
  if [ -z "$exclude_glob" ]; then
    continue
  fi
  case "$exclude_glob" in
    \#*)
      continue
      ;;
  esac
  search_exclude_args+=(-g "!$exclude_glob")
done < "$search_excludes_file"

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

count_active_followup_tasks() {
  find docs/followup/active -maxdepth 1 -type f ! -name '.gitkeep' \
    | sed 's#^.*/##' \
    | sed -E 's/\.(md|scope)$//' \
    | sort -u \
    | wc -l \
    | tr -d ' '
}

requires_implementation_closure() {
  has_changed '^documents-(api|core|infrastructure|boot)/src/|^build\.gradle$|^settings\.gradle$|^gradlew$|^docs/REQUIREMENTS\.md$|^docs/guides/|^docs/decisions/'
}

check_required_file() {
  local path=$1
  local label=$2
  if printf '%s\n' "$changed_files" | grep -Fx -q "$path"; then
    pass "$label"
  else
    fail "$label 누락"
  fi
}

check_required_prefix() {
  local prefix=$1
  local label=$2
  if printf '%s\n' "$changed_files" | grep -E -q "^$prefix"; then
    pass "$label"
  else
    fail "$label 누락"
  fi
}

work_types=()

if [ -n "$forced_work_type" ]; then
  work_types+=("$forced_work_type")
else
  if has_changed '^AGENTS\.md$|^docs/README\.md$|^\.codex/|^docs/followup/README\.md$|^docs/runbook/README\.md$'; then
    work_types+=(doc-governance-change)
  fi

  if has_changed '^docs/followup/(README\.md|000-active-task-template\.md)$'; then
    work_types+=(followup-policy-change)
  fi

  if has_changed '^docs/runbook/' && ! has_changed '^docs/runbook/DEBUG\.md$'; then
    work_types+=(runbook-policy-change)
  fi

  if has_changed '^prompts/README\.md$|^prompts/topics/' ; then
    work_types+=(prompt-governance-change)
  fi
fi

if [ ${#work_types[@]} -eq 0 ]; then
  pass '공식 문서 검증 대상 변경 없음'
  if requires_implementation_closure && [ "${VERIFY_AND_RETRY_ACTIVE:-0}" != "1" ]; then
    if is_in_progress_stage; then
      pass '코드/계약 변경이지만 followup 검증 단계가 진행 중이므로 PASS 게이트 유예'
    else
      fail '코드/계약 변경은 verify-and-retry 경로로 PASS를 닫아야 합니다.'
    fi
    printf '\n검증 실패 %d건\n' "$failures"
    if [ "$failures" -gt 0 ]; then
      exit 1
    fi
  fi
  exit 0
fi

printf '감지된 작업 유형: %s\n' "${work_types[*]}"
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

for work_type in "${work_types[@]}"; do
  case "$work_type" in
    doc-governance-change)
      check_required_file 'AGENTS.md' 'AGENTS.md 최신화'
      check_required_file 'docs/README.md' 'docs/README.md 최신화'
      check_required_file 'prompts/topics/docs-and-prompt-governance.md' 'docs governance topic 최신화'
      check_required_prefix 'prompts/worklog/' 'worklog 최신화'
      if has_changed '^\.codex/(skills|scripts|config)/' && ! has_changed '^\.codex/README\.md$'; then
        fail '.codex 보조 경로 변경 시 .codex/README.md 최신화 필요'
      elif has_changed '^\.codex/(skills|scripts|config)/'; then
        pass '.codex 보조 경로와 .codex/README.md 연결'
      fi
      ;;
    followup-policy-change)
      check_required_file 'docs/followup/README.md' 'followup README 최신화'
      if has_changed '^\.codex/skills/followup-handoff/' && ! has_changed '^AGENTS\.md$'; then
        fail 'followup 절차 변경 시 AGENTS.md 선언 연결 확인 필요'
      elif has_changed '^\.codex/skills/followup-handoff/'; then
        pass 'followup 절차와 AGENTS 연결 확인'
      fi
      ;;
    runbook-policy-change)
      check_required_file 'docs/runbook/README.md' 'runbook README 최신화'
      if has_non_readme_runbook_change; then
        pass '개별 runbook 최신화'
      else
        fail 'runbook 정책 변경 시 해당 runbook 파일 최신화 필요'
      fi
      ;;
    prompt-governance-change)
      check_required_file 'prompts/README.md' 'prompts README 최신화'
      ;;
    repeated-error-case-update)
      if has_non_readme_runbook_change; then
        pass '반복 에러용 runbook 파일 반영'
      else
        fail '반복 에러 처리 시 관련 runbook 파일 최신화 필요'
      fi
      ;;
    *)
      fail "알 수 없는 작업 유형: $work_type"
      ;;
  esac
done

if rg -F -n 'docs/learn/followup' AGENTS.md docs prompts/README.md prompts/topics "${search_exclude_args[@]}" >/dev/null 2>&1; then
  fail '금지된 docs/learn/followup 참조가 남아 있습니다.'
else
  pass '금지된 docs/learn/followup 참조 없음'
fi

active_followup_count=$(count_active_followup_tasks)
if [ "$active_followup_count" -le 1 ]; then
  pass 'docs/followup/active 정리 상태 정상'
else
  fail 'docs/followup/active 에 여러 작업 파일이 남아 있습니다.'
fi

if has_changed '^\.codex/(skills|scripts|config)/' || has_changed '^AGENTS\.md$'; then
  if rg -n '\.codex/(skills|scripts|config)|check-doc-implementation\.sh|doc-to-code-check-matrix\.md|verify-and-retry\.sh|failure-route-map\.md' AGENTS.md docs/README.md docs/runbook/README.md prompts/topics/docs-and-prompt-governance.md .codex/README.md >/dev/null 2>&1; then
    pass '.codex 경로 반영 확인'
  else
    fail '.codex 경로 반영이 누락됐습니다.'
  fi
fi

if requires_implementation_closure && [ "${VERIFY_AND_RETRY_ACTIVE:-0}" != "1" ]; then
  if is_in_progress_stage; then
    pass '코드/계약 변경이지만 followup 검증 단계가 진행 중이므로 PASS 게이트 유예'
  else
    fail '코드/계약 변경은 verify-and-retry 경로로 PASS를 닫아야 합니다.'
  fi
fi

if [ "$failures" -gt 0 ]; then
  printf '\n검증 실패 %d건\n' "$failures"
  exit 1
fi

printf '\n문서 거버넌스 검증 통과\n'
