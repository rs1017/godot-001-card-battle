class_name DeathState extends State
## 사망 상태 - 애니메이션 재생 후 제거

var _death_timer: float = 0.0
const DEATH_DURATION: float = 1.5


func enter() -> void:
	_death_timer = 0.0

	if character:
		# 이동 정지
		character.velocity = Vector3.ZERO

		# 충돌 비활성화
		character.set_collision_layer(0)
		character.set_collision_mask(0)

		# AggroArea 비활성화
		var aggro: Area3D = character.get_node_or_null("AggroArea")
		if aggro:
			aggro.monitoring = false

	# 사망 애니메이션
	if character and character.has_method("get_card_data") and character.get_card_data():
		play_animation(character.get_card_data().anim_death)
	else:
		play_animation("Death_A")


func physics_update(delta: float) -> void:
	_death_timer += delta
	if _death_timer >= DEATH_DURATION:
		if character and is_instance_valid(character):
			character.queue_free()
