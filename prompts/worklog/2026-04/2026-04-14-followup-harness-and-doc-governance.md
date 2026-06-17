# 2026-04-14 Followup Harness And Doc Governance

## Step 1. followup 경로를 공식 복구 경로로 승격

- 목적: 세션 초기화나 긴 컨텍스트 상황에서도 현재 작업을 짧은 상태 문서 하나로 복구할 수 있게 한다.
- 변경 내용: `docs/followup/README.md`와 `docs/followup/000-active-task-template.md`를 추가해 진행 중 작업 handoff 구조를 정의했다.
- 변경 내용: 진행 중 작업 파일은 `docs/followup/active/` 아래에 두고, 누적 로그가 아니라 현재 상태 스냅샷으로 유지하도록 규칙을 정했다.
- 판단: followup은 기억 강제가 아니라 복구를 위한 운영 경로로 정의하고, 공식 정책이나 장기 로그와 역할을 분리했다.

## Step 2. 전역 규칙과 문서 인덱스를 토큰 절약형으로 압축

- 목적: 문서 규칙을 유지하면서도 매 작업에서 읽는 기본 토큰 비용을 낮춘다.
- 변경 내용: `AGENTS.md`를 진입 규칙, 경로 분기, 하네스 절차 중심으로 다시 정리했다.
- 변경 내용: `docs/README.md`를 문서 맵과 전역 원칙, 최소 읽기 기준 중심으로 압축했다.
- 변경 내용: `docs/learn/README.md`, `prompts/README.md`에 `followup`과의 역할 경계를 반영했다.

## Step 3. Codex 반복 절차 분리

- 목적: 레포 규칙과 반복 절차를 분리해 하네스 구조를 더 선명하게 만든다.
- 변경 내용: `.codex/README.md`와 `.codex/skills/docs-task-start/SKILL.md`, `.codex/skills/followup-handoff/SKILL.md`를 추가했다.
- 변경 내용: 문서 작업 시작 절차와 followup 갱신 절차는 `.codex/skills/`로 옮기고, 전역 규칙은 `AGENTS.md`와 `README.md` 계층에 남겼다.

## Step 4. 반복 실수 분기와 자동 검증 추가

- 목적: 반복 실수 시 관련 runbook 파일만 다시 읽고, 문서 체계 변경 후 누락 파일과 금지 경로를 자동으로 확인할 수 있게 한다.
- 변경 내용: `.codex/skills/runbook-trigger/SKILL.md`를 추가해 증상 기반 runbook 재읽기 절차를 분리했다.
- 변경 내용: `.codex/skills/doc-governance-check/SKILL.md`와 `.codex/scripts/check-doc-governance.sh`를 추가해 문서 거버넌스 자동 검증 경로를 만들었다.
- 변경 내용: `docs/runbook/README.md`, `docs/runbook/ai-doc-workflow-recovery.md`, `prompts/topics/docs-and-prompt-governance.md`에 자동 검증과 runbook 분기 연결을 반영했다.
- 검증 내용: `.codex/scripts/check-doc-governance.sh` 실행으로 관련 파일 누락, 금지된 `docs/learn/followup` 참조, followup active 정리 상태를 확인했다.
- 판단: 자동 검증은 누락과 금지 패턴 확인용이고, 최종 문서 경계 판단까지 대체하지는 않는다.

## Step 5. 문서 검증과 구현 검증 PASS 게이트 강화

