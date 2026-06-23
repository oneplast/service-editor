# Document To Code Check Matrix

이 문서는 문서 영향 판정과 필요한 공식 문서 갱신과 별도로, 어떤 변경이 구현 검증 후보인지와 실제 구현 검증 게이트를 언제 활성화할지 정의한다.

## 목적

- 문서는 맞지만 구현이 어긋나는 상태를 줄인다.
- 코드 변경과 계약 문서 변경을 같은 기준으로 검증한다.
- 문서만 정리한 작업에 불필요한 테스트를 강제하지 않는다.

## 판별 계약

변경 경로는 구현 검증 후보를 탐지하고, 변경 성격은 실제 게이트 활성화를 결정한다.

코드나 설정 변경은 구현 검증 판정과 별도로 메인 에이전트가 `.codex/config/doc-update-matrix.md`의 문서 영향 게이트를 판정한다. 구현 검증 절차는 이 문서 게이트를 대신 실행하지 않는다.

- `DOC_REQUIRED`이면 필요한 공식 문서만 갱신한다.
- `DOC_NONE`이면 문서 최신화를 위한 추가 읽기와 수정을 하지 않는다.
- `DOC_UNDETERMINED`이면 문서 영향 분류 전까지 완료 판정을 보류한다.

### 변경 성격

- `implementation-change`
  - 제품 코드, 빌드 설정 또는 제품 동작 변경과 함께 테스트 코드를 바꾸는 변경
  - 메인 에이전트가 구현 검증 게이트를 활성화한다.
- `contract-change`
  - 문서가 실제 기대 동작, 외부 계약, 채택 정책, 명령, 설정 키, 기대 결과를 바꾸는 변경
  - 메인 에이전트가 관련 구현과 테스트를 확인하는 구현 검증 게이트를 활성화한다.
- `non-contract-doc`
  - 오타, 표현, 링크, 인덱스, 예시, 현재 계약을 바꾸지 않는 문서 정리
  - 구현 검증 게이트를 활성화하지 않는다.
- `verification-only`
  - 제품 동작을 바꾸지 않고 테스트, fixture, 검증 도구만 보강하는 변경
  - 변경한 검증 범위의 테스트나 sanity check만 선택하고 전체 제품 테스트를 자동 강제하지 않는다.

### 판별 우선순위

1. 명시적으로 전달된 변경 성격
2. 현재 scope의 diff와 사용자 요청으로 확정한 변경 성격
3. 경로 기반 후보 탐지
4. 계약 문서 경로만으로 의미 변경을 확정할 수 없으면 `UNCLASSIFIED`

`UNCLASSIFIED`는 구현 검증 불필요를 뜻하지 않는다. 변경 성격이 아직 분류되지 않았으므로, 메인 에이전트가 diff를 확인해 `contract-change` 또는 `non-contract-doc`으로 확정하기 전까지 완료 판정을 보류하는 상태다.

공통 반환 정보와 재분류·재개 절차는 `.codex/config/gate-state-contract.md`를 따른다.

scope 파일이 있으면 해당 파일 목록만 후보 탐지와 테스트 범위 계산에 사용한다. scope가 없을 때만 `git status` 전체를 마지막 fallback으로 사용한다.

## 구현 검증 후보

### 1. `code-change`

다음 경로가 바뀌면 `implementation-change` 또는 `verification-only` 후보로 본다.

- `documents-api/src/**`
- `documents-core/src/**`
- `documents-infrastructure/src/**`
- `documents-boot/src/**`
- `build.gradle`
- `settings.gradle`
- `documents-*/build.gradle`
- `gradlew`

### 2. `contract-doc-change`

다음 문서는 `contract-change` 후보 경로다. 경로만 바뀌었다고 전체 테스트를 확정하지 않는다.

- `docs/REQUIREMENTS.md`
- `docs/guides/**`
- `docs/decisions/**`
- 실제 명령, 엔드포인트, 설정 키, 기대 결과를 바꾸는 `docs/runbook/**`

### 3. `cross-check-only`

다음 변경은 기본적으로 `non-contract-doc` 후보다.

- `AGENTS.md`
- `docs/README.md`
- `docs/explainers/**`
- `docs/followup/**`
- `prompts/**`
- `docs/learn/**`
- 단순 표현 정리, 링크 수정, 인덱스 보강

`docs/REQUIREMENTS.md`, `docs/guides/**`, `docs/decisions/**`, `docs/runbook/**`도 실제 계약 의미를 바꾸지 않으면 `non-contract-doc`으로 판정할 수 있다.

## 검증 단위

### 모듈별 기본 테스트 태스크

- `documents-api/**` -> `:documents-api:test`
- `documents-core/**` -> `:documents-core:test`
- `documents-infrastructure/**` -> `:documents-infrastructure:test`
- `documents-boot/**` -> `:documents-boot:test`

### 전체 테스트로 올려야 하는 경우

- 여러 모듈이 함께 바뀐 경우
- 루트 Gradle 설정이 바뀐 경우
- 어떤 모듈 테스트만으로 충분한지 바로 확정하기 어려운 경우

이 경우 기본 태스크는 `test`다.

### 자동 검증 제외 테스트

