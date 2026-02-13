extends CanvasLayer
## 배틀 HUD
## 체력바, 마나, 카드, 레인 선택, 게임 오버 화면을 관리합니다.

signal card_selected(card_index: int)
signal lane_selected(lane_index: int)

var _player_tower: StaticBody3D
var _enemy_tower: StaticBody3D

# UI 노드들 (런타임에 생성)
var _top_bar: HBoxContainer
var _player_hp_label: Label
var _enemy_hp_label: Label
var _timer_label: Label
var _mana_bar: HBoxContainer
var _mana_progress: ProgressBar
var _mana_label: Label
var _card_hand: HBoxContainer
var _next_card_panel: PanelContainer
var _next_card_name_label: Label
var _next_card_cost_label: Label
var _lane_overlay: Control
var _lane_hint_label: Label
var _game_over_panel: PanelContainer
var _pause_overlay: ColorRect
var _go_overlay: ColorRect

const CardUIScene: PackedScene = preload("res://scenes/ui/card_ui.tscn")

var _card_uis: Array = []
var _current_mana: float = 0.0
var _match_timer: float = 0.0
var _use_external_timer: bool = false
var _card_deck: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _process(delta: float) -> void:
	if not _use_external_timer and not get_tree().paused:
		_match_timer += delta
	if _timer_label:
		if not _use_external_timer:
			var minutes: int = int(_match_timer) / 60
			var seconds: int = int(_match_timer) % 60
			_timer_label.text = "%d:%02d" % [minutes, seconds]

	# 일시정지 오버레이
	if _pause_overlay:
		_pause_overlay.visible = GameManager.current_state == GameManager.GameState.BATTLE_PAUSED

	# 타워 HP 업데이트
	_update_tower_hp()


func setup(player_tower: StaticBody3D, enemy_tower: StaticBody3D, card_deck: Node = null) -> void:
	_player_tower = player_tower
	_enemy_tower = enemy_tower
	_card_deck = card_deck
	_update_next_card_preview()


