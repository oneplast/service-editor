#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# shellcheck source=.codex/scripts/gate-common.sh
source .codex/scripts/gate-common.sh

failure_file=""
scope_file=""
followup_file=""
runbook_approved=""
label="verification-failure"
dry_run=false
pass_state_files=()

while [ $# -gt 0 ]; do
  case "$1" in
    --failure-file)
      failure_file="$2"
      shift 2
      ;;
    --pass-state)
      pass_state_files+=("$2")
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
    --runbook-approved)
      runbook_approved="$2"
      shift 2
      ;;
    --label)
      label="$2"
      shift 2
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

if [ -z "$failure_file" ] || [ ! -f "$failure_file" ]; then
  gate_print_unclassified \
    '실패 정보' \
    'verification-retry에는 최초 검증이 생성한 failure-file이 필요합니다.' \
    '유효한 FAIL 결과 파일' \
    '실패한 게이트의 result-file' \
    'failure-file 입력'
  exit 2
fi

failure_state=$(gate_read_result_value "$failure_file" state)
failed_gate=$(gate_read_result_value "$failure_file" gate_id)
failed_change_kind=$(gate_read_result_value "$failure_file" change_kind)
if [ "$failure_state" != 'FAIL' ]; then
  gate_print_unclassified \
    '실패 정보 상태' \
    "failure-file 상태가 FAIL이 아닙니다: $failure_state" \
    'FAIL' \
    'failure-file 내용' \
    'failure-file 입력'
  exit 2
fi

resolve_followup_file() {
  if [ -n "$followup_file" ]; then
    printf '%s\n' "$followup_file"
  elif [ -n "$scope_file" ] && printf '%s' "$scope_file" | grep -Eq '^docs/followup/active/.*\.scope$'; then
    printf '%s\n' "${scope_file%.scope}.md"
  fi
}

resolved_followup=$(resolve_followup_file)
if [ -n "$resolved_followup" ] && [ -f "$resolved_followup" ]; then
  stage=$(sed -n 's/^- 검증 단계:[[:space:]]*//p' "$resolved_followup" | head -n 1 | tr -d '\r')
  if [ "$stage" = '진행 중' ] || [ "$stage" = 'in_progress' ]; then
    printf '[FAIL] 검증 단계가 진행 중입니다. 검증 대기로 전환한 뒤 재시도하세요.\n' >&2
    exit 1
  fi
fi

changed_files=$(gate_load_changed_files "$scope_file") || exit $?
mapfile -t scope_paths < <(printf '%s\n' "$changed_files" | sed '/^$/d')

scope_args=()
if [ -n "$scope_file" ]; then
  scope_args+=(--scope-file "$scope_file")
fi
if [ -n "$followup_file" ]; then
  scope_args+=(--followup-file "$followup_file")
fi

run_gate() {
  local gate_id=$1
  local change_kind=$2
  local result_file=$3

  case "$gate_id" in
    doc-governance)
      bash .codex/scripts/check-doc-governance.sh \
        --change-kind "$change_kind" \
        --result-file "$result_file" \
        "${scope_args[@]}"
      ;;
    implementation-verification)
      bash .codex/scripts/check-doc-implementation.sh \
        --change-kind "$change_kind" \
        --run \
        --result-file "$result_file" \
        "${scope_args[@]}"
      ;;
    *)
      gate_print_unclassified \
        '재시도 게이트' \
        "지원하지 않는 gate_id입니다: $gate_id" \
        'doc-governance | implementation-verification' \
        'failure-file 또는 pass-state 내용' \
        '게이트 재실행'
      return 2
      ;;
  esac
}

invalidated_states=()
state_file=""
for state_file in "${pass_state_files[@]:-}"; do
  if [ -z "$state_file" ]; then
    continue
  fi
  if [ ! -f "$state_file" ]; then
    gate_print_unclassified \
      '선행 PASS 정보' \
      "pass-state 파일을 찾을 수 없습니다: $state_file" \
      '유효한 PASS 결과 파일' \
      'pass-state 경로' \
      'PASS 영향 판정'
    exit 2
  fi

  state=$(gate_read_result_value "$state_file" state)
  if [ "$state" != 'PASS' ]; then
    gate_print_unclassified \
      '선행 PASS 상태' \
      "pass-state 상태가 PASS가 아닙니다: $state_file ($state)" \
      'PASS' \
      'pass-state 내용' \
      'PASS 영향 판정'
    exit 2
  fi

  state_gate=$(gate_read_result_value "$state_file" gate_id)
  state_change_kind=$(gate_read_result_value "$state_file" change_kind)
  if [ "$state_gate" = "$failed_gate" ] && [ "$state_change_kind" = "$failed_change_kind" ]; then
    printf '[SKIP] 실패 게이트와 동일한 과거 PASS는 선행 PASS 재검증 대상에서 제외: %s\n' "$state_gate"
    continue
  fi

  if gate_result_dependencies_changed "$state_file" "$changed_files"; then
    invalidated_states+=("$state_file")
    printf '[RECHECK] %s\n' "$(gate_read_result_value "$state_file" gate_id)"
  else
    printf '[REUSED] %s\n' "$(gate_read_result_value "$state_file" gate_id)"
  fi
done

printf '[PLAN] 무효화된 선행 PASS: %d건\n' "${#invalidated_states[@]}"
printf '[PLAN] 실패 게이트 재개: %s\n' "$failed_gate"
retry_result_file="${failure_file}.retry"
if [ "$dry_run" = true ]; then
  printf '[PLAN] 재시도 결과 파일: %s\n' "$retry_result_file"
  exit 0
fi

for state_file in "${invalidated_states[@]}"; do
  gate_id=$(gate_read_result_value "$state_file" gate_id)
  change_kind=$(gate_read_result_value "$state_file" change_kind)
  printf '[RETRY] 무효화된 선행 게이트: %s\n' "$gate_id"
  run_gate "$gate_id" "$change_kind" "$state_file"
done

printf '[RETRY] 실패 게이트: %s\n' "$failed_gate"
run_gate "$failed_gate" "$failed_change_kind" "$retry_result_file"
printf '[PASS] 실패 원본 보존: %s\n' "$failure_file"
printf '[PASS] 재시도 결과 저장: %s\n' "$retry_result_file"

if [ -n "$runbook_approved" ]; then
  if [ ! -f "$runbook_approved" ]; then
    gate_print_unclassified \
      '승인된 runbook 경로' \
      "runbook 파일을 찾을 수 없습니다: $runbook_approved" \
      '기존 runbook 파일' \
      '메인이 확정한 runbook 경로' \
      'runbook 기록'
    exit 2
  fi
  {
    printf '\n### %s %s\n\n' "$(date '+%Y-%m-%d')" "$label"
    printf -- '- 실패 검증: %s\n' "$failed_gate"
    printf -- '- 실패 정보: %s\n' "$failure_file"
    printf -- '- 복구 결과: 영향받은 PASS 재검증 후 동일 게이트 PASS\n'
  } >> "$runbook_approved"
  printf '[PASS] 승인된 runbook에 실패 사례 기록: %s\n' "$runbook_approved"
fi

printf '[PASS] 선택적 재검증 완료\n'
