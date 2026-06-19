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
