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

---

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

---

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

---

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

---

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

---

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

---

## Step 7. 조건부 하네스 게이트 시나리오 검증 추가

### 목적

- 조건부 하네스 중 script로 관찰 가능한 대표 게이트 분기가 false positive와 false negative 없이 동작하는지 자동 검증한다.

### 변경 내용

- `.codex/scripts/check-harness-scenarios.sh`를 추가했다.
- 시나리오 검증은 `/tmp`에 임시 scope와 state를 만들고 기존 게이트 script의 exit code와 출력만 확인하도록 했다.
- 문서 거버넌스 후보 없음, 변경 성격 미확정, 비활성, workflow 계약 변경 실패와 성공을 검증했다.
- 구현 검증 후보 없음, 변경 성격 미확정, 비활성, 모듈별 dry-run, 전체 dry-run, scope 불일치를 검증했다.
- 실패 재시도에서 영향 없는 `PASS` 재사용, 영향받은 `PASS` 재검증 후보, `FAIL`이 아닌 failure-file 차단을 검증했다.
- 이 script는 운영 파이프라인의 자동 고려 대상이 아니므로 `.codex/README.md`, `.codex/scripts/README.md`, topic에는 재사용 경로로 연결하지 않았다.

### 판단

- 7단계는 자동화 가능한 게이트 회귀 검증으로 제한하고, Direct/Scoped/subagent/doc-impact처럼 에이전트 행동을 직접 봐야 하는 계약은 8단계 최종 정합성 검토에서 확인한다.
- Direct 작업에서 문서를 읽지 않는지 같은 메인 행동 계약은 shell script로 직접 증명하지 않고, 게이트 script가 기계적으로 판정 가능한 대표 분기만 자동화했다.
- 제품 코드와 CI를 변경하지 않고 하네스 자체의 분기 안정성을 확인하는 방식으로 7단계 범위를 제한했다.

### 검증

- `bash .codex/scripts/check-harness-scenarios.sh`를 실행해 14개 대표 시나리오의 31개 assertion이 모두 통과했다.
- 여기서 assertion은 각 시나리오의 exit code와 핵심 출력 문구를 확인한 단위다.

| 축 | 시나리오 수 | assertion 수 | 검증 내용 |
| --- | ---: | ---: | --- |
| doc-governance | 5 | 10 | 후보 없음, 미확정, 비활성, 필수 연결 문서 누락 실패, 정상 `PASS` |
| implementation | 6 | 13 | 후보 없음, 미확정, 비활성, 모듈 dry-run, 전체 dry-run, scope 불일치 |
| retry | 3 | 8 | 선행 `PASS` 재사용, 영향받은 `PASS` 재검증 후보, 잘못된 failure-file 차단 |
| 합계 | 14 | 31 | 자동화 가능한 대표 게이트 분기 검증 |

---

## Step 8. 최종 정합성 검증과 작업 기록 마감

### 목적

- 1단계부터 7단계까지 만든 조건부 하네스 계약이 서로 충돌하지 않는지 확인하고, 작업 기록을 최종 기준으로 정리한다.

### 변경 내용

- topic에 조건부 하네스 전환 worklog를 연결해 이후 문서·프롬프트 거버넌스 기준에서 바로 찾을 수 있게 했다.
- `doc-governance-check` skill과 `check-doc-governance.sh`의 안내 문구를 `doc-update-matrix`의 세분화된 change-kind 기준과 맞췄다.
- active followup은 다음 세션 복구용 최소 상태만 남기도록 다시 정리했다.

### 판단

- `AGENTS.md`가 최상위 계약을 소유하고, README는 경로 라우팅, config는 판정 기준, skill은 절차, script는 자동 검증 실행을 맡는 구조로 유지했다.
- Direct, Scoped, Harness는 작업 수준 판정이며, 각 게이트는 필요한 경우에만 독립적으로 활성화된다.
- `DOC_UNDETERMINED`는 문서 영향 미확정 값이고, `UNCLASSIFIED`는 게이트 실행 상태로 분리되어 있다.
- subagent는 상시 분업자가 아니라 main-owned selective orchestration의 bounded capability로 남겼다.
- commit 보조 skill은 사용자가 명시적으로 요청할 때 쓰는 편의 절차이며, 하네스 기본 파이프라인에는 연결하지 않는다.

