# Workspace Methodology

## 1. Goal
1. 이 방법론은 워크스페이스 작업을 반복 가능한 사이클로 고정하고, 피드백이 다음 작업에 누락 없이 반영되게 한다.
2. 적용 대상은 기획, 개발, 그래픽, QA 전 역할이다.

## 2. Workspace Structure
1. 작업 단위별 워크스페이스 기록은 `docs/reviews/` 또는 `docs/qa/`에 남긴다.
2. 반복 작업 상태는 `docs/ralph/state.json`, `docs/ralph/cycle_log.md`를 기준으로 추적한다.
3. 산출물은 활성 경로(`docs/plans`, `docs/references`, `docs/graphics`, `docs/reviews`, `docs/qa`)에 저장한다.
4. 과거 사이클 산출물은 `docs/archive/ralph_runs/`로 이동해 보관한다.

## 3. Iterative Cycle Rule
1. 기본 사이클은 `수집 -> 계획 -> 구현 -> 리뷰 -> QA -> 기록` 순서로 수행한다.
2. 각 사이클 종료 조건은 다음 3가지를 모두 만족해야 한다.
`필수 산출물 생성`, `스모크/검증 통과`, `사이클 로그 기록`
3. 종료 조건 미충족 시 같은 주제를 다음 사이클에서 반복한다.
4. 반복 횟수 정책은 도구/지침에서 지정한 값을 따르고, 미지정 시 기본 반복 횟수를 사용한다.

## 4. Feedback Incorporation Rule
1. 지침/리뷰/QA 피드백이 발생하면 다음 작업 시작 전에 `피드백 항목 목록`을 먼저 만든다.
2. 각 피드백은 `반영 상태`를 반드시 표시한다.
`pending`, `applied`, `rejected(with reason)`
3. 다음 사이클 계획에는 이전 사이클 피드백 반영 항목을 첫 섹션으로 배치한다.
4. 반영 누락이 확인되면 해당 사이클은 실패로 처리하고 재실행한다.

## 5. Instruction Delta Rule
1. 새 지침이 들어오면 기존 룰과 차이를 비교해 `delta`를 기록한다.
2. delta가 있으면 관련 룰 문서와 템플릿을 같은 턴에 업데이트한다.
3. 상충 지침이 있으면 우선순위(`사용자 직접 지시 -> AGENTS.md -> rules`)로 정리하고, 정리 결과를 기록한다.

## 6. Completion and Handoff Rule
1. 사이클 완료 보고에는 반드시 다음 항목을 포함한다.
`이번 반영 내용`, `남은 리스크`, `다음 사이클 우선순위`
2. 다음 담당자 인계를 위해 변경 파일 경로와 검증 결과를 함께 남긴다.
3. 피드백 추적표가 비어 있지 않으면 완료 처리하지 않는다.
