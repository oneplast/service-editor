---
name: "commit-stage"
description: "사용자가 특정 작업, 범위, 주제에 관련된 변경만 stage(git add)해 달라고 요청할 때 사용하는 절차. $commit-stage 뒤에 작업 설명을 붙여 호출하면 변경 세트를 선별해 해당 작업과 직접 관련된 파일만 stage한다."
---

# Commit Stage

이 skill은 `git add .`를 수행하는 절차가 아니다. 사용자가 말한 작업 범위와 직접 관련된 변경만 선별해 stage한다.

예: `$commit-stage worklog 템플릿 작업`, `$commit-stage commit message skill 작업`

## 기본 원칙

- 사용자가 지정한 작업 범위와 명확히 연결되는 파일만 stage한다.
- 현재 대화에 이미 있는 작업 맥락은 후보 축소에만 사용하고, 최종 stage 여부는 Git 상태와 최소 diff로 확인한다.
- followup이나 worklog는 기본으로 읽지 않고, 세션이 끊겼거나 범위가 불명확할 때만 최소 확인한다.
- 전체 `git diff` 본문은 기본으로 실행하지 않는다. 후보가 좁혀지지 않을 때 `git diff --stat`을 먼저 보고, 마지막 fallback으로 필요한 경로의 diff만 확인한다.
- `git add .`, `git add -A`, 넓은 glob stage를 사용하지 않는다.
- ignored 파일은 stage하지 않는다.
- 기존 staged 변경이 요청 범위와 무관하거나 커밋 단위가 불명확하면 stage하지 않고 사용자에게 확인한다.
- staged 변경을 임의로 unstage하지 않는다. 정리가 필요하면 사용자에게 확인한다.

## 확인 순서

1. 사용자 요청과 현재 대화에서 이미 확인된 맥락으로 후보 범위를 좁힌다.
2. `git status --short`로 staged, unstaged, untracked 상태를 확인한다.
3. 이미 staged된 파일이 있으면 현재 요청 범위와 같은 커밋 단위인지 판단한다.
4. 후보가 좁혀지면 후보 파일만 `git diff -- <path>`로 확인한다.
5. 후보가 좁혀지지 않으면 `git diff --stat`으로 전체 변경 요약을 본 뒤 경로와 파일명으로 후보를 다시 좁힌다.
6. 그래도 판단할 수 없을 때만 필요한 경로의 diff 본문을 확인한다.
7. untracked 파일은 경로와 이름만으로 부족할 때만 내용을 최소 확인한다.
8. ignored 여부가 의심되는 파일은 `git check-ignore -- <path>`로 확인하고 제외한다.
9. stage 대상이 확정되면 `git add -- <path>...`처럼 명시 경로만 사용한다.
10. `git diff --cached --name-only`와 `git diff --cached --stat`으로 결과를 확인한다.

## 판단 기준

- 같은 작업의 구현 파일, 직접 관련 테스트, 직접 관련 문서 또는 worklog는 함께 stage할 수 있다.
- 같은 세션에서 수정됐어도 요청한 작업과 직접 관련이 없으면 stage하지 않는다.
- 단순히 파일이 가까운 경로에 있다는 이유만으로 stage하지 않는다.
- 삭제 파일도 요청 범위와 직접 관련될 때만 stage한다.
- 새 skill, script, template처럼 새 파일이 작업의 핵심 산출물이면 포함한다.

## 출력 기준

- stage한 파일 목록을 짧게 보여준다.
- stage하지 않은 애매한 후보가 있으면 따로 보여준다.
- stage할 파일이 없으면 아무 것도 stage하지 않고 이유를 말한다.
- 사용자가 커밋 메시지 작성까지 요청한 경우에만 staging 완료 후 `commit-msg` 절차를 이어서 사용한다.
