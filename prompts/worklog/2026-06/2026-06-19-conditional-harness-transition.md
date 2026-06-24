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

## Step 4. 검증 스크립트 독립 조건부 게이트 전환

### 목적

- 3단계에서 정의한 게이트 판별과 재개 계약을 실제 shell script 입력·출력과 실행 흐름에 반영한다.

### 변경 내용

- 문서 거버넌스와 구현 검증 script가 메인이 확정한 `--change-kind`와 scope를 별도 입력으로 받도록 변경했다.
- 후보 경로가 있지만 변경 성격이 없으면 경로로 자동 확정하지 않고 `UNCLASSIFIED`를 반환하도록 했다.
- 구현 검증의 계획 확인과 실제 테스트 실행을 `--dry-run`, `--run`으로 분리했다.
- 게이트 결과를 `docs/followup/active/.state/`에 저장하고 직접 의존 파일 해시와 경로 패턴으로 PASS 재사용 여부를 판정하도록 했다.
- `verify-and-retry`가 최초 검증을 다시 실행하거나 두 게이트를 일괄 실행하지 않고, 전달받은 실패 게이트와 영향받은 선행 PASS만 재실행하도록 변경했다.
- runbook은 자동 기록하지 않고 메인이 축을 확정해 `--runbook-approved`를 전달한 경우에만 기록하도록 했다.
- script 파일을 직접 실행할 수 있도록 실행 권한을 적용했다.
- runbook 진입 뒤에도 전체 문서를 먼저 읽지 않도록 `빠른 진입점` 기준을 추가했다.
- script 상세 입출력과 예시는 `.codex/scripts/README.md`로 분리하고, `.codex/README.md`는 `.codex` 경로 라우팅만 남기도록 정리했다.

### 판단

- scope 전체 fingerprint만 비교하면 무관한 파일 추가에도 모든 PASS가 무효화되므로, 직접 의존 파일 해시와 의존 경로 패턴 비교로 범위를 좁혔다.
- PASS 효력 판정은 로컬 해시 계산으로 처리하고 의미론이 필요한 영향 범위는 `UNCLASSIFIED`로 메인에 반환한다.
- 상태 파일은 작업 중 임시 실행 정보이며 followup ignore 범위에 두고 커밋하지 않는다.
- runbook은 파일 하나를 고른 뒤에도 빠른 진입점이나 가까운 실패 사례부터 확인하고, 필요한 경우에만 추가 섹션으로 확장한다.
- script 상세 계약을 하위 README가 소유하게 해 `.codex/README.md`를 읽는 작업에서 불필요한 script 옵션까지 함께 읽는 비용을 줄였다.

### 검증

- 모든 shell script의 `bash -n` 문법 검사를 통과했다.
- 거버넌스 후보와 구현 계약 후보에서 변경 성격 미입력 시 `UNCLASSIFIED`가 반환되는 것을 확인했다.
- `workflow-implementation-change`, `non-contract-doc`에서 불필요한 거버넌스와 구현 검증이 비활성화되는 것을 확인했다.
- 단일 모듈 구현 변경 dry-run에서 해당 모듈 테스트만 계획되는 것을 확인했다.
- 의존 파일이 유지되면 `REUSED`, 변경되면 `RECHECK`, 무관한 scope 파일만 추가되면 기존 PASS가 유지되는 것을 확인했다.
- 실제 문서 거버넌스 `FAIL` 결과를 수정된 scope로 재개해 실패 원본 보존과 `.retry` PASS 결과 생성을 확인했다.
- 현재 4단계 scope의 문서 거버넌스 검증을 통과했고 구현 검증 게이트가 불필요함을 확인했다.

## Step 5. 메인·서브 에이전트 역할과 호출 계약 정의

### 목적

- subagent 게이트가 활성화될 때 메인과 서브의 역할, 입력 패킷, 출력 계약을 정의한다.

### 변경 내용