func _build_ui() -> void:
	# 메인 컨테이너
	var main: Control = Control.new()
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main)

	# === Top Bar ===
	_top_bar = HBoxContainer.new()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 50
	_top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	main.add_child(_top_bar)

	var top_bg: PanelContainer = PanelContainer.new()
	_top_bar.add_child(top_bg)
	var top_hbox: HBoxContainer = HBoxContainer.new()
	top_bg.add_child(top_hbox)
	top_hbox.add_theme_constant_override("separation", 40)

	_player_hp_label = Label.new()
	_player_hp_label.text = "Player: 2000"
	_player_hp_label.add_theme_font_size_override("font_size", 20)
	top_hbox.add_child(_player_hp_label)

	_timer_label = Label.new()
	_timer_label.text = "0:00"
	_timer_label.add_theme_font_size_override("font_size", 24)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size.x = 80
	top_hbox.add_child(_timer_label)

	_enemy_hp_label = Label.new()
	_enemy_hp_label.text = "Enemy: 2000"
	_enemy_hp_label.add_theme_font_size_override("font_size", 20)
	top_hbox.add_child(_enemy_hp_label)

	# === Mana Bar ===
	_mana_bar = HBoxContainer.new()
	_mana_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_mana_bar.offset_top = -250
	_mana_bar.offset_bottom = -220
	_mana_bar.offset_left = 200
	_mana_bar.offset_right = -200
	main.add_child(_mana_bar)

	_mana_progress = ProgressBar.new()
	_mana_progress.max_value = 10.0
	_mana_progress.value = 5.0
	_mana_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mana_progress.custom_minimum_size.y = 25
	_mana_progress.show_percentage = false

	# 마나바 스타일
	var mana_bg: StyleBoxFlat = StyleBoxFlat.new()
	mana_bg.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	mana_bg.corner_radius_top_left = 4
	mana_bg.corner_radius_top_right = 4
	mana_bg.corner_radius_bottom_left = 4
	mana_bg.corner_radius_bottom_right = 4
	_mana_progress.add_theme_stylebox_override("background", mana_bg)

	var mana_fill: StyleBoxFlat = StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.2, 0.4, 0.9, 0.9)
	mana_fill.corner_radius_top_left = 4
	mana_fill.corner_radius_top_right = 4
	mana_fill.corner_radius_bottom_left = 4
	mana_fill.corner_radius_bottom_right = 4
	_mana_progress.add_theme_stylebox_override("fill", mana_fill)

	_mana_bar.add_child(_mana_progress)

	_mana_label = Label.new()
	_mana_label.text = " 5/10"
	_mana_label.add_theme_font_size_override("font_size", 18)
	_mana_label.custom_minimum_size.x = 60
	_mana_bar.add_child(_mana_label)

	# === Card Hand ===
	_card_hand = HBoxContainer.new()
	_card_hand.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_card_hand.offset_top = -210
	_card_hand.offset_bottom = -10
	_card_hand.offset_left = -340
	_card_hand.offset_right = 340
	_card_hand.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_hand.add_theme_constant_override("separation", 10)
	main.add_child(_card_hand)

	# === Next Card Preview ===
	_next_card_panel = PanelContainer.new()
	_next_card_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_next_card_panel.offset_left = 20
	_next_card_panel.offset_top = -170
	_next_card_panel.offset_right = 220
	_next_card_panel.offset_bottom = -20
	main.add_child(_next_card_panel)

	var next_style: StyleBoxFlat = StyleBoxFlat.new()
	next_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	next_style.border_width_left = 2
	next_style.border_width_right = 2
	next_style.border_width_top = 2
	next_style.border_width_bottom = 2
	next_style.border_color = Color(0.6, 0.6, 0.75, 0.9)
	next_style.corner_radius_top_left = 8
	next_style.corner_radius_top_right = 8
	next_style.corner_radius_bottom_left = 8
	next_style.corner_radius_bottom_right = 8
	_next_card_panel.add_theme_stylebox_override("panel", next_style)

	var next_vbox: VBoxContainer = VBoxContainer.new()
	next_vbox.add_theme_constant_override("separation", 4)
	_next_card_panel.add_child(next_vbox)

	var next_title: Label = Label.new()
	next_title.text = "NEXT"
	next_title.add_theme_font_size_override("font_size", 14)
	next_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.95))
	next_vbox.add_child(next_title)

	_next_card_name_label = Label.new()
	_next_card_name_label.text = "-"
	_next_card_name_label.add_theme_font_size_override("font_size", 18)
	next_vbox.add_child(_next_card_name_label)

	_next_card_cost_label = Label.new()
	_next_card_cost_label.text = "Mana: -"
	_next_card_cost_label.add_theme_font_size_override("font_size", 14)
	next_vbox.add_child(_next_card_cost_label)

	# === Lane Select Overlay ===
	_lane_overlay = Control.new()
	_lane_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lane_overlay.visible = false
	_lane_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(_lane_overlay)

	var lane_bg: ColorRect = ColorRect.new()
	lane_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	lane_bg.color = Color(0.02, 0.02, 0.06, 0.45)
	lane_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lane_overlay.add_child(lane_bg)

	var lane_label: Label = Label.new()
	lane_label.text = "Select Lane"
	lane_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lane_label.offset_top = 80
	lane_label.add_theme_font_size_override("font_size", 28)
	lane_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lane_overlay.add_child(lane_label)

	_lane_hint_label = Label.new()
	_lane_hint_label.text = "Right click to cancel"
	_lane_hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lane_hint_label.offset_top = 120
	_lane_hint_label.add_theme_font_size_override("font_size", 18)
	_lane_hint_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	_lane_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lane_overlay.add_child(_lane_hint_label)

	var left_btn: Button = Button.new()
	left_btn.text = "LEFT LANE"
	left_btn.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	left_btn.offset_left = 100
	left_btn.offset_right = 300
	left_btn.custom_minimum_size = Vector2(200, 80)
	left_btn.pressed.connect(func(): lane_selected.emit(0))
	_lane_overlay.add_child(left_btn)

	var right_btn: Button = Button.new()
	right_btn.text = "RIGHT LANE"
	right_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right_btn.offset_left = -300
	right_btn.offset_right = -100
	right_btn.custom_minimum_size = Vector2(200, 80)
	right_btn.pressed.connect(func(): lane_selected.emit(1))
	_lane_overlay.add_child(right_btn)

	# === Game Over Overlay ===
	var go_overlay: ColorRect = ColorRect.new()
	go_overlay.name = "GameOverOverlay"
	go_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	go_overlay.color = Color(0, 0, 0, 0.6)
	go_overlay.visible = false
	_go_overlay = go_overlay
	main.add_child(go_overlay)

	_game_over_panel = PanelContainer.new()
	_game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	_game_over_panel.offset_left = -200
	_game_over_panel.offset_top = -150
	_game_over_panel.offset_right = 200
	_game_over_panel.offset_bottom = 150
	_game_over_panel.visible = false

	var go_style: StyleBoxFlat = StyleBoxFlat.new()
	go_style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	go_style.border_width_left = 3
	go_style.border_width_right = 3
	go_style.border_width_top = 3
	go_style.border_width_bottom = 3
	go_style.border_color = Color(0.8, 0.7, 0.3)
	go_style.corner_radius_top_left = 12
	go_style.corner_radius_top_right = 12
	go_style.corner_radius_bottom_left = 12
	go_style.corner_radius_bottom_right = 12
	_game_over_panel.add_theme_stylebox_override("panel", go_style)
	main.add_child(_game_over_panel)

	var go_vbox: VBoxContainer = VBoxContainer.new()
	go_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	go_vbox.add_theme_constant_override("separation", 20)
	_game_over_panel.add_child(go_vbox)

	var result_label: Label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "VICTORY!"
	result_label.add_theme_font_size_override("font_size", 42)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	go_vbox.add_child(result_label)

	var restart_btn: Button = Button.new()
	restart_btn.text = "Restart"
	restart_btn.custom_minimum_size = Vector2(180, 50)
	restart_btn.pressed.connect(_on_restart_pressed)
	go_vbox.add_child(restart_btn)

	var menu_btn: Button = Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(180, 50)
	menu_btn.pressed.connect(_on_menu_pressed)
	go_vbox.add_child(menu_btn)

	# === Pause Overlay ===
	_pause_overlay = ColorRect.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.color = Color(0, 0, 0, 0.4)
	_pause_overlay.visible = false
	main.add_child(_pause_overlay)

	var pause_label: Label = Label.new()
	pause_label.text = "PAUSED"
	pause_label.set_anchors_preset(Control.PRESET_CENTER)
	pause_label.add_theme_font_size_override("font_size", 48)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_overlay.add_child(pause_label)

	var resume_btn: Button = Button.new()
	resume_btn.text = "Resume (ESC)"
	resume_btn.set_anchors_preset(Control.PRESET_CENTER)
	resume_btn.offset_top = 50
	resume_btn.offset_bottom = 100
	resume_btn.offset_left = -80
	resume_btn.offset_right = 80
	resume_btn.pressed.connect(_on_resume_pressed)
	_pause_overlay.add_child(resume_btn)


