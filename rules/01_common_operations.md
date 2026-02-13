# 공통 운영 규칙

## 범위
- 본 규칙은 기획/개발/그래픽/QA 전 단계에 공통 적용한다.

## 기본 순서
1. 요청 파악
2. 구현 또는 문서 작성
3. 검증
4. 결과 기록

## 산출물 경로
- 활성: `docs/plans`, `docs/plans/data`, `docs/plans/images`, `docs/references`, `docs/reference_reports`, `docs/graphics`, `docs/reviews`, `docs/qa`
- 아카이브: `docs/archive/ralph_runs`

## 실행 기본값
- 헤드리스 스모크: `tools\run_headless_smoke.bat`
- 안정 실행: `tools\run_game_stable.bat`

## 이미지/레퍼런스
- 계획 문서 본문에 외부 이미지 URL 직접 링크 금지
- 이미지 파일은 로컬 저장 후 상대 경로로 연결

## Runtime Log Storage Policy
- Store runtime logs under `gamelogs/`.
- Full stream file: `gamelogs/godot-live.log`.
- Error-only file: `gamelogs/godot-errors.log` (lines beginning with `ERROR:`).

## Runtime Error Fix Policy
- If runtime `ERROR:` lines are logged, treat them as actionable defects in the same task cycle.
- Apply code/resource fixes, rerun smoke/run checks, and verify the error line is resolved.
