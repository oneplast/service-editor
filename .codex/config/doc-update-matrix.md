# Document Update Matrix

이 문서는 공식 문서 변경 시 어떤 파일이 최신화 대상이고, 어떤 경로는 검증 대상에서 제외되는지 정의한다.

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

## 작업 유형별 갱신 기준

### 1. `doc-governance-change`

문서 체계, 규칙 소유 위치, README 계층, `.codex` 작업 절차를 바꾸는 작업이다.

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

### 2. `followup-policy-change`

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

### 3. `runbook-policy-change`

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

### 4. `prompt-governance-change`

`prompts/README.md`, topic 인덱스 기준, worklog 운영 기준을 바꾸는 작업이다.

- 필수:
  - `prompts/README.md`
- 조건부:
  - `prompts/topics/docs-and-prompt-governance.md`
  - `prompts/worklog/**`
  - `AGENTS.md`
- 제외:
  - `docs/learn/**`

### 5. `repeated-error-case-update`

같은 문제 축의 에러가 반복되어 기존 runbook 파일에 새 케이스를 추가하거나 기존 항목을 보강하는 작업이다.

- 필수:
  - 관련 runbook 파일
  - `prompts/worklog/**`
- 조건부:
  - `docs/runbook/README.md`
  - `.codex/skills/runbook-trigger/SKILL.md`
  - `prompts/topics/docs-and-prompt-governance.md`
- 제외:
  - `docs/learn/**`

## 구현 검증과의 경계

- 문서 최신화 검증은 이 문서와 `.codex/scripts/check-doc-governance.sh`가 담당한다.
- 코드 변경이나 구현 의미를 바꾸는 문서 변경이 있으면, 별도로 `.codex/config/doc-to-code-check-matrix.md`와 `.codex/scripts/check-doc-implementation.sh`를 따른다.
- 문서만 정리한 작업을 구현 검증 대상으로 과하게 올리지 않는다.

## 자동 검증이 하는 일

- 변경된 공식 문서 경로를 보고 작업 유형을 추정한다.
- 작업 유형에 따라 필수/조건부 최신화 대상을 다시 계산한다.
- 실제 변경 세트에 필요한 동반 문서가 빠졌는지 확인한다.
- `docs/learn/**`는 검증 대상에서 제외한다.
- 금지 참조 검사 제외 경로는 `.codex/config/doc-governance-search-excludes.txt`에서 읽는다.

## 자동 검증이 하지 않는 일

- 요구사항 변경이 실제로 있었는지 같은 의미론 판단
- discussion 이 필요한지 ADR 이 필요한지 최종 결정
- 문서 내용 자체의 품질 판단
- 같은 주제인지, 같은 결정인지의 의미론적 동일성 판단
- 반복 에러가 정말 같은 문제 축인지의 최종 판단

이 다섯 가지는 문서 규칙과 작업 맥락을 사람이 최종 확인해야 한다.