### 검증

- 규칙 충돌 후보 검색으로 오래된 `REVIEW`, `git-add`, `/commit-*`, `./commit-*`, subagent 후속 임시 문구가 공식 계약 경로에 남아 있지 않은지 확인했다.
- Direct, Scoped, subagent, doc-impact처럼 script로 직접 증명하기 어려운 메인 행동 계약은 `AGENTS.md`, `.codex/README.md`, config, skill의 소유 경계를 대조했다.
- `git diff --check`를 통과했다.
- 모든 shell script의 `bash -n` 문법 검사를 통과했다.
- `bash .codex/scripts/check-harness-scenarios.sh`를 실행해 31개 assertion이 모두 통과했다.
- `workflow-contract-change`와 `prompt-governance-change` 기준 문서 거버넌스 검증을 통과했다.
- `non-contract-doc` 기준 구현 검증 게이트 비활성을 확인했다.

---

## Step 9. 조건부 하네스 실사용 수용 검증

### 목적

- before/after troubleshooting 비교 실험으로 넘어가기 전에, 현재 조건부 하네스가 5가지 우선사항을 실제 작업 흐름에서 만족하는지 확인한다.

### 변경 내용

- 9단계를 구조 비교 실험이 아니라 현재 하네스 수용 검증으로 분리했다.
- 자동 검증 가능한 script 분기와 에이전트 행동 계약을 별도 축으로 나눴다.
- 선택적 subagent 호출 검증은 quoted excerpt만 전달하는 bounded 독립 리뷰 1건으로 제한했다.

### 판단

- 1~8단계는 구조 구축과 자동화 가능한 회귀 검증이고, 9단계는 실사용 시나리오에서 하네스가 의도대로 작동하는지 확인하는 acceptance validation이다.
- Direct, Scoped, doc-impact, subagent 호출 판단은 shell script만으로 완전히 증명하기 어렵기 때문에 계약 대조와 실제 세션 관찰을 함께 사용한다.
- 수치화된 before/after 비교, 토큰 추정 알고리즘 적용, 구조별 trial 반복은 기존 troubleshooting 비교 실험에서 별도로 수행한다.

### 수용 검증 시나리오

| 시나리오 | 기대 작업 수준 | 기대 게이트 | 확인 방식 | 수용 기준 |
| --- | --- | --- | --- | --- |
| 단순 질의 또는 상태 확인 | Direct | 추가 게이트 없음 | 세션 행동 관찰 | README, skill, script, runbook, prompts, subagent를 열지 않는다. |
| 특정 파일·경로의 작은 수정 | Scoped | path-rule 또는 대상 경로 README만 | 세션 행동 관찰 | 지정 범위와 직접 관련 파일을 넘어 확장하지 않는다. |
| 코드 변경 후 문서 영향 없음 | Scoped 또는 Harness | doc-impact = `DOC_NONE` | 계약 대조와 diff 판단 | 문서 최신화를 위한 추가 탐색과 수정을 하지 않는다. |
| API·설정·정책 변경 | Harness | doc-impact = `DOC_REQUIRED`, 필요 시 docs-routing/doc-update | 계약 대조와 diff 판단 | 필요한 공식 문서만 좁게 읽고 갱신한다. |
| 문서 영향 불명확 | Harness | doc-impact = `DOC_UNDETERMINED` | 계약 대조 | 최소 공식 문서 후보 확인 전 완료하지 않는다. |
| 문서 체계·workflow 계약 변경 | Harness | doc-governance | script와 계약 대조 | `doc-update`와 섞지 않고 동반 문서 정합성만 검증한다. |
| 구현 의미 변경 | Harness | implementation-verification | script dry-run 또는 run | scope에 맞는 구현 검증만 선택한다. |
| 검증 성공 | Harness | retry/runbook 비활성 | script 시나리오 | 성공 결과만으로 retry나 runbook을 열지 않는다. |
| 검증 실패 | Harness | verification-retry, 필요 시 runbook | script 시나리오 | 실패 정보 기반으로 같은 검증 또는 영향받은 선행 PASS만 재개한다. |
| 독립 bounded 분석 | Harness | subagent 선택 호출 | 실제 subagent smoke/review | 중복 컨텍스트 비용보다 이득이 있을 때만 packet으로 호출한다. |
| 단일 문서 읽기 또는 메인이 이미 아는 범위 | Direct 또는 Scoped | subagent 미호출 | 계약 대조 | subagent를 기본 실행자로 쓰지 않는다. |

