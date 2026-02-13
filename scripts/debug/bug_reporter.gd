extends Node
## Bug Reporter - 디버그 오버레이 도구
## F12 또는 BUG 버튼으로 활성화하여 오브젝트 번호 오버레이, 스크린샷, 크롭 기능 제공

const SAVE_DIR_USER: String = "user://bug_reports"
const SAVE_DIR_PROJECT: String = "res://docs/qa/bug_reports"
const BADGE_COLOR: Color = Color(0.9, 0.2, 0.2, 0.85)
const BADGE_FONT_SIZE: int = 14
const TOOLBAR_HEIGHT: int = 50

var _canvas_layer: CanvasLayer
var _bug_button: Button
var _overlay_container: Control
var _toolbar: HBoxContainer
var _crop_rect: ColorRect
var _dim_background: ColorRect

var _is_active: bool = false
var _is_cropping: bool = false
var _crop_start: Vector2 = Vector2.ZERO
var _crop_end: Vector2 = Vector2.ZERO
var _report_count: int = 0
var _resolved_save_dir: String = SAVE_DIR_USER

var _badge_nodes: Array[Control] = []
var _badge_map: Dictionary = {}  # number -> description


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_save_dir()
	_build_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			_toggle_reporter()
			get_viewport().set_input_as_handled()

	if not _is_active:
		return

	if _is_cropping:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_crop_start = event.position
				_crop_end = event.position
				_update_crop_visual()
				_crop_rect.visible = true
			else:
				_crop_end = event.position
				_finish_crop()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_crop_end = event.position
			_update_crop_visual()
			get_viewport().set_input_as_handled()


# === UI 구성 ===

func _build_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas_layer)

	# BUG 버튼 (항상 표시)
	_bug_button = Button.new()
	_bug_button.text = "BUG"
	_bug_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_bug_button.offset_left = -70
	_bug_button.offset_top = 10
	_bug_button.offset_right = -10
	_bug_button.offset_bottom = 40
	_bug_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.8, 0.1, 0.1, 0.7)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	_bug_button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(1.0, 0.2, 0.2, 0.9)
	_bug_button.add_theme_stylebox_override("hover", btn_hover)
	_bug_button.add_theme_font_size_override("font_size", 14)
	_bug_button.pressed.connect(_toggle_reporter)
	_canvas_layer.add_child(_bug_button)

	# 오버레이 컨테이너 (활성화 시만 표시)
	_overlay_container = Control.new()
	_overlay_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_container.visible = false
	_canvas_layer.add_child(_overlay_container)

	# 반투명 배경
	_dim_background = ColorRect.new()
	_dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_background.color = Color(0, 0, 0, 0.3)
	_dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_container.add_child(_dim_background)

	# 크롭 영역 표시
	_crop_rect = ColorRect.new()
	_crop_rect.color = Color(0.2, 0.6, 1.0, 0.3)
	_crop_rect.visible = false
	_crop_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_container.add_child(_crop_rect)

	# 툴바 (하단)
	_build_toolbar()


func _build_toolbar() -> void:
	var toolbar_bg: PanelContainer = PanelContainer.new()
	toolbar_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toolbar_bg.offset_top = -TOOLBAR_HEIGHT
	var tb_style: StyleBoxFlat = StyleBoxFlat.new()
	tb_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	toolbar_bg.add_theme_stylebox_override("panel", tb_style)
	toolbar_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_container.add_child(toolbar_bg)

	_toolbar = HBoxContainer.new()
	_toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	_toolbar.add_theme_constant_override("separation", 20)
	toolbar_bg.add_child(_toolbar)

	var save_btn: Button = _create_toolbar_button("Save Full", _on_save_full)
	_toolbar.add_child(save_btn)

	var crop_btn: Button = _create_toolbar_button("Crop Select", _on_crop_select)
	_toolbar.add_child(crop_btn)

	var close_btn: Button = _create_toolbar_button("Close", _on_close)
	_toolbar.add_child(close_btn)


func _create_toolbar_button(text: String, callback: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 36)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(callback)
	return btn


# === 토글 ===

func _toggle_reporter() -> void:
	if _is_active:
		_deactivate()
	else:
		_activate()


func _activate() -> void:
	_is_active = true
	_is_cropping = false
	_report_count += 1
	get_tree().paused = true

	# 원본 스크린샷 저장 (번호 없이)
	_save_screenshot(false)

	# 번호 오버레이 생성
	_build_badges()
	_print_report()

	_overlay_container.visible = true
	_bug_button.visible = false


