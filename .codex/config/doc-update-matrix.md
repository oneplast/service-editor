# Document Update Matrix

이 문서는 코드·설정 변경의 문서 영향 판정, 영향받는 공식 문서 갱신, 문서 체계·규칙 변경의 거버넌스 검증 기준을 정의한다.

## 판별 계약

문서 경로와 변경 성격을 분리해서 판단한다.

1. 코드나 설정 변경에서는 문서를 읽기 전에 문서 영향 여부를 먼저 판정한다.
2. 문서 변경 경로는 가능한 작업 유형과 확인 대상을 찾는 후보 신호다.
3. 변경 성격은 `doc-update` 또는 `doc-governance` 게이트를 활성화하는 최종 입력이다.
4. 경로만으로 변경 성격을 확정할 수 없으면 전체 동반 문서를 강제하지 않고 `UNCLASSIFIED`로 남긴다.
5. 최종 판정은 사용자 요청, diff, 현재 공식 규칙을 확인한 메인 에이전트가 확정한다.

### 역할 경계

- `doc-impact`
  - 코드·설정 변경 뒤 메인 에이전트가 문서 갱신 필요 여부를 `DOC_REQUIRED`, `DOC_NONE`, `DOC_UNDETERMINED`로 판정한다.
  - 사용자 요청과 diff를 우선하며, `DOC_UNDETERMINED`일 때만 직접 관련된 공식 문서 후보를 최소 확인한다.
- `docs-routing`
  - 직접 문서 수정 요청이거나 `DOC_REQUIRED`일 때 `docs/README.md`와 대상 경로 README로 갱신 대상을 찾는다.
- `doc-update`
  - `docs-routing`이 찾은 영향 문서만 읽고 갱신한다.
  - 제품 요구사항·계약 문서 갱신만으로 `doc-governance`를 자동 활성화하지 않는다.
- `doc-governance`
  - 문서 체계, 규칙 소유 위치, README, 템플릿, 문서 작업 절차, workflow 계약 변경의 동반 문서와 규칙 정합성만 검증한다.
  - `doc-impact`를 판정하거나 `doc-update`를 활성화하지 않는다.

### 문서 영향 게이트

코드, 설정, 자동화 변경이 공식 문서 갱신을 요구하는지 아래 상태로 판정한다.

- `DOC_REQUIRED`
  - 제품 요구사항, 외부 계약, 채택 정책, API 요청·응답·에러, 인증·권한, 설정 키, 실행 명령, 모듈 경계, 작업 절차, 기대 결과가 바뀐다.
  - 이때만 `docs-routing` 게이트를 활성화하고 `docs/README.md`에서 필요한 공식 문서 경로를 찾는다.
  - 관련 문서 전체가 아니라 영향받는 문서만 읽고 갱신한다.
- `DOC_NONE`
  - 현재 요구사항과 계약 안의 버그 수정, 동작 변경 없는 리팩터링, 테스트·fixture 보강, 죽은 코드 제거, 내부 구현 세부 조정이다.
  - 문서 갱신을 위해 `docs/README.md`, REQUIREMENTS, guide, ADR, worklog를 추가로 읽지 않는다.
- `DOC_UNDETERMINED`
  - 사용자 요청과 diff만으로 문서 영향 여부를 확정할 수 없다.
  - 문서 갱신 불필요로 간주하지 않고 완료를 보류한다.
  - 변경 영역과 직접 연결된 공식 문서 후보만 최소 확인한 뒤 `DOC_REQUIRED` 또는 `DOC_NONE`으로 확정한다.

`DOC_UNDETERMINED`는 문서 영향 결과값이고, 공통 게이트 상태인 `UNCLASSIFIED`와 다른 값이다. `DOC_UNDETERMINED`인 동안 `doc-impact` 게이트는 완료되지 않은 상태이며, 최소 확인 후 문서 영향 결과를 확정하고 중단된 `doc-impact` 흐름부터 재개한다.

문서 영향 판정은 문서 정합성을 매번 확인하는 절차가 아니다. 문서 읽기·수정 게이트 자체를 열지 결정하는 선행 절차다.

`DOC_REQUIRED`는 `doc-update` 게이트를 활성화한다. 문서 체계, 규칙 소유 위치, README, 템플릿, workflow 계약까지 바뀌지 않으면 `doc-governance` 게이트를 자동 활성화하지 않는다.

