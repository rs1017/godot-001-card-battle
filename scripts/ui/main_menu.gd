extends Control
## 메인 메뉴
## 배틀 시작과 종료를 처리합니다.

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/Title
@onready var subtitle_label: Label = $VBoxContainer/Subtitle

var _is_transitioning: bool = false


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 타이틀 스타일
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

	# 버튼 스타일
	start_button.add_theme_font_size_override("font_size", 22)
	quit_button.add_theme_font_size_override("font_size", 22)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()


func _on_start_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	start_button.disabled = true
	quit_button.disabled = true
	get_tree().change_scene_to_file("res://scenes/battle/battle_arena.tscn")


func _on_quit_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	start_button.disabled = true
	quit_button.disabled = true
	get_tree().quit()