func _deactivate() -> void:
	_is_active = false
	_is_cropping = false
	_crop_rect.visible = false
	_clear_badges()
	_overlay_container.visible = false
	_bug_button.visible = true
	get_tree().paused = false


# === 번호 뱃지 시스템 ===

func _build_badges() -> void:
	_clear_badges()
	_badge_map.clear()
	var idx: int = 1

	# --- Zone ---
	idx = _add_zone_badges(idx)

	# --- Entity ---
	idx = _add_entity_badges(idx)

	# --- UI ---
	idx = _add_ui_badges(idx)


func _clear_badges() -> void:
	for badge in _badge_nodes:
		if is_instance_valid(badge):
			badge.queue_free()
	_badge_nodes.clear()


func _add_zone_badges(idx: int) -> int:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	# 고정 영역들 (화면 비율 기반)
	var zones: Array[Dictionary] = [
		{"name": "Left Lane", "pos": Vector2(viewport_size.x * 0.3, viewport_size.y * 0.5)},
		{"name": "Right Lane", "pos": Vector2(viewport_size.x * 0.7, viewport_size.y * 0.5)},
		{"name": "River (Center)", "pos": Vector2(viewport_size.x * 0.5, viewport_size.y * 0.45)},
		{"name": "Player Territory", "pos": Vector2(viewport_size.x * 0.5, viewport_size.y * 0.75)},
		{"name": "Enemy Territory", "pos": Vector2(viewport_size.x * 0.5, viewport_size.y * 0.2)},
	]

	for zone in zones:
		_create_badge(idx, zone["name"], zone["pos"], Color(0.2, 0.6, 0.2, 0.85))
		idx += 1

	return idx


func _add_entity_badges(idx: int) -> int:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return idx

	# 전투 씬에서 엔티티 찾기
	var battle_arena: Node = _find_battle_arena()
	if not battle_arena:
		return idx

	# Player Tower
	var player_tower: Node = battle_arena.get_node_or_null("Entities/PlayerTower")
	if player_tower and player_tower is Node3D:
		var hp_text: String = _get_health_text(player_tower)
		var screen_pos: Vector2 = _project_to_screen(camera, player_tower.global_position + Vector3(0, 2, 0))
		if _is_on_screen(screen_pos):
			_create_badge(idx, "Player Tower %s" % hp_text, screen_pos, BADGE_COLOR)
			idx += 1

	# Enemy Tower
	var enemy_tower: Node = battle_arena.get_node_or_null("Entities/EnemyTower")
	if enemy_tower and enemy_tower is Node3D:
		var hp_text: String = _get_health_text(enemy_tower)
		var screen_pos: Vector2 = _project_to_screen(camera, enemy_tower.global_position + Vector3(0, 2, 0))
		if _is_on_screen(screen_pos):
			_create_badge(idx, "Enemy Tower %s" % hp_text, screen_pos, BADGE_COLOR)
			idx += 1

	# Player Minions
	var player_minions: Node = battle_arena.get_node_or_null("Entities/PlayerMinions")
	if player_minions:
		for minion in player_minions.get_children():
			if minion is CharacterBody3D and minion.has_method("is_dead") and not minion.is_dead():
				var card_name: String = _get_minion_name(minion)
				var hp_text: String = _get_health_text(minion)
				var screen_pos: Vector2 = _project_to_screen(camera, minion.global_position + Vector3(0, 1.5, 0))
				if _is_on_screen(screen_pos):
					_create_badge(idx, "Player %s %s" % [card_name, hp_text], screen_pos, Color(0.2, 0.5, 0.9, 0.85))
					idx += 1

	# Enemy Minions
	var enemy_minions: Node = battle_arena.get_node_or_null("Entities/EnemyMinions")
	if enemy_minions:
		for minion in enemy_minions.get_children():
			if minion is CharacterBody3D and minion.has_method("is_dead") and not minion.is_dead():
				var card_name: String = _get_minion_name(minion)
				var hp_text: String = _get_health_text(minion)
				var screen_pos: Vector2 = _project_to_screen(camera, minion.global_position + Vector3(0, 1.5, 0))
				if _is_on_screen(screen_pos):
					_create_badge(idx, "Enemy %s %s" % [card_name, hp_text], screen_pos, Color(0.9, 0.5, 0.2, 0.85))
					idx += 1

	return idx


