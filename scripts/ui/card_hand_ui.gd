extends HBoxContainer
## 카드 핸드 UI
## 4장의 카드를 표시하고 클릭 이벤트를 상위로 전달합니다.

signal card_selected(card_index: int)

const CardUIScene: PackedScene = preload("res://scenes/ui/card_ui.tscn")

var _card_uis: Array = []
var _current_mana: float = 0.0


func update_hand(hand: Array) -> void:
	# 기존 카드 제거
	for child in get_children():
		child.queue_free()
	_card_uis.clear()

	# 새 카드 추가
	for i in hand.size():
		var card_ui: PanelContainer = CardUIScene.instantiate()
		add_child(card_ui)
		card_ui.setup(hand[i], i)
		card_ui.card_clicked.connect(_on_card_clicked)
		card_ui.set_affordable(hand[i].mana_cost <= int(_current_mana))
		_card_uis.append(card_ui)


func update_mana(current_mana: float) -> void:
	_current_mana = current_mana
	for card_ui in _card_uis:
		if is_instance_valid(card_ui) and card_ui.card_data:
			card_ui.set_affordable(card_ui.card_data.mana_cost <= int(current_mana))


func _on_card_clicked(card_index: int) -> void:
	card_selected.emit(card_index)
