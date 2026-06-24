# Docs 운영 메모

이 디렉토리는 프로젝트 문서를 성격별로 나눠 보관한다. 문서를 새로 만들거나 갱신할 때는 먼저 문서 성격을 판단하고, 해당 하위 디렉토리 `README.md`가 있으면 그 기준을 따른다.

## 디렉토리 맵

- `docs/REQUIREMENTS.md`
  - 현재 유효한 제품 요구사항과 채택된 정책
- `docs/discussions/`
  - 채택 전 설계 검토, 전략 비교, 회의 메모
- `docs/decisions/`
  - 채택된 기술 결정과 ADR
- `docs/runbook/`
  - 실패 축별 예방 체크포인트, 점검 순서, 복구 절차
- `docs/roadmap/`
  - 기능별 후속 Todo와 버전별 확장 검토
- `docs/explainers/`
  - 코드만으로 파악하기 어려운 핵심 기술 구조 설명
- `docs/guides/`
  - 구현 계약, 작업 순서, 체크리스트
- `docs/followup/`
  - 세션 복구와 진행 중 작업 handoff
- `docs/learn/`
  - 개인 학습용 로컬 문서와 개인 트러블슈팅 기록
- `docs/platform.md`
  - `platform-runtime`, `platform-security`, `platform-governance`, `platform-resource` 현재 소비 기준
- `docs/contract/`
  - service-contract에서 이동한 서비스별 API, 보안, 운영, 에러 문서
- `docs/troubleshooting.md`
  - 장애 재현 절차와 운영 점검 기준의 루트 진입 문서
- `docs/runbook/troubleshooting.md`
  - Gateway 내부 JWT, 문서 API 401, 환경 설정 점검
- `docs/guides/contract/contract-change-guideline.md`
  - 구현 변경 후 service-contract, local 문서, contract.lock.yml 갱신 순서

## 전역 원칙

- 전역 문서 규칙은 `docs/README.md` 한 곳에 두고, 하위 `README.md`에는 해당 디렉토리 전용 추가 규칙만 둔다.
- 같은 내용을 여러 문서에 중복으로 적기보다, 문서 성격에 맞는 위치 한 곳에 먼저 정리한다.
- 문서 규칙과 경로 소유 위치를 먼저 지키고, 추가 설명이 필요하면 그 범위 안에서만 보강한다.
- 최종 기준을 보여주는 문서는 새 내용을 계속 누적하기보다 기존 관련 섹션에 통합해 최신 기준이 한 번에 읽히게 갱신한다.
- 경과 보존이 목적 문서는 기존 기록을 덮어쓰지 않는다. `discussions`, `prompts/worklog`는 경과 보존 경로다.
- `docs/followup/active`는 경과 누적이 아니라 진행 중 작업의 현재 상태 스냅샷 경로다.
- 문서 내부 링크는 로컬 절대 경로 대신 GitHub 저장소 기준 `blob/dev` 링크를 사용한다.
- 외부 근거를 썼다면 사실과 해석을 구분해 드러낸다.
- 요구사항으로 확정된 내용은 `docs/REQUIREMENTS.md`, 아직 채택되지 않은 비교나 검토는 `docs/discussions/`, 실제로 채택된 결정은 `docs/decisions/`, 반복 실수 축이나 검증/운영 축의 runbook은 `docs/runbook/`에 둔다.
- `docs/discussions/`와 `docs/decisions/`는 항상 먼저 읽는 경로가 아니라, README와 관련 문서가 가리킬 때 따라가는 공식 근거 경로로 유지한다.
- `docs/learn/`는 로컬 학습 메모 경로다. 공식 문서 근거나 직접 링크 대상으로 사용하지 않는다.
- 세션 복구와 진행 중 작업 상태는 `docs/followup/`에 두고, 장기 로그나 공식 정책을 그곳에 두지 않는다.
- 코드 변경이 있거나 구현 의미를 바꾸는 공식 문서를 갱신했다면, 필요한 공식 문서 갱신과 별도로 구현 검증도 함께 수행한다.
- 긴 구현 작업은 중간 단계마다 전체 검증을 반복하기보다, followup에 `검증 단계`를 남기고 `진행 중`에는 최소 검증만 선택한다.
- 검증 실패가 남아 있으면 작업을 완료로 판단하지 않는다. 실패 수정 후 재검증이 통과해야 완료로 본다.

