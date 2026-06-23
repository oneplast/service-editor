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

## Step 3. 문서·구현 검증 게이트 판별 계약 분리

### 목적

- 변경 경로만으로 강한 문서 거버넌스나 전체 구현 검증을 확정하던 계약을 후보 탐지와 최종 판정으로 분리한다.

### 변경 내용

- 코드·설정 변경의 문서 영향을 `DOC_REQUIRED`, `DOC_NONE`, `DOC_UNDETERMINED`로 먼저 판정하는 게이트를 추가했다.
- `DOC_NONE`이면 문서 최신화를 위한 추가 읽기와 수정을 하지 않고, `DOC_REQUIRED`일 때만 필요한 공식 문서를 라우팅하도록 했다.
- 제품 문서 최신화용 `doc-update`와 문서 체계·규칙 검증용 `doc-governance`를 분리했다.
- 문서 변경을 `content-only`, `doc-governance-change`, `workflow-contract-change`, `workflow-implementation-change`, `repeated-error-case-update`로 구분했다.
- 구현 검증 변경을 `implementation-change`, `contract-change`, `non-contract-doc`, `verification-only`로 구분했다.
- 계약 문서 경로만으로 의미 변경을 확정할 수 없으면 전체 테스트 대신 `UNCLASSIFIED`로 남기는 기준을 추가했다.
- scope가 있으면 해당 범위를 우선하고 전체 worktree는 마지막 fallback으로 사용하는 계약을 config와 skill에 맞췄다.

### 판단

- 문서 영향 판정은 매번 문서 정합성을 확인하는 절차가 아니라, 문서 읽기·수정 게이트를 열지 결정하는 선행 절차다.
- `doc-impact`는 구현 요청과 diff로 문서 갱신 필요 여부를 판정하고, `DOC_REQUIRED`일 때 `docs-task-start`를 통해 `docs-routing`과 `doc-update`를 활성화한다.
- 초기 작업 수준과 `doc-impact`를 포함한 게이트 판정은 메인 에이전트가 소유하고, skill과 script는 확정된 입력을 재사용하도록 경계를 고정했다.
- 같은 목표와 scope에서 이미 읽었고 변경되지 않은 기준 문서는 재독하지 않고, 기준 변경·scope 변경·세션 복구 시에만 다시 확인하도록 했다.
- `doc-governance`는 `doc-impact` 판정이나 `doc-update` 활성화를 담당하지 않고, 문서 체계·규칙·workflow 계약 변경의 동반 문서와 규칙 정합성만 검증한다.
- 일반 반복 에러 사례 반영은 `runbook` 게이트 책임으로 남기고 `doc-governance-check`의 자동 검증 항목에서 제외했다.
- `implementation-check`는 문서 게이트를 실행하지 않고 구현 검증만 담당하도록 분리했다.
- 일반 runbook 사례 추가는 거버넌스 검증과 prompts 기록을 자동 요구하지 않고, 운영 계약 변경이나 의미 있는 프로젝트 기록 조건을 각각 만족할 때만 별도 게이트를 활성화하도록 했다.
- `docs-task-start`, `doc-governance-check`, `implementation-check`, `runbook-trigger`, `verification-retry`가 다른 독립 게이트를 직접 활성화하거나 변경 성격을 임의 확정하지 않고, 필요 신호 또는 `UNCLASSIFIED`를 메인에 반환하도록 통일했다.
- `UNCLASSIFIED`의 공통 반환 정보와 `최소 확인 -> 증분 재분류 -> 중단된 동일 게이트 재개` 계약을 별도 config 원본으로 정의했다.
- 문서 영향 결과의 미확정 값은 `DOC_UNDETERMINED`, 공통 게이트 상태는 `UNCLASSIFIED`로 분리했다.
- `DOC_REQUIRED`라도 제품 문서만 갱신하는 작업은 문서 체계 검증으로 자동 승격하지 않는다.
- 경로는 자동화가 찾을 수 있는 후보 신호이고, 의미 변경 여부는 사용자 요청과 diff를 확인한 메인 에이전트가 확정한다.
- `.codex` 내부 구현 수정은 workflow 계약이 바뀌지 않으면 최상위 문서 전체 최신화를 요구하지 않는다.
- 일반 구현·검증 결과는 worklog를 만들기 위한 prompts 게이트를 자동 활성화하지 않고, 이미 활성화된 같은 목표나 의미 있는 프로젝트 기록에만 남긴다.
- 최초 검증과 실패 재시도를 분리했다. 최초 검증은 한 번만 실행하고 `FAIL` 반환 정보로 실패 검증·입력·scope·실패 요약·재개 지점을 전달하며, 재시도는 원인 수정 뒤 실패한 동일 검증부터 재개한다.
- 실패 축 자동화는 runbook 경로 후보만 반환하고, 메인이 runbook 게이트와 실패 축을 확정한 뒤에만 실제 케이스를 기록하도록 경계를 고정했다.
- 실패 수정으로 입력이나 직접 의존 대상이 달라진 선행 `PASS`만 선택적으로 무효화하고, 영향 없는 `PASS`는 재사용하도록 계약을 보강했다. 영향 범위를 확정할 수 없을 때만 `UNCLASSIFIED`로 최소 확인한 뒤 검증 범위를 확대한다.
- script의 실제 옵션과 분기 동작은 4단계에서 구현한다.

### 검증

- `bash .codex/scripts/check-doc-governance.sh --scope-file docs/followup/active/conditional-harness-transition.scope --followup-file docs/followup/active/conditional-harness-transition.md --work-type doc-governance-change`
- 현재 스크립트가 새 `workflow-contract-change` 유형을 아직 지원하지 않아 기존 유형으로 과도기 문서 거버넌스 검증 PASS
- `bash .codex/scripts/check-doc-implementation.sh --scope-file docs/followup/active/conditional-harness-transition.scope --followup-file docs/followup/active/conditional-harness-transition.md`
- 구현 의미 변경 문서가 없어 구현 검증 불필요 확인
- `git diff --check` PASS