func _on_mana_changed(current: float, max_mana: float) -> void:
	_current_mana = current
	if _mana_progress:
		_mana_progress.max_value = max_mana
		_mana_progress.value = current
	if _mana_label:
		_mana_label.text = " %d/%d" % [int(current), int(max_mana)]

	# 카드 어포더빌리티 업데이트
	for card_ui in _card_uis:
		if is_instance_valid(card_ui) and card_ui.card_data:
			card_ui.set_affordable(card_ui.card_data.mana_cost <= int(current))


func _on_hand_changed(hand: Array) -> void:
	# 기존 카드 제거
	for child in _card_hand.get_children():
		child.queue_free()
	_card_uis.clear()

	# 새 카드 추가
	for i in hand.size():
		var card_ui: PanelContainer = CardUIScene.instantiate()
		_card_hand.add_child(card_ui)
		card_ui.setup(hand[i], i)
		card_ui.card_clicked.connect(_on_card_clicked)
		card_ui.set_affordable(hand[i].mana_cost <= int(_current_mana))
		_card_uis.append(card_ui)

	_update_next_card_preview()


func _on_card_clicked(card_index: int) -> void:
	card_selected.emit(card_index)


func show_lane_select() -> void:
	if _lane_overlay:
		_lane_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		_lane_overlay.visible = true


func hide_lane_select() -> void:
	if _lane_overlay:
		_lane_overlay.visible = false
		_lane_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_game_over(player_won: bool) -> void:
	# 배경 오버레이 표시
	if _go_overlay:
		_go_overlay.visible = true
	elif has_node("GameOverOverlay"):
		get_node("GameOverOverlay").visible = true

	if _game_over_panel:
		_game_over_panel.visible = true
		# ResultLabel 찾기
		var result_label: Label = null
		for child in _game_over_panel.get_children():
			if child is VBoxContainer:
				for sub in child.get_children():
					if sub is Label and sub.name == "ResultLabel":
						result_label = sub
						break

		if result_label:
			if player_won:
				result_label.text = "VICTORY!"
				result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
			else:
				result_label.text = "DEFEAT!"
				result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))


func update_match_phase(phase_label: String, time_left: float) -> void:
	_use_external_timer = true
	if not _timer_label:
		return
	var sec_left: int = maxi(int(ceilf(time_left)), 0)
	var minutes: int = sec_left / 60
	var seconds: int = sec_left % 60
	_timer_label.text = "%s %d:%02d" % [phase_label, minutes, seconds]


func _update_tower_hp() -> void:
	if _player_tower and is_instance_valid(_player_tower):
		var hp: HealthComponent = _player_tower.get_node_or_null("HealthComponent")
		if hp and _player_hp_label:
			_player_hp_label.text = "Player: %d" % hp.current_health

	if _enemy_tower and is_instance_valid(_enemy_tower):
		var hp: HealthComponent = _enemy_tower.get_node_or_null("HealthComponent")
		if hp and _enemy_hp_label:
			_enemy_hp_label.text = "Enemy: %d" % hp.current_health


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_resume_pressed() -> void:
	GameManager.change_state(GameManager.GameState.BATTLE_PLAYING)
	_pause_overlay.visible = false


func _update_next_card_preview() -> void:
	if not _next_card_name_label or not _next_card_cost_label:
		return
	if not _card_deck or not _card_deck.has_method("get_next_card_preview"):
		_next_card_name_label.text = "-"
		_next_card_cost_label.text = "Mana: -"
		return

	var next_card: CardData = _card_deck.get_next_card_preview()
	if not next_card:
		_next_card_name_label.text = "-"
		_next_card_cost_label.text = "Mana: -"
		return

	_next_card_name_label.text = next_card.card_name
	_next_card_cost_label.text = "Mana: %d" % next_card.mana_cost
