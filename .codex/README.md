# Project Codex Helpers

이 경로는 저장소 전역 규칙을 다시 적는 곳이 아니라, 반복 가능한 Codex 작업 절차와 자동 검증 보조 도구를 두는 보조 경로다.

- 레포 규칙과 문서 소유 위치는 `AGENTS.md`와 `README.md` 계층을 기준으로 본다.
- `.codex/skills/`에는 반복 가능한 작업 절차만 두고, 각 `SKILL.md`는 최소 YAML frontmatter(`name`, `description`)를 포함한다.
- `.codex/scripts/`에는 사람이 직접 실행하거나 skill에서 참조하는 자동 검증 스크립트를 둔다.
- `.codex/config/`에는 작업 유형별 문서 최신화 기준, 제외 범위, 금지 참조 검사 제외 glob, 구현 검증 트리거를 둔다.
- 프로젝트별 세션 복구와 handoff 기준은 `docs/followup/`을 따른다.
- 문서 체계 검증은 `.codex/scripts/check-doc-governance.sh`, 구현 검증 필요 여부 판별과 테스트 실행은 `.codex/scripts/check-doc-implementation.sh`를 기준으로 한다.
- 검증 실패 재검증과 실패 케이스 즉시 기록은 `.codex/config/failure-route-map.md`, `.codex/scripts/verify-and-retry.sh`, `.codex/skills/verification-retry/SKILL.md`를 기준으로 한다.
- 구현 검증의 경로별 태스크와 로컬 제외 테스트는 `.codex/config/doc-to-code-check-matrix.md`를 원본으로 본다.
