extends Node
## Bug Reporter overlay tool.

const SAVE_DIR_USER: String = "user://bug_reports"
const SAVE_DIR_PROJECT: String = "res://docs/qa/bug_reports"
const BADGE_COLOR: Color = Color(0.9, 0.2, 0.2, 0.85)
const BADGE_FONT_SIZE: int = 14
const TOOLBAR_HEIGHT: int = 50
const BUG_BUTTON_WIDTH: float = 120.0
const BUG_BUTTON_HEIGHT: float = 64.0

var _canvas_layer: CanvasLayer
var _bug_button: Button
var _overlay_container: Control
var _toolbar: HBoxContainer
var _crop_rect: ColorRect
var _dim_background: ColorRect
var _report_panel: PanelContainer
var _preview_rect: TextureRect
var _badge_list_label: RichTextLabel
var _note_input: TextEdit

var _is_active: bool = false
var _is_cropping: bool = false
var _crop_start: Vector2 = Vector2.ZERO
var _crop_end: Vector2 = Vector2.ZERO
var _report_count: int = 0
var _resolved_save_dir: String = SAVE_DIR_USER

var _badge_nodes: Array[Control] = []
var _badge_map: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _ensure_save_dir():
		push_warning("[BugReporter] Disabled: no writable save directory")
		return
	_build_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
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


func _build_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas_layer)

	_bug_button = Button.new()
	_bug_button.text = "BUG"
	_bug_button.anchor_left = 1.0
	_bug_button.anchor_right = 1.0
	_bug_button.anchor_top = 0.5
	_bug_button.anchor_bottom = 0.5
	_bug_button.offset_left = -BUG_BUTTON_WIDTH - 12.0
	_bug_button.offset_right = -12.0
	_bug_button.offset_top = -BUG_BUTTON_HEIGHT * 0.5
	_bug_button.offset_bottom = BUG_BUTTON_HEIGHT * 0.5
	_bug_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.95, 0.15, 0.1, 0.95)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	_bug_button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(1.0, 0.25, 0.15, 1.0)
	_bug_button.add_theme_stylebox_override("hover", btn_hover)
	_bug_button.add_theme_font_size_override("font_size", 28)
	_bug_button.pressed.connect(_toggle_reporter)
	_canvas_layer.add_child(_bug_button)

	_overlay_container = Control.new()
	_overlay_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_container.visible = false
	_canvas_layer.add_child(_overlay_container)

	_dim_background = ColorRect.new()
	_dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_background.color = Color(0, 0, 0, 0.3)
	_dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_container.add_child(_dim_background)

	_crop_rect = ColorRect.new()
	_crop_rect.color = Color(0.2, 0.6, 1.0, 0.3)
	_crop_rect.visible = false
	_crop_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_container.add_child(_crop_rect)

	_build_toolbar()
	_build_report_panel()


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

	_toolbar.add_child(_create_toolbar_button("Save Full", _on_save_full))
	_toolbar.add_child(_create_toolbar_button("Crop Select", _on_crop_select))
	_toolbar.add_child(_create_toolbar_button("Save Note", _on_save_note))
	_toolbar.add_child(_create_toolbar_button("Close", _on_close))


func _build_report_panel() -> void:
	_report_panel = PanelContainer.new()
	_report_panel.anchor_left = 0.02
	_report_panel.anchor_right = 0.46
	_report_panel.anchor_top = 0.04
	_report_panel.anchor_bottom = 0.9
	_report_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_panel.visible = false

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	_report_panel.add_theme_stylebox_override("panel", panel_style)
	_overlay_container.add_child(_report_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_report_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Bug Report Preview"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	_preview_rect = TextureRect.new()
	_preview_rect.custom_minimum_size = Vector2(640, 320)
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_rect)

	_badge_list_label = RichTextLabel.new()
	_badge_list_label.custom_minimum_size = Vector2(640, 140)
	_badge_list_label.bbcode_enabled = false
	_badge_list_label.fit_content = false
	_badge_list_label.scroll_active = true
	vbox.add_child(_badge_list_label)

	_note_input = TextEdit.new()
	_note_input.custom_minimum_size = Vector2(640, 120)
	_note_input.placeholder_text = "재현 스텝/기대 결과/실제 결과를 입력하세요"
	_note_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(_note_input)


func _create_toolbar_button(text: String, callback: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 36)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(callback)
	return btn


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

	_build_badges()
	_print_report()

	_overlay_container.visible = true
	_report_panel.visible = true
	_update_report_panel()
	_bug_button.visible = false


func _deactivate() -> void:
	_is_active = false
	_is_cropping = false
	_crop_rect.visible = false
	_clear_badges()
	_overlay_container.visible = false
	_report_panel.visible = false
	_bug_button.visible = true
	get_tree().paused = false


