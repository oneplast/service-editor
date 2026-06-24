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
search_excludes_file=".codex/config/doc-governance-search-excludes.txt"
search_exclude_args=()
failures=0

while [ $# -gt 0 ]; do
  case "$1" in
    --change-kind|--work-type)
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

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  failures=$((failures + 1))
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

governance_candidate=false
if has_changed '^AGENTS\.md$|^docs/README\.md$|^docs/followup/README\.md$|^docs/runbook/README\.md$|^prompts/README\.md$|^prompts/topics/|^\.codex/(README\.md|skills/|scripts/|config/)'; then
  governance_candidate=true
fi

if [ -z "$change_kind" ]; then
  if [ "$governance_candidate" = false ]; then
    gate_write_result "$result_file" doc-governance PASS not-applicable "$scope_fingerprint" EMPTY complete \
      '문서 거버넌스 후보 변경 없음'
    pass '문서 거버넌스 후보 변경 없음'
    exit 0
  fi

  gate_print_unclassified \
    '문서 거버넌스 변경 성격' \
    '거버넌스 후보 경로가 있지만 명시된 변경 성격이 없습니다.' \
    'doc-governance-change | workflow-contract-change | workflow-implementation-change | content-only' \
    '사용자 요청과 현재 scope diff' \
    'change-kind 입력'
  gate_write_result "$result_file" doc-governance UNCLASSIFIED unknown "$scope_fingerprint" "$scope_fingerprint" \
    'change-kind 입력' '문서 거버넌스 변경 성격 미확정' "${scope_paths[@]}"
  exit 2
fi

case "$change_kind" in
  content-only|workflow-implementation-change|repeated-error-case-update|non-contract-doc)
    gate_write_result "$result_file" doc-governance PASS "$change_kind" "$scope_fingerprint" EMPTY complete \
      '문서 체계 또는 workflow 계약 변경이 아니므로 게이트 비활성'
    pass '문서 거버넌스 게이트 비활성'
    exit 0
    ;;
  doc-governance-change|workflow-contract-change|followup-policy-change|runbook-policy-change|prompt-governance-change)
    ;;
  *)
    gate_print_unclassified \
      '문서 거버넌스 변경 성격' \
      "지원하지 않는 변경 성격입니다: $change_kind" \
      'doc-governance-change | workflow-contract-change | workflow-implementation-change | content-only' \
      '변경 성격 입력' \
      'change-kind 입력'
    gate_write_result "$result_file" doc-governance UNCLASSIFIED "$change_kind" "$scope_fingerprint" "$scope_fingerprint" \
      'change-kind 입력' '지원하지 않는 문서 거버넌스 변경 성격' "${scope_paths[@]}"
    exit 2
    ;;
esac

if [ ! -f "$search_excludes_file" ]; then
  fail "금지 참조 검사 제외 glob 설정 파일 누락: $search_excludes_file"
fi

if [ -f "$search_excludes_file" ]; then
  while IFS= read -r exclude_glob; do
    case "$exclude_glob" in
      ''|\#*) continue ;;
    esac
    search_exclude_args+=(-g "!$exclude_glob")
  done < "$search_excludes_file"
fi

case "$change_kind" in
  doc-governance-change)
    check_required_file 'AGENTS.md' 'AGENTS.md 최신화'
    check_required_file 'docs/README.md' 'docs/README.md 최신화'
    check_required_file 'prompts/topics/docs-and-prompt-governance.md' 'docs governance topic 최신화'
    check_required_prefix 'prompts/worklog/' 'worklog 최신화'
    ;;
  workflow-contract-change)
    if has_changed '^\.codex/(skills|scripts|config)/' && ! has_changed '^\.codex/README\.md$'; then
      fail '.codex workflow 계약 변경 시 .codex/README.md 최신화 필요'
    else
      pass '.codex workflow 계약 연결 확인'
    fi
    ;;
  followup-policy-change)
    check_required_file 'docs/followup/README.md' 'followup README 최신화'
    ;;
  runbook-policy-change)
    check_required_file 'docs/runbook/README.md' 'runbook README 최신화'
    ;;
  prompt-governance-change)
    check_required_file 'prompts/README.md' 'prompts README 최신화'
    ;;
esac

if [ -f "$search_excludes_file" ]; then
  if rg -F -n 'docs/learn/followup' AGENTS.md docs prompts/README.md prompts/topics "${search_exclude_args[@]}" >/dev/null 2>&1; then
    fail '금지된 docs/learn/followup 참조가 남아 있습니다.'
  else
    pass '금지된 docs/learn/followup 참조 없음'
  fi
fi

active_followup_count=$(find docs/followup/active -maxdepth 1 -type f ! -name '.gitkeep' \
  | sed 's#^.*/##' \
  | sed -E 's/\.(md|scope)$//' \
  | sort -u \
  | wc -l \
  | tr -d ' ')
if [ "$active_followup_count" -le 1 ]; then
  pass 'docs/followup/active 정리 상태 정상'
else
  fail 'docs/followup/active 에 여러 작업 파일이 남아 있습니다.'
fi

dependency_fingerprint=$(gate_fingerprint_lines "${scope_paths[@]}")
if [ "$failures" -gt 0 ]; then
  gate_write_result "$result_file" doc-governance FAIL "$change_kind" "$scope_fingerprint" "$dependency_fingerprint" \
    'doc-governance 검증' "문서 거버넌스 검증 실패 ${failures}건" "${scope_paths[@]}"
  gate_append_dependency_patterns "$result_file" \
    '^AGENTS\.md$|^docs/README\.md$|^docs/followup/README\.md$|^docs/runbook/README\.md$|^prompts/README\.md$|^prompts/topics/|^prompts/worklog/|^\.codex/'
  printf '\n검증 실패 %d건\n' "$failures" >&2
  exit 1
fi

gate_write_result "$result_file" doc-governance PASS "$change_kind" "$scope_fingerprint" "$dependency_fingerprint" complete \
  '문서 거버넌스 검증 통과' "${scope_paths[@]}"
gate_append_dependency_patterns "$result_file" \
  '^AGENTS\.md$|^docs/README\.md$|^docs/followup/README\.md$|^docs/runbook/README\.md$|^prompts/README\.md$|^prompts/topics/|^prompts/worklog/|^\.codex/'
printf '\n[PASS] 문서 거버넌스 검증 통과\n'