### 5가지 우선사항 판정표

| 우선사항 | 현재 수용 기준 | 현재 판정 |
| --- | --- | --- |
| 토큰 절약 | 작은 충분 컨텍스트로 시작하고, 필요 없는 문서·skill·script·subagent를 열지 않는다. | PASS |
| 문서 정합성 | `DOC_REQUIRED`일 때만 필요한 공식 문서를 좁게 갱신하고, 문서 체계 변경은 `doc-governance`로 별도 검증한다. | PASS |
| 안정적인 파이프라인 | `FAIL`, `UNCLASSIFIED`, retry, runbook, PASS 재사용 경계가 끊기지 않는다. | PASS |
| 요구사항 준수 | `AGENTS.md`와 경로 README의 소유 규칙을 유지하고, 사용자 확인이 필요한 결정은 임의 확정하지 않는다. | PASS |
| 중복 조회/호출 최소화 | 같은 기준 문서를 반복해서 읽지 않고, subagent와 메인이 같은 전체 문맥을 중복 조회하지 않는다. | PASS |

### 검증

- Direct 질의 관찰: "남은 작업이 길어서 일부만 진행한 것인지" 질문에는 추가 파일, skill, script, runbook, prompts, subagent를 열지 않고 세션 상태만으로 답했다.
- Scoped/Harness 문서 작업 관찰: 9단계 worklog 보강에서는 `prompts/` 경로를 직접 수정하므로 `prompts/README.md`와 `prompts/worklog/README.md`만 확인했고, troubleshooting 비교 실험 문서는 수정하지 않았다.
- Scoped 문서 수정 관찰: 9단계 worklog 보강은 기존 목표의 같은 worklog 파일 1개만 수정했고, topic·troubleshooting·제품 문서로 확장하지 않았다.
- 통제된 doc-impact 판정 시나리오로 `DOC_NONE`, `DOC_REQUIRED`, `DOC_UNDETERMINED`의 분기 기준을 확인했다.
- subagent 독립 리뷰는 quoted excerpt만 사용하도록 제한했다.
- subagent 결과는 `PASS`이며, main-owned selective subagent orchestration과 충돌되는 문구가 없다고 보고했다.
- `git diff --check`를 통과했다.
- 모든 shell script의 `bash -n` 문법 검사를 통과했다.
- `bash .codex/scripts/check-harness-scenarios.sh`를 실행해 31개 assertion이 모두 통과했다.
- `prompt-governance-change` 기준 문서 거버넌스 검증을 통과했다.
- `non-contract-doc` 기준 구현 검증 게이트 비활성을 확인했다.

### doc-impact 수용 판정

| 통제 시나리오 | 기대 판정 | 수용 판단 |
| --- | --- | --- |
| 현재 요구사항과 계약 안의 내부 리팩터링 또는 테스트 보강 | `DOC_NONE` | 문서 최신화를 위한 `docs/README.md`, REQUIREMENTS, guide, ADR 추가 읽기를 하지 않는 흐름이 맞다. |
| API 요청·응답·에러, 인증·권한, 설정 키, 실행 명령, 모듈 경계가 바뀌는 변경 | `DOC_REQUIRED` | `docs-routing`과 `doc-update`를 열고 영향받는 공식 문서만 좁게 읽는 흐름이 맞다. |
| 사용자 요청과 diff만으로 외부 계약 또는 문서화된 절차 변경 여부를 확정할 수 없는 변경 | `DOC_UNDETERMINED` | 완료를 보류하고 직접 관련된 공식 문서 후보만 최소 확인한 뒤 `DOC_REQUIRED` 또는 `DOC_NONE`으로 재분류하는 흐름이 맞다. |

### 남은 수용 검증

- 실제 제품 코드 변경을 일부러 만들지는 않는다.
- 이후 자연 발생하는 실제 코드 변경 작업에서 `DOC_NONE`, `DOC_REQUIRED`, `DOC_UNDETERMINED` 판정 사례가 나오면 같은 Step에 추가 보강한다.
- 수치화된 토큰 절약과 before/after 구조 비교는 troubleshooting 비교 실험에서 수행한다.

