extends PanelContainer
## 개별 카드 UI
## 카드 이름, 마나, 스탯 표시 및 클릭 이벤트 처리

signal card_clicked(card_index: int)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var mana_label: Label = $VBoxContainer/ManaLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel

var card_data: CardData
var card_index: int = 0
var _can_afford: bool = true
var _is_hovered: bool = false
var _hover_tween: Tween

# 타입별 색상
const TYPE_COLORS: Dictionary = {
	0: Color(0.8, 0.3, 0.2),   # MELEE - 빨강
	1: Color(0.3, 0.4, 0.8),   # RANGED - 파랑
	2: Color(0.3, 0.7, 0.3),   # TANK - 초록
}


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_style()


func setup(data: CardData, index: int) -> void:
	card_data = data
	card_index = index
	_update_display()
	_apply_style()


func set_affordable(affordable: bool) -> void:
	_can_afford = affordable
	mouse_filter = Control.MOUSE_FILTER_STOP if affordable else Control.MOUSE_FILTER_IGNORE
	if affordable:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.8)


func _apply_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if card_data:
		var type_color: Color = TYPE_COLORS.get(card_data.minion_type, Color.WHITE)
		style.border_color = type_color
	else:
		style.border_color = Color(0.5, 0.5, 0.5)

	add_theme_stylebox_override("panel", style)


func _update_display() -> void:
	if not card_data:
		return

	name_label.text = card_data.card_name
	mana_label.text = "Mana: %d" % card_data.mana_cost

	var type_names: Array[String] = ["MELEE", "RANGED", "TANK"]
	var category_names: Array[String] = ["TROOP", "SPELL", "BUILDING"]
	var type_index: int = int(card_data.minion_type)
	var category_index: int = int(card_data.card_category)
	var category_text: String = "UNKNOWN"
	if category_index >= 0 and category_index < category_names.size():
		category_text = category_names[category_index]
	if type_index < 0 or type_index >= type_names.size():
		type_label.text = "%s | UNKNOWN" % category_text
	else:
		type_label.text = "%s | %s" % [category_text, type_names[type_index]]

	var type_color: Color = TYPE_COLORS.get(card_data.minion_type, Color.WHITE)
	type_label.add_theme_color_override("font_color", type_color)

	stats_label.text = "HP:%d DMG:%d\nSPD:%.1f RNG:%.1f" % [
		card_data.health, card_data.damage, card_data.move_speed, card_data.attack_range
	]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _can_afford:
			card_clicked.emit(card_index)


func _on_mouse_entered() -> void:
	_is_hovered = true
	if _can_afford:
		if _hover_tween:
			_hover_tween.kill()
		_hover_tween = create_tween()
		_hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)


func _on_mouse_exited() -> void:
	_is_hovered = false
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
