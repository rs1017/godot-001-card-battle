# QA 규칙

## 기본 검증
- 헤드리스 스모크: `tools\run_headless_smoke.bat`
- 기능 체크: 입력/마나/스폰/상태 전환/승패/일시정지

## 리포트
- QA 문서: `docs/qa/qa_YYYYMMDD_HHMMSS.md`
- 버그 스크린샷: `docs/qa/bug_reports/`
- 실패 시 재현 절차와 로그를 포함한다.

## 게이트
- 스모크 PASS 없이 완료 처리 금지