func _build_badges() -> void:
	_clear_badges()
	_badge_map.clear()
	var idx: int = 1
	idx = _add_zone_badges(idx)
	idx = _add_entity_badges(idx)
	idx = _add_ui_badges(idx)


func _update_report_panel() -> void:
	_preview_rect.texture = get_viewport().get_texture()
	var keys: Array = _badge_map.keys()
	keys.sort()
	var lines: PackedStringArray = []
	for key in keys:
		lines.append("#%02d %s" % [int(key), str(_badge_map[key])])
	_badge_list_label.text = "\n".join(lines)
	if _note_input.text.is_empty():
		_note_input.text = ""


func _clear_badges() -> void:
	for badge in _badge_nodes:
		if is_instance_valid(badge):
			badge.queue_free()
	_badge_nodes.clear()


func _add_zone_badges(idx: int) -> int:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
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
	var battle_arena: Node = _find_battle_arena()
	if not battle_arena:
		return idx

	var player_tower: Node = battle_arena.get_node_or_null("Entities/PlayerTower")
	if player_tower and player_tower is Node3D:
		var hp_text: String = _get_health_text(player_tower)
		var screen_pos: Vector2 = _project_to_screen(camera, player_tower.global_position + Vector3(0, 2, 0))
		if _is_on_screen(screen_pos):
			_create_badge(idx, "Player Tower %s" % hp_text, screen_pos, BADGE_COLOR)
			idx += 1

	var enemy_tower: Node = battle_arena.get_node_or_null("Entities/EnemyTower")
	if enemy_tower and enemy_tower is Node3D:
		var hp_text2: String = _get_health_text(enemy_tower)
		var screen_pos2: Vector2 = _project_to_screen(camera, enemy_tower.global_position + Vector3(0, 2, 0))
		if _is_on_screen(screen_pos2):
			_create_badge(idx, "Enemy Tower %s" % hp_text2, screen_pos2, BADGE_COLOR)
			idx += 1

	var player_minions: Node = battle_arena.get_node_or_null("Entities/PlayerMinions")
	if player_minions:
		for minion in player_minions.get_children():
			if minion is CharacterBody3D and minion.has_method("is_dead") and not minion.is_dead():
				var card_name: String = _get_minion_name(minion)
				var hp_text3: String = _get_health_text(minion)
				var screen_pos3: Vector2 = _project_to_screen(camera, minion.global_position + Vector3(0, 1.5, 0))
				if _is_on_screen(screen_pos3):
					_create_badge(idx, "Player %s %s" % [card_name, hp_text3], screen_pos3, Color(0.2, 0.5, 0.9, 0.85))
					idx += 1

	var enemy_minions: Node = battle_arena.get_node_or_null("Entities/EnemyMinions")
	if enemy_minions:
		for minion in enemy_minions.get_children():
			if minion is CharacterBody3D and minion.has_method("is_dead") and not minion.is_dead():
				var card_name2: String = _get_minion_name(minion)
				var hp_text4: String = _get_health_text(minion)
				var screen_pos4: Vector2 = _project_to_screen(camera, minion.global_position + Vector3(0, 1.5, 0))
				if _is_on_screen(screen_pos4):
					_create_badge(idx, "Enemy %s %s" % [card_name2, hp_text4], screen_pos4, Color(0.9, 0.5, 0.2, 0.85))
					idx += 1

	return idx


func _add_ui_badges(idx: int) -> int:
	var main_menu: Node = _find_main_menu()
	if main_menu:
		return _add_main_menu_badges(idx, main_menu)
	var battle_hud: Node = _find_battle_hud()
	if not battle_hud:
		return idx

	var player_hp: Label = battle_hud.get("_player_hp_label")
	if player_hp and is_instance_valid(player_hp):
		_create_badge(idx, "Player HP Label", _get_control_screen_center(player_hp), Color(0.6, 0.2, 0.8, 0.85))
		idx += 1
	var timer_label: Label = battle_hud.get("_timer_label")
	if timer_label and is_instance_valid(timer_label):
		_create_badge(idx, "Timer", _get_control_screen_center(timer_label), Color(0.6, 0.2, 0.8, 0.85))
		idx += 1
	var enemy_hp: Label = battle_hud.get("_enemy_hp_label")
	if enemy_hp and is_instance_valid(enemy_hp):
		_create_badge(idx, "Enemy HP Label", _get_control_screen_center(enemy_hp), Color(0.6, 0.2, 0.8, 0.85))
		idx += 1
	var mana_progress: ProgressBar = battle_hud.get("_mana_progress")
	var mana_label: Label = battle_hud.get("_mana_label")
	if mana_progress and is_instance_valid(mana_progress):
		var mana_text: String = mana_label.text.strip_edges() if mana_label else ""
		_create_badge(idx, "Mana Bar: %s" % mana_text, _get_control_screen_center(mana_progress), Color(0.6, 0.2, 0.8, 0.85))
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
	panel.add_child(label)
	_overlay_container.add_child(panel)
	_overlay_container.move_child(panel, _overlay_container.get_child_count() - 2)
	panel.position = screen_pos - Vector2(20, 12)
	_badge_nodes.append(panel)