- 목적: 코드 변경이나 계약 문서 변경이 있는 작업은 테스트 PASS 전까지 완료로 간주하지 않도록 닫는다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`가 코드/계약 변경을 감지하면 `verify-and-retry` 경로를 거치지 않은 상태에서 실패를 내도록 바꿨다.
- 변경 내용: `.codex/scripts/verify-and-retry.sh`는 내부에서 `VERIFY_AND_RETRY_ACTIVE=1`로 거버넌스 검증을 호출해, 코드 변경 작업은 PASS가 닫힐 때만 완료될 수 있게 했다.
- 변경 내용: `AGENTS.md`에 코드/계약 변경은 문서 거버넌스만 통과해도 완료가 아니라고 명시했다.
- 판단: 이 변경으로 코드 변경 작업은 문서 정리와 별개로 테스트 PASS 전 완료 금지 원칙이 더 강하게 닫혔다.

## Step 6. 작업 범위 검증과 실패 라우팅 보강

- 목적: dirty worktree 전체가 아니라 현재 작업 파일 범위만 검증하고, 실패 축이 모호할 때 runbook 역할이 흔들리지 않게 한다.
- 변경 내용: `AGENTS.md`, `docs/followup/README.md`, `.codex/scripts/check-doc-governance.sh`, `.codex/scripts/check-doc-implementation.sh`, `.codex/scripts/verify-and-retry.sh`에 `--scope-file` 기반 범위 검증을 추가했다.
- 변경 내용: `.codex/config/failure-route-map.md`에 기존에 정의된 실패 축만 자동 라우팅하고, 새로운 축은 자동 새 runbook 생성 없이 worklog 기록 후 사용자가 분리 여부를 선택하도록 명시했다.
- 변경 내용: `docs/runbook/test-verification-recovery.md`를 유지하면서 구현/테스트 실패를 그쪽으로 모으고, 문서 거버넌스 실패는 `ai-doc-workflow-recovery.md`에 남기도록 역할을 고정했다.
- 변경 내용: `/docs/learn/infra/codex-harness-verification-and-failure-routing.md`에 현재 구조를 로컬 학습용으로 정리했다.
- 검증 내용: 임시 scope 파일로 `check-doc-governance.sh`, `check-doc-implementation.sh --strict`, `verify-and-retry.sh --label scoped-audit`를 실행해 범위 검증이 동작하는 것을 확인했다.
- 판단: 현재 작업 범위 분리와 기존 실패 축 유지에는 확신이 있고, 완전히 새로운 실패 축 자동 생성은 의도적으로 제외했다.

## Step 7. 완료 직전 강한 검증만 닫도록 followup 검증 단계 추가

- 목적: 긴 기능 작업에서 중간 단계마다 강한 검증을 반복하지 않고, 작업을 닫는 시점에만 PASS 게이트를 강제한다.
- 변경 내용: `AGENTS.md`, `docs/README.md`, `docs/followup/README.md`, `docs/followup/000-active-task-template.md`에 followup `현재 상태`의 `검증 단계` 규칙을 추가했다.
- 변경 내용: `.codex/skills/followup-handoff/SKILL.md`, `.codex/skills/implementation-check/SKILL.md`, `.codex/skills/verification-retry/SKILL.md`에 `진행 중`과 `검증 대기` 단계 사용 방식을 반영했다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`, `.codex/scripts/check-doc-implementation.sh`가 scope 파일과 짝인 followup 파일의 `검증 단계`를 읽고, `진행 중`이면 강한 검증 게이트를 유예하도록 바꿨다.
- 판단: 중간 단계에서는 컴파일, 아주 좁은 테스트, sanity check만 선택할 수 있게 하고, 기능 단위를 닫는 시점의 PASS 게이트는 유지하는 쪽이 토큰 비용과 검증 신뢰도 사이 균형이 가장 좋다.

## Step 8. followup active 정리 규칙과 verify-and-retry 시작 조건 보정

- 목적: 진행 중 followup 파일을 정상 상태로 인정하면서도, 완료 직전 검증만 강하게 닫는 규칙이 실제 스크립트와 충돌하지 않게 맞춘다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`가 `docs/followup/active/`에 파일이 하나 남아 있어도 실패하지 않게 바꾸고, 여러 작업 파일이 동시에 남아 있을 때만 실패하게 조정했다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`, `.codex/scripts/check-doc-implementation.sh`, `.codex/scripts/verify-and-retry.sh`에 `--followup-file` 인자를 추가해 표준 scope 경로가 아니어도 followup 연결을 명시할 수 있게 했다.
- 변경 내용: `.codex/scripts/verify-and-retry.sh`는 `검증 단계: 진행 중`인 followup으로 실행되면 시작 단계에서 즉시 실패하도록 바꿨다. 이제 이 스크립트는 `검증 대기` 단계에서만 PASS를 닫는다.
- 판단: 이 보정으로 followup을 세션 복구용으로 실제 사용할 수 있고, 중간 단계에서 실수로 `verify-and-retry`를 돌려 허위 PASS처럼 보이는 문제를 막을 수 있다.

## Step 9. docs/learn 제외 범위와 거버넌스 금지 참조 검사를 일치시킴

