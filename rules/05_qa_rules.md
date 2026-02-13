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

## Bug Send Rule
- BUG 버튼 클릭 시 `버그 보내기` 버튼이 표시되어야 한다.
- `버그 보내기` 클릭 시 `docs/qa/bug_reports/` 아래에 스크린샷(.png)과 노트(.txt)가 생성되어야 한다.
- 전송 실패 시 사용자에게 실패 메시지가 보여야 하며 QA 실패로 처리한다.

## Runtime Error Log Gate
- During QA run, check `docs/qa/bug_reports/godot-errors.log`.
- If new runtime `ERROR:` lines exist, QA is fail until corresponding fixes are verified.
