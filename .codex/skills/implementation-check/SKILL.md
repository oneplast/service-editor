---
name: "implementation-check"
description: "코드 변경이나 계약 문서 변경 시 필요한 구현 검증 범위를 판단하고 관련 테스트를 실행하는 절차."
---

# Implementation Check

이 skill은 코드 변경이나 구현 의미를 바꾸는 문서 변경이 있을 때, 어떤 구현 검증이 필요한지 판단하고 관련 Gradle 테스트를 실행하는 절차다.

코드·설정 변경의 `doc-impact`, `doc-update`, `doc-governance`는 메인 에이전트가 별도 게이트로 관리한다. 이 skill은 해당 상태를 참고할 수 있지만 문서 게이트를 판정하거나 실행하지 않고 구현 검증만 담당한다.

## 사용할 때

- 제품 코드나 테스트 코드를 수정한 작업
- `docs/REQUIREMENTS.md`, `docs/guides/**`, `docs/decisions/**`를 바꿔 실제 기대 동작이나 계약이 달라진 작업
- 실제 명령, 엔드포인트, 설정 키, 기대 결과가 바뀐 `docs/runbook/**` 작업

## 절차

1. 가능하면 현재 작업 파일 목록을 고정한다. 짧은 범위는 `--scope-path <path>`를 반복해서 넘기고, 이미 scope 파일이 있거나 다음 세션 복구에 같은 입력 파일이 필요하면 `--scope-file <scope>`을 넘긴다. `--scope-file`에는 작업 파일 목록을 담은 실제 파일 경로를 넘긴다. process substitution, `/dev/fd/*`, stdin 대체 입력은 재현 가능한 scope 파일로 보지 않는다.
2. 메인 에이전트가 확정한 구현 변경 성격이 `implementation-change`, `contract-change`, `non-contract-doc`, `verification-only` 중 무엇인지 확인한다.
3. 단순 구현이나 단일 모듈 변경에서는 먼저 `.codex/scripts/check-doc-implementation.sh --change-kind <kind> <scope 입력> --dry-run --json`으로 검증 계획만 받는다.
4. JSON 결과가 `PASS`이고 `verification_floor`가 명확하면 그 출력만 기준으로 검증 floor를 정한다. 이때 matrix나 script 본문을 추가로 읽지 않는다.
5. JSON 결과가 `UNCLASSIFIED`, `FAIL`, 빈 floor, 여러 모듈/루트 설정 변경, 계약 문서 변경, 실패 재시도, scope 불명확 상태이면 그때만 `.codex/config/doc-to-code-check-matrix.md`와 필요한 script 본문을 확인한다.
6. followup 파일이 있으면 `현재 상태`의 `검증 단계`를 확인한다. `진행 중`이면 필요한 컴파일, 좁은 테스트, sanity check만 고른다.
7. scope 파일 경로만으로 followup 연결이 어려우면 `--followup-file <path>`를 함께 넘긴다.
8. 구현 검증 대상이 `검증 대기` 단계에 들어가면 `--run --result-file docs/followup/active/.state/<task>-implementation.state`로 선택한 구현 검증을 최초 한 번 실행한다.
9. `PASS`이면 구현 검증 게이트를 닫고, `FAIL`이면 `.codex/config/gate-state-contract.md`의 실패 정보를 메인 에이전트에 반환한다. 이 skill에서 `verification-retry`나 `runbook`을 직접 활성화하지 않는다.
10. 더 좁은 테스트가 부족하거나 여러 모듈이 얽히면 matrix의 전체 테스트 기준까지 올린다.
11. 같은 목표의 worklog가 이미 활성화됐거나 팀·프로젝트 단위의 의미 있는 기록이 필요한 작업에서만 검증 결과를 해당 Step에 짧게 남긴다.

## 자동 판별 기준

- 코드 경로 변경 -> `implementation-change` 또는 `verification-only` 후보
- 계약 문서 경로 변경 -> `contract-change` 또는 `non-contract-doc` 검토
- 단순 표현 정리, 링크 수정, 인덱스 문서 변경 -> `non-contract-doc`

## 하지 말 것

- 문서 정리만 한 작업에 무조건 전체 테스트를 강제하지 않는다.
- 이 skill 안에서 `doc-impact`를 다시 판정하거나 `docs-task-start`, `doc-update`, `doc-governance-check`를 실행하지 않는다.
- 계약 문서 경로만으로 `contract-change`를 확정하지 않는다.
- 메인이 확정하지 않은 구현 변경 성격을 이 skill에서 임의로 확정하지 않는다.
- 최초 검증 전에 `verify-and-retry`를 실행하거나 실패 확인을 위해 같은 검증을 중복 실행하지 않는다.
- 재분류가 끝나면 중단된 이 skill 절차부터 재개하고, 문서 게이트나 앞선 판정을 반복하지 않는다.
- 일반 구현·검증 결과를 남기기 위해 prompts 게이트를 자동 활성화하지 않는다.
- 코드 변경이 있는데 문서 거버넌스 검증만 통과했다고 끝내지 않는다.
- 자동 판별만으로 충분하다고 보고 최종 테스트 범위 판단을 생략하지 않는다.
- 단순 구현의 검증 계획 확인만을 위해 matrix와 script 본문을 먼저 읽지 않는다. 구조화된 dry-run 출력으로 부족할 때만 세부 원본을 확인한다.
