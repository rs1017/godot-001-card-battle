class_name IdleState extends State
## 대기 상태 - 스폰 후 0.5초 대기, 이후 Walk로 전환

var _timer: float = 0.0
const IDLE_DURATION: float = 0.5


func enter() -> void:
	_timer = 0.0
	if character and character.has_method("get_card_data"):
		play_animation(character.get_card_data().anim_idle)
	else:
		play_animation("Idle")


func physics_update(delta: float) -> void:
	_timer += delta
	if _timer >= IDLE_DURATION:
		request_transition("WalkState")
