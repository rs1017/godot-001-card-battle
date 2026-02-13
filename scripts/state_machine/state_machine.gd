class_name StateMachine extends Node
## 유한 상태 머신 구현

signal state_changed(old_state: State, new_state: State)

@export var initial_state: State
@export var auto_start: bool = false

var current_state: State
var _states: Dictionary = {}
var _started: bool = false
var _bound_character: CharacterBody3D
var _bound_animation_player: AnimationPlayer


func _ready() -> void:
	_collect_states()
	_apply_bound_references()

	if auto_start:
		start()


func _process(delta: float) -> void:
	if current_state:
		current_state.frame_update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func transition_to(state_name: String) -> void:
	_collect_states()
	if not _states.has(state_name):
		push_error("[StateMachine] State not found: %s" % state_name)
		return

	var new_state: State = _states[state_name]
	if new_state == current_state:
		return

	var old_state: State = current_state

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()

	state_changed.emit(old_state, new_state)


func start() -> void:
	if _started:
		return
	_collect_states()
	_apply_bound_references()
	_started = true
	if initial_state:
		current_state = initial_state
		current_state.enter()
	elif not _states.is_empty():
		current_state = _states.values()[0]
		current_state.enter()


func setup(character: CharacterBody3D, animation_player: AnimationPlayer) -> void:
	_bound_character = character
	_bound_animation_player = animation_player
	_collect_states()
	_apply_bound_references()


func _collect_states() -> void:
	if not _states.is_empty():
		return
	for state in _states.values():
		if state and state.transition_requested.is_connected(_on_transition_requested):
			state.transition_requested.disconnect(_on_transition_requested)
	_states.clear()

	for child in get_children():
		if child is State:
			_states[child.name] = child
			if not child.transition_requested.is_connected(_on_transition_requested):
				child.transition_requested.connect(_on_transition_requested)


func _apply_bound_references() -> void:
	for state in _states.values():
		state.character = _bound_character
		state.animation_player = _bound_animation_player


func _on_transition_requested(new_state_name: String) -> void:
	transition_to(new_state_name)


func get_current_state_name() -> String:
	return current_state.name if current_state else ""


func is_in_state(state_name: String) -> bool:
	return current_state and current_state.name == state_name
