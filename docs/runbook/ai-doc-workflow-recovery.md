# AI Document Workflow Recovery

## 언제 읽는가

- 문서 작업에서 같은 실수가 반복될 때
- 세션이 길어지면서 문서 읽기 순서나 경로 판단이 흔들릴 때
- 세션이 끊겼다가 다시 시작해 현재 작업과 제약을 다시 맞춰야 할 때
- followup 없이 긴 작업을 진행해 복구 비용이 커졌을 때
- 어떤 문서를 먼저 읽어야 하는지 판단이 흐려졌을 때

문서 체계, README, topic, followup, `.codex` 절차를 수정한다는 이유만으로 선행 로드하지 않는다.

## 먼저 다시 볼 원문

- `AGENTS.md`
- 현재 증상과 직접 관련된 README 또는 원문 문서
- 세션 복구 중이면 현재 followup 파일
- 반복 검증 실패면 관련 config 또는 script

## 작업 전 체크포인트

- 현재 실패나 흔들림의 증상을 한 문장으로 고정했는가
- 문서 수정 작업이면 `AGENTS.md -> docs/README.md -> 대상 경로 README` 순서로 읽었는가
- topic에는 링크와 짧은 현재 기준만 남기고 있는가
- 전역 규칙을 하위 README, 템플릿, skill에 다시 복제하지 않았는가
- 긴 작업이면 followup과 scope를 먼저 고정했는가
- 세션 재개라면 followup의 `목표`, `고정 제약`, `현재 상태`, `다음 작업`을 먼저 다시 읽었는가

## 검증/자기점검 때 볼 분기

- 읽기 순서가 흔들리거나 상위 기준을 다시 못 설명하겠으면 `상위 README 누락`
- 문서 위치가 애매하거나 경로를 다시 고르게 되면 `문서 경로 오분류`
- 세션 재개 직후 현재 작업과 다음 액션이 바로 안 잡히면 `followup 누락`
- topic이 커지거나 절차형 내용이 들어가면 `인덱스 문서 과적재`
- 같은 규칙이 여러 파일에 보이거나 하위 문서가 더 길어지면 `규칙 중복 복제`

## 반복 실수/실패 사례

### 1. 상위 README 누락

- 증상: 대상 문서만 바로 열고 수정한다.
- 원인: 문서 읽기 순서를 작업 시작 전에 다시 고정하지 않았다.
- 복구: `AGENTS.md -> docs/README.md -> 대상 경로 README -> 대상 문서` 순서로 다시 읽는다.
- 방지: `docs-routing` 게이트가 활성화된 문서 생성·수정 작업에서 `.codex/skills/docs-task-start/SKILL.md` 절차를 따른다.

### 2. 문서 경로 오분류

- 증상: 운영 절차, worklog, 공식 기준 문서를 서로 다른 경로에 섞어 둔다.
- 원인: 현재 문서가 기록인지 기준인지 복구용 상태인지 먼저 구분하지 않았다.
- 복구: `docs/README.md`, `prompts/README.md`, `docs/followup/README.md` 중 현재 문서 성격에 맞는 README만 다시 읽는다.
- 방지: 본문 작성 전에 문서 목적을 한 문장으로 먼저 적고 경로를 결정한다.

### 3. followup 누락

- 증상: 여러 단계 작업인데 현재 상태 문서가 없다.
- 원인: 긴 작업으로 바뀌는 시점을 followup 생성 트리거로 인식하지 못했다.
- 복구: `docs/followup/000-active-task-template.md`로 `active/<slug>.md`를 만들고 목표, 고정 제약, 읽은 기준 문서, 현재 파일 범위, 현재 상태, 다음 작업만 적는다.
- 방지: 여러 턴을 넘기거나 목표, 제약, scope, 검증 상태의 복구 위험이 생기면 followup을 만든다.

### 4. 인덱스 문서 과적재

- 증상: `prompts/topics/`에 상세 디버깅 절차나 반복 실수 설명을 길게 넣는다.
- 원인: topic을 운영 문서가 아니라 인덱스라는 점을 잊었다.
- 복구: topic에는 링크와 짧은 현재 기준만 남기고, 절차형 내용은 runbook이나 공식 문서로 옮긴다.
- 방지: topic 수정 전 [prompts/topics/README.md](https://github.com/jho951/Block-server/blob/dev/prompts/topics/README.md)를 다시 확인한다.

### 5. 규칙 중복 복제

- 증상: 전역 규칙을 하위 README, 템플릿, skill에 다시 적는다.
- 원인: 선언과 절차를 같은 파일에 모두 담으려 했다.
- 복구: 공식 기준 문서는 `correct_in_place`, topic은 `topic_scoped_correction`, worklog는 `goal_scoped_log`, followup은 `rewrite_snapshot` 원칙을 다시 적용한다.
- 방지: 문서 체계 변경 후 `AGENTS.md`, 대상 README, 관련 skill, `.codex/config/doc-update-matrix.md`를 함께 대조한다.

## 실패 후 복구 순서

1. 위 `검증/자기점검 때 볼 분기`에서 가장 가까운 항목 하나를 고른다.
2. `먼저 다시 볼 원문`에서 필요한 파일만 다시 읽는다.
3. 세션 재개 작업이거나 상태가 흐려졌다면 followup의 `현재 상태`와 `다음 작업`을 먼저 다시 맞춘다.
4. 필요한 경우 followup 파일을 만든다.
5. 문서 체계나 규칙을 바꿨다면 `.codex/scripts/check-doc-governance.sh`를 실행한다.
6. 같은 실패 축이 확인되면 이 문서에 새 케이스를 추가하거나 기존 항목을 보강한다.

## 반복 케이스를 추가해야 하는 경우

- 위 문제 축에서 새로운 변형이 다시 발생했다.
- 기존 항목의 복구 절차가 실제 반복 에러를 막기엔 부족했다.
- 같은 증상이 다른 경로나 다른 문서 유형에서도 반복됐다.

반복 케이스가 발생하면 이 문서 안에 새 케이스를 추가하거나 기존 항목을 보강한다. runbook 반영 없이 끝내지 않는다.