- `.codex/scripts/check-doc-implementation.sh --run`은 `com.documents.api.resource.ResourceAccessAndLifecycleIntegrationTest`를 실행 대상에서 제외한다.
- 이 테스트는 platform/resource lifecycle 연동 권한과 외부 패키지 구성이 필요하므로, 현재 저장소의 Codex 구현 검증 게이트에서 직접 해결 가능한 범위가 아니다.
- 제외 범위는 `.codex` 로컬 검증 파이프라인에만 적용한다. 제품 코드, Gradle 테스트 정의, CI 워크플로는 이 예외 때문에 수정하지 않는다.

## 작업 유형별 원칙

### 코드 변경

- 변경된 모듈 기준으로 최소 테스트를 먼저 고른다.
- 모듈 경계가 섞이면 루트 `test`로 올린다.
- 동작 변경이면 관련 테스트를 추가하거나 기존 테스트를 갱신한다.
- 테스트와 fixture만 바뀐 `verification-only`는 변경한 검증 범위부터 실행한다.
- 코드 변경의 문서 영향은 `DOC_REQUIRED`, `DOC_NONE`, `DOC_UNDETERMINED` 중 하나로 별도 판정한다.

### 계약 문서 변경

- 문서가 실제 기대 동작을 바꾼다면 관련 구현과 테스트를 같이 확인한다.
- `contract-change`인데 아직 코드 변경이 없다면 구현 반영이 필요한 상태를 남기고 완료로 판단하지 않는다.
- `non-contract-doc`이면 구현 검증을 실행하지 않는다.
- `runbook` 변경은 실제 명령, 기대 결과, 로그 경로가 바뀐 경우에만 구현 검증 대상으로 본다.

## 실패 처리와 재검증

- 검증 실패는 완료 조건을 만족하지 못한 상태다.
- 최초 검증은 활성화된 구현 검증 게이트에서 한 번만 실행하고, 실패하면 `.codex/config/gate-state-contract.md`의 `FAIL` 반환 정보를 남긴다.
- 메인 에이전트는 실패 정보를 기준으로 `verification-retry`와 `runbook` 게이트를 각각 판정한다.
- 같은 입력으로 의미 없이 반복 실행하지 않고, 실패 원인을 수정한 뒤 다시 검증한다.
- 실패가 발생했거나 알려진 반복 실패의 예방 체크포인트가 직접 필요할 때만 관련 runbook 파일 하나를 읽는다.
- 실패 축 후보는 `.codex/config/failure-route-map.md`로 계산할 수 있지만, 메인이 runbook 게이트와 축을 확정한 뒤에만 관련 runbook 파일에 케이스를 남긴다.
- 실패 원인 수정 뒤 수정 diff가 기존 `PASS`의 입력 또는 직접 의존 대상을 바꿨는지 확인한다.
- 영향받지 않은 `PASS`는 재사용하고, 영향받은 `PASS`만 무효화해 관련 선행 검증과 실패한 동일 검증을 다시 실행한다.
- 영향 범위가 불명확하면 `UNCLASSIFIED`로 최소 확인 대상을 반환하고, 확인 뒤에도 좁힐 수 없을 때만 모듈 또는 전체 테스트 기준으로 확대한다.
- 재시도는 최초 검증을 다시 확인하거나 전체 파이프라인을 반복하는 절차가 아니라, 무효화된 선행 검증과 실패한 동일 검증부터 재개하는 절차다.

## 작업 기록 경계

- 구현 검증 결과는 모든 작업에서 worklog를 요구하지 않는다.
- 같은 목표의 worklog가 이미 활성화됐거나 팀·프로젝트 단위의 의미 있는 기록이 필요한 경우에만 해당 Step을 갱신한다.
- 일반 구현, 단순 검증, 짧은 버그 수정에서는 결과 기록만을 이유로 prompts 게이트를 활성화하지 않는다.

## 자동 판별이 하는 일

- 변경 세트를 보고 구현 검증 후보와 가능한 변경 성격을 추정한다.
- 명시된 변경 성격에 따라 구현 검증 게이트 활성화 여부를 결정한다.
- 변경 경로로부터 우선 실행할 Gradle 테스트 태스크를 계산한다.
- 요청 시 계산된 태스크를 실행한다.
- 실패 결과와 기존 runbook 축 후보를 반환한다.
- 실패 수정 diff로 영향받을 수 있는 기존 `PASS` 후보를 계산한다.

## 자동 판별이 하지 않는 일

- 요구사항이 정말 바뀌었는지의 의미론 판단
- 어떤 테스트가 충분한지의 최종 보장
- 비즈니스 시나리오 검증 완전성 판단
- 어떤 runbook 주제가 맞는지의 최종 의미론 판단
- 계약 문서 경로만으로 `contract-change`와 `non-contract-doc`을 최종 구분하는 일
- 메인을 대신해 runbook 게이트를 활성화하거나 실패 케이스를 기록하는 일
- 경로와 입력 정보만으로 확정할 수 없는 의미론적 `PASS` 영향 범위를 임의 확정하는 일

이 일곱 가지는 메인 에이전트 또는 사람이 마지막으로 확인해야 한다.
