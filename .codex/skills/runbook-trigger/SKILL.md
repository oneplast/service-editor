---
name: "runbook-trigger"
description: "관련 작업 축에 맞는 runbook 파일 하나만 먼저 읽고, 반복 실수나 이상 징후가 보이면 같은 파일로 다시 분기하는 절차."
---

# Runbook Trigger

이 skill은 관련 작업 축에 맞는 runbook 파일 하나만 먼저 읽고, 반복 실수나 작업 이상 징후가 보일 때도 같은 파일로 다시 분기하는 절차다.

## 사용할 때

- 문서 체계, followup, topic, `.codex` 절차를 수정하기 전
- 구현 검증, 테스트, `verify-and-retry` 계열 작업을 시작하기 전
- 같은 문서 작업 실수가 두 번 이상 반복될 때
- 읽기 순서, 경로 분류, followup 사용 여부가 흔들릴 때
- 인덱스 문서에 절차형 내용을 넣으려 할 때
- 전역 규칙을 하위 문서나 skill에 다시 적으려 할 때

## 절차

1. 현재 작업이 문서 거버넌스 축인지, 구현 검증 축인지 먼저 고른다.
2. `docs/runbook/README.md`의 선택 기준을 다시 읽는다.
3. 문서 거버넌스 축이면 `docs/runbook/ai-doc-workflow-recovery.md`, 구현 검증 축이면 `docs/runbook/test-verification-recovery.md`를 먼저 읽는다.
4. 정상 작업이면 `작업 전 체크포인트`만 먼저 확인하고 시작한다.
5. 검증 직전, 세션 재개 직후, 작업 방향이 흔들릴 때는 같은 runbook의 `검증/자기점검 때 볼 분기`에서 가장 가까운 항목 하나를 고른다.
6. 그 항목이 요구하는 원문 문서와 followup 상태를 다시 읽고 작업을 이어간다.
7. 같은 문제 축이 확인되면 기존 runbook 파일에 새 케이스를 추가하거나 기존 항목을 보강한다.
8. 문서 거버넌스 축을 반영했다면 `.codex/scripts/check-doc-governance.sh repeated-error-case-update`를 실행한다.

## 하지 말 것

- runbook 디렉토리 전체를 넓게 읽지 않는다.
- 증상을 정리하지 않은 채 감으로 여러 문서를 다시 열지 않는다.
- topic 문서에 복구 절차를 길게 적지 않는다.
- 반복 에러를 runbook 갱신 없이 끝내지 않는다.
