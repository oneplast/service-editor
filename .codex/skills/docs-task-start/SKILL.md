---
name: "docs-task-start"
description: "문서 작업 시작 시 필요한 기준 문서만 읽고 올바른 경로로 분기하기 위한 절차."
---

# Docs Task Start

이 skill은 문서 작업 시작 시 최소한의 문서만 읽고 올바른 경로로 분기하기 위한 절차다.

## 사용할 때

- `docs/` 문서를 새로 만들거나 수정할 때
- 문서 체계와 규칙을 바꾸는 작업을 시작할 때
- 어떤 공식 문서 경로를 먼저 읽어야 할지 빠르게 정리해야 할 때

## 절차

1. `AGENTS.md`를 읽고 현재 작업이 문서 작업인지 확정한다.
2. `docs/README.md`를 읽고 문서 성격을 분류한다.
3. 대상 경로로 내려가며 필요한 상위 `README.md`만 읽는다.
4. 실제 본문 문서는 현재 작업을 직접 제약하는 것만 읽는다.
5. 문서 체계, followup, topic, `.codex` 절차를 건드리는 작업이면 `.codex/skills/runbook-trigger/SKILL.md`를 따라 `docs/runbook/ai-doc-workflow-recovery.md`를 먼저 읽는다.
6. 반복 실수 징후가 보이면 `.codex/skills/runbook-trigger/SKILL.md`를 따라 관련 runbook 파일 하나만 다시 읽는다.
7. 문서 체계나 규칙을 바꾸는 작업이면 관련 README, 템플릿, worklog를 함께 갱신하고, topic은 링크와 짧은 현재 기준만 보강한다.
8. 긴 작업이 되면 `docs/followup/active/<slug>.md`를 만들고 현재 상태를 압축한다.
9. 문서 체계나 규칙을 바꿨다면 마지막에 `.codex/skills/doc-governance-check/SKILL.md`를 따라 자동 검증을 실행한다.

## 하지 말 것

- 관련 없는 하위 README를 관성적으로 넓게 읽지 않는다.
- 전역 규칙을 하위 README나 템플릿에 다시 복제하지 않는다.
- worklog를 현재 기준 문서처럼 덮어쓰지 않는다.
- topic을 공식 규칙 축약본처럼 키우지 않는다.
