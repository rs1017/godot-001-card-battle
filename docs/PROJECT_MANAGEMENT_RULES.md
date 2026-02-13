# 프로젝트 관리 규칙 (Ralph Workflow)

## 1. 목적
- 이 문서는 본 저장소의 기획/개발/그래픽/QA 운영 규칙의 기준 문서다.
- 목표는 "반복 가능한 개발 루프"를 유지하고, 산출물 위치/형식/검증 기준을 고정하는 것이다.

## 2. 기본 루프
1. 레퍼런스 수집
2. 계획 수립 및 배포
3. 그래픽 전략 수립 (ComfyUI 우선, KayKit 보완)
4. 구현
5. 리뷰
6. QA

## 3. 산출물 경로
- 활성 산출물
  - `docs/plans/`
  - `docs/plans/data/`
  - `docs/plans/images/`
  - `docs/references/`
  - `docs/reference_reports/`
  - `docs/graphics/`
  - `docs/reviews/`
  - `docs/qa/`
- 아카이브 산출물
  - `docs/archive/ralph_runs/`

## 4. 파일 네이밍
- 계획: `plan_YYYYMMDD_HHMMSS.md`
- QA: `qa_YYYYMMDD_HHMMSS.md`
- 리뷰: `review_YYYYMMDD_HHMMSS.md`
- 개발 로그: `development_log_YYYYMMDD_HHMMSS.md`
- 레퍼런스 인벤토리: `reference_inventory_YYYYMMDD_HHMMSS.md`
- 루프 상태: `docs/ralph/state.json`
- 루프 로그: `docs/ralph/cycle_log.md`

## 5. 계획 문서 규칙
- 기본 문서: `docs/plans/latest_plan.md`
- 기본 템플릿: `docs/plans/templates/game_plan_format_kr.md`
- 언어: 한국어 기본
- 구조화 데이터: `docs/plans/data/*.csv`
- 이미지: `docs/plans/images/...`의 로컬 파일만 사용
- 웹 이미지 URL을 계획 문서 본문에 직접 링크하지 않는다.
- UI 계획 산출물
  - 이미지: `docs/plans/images/ui/`
  - 표 데이터: `docs/plans/data/ui_*.csv`

## 6. 그래픽 규칙
- ComfyUI 우선, KayKit 보완
- ComfyUI 루트 경로: `D:\comfyUI`
- 기본 호출 방식: `http://127.0.0.1:8188` API
- 생성 결과는 로컬 경로로 저장하고 문서에는 로컬 경로만 연결한다.

## 7. 실행/검증 규칙
- 기본 스모크: `tools\run_headless_smoke.bat`
- 기본 루프 실행
  - 단일: `tools\run_ralph_mode.bat [feature-name]`
  - 반복: `tools\run_ralph_loop.bat [feature-name] [max-cycles] [required-success-cycles] [completion-flag-path]`
- 루프 성공 기준
  - `inventory/plan/graphics/devlog/review/qa` 산출물 모두 생성
  - 스모크 QA PASS
  - 리뷰 게이트 PASS

## 8. 아카이브 정책
- 기본 원칙: 삭제보다 아카이브 우선
- 타임스탬프 누적 산출물은 `docs/archive/ralph_runs/`로 이동해 보관
- 활성 경로에는 최신/실행 중 문서 중심으로 유지

## 9. Git/릴리즈 규칙
- 커밋 메시지: `type(scope): imperative summary`
- 코드/콘텐츠 수정 후 같은 작업 사이클에서 커밋/푸시
- 규칙 문서 수정 시 `rules/`와 동기화

## 10. 체크리스트
- 경로/파일명 규칙 준수 여부
- 계획 문서 필수 섹션 존재 여부
- QA/리뷰 결과 문서 생성 여부
- 아카이브 분리 준수 여부