- 목적: 공식 검증 제외 경로인 `docs/learn/**` 때문에 문서 거버넌스 검증이 거짓 실패하지 않게 맞춘다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`의 금지된 `docs/learn/followup` 참조 검사에서 `docs/learn/**`를 검색 제외로 바꿨다.
- 판단: 공식 검증 범위에서 제외한 경로는 금지 참조 검사에서도 제외해야 `docs/learn` 설명 문서가 자동 검증을 오염시키지 않는다.

## Step 10. 금지 참조 검사 범위를 공식 기준 문서 쪽으로만 보강

- 목적: 금지된 `docs/learn/followup` 참조를 공식 기준 문서 범위에서만 안정적으로 잡고, worklog나 `.codex` 자기참조 오탐은 피한다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`의 검사 대상에 `prompts/README.md`를 추가하고, 문자열 검색은 `rg -F`로 고정 문자열 매칭으로 바꿨다.
- 판단: `prompts/README.md`는 공식 기준 문서라 검사 대상에 포함하는 편이 맞고, `prompts/worklog/**`와 `.codex/**`는 이 문자열 자체를 설명하는 기록/절차 문서가 있어 현재처럼 제외하는 편이 더 일관된다.

## Step 11. 금지 참조 검사 제외 규칙 원본을 config로 분리

- 목적: 제외 경로가 늘어나도 스크립트 안에 glob를 하드코딩하지 않고, 제외 규칙 원본을 한 곳에서 관리한다.
- 변경 내용: `.codex/config/doc-governance-search-excludes.txt`를 추가하고, `.codex/scripts/check-doc-governance.sh`가 이 파일을 읽어 `rg -g '!<glob>'` 인자를 구성하게 바꿨다.
- 변경 내용: `.codex/config/doc-update-matrix.md`, `.codex/README.md`, `prompts/topics/docs-and-prompt-governance.md`에 제외 glob 원본 위치를 반영했다.
- 판단: 공식 검증 제외 범위와 금지 참조 검사 제외 범위의 원본을 분리된 config 파일 하나로 모아야, 예외 경로가 늘어날 때 문서와 스크립트가 따로 드리프트할 가능성을 줄일 수 있다.

## Step 12. 금지 참조 검사 설정 누락을 조기에 실패로 닫음

- 목적: 금지 참조 검사 exclude config가 빠졌을 때 조용히 동작이 바뀌지 않도록 fail-fast로 막는다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`가 `.codex/config/doc-governance-search-excludes.txt`를 찾지 못하면 즉시 `[FAIL]`로 종료하게 바꿨다.
- 변경 내용: `.codex/config/doc-update-matrix.md`에 `공식 검증 제외 범위`와 `금지 참조 검사 제외 glob`는 역할이 다르다는 설명을 추가했다.
- 판단: 검증 스크립트의 핵심 설정 파일은 없어도 그냥 진행하기보다, 누락을 바로 드러내는 쪽이 확장성과 검증 신뢰도 면에서 낫다.

## Step 13. 진입 규칙과 검증 범위 fallback 메시지를 더 압축

- 목적: 항상 먼저 읽히는 `AGENTS.md`의 중복 설명을 줄이고, scope 없이 전체 변경 세트를 검증하는 비효율을 더 빨리 드러낸다.
- 변경 내용: `AGENTS.md`의 문서 경로 설명을 진입 규칙과 핵심 분류 기준 중심으로 압축하고, 세부 분류는 `docs/README.md`, `prompts/README.md`, 각 경로 `README.md`로 위임했다.
- 변경 내용: `.codex/scripts/check-doc-governance.sh`, `.codex/scripts/check-doc-implementation.sh`, `.codex/scripts/verify-and-retry.sh`가 `--scope-file` 없이 실행되면 `git status` 전체 fallback 사용 중이라는 `[INFO]` 메시지를 출력하게 바꿨다.
- 판단: 잘 스코프된 작업이 더 잘 동작한다는 현재 운영 방향에 맞게, 자주 읽는 문서는 줄이고 넓은 fallback은 더 눈에 띄게 경고하는 편이 토큰과 검증 비용을 함께 줄인다.

## Step 14. main 리베이스 뒤 공식 결정 기록 복구

- 목적: 배포/인프라 기준은 `main`을 유지하되, 하네스가 필요한 공식 의사결정 문맥을 잃지 않게 한다.
- 변경 내용: `docs/decisions/`, `docs/discussions/`, `prompts/topics/`, 과거 worklog를 `docs/##_AI_문서_고도화` 기준으로 복구했다.
- 변경 내용: `main`에서 이미 `REQUIREMENTS`와 explainer에 반영된 document resource 경계의 누락 ADR로 `docs/decisions/022-keep-document-canonical-state-in-db-and-link-external-resources.md`를 추가했다.
- 변경 내용: `docs/followup/000-active-task-template.md`의 빈 항목 trailing whitespace를 정리하고, `prompts/README.md`의 중복 요약 목록을 줄였다.
- 판단: 공식 결정/검토 문서는 저장소에 남기고, 하네스는 README와 topic을 통해 필요한 문서만 좁혀 읽는 방식이 컨텍스트 최소화와 정합성 유지에 더 맞다.
