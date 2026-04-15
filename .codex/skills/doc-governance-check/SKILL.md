---
name: "doc-governance-check"
description: "문서 체계나 규칙 변경 뒤 최신화 대상과 제외 대상을 판별하고 문서 거버넌스 자동 검증을 수행하는 절차."
---

# Doc Governance Check

이 skill은 문서 체계나 규칙 변경 후, 기존 문서 규칙을 기준으로 최신화 대상과 제외 대상을 판별하고 자동 검증하는 절차다.

## 사용할 때

- `AGENTS.md`, `docs/README.md`, 하위 `README.md`, 템플릿, `.codex/skills/`를 함께 건드린 작업
- 문서 체계나 규칙을 바꾼 작업
- followup, runbook, prompts topic 경계를 조정한 작업
- 반복 에러를 기존 runbook에 새 케이스로 반영한 작업

## 절차

1. 관련 파일 변경을 마친다.
2. `.codex/config/doc-update-matrix.md`에서 작업 유형별 최신화 기준과 편집 모드를 확인한다.
3. `.codex/scripts/check-doc-governance.sh`를 실행한다.
4. 스크립트 출력에서 빠진 동반 문서나 금지 경로 참조가 있으면 해당 파일을 다시 고친다.
5. 코드 변경이나 구현 의미를 바꾸는 문서 변경이 있었다면 `.codex/scripts/verify-and-retry.sh --runbook <path>`로 재시도 루프까지 닫는다.
6. 스크립트가 통과해도 사람이 마지막으로 요구사항 변경 여부, discussion/ADR 필요 여부, 같은 주제/같은 결정 여부를 확인한다.

## 편집 모드 요약

- `correct_in_place`: 공식 기준 문서는 기존 내용을 직접 고쳐 최신 기준으로 유지한다.
- `topic_scoped_correction`: 같은 주제면 기존 파일을 보강한다.
- `decision_scoped_file`: 같은 결정 문서는 보정하고, 새 결정이면 새 ADR 파일을 만든다.
- `goal_scoped_log`: 같은 사용자 목표는 기존 worklog 파일에 Step을 누적한다.
- `rewrite_snapshot`: followup active 파일은 최신 상태만 남긴다.
- `local_excluded`: `docs/learn/**`는 공식 검증 대상에서 제외한다.

## 자동 검증 항목

- 변경 세트 기반 작업 유형 추정
- 작업 유형별 필수 문서 최신화 여부
- 조건부 문서 최신화 누락 여부
- 금지된 `docs/learn/followup` 참조 존재 여부
- `docs/followup/active` 정리 상태
- `.codex/skills/`와 prompts governance 연결 여부
- 반복 에러 처리 시 관련 runbook 파일이 반영됐는지
- 구현 검증이 필요한 변경인지 여부 안내

## 하지 말 것

- 스크립트 통과만으로 검토가 끝났다고 가정하지 않는다.
- `docs/learn/` 변경을 공식 문서 최신화 누락으로 해석하지 않는다.
- 의미론 판단까지 자동 검증에 맡기지 않는다.
