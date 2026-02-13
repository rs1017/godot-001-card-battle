class_name WalkState extends State
## 이동 상태 - 웨이포인트를 따라 레인을 이동, 적 감지 시 Attack 전환

var _minion: Node
var _reached_end: bool = false


func enter() -> void:
	_minion = character
	_reached_end = false
	if _minion and _minion.has_method("get_card_data"):
		play_animation(_minion.get_card_data().anim_walk)
	else:
		play_animation("Walking_A")


func physics_update(delta: float) -> void:
	if not _minion:
		return

	# 적 감지 시 공격 상태로 전환
	if _minion.has_method("find_closest_enemy"):
		var enemy: Node = _minion.find_closest_enemy()
		if enemy:
			request_transition("AttackState")
			return

	# 웨이포인트 따라 이동
	if _minion.has_method("move_along_waypoints"):
		var old_index: int = _minion._current_waypoint_index
		_minion.move_along_waypoints(delta)

		# 웨이포인트 끝 도달 시: 대기하며 적 탐색 계속
		if _minion._current_waypoint_index >= _minion._waypoints.size():
			if not _reached_end:
				_reached_end = true
				if _minion.has_method("get_card_data"):
					play_animation(_minion.get_card_data().anim_idle)
				else:
					play_animation("Idle")
