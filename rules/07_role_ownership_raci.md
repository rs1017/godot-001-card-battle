# Role Ownership RACI

## 1. Purpose
1. 역할 간 승인 경계를 명확히 해 병목과 책임 공백을 줄인다.
2. `R`(Responsible), `A`(Accountable), `C`(Consulted), `I`(Informed)로 운영한다.

## 2. Core Decision Matrix
| Topic | R | A | C | I |
|---|---|---|---|---|
| 전투 규칙 변경 | Developer | Tech Lead | Planner, QA | Graphics |
| 밸런스 수치 변경 | Planner | Game Director | Developer, QA | Graphics |
| UI 흐름 변경 | Planner | Product Owner | Developer, QA | Graphics |
| 아트 스타일 변경 | Graphics | Art Lead | Planner, QA | Developer |
| 에셋 교체/추가 | Graphics | Art Lead | Developer | QA |
| QA 기준 변경 | QA | QA Lead | Planner, Developer | Graphics |
| 릴리즈 승인 | QA Lead | Product Owner | Tech Lead, Art Lead | All |

## 3. Approval Rules
1. `A`가 비어 있는 항목은 작업 착수 금지.
2. `A` 변경 시 문서와 실제 승인 루트를 동시에 갱신한다.
3. 긴급 수정이라도 사후 24시간 내 승인 로그를 남긴다.

## 4. Handoff Rules
1. 기획 -> 개발 인계 시: 규칙, 변수, 예외, 완료 조건을 필수 전달한다.
2. 그래픽 -> 개발 인계 시: 파일 경로, 포맷, 스케일, pivot 규칙을 전달한다.
3. 개발 -> QA 인계 시: 테스트 포인트, 위험 구간, 알려진 제한을 전달한다.

## 5. Escalation
1. 충돌 해결 시간 1일 초과 시 `A`가 최종 결정을 내린다.
2. 반복 충돌 항목은 월간 룰 개정 안건으로 승격한다.
