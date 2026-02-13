class_name State extends Node
## 상태 머신의 기본 상태 클래스

signal transition_requested(new_state_name: String)

var character: CharacterBody3D
var animation_player: AnimationPlayer


func _ready() -> void:
	set_physics_process(false)
	set_process(false)


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(delta: float) -> void:
	pass


func frame_update(delta: float) -> void:
	pass


func handle_input(event: InputEvent) -> void:
	pass


func play_animation(anim_name: String) -> void:
	if not animation_player:
		return
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		# 부분 일치 폴백 시도
		for a in animation_player.get_animation_list():
			if anim_name.to_lower() in a.to_lower():
				animation_player.play(a)
				return


func request_transition(new_state_name: String) -> void:
	transition_requested.emit(new_state_name)