### 문서 영향 판별 순서

1. 사용자 요청에 제품 동작, 계약, 정책 변경이 명시됐는지 확인한다.
2. 코드·설정 diff에서 외부에 관찰 가능한 동작과 문서화된 작업 절차가 달라지는지 확인한다.
3. 명확하면 `DOC_REQUIRED` 또는 `DOC_NONE`으로 확정한다.
4. 불명확할 때만 관련 공식 문서 후보를 최소 범위로 확인한다.
5. `DOC_REQUIRED`일 때만 문서 경로를 라우팅하고 필요한 문서를 갱신한다.

### 변경 성격

- `content-only`
  - 오타, 표현, 링크, 예시, 인덱스, 현재 정책을 바꾸지 않는 본문 정리
  - 대상 경로 README 규칙은 적용하지만 문서 거버넌스 게이트는 활성화하지 않는다.
- `doc-governance-change`
  - 문서 체계, 경로 분류, 규칙 소유 위치, README 계층, 템플릿 구조를 바꾸는 변경
  - 메인 에이전트가 문서 거버넌스 게이트를 활성화한다.
- `workflow-contract-change`
  - skill 활성화 조건, config 판별 계약, script 입출력·실행 게이트, followup·runbook·prompts 운영 경계를 바꾸는 변경
  - 메인 에이전트가 문서 거버넌스 게이트를 활성화한다.
- `workflow-implementation-change`
  - 이미 채택된 계약 안에서 script 버그, 내부 구현, 메시지, 성능만 바꾸는 변경
  - `.codex` 경로라는 이유만으로 `doc-governance-change`로 승격하지 않는다. 관련 자동 검증만 선택한다.
- `repeated-error-case-update`
  - 기존 실패 축의 runbook 사례를 추가하거나 보강하는 변경
  - 해당 runbook만 필수로 갱신하고, 작업 기록과 거버넌스 검증은 각 게이트 조건을 별도로 판정한다.

### 판별 우선순위

1. 명시적으로 전달된 문서 영향과 변경 성격
2. 현재 scope의 diff와 사용자 요청으로 확정한 문서 영향과 변경 성격
3. 경로 기반 후보 탐지
4. 변경 성격을 확정할 수 없으면 `UNCLASSIFIED`

scope 파일이 있으면 해당 파일 목록만 후보 탐지에 사용한다. scope가 없을 때만 `git status` 전체를 마지막 fallback으로 사용한다.

## 공식 검증 범위

- `AGENTS.md`
- `docs/README.md`
- `docs/REQUIREMENTS.md`
- `docs/discussions/**`
- `docs/decisions/**`
- `docs/runbook/**`
- `docs/roadmap/**`
- `docs/explainers/**`
- `docs/guides/**`
- `docs/followup/**`
- `prompts/README.md`
- `prompts/topics/**`
- `prompts/worklog/**`
- `.codex/README.md`
- `.codex/skills/**`
- `.codex/scripts/**`
- `.codex/config/**`

## 공식 검증 제외 범위

- `docs/learn/**`
- `docs/followup/active/.gitkeep`

`docs/learn/`는 로컬 학습 문서 경로이므로, 공식 문서 최신화 검증 대상에 포함하지 않는다.
금지 참조 검사에서 제외할 경로 glob 원본은 `.codex/config/doc-governance-search-excludes.txt`로 관리한다.
여기의 `공식 검증 제외 범위`는 변경 세트와 동반 문서 누락 검사를 위한 기준이고, `doc-governance-search-excludes.txt`는 문자열 기반 금지 참조 검사 범위를 줄이기 위한 검색 제외 glob 기준이다.
두 기준은 현재 일부 경로가 같을 수 있지만, 역할이 다르므로 항상 같은 목록이라고 가정하지 않는다.

## 편집 모드

### 1. `correct_in_place`

기존 잘못된 내용을 직접 고쳐 현재 기준이 한 번에 읽히게 유지하는 모드다.

- 대상:
  - `AGENTS.md`
  - `docs/README.md`
  - `docs/REQUIREMENTS.md`
  - 각 디렉토리 `README.md`
  - `docs/guides/**`
  - `docs/explainers/**`
  - `docs/runbook/**`
- 원칙:
  - 새 Step이나 장기 이력을 문서 본문에 누적하지 않는다.
  - 기존 관련 섹션을 직접 수정해 최신 기준을 반영한다.

