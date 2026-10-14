# Codex Scripts

이 디렉토리는 메인 에이전트가 확정한 게이트 입력을 받아 문서 거버넌스, 구현 검증, 실패 재시도를 기계적으로 수행하는 script를 둔다.

이 문서는 script를 실제로 실행하거나 옵션을 확인해야 할 때 읽는다. `.codex/` 경로를 확인한다는 이유만으로 선행 로드하지 않는다.

## 공통 입출력

- 공통 종료 상태:
  - `0`: `PASS` 또는 명시적으로 비활성화된 게이트
  - `1`: `FAIL`
  - `2`: `UNCLASSIFIED`
  - `64`: 잘못된 옵션
- `--scope-path <path>`를 반복해서 넘기면 그 경로 목록만 사용한다. script는 내부에서 임시 scope 파일로 변환해 기존 fingerprint와 검증 계획 산출 흐름을 그대로 사용하고, 종료 시 임시 파일을 정리한다.
- `--scope-file`이 있으면 해당 파일 목록만 사용하고, 없을 때만 `git status` 전체를 fallback으로 사용한다. `--scope-path`와 `--scope-file`은 함께 사용하지 않는다.
- `--scope-file`은 작업 파일 목록을 담은 실제 일반 파일 경로여야 한다. `<(printf ...)`, `/dev/fd/*`, `/proc/*/fd/*`, `-` 같은 임시 입력은 재현 가능한 scope 파일로 쓰지 않는다.
- `--result-file docs/followup/active/.state/<task>-<gate>.state`를 지정하면 게이트, 상태, 변경 성격, scope fingerprint, 직접 의존 파일 해시와 재개 지점을 기록한다.
- 상태 파일은 `docs/followup/active/**` ignore 범위에 두며 followup에 필요한 경로만 남긴다.
- script는 명시된 `--change-kind`를 소비하며 경로만으로 의미론적 변경 성격을 확정하지 않는다.

## 문서 거버넌스

```bash
bash .codex/scripts/check-doc-governance.sh \
  --change-kind workflow-contract-change \
  --scope-file <scope> \
  --result-file docs/followup/active/.state/<task>-governance.state
```

`content-only`, `workflow-implementation-change`, `non-contract-doc`이면 거버넌스 게이트를 실행하지 않고 `PASS`로 닫는다. 후보 경로가 있는데 `--change-kind`가 없으면 `UNCLASSIFIED`다.

## 구현 검증

```bash
mkdir -p build/codex
printf '%s\n' \
  path/to/changed-file.kt \
  path/to/changed-test.kt \
  > build/codex/scope.txt

bash .codex/scripts/check-doc-implementation.sh \
  --change-kind implementation-change \
  --scope-file build/codex/scope.txt \
  --dry-run

bash .codex/scripts/check-doc-implementation.sh \
  --change-kind implementation-change \
  --scope-path path/to/changed-file.kt \
  --scope-path path/to/changed-test.kt \
  --dry-run \
  --json

bash .codex/scripts/check-doc-implementation.sh \
  --change-kind implementation-change \
  --scope-file build/codex/scope.txt \
  --dry-run \
  --json

bash .codex/scripts/check-doc-implementation.sh \
  --change-kind implementation-change \
  --scope-file build/codex/scope.txt \
  --run \
  --result-file docs/followup/active/.state/<task>-implementation.state
```

기본 실행과 `--dry-run`은 테스트 계획만 출력한다. `--run`일 때만 테스트를 실행하고 최종 게이트 결과를 저장한다.

단순 구현이나 단일 모듈 변경에서는 `--dry-run --json` 출력을 먼저 사용한다. JSON 출력의 `verification_floor`가 명확하면 script 본문이나 matrix 전문을 읽지 않고 해당 floor를 기준으로 검증한다. `UNCLASSIFIED`, 빈 floor, 다중 모듈, 루트 Gradle 변경, 계약 문서 변경, 검증 실패처럼 추가 판단이 필요한 경우에만 세부 config나 script 본문을 확인한다.

## 실패 재시도

```bash
bash .codex/scripts/verify-and-retry.sh \
  --failure-file docs/followup/active/.state/<task>-failed.state \
  --pass-state docs/followup/active/.state/<task>-previous-pass.state \
  --scope-file <scope> \
  --dry-run
```

- `--failure-file`은 최초 검증이 남긴 `FAIL` 결과 파일이어야 한다.
- `--pass-state`는 여러 번 전달할 수 있다.
- 수정 영향을 받지 않은 PASS는 `REUSED`, 영향받은 PASS는 `RECHECK`로 계획한다.
- `--dry-run`을 제거하면 `RECHECK` 대상과 실패 게이트만 실행한다.
- 최초 `FAIL` 파일은 보존하고 재시도 결과는 `<failure-file>.retry`에 저장한다.
- runbook 기록은 메인이 축을 확정한 뒤 `--runbook-approved <기존 파일>`을 명시한 경우에만 수행한다.
