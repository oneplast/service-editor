# Document To Code Check Matrix

이 문서는 문서 최신화 검증과 별도로, 언제 구현 검증을 수행해야 하는지와 어떤 테스트 단위로 확인할지 정의한다.

## 목적

- 문서는 맞지만 구현이 어긋나는 상태를 줄인다.
- 코드 변경과 계약 문서 변경을 같은 기준으로 검증한다.
- 문서만 정리한 작업에 불필요한 테스트를 강제하지 않는다.

## 구현 검증이 필요한 경우

### 1. `code-change`

다음 경로가 바뀌면 구현 검증이 필요하다.

- `documents-api/src/**`
- `documents-core/src/**`
- `documents-infrastructure/src/**`
- `documents-boot/src/**`
- `build.gradle`
- `settings.gradle`
- `documents-*/build.gradle`
- `gradlew`

### 2. `contract-doc-change`

다음 문서가 구현 기대, 계약, 정책을 바꾼다면 구현 검증이 필요하다.

- `docs/REQUIREMENTS.md`
- `docs/guides/**`
- `docs/decisions/**`
- 실제 명령, 엔드포인트, 설정 키, 기대 결과를 바꾸는 `docs/runbook/**`

### 3. `cross-check-only`

다음 변경은 원칙적으로 문서 거버넌스 검증만 수행하면 된다.

- `AGENTS.md`
- `docs/README.md`
- `docs/explainers/**`
- `docs/followup/**`
- `prompts/**`
- `docs/learn/**`
- 단순 표현 정리, 링크 수정, 인덱스 보강

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

### 계약 문서 변경

- 문서가 실제 기대 동작을 바꾼다면 관련 구현과 테스트를 같이 확인한다.
- 아직 코드 변경이 없는 문서 정리 단계라면, 구현 검증이 필요한 상태라는 사실을 남기고 종료하지 않는다.
- `runbook` 변경은 실제 명령, 기대 결과, 로그 경로가 바뀐 경우에만 구현 검증 대상으로 본다.

## 실패 처리와 재검증

- 검증 실패는 완료 조건을 만족하지 못한 상태다.
- 같은 입력으로 의미 없이 반복 실행하지 않고, 실패 원인을 수정한 뒤 다시 검증한다.
- 실패가 발생했거나 알려진 반복 실패의 예방 체크포인트가 직접 필요할 때만 관련 runbook 파일 하나를 읽는다.
- 실패 축이 명확하면 관련 runbook 파일에 바로 케이스를 남긴다.
- 실패 케이스 기록과 재시도 라우팅은 `.codex/config/failure-route-map.md`, `.codex/scripts/verify-and-retry.sh`가 담당한다.

## 자동 판별이 하는 일

- 변경 세트를 보고 구현 검증 필요 여부를 추정한다.
- 변경 경로로부터 우선 실행할 Gradle 테스트 태스크를 계산한다.
- 요청 시 계산된 태스크를 실행한다.
- 실패 축이 명확한 검증 실패를 관련 runbook에 자동으로 추가한다.

## 자동 판별이 하지 않는 일

- 요구사항이 정말 바뀌었는지의 의미론 판단
- 어떤 테스트가 충분한지의 최종 보장
- 비즈니스 시나리오 검증 완전성 판단
- 어떤 runbook 주제가 맞는지의 최종 의미론 판단

이 네 가지는 사람이 마지막으로 확인해야 한다.