### 2. `topic_scoped_correction`

하나의 주제는 한 파일로 유지하되, 같은 주제의 후속 내용은 기존 파일을 보강하는 모드다.

- 대상:
  - `docs/discussions/**`
  - `docs/roadmap/**`
  - `prompts/topics/**`
- 원칙:
  - 같은 주제면 새 파일을 늘리기보다 기존 파일을 보강한다.
  - 다만 topic 문서는 인덱스 역할만 유지하고, 절차형 장문 내용은 다른 공식 문서로 옮긴다.

### 3. `decision_scoped_file`

결정 하나당 한 파일을 유지하는 모드다.

- 대상:
  - `docs/decisions/**`
- 원칙:
  - 같은 결정 문서의 표현 보정이나 링크 보강은 기존 파일을 수정한다.
  - 새로운 결정이나 정책 전환이면 새 ADR 파일을 추가한다.

### 4. `goal_scoped_log`

하나의 사용자 목표는 한 로그 파일로 유지하고 Step을 누적하는 모드다.

- 대상:
  - `prompts/worklog/**`
- 원칙:
  - 같은 목표의 후속 구현, 검증, 문서 보강은 기존 파일에 Step으로 누적한다.
  - 단순 사실 기록 경로이므로 기존 Step을 무리하게 현재 기준 문서처럼 다시 쓰지 않는다.

### 5. `rewrite_snapshot`

현재 상태만 남기고 계속 다시 쓰는 스냅샷 모드다.

- 대상:
  - `docs/followup/active/**`
- 원칙:
  - 진행 중 작업의 현재 상태만 남긴다.
  - 완료 항목과 오래된 상태는 지우고 최신 복구 정보만 유지한다.

### 6. `local_excluded`

공식 문서 최신화 검증 대상에서 제외하는 모드다.

- 대상:
  - `docs/learn/**`
- 원칙:
  - 로컬 학습 문서이므로 공식 문서 누락 검증과 연결하지 않는다.

## 게이트별 갱신 기준

### 1. `doc-governance-change`

문서 체계, 규칙 소유 위치, README 계층, 템플릿 구조를 바꾸는 작업이다.

- 필수:
  - `AGENTS.md`
  - `docs/README.md`
  - `prompts/topics/docs-and-prompt-governance.md`
  - `prompts/worklog/**`
- 조건부:
  - `docs/followup/README.md`
  - `docs/runbook/README.md`
  - `.codex/README.md`
  - `.codex/skills/**`
  - `.codex/scripts/**`
  - `.codex/config/**`
- 제외:
  - `docs/learn/**`

### 2. `workflow-contract-change`

skill 활성화 조건, config 판별 계약, script 입출력·실행 게이트를 바꾸는 작업이다.

- 필수:
  - 변경한 `.codex` 원본 파일
  - `.codex/README.md`
  - `prompts/topics/docs-and-prompt-governance.md`
  - `prompts/worklog/**`
- 조건부:
  - 최상위 진입 규칙이 바뀌면 `AGENTS.md`
  - 문서 전역 라우팅이 바뀌면 `docs/README.md`
  - followup 운영 경계가 바뀌면 `docs/followup/README.md`
  - runbook 운영 경계가 바뀌면 `docs/runbook/README.md`
- 제외:
  - 직접 영향이 없는 README와 template
  - `docs/learn/**`

### 3. `workflow-implementation-change`

채택된 workflow 계약을 유지한 채 script 내부 구현, 오류 메시지, 성능, 국소 버그를 바꾸는 작업이다.

- 필수:
  - 변경한 script 또는 보조 파일
- 조건부:
  - 사용법이나 입출력 계약이 바뀌면 `.codex/README.md`와 관련 skill/config
  - 재현 가능한 동작 검증이 있으면 관련 fixture 또는 테스트
- 제외:
  - 계약 변화가 없는 경우 `AGENTS.md`, `docs/README.md`, governance topic의 강제 최신화
  - `docs/learn/**`

### 4. `followup-policy-change`

세션 복구, active 정리 기준, followup 템플릿을 바꾸는 작업이다.

- 필수:
  - `docs/followup/README.md`
- 조건부:
  - `AGENTS.md`
  - `.codex/skills/followup-handoff/SKILL.md`
  - `prompts/topics/docs-and-prompt-governance.md`
  - `prompts/worklog/**`