func _add_ui_badges(idx: int) -> int:
	# 메인 메뉴 UI 확인
	var main_menu: Node = _find_main_menu()
	if main_menu:
		return _add_main_menu_badges(idx, main_menu)

	# 배틀 HUD UI 확인
	var battle_hud: Node = _find_battle_hud()
	if not battle_hud:
		return idx

	# battle_hud.gd 멤버 변수에 직접 접근
	var player_hp: Label = battle_hud.get("_player_hp_label")
	if player_hp and is_instance_valid(player_hp):
		var screen_pos: Vector2 = _get_control_screen_center(player_hp)
		_create_badge(idx, "Player HP Label", screen_pos, Color(0.6, 0.2, 0.8, 0.85))
		idx += 1

	var timer_label: Label = battle_hud.get("_timer_label")
	if timer_label and is_instance_valid(timer_label):
		var screen_pos: Vector2 = _get_control_screen_center(timer_label)
		_create_badge(idx, "Timer", screen_pos, Color(0.6, 0.2, 0.8, 0.85))
		idx += 1

	var enemy_hp: Label = battle_hud.get("_enemy_hp_label")
	if enemy_hp and is_instance_valid(enemy_hp):
		var screen_pos: Vector2 = _get_control_screen_center(enemy_hp)
		_create_badge(idx, "Enemy HP Label", screen_pos, Color(0.6, 0.2, 0.8, 0.85))
		idx += 1

	# Mana bar
	var mana_progress: ProgressBar = battle_hud.get("_mana_progress")
	var mana_label: Label = battle_hud.get("_mana_label")
	if mana_progress and is_instance_valid(mana_progress):
		var mana_text: String = mana_label.text.strip_edges() if mana_label else ""
		var screen_pos: Vector2 = _get_control_screen_center(mana_progress)
		_create_badge(idx, "Mana Bar: %s" % mana_text, screen_pos, Color(0.6, 0.2, 0.8, 0.85))
		idx += 1

	# Card Hand (각 카드 개별)
	var card_uis: Array = battle_hud.get("_card_uis") if battle_hud.get("_card_uis") != null else []
	for i in card_uis.size():
		var card_ui: Control = card_uis[i]
		if is_instance_valid(card_ui):
			var card_data = card_ui.get("card_data")
			var card_info: String = "Card %d" % (i + 1)
			if card_data:
				card_info = "Card %d: %s (Mana: %d)" % [i + 1, card_data.card_name, card_data.mana_cost]
			var screen_pos: Vector2 = _get_control_screen_center(card_ui)
			_create_badge(idx, card_info, screen_pos, Color(0.8, 0.6, 0.1, 0.85))
			idx += 1

	return idx


func _add_main_menu_badges(idx: int, main_menu: Node) -> int:
	var ui_color: Color = Color(0.6, 0.2, 0.8, 0.85)

	var title: Label = main_menu.get_node_or_null("VBoxContainer/Title")
	if title and is_instance_valid(title):
		_create_badge(idx, "Title: %s" % title.text, _get_control_screen_center(title), ui_color)
		idx += 1

	var subtitle: Label = main_menu.get_node_or_null("VBoxContainer/Subtitle")
	if subtitle and is_instance_valid(subtitle):
		_create_badge(idx, "Subtitle: %s" % subtitle.text, _get_control_screen_center(subtitle), ui_color)
		idx += 1

	var start_btn: Button = main_menu.get_node_or_null("VBoxContainer/StartButton")
	if start_btn and is_instance_valid(start_btn):
		_create_badge(idx, "StartButton: %s" % start_btn.text, _get_control_screen_center(start_btn), ui_color)
		idx += 1

	var quit_btn: Button = main_menu.get_node_or_null("VBoxContainer/QuitButton")
	if quit_btn and is_instance_valid(quit_btn):
		_create_badge(idx, "QuitButton: %s" % quit_btn.text, _get_control_screen_center(quit_btn), ui_color)
		idx += 1

	return idx


