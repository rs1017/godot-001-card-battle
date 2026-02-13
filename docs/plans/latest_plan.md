# 랄프 방식 통합 기획서 (100회 반복 실행)

- 문서 버전: v1.0
- 작성일: 2026-02-13 17:29:33
- 작성 언어: 한국어
- 작업 모드: 레퍼런스 수집 -> 기획 -> 그래픽(ComfyUI 우선, KayKit 보조) -> 개발 -> 리뷰 -> QA -> 재검증
- 반복 횟수: 100회
- 이미지 정책: 외부 URL 직접 링크 금지, 로컬 파일 링크만 사용

## 1. 기획 목표

- 장르: 실시간 2레인 카드 배틀
- 핵심 경험: 짧은 전투(3~5분), 높은 선택 밀도, 명확한 카운터플레이
- 개발 방향: 기획 데이터 표준화, 상태머신 안정화, QA 반복 기반 개선

## 2. 레퍼런스 샘플

### 2.1 웹 레퍼런스 + 생성 이미지 샘플
![웹 레퍼런스 1](images/web_refs/web_ref_00013.jpg)
![ComfyUI 샘플 1](images/game_screenshots_generated/batch_0001/shot_00001.png)
![웹 레퍼런스 2](images/web_refs/web_ref_00014.jpg)
![ComfyUI 샘플 2](images/game_screenshots_generated/batch_0001/shot_00002.png)
![웹 레퍼런스 3](images/web_refs/web_ref_00015.jpg)
![ComfyUI 샘플 3](images/game_screenshots_generated/batch_0001/shot_00003.png)
![웹 레퍼런스 4](images/web_refs/web_ref_00016.jpg)
![ComfyUI 샘플 4](images/game_screenshots_generated/batch_0001/shot_00004.png)
![웹 레퍼런스 5](images/web_refs/web_ref_00017.jpg)
![ComfyUI 샘플 5](images/game_screenshots_generated/batch_0001/shot_00005.png)
![웹 레퍼런스 6](images/web_refs/web_ref_00018.jpg)
![ComfyUI 샘플 6](images/game_screenshots_generated/batch_0001/shot_00006.png)

### 2.2 레퍼런스 적용 기준

| 항목 | 체크 기준 | 개발 반영 |
|---|---|---|
| 전장 가독성 | 유닛 실루엣, 팀 색상 구분 | 타일 명도 대비와 이펙트 상한선 적용 |
| 카드 UX | 선택, 취소, 배치 피드백 | 핸드 하이라이트 및 배치 오버레이 |
| 전투 속도 | 마나 순환, TTK, 역전 타이밍 | 전투 공식과 코스트 커브 동시 조정 |
| 승패 전달 | 결과 인지 속도 | 승리/실패 연출과 결과 UI 고정 |

## 3. 시스템 상세 기획

### 3.1 카드 덱 구성 규칙

| 항목 | 규칙 | 검증 로직 |
|---|---|---|
| 덱 크기 | 8장 고정 | 저장 시 8장 검증 |
| 코스트 분포 | 1~2코 2장 이상, 5코 이상 2장 이하 | 덱 컴파일 단계 검증 |
| 역할 분포 | 탱커/딜러/유틸/스펠 최소 1종 | 태그 누락 검사 |
| 중복 제한 | 동일 카드 최대 2장 | 카드 ID 카운트 검사 |

### 3.2 카드 룰 및 전투 공식

| 항목 | 공식 또는 규칙 | 설명 |
|---|---|---|
| 최종 피해량 | `final_damage = (base_attack * skill_coeff) * (1 - armor_reduction)` | 최소값 1 보정 |
| DPS | `dps = final_damage / attack_interval` | 밸런스 비교 지표 |
| 마나 회복 | `mana_next = min(max_mana, mana_now + regen * dt)` | 기본 regen 1.0/s |
| 오버타임 | 120초 이후 타워 피해 1.25배 | 장기전 억제 |
| 서든데스 | 180초 이후 타워 피해 1.5배, 힐 50% | 강제 결판 |