- 제외:
  - `docs/learn/**`

### 5. `runbook-policy-change`

runbook 선택 기준, 반복 실수 복구 절차, 운영 점검 기준을 바꾸는 작업이다.

- 필수:
  - `docs/runbook/README.md`
  - 해당 runbook 파일
- 조건부:
  - `.codex/skills/runbook-trigger/SKILL.md`
  - `prompts/topics/docs-and-prompt-governance.md`
  - `prompts/worklog/**`
- 제외:
  - `docs/learn/**`

### 6. `prompt-governance-change`

`prompts/README.md`, topic 인덱스 기준, worklog 운영 기준을 바꾸는 작업이다.

- 필수:
  - `prompts/README.md`
- 조건부:
  - `prompts/topics/docs-and-prompt-governance.md`
  - `prompts/worklog/**`
  - `AGENTS.md`
- 제외:
  - `docs/learn/**`

### 7. `repeated-error-case-update`

같은 문제 축의 에러가 반복되어 기존 runbook 파일에 새 케이스를 추가하거나 기존 항목을 보강하는 작업이다.

- 필수:
  - 관련 runbook 파일
- 조건부:
  - 같은 목표의 worklog가 이미 활성화됐거나 팀·프로젝트 단위의 의미 있는 기록이면 `prompts/worklog/**`
  - `docs/runbook/README.md`
  - `.codex/skills/runbook-trigger/SKILL.md`
  - `prompts/topics/docs-and-prompt-governance.md`
  - runbook 체계·운영 규칙·workflow 계약이 바뀌면 `doc-governance`
- 제외:
  - `docs/learn/**`

## 구현 검증과의 경계

- 이 문서는 `doc-impact` 판정과 `doc-update` 대상 기준을 제공하고, 메인 에이전트가 사용자 요청과 scope·diff를 기준으로 상태를 확정한다.
- `implementation-check`는 문서 영향 상태를 판정하거나 문서 게이트를 실행하지 않는다. 메인 에이전트가 문서 게이트와 구현 검증 결과를 독립적으로 닫고 최종 완료 상태를 통합한다.
- 코드·설정 변경에서 `DOC_NONE`이면 문서 최신화 게이트를 활성화하지 않는다.
- `DOC_REQUIRED`이면 `docs-task-start` 절차로 영향받는 공식 문서만 갱신한다.
- `DOC_REQUIRED`라도 문서 체계·규칙 변경이 아니면 `doc-governance-change`로 승격하지 않는다.
- `.codex/scripts/check-doc-governance.sh`는 문서 체계·규칙·workflow 계약 변경의 동반 문서 누락과 거버넌스 정합성만 검증한다.
- 일반 제품 문서 갱신의 완료 여부는 대상 diff와 경로 규칙을 대조하고, 구현 의미가 바뀌었다면 구현 검증으로 함께 닫는다.
- 코드 변경이나 구현 의미를 바꾸는 문서 변경이 있으면, 별도로 `.codex/config/doc-to-code-check-matrix.md`와 `.codex/scripts/check-doc-implementation.sh`를 따른다.
- 문서만 정리한 작업을 구현 검증 대상으로 과하게 올리지 않는다.

## 자동 검증이 하는 일

- 변경된 공식 문서 경로를 보고 가능한 작업 유형 후보를 탐지한다.
- 명시된 변경 성격이 있으면 해당 게이트의 필수/조건부 최신화 대상을 계산한다.
- 실제 변경 세트에 필요한 동반 문서가 빠졌는지 확인한다.
- `docs/learn/**`는 검증 대상에서 제외한다.
- 금지 참조 검사 제외 경로는 `.codex/config/doc-governance-search-excludes.txt`에서 읽는다.

## 자동 검증이 하지 않는 일

- 요구사항 변경이 실제로 있었는지 같은 의미론 판단
- discussion 이 필요한지 ADR 이 필요한지 최종 결정
- 문서 내용 자체의 품질 판단
- 같은 주제인지, 같은 결정인지의 의미론적 동일성 판단
- 반복 에러가 정말 같은 문제 축인지의 최종 판단
- 경로 후보만으로 `content-only`, `workflow-contract-change`, `workflow-implementation-change`를 최종 확정하는 일

이 여섯 가지는 문서 규칙과 작업 맥락을 메인 에이전트 또는 사람이 최종 확인해야 한다.