func _find_battle_arena() -> Node:
	var root: Node = get_tree().current_scene
	if root and root.name == "BattleArena":
		return root
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
	return control.get_global_rect().get_center()


func _get_timestamp() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"]]


func _build_unique_save_path(base_name: String, ext: String = "png") -> Dictionary:
	var abs_dir: String = ProjectSettings.globalize_path(_resolved_save_dir)
	var user_path: String = "%s/%s.%s" % [_resolved_save_dir, base_name, ext]
	var abs_path: String = "%s/%s.%s" % [abs_dir, base_name, ext]
	if not FileAccess.file_exists(abs_path):
		return {"user": user_path, "abs": abs_path}
	var suffix: int = Time.get_ticks_msec() % 100000
	user_path = "%s/%s_%d.%s" % [_resolved_save_dir, base_name, suffix, ext]
	abs_path = "%s/%s_%d.%s" % [abs_dir, base_name, suffix, ext]
	return {"user": user_path, "abs": abs_path}


func _save_screenshot(with_overlay: bool) -> String:
	var image: Image = get_viewport().get_texture().get_image()
	if not image:
		push_error("[BugReporter] Failed to capture screenshot")
		return ""
	var timestamp: String = _get_timestamp()
	var suffix: String = "" if not with_overlay else "_annotated"
	var save_paths: Dictionary = _build_unique_save_path("bug_%s%s" % [timestamp, suffix])
	var abs_path: String = save_paths["abs"]
	var err: Error = image.save_png(abs_path)
	if err != OK:
		push_error("[BugReporter] Failed to save screenshot: %s (error: %d)" % [abs_path, err])
		return ""
	print("[BugReporter] Screenshot: %s" % abs_path)
	return save_paths["user"]


func _save_crop(rect: Rect2i) -> String:
	var image: Image = get_viewport().get_texture().get_image()
	if not image:
		push_error("[BugReporter] Failed to capture screenshot for crop")
		return ""
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
	var err: Error = cropped.save_png(save_paths["abs"])
	if err != OK:
		push_error("[BugReporter] Failed to save crop: %s (error: %d)" % [save_paths["abs"], err])
		return ""
	print("[BugReporter] Crop saved: %s" % save_paths["abs"])
	return save_paths["user"]


func _ensure_save_dir() -> bool:
	_resolved_save_dir = SAVE_DIR_USER
	var candidates: Array[String] = [SAVE_DIR_PROJECT, SAVE_DIR_USER]
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
			return true
	push_error("[BugReporter] No writable save directory found. Tried user:// and res://docs/qa/bug_reports")
	return false


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


func _on_save_full() -> void:
	var path: String = _save_screenshot(true)
	if not path.is_empty():
		print("[BugReporter] Full screenshot saved with overlay")


func _on_crop_select() -> void:
	_is_cropping = true
	_crop_rect.visible = false
	print("[BugReporter] Drag to select crop area...")


func _on_save_note() -> void:
	var timestamp: String = _get_timestamp()
	var save_paths: Dictionary = _build_unique_save_path("bug_%s_note" % timestamp, "txt")
	var f: FileAccess = FileAccess.open(save_paths["abs"], FileAccess.WRITE)
	if not f:
		push_error("[BugReporter] Failed to write note file: %s" % save_paths["abs"])
		return
	f.store_line("[BugReporter] Report #%d" % _report_count)
	f.store_line("ScreenshotDir: %s" % ProjectSettings.globalize_path(_resolved_save_dir))
	f.store_line("--- Badges ---")
	var keys: Array = _badge_map.keys()
	keys.sort()
	for key in keys:
		f.store_line("#%02d %s" % [int(key), str(_badge_map[key])])
	f.store_line("--- Note ---")
	f.store_string(_note_input.text)
	f.close()
	print("[BugReporter] Note saved: %s" % save_paths["abs"])


func _on_close() -> void:
	_deactivate()


func _print_report() -> void:
	print("")
	print("[BugReporter] === BUG REPORT #%d ===" % _report_count)
	var sorted_keys: Array = _badge_map.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		print("  #%02d %s" % [int(key), str(_badge_map[key])])
	var global_path: String = ProjectSettings.globalize_path(_resolved_save_dir)
	print("[BugReporter] Save directory: %s" % global_path)
	print("")
