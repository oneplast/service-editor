# Test Verification Recovery

## 언제 읽는가

- 구현 검증, 테스트, Gradle 설정, `verify-and-retry` 작업을 시작하기 전에
- 구현 검증에서 테스트 실패가 반복될 때
- Gradle 모듈 테스트 선택이 흔들릴 때
- 세션이 끊겼다가 다시 시작해 현재 검증 단계와 범위를 다시 맞춰야 할 때
- 코드 변경 이후 어떤 테스트를 다시 돌려야 할지 애매할 때
- 빌드 설정 변경이나 모듈 경계 변경 뒤 검증이 실패할 때

## 먼저 다시 볼 원문

- `.codex/config/doc-to-code-check-matrix.md`
- `.codex/config/failure-route-map.md`
- `.codex/skills/implementation-check/SKILL.md`
- `.codex/skills/verification-retry/SKILL.md`
- `.codex/scripts/check-doc-implementation.sh`
- `.codex/scripts/verify-and-retry.sh`

## 작업 전 체크포인트

- 변경 경로와 관련 모듈을 먼저 적었는가
- 계약 문서 변경이면 구현 경로와 테스트를 같은 세트로 보고 있는가
- `--strict`로 구현 검증 필요 여부를 먼저 확인했는가
- followup이 있으면 `검증 단계`가 `검증 대기`인지 확인했는가
- 세션 재개라면 followup의 `현재 상태`, `.scope`, `검증 단계`를 먼저 다시 읽었는가

## 검증/자기점검 때 볼 분기

- 테스트 범위를 바로 설명하지 못하거나 자꾸 다시 고르면 `모듈 테스트 선택 오류`
- 문서 기대와 코드 반영 범위가 같이 떠오르지 않으면 `계약 문서와 구현 드리프트`
- Gradle 설정 변경 뒤 영향 범위를 좁히기 어렵거나 연쇄 실패가 나면 `Gradle 설정 변경 후 전체 테스트 실패`

## 반복 실수/실패 사례

### 1. 모듈 테스트 선택 오류

- 증상: 관련 없는 모듈 테스트를 돌리거나 전체 테스트만 반복한다.
- 원인: 변경 경로와 모듈 경계를 먼저 확정하지 않았다.
- 복구: `.codex/config/doc-to-code-check-matrix.md`를 다시 읽고 변경된 모듈 기준 기본 태스크를 고른다.
- 방지: 코드 변경 전후로 어떤 모듈이 바뀌었는지 먼저 적고 테스트를 시작한다.

### 2. 계약 문서와 구현 드리프트

- 증상: `REQUIREMENTS`, `guide`, `decision`을 바꾼 뒤 테스트가 실패한다.
- 원인: 문서 기대와 코드 반영 범위를 같은 세트로 보지 않았다.
- 복구: 관련 문서, 구현 경로, 테스트를 한 번에 다시 매핑한다.
- 방지: 계약 문서 변경 시 `.codex/scripts/check-doc-implementation.sh --strict`를 먼저 돌린다.

### 3. Gradle 설정 변경 후 전체 테스트 실패

- 증상: 루트 `build.gradle`, `settings.gradle`, 모듈 `build.gradle` 변경 후 여러 모듈 테스트가 연쇄 실패한다.
- 원인: 설정 변경 영향을 모듈 단위로 과소평가했다.
- 복구: 루트 `test` 기준으로 다시 확인하고 실패 모듈을 좁힌다.
- 방지: 빌드 설정 변경은 처음부터 전체 테스트 후보로 올린다.

## 실패 후 복구 순서

1. 위 `검증/자기점검 때 볼 분기`에서 가장 가까운 항목 하나를 고른다.
2. `먼저 다시 볼 원문`에서 필요한 파일만 다시 읽는다.
3. 세션 재개 작업이거나 상태가 흐려졌다면 followup의 `현재 상태`, `.scope`, `검증 단계`를 먼저 다시 맞춘다.
4. 변경 경로와 관련 모듈을 먼저 적는다.
5. `.codex/scripts/check-doc-implementation.sh --strict` 또는 `--run`으로 현재 상태를 확인한다.
6. 실패가 나면 원인을 고치고 `.codex/scripts/verify-and-retry.sh`로 PASS를 다시 닫는다.
7. 실패 축이 명확하면 이 문서에 바로 새 케이스를 추가하거나 기존 항목을 보강한다.

## 자동 기록된 실패 케이스

이 섹션은 `.codex/scripts/verify-and-retry.sh`가 실패 축이 명확한 검증 실패를 확인했을 때 바로 추가한다.
