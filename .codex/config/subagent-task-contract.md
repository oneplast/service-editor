# Subagent Task Contract

이 문서는 subagent 게이트가 활성화됐을 때 메인 에이전트와 서브 에이전트의 역할, 입력 패킷, 출력 계약을 정의한다.

subagent는 기본값이 `OFF`다. 메인 에이전트가 기본 실행 주체이며, subagent는 역할별 상시 분업자가 아니라 선택적으로 호출하는 bounded capability다. 작업을 독립적인 bounded task로 나눌 수 있고, 추가 에이전트 호출로 생기는 중복 컨텍스트 비용보다 탐색·검증 이득이 클 때만 사용한다.

이 문서는 실제 플랫폼 등록이나 호출 절차를 정의하지 않는다. 호출 절차와 연결 방식은 후속 오케스트레이션 단계에서 별도로 다룬다.

## 기본 실행 모델

이 구조는 상시 분업 multi-agent가 아니라 main-owned selective subagent orchestration이다.

- 메인은 가능한 한 작은 충분 컨텍스트로 직접 작업한다.
- subagent는 단순 문서 읽기, 단일 파일 수정, 작은 검증 판단의 기본 실행자가 아니다.
- `Explorer`, `Worker`, `Doc Governance Reviewer`, `Verification Analyst`는 항상 실행되는 단계가 아니라 호출됐을 때의 책임을 제한하는 역할 이름이다.
- subagent 호출은 작업을 나누는 것이 아니라, 메인 컨텍스트를 보존하거나 독립 검토 이득이 호출 비용보다 클 때만 사용하는 선택지다.
- 서브가 전체 하네스나 전체 문서를 다시 읽어야만 수행 가능한 작업은 호출하지 않는다.

## 메인 에이전트가 소유하는 것

메인 에이전트는 아래 판단과 완료 책임을 서브 에이전트에 넘기지 않는다.

- 최초 작업 수준 판정
- 독립 게이트의 초기 ON/OFF 판정
- 사용자 소통과 확인 질문
- task packet 작성과 서브 호출 여부 결정
- 여러 서브 결과의 충돌 해소와 최종 통합
- `DOC_REQUIRED`, `DOC_NONE`, `DOC_UNDETERMINED` 판정
- `doc-governance-change`, `workflow-contract-change`, `implementation-change`, `contract-change` 같은 변경 성격 확정
- `REQUIREMENTS` 변경 여부, ADR 필요 여부, 새 runbook 축 분리 판단
- 최종 검증 선택과 완료 선언

서브 에이전트는 받은 packet 안에서만 탐색·수정·검토·분석을 수행하고, 범위를 넘는 판단은 메인에게 신호로 반환한다.

## 호출 금지 기본값

아래 경우에는 subagent를 호출하지 않는다.

- `Direct` 작업
- 단일 파일 설명, 단순 상태 확인, 짧은 문구 수정
- 단일 문서나 특정 섹션만 읽으면 충분한 작업
- 메인이 이미 필요한 컨텍스트를 충분히 갖고 있고 결과 통합 비용이 더 큰 작업
- task packet 없이 넓은 저장소 탐색을 맡겨야 하는 경우
- 서브가 전체 하네스, README, skill, script, runbook을 다시 읽어야만 수행 가능한 경우
- 메인이 아직 작업 수준이나 게이트를 확정하지 못한 경우
- 같은 정보를 메인과 서브가 모두 읽게 되어 토큰 비용이 이득보다 큰 경우

애매하면 subagent를 호출하지 않고 메인이 `Scoped`로 진행한다.

## 호출 가능 조건

아래 조건을 모두 만족할 때만 subagent 호출을 고려한다.

1. task가 독립적으로 끝나는 bounded task다.
2. 입력 파일, 허용 경로, 금지 경로가 명확하다.
3. 기대 출력이 짧은 요약, diff 후보, 검증 결과, 위험 신호처럼 통합 가능한 형태다.
4. 서브가 새 전역 규칙이나 전체 하네스를 읽지 않아도 된다.
5. 서브 결과를 메인이 검토한 뒤 최종 판단할 수 있다.

## 역할 후보

### Explorer

목적:

- 메인이 아직 직접 읽지 않은 넓은 후보 범위에서 관련 파일, 기존 패턴, 위험 후보를 찾아 짧은 후보 목록으로 줄인다.
- 단일 문서나 특정 섹션을 대신 읽고 요약하는 역할이 아니다.

권한:

- 지정된 `allowed_reads` 안에서 후보 탐색만 수행한다.
- 코드를 수정하지 않는다.
- 검증 명령을 실행하지 않는다.
- 메인이 이미 읽은 문서를 다시 읽지 않는다.
- 전체 README, 전체 skill, 전체 runbook을 읽어야 하면 진행하지 않고 `UNCLASSIFIED`를 반환한다.

출력:

- 관련 후보 파일과 후보 이유
- 제외한 후보와 제외 이유
- 발견한 관련 패턴 또는 위험 신호
- 메인이 다음에 직접 확인해야 할 최소 파일·섹션
- 불확실한 지점과 최소 추가 확인 대상

### Worker

목적:

- 메인이 지정한 파일과 제약 안에서 국소 구현 또는 문서 수정을 수행한다.

권한:

- packet의 허용 경로만 수정한다.
- 지정되지 않은 요구사항, 외부 계약, 문서 체계는 바꾸지 않는다.
- 새 파일 생성은 packet에 허용된 경우에만 수행한다.

출력:

- 변경 요약
- 수정 파일 목록
- 가정과 제한
- 필요한 검증 후보
- 메인이 확인해야 할 위험 신호

### Doc Governance Reviewer

목적:

- 문서 체계·규칙·workflow 계약 변경이 메인이 확정한 scope 안에서 서로 충돌하지 않는지 검토한다.

권한:

- 메인이 지정한 README, config, skill, runbook, worklog만 확인한다.
- `doc-impact`를 다시 판정하지 않는다.
- `doc-update` 또는 `doc-governance`를 직접 활성화하지 않는다.

출력:

- 누락된 동반 문서 후보
- 중복 규칙 후보
- 상위/하위 소유 위치 충돌
- `UNCLASSIFIED`가 필요한 최소 확인 대상

### Verification Analyst

목적:

- 실패 결과, PASS state, scope를 보고 재검증 범위와 retry 후보를 분석한다.

권한:

- 실패 파일과 지정된 PASS state를 읽는다.
- 지정된 dry-run이나 읽기 전용 분석만 수행한다.
- 실패 축과 runbook 기록 여부를 확정하지 않는다.

출력:

- 재사용 가능한 PASS 후보
- 재검증해야 하는 PASS 후보
- 실패한 동일 검증 재개 지점
- `UNCLASSIFIED`가 필요한 영향 범위

## Task packet 필드

메인은 서브를 호출할 때 아래 필드 중 필요한 최소만 전달한다.

```text
task_id:
role:
goal:
why_subagent:
work_level:
active_gates:
scope_files:
allowed_paths:
blocked_paths:
context_facts:
quoted_extracts:
allowed_reads:
blocked_reads:
state_refs:
known_constraints:
change_kind:
doc_impact:
must_not_reclassify:
allowed_commands:
expected_output:
stop_conditions:
handoff_format:
```

필드 기준:

- `context_facts`에는 메인이 확정했고 서브가 다시 판정하지 않아야 하는 사실만 넣는다.
- `quoted_extracts`에는 서브가 정확성을 위해 봐야 하는 짧은 원문 발췌만 넣는다.
- `allowed_reads`에는 서브가 직접 읽어도 되는 파일이나 섹션만 넣는다.
- `blocked_reads`에는 읽으면 안 되는 범위를 명시한다.
- `state_refs`에는 재사용할 실패 결과, PASS state, scope 파일만 넣는다.
- 전체 README, 전체 skill, 전체 runbook은 기본 전달하거나 읽게 하지 않는다.
- `allowed_commands`가 비어 있으면 서브는 명령을 실행하지 않는다.
- `change_kind`와 `doc_impact`가 미확정이면 서브가 확정하지 않고 `UNCLASSIFIED` 신호를 반환한다.
- `must_not_reclassify`에는 서브가 반복 판정하면 안 되는 작업 수준, 게이트, 문서 영향, 변경 성격을 넣는다.
- `stop_conditions`에는 범위 밖 파일 발견, 계약 변경 필요, 실패 축 불명확, 사용자 결정 필요 같은 중단 조건을 넣는다.

## 출력 계약

서브 결과는 메인이 바로 통합할 수 있게 아래 형식을 우선한다.

```text
status: PASS | FAIL | UNCLASSIFIED
summary:
files_read:
files_changed:
commands_run:
candidate_files:
excluded_candidates:
findings:
risks:
needs_main_decision:
minimum_next_check:
```

`files_read`는 추적용 메타데이터다. 메인이 다시 읽어야 하는 목록이 아니다. 메인이 직접 확인할 대상은 `minimum_next_check`와 `candidate_files`에서 필요한 최소 범위로 제한한다.

서브의 `PASS`는 해당 bounded task가 packet 안에서 끝났다는 뜻이다. 전체 작업 완료나 최종 검증 완료를 뜻하지 않는다.

서브의 `FAIL`은 packet 안에서 수행한 작업 또는 검증이 실패했다는 뜻이다. 메인이 실패 정보를 받아 `verification-retry`와 `runbook` 게이트를 각각 판정한다.

서브의 `UNCLASSIFIED`는 packet 입력만으로 안전하게 판단할 수 없다는 뜻이다. 메인은 `minimum_next_check`만 확인한 뒤 같은 task의 재개 여부를 결정한다.

## 금지 사항

- 서브가 최초 작업 수준과 독립 게이트를 다시 판정하지 않는다.
- 서브가 메인 승인 없이 `REQUIREMENTS`, ADR, 새 runbook 축, 외부 계약을 확정하지 않는다.
- 서브가 관련 없는 README, skill, script, runbook, prompts를 넓게 읽지 않는다.
- 서브가 `allowed_reads` 밖 문서를 임의로 열어 부족한 context를 보충하지 않는다. 필요한 경우 `UNCLASSIFIED`와 최소 확인 대상을 반환한다.
- 서브가 다른 서브를 호출하지 않는다.
- 서브 결과를 메인이 검토하지 않고 최종 완료로 선언하지 않는다.
- `skill = subagent` 또는 `script = subagent`처럼 1:1로 매핑하지 않는다.
- 토큰 절약 근거가 불명확한 작업에 subagent를 관성적으로 호출하지 않는다.
