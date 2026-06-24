#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/codex-harness-scenarios.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

passed=0
failed=0

pass() {
  printf '[PASS] %s\n' "$1"
  passed=$((passed + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  failed=$((failed + 1))
}

write_scope() {
  local name=$1
  shift
  local scope_file="$tmp_dir/${name}.scope"

  printf '%s\n' "$@" > "$scope_file"
  printf '%s\n' "$scope_file"
}

run_and_capture() {
  local label=$1
  shift

  local out_file="$tmp_dir/${label}.out"
  local err_file="$tmp_dir/${label}.err"
  local status_file="$tmp_dir/${label}.status"

  set +e
  "$@" > "$out_file" 2> "$err_file"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$status_file"
}

assert_status() {
  local label=$1
  local expected=$2
  local actual
  actual=$(cat "$tmp_dir/${label}.status")

  if [ "$actual" = "$expected" ]; then
    pass "$label exit=$expected"
  else
    fail "$label exit expected=$expected actual=$actual"
  fi
}

assert_output_contains() {
  local label=$1
  local expected=$2

  if grep -F -q "$expected" "$tmp_dir/${label}.out" "$tmp_dir/${label}.err"; then
    pass "$label contains: $expected"
  else
    fail "$label missing output: $expected"
  fi
}

write_result_state() {
  local path=$1
  local gate_id=$2
  local state=$3
  local change_kind=$4
  local dependency=$5
  local dependency_pattern=$6

  {
    printf 'version=1\n'
    printf 'gate_id=%s\n' "$gate_id"
    printf 'state=%s\n' "$state"
    printf 'change_kind=%s\n' "$change_kind"
    printf 'scope_fingerprint=scenario\n'
    printf 'dependency_fingerprint=scenario\n'
    printf 'retry_from=scenario\n'
    printf 'summary=scenario fixture\n'
    if [ -n "$dependency" ]; then
      printf 'dependency\t%s\t%s\n' "$dependency" "$(sha256sum "$dependency" | awk '{print $1}')"
    fi
    if [ -n "$dependency_pattern" ]; then
      printf 'dependency_pattern\t%s\n' "$dependency_pattern"
    fi
  } > "$path"
}

run_doc_governance_scenarios() {
  local scope

  scope=$(write_scope no-governance-candidate README.md)
  run_and_capture doc_governance_no_candidate \
    bash .codex/scripts/check-doc-governance.sh --scope-file "$scope"
  assert_status doc_governance_no_candidate 0
  assert_output_contains doc_governance_no_candidate '[PASS] 문서 거버넌스 후보 변경 없음'

  scope=$(write_scope governance_candidate_without_kind .codex/skills/example/SKILL.md)
  run_and_capture doc_governance_unclassified \
    bash .codex/scripts/check-doc-governance.sh --scope-file "$scope"
  assert_status doc_governance_unclassified 2
  assert_output_contains doc_governance_unclassified '[UNCLASSIFIED] 문서 거버넌스 변경 성격'

  run_and_capture doc_governance_content_only_inactive \
    bash .codex/scripts/check-doc-governance.sh --change-kind content-only --scope-file "$scope"
  assert_status doc_governance_content_only_inactive 0
  assert_output_contains doc_governance_content_only_inactive '[PASS] 문서 거버넌스 게이트 비활성'

  run_and_capture doc_governance_contract_missing_readme \
    bash .codex/scripts/check-doc-governance.sh --change-kind workflow-contract-change --scope-file "$scope"
  assert_status doc_governance_contract_missing_readme 1
  assert_output_contains doc_governance_contract_missing_readme '.codex workflow 계약 변경 시 .codex/README.md 최신화 필요'

  scope=$(write_scope governance_contract_with_readme .codex/README.md .codex/skills/example/SKILL.md)
  run_and_capture doc_governance_contract_pass \
    bash .codex/scripts/check-doc-governance.sh --change-kind workflow-contract-change --scope-file "$scope"
  assert_status doc_governance_contract_pass 0
  assert_output_contains doc_governance_contract_pass '[PASS] 문서 거버넌스 검증 통과'
}

run_implementation_scenarios() {
  local scope

  scope=$(write_scope no_implementation_candidate README.md)
  run_and_capture implementation_no_candidate \
    bash .codex/scripts/check-doc-implementation.sh --scope-file "$scope"
  assert_status implementation_no_candidate 0
  assert_output_contains implementation_no_candidate '[PASS] 구현 검증 후보 변경 없음'

  scope=$(write_scope contract_doc_without_kind docs/REQUIREMENTS.md)
  run_and_capture implementation_unclassified \
    bash .codex/scripts/check-doc-implementation.sh --scope-file "$scope"
  assert_status implementation_unclassified 2
  assert_output_contains implementation_unclassified '[UNCLASSIFIED] 구현 변경 성격'

  run_and_capture implementation_non_contract_doc_inactive \
    bash .codex/scripts/check-doc-implementation.sh --change-kind non-contract-doc --scope-file "$scope"
  assert_status implementation_non_contract_doc_inactive 0
  assert_output_contains implementation_non_contract_doc_inactive '[PASS] 구현 검증 게이트 비활성'

  scope=$(write_scope api_implementation_change documents-api/src/main/java/example/Foo.java)
  run_and_capture implementation_api_dry_run \
    bash .codex/scripts/check-doc-implementation.sh --change-kind implementation-change --scope-file "$scope" --dry-run
  assert_status implementation_api_dry_run 0
  assert_output_contains implementation_api_dry_run '기본 테스트 태스크: :documents-api:test'
  assert_output_contains implementation_api_dry_run '[PLAN] 테스트는 실행하지 않았습니다.'

  scope=$(write_scope root_build_change build.gradle)
  run_and_capture implementation_root_dry_run \
    bash .codex/scripts/check-doc-implementation.sh --change-kind implementation-change --scope-file "$scope" --dry-run
  assert_status implementation_root_dry_run 0
  assert_output_contains implementation_root_dry_run '기본 테스트 태스크: test'

  scope=$(write_scope mismatched_implementation README.md)
  run_and_capture implementation_mismatch_unclassified \
    bash .codex/scripts/check-doc-implementation.sh --change-kind implementation-change --scope-file "$scope" --dry-run
  assert_status implementation_mismatch_unclassified 2
  assert_output_contains implementation_mismatch_unclassified '[UNCLASSIFIED] 구현 변경 성격과 scope'
}

run_retry_scenarios() {
  local failure_file="$tmp_dir/failure.state"
  local pass_file="$tmp_dir/pass.state"
  local scope

  write_result_state "$failure_file" implementation-verification FAIL implementation-change '' ''
  write_result_state "$pass_file" doc-governance PASS workflow-contract-change .codex/README.md '^\.codex/'

  scope=$(write_scope retry_reuse README.md)
  run_and_capture retry_reuses_unaffected_pass \
    bash .codex/scripts/verify-and-retry.sh --failure-file "$failure_file" --pass-state "$pass_file" --scope-file "$scope" --dry-run
  assert_status retry_reuses_unaffected_pass 0
  assert_output_contains retry_reuses_unaffected_pass '[REUSED] doc-governance'
  assert_output_contains retry_reuses_unaffected_pass '[PLAN] 무효화된 선행 PASS: 0건'

  scope=$(write_scope retry_recheck_codex .codex/config/new-contract.md)
  run_and_capture retry_rechecks_affected_pass \
    bash .codex/scripts/verify-and-retry.sh --failure-file "$failure_file" --pass-state "$pass_file" --scope-file "$scope" --dry-run
  assert_status retry_rechecks_affected_pass 0
  assert_output_contains retry_rechecks_affected_pass '[RECHECK] doc-governance'
  assert_output_contains retry_rechecks_affected_pass '[PLAN] 무효화된 선행 PASS: 1건'

  write_result_state "$failure_file" implementation-verification PASS implementation-change '' ''
  run_and_capture retry_requires_fail_state \
    bash .codex/scripts/verify-and-retry.sh --failure-file "$failure_file" --pass-state "$pass_file" --scope-file "$scope" --dry-run
  assert_status retry_requires_fail_state 2
  assert_output_contains retry_requires_fail_state '[UNCLASSIFIED] 실패 정보 상태'
}

run_doc_governance_scenarios
run_implementation_scenarios
run_retry_scenarios

if [ "$failed" -gt 0 ]; then
  printf '\n[FAIL] 조건부 하네스 시나리오 검증 실패: %d건 실패, %d건 통과\n' "$failed" "$passed" >&2
  exit 1
fi

printf '\n[PASS] 조건부 하네스 시나리오 검증 통과: %d건\n' "$passed"