---

## Step 10. 임시 worktree 기반 실전 코드 변경 시나리오 검증

### 목적

- 현재 브랜치를 오염시키지 않고 disposable worktree에서 실제 코드 변경 시나리오를 수행해, 조건부 하네스가 코드 변경 복잡도별로 적절히 분기되는지 확인한다.

### 변경 내용

- 기준 커밋 `0cb6289`에서 임시 worktree를 만들고, 시나리오별 변경을 현재 브랜치에 남기지 않는 방식으로 검증했다.
- `DOC_NONE`, `DOC_REQUIRED`, `DOC_UNDETERMINED` 재분류, 복잡한 다중 범위 변경의 subagent bounded 리뷰를 분리해 관찰했다.
- 실험 코드 변경은 폐기 대상으로 두고, 현재 브랜치에는 관찰 결과만 기록한다.

### 시나리오 결과

| 시나리오 | 임시 변경 | 기대 분기 | 관찰 결과 |
| --- | --- | --- | --- |
| `DOC_NONE` 테스트 보강 | `TextNormalizerTest`에 nullable trim 테스트 추가 | 문서 갱신 없음, 최소 구현 검증 | 문서 거버넌스 비활성, `verification-only` dry-run이 `:documents-infrastructure:test`를 선택했다. |
| `DOC_REQUIRED` 에러 계약 변경 | `DOCUMENT_TITLE_TOO_LONG` 비즈니스/API 에러 코드 추가, REQUIREMENTS와 error contract 갱신 | 문서 갱신 필요, 구현 검증 필요, doc-governance 비활성 | `implementation-change` dry-run이 root `test`를 선택했고, 문서 체계 변경이 아니므로 doc-governance는 비활성으로 유지됐다. |
| `DOC_UNDETERMINED` 재분류 | `CreateDocumentRequest`의 title max를 `255 -> 120`으로 변경 | 최소 공식 문서 확인 후 `DOC_REQUIRED` 재분류 | REQUIREMENTS에 title 최대 길이 `255`가 있어 완료 보류 후 REQUIREMENTS만 좁게 갱신하는 흐름으로 재분류했다. |
| 복잡한 다중 범위 변경 subagent 리뷰 | 에러 코드와 공식 문서 동반 변경 요약을 quoted context로 전달 | 선택적 bounded subagent 호출 | subagent는 동반 문서 누락 없음 `PASS`를 반환했고, 메인이 `9018` 중복과 심볼명 일치를 최소 확인했다. |

### 판단

- 코드 변경 복잡도가 올라갈수록 `Scoped -> Harness`, `DOC_NONE -> DOC_REQUIRED`, 구현 검증 범위가 달라지는 흐름이 관찰됐다.
- 제품 계약 변경에서는 `doc-update`가 필요하지만, 문서 체계나 workflow 계약 변경이 아니면 `doc-governance`를 자동 활성화하지 않는 설계가 유지됐다.
- `DOC_UNDETERMINED`는 완료가 아니라 최소 공식 문서 후보 확인으로 이어지는 보류 상태로 작동한다.
- subagent는 전체 하네스를 다시 읽지 않고, 다중 범위 변경의 누락 후보를 확인하는 bounded 리뷰로만 사용했다.
- 실제 Gradle 테스트 실행은 worktree 환경의 `JAVA_HOME` 미설정으로 수행하지 못했고, 구현 검증은 dry-run 범위 선택까지만 확인했다.

### 검증

- `DOC_NONE` 시나리오에서 `check-doc-implementation --change-kind verification-only --dry-run`이 `:documents-infrastructure:test`를 선택했다.
- `DOC_REQUIRED` 시나리오에서 `check-doc-implementation --change-kind implementation-change --dry-run`이 root `test`를 선택했다.
- `DOC_UNDETERMINED` 재분류 시나리오에서 `check-doc-implementation --change-kind implementation-change --dry-run`이 `:documents-api:test`를 선택했다.
- 각 시나리오에서 `check-doc-governance --change-kind content-only`는 문서 체계 변경이 아니므로 비활성 `PASS`를 반환했다.
- subagent bounded 리뷰 결과는 `PASS`였고, 메인이 `9018`과 `DOCUMENT_TITLE_TOO_LONG`의 임시 변경 범위 내 일치를 확인했다.
