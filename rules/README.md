# Project Rules Index

이 폴더는 `godot-001-card-battle` 프로젝트 운영 규칙의 단일 진입점이다.

## Rule Set
- `rules/01_common_operations.md`: 전 역할 공통 운영 규칙
- `rules/02_developer_rules.md`: 프로그래머 코딩/개발 규칙
- `rules/03_planner_rules.md`: 기획자 문서/스펙 규칙
- `rules/04_graphics_rules.md`: 그래픽 제작/에셋 규칙
- `rules/05_qa_rules.md`: QA 실행/기록 규칙
- `rules/06_git_review_release_rules.md`: Git/리뷰/릴리즈 규칙
- `rules/07_role_ownership_raci.md`: 역할 책임/승인 체계
- `rules/08_workspace_methodology.md`: 워크스페이스 운영 방법론(반복/피드백 반영)

## Priority
1. 사용자 직접 지시
2. `AGENTS.md`
3. `rules/*.md` (이 폴더)
4. 기타 문서

## Change Control
1. 룰 변경은 반드시 PR/커밋 메시지에 목적과 영향 범위를 명시한다.
2. 룰 변경 시 같은 작업 턴에서 관련 템플릿/체크리스트를 같이 업데이트한다.
3. 룰 충돌 시 `AGENTS.md`를 우선하고, 충돌 내역을 `docs/reviews/`에 기록한다.
