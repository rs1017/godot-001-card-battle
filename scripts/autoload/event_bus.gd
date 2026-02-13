extends Node
## 글로벌 이벤트 버스
## 게임 전체에서 사용되는 시그널을 중앙 관리합니다.

# 매치 이벤트
signal match_started
signal match_ended(player_won: bool)

# 미니언 이벤트
signal minion_spawned(minion: Node, team: int)
signal minion_killed(minion: Node, killer: Node)

# 타워 이벤트
signal tower_damaged(tower: Node, amount: int)
signal tower_destroyed(tower: Node)

# 카드 이벤트
signal card_played(card_data: Resource, team: int, lane: int)

# 마나 이벤트
signal mana_changed(current: float, max_mana: float)

# UI 이벤트
signal deploy_mode_entered(card_index: int)
signal deploy_mode_exited
signal lane_selected(lane_index: int)

# 메타 시스템 이벤트
signal auth_login_result(success: bool, user_id: String, reason_code: String)
signal shop_purchase_result(success: bool, product_id: String, quantity: int, reason_code: String, balance_after: int)
signal inventory_card_changed(card_id: String, delta: int, current_total: int)
signal chat_message_sent(channel_id: String, sender_id: String, message: String, timestamp: int)
signal system_log_added(level: String, category: String, message: String, timestamp: int)
signal friend_request_sent(from_user_id: String, to_user_id: String)
signal friend_status_changed(user_id: String, target_user_id: String, status: String)
signal party_updated(party_id: String, members: PackedStringArray)
signal guild_updated(guild_id: String, members: PackedStringArray)
signal trigger_fired(trigger_id: String, payload: Dictionary)
signal skill_cast_requested(caster_id: String, skill_id: String, target_id: String)
signal skill_cast_result(success: bool, skill_id: String, reason_code: String)
signal item_granted(item_id: String, amount: int, reason: String)
signal mail_received(mail_id: String, title: String)
signal mail_claimed(mail_id: String, attachments: Dictionary)
