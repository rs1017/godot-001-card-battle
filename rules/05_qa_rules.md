# QA Rules

## 1. QA Gate
1. 모든 사이클은 스모크 통과 전 완료 처리 금지.
2. 기본 스모크 명령은 `tools/run_headless_smoke.bat`를 사용한다.
3. QA 결과는 `docs/qa/qa_YYYYMMDD_HHMMSS.md` 형식으로 기록한다.

## 2. Mandatory Functional Checks
1. 카드 선택/취소 입력
2. 마나 보유/소모/부족 처리
3. 미니언 스폰 및 상태 전이
4. 승/패 및 일시정지 상태 전이

## 3. Bug Reporting Rules
1. 재현 절차는 `환경 -> 단계 -> 실제/기대 결과` 3줄 규칙으로 기록한다.
2. 스크린샷은 `docs/qa/bug_reports/`에 저장한다.
3. 로그/캡처 파일명은 시각 기반으로 작성한다.

## 4. Review Agent Loop
1. 각 사이클에서 `tools/review_agent_validate.ps1` 검증을 수행한다.
2. 검증 실패 시 성공 연속 카운트는 리셋한다.
3. 반려 사유는 다음 사이클 계획에 반영한다.

## 5. Quality Criteria
1. 기능 정상 외에 재미 점수(fun-score) 게이트를 기록한다.
2. 잔여 리스크와 미검증 범위를 반드시 남긴다.