### 3.3 맵/승패/애니메이션

| 요소 | 기획 | 구현 포인트 |
|---|---|---|
| 맵 | 좌/우 2레인, 중앙 시야 확보 | 배치 가능 영역 시각화 |
| 승리 | 상대 본진 HP 0 또는 시간 종료 시 우위 | 종료 판정 단일 모듈 |
| 실패 | 내 본진 HP 0 또는 열세 | 결과 화면 전환 고정 |
| 애니메이션 | 소환/피격/사망/스킬 4상태 | 상태 전이 로그 |

### 3.4 카드 인벤토리/캐릭터 설명

| 데이터 | 필드 | 목적 |
|---|---|---|
| CardInventory | card_id, rarity, owned, level, tags | 보유/성장 추적 |
| CharacterProfile | unit_id, role, strengths, weaknesses, countered_by | 역할과 상성 문서화 |
| BalanceLog | patch_ver, target, before, after, reason | 밸런스 변경 근거 |

## 4. UI 흐름

```mermaid
flowchart TD
A[메인 페이지] --> B[덱 편성]
B --> C[매치 진입]
C --> D[전투 진행]
D --> E{종료 조건 충족}
E -- 아니오 --> D
E -- 예 --> F[결과 화면]
F --> G[재시작 또는 로비]
```

| 화면 | 필수 요소 | QA 체크 |
|---|---|---|
| 메인 | 시작, 덱, 설정 | 해상도별 배치 확인 |
| 전투 HUD | 마나, 핸드, HP, 타이머 | 선택/취소 입력 정확도 |
| 결과 | 승패 문구, 보상, 재시작 | 중복 입력 방지 |

## 5. 랄프 100회 반복 사이클

