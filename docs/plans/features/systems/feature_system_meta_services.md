# [SYS-META-001] 메타/소셜 통합 시스템 기획서

## 1. 목표
- 전투 외 메타 기능(로그인, 상점, 인벤토리, 채팅, 친구/파티/길드, 트리거, 스킬, 아이템, 우편, 로그)을 단일 런타임 서비스 레이어로 제공한다.
- 초기 버전은 로컬 메모리 기반으로 구현하고, 이후 서버 연동 시 인터페이스를 유지한 채 저장소/네트워크 어댑터만 교체 가능하도록 분리한다.

## 2. 입력/출력
| 구분 | 내용 |
|---|---|
| 입력 | UI 액션, 디버그 콘솔 호출, 이벤트 버스 요청 |
| 출력 | 서비스 상태 갱신, EventBus 시그널, 감사 로그 |

## 3. 핵심 규칙
| 시스템 | 규칙 |
|---|---|
| 로그인 | `user_id` 기준 단일 세션 유지, 로그인 성공 시 프로필/지갑 초기화 보장 |
| 상점 | 상품은 카탈로그 기준 검증 후 구매 처리, 재화 부족 시 지급 금지 |
| 카드 인벤 | 카드 수량은 음수 금지, 스냅샷 조회 API 제공 |
| 채팅 | 채널 단위 최근 메시지 보관(기본 50개), 빈 메시지 차단 |
| 친구 | 본인 추가 금지, 중복 요청/중복 친구 금지 |
| 파티 | 파티 최대 4인, 파티장만 해산 가능 |
| 길드 | 길드 최대 30인, 길드장 위임 시 기존 길드장 멤버 유지 |
| 트리거 | `trigger_id` 기준 리스너 등록/해제, 발화 시 EventBus + 콜백 동시 처리 |
| 스킬 | 쿨다운 중 재시전 금지, 마나 부족 시 시전 실패 |
| 아이템 | 지급/소모 이력은 로그 서비스에 기록 |
| 우편 | 첨부 보상은 1회만 수령 가능 |
| 로그 | 메모리 로그 500건 유지, 초과 시 FIFO 제거 |

## 4. 상태
| 상태 | 설명 |
|---|---|
| Unauthenticated | 로그인 이전 상태 |
| Authenticated | 로그인 완료, 메타 시스템 사용 가능 |
| SocialReady | 친구/파티/길드 API 활성 |
| LiveOpsReady | 상점/우편/아이템 API 활성 |

## 5. 예외 처리
| 예외 | 처리 |
|---|---|
| 잘못된 로그인 자격 | 실패 코드 반환 + 경고 로그 |
| 없는 상품 구매 요청 | 실패 코드 반환 + 로그 |
| 카드/아이템 음수 차감 | 연산 차단 + 오류 로그 |
| 파티/길드 정원 초과 | 가입 거절 |
| 우편 중복 수령 | 재수령 차단 + 알림 |
| 등록되지 않은 트리거 발화 | 에러 없이 무시 + 디버그 로그 |

## 6. 구현 연결
- `scripts/autoload/event_bus.gd`
- `scripts/autoload/log_service.gd`
- `scripts/autoload/auth_service.gd`
- `scripts/autoload/inventory_service.gd`
- `scripts/autoload/shop_service.gd`
- `scripts/autoload/chat_service.gd`
- `scripts/autoload/social_service.gd`
- `scripts/autoload/trigger_service.gd`
- `scripts/autoload/skill_service.gd`
- `scripts/autoload/mail_service.gd`r`n- `scripts/autoload/meta_persistence_service.gd`

## 7. 검수 기준
- 로그인 -> 상점 구매 -> 인벤 증가 흐름 100회 호출 시 실패율 0%.
- 우편 첨부 보상 중복 수령 시도 100회에서 중복 지급 0건.
- 트리거 발화 1000회에서 등록 리스너 누락 호출 0건.
- 채팅 메시지 1000건 입력 후 채널 보관 메시지 수가 최대치(50)로 유지.

