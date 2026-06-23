# Project Codex Helpers

이 경로는 저장소 전역 규칙을 다시 적는 곳이 아니라, 반복 가능한 Codex 작업 절차와 자동 검증 보조 도구를 두는 보조 경로다.

- 레포 규칙과 문서 소유 위치는 `AGENTS.md`와 `README.md` 계층을 기준으로 본다.
- `.codex/`는 모든 작업의 기본 진입 경로가 아니다. `skill`, `script`, 검증, 실패 복구 게이트가 활성화됐을 때 필요한 파일만 읽는다.
- `.codex/skills/`에는 반복 가능한 작업 절차만 두고, 각 `SKILL.md`는 최소 YAML frontmatter(`name`, `description`)를 포함한다.
- skill의 발동 조건을 만족해 읽었더라도 관련 config와 script를 자동으로 모두 읽거나 실행하지 않는다.
- `.codex/scripts/`에는 사람이 직접 실행하거나 skill에서 참조하는 자동 검증 스크립트를 둔다.
- `.codex/config/`에는 문서 영향 판정, 문서 갱신·거버넌스 기준, 제외 범위, 금지 참조 검사 제외 glob, 구현 검증 트리거를 둔다.
- 독립 게이트의 `PASS`, `FAIL`, `UNCLASSIFIED` 공통 상태와 재개 계약은 `.codex/config/gate-state-contract.md`를 원본으로 본다.
- `FAIL`은 실패한 검증과 입력·scope, 실패 요약, 재개 지점을 함께 반환한다. 재시도 절차는 이 정보를 재사용하고 실패 확인을 위한 선행 재실행을 하지 않는다.
- 실패 수정 뒤에는 입력이나 직접 의존 대상이 달라진 선행 `PASS`만 무효화하고, 영향 없는 `PASS`는 재사용한다. 무효화는 새 게이트 상태가 아니라 기존 검증 증거의 효력 관리다.
- 문서 영향 결과는 `DOC_REQUIRED`, `DOC_NONE`, `DOC_UNDETERMINED`를 사용하고 공통 게이트 상태와 구분한다.
- config matrix는 변경 경로를 후보 탐지에 사용하고, 명시된 변경 성격을 실제 게이트 판정에 사용한다.
- 의미를 확정할 수 없는 계약 문서 변경은 전체 테스트로 자동 승격하지 않고 `UNCLASSIFIED`로 남긴다.
- 코드·설정 변경은 메인 에이전트가 문서 영향 게이트를 먼저 판정하고, `DOC_REQUIRED`일 때만 문서 라우팅과 최신화를 활성화한다.
- `doc-update`와 `doc-governance`를 분리한다. 제품 문서 최신화만 필요한 작업은 문서 체계 검증으로 자동 승격하지 않는다.
- `doc-impact`는 문서 갱신 필요 여부를 판정하고, `docs-routing`과 `doc-update`는 필요한 문서를 찾아 갱신하며, `doc-governance`는 문서 체계·규칙·workflow 계약 변경만 검증한다.
- skill과 script는 메인 에이전트가 확정한 게이트 입력을 사용하며, 같은 초기 판정을 독립적으로 반복하지 않는다.
- skill은 수행 중 발견한 추가 위험을 신호로 반환하며 다른 독립 게이트를 직접 활성화하지 않는다.
- runbook 경로 후보는 config나 script가 반환할 수 있지만, runbook 게이트 활성화와 실제 기록은 메인 에이전트가 실패 축을 확정한 뒤 수행한다.
- 프로젝트별 세션 복구와 handoff 기준은 `docs/followup/`을 따른다.
- 문서 체계 검증은 `.codex/scripts/check-doc-governance.sh`, 구현 검증 필요 여부 판별과 테스트 실행은 `.codex/scripts/check-doc-implementation.sh`를 기준으로 한다.
- 검증 실패 재검증과 메인이 확정한 실패 케이스 기록은 `.codex/config/failure-route-map.md`, `.codex/scripts/verify-and-retry.sh`, `.codex/skills/verification-retry/SKILL.md`를 기준으로 한다.
- 구현 검증의 경로별 태스크와 로컬 제외 테스트는 `.codex/config/doc-to-code-check-matrix.md`를 원본으로 본다.
- `AGENTS.md`는 게이트 존재와 상위 활성화 원칙, README는 경로 규칙, config는 세부 판정 기준, skill은 실행 절차, script는 입력·출력과 기계적 실행을 소유한다.
- 하위 파일은 상위 원칙을 다시 정의하지 않고, 자신의 역할에 필요한 세부 계약만 둔다.
- 문서·복구 skill은 단순 작업에서 자동 활성화하지 않고, 각 `SKILL.md`의 `사용할 때` 조건을 만족할 때만 사용한다.
