class_name AttackState extends State
## 공격 상태 - 적 추적/공격, 적 사망 시 Walk로 복귀

var _minion: Node
var _target: Node = null
var _attack_timer: float = 0.0
var _attack_cooldown: float = 1.0


func enter() -> void:
	_minion = character
	_attack_timer = 0.0
	if _minion and _minion.has_method("get_card_data"):
		var speed: float = maxf(_minion.get_card_data().attack_speed, 0.1)
		_attack_cooldown = 1.0 / speed
	_find_target()


func exit() -> void:
	_target = null


func physics_update(delta: float) -> void:
	if not _minion:
		return

	# 타겟 유효성 확인
	if not _is_target_valid():
		_find_target()
		if not _target:
			request_transition("WalkState")
			return

	var distance: float = _minion.global_position.distance_to(_target.global_position)
	var attack_range: float = 2.0
	if _minion.has_method("get_card_data"):
		attack_range = _minion.get_card_data().attack_range

	if distance <= attack_range:
		# 공격 범위 내 - 공격
		_face_target()
		_attack_timer += delta
		if _attack_timer >= _attack_cooldown:
			_attack_timer = 0.0
			_perform_attack()
	else:
		# 적 방향으로 추적
		_chase_target(delta)


func _find_target() -> void:
	if _minion.has_method("find_closest_enemy"):
		_target = _minion.find_closest_enemy()


func _is_target_valid() -> bool:
	if not is_instance_valid(_target):
		return false
	if _target.has_method("is_dead") and _target.is_dead():
		return false
	if _target is CharacterBody3D:
		var health_comp: HealthComponent = _target.get_node_or_null("HealthComponent")
		if health_comp and health_comp.is_dead:
			return false
	elif _target.has_node("HealthComponent"):
		var health_comp: HealthComponent = _target.get_node("HealthComponent")
		if health_comp.is_dead:
			return false
	return true


func _face_target() -> void:
	if _target:
		var look_pos: Vector3 = _target.global_position
		look_pos.y = _minion.global_position.y
		if look_pos.distance_to(_minion.global_position) > 0.01:
			_minion.look_at(look_pos)


func _chase_target(delta: float) -> void:
	var move_speed: float = 3.0
	if _minion.has_method("get_card_data"):
		move_speed = _minion.get_card_data().move_speed
		play_animation(_minion.get_card_data().anim_walk)
	else:
		play_animation("Walking_A")

	var direction: Vector3 = (_target.global_position - _minion.global_position).normalized()
	direction.y = 0
	var grav_y: float = _minion.velocity.y if not _minion.is_on_floor() else 0.0
	_minion.velocity = direction * move_speed
	_minion.velocity.y = grav_y
	_minion.move_and_slide()
	_face_target()


func _perform_attack() -> void:
	if _minion.has_method("get_card_data"):
		play_animation(_minion.get_card_data().anim_attack)
	else:
		play_animation("1H_Melee_Attack_Chop")

	# 데미지 적용
	if _target and is_instance_valid(_target):
		var damage: int = 20
		if _minion.has_method("get_card_data"):
			damage = _minion.get_card_data().damage

		var health_comp: HealthComponent = _target.get_node_or_null("HealthComponent")
		if health_comp:
			health_comp.take_damage(damage, _minion)