- subagent 역할과 task packet 원본을 `.codex/config/subagent-task-contract.md`로 추가했다.
- 메인 에이전트가 최초 작업 수준, 게이트 판정, 사용자 소통, 결과 통합, 최종 검증과 완료 선언을 소유하도록 고정했다.
- 서브 역할 후보를 `Explorer`, `Worker`, `Doc Governance Reviewer`, `Verification Analyst`로 나누고 각 역할의 권한과 금지사항을 정의했다.
- 서브 호출 기본값을 `OFF`로 두고, 역할별 상시 분업이 아니라 main-owned selective subagent orchestration으로 정의했다.
- task packet의 context를 확정 사실, 짧은 원문 발췌, 허용 읽기 범위, 금지 읽기 범위, state 참조, 재분류 금지 항목으로 나눠 중복 읽기와 누락 위험을 함께 줄이도록 했다.
- Explorer는 문서 읽기 대행자가 아니라 넓은 후보 범위를 짧은 후보 목록과 최소 확인 대상으로 줄이는 역할로 고정했다.

### 판단

- `skill = subagent` 1:1 매핑은 금지하고, 역할 기반 bounded capability로 정의했다.
- 서브의 `PASS`는 bounded task 완료일 뿐 전체 작업 완료가 아니며, 최종 완료는 메인이 선언한다.
- 단순 문서 읽기, 단일 파일 수정, 작은 검증 판단은 메인이 직접 수행하고 subagent로 분리하지 않는다.
- Explorer의 `files_read`는 추적용 메타데이터이며, 메인은 Explorer가 읽은 파일 전체를 다시 읽지 않고 `candidate_files`와 `minimum_next_check`의 최소 대상만 확인한다.
- `REQUIREMENTS`, ADR, 새 runbook 축, 외부 계약, 변경 성격 확정은 메인 또는 사람이 최종 판단한다.
- 실제 플랫폼 등록과 호출 절차 연결은 6단계 범위로 남겼다.

### 검증

- 문서 거버넌스 검증을 통과했다.
- `git diff --check`를 통과했다.

## Step 6. 조건부 서브 에이전트 오케스트레이션 절차 연결

### 목적

- 5단계에서 정의한 subagent 역할과 task packet 계약을 실제 호출 판단, 병렬 조건, 결과 통합 절차로 연결한다.

### 변경 내용

- subagent 호출과 결과 통합 절차를 `.codex/skills/subagent-orchestration/SKILL.md`로 추가했다.
- `.codex/config/subagent-task-contract.md`의 후속 단계 임시 문구를 실제 skill 경로로 바꿨다.
- task packet 검증, `allowed_reads`/`blocked_reads`, `state_refs`, `must_not_reclassify` 사용 절차를 skill에 연결했다.
- 파일 본문 읽기가 필요한 subagent task는 `allowed_reads`와 read-only `allowed_commands`를 함께 주거나 `quoted_extracts`로 필요한 원문만 전달하도록 보강했다.
- 병렬 호출은 독립 읽기·분석 task에만 허용하고, Worker 수정 범위가 겹치면 순차 실행하도록 정리했다.
- Explorer, Worker, Doc Governance Reviewer, Verification Analyst별 packet 주의점을 분리했다.
- 검증 결과는 검증 대상을 만든 Step이 아니라 실제 검증을 실행한 Step에 기록하도록 worklog 운영 기준을 보강했다.

### 판단

- 실제 subagent 런타임이 있더라도 이 저장소 계약을 만족할 때만 선택적으로 호출한다.
- subagent 호출은 속도 최적화가 아니라 중복 context 비용보다 이득이 클 때만 사용하는 절차다.
- 서브 결과의 `PASS`는 bounded task 완료일 뿐 전체 작업 완료가 아니며, 메인이 현재 diff와 state 기준을 대조한 뒤 통합한다.

### 검증

- 실제 subagent 호출 smoke test를 수행해 bounded packet 준수와 별도 subagent 응답 수신을 확인했다.
- `allowed_commands`가 비어 있으면 subagent가 파일 읽기 명령도 실행하지 않고 `UNCLASSIFIED`를 반환하는 것을 확인했다.
- 단일 read command를 명시 허용한 뒤 `.codex/config/subagent-task-contract.md`만 읽고 선택적 subagent orchestration 핵심 조건을 확인하는 smoke test가 `PASS`로 끝났다.
- 문서 거버넌스 검증을 통과했다.
- `git diff --check`를 통과했다.
