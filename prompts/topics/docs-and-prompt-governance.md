# Docs And Prompt Governance

## 목적

문서 저장소 운영 규칙, `AGENTS.md` 정리, 디렉토리 README 체계, followup 복구 경로, 프롬프트 로그 운영 규칙, 문서-구현 검증 경계를 다시 찾기 쉽게 묶는다.

## 관련 worklog

- [2026-03-13-agents-repository-context.md](https://github.com/jho951/Block-server/blob/dev/prompts/worklog/2026-03/2026-03-13-agents-repository-context.md)
- [2026-03-31-agents-and-directory-guide-cleanup.md](https://github.com/jho951/Block-server/blob/dev/prompts/worklog/2026-03/2026-03-31-agents-and-directory-guide-cleanup.md)
- [2026-03-31-troubleshooting-doc-system.md](https://github.com/jho951/Block-server/blob/dev/prompts/worklog/2026-03/2026-03-31-troubleshooting-doc-system.md)
- [2026-04-07-docs-governance-dedup-and-readability.md](https://github.com/jho951/Block-server/blob/dev/prompts/worklog/2026-04/2026-04-07-docs-governance-dedup-and-readability.md)
- [2026-04-14-followup-harness-and-doc-governance.md](https://github.com/jho951/Block-server/blob/dev/prompts/worklog/2026-04/2026-04-14-followup-harness-and-doc-governance.md)

## 관련 문서

- [AGENTS.md](https://github.com/jho951/Block-server/blob/dev/AGENTS.md)
- [docs/README.md](https://github.com/jho951/Block-server/blob/dev/docs/README.md)
- [docs/followup/README.md](https://github.com/jho951/Block-server/blob/dev/docs/followup/README.md)
- [docs/runbook/README.md](https://github.com/jho951/Block-server/blob/dev/docs/runbook/README.md)
- [docs/runbook/ai-doc-workflow-recovery.md](https://github.com/jho951/Block-server/blob/dev/docs/runbook/ai-doc-workflow-recovery.md)
- [docs/runbook/test-verification-recovery.md](https://github.com/jho951/Block-server/blob/dev/docs/runbook/test-verification-recovery.md)
- [.codex/README.md](https://github.com/jho951/Block-server/blob/dev/.codex/README.md)
- [.codex/config/doc-update-matrix.md](https://github.com/jho951/Block-server/blob/dev/.codex/config/doc-update-matrix.md)
- [.codex/config/doc-to-code-check-matrix.md](https://github.com/jho951/Block-server/blob/dev/.codex/config/doc-to-code-check-matrix.md)
- [.codex/config/failure-route-map.md](https://github.com/jho951/Block-server/blob/dev/.codex/config/failure-route-map.md)
- [prompts/README.md](https://github.com/jho951/Block-server/blob/dev/prompts/README.md)
- [prompts/topics/README.md](https://github.com/jho951/Block-server/blob/dev/prompts/topics/README.md)

## 현재 기준

- `AGENTS.md`는 진입 규칙과 작업 절차를 담당한다.
- 문서 전역 규칙은 `docs/README.md`가 담당한다.
- 디렉토리별 상세 작성 기준은 각 경로 `README.md`가 담당한다.
- `docs/discussions/`와 `docs/decisions/`는 컨텍스트 절약을 위해 삭제하는 경로가 아니라, 필요할 때 README와 관련 문서에서 따라가는 공식 근거 경로다.
- 세션 복구와 진행 중 작업 handoff는 `docs/followup/`가 담당한다.
- 문서 거버넌스와 구현 검증 경계는 `.codex/config/*`, `.codex/scripts/*`, 관련 runbook이 담당한다.
- 원본 작업 로그는 `prompts/worklog/`, 주제별 탐색 문서는 `prompts/topics/`에서 관리한다.
- 상세 운영 규칙은 이 topic에 다시 복제하지 않고, 위 관련 문서를 기준으로 본다.

## 열어둘 질문

- topic 문서의 `현재 기준`을 지금보다 더 짧게 제한할지 여부
- `prompts/plans/`의 장기 유지 필요 여부
