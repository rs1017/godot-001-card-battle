class_name WalkState extends State
## Movement state.

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

	# Keep walk animation alive even for non-loop clips.
	if animation_player and not animation_player.is_playing():
		if _minion.has_method("get_card_data"):
			play_animation(_minion.get_card_data().anim_walk)
		else:
			play_animation("Walking_A")

	if _minion.has_method("find_closest_enemy"):
		var enemy: Node = _minion.find_closest_enemy()
		if enemy:
			request_transition("AttackState")
			return

	if _minion.has_method("move_along_waypoints"):
		_minion.move_along_waypoints(delta)
		if _minion._current_waypoint_index >= _minion._waypoints.size():
			if not _reached_end:
				_reached_end = true
				if _minion.has_method("get_card_data"):
					play_animation(_minion.get_card_data().anim_idle)
				else:
					play_animation("Idle")