| 사이클 | 레퍼런스 이미지 | 기획 초점 | 그래픽 샘플 | 개발 초점 | 리뷰 초점 | QA 초점 |
|---|---|---|---|---|---|---|
| 1 | ![R1-W](images/web_refs/web_ref_00013.jpg) | 메인 UI 가독성 | ![R1-G](images/game_screenshots_generated/batch_0001/shot_00001.png) | 상태머신 이벤트 연결 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 2 | ![R2-W](images/web_refs/web_ref_00014.jpg) | 카드핸드 조작성 | ![R2-G](images/game_screenshots_generated/batch_0001/shot_00002.png) | 카드 데이터 검증기 | 코스트 대비 성능 역전 | 입력 정확도 |
| 3 | ![R3-W](images/web_refs/web_ref_00015.jpg) | 레인 배치 규칙 | ![R3-G](images/game_screenshots_generated/batch_0001/shot_00003.png) | 전투 공식 파라미터 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 4 | ![R4-W](images/web_refs/web_ref_00016.jpg) | 마나 템포 밸런스 | ![R4-G](images/game_screenshots_generated/batch_0001/shot_00004.png) | 맵 충돌 및 배치 영역 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 5 | ![R5-W](images/web_refs/web_ref_00017.jpg) | 소환 이펙트 일관성 | ![R5-G](images/game_screenshots_generated/batch_0001/shot_00005.png) | 결과 화면 흐름 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 6 | ![R6-W](images/web_refs/web_ref_00018.jpg) | 승리 연출 명확성 | ![R6-G](images/game_screenshots_generated/batch_0001/shot_00006.png) | 상태머신 이벤트 연결 | 코스트 대비 성능 역전 | 입력 정확도 |
| 7 | ![R7-W](images/web_refs/web_ref_00019.jpg) | 실패 연출 명확성 | ![R7-G](images/game_screenshots_generated/batch_0001/shot_00007.png) | 카드 데이터 검증기 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 8 | ![R8-W](images/web_refs/web_ref_00020.jpg) | 카운터플레이 유도 | ![R8-G](images/game_screenshots_generated/batch_0001/shot_00008.png) | 전투 공식 파라미터 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 9 | ![R9-W](images/web_refs/web_ref_00021.jpg) | 덱 다양성 보장 | ![R9-G](images/game_screenshots_generated/batch_0001/shot_00009.png) | 맵 충돌 및 배치 영역 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 10 | ![R10-W](images/web_refs/web_ref_00022.jpg) | 오버타임 안정화 | ![R10-G](images/game_screenshots_generated/batch_0001/shot_00010.png) | 결과 화면 흐름 | 코스트 대비 성능 역전 | 입력 정확도 |
| 11 | ![R11-W](images/web_refs/web_ref_00023.jpg) | 메인 UI 가독성 | ![R11-G](images/game_screenshots_generated/batch_0001/shot_00021.png) | 상태머신 이벤트 연결 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 12 | ![R12-W](images/web_refs/web_ref_00024.jpg) | 카드핸드 조작성 | ![R12-G](images/game_screenshots_generated/batch_0001/shot_00022.png) | 카드 데이터 검증기 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 13 | ![R13-W](images/web_refs/web_ref_00025.jpg) | 레인 배치 규칙 | ![R13-G](images/game_screenshots_generated/batch_0001/shot_00023.png) | 전투 공식 파라미터 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 14 | ![R14-W](images/web_refs/web_ref_00026.jpg) | 마나 템포 밸런스 | ![R14-G](images/game_screenshots_generated/batch_0001/shot_00024.png) | 맵 충돌 및 배치 영역 | 코스트 대비 성능 역전 | 입력 정확도 |
| 15 | ![R15-W](images/web_refs/web_ref_00027.jpg) | 소환 이펙트 일관성 | ![R15-G](images/game_screenshots_generated/batch_0001/shot_00025.png) | 결과 화면 흐름 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 16 | ![R16-W](images/web_refs/web_ref_00028.jpg) | 승리 연출 명확성 | ![R16-G](images/game_screenshots_generated/batch_0001/shot_00026.png) | 상태머신 이벤트 연결 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 17 | ![R17-W](images/web_refs/web_ref_00029.jpg) | 실패 연출 명확성 | ![R17-G](images/game_screenshots_generated/batch_0001/shot_00027.png) | 카드 데이터 검증기 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 18 | ![R18-W](images/web_refs/web_ref_00030.jpg) | 카운터플레이 유도 | ![R18-G](images/game_screenshots_generated/batch_0001/shot_00028.png) | 전투 공식 파라미터 | 코스트 대비 성능 역전 | 입력 정확도 |
| 19 | ![R19-W](images/web_refs/web_ref_00031.jpg) | 덱 다양성 보장 | ![R19-G](images/game_screenshots_generated/batch_0001/shot_00029.png) | 맵 충돌 및 배치 영역 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 20 | ![R20-W](images/web_refs/web_ref_00032.jpg) | 오버타임 안정화 | ![R20-G](images/game_screenshots_generated/batch_0001/shot_00030.png) | 결과 화면 흐름 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 21 | ![R21-W](images/web_refs/web_ref_00033.jpg) | 메인 UI 가독성 | ![R21-G](images/game_screenshots_generated/batch_0001/shot_00031.png) | 상태머신 이벤트 연결 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 22 | ![R22-W](images/web_refs/web_ref_00034.jpg) | 카드핸드 조작성 | ![R22-G](images/game_screenshots_generated/batch_0001/shot_00032.png) | 카드 데이터 검증기 | 코스트 대비 성능 역전 | 입력 정확도 |
| 23 | ![R23-W](images/web_refs/web_ref_00035.jpg) | 레인 배치 규칙 | ![R23-G](images/game_screenshots_generated/batch_0001/shot_00033.png) | 전투 공식 파라미터 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 24 | ![R24-W](images/web_refs/web_ref_00036.jpg) | 마나 템포 밸런스 | ![R24-G](images/game_screenshots_generated/batch_0001/shot_00034.png) | 맵 충돌 및 배치 영역 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 25 | ![R25-W](images/web_refs/web_ref_00037.jpg) | 소환 이펙트 일관성 | ![R25-G](images/game_screenshots_generated/batch_0001/shot_00035.png) | 결과 화면 흐름 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 26 | ![R26-W](images/web_refs/web_ref_00038.jpg) | 승리 연출 명확성 | ![R26-G](images/game_screenshots_generated/batch_0001/shot_00036.png) | 상태머신 이벤트 연결 | 코스트 대비 성능 역전 | 입력 정확도 |
| 27 | ![R27-W](images/web_refs/web_ref_00039.jpg) | 실패 연출 명확성 | ![R27-G](images/game_screenshots_generated/batch_0001/shot_00037.png) | 카드 데이터 검증기 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 28 | ![R28-W](images/web_refs/web_ref_00040.jpg) | 카운터플레이 유도 | ![R28-G](images/game_screenshots_generated/batch_0001/shot_00038.png) | 전투 공식 파라미터 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 29 | ![R29-W](images/web_refs/web_ref_00041.jpg) | 덱 다양성 보장 | ![R29-G](images/game_screenshots_generated/batch_0001/shot_00039.png) | 맵 충돌 및 배치 영역 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 30 | ![R30-W](images/web_refs/web_ref_00042.jpg) | 오버타임 안정화 | ![R30-G](images/game_screenshots_generated/batch_0001/shot_00040.png) | 결과 화면 흐름 | 코스트 대비 성능 역전 | 입력 정확도 |
| 31 | ![R31-W](images/web_refs/web_ref_00043.jpg) | 메인 UI 가독성 | ![R31-G](images/game_screenshots_generated/batch_0002/shot_00011.png) | 상태머신 이벤트 연결 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 32 | ![R32-W](images/web_refs/web_ref_00044.jpg) | 카드핸드 조작성 | ![R32-G](images/game_screenshots_generated/batch_0002/shot_00012.png) | 카드 데이터 검증기 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 33 | ![R33-W](images/web_refs/web_ref_00045.jpg) | 레인 배치 규칙 | ![R33-G](images/game_screenshots_generated/batch_0002/shot_00013.png) | 전투 공식 파라미터 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 34 | ![R34-W](images/web_refs/web_ref_00046.jpg) | 마나 템포 밸런스 | ![R34-G](images/game_screenshots_generated/batch_0002/shot_00014.png) | 맵 충돌 및 배치 영역 | 코스트 대비 성능 역전 | 입력 정확도 |
| 35 | ![R35-W](images/web_refs/web_ref_00047.jpg) | 소환 이펙트 일관성 | ![R35-G](images/game_screenshots_generated/batch_0002/shot_00015.png) | 결과 화면 흐름 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 36 | ![R36-W](images/web_refs/web_ref_00048.jpg) | 승리 연출 명확성 | ![R36-G](images/game_screenshots_generated/batch_0002/shot_00016.png) | 상태머신 이벤트 연결 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 37 | ![R37-W](images/web_refs/web_ref_00049.jpg) | 실패 연출 명확성 | ![R37-G](images/game_screenshots_generated/batch_0002/shot_00017.png) | 카드 데이터 검증기 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 38 | ![R38-W](images/web_refs/web_ref_00050.jpg) | 카운터플레이 유도 | ![R38-G](images/game_screenshots_generated/batch_0002/shot_00018.png) | 전투 공식 파라미터 | 코스트 대비 성능 역전 | 입력 정확도 |
| 39 | ![R39-W](images/web_refs/web_ref_00051.jpg) | 덱 다양성 보장 | ![R39-G](images/game_screenshots_generated/batch_0002/shot_00019.png) | 맵 충돌 및 배치 영역 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 40 | ![R40-W](images/web_refs/web_ref_00052.jpg) | 오버타임 안정화 | ![R40-G](images/game_screenshots_generated/batch_0002/shot_00020.png) | 결과 화면 흐름 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 41 | ![R41-W](images/web_refs/web_ref_00053.jpg) | 메인 UI 가독성 | ![R41-G](images/game_screenshots_generated/batch_0001/shot_00001.png) | 상태머신 이벤트 연결 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 42 | ![R42-W](images/web_refs/web_ref_00054.jpg) | 카드핸드 조작성 | ![R42-G](images/game_screenshots_generated/batch_0001/shot_00002.png) | 카드 데이터 검증기 | 코스트 대비 성능 역전 | 입력 정확도 |
| 43 | ![R43-W](images/web_refs/web_ref_00055.jpg) | 레인 배치 규칙 | ![R43-G](images/game_screenshots_generated/batch_0001/shot_00003.png) | 전투 공식 파라미터 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 44 | ![R44-W](images/web_refs/web_ref_00056.jpg) | 마나 템포 밸런스 | ![R44-G](images/game_screenshots_generated/batch_0001/shot_00004.png) | 맵 충돌 및 배치 영역 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 45 | ![R45-W](images/web_refs/web_ref_00057.jpg) | 소환 이펙트 일관성 | ![R45-G](images/game_screenshots_generated/batch_0001/shot_00005.png) | 결과 화면 흐름 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 46 | ![R46-W](images/web_refs/web_ref_00058.jpg) | 승리 연출 명확성 | ![R46-G](images/game_screenshots_generated/batch_0001/shot_00006.png) | 상태머신 이벤트 연결 | 코스트 대비 성능 역전 | 입력 정확도 |
| 47 | ![R47-W](images/web_refs/web_ref_00059.jpg) | 실패 연출 명확성 | ![R47-G](images/game_screenshots_generated/batch_0001/shot_00007.png) | 카드 데이터 검증기 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 48 | ![R48-W](images/web_refs/web_ref_00060.jpg) | 카운터플레이 유도 | ![R48-G](images/game_screenshots_generated/batch_0001/shot_00008.png) | 전투 공식 파라미터 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 49 | ![R49-W](images/web_refs/web_ref_00061.jpg) | 덱 다양성 보장 | ![R49-G](images/game_screenshots_generated/batch_0001/shot_00009.png) | 맵 충돌 및 배치 영역 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 50 | ![R50-W](images/web_refs/web_ref_00062.jpg) | 오버타임 안정화 | ![R50-G](images/game_screenshots_generated/batch_0001/shot_00010.png) | 결과 화면 흐름 | 코스트 대비 성능 역전 | 입력 정확도 |
| 51 | ![R51-W](images/web_refs/web_ref_00063.jpg) | 메인 UI 가독성 | ![R51-G](images/game_screenshots_generated/batch_0001/shot_00021.png) | 상태머신 이벤트 연결 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 52 | ![R52-W](images/web_refs/web_ref_00064.jpg) | 카드핸드 조작성 | ![R52-G](images/game_screenshots_generated/batch_0001/shot_00022.png) | 카드 데이터 검증기 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 53 | ![R53-W](images/web_refs/web_ref_00065.jpg) | 레인 배치 규칙 | ![R53-G](images/game_screenshots_generated/batch_0001/shot_00023.png) | 전투 공식 파라미터 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 54 | ![R54-W](images/web_refs/web_ref_00066.jpg) | 마나 템포 밸런스 | ![R54-G](images/game_screenshots_generated/batch_0001/shot_00024.png) | 맵 충돌 및 배치 영역 | 코스트 대비 성능 역전 | 입력 정확도 |
| 55 | ![R55-W](images/web_refs/web_ref_00067.jpg) | 소환 이펙트 일관성 | ![R55-G](images/game_screenshots_generated/batch_0001/shot_00025.png) | 결과 화면 흐름 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 56 | ![R56-W](images/web_refs/web_ref_00068.jpg) | 승리 연출 명확성 | ![R56-G](images/game_screenshots_generated/batch_0001/shot_00026.png) | 상태머신 이벤트 연결 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 57 | ![R57-W](images/web_refs/web_ref_00069.jpg) | 실패 연출 명확성 | ![R57-G](images/game_screenshots_generated/batch_0001/shot_00027.png) | 카드 데이터 검증기 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 58 | ![R58-W](images/web_refs/web_ref_00070.jpg) | 카운터플레이 유도 | ![R58-G](images/game_screenshots_generated/batch_0001/shot_00028.png) | 전투 공식 파라미터 | 코스트 대비 성능 역전 | 입력 정확도 |
| 59 | ![R59-W](images/web_refs/web_ref_00071.jpg) | 덱 다양성 보장 | ![R59-G](images/game_screenshots_generated/batch_0001/shot_00029.png) | 맵 충돌 및 배치 영역 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 60 | ![R60-W](images/web_refs/web_ref_00072.jpg) | 오버타임 안정화 | ![R60-G](images/game_screenshots_generated/batch_0001/shot_00030.png) | 결과 화면 흐름 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 61 | ![R61-W](images/web_refs/web_ref_00073.jpg) | 메인 UI 가독성 | ![R61-G](images/game_screenshots_generated/batch_0001/shot_00031.png) | 상태머신 이벤트 연결 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 62 | ![R62-W](images/web_refs/web_ref_00074.jpg) | 카드핸드 조작성 | ![R62-G](images/game_screenshots_generated/batch_0001/shot_00032.png) | 카드 데이터 검증기 | 코스트 대비 성능 역전 | 입력 정확도 |
| 63 | ![R63-W](images/web_refs/web_ref_00075.jpg) | 레인 배치 규칙 | ![R63-G](images/game_screenshots_generated/batch_0001/shot_00033.png) | 전투 공식 파라미터 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 64 | ![R64-W](images/web_refs/web_ref_00076.jpg) | 마나 템포 밸런스 | ![R64-G](images/game_screenshots_generated/batch_0001/shot_00034.png) | 맵 충돌 및 배치 영역 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 65 | ![R65-W](images/web_refs/web_ref_00077.jpg) | 소환 이펙트 일관성 | ![R65-G](images/game_screenshots_generated/batch_0001/shot_00035.png) | 결과 화면 흐름 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 66 | ![R66-W](images/web_refs/web_ref_00078.jpg) | 승리 연출 명확성 | ![R66-G](images/game_screenshots_generated/batch_0001/shot_00036.png) | 상태머신 이벤트 연결 | 코스트 대비 성능 역전 | 입력 정확도 |
| 67 | ![R67-W](images/web_refs/web_ref_00079.jpg) | 실패 연출 명확성 | ![R67-G](images/game_screenshots_generated/batch_0001/shot_00037.png) | 카드 데이터 검증기 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 68 | ![R68-W](images/web_refs/web_ref_00080.jpg) | 카운터플레이 유도 | ![R68-G](images/game_screenshots_generated/batch_0001/shot_00038.png) | 전투 공식 파라미터 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 69 | ![R69-W](images/web_refs/web_ref_00081.jpg) | 덱 다양성 보장 | ![R69-G](images/game_screenshots_generated/batch_0001/shot_00039.png) | 맵 충돌 및 배치 영역 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 70 | ![R70-W](images/web_refs/web_ref_00082.jpg) | 오버타임 안정화 | ![R70-G](images/game_screenshots_generated/batch_0001/shot_00040.png) | 결과 화면 흐름 | 코스트 대비 성능 역전 | 입력 정확도 |
| 71 | ![R71-W](images/web_refs/web_ref_00083.jpg) | 메인 UI 가독성 | ![R71-G](images/game_screenshots_generated/batch_0002/shot_00011.png) | 상태머신 이벤트 연결 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 72 | ![R72-W](images/web_refs/web_ref_00084.jpg) | 카드핸드 조작성 | ![R72-G](images/game_screenshots_generated/batch_0002/shot_00012.png) | 카드 데이터 검증기 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 73 | ![R73-W](images/web_refs/web_ref_00085.jpg) | 레인 배치 규칙 | ![R73-G](images/game_screenshots_generated/batch_0002/shot_00013.png) | 전투 공식 파라미터 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 74 | ![R74-W](images/web_refs/web_ref_00086.jpg) | 마나 템포 밸런스 | ![R74-G](images/game_screenshots_generated/batch_0002/shot_00014.png) | 맵 충돌 및 배치 영역 | 코스트 대비 성능 역전 | 입력 정확도 |
| 75 | ![R75-W](images/web_refs/web_ref_00087.jpg) | 소환 이펙트 일관성 | ![R75-G](images/game_screenshots_generated/batch_0002/shot_00015.png) | 결과 화면 흐름 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 76 | ![R76-W](images/web_refs/web_ref_00088.jpg) | 승리 연출 명확성 | ![R76-G](images/game_screenshots_generated/batch_0002/shot_00016.png) | 상태머신 이벤트 연결 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 77 | ![R77-W](images/web_refs/web_ref_00089.jpg) | 실패 연출 명확성 | ![R77-G](images/game_screenshots_generated/batch_0002/shot_00017.png) | 카드 데이터 검증기 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 78 | ![R78-W](images/web_refs/web_ref_00090.jpg) | 카운터플레이 유도 | ![R78-G](images/game_screenshots_generated/batch_0002/shot_00018.png) | 전투 공식 파라미터 | 코스트 대비 성능 역전 | 입력 정확도 |
| 79 | ![R79-W](images/web_refs/web_ref_00091.jpg) | 덱 다양성 보장 | ![R79-G](images/game_screenshots_generated/batch_0002/shot_00019.png) | 맵 충돌 및 배치 영역 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 80 | ![R80-W](images/web_refs/web_ref_00092.jpg) | 오버타임 안정화 | ![R80-G](images/game_screenshots_generated/batch_0002/shot_00020.png) | 결과 화면 흐름 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 81 | ![R81-W](images/web_refs/web_ref_00093.jpg) | 메인 UI 가독성 | ![R81-G](images/game_screenshots_generated/batch_0001/shot_00001.png) | 상태머신 이벤트 연결 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 82 | ![R82-W](images/web_refs/web_ref_00094.jpg) | 카드핸드 조작성 | ![R82-G](images/game_screenshots_generated/batch_0001/shot_00002.png) | 카드 데이터 검증기 | 코스트 대비 성능 역전 | 입력 정확도 |
| 83 | ![R83-W](images/web_refs/web_ref_00095.jpg) | 레인 배치 규칙 | ![R83-G](images/game_screenshots_generated/batch_0001/shot_00003.png) | 전투 공식 파라미터 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 84 | ![R84-W](images/web_refs/web_ref_00096.jpg) | 마나 템포 밸런스 | ![R84-G](images/game_screenshots_generated/batch_0001/shot_00004.png) | 맵 충돌 및 배치 영역 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 85 | ![R85-W](images/web_refs/web_ref_00097.jpg) | 소환 이펙트 일관성 | ![R85-G](images/game_screenshots_generated/batch_0001/shot_00005.png) | 결과 화면 흐름 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 86 | ![R86-W](images/web_refs/web_ref_00098.jpg) | 승리 연출 명확성 | ![R86-G](images/game_screenshots_generated/batch_0001/shot_00006.png) | 상태머신 이벤트 연결 | 코스트 대비 성능 역전 | 입력 정확도 |
| 87 | ![R87-W](images/web_refs/web_ref_00099.jpg) | 실패 연출 명확성 | ![R87-G](images/game_screenshots_generated/batch_0001/shot_00007.png) | 카드 데이터 검증기 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 88 | ![R88-W](images/web_refs/web_ref_00100.jpg) | 카운터플레이 유도 | ![R88-G](images/game_screenshots_generated/batch_0001/shot_00008.png) | 전투 공식 파라미터 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 89 | ![R89-W](images/web_refs/web_ref_00101.jpg) | 덱 다양성 보장 | ![R89-G](images/game_screenshots_generated/batch_0001/shot_00009.png) | 맵 충돌 및 배치 영역 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 90 | ![R90-W](images/web_refs/web_ref_00102.jpg) | 오버타임 안정화 | ![R90-G](images/game_screenshots_generated/batch_0001/shot_00010.png) | 결과 화면 흐름 | 코스트 대비 성능 역전 | 입력 정확도 |
| 91 | ![R91-W](images/web_refs/web_ref_00103.jpg) | 메인 UI 가독성 | ![R91-G](images/game_screenshots_generated/batch_0001/shot_00021.png) | 상태머신 이벤트 연결 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 92 | ![R92-W](images/web_refs/web_ref_00104.jpg) | 카드핸드 조작성 | ![R92-G](images/game_screenshots_generated/batch_0001/shot_00022.png) | 카드 데이터 검증기 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 93 | ![R93-W](images/web_refs/web_ref_00105.jpg) | 레인 배치 규칙 | ![R93-G](images/game_screenshots_generated/batch_0001/shot_00023.png) | 전투 공식 파라미터 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 94 | ![R94-W](images/web_refs/web_ref_00106.jpg) | 마나 템포 밸런스 | ![R94-G](images/game_screenshots_generated/batch_0001/shot_00024.png) | 맵 충돌 및 배치 영역 | 코스트 대비 성능 역전 | 입력 정확도 |
| 95 | ![R95-W](images/web_refs/web_ref_00107.jpg) | 소환 이펙트 일관성 | ![R95-G](images/game_screenshots_generated/batch_0001/shot_00025.png) | 결과 화면 흐름 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 96 | ![R96-W](images/web_refs/web_ref_00108.jpg) | 승리 연출 명확성 | ![R96-G](images/game_screenshots_generated/batch_0001/shot_00026.png) | 상태머신 이벤트 연결 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |
| 97 | ![R97-W](images/web_refs/web_ref_00109.jpg) | 실패 연출 명확성 | ![R97-G](images/game_screenshots_generated/batch_0001/shot_00027.png) | 카드 데이터 검증기 | Null 접근과 전이 누락 | 재미도 4점 척도 |
| 98 | ![R98-W](images/web_refs/web_ref_00110.jpg) | 카운터플레이 유도 | ![R98-G](images/game_screenshots_generated/batch_0001/shot_00028.png) | 전투 공식 파라미터 | 코스트 대비 성능 역전 | 입력 정확도 |
| 99 | ![R99-W](images/web_refs/web_ref_00111.jpg) | 덱 다양성 보장 | ![R99-G](images/game_screenshots_generated/batch_0001/shot_00029.png) | 맵 충돌 및 배치 영역 | 과도한 이펙트 중첩 | 프레임 안정성 |
| 100 | ![R100-W](images/web_refs/web_ref_00112.jpg) | 오버타임 안정화 | ![R100-G](images/game_screenshots_generated/batch_0001/shot_00030.png) | 결과 화면 흐름 | 승패 판정 경계값 | 튜토리얼 없이 플레이 가능성 |

