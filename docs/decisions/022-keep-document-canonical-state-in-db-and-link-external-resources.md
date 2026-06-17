# ADR 022: 문서 본문 canonical source는 DB에 두고 외부 리소스는 platform-resource와 연결한다

## 상태

채택됨

## 배경

`editor-service`는 문서 메타데이터와 블록 구조를 직접 소유한다. 동시에 첨부파일, 문서 스냅샷, 향후 export/import artifact 같은 외부 리소스는 `platform-resource`와 lifecycle audit 흐름으로 관리해야 한다.

이때 `blocks.content_json`까지 파일 리소스로 옮기면 편집기의 canonical source, version 증가 규칙, editor save batch 적용 경계가 흐려진다. 반대로 첨부파일과 스냅샷까지 editor-service 내부 저장 모델로만 관리하면 플랫폼 리소스 lifecycle, purge, reconcile, governance audit 기준과 분리된다.

## 결정

- 문서 자체 상태는 editor-service DB를 canonical source로 유지한다.
- DB canonical 범위는 `documents`, `blocks`, `blocks.content_json`, 문서/블록 version 규칙, editor save/move/delete/restore 도메인 규칙이다.
- 첨부파일, 문서 스냅샷, 향후 에셋, export 결과물, import 원본, backup artifact 같은 외부 리소스는 `platform-resource`가 소유한다.
- 문서와 외부 리소스 연결은 `document_resources` 참조 모델로 관리한다.
- `document_resources`는 live aggregate FK 테이블이 아니라 resource cleanup ledger로 다룬다.
- 문서 기준 연결은 필수, 블록 기준 연결은 선택으로 둔다.
- binding 상태는 `ACTIVE`, `TRASHED`, `PENDING_PURGE`, `PURGED`, `BROKEN` 기준으로 운영한다.
- 리소스 저장, `document_resources` 참조 저장, lifecycle 전달은 단일 XA 트랜잭션으로 보지 않고 로컬 DB 트랜잭션과 `OUTBOX` relay 기준으로 운영한다.
- 문서 trash 시 연결된 attachment와 snapshot은 즉시 삭제하지 않고 보존하며, 복구 시 `ACTIVE`로 되돌린다.
- document hard delete, block delete, trash 만료 purge 같은 영구 정리 경로에서만 resource soft delete와 binding purge 예약을 수행한다.
- reconcile job은 catalog와 binding drift를 점검하고, 자동 복구가 안전하지 않은 경우 `BROKEN` 상태로 남겨 수동 점검 대상으로 둔다.

## 영향

- 장점:
- 편집 본문의 canonical source와 외부 파일 lifecycle 경계가 분명해진다.
- editor save/move의 version 규칙을 기존 DB 중심 모델로 유지할 수 있다.
- 첨부파일과 스냅샷은 platform-resource의 kind, lifecycle, outbox, governance audit 흐름에 맞춰 운영할 수 있다.
- 문서 trash/restore/hard delete와 resource purge grace period를 분리해 운영할 수 있다.

- 단점:
- editor-service DB에 `document_resources` ledger와 상태 전이 관리가 추가된다.
- resource catalog와 binding drift를 점검하는 reconcile/purge 운영 작업이 필요하다.
- 단일 XA 트랜잭션이 아니므로 outbox relay 실패와 재시도 상태를 명확히 관찰해야 한다.

## 관련 문서

- [REQUIREMENTS.md](https://github.com/jho951/Block-server/blob/dev/docs/REQUIREMENTS.md)
- [document-resource-boundary-and-transaction-flow.md](https://github.com/jho951/Block-server/blob/dev/docs/explainers/document-resource-boundary-and-transaction-flow.md)
- [contract-change-guideline.md](https://github.com/jho951/Block-server/blob/dev/docs/guides/contract/contract-change-guideline.md)