func _create_badge(number: int, description: String, screen_pos: Vector2, color: Color) -> void:
	_badge_map[number] = description

	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label: Label = Label.new()
	label.text = "#%02d" % number
	label.add_theme_font_size_override("font_size", BADGE_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

	_overlay_container.add_child(panel)

	# 뱃지를 크롭 사각형 아래, 툴바 위에 배치
	_overlay_container.move_child(panel, _overlay_container.get_child_count() - 2)

	# 위치 설정 (뱃지 중앙이 screen_pos에 오도록)
	panel.position = screen_pos - Vector2(20, 12)

	_badge_nodes.append(panel)


# === 헬퍼 함수 ===

func _find_battle_arena() -> Node:
	var root: Node = get_tree().current_scene
	if root and root.name == "BattleArena":
		return root
	# 재귀 검색
	return _find_node_by_name(root, "BattleArena") if root else null


func _find_battle_hud() -> Node:
	var arena: Node = _find_battle_arena()
	if arena:
		return arena.get_node_or_null("BattleHUD")
	return null


func _find_main_menu() -> Node:
	var root: Node = get_tree().current_scene
	if root and root.name == "Main":
		return root
	return null


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found: Node = _find_node_by_name(child, target_name)
		if found:
			return found
	return null


func _get_health_text(entity: Node) -> String:
	var health_comp: Node = entity.get_node_or_null("HealthComponent")
	if health_comp:
		return "(HP: %d/%d)" % [health_comp.current_health, health_comp.max_health]
	return ""


func _get_minion_name(minion: Node) -> String:
	if minion.has_method("get_card_data"):
		var card_data = minion.get_card_data()
		if card_data:
			return card_data.card_name
	return "Minion"


func _project_to_screen(camera: Camera3D, world_pos: Vector3) -> Vector2:
	if camera.is_position_behind(world_pos):
		return Vector2(-1000, -1000)
	return camera.unproject_position(world_pos)


func _is_on_screen(pos: Vector2) -> bool:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return pos.x >= 0 and pos.x <= viewport_size.x and pos.y >= 0 and pos.y <= viewport_size.y


func _get_control_screen_center(control: Control) -> Vector2:
	var rect: Rect2 = control.get_global_rect()
	return rect.get_center()


# === 스크린샷 ===

func _get_timestamp() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"]]


func _build_unique_save_path(base_name: String) -> Dictionary:
	var abs_dir: String = ProjectSettings.globalize_path(_resolved_save_dir)
	var user_path: String = "%s/%s.png" % [_resolved_save_dir, base_name]
	var abs_path: String = "%s/%s.png" % [abs_dir, base_name]

	if not FileAccess.file_exists(abs_path):
		return {"user": user_path, "abs": abs_path}

	# 같은 초에 반복 저장될 수 있으므로 ticks 기반 suffix를 추가해 충돌 방지.
	var suffix: int = Time.get_ticks_msec() % 100000
	user_path = "%s/%s_%d.png" % [_resolved_save_dir, base_name, suffix]
	abs_path = "%s/%s_%d.png" % [abs_dir, base_name, suffix]
	return {"user": user_path, "abs": abs_path}


func _save_screenshot(with_overlay: bool) -> String:
	var image: Image = get_viewport().get_texture().get_image()
	if not image:
		push_error("[BugReporter] Failed to capture screenshot")
		return ""

	var timestamp: String = _get_timestamp()
	var suffix: String = "" if not with_overlay else "_annotated"
	var save_paths: Dictionary = _build_unique_save_path("bug_%s%s" % [timestamp, suffix])
	var path: String = save_paths["user"]
	var abs_path: String = save_paths["abs"]

	var err: Error = image.save_png(abs_path)
	if err != OK:
		push_error("[BugReporter] Failed to save screenshot: %s (error: %d)" % [abs_path, err])
		return ""

	print("[BugReporter] Screenshot: %s" % abs_path)
	return path


func _save_crop(rect: Rect2i) -> String:
	var image: Image = get_viewport().get_texture().get_image()
	if not image:
		push_error("[BugReporter] Failed to capture screenshot for crop")
		return ""

	# 범위 클램프
	var img_size: Vector2i = image.get_size()
	rect.position.x = clampi(rect.position.x, 0, img_size.x - 1)
	rect.position.y = clampi(rect.position.y, 0, img_size.y - 1)
	rect.size.x = clampi(rect.size.x, 1, img_size.x - rect.position.x)
	rect.size.y = clampi(rect.size.y, 1, img_size.y - rect.position.y)

	var cropped: Image = image.get_region(rect)
	if not cropped:
		push_error("[BugReporter] Failed to crop image")
		return ""

	var timestamp: String = _get_timestamp()
	var save_paths: Dictionary = _build_unique_save_path("bug_%s_crop" % timestamp)
	var path: String = save_paths["user"]
	var abs_path: String = save_paths["abs"]

	var err: Error = cropped.save_png(abs_path)
	if err != OK:
		push_error("[BugReporter] Failed to save crop: %s (error: %d)" % [abs_path, err])
		return ""

	print("[BugReporter] Crop saved: %s" % abs_path)
	return path


func _ensure_save_dir() -> void:
	_resolved_save_dir = SAVE_DIR_USER
	var candidates: Array[String] = [SAVE_DIR_USER, SAVE_DIR_PROJECT]
	for candidate in candidates:
		var abs_dir: String = ProjectSettings.globalize_path(candidate)
		var mk_err: Error = DirAccess.make_dir_recursive_absolute(abs_dir)
		if mk_err != OK and mk_err != ERR_ALREADY_EXISTS:
			continue
		var probe_path: String = "%s/.probe_write.tmp" % abs_dir
		var f: FileAccess = FileAccess.open(probe_path, FileAccess.WRITE)
		if f:
			f.store_string("ok")
			f.close()
			DirAccess.remove_absolute(probe_path)
			_resolved_save_dir = candidate
			print("[BugReporter] Save dir selected: %s" % abs_dir)
			return

	push_error("[BugReporter] No writable save directory found. Tried user:// and res://docs/qa/bug_reports")


# === 크롭 기능 ===

func _update_crop_visual() -> void:
	var rect: Rect2 = _get_crop_rect2()
	_crop_rect.position = rect.position
	_crop_rect.size = rect.size


func _get_crop_rect2() -> Rect2:
	var top_left: Vector2 = Vector2(minf(_crop_start.x, _crop_end.x), minf(_crop_start.y, _crop_end.y))
	var bottom_right: Vector2 = Vector2(maxf(_crop_start.x, _crop_end.x), maxf(_crop_start.y, _crop_end.y))
	return Rect2(top_left, bottom_right - top_left)


func _finish_crop() -> void:
	_is_cropping = false
	_crop_rect.visible = false

	var rect: Rect2 = _get_crop_rect2()
	if rect.size.x < 10 or rect.size.y < 10:
		print("[BugReporter] Crop area too small, cancelled")
		return

	var rect_i: Rect2i = Rect2i(int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y))
	_save_crop(rect_i)


