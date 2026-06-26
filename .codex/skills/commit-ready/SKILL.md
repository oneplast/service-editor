---
name: "commit-ready"
description: "사용자가 특정 작업을 기준으로 관련 변경을 stage한 뒤 그 staged 변경 기준으로 커밋 메시지 초안까지 작성해 달라고 요청할 때 사용하는 절차. $commit-ready 뒤에 작업 설명을 붙여 호출하면 commit-stage 후 commit-msg 순서로 실행한다."
---

# Commit Ready

이 skill은 커밋 실행용이 아니다. 사용자가 지정한 작업 범위로 stage를 준비하고, 그 staged 변경 기준으로 커밋 메시지 초안을 작성한다.

## 실행 모델

1. `commit-stage` 절차로 사용자가 지정한 작업 범위와 직접 관련된 파일만 stage한다.
2. staging이 성공하고 staged 범위가 요청과 일치할 때만 `commit-msg` 절차로 메시지 초안을 작성한다.
3. 범위가 애매하거나 기존 staged 변경과 충돌하면 메시지 작성으로 넘어가지 않는다.
4. 실제 `git commit`은 사용자가 별도로 명시적으로 요청한 경우에만 수행한다.

## 기본 원칙

- `commit-stage`와 `commit-msg`의 책임을 중복 구현하지 않는다.
- `git add .`, `git add -A`, 넓은 glob stage를 사용하지 않는다.
- ignored 파일은 stage하지 않고 커밋 메시지에도 포함하지 않는다.
- 기존 staged 변경이 요청 범위와 무관하면 진행을 멈추고 사용자 확인을 받는다.
- staging 결과가 비어 있으면 커밋 메시지를 작성하지 않는다.
- staging 후 `git diff --cached --name-only`와 `git diff --cached --stat`으로 기준을 확인한다.
- 커밋 메시지는 staged diff 기준으로만 작성한다.

## 출력 기준

- staging 결과는 기본적으로 staged 파일 개수와 stat 요약만 짧게 보여준다.
- 파일 목록은 stage 대상이 적거나, 제외/애매한 후보가 있거나, 사용자가 요청한 경우에만 보여준다.
- 이어서 커밋 제목과 본문 초안을 제시한다.
- 자세한 stage 상태는 `git status --short`로 확인할 수 있음을 안내한다.
- 커밋은 하지 않는다.