## 읽기 기준

- `docs/README.md`는 모든 작업의 기본 컨텍스트가 아니라 `docs-routing` 게이트가 활성화됐을 때 사용하는 문서 전역 기준과 경로 라우터다.
- `docs/` 문서를 생성·수정하거나 문서 분류가 필요한 작업에서는 `AGENTS.md -> docs/README.md -> 대상 경로 README -> 실제 대상 문서` 순서로 최소 경로만 읽는다.
- 코드 작업, 단순 질의, 상태 확인처럼 문서 경로 판단이 필요 없는 작업에서는 이 문서를 관성적으로 읽지 않는다.
- 실제 대상 문서는 현재 작업을 직접 제약하는 것만 읽는다.
  - 요구사항이면 `docs/REQUIREMENTS.md`
  - 채택된 결정이면 관련 ADR
  - 구현 계약이면 관련 guide
  - 운영/재현 절차면 관련 runbook
  - 구조 설명이면 관련 explainer
  - 세션 복구면 관련 followup 파일
- 작업과 직접 관련 없는 하위 README나 문서를 관성적으로 넓게 읽지 않는다.
- `docs/discussions/`, `docs/decisions/`는 관련 결정과 충돌하거나 정책·계약 판단이 필요할 때만 좁게 따라간다.
- followup과 runbook은 문서 작업의 기본 경로가 아니며, 세션 복구 또는 실패·반복 실수 신호가 있을 때만 해당 README와 대상 파일로 분기한다.
- 문서 경로는 검증 게이트의 후보 신호다. 실제 문서 체계·계약 의미 변경 여부는 사용자 요청과 diff를 확인해 별도로 확정한다.
- 코드·설정 변경의 문서 영향이 `DOC_REQUIRED`일 때만 이 문서로 진입해 영향받는 공식 문서를 찾는다. `DOC_NONE`이면 문서 최신화를 위한 추가 읽기를 하지 않는다.
- 제품 문서 최신화와 문서 체계 검증은 별도 게이트다. 요구사항·계약 문서만 갱신하는 작업을 문서 체계 변경으로 자동 승격하지 않는다.
- 이 문서는 `DOC_REQUIRED` 판정 뒤 `docs-routing`과 `doc-update`에 사용한다. 코드·설정 변경의 문서 영향을 판정하거나 `doc-update`를 활성화하는 역할은 맡지 않는다.
- 문서 체계 검증은 `.codex/scripts/check-doc-governance.sh`, 구현 검증 계획과 실행은 `.codex/scripts/check-doc-implementation.sh`, 실제 실패 뒤 선택적 재시도는 `.codex/scripts/verify-and-retry.sh`를 기준으로 본다.

## Markdown 가독성 규칙

- 헤더 깊이는 일관되게 사용한다. `##`는 주요 섹션, `###`는 그 하위 논점으로 사용하고 `####` 이하는 꼭 필요한 경우에만 쓴다.
- 들여쓰기로 문단 구조를 만들지 않는다. 헤더, 짧은 문단, 빈 줄, 일관된 리스트 형식으로 흐름을 만든다.
- 같은 성격의 항목은 같은 리스트 형식을 유지한다. 원칙/포인트는 `-`, 순서/절차는 `1.` 형식을 우선한다.
- 한 문단에는 하나의 주장이나 설명만 담고, 길어지면 문단을 나눈다.
- 강조는 최소한으로 사용한다. 식별자, 코드, 경로, API 이름은 백틱으로 표기하고 굵은 글씨는 꼭 필요한 핵심어에만 제한한다.
- 표는 비교 항목이 매우 정형적일 때만 쓰고 일반 설명은 리스트나 짧은 문단을 우선한다.
- 구분선 `---`은 읽는 모드가 크게 바뀌는 지점에만 제한적으로 사용한다.
