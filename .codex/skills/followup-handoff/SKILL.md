---
name: "followup-handoff"
description: "긴 작업이나 세션 복구가 필요한 작업에서 followup 문서를 짧고 일관되게 유지하는 절차."
---

# Followup Handoff

이 skill은 긴 작업이나 세션 복구가 필요한 작업에서 `docs/followup/active/<slug>.md`를 짧게 유지하기 위한 절차다.

## 사용할 때

- 여러 단계 또는 여러 턴에 걸쳐 이어질 가능성이 높은 구현·문서 작업
- 컨텍스트 압축이나 세션 중단 시 목표, 제약, scope, 검증 상태가 유실될 위험이 있는 작업
- 리베이스, 충돌, 복합 검증처럼 다음 세션에서 정확한 상태 복구가 필요한 작업

기준 문서 수가 늘었다는 이유만으로 활성화하지 않는다. 현재 턴 안에 안전하게 완료할 수 있고 복구할 상태가 없는 작업에는 사용하지 않는다.

## 절차

1. `AGENTS.md`와 [docs/followup/README.md](https://github.com/oneplast/service-editor/blob/dev/docs/followup/README.md)를 먼저 확인한다.
2. followup 파일이 없으면 `docs/followup/active/<slug>.md`를 템플릿으로 만든다.
3. followup 파일에는 `목표`, `고정 제약`, `읽은 기준 문서`, `현재 파일 범위`, `현재 상태`, `다음 작업`만 남긴다. 코드/계약 변경 작업이면 `현재 상태` 안에 `검증 단계: 진행 중` 또는 `검증 단계: 검증 대기`를 적는다.
4. 새 사실이 생기면 뒤에 누적하지 말고 현재 상태 기준으로 다시 쓴다.
5. 구현 단계나 검증 단계가 바뀌거나 턴을 마치기 전에 followup 파일을 갱신한다.
6. 다음 세션에서는 followup 파일 1개와 그 파일이 가리키는 기준 문서만 다시 읽고 재개한다.

## 하지 말 것

- worklog처럼 상세 이력을 누적하지 않는다.
- 짧은 질문, 한 번에 끝나는 수정, 단순 검증에 followup을 만들지 않는다.
- 공식 정책, ADR, 요구사항을 followup 파일에 복사하지 않는다.
- 여러 작업을 한 파일에 섞지 않는다.
