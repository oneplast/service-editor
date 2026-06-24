---
name: "subagent-orchestration"
description: "subagent 게이트가 활성화됐을 때 선택적 호출 여부, task packet 작성, 병렬 조건, 결과 통합을 관리하는 절차."
---

# Subagent Orchestration

이 skill은 subagent 게이트가 활성화됐을 때만 사용한다. subagent는 역할별 상시 분업자가 아니라, 메인이 직접 처리하는 것보다 탐색·검토·병렬화 이득이 큰 bounded task에만 선택적으로 호출하는 capability다.

## 사용할 때

- 작업이 `Harness` 수준이고 독립적인 bounded task로 분리할 수 있을 때
- 넓은 후보 탐색을 짧은 후보 목록으로 줄이는 것이 메인 컨텍스트 절약에 도움이 될 때
- 수정 권한이 없는 독립 리뷰가 누락이나 충돌을 줄일 때
- 실패 state와 PASS state 분석이 구현 수정과 분리될 때
- 병렬 읽기·분석 task가 서로 의존하지 않고 결과 통합 기준이 명확할 때

아래 경우에는 사용하지 않는다.

- `Direct` 작업
- 일반 `Scoped` 작업
- 단일 문서나 특정 섹션을 읽으면 충분한 작업
- 단일 파일 수정
- 메인이 이미 필요한 컨텍스트를 갖고 있는 작업
- 서브가 전체 하네스, README, skill, script, runbook을 다시 읽어야 하는 작업

## 절차

1. 메인이 작업 수준과 독립 게이트 상태를 먼저 확정한다.
2. `.codex/config/subagent-task-contract.md`의 호출 금지 기본값과 호출 가능 조건을 확인한다.
3. subagent 호출 이득이 불명확하면 호출하지 않고 메인이 계속 진행한다.
4. 호출이 필요하면 role을 하나 고르고 task packet을 작성한다.
5. packet에는 `context_facts`, `quoted_extracts`, `allowed_reads`, `blocked_reads`, `state_refs`, `must_not_reclassify`를 분리해 넣는다.
6. 서브가 파일 본문을 직접 읽어야 하면 `allowed_reads`와 함께 read-only `allowed_commands`를 명시하거나, 메인이 필요한 짧은 원문을 `quoted_extracts`로 전달한다.
7. `allowed_reads`, `allowed_paths`, `allowed_commands`를 비워 두면 해당 행위는 금지로 해석한다.
8. 병렬 호출은 서로 독립적인 읽기·분석 task에만 허용한다. Worker의 수정 범위가 겹치면 병렬 호출하지 않는다.
9. 서브 결과의 `status`, `base_revision`, `scope_fingerprint`, `files_changed`, `minimum_next_check`를 확인한다.
10. `PASS`는 bounded task 완료로만 해석하고, 전체 작업 완료는 메인이 별도 검증 뒤 선언한다.
11. `FAIL`이나 `UNCLASSIFIED`는 메인이 필요한 게이트만 증분 판정하고, 전체 하네스를 처음부터 반복하지 않는다.

## Role별 packet 주의점

### Explorer

- `allowed_reads`는 후보 탐색 범위다.
- 메인이 이미 읽은 문서를 다시 읽히지 않는다.
- 출력은 `candidate_files`, `excluded_candidates`, `minimum_next_check` 중심으로 받는다.
- `files_read`는 추적용이며 메인이 다시 읽을 목록이 아니다.

### Worker

- `allowed_paths`를 명확히 지정한다.
- 병렬 Worker는 수정 경로가 겹치면 안 된다.
- 지정되지 않은 요구사항, ADR, 외부 계약, 새 runbook 축을 확정하지 않는다.
- 수정 결과는 메인이 diff를 검토한 뒤 통합한다.

### Doc Governance Reviewer

- 메인이 확정한 문서 체계 또는 workflow 계약 변경 scope만 검토한다.
- `doc-impact`, `doc-update`, `doc-governance` 활성화 여부를 다시 판정하지 않는다.
- 누락 후보, 중복 규칙, 소유 위치 충돌만 반환한다.

### Verification Analyst

- 실패 state와 PASS state를 읽어 재사용·재검증 후보를 분석한다.
- 실패 축과 runbook 기록 여부를 확정하지 않는다.
- 실제 재검증 실행은 메인이 관련 검증 게이트와 script로 연결한다.

## 하지 말 것

- subagent를 역할별 기본 실행 단계처럼 호출하지 않는다.
- 같은 문서나 파일을 메인과 서브가 관성적으로 중복 읽지 않는다.
- task packet 없이 넓은 저장소 탐색을 맡기지 않는다.
- 서브가 `allowed_reads` 밖 자료를 임의로 읽어 context를 보충하게 하지 않는다.
- 서브 결과를 메인 검토 없이 최종 완료로 처리하지 않는다.
- 병렬 호출을 속도 최적화만 보고 선택하지 않는다. 중복 context 비용과 통합 비용을 함께 본다.
