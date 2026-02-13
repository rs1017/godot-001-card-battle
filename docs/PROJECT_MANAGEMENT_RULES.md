# 프로젝트 관리 룰 (Ralph Workflow)

## 1) 목표
- 이 문서는 게임 개발 산출물의 생성, 정리, 보관 규칙을 고정한다.
- 기준: 반복 개발(레퍼런스 -> 기획 -> 그래픽 -> 개발 -> 리뷰 -> QA) 중에도 폴더가 난잡해지지 않게 유지.

## 2) 핵심 원칙
- 최신 작업물과 이력(아카이브)을 분리한다.
- 삭제보다 아카이브 이동을 우선한다.
- 이미지 레퍼런스는 로컬 파일 링크만 사용한다.
- 레퍼런스는 게임 개발에 필요한 스크린샷 중심으로 관리한다.

## 3) 폴더 운영 규칙
- 활성 산출물(현재 사용):
  - `docs/plans/`
  - `docs/plans/data/`
  - `docs/plans/images/`
  - `docs/references/`
  - `docs/graphics/`
  - `docs/reviews/` (필수 리뷰 결과)
- 이력 산출물(아카이브):
  - `docs/archive/ralph_runs/`
  - 하위 분류: `plans/`, `plans/data/`, `qa/`, `reviews/`, `graphics/`, `reference_reports/`

## 4) 파일 네이밍 규칙
- 계획서(주기 산출): `plan_YYYYMMDD_HHMMSS.md`
- QA: `qa_YYYYMMDD_HHMMSS.md`
- 리뷰: `review_YYYYMMDD_HHMMSS.md`
- 개발 로그: `development_log_YYYYMMDD_HHMMSS.md`
- 레퍼런스 인벤토리: `reference_inventory_YYYYMMDD_HHMMSS.md`
- 마스터 문서는 고정 파일명 유지:
  - `docs/plans/master_plan_300_pages.md`
  - `docs/plans/latest_plan.md`

## 5) 이미지/레퍼런스 규칙
- 외부 이미지 URL 직접 링크 금지.
- 기획서 이미지는 `docs/plans/images/...` 로컬 파일만 연결.
- 스크린샷 레퍼런스는 배치 폴더로 분할:
  - 예: `docs/plans/images/game_screenshots_generated/batch_0001/`
- 중복 이미지는 해시(SHA1) 기준으로 제거.

## 6) 반복 실행 규칙
- 대량 생성/수집은 청크 단위 실행:
  - 기본 청크 크기 500
  - 1회 실행 후 카운트/품질 점검 후 다음 청크
- 목표 개수(예: 10,000장)는 청크 누적으로 달성.

## 7) 품질 필터 규칙
- 레퍼런스는 아래 기준을 만족해야 한다.
  - 실제 게임 플레이 맥락(전투 화면, UI 맥락, 레인/전장/카드 상호작용)
  - 해상도 최소 기준(저품질/깨진 파일 제외)
  - 프로젝트 장르 연관성(카드/전략/전투 중심)
- 장르 무관 이미지 비율이 높아지면 즉시 수집 기준을 강화한다.

## 8) 운영 체크리스트
- 루트 docs에 timestamp 파일이 과도하게 쌓였는가?
- 최신 문서와 아카이브가 분리되어 있는가?
- master plan 이미지 링크가 모두 로컬 파일인가?
- CSV 매핑과 실제 파일 경로가 일치하는가?
- 리뷰/QA 결과를 남기고 다음 사이클로 넘어갔는가?
