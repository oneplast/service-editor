---
name: "doc-governance-check"
description: "문서 체계나 규칙 변경 뒤 최신화 대상과 제외 대상을 판별하고 문서 거버넌스 자동 검증을 수행하는 절차."
---

# Doc Governance Check

이 skill은 문서 체계나 규칙 변경 후, 기존 문서 규칙을 기준으로 최신화 대상과 제외 대상을 판별하고 자동 검증하는 절차다.

이 skill은 코드·설정 변경의 문서 영향을 판정하거나 `doc-update`를 활성화하지 않는다. 메인 에이전트가 문서 체계·규칙·workflow 계약 변경으로 확정한 변경의 동반 문서와 규칙 정합성만 검증한다.

## 사용할 때

- 문서 체계나 규칙을 바꾼 작업
- 규칙 소유 위치, README 계층, 템플릿, 문서 작업 절차를 바꾼 작업
- followup, runbook, prompts topic 경계를 조정한 작업
- 반복 에러 처리 규칙이나 runbook 운영 계약을 바꾼 작업

일반 문서 본문, 오타, 링크, 표현만 정리한 작업에는 사용하지 않는다.
문서 영향이 `DOC_NONE`인 코드·설정 변경에는 사용하지 않는다.
문서 영향이 `DOC_REQUIRED`라도 제품 요구사항·계약 문서만 갱신하고 문서 체계나 규칙을 바꾸지 않았다면 사용하지 않는다.

## 절차

1. 관련 파일 변경을 마친다.
2. 메인 에이전트가 확정한 변경 성격이 `.codex/config/doc-update-matrix.md`의 문서 거버넌스 계열 변경인지 확인한다. 입력과 scope·diff가 어긋나면 `.codex/config/gate-state-contract.md` 형식으로 `UNCLASSIFIED`를 반환한다.
3. `.codex/config/doc-update-matrix.md`에서 해당 게이트의 최신화 기준과 편집 모드를 확인한다.
4. scope와 확정한 변경 성격을 `--scope-file`, `--change-kind`로 명시해 `.codex/scripts/check-doc-governance.sh`를 실행한다. 긴 작업이면 `--result-file`을 `docs/followup/active/.state/`에 둔다.
5. 스크립트 출력에서 빠진 동반 문서나 금지 경로 참조가 있으면 해당 파일을 다시 고친다.
6. 코드 변경이나 구현 의미를 바꾸는 문서 변경이 확인되면 구현 검증 필요 신호를 메인 에이전트에 반환한다.
7. 스크립트가 통과해도 메인 에이전트 또는 사람이 요구사항 변경 여부, discussion/ADR 필요 여부, 같은 주제/같은 결정 여부를 마지막으로 확인한다.

## 편집 모드 요약

- `correct_in_place`: 공식 기준 문서는 기존 내용을 직접 고쳐 최신 기준으로 유지한다.
- `topic_scoped_correction`: 같은 주제면 기존 파일을 보강한다.
- `decision_scoped_file`: 같은 결정 문서는 보정하고, 새 결정이면 새 ADR 파일을 만든다.
- `goal_scoped_log`: 같은 사용자 목표는 기존 worklog 파일에 Step을 누적한다.
- `rewrite_snapshot`: followup active 파일은 최신 상태만 남긴다.
- `local_excluded`: `docs/learn/**`는 공식 검증 대상에서 제외한다.

## 자동 검증 항목

- 변경 세트 기반 작업 유형 후보 탐지
- 명시된 변경 성격 기반 게이트 판정
- 문서 거버넌스 변경 유형별 필수 동반 문서 갱신 여부
- 문서 체계·규칙·workflow 계약 변경의 조건부 동반 문서 누락 여부
- 금지된 `docs/learn/followup` 참조 존재 여부
- `docs/followup/active` 정리 상태
- `.codex/skills/`와 prompts governance 연결 여부
- 메인 에이전트가 별도 판정할 구현 검증 필요 후보 안내

## 하지 말 것

- 스크립트 통과만으로 검토가 끝났다고 가정하지 않는다.
- 일반 제품 문서 갱신 여부를 이 skill에서 판정하지 않는다.
- `DOC_REQUIRED`만으로 이 skill을 활성화하지 않는다.
- 구현 검증 게이트를 직접 활성화하거나 구현 검증을 실행하지 않는다.
- `.codex` 경로가 바뀌었다는 이유만으로 workflow 계약 변경을 확정하지 않는다.
- `docs/learn/` 변경을 공식 문서 최신화 누락으로 해석하지 않는다.
- 의미론 판단까지 자동 검증에 맡기지 않는다.
- 메인이 확정하지 않은 변경 성격을 이 skill에서 임의로 확정하지 않는다.
- 재분류가 끝나면 중단된 이 skill 절차부터 재개하고, 앞선 게이트를 처음부터 반복하지 않는다.
