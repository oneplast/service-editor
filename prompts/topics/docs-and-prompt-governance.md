# Docs And Prompt Governance

## 목적

문서 저장소 운영 규칙, `AGENTS.md` 정리, 디렉토리 README 체계, followup 복구 경로, 프롬프트 로그 운영 규칙, 문서-구현 검증 경계를 다시 찾기 쉽게 묶는다.

## 관련 worklog

- [2026-03-13-agents-repository-context.md](https://github.com/oneplast/service-editor/blob/dev/prompts/worklog/2026-03/2026-03-13-agents-repository-context.md)
- [2026-03-31-agents-and-directory-guide-cleanup.md](https://github.com/oneplast/service-editor/blob/dev/prompts/worklog/2026-03/2026-03-31-agents-and-directory-guide-cleanup.md)
- [2026-03-31-troubleshooting-doc-system.md](https://github.com/oneplast/service-editor/blob/dev/prompts/worklog/2026-03/2026-03-31-troubleshooting-doc-system.md)
- [2026-04-07-docs-governance-dedup-and-readability.md](https://github.com/oneplast/service-editor/blob/dev/prompts/worklog/2026-04/2026-04-07-docs-governance-dedup-and-readability.md)
- [2026-04-14-followup-harness-and-doc-governance.md](https://github.com/oneplast/service-editor/blob/dev/prompts/worklog/2026-04/2026-04-14-followup-harness-and-doc-governance.md)
- [2026-06-19-conditional-harness-transition.md](https://github.com/oneplast/service-editor/blob/dev/prompts/worklog/2026-06/2026-06-19-conditional-harness-transition.md)

## 관련 문서

- [AGENTS.md](https://github.com/oneplast/service-editor/blob/dev/AGENTS.md)
- [docs/README.md](https://github.com/oneplast/service-editor/blob/dev/docs/README.md)
- [docs/followup/README.md](https://github.com/oneplast/service-editor/blob/dev/docs/followup/README.md)
- [docs/runbook/README.md](https://github.com/oneplast/service-editor/blob/dev/docs/runbook/README.md)
- [docs/runbook/ai-doc-workflow-recovery.md](https://github.com/oneplast/service-editor/blob/dev/docs/runbook/ai-doc-workflow-recovery.md)
- [docs/runbook/test-verification-recovery.md](https://github.com/oneplast/service-editor/blob/dev/docs/runbook/test-verification-recovery.md)
- [.codex/README.md](https://github.com/oneplast/service-editor/blob/dev/.codex/README.md)
- [.codex/config/doc-update-matrix.md](https://github.com/oneplast/service-editor/blob/dev/.codex/config/doc-update-matrix.md)
- [.codex/config/doc-to-code-check-matrix.md](https://github.com/oneplast/service-editor/blob/dev/.codex/config/doc-to-code-check-matrix.md)
- [.codex/config/failure-route-map.md](https://github.com/oneplast/service-editor/blob/dev/.codex/config/failure-route-map.md)
- [.codex/config/subagent-task-contract.md](https://github.com/oneplast/service-editor/blob/dev/.codex/config/subagent-task-contract.md)
- [.codex/skills/subagent-orchestration/SKILL.md](https://github.com/oneplast/service-editor/blob/dev/.codex/skills/subagent-orchestration/SKILL.md)
- [prompts/README.md](https://github.com/oneplast/service-editor/blob/dev/prompts/README.md)
- [prompts/topics/README.md](https://github.com/oneplast/service-editor/blob/dev/prompts/topics/README.md)

## 현재 기준

- `AGENTS.md`는 항상 적용되는 최상위 계약과 Direct, Scoped, Harness 작업 수준 및 독립 게이트를 담당한다.
- 문서 전역 규칙과 디렉토리별 상세 기준은 `docs/README.md`와 각 경로 `README.md`가 담당한다.
- README, skill, script, runbook, followup, prompts, subagent는 작업 조건에 맞는 게이트가 활성화될 때만 확장한다.
- 메인 에이전트가 초기 작업 수준과 게이트를 판정하고, skill과 script는 확정된 입력을 재사용하거나 새 위험 신호만 반환한다.
- subagent는 역할별 상시 분업자가 아니라 bounded task와 중복 컨텍스트 비용 대비 이득이 명확할 때만 task packet으로 호출하는 선택적 capability이며, 호출 절차와 결과 통합은 subagent-orchestration skill을 따르고 최종 통합과 완료 선언은 메인 에이전트가 소유한다.
- 변경 경로는 후보 탐지에만 사용하고, 문서 체계·workflow 계약·구현 계약의 실제 변경 여부는 diff 기준 변경 성격으로 확정한다.
- 코드·설정 변경은 `DOC_REQUIRED`, `DOC_NONE`, `DOC_UNDETERMINED`로 문서 영향을 먼저 판정하고 필요한 경우에만 공식 문서를 갱신한다.
- `DOC_REQUIRED`의 제품 문서 최신화와 문서 체계·규칙 변경의 `doc-governance`는 별도 게이트로 유지한다.
- `doc-impact`가 문서 갱신 필요 여부를 판정하고, `docs-routing`과 `doc-update`가 대상 문서를 찾고 갱신하며, `doc-governance`는 문서 체계·규칙·workflow 계약 변경만 검증한다.
- 국소 오타, 표현, 깨진 링크 정리는 `doc-governance`를 열지 않지만, 여러 문서 경로에 같은 기준을 적용하거나 문서 운영 경계를 판단해야 하면 후보로 올린다.
- followup은 복구할 상태가 있는 긴 작업에만 사용하고, runbook은 실패·반복 실수·복구 신호가 있을 때만 읽는다.
- `prompts/`는 기본 읽기 대상에서 제외하고 기록, 같은 목표 재개, 과거 의도 복구가 필요할 때만 관련 파일 하나부터 확인한다.
- 기존 규칙과 근거 경로는 유지하며, 상세 운영 규칙은 이 topic에 복제하지 않고 각 소유 문서를 기준으로 본다.