## 6. 품질 게이트

| 게이트 | 통과 기준 | 실패 시 조치 |
|---|---|---|
| 레퍼런스 적합성 | 목표와 직접 관련된 이미지 2장 이상 | 재수집 후 재기획 |
| 리뷰 | 치명/높음 이슈 0건 | 수정 후 동일 케이스 재검증 |
| QA 기능 | 배치, 전투, 승패, 재시작 정상 | 실패 로그 첨부 후 수정 |
| QA 재미 | 평균 3.0/4.0 이상 | 카드 룰과 수치 재조정 |

## 7. 산출물 링크

- 반복 데이터: `docs/plans/data/ralph_cycle_100.csv`
- 페이지 데이터: `docs/plans/data/master_plan_pages.csv`
- 웹 레퍼런스 소스: `docs/plans/data/web_reference_sources.csv`
- ComfyUI 매니페스트: `docs/plans/data/game_screenshot_generated_manifest.csv`

## 8. 개발 착수 항목

1. `scripts/battle/` 전투 공식 파라미터 테이블 적용
2. `scripts/ui/` 카드 선택/취소 피드백 통일
3. `resources/cards/` 카드 태그 표준화와 덱 검증 훅 추가
4. 사이클별 헤드리스 스모크와 수동 QA 병행 실행