# === 툴바 콜백 ===

func _on_save_full() -> void:
	var path: String = _save_screenshot(true)
	if not path.is_empty():
		print("[BugReporter] Full screenshot saved with overlay")


func _on_crop_select() -> void:
	_is_cropping = true
	_crop_rect.visible = false
	print("[BugReporter] Drag to select crop area...")


func _on_close() -> void:
	_deactivate()


# === 콘솔 리포트 ===

func _print_report() -> void:
	print("")
	print("[BugReporter] === BUG REPORT #%d ===" % _report_count)

	var current_category: String = ""

	var sorted_keys: Array = _badge_map.keys()
	sorted_keys.sort()

	for key in sorted_keys:
		var desc: String = _badge_map[key]
		var category: String = _get_category(key, desc)

		if category != current_category:
			print("  --- %s ---" % category)
			current_category = category

		print("    #%02d  %s" % [key, desc])

	var global_path: String = ProjectSettings.globalize_path(_resolved_save_dir)
	print("[BugReporter] Save directory: %s" % global_path)
	print("")


func _get_category(number: int, desc: String) -> String:
	if desc.contains("Lane") or desc.contains("River") or desc.contains("Territory"):
		return "Zone"
	elif desc.contains("Tower") or desc.contains("Player ") or desc.contains("Enemy "):
		if desc.contains("HP Label"):
			return "UI"
		if desc.contains("Tower") or desc.contains("Minion") or desc.contains("Knight") or desc.contains("Archer") or desc.contains("Mage") or desc.contains("Tank"):
			return "Entity"
		return "Entity"
	elif desc.begins_with("Card") or desc.contains("Mana") or desc.contains("Timer") or desc.contains("Label"):
		return "UI"
	elif desc.contains("Title") or desc.contains("Subtitle") or desc.contains("Button"):
		return "UI"
	return "Other"
