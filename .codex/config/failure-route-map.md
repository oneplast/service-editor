# Failure Route Map

이 문서는 검증 실패가 발생했을 때 어떤 runbook md로 보내는지 정의한다.

## runbook 라우팅 기준

### 1. `doc-governance-failure`

다음 실패는 기본적으로 `docs/runbook/ai-doc-workflow-recovery.md`로 보낸다.

- `AGENTS.md`, `docs/README.md`, `docs/followup/**`, `prompts/topics/**`, `.codex/**` 관련 문서 거버넌스 검증 실패
- 문서 읽기 순서, 경로 분류, followup 누락, 규칙 중복 복제 같은 반복 실수

### 2. `implementation-verification-failure`

다음 실패는 기본적으로 `docs/runbook/test-verification-recovery.md`로 보낸다.

- Gradle 테스트 실패
- 모듈 테스트 선택 오류
- 구현 계약 문서 변경 후 구현 검증 실패
- 빌드 설정 변경 뒤 검증 실패

## 역할 경계

- 자동 라우팅은 기존에 정의된 실패 축에만 적용한다.
- 완전히 새로운 문제 축을 자동으로 새 runbook 파일로 만들지 않는다.
- 기존 축에 넣기 애매한 실패는 자동 기록하지 않고, 새 runbook 주제 분리가 필요한지는 사용자가 선택한다.
- 애매한 경우에는 후보 안 2~3개를 제시하고 추천안을 함께 표시한다.

## 자동화 범위

- `.codex/scripts/verify-and-retry.sh`는 명확한 기존 실패 축만 자동으로 고르고 관련 runbook에 바로 기록한다.
- 완전히 새로운 문제 축을 별도 runbook으로 분리해야 하는지의 최종 판단은 사람이 한다.
