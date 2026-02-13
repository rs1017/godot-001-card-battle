extends Node
## 게임 상태를 관리하는 매니저
## 게임의 전체적인 상태 전환을 담당합니다.

enum GameState {
	MAIN_MENU,
	BATTLE_PLAYING,
	BATTLE_DEPLOYING,
	BATTLE_PAUSED,
	GAME_OVER,
}

var current_state: GameState = GameState.MAIN_MENU
var _previous_state: GameState = GameState.MAIN_MENU


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event and event.is_action_pressed("pause"):
		_toggle_pause()


func change_state(new_state: GameState) -> void:
	_previous_state = current_state
	current_state = new_state
	var tree: SceneTree = get_tree()
	if not tree:
		push_warning("[GameManager] SceneTree is not available. Skipping pause state update.")
		return

	match new_state:
		GameState.BATTLE_PLAYING:
			tree.paused = false
		GameState.BATTLE_PAUSED:
			tree.paused = true
		GameState.GAME_OVER:
			tree.paused = true
		_:
			tree.paused = false

	print("[GameManager] State: %s -> %s" % [GameState.keys()[_previous_state], GameState.keys()[new_state]])


func _toggle_pause() -> void:
	if current_state == GameState.BATTLE_PLAYING:
		change_state(GameState.BATTLE_PAUSED)
	elif current_state == GameState.BATTLE_PAUSED:
		change_state(GameState.BATTLE_PLAYING)


func is_battle_active() -> bool:
	return current_state == GameState.BATTLE_PLAYING or current_state == GameState.BATTLE_DEPLOYING
