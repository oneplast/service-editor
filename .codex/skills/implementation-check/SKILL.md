---
name: "implementation-check"
description: "코드 변경이나 계약 문서 변경 시 필요한 구현 검증 범위를 판단하고 관련 테스트를 실행하는 절차."
---

# Implementation Check

이 skill은 코드 변경이나 구현 의미를 바꾸는 문서 변경이 있을 때, 어떤 구현 검증이 필요한지 판단하고 관련 Gradle 테스트를 실행하는 절차다.

## 사용할 때

- 제품 코드나 테스트 코드를 수정한 작업
- `docs/REQUIREMENTS.md`, `docs/guides/**`, `docs/decisions/**`를 바꿔 실제 기대 동작이나 계약이 달라진 작업
- 실제 명령, 엔드포인트, 설정 키, 기대 결과가 바뀐 `docs/runbook/**` 작업

## 절차

1. `.codex/config/doc-to-code-check-matrix.md`에서 구현 검증 필요 여부와 기본 테스트 단위를 확인한다.
2. 가능하면 `--scope-file`로 현재 작업 파일 목록을 고정한다.
3. followup 파일이 있으면 `현재 상태`의 `검증 단계`를 먼저 확인한다. `진행 중`이면 필요할 때만 컴파일, 아주 좁은 테스트, sanity check를 고른다.
4. `.codex/scripts/check-doc-implementation.sh --strict --scope-file <path>`를 실행해 현재 변경 세트가 구현 검증 대상인지 확인한다.
5. scope 파일 경로만으로 followup 연결이 어려우면 `--followup-file <path>`를 함께 넘긴다.
6. 코드 변경이나 계약 문서 변경이 `검증 대기` 단계에 들어가면 `.codex/scripts/verify-and-retry.sh --scope-file <path> --followup-file <path> --label <task>`로 테스트와 재검증 루프를 닫는다.
7. 더 좁은 테스트가 부족하거나 여러 모듈이 얽히면 루트 `test`까지 올린다.
8. 결과는 같은 목표의 `prompts/worklog/**` Step에 짧게 남긴다.

## 자동 판별 기준

- 코드 경로 변경 -> 구현 검증 필요
- 계약 문서 변경 -> 구현 검증 필요 여부 재확인
- 단순 표현 정리, 링크 수정, 인덱스 문서 변경 -> 구현 검증 불필요

## 하지 말 것

- 문서 정리만 한 작업에 무조건 전체 테스트를 강제하지 않는다.
- 코드 변경이 있는데 문서 거버넌스 검증만 통과했다고 끝내지 않는다.
- 자동 판별만으로 충분하다고 보고 최종 테스트 범위 판단을 생략하지 않는다.
