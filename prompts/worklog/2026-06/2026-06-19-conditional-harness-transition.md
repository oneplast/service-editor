# 조건부 하네스 전환

## Step 1. 최상위 진입과 게이트 정책 정의

### 목적

- 강한 기본 하네스를 최소 컨텍스트 시작과 조건부 확장 구조로 전환하는 최상위 계약을 정의한다.

### 변경 내용

- `AGENTS.md`에 Direct, Scoped, Harness 작업 수준과 독립 게이트를 정의했다.
- 문서, prompts, `.codex` 보조 경로가 모든 작업에서 자동으로 열리지 않도록 진입 조건을 명시했다.
- 기존 전역 규칙과 각 README의 디렉토리 전용 규칙은 유지하고, 관련 경로에 진입할 때 적용하도록 경계를 고정했다.

### 판단

- `Harness`는 전체 파이프라인 실행 모드가 아니라 필요한 게이트를 조합할 수 있는 작업 수준으로 정의했다.
- prompts 기록은 현재 요구사항의 원본이 아니므로 기본 읽기 게이트를 `OFF`로 두었다.
- skill과 script의 구체 발동 조건 및 실행 로직은 후속 단계에서 조정한다.

### 검증

- `bash .codex/scripts/check-doc-governance.sh --scope-file docs/followup/active/conditional-harness-transition.scope --followup-file docs/followup/active/conditional-harness-transition.md`
- 문서 거버넌스 검증 PASS
- 스크립트 파일에 실행 권한이 없어 직접 실행은 실패했고, `bash` 실행으로 검증했다. 실행 진입 방식은 검증 스크립트 전환 단계에서 다시 확인한다.

## Step 2. 문서·복구 skill 활성화 조건 경량화

### 목적

- 문서 작업, 테스트, 검증이라는 이유만으로 followup과 runbook까지 선행 활성화되는 흐름을 제거한다.

### 변경 내용

- `docs-task-start`를 `docs-routing` 게이트가 활성화된 문서 생성·수정 작업으로 제한했다.
- followup은 여러 턴, 컨텍스트 압축, 복합 상태 복구 위험이 있을 때만 생성하도록 조건을 좁혔다.
- runbook은 정상 작업의 선행 문서가 아니라 실패, 반복 실수, 복구 신호가 확인된 뒤 읽도록 변경했다.
- 일반 문서 본문 정리는 `doc-governance-check` 활성화 대상에서 제외했다.

### 판단

- 기준 문서 수 자체는 followup 생성 근거로 사용하지 않는다.
- 테스트와 구현 검증 시작 자체는 runbook 활성화 근거로 사용하지 않는다.
- skill의 절차는 조건이 충족된 뒤에만 적용하고, 다른 skill과 script로 자동 연쇄하지 않는다.

### 검증

- `bash .codex/scripts/check-doc-governance.sh --scope-file docs/followup/active/conditional-harness-transition.scope --followup-file docs/followup/active/conditional-harness-transition.md`
- 문서 거버넌스 검증 PASS
- `bash .codex/scripts/check-doc-implementation.sh --scope-file docs/followup/active/conditional-harness-transition.scope --followup-file docs/followup/active/conditional-harness-transition.md`
- runbook 절차 변경 검토 안내와 자동 실행 테스트 없음 확인
- 이전 선행 로드 문구 검색 결과 없음
