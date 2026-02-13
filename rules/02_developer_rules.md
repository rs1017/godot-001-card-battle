# Developer Rules

## 1. Code Style
1. GDScript 4 문법을 사용한다.
2. 들여쓰기는 탭을 사용한다.
3. 파일명은 `snake_case.gd`, 씬은 `snake_case.tscn`을 따른다.
4. 가능하면 타입 힌트를 명시한다.
5. 리소스 경로는 `res://`만 사용한다.

## 2. Architecture and Boundaries
1. 전투 로직은 `scripts/battle/`에 집중한다.
2. UI 로직은 `scripts/ui/`에 집중한다.
3. 전역 상태/이벤트는 오토로드(`EventBus`, `GameManager`)를 통해서만 전달한다.
4. 스크립트 간 직접 결합보다 신호/이벤트 결합을 우선한다.

## 3. Gameplay Safety Rules
1. 전투 밸런스 영향값(스폰 수, 코스트, 타이머)은 하드코딩 테스트값을 기본값으로 커밋하지 않는다.
2. 카드 1장당 결과(스폰 수/효과 수)는 명세를 벗어나면 즉시 차단한다.
3. 상태 전환(배치, 취소, 종료)은 입력 이벤트와 1:1 추적 가능해야 한다.
4. 승패 처리 로직 변경 시 타이브레이커/서든데스 예외를 함께 검증한다.

## 4. Required Local Validation
1. 코드 변경 후 최소 1회 `tools/run_headless_smoke.bat`를 실행한다.
2. 다음 항목을 수동 확인한다:
`card select/cancel`, `mana afford/spend`, `minion spawn/state`, `win/lose/pause`
3. 실패 로그는 `docs/qa` 또는 `docs/reviews`에 남긴다.

## 5. Generated File Control
1. `.godot/`, `.tmp/` 등 실행 생성물은 기본 커밋 대상에서 제외한다.
2. 예외적으로 추적이 필요한 `.uid`, `.import`는 관련 에셋과 함께 커밋한다.
3. 임시 확장자(`*.tmp`)는 릴리즈/PR 기준으로 정리한다.

## 6. Done Criteria
1. 구현 완료 + 스모크 통과 + 리뷰 기록이 있어야 완료로 간주한다.
