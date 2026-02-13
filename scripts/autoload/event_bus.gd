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
