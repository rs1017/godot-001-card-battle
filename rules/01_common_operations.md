# Common Operations Rules

## 1. Scope
1. 이 규칙은 기획, 개발, 그래픽, QA 전 역할에 공통 적용한다.
2. 프로젝트 기준 엔진/환경은 Godot 4.5 + 현재 저장소 구조를 따른다.

## 2. Standard Workflow
1. 모든 작업은 `요청 -> 작업 -> 검증 -> 기록` 4단계를 따른다.
2. 단계 누락 시 완료 처리하지 않는다.
3. 한 사이클 종료 기준은 `필수 산출물 생성 + QA 스모크 통과`다.

## 3. Output Paths
1. 활성 산출물:
`docs/plans`, `docs/plans/data`, `docs/plans/images`, `docs/references`, `docs/graphics`, `docs/reviews`, `docs/qa`
2. 이력/보관:
`docs/archive/ralph_runs`
3. 임시 산출물:
`docs/archive/system_tmp` 또는 `.tmp`

## 4. Naming Rules
1. 계획 문서: `plan_YYYYMMDD_HHMMSS.md`
2. QA 문서: `qa_YYYYMMDD_HHMMSS.md`
3. 리뷰 문서: `review_YYYYMMDD_HHMMSS.md`
4. 개발 로그: `development_log_YYYYMMDD_HHMMSS.md`
5. 리포트 파일명은 공백 대신 `_`를 사용한다.

## 5. Archive-First Policy
1. 대량 삭제 금지, 우선 아카이브 이동 후 검증한다.
2. `docs/archive/ralph_runs` 내 폴더 구조를 유지한다.
3. 활성 폴더에는 최신 문서만 유지한다.

## 6. Reference and Screenshot Policy
1. 계획 문서에 외부 이미지 URL 직접 링크를 금지한다.
2. 이미지는 로컬 저장 후 문서에서 상대 경로로 참조한다.
3. 스크린샷은 배치 단위 폴더(`batch_0001` 등)와 해시 중복 제거를 사용한다.

## 7. Decision Log Policy
1. 기획/규칙 변경은 `무엇`, `왜`, `영향 범위` 3요소를 기록한다.
2. 변경 전/후 기준값이 있으면 수치로 남긴다.
3. 승인자와 승인 시각을 기록한다.

## 8. Build and Run Method
1. Build/smoke verification must run first:
`tools\run_headless_smoke.bat`
2. Stable game run command:
`tools\run_game_stable.bat`
3. Stable run must launch GUI and console together, and enforce windowed mode (`--windowed`).
4. Direct launch fallback (GUI):
`Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe --path . --rendering-driver opengl3`

## 9. Runtime Startup Error Runbook
1. If startup fails, run checks in this order:
`run_headless_smoke.bat -> run_game_stable.bat -> direct GUI fallback`
2. If this error appears, apply fallback immediately:
`Could not create directory: 'user://logs'`
3. When the `user://logs` error occurs:
- Treat console launch as unstable for that session.
- Use GUI launch path as temporary default.
- Record failure text in QA/review log and verify `user://` write permission and logging path settings before restoring console-first flow.
