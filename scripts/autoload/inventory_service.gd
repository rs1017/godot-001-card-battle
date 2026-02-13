extends Node
## 카드/아이템 인벤토리 서비스

var _card_inventory: Dictionary = {}
var _item_inventory: Dictionary = {}


func add_card(card_id: String, amount: int = 1) -> int:
	if card_id.is_empty() or amount <= 0:
		return int(_card_inventory.get(card_id, 0))
	var next_value: int = int(_card_inventory.get(card_id, 0)) + amount
	_card_inventory[card_id] = next_value
	EventBus.inventory_card_changed.emit(card_id, amount, next_value)
	LogService.add("INFO", "inventory", "card added", {"card_id": card_id, "amount": amount, "next": next_value})
	return next_value


func remove_card(card_id: String, amount: int = 1) -> bool:
	if card_id.is_empty() or amount <= 0:
		return false
	var current: int = int(_card_inventory.get(card_id, 0))
	if current < amount:
		LogService.add("WARN", "inventory", "card remove rejected", {"card_id": card_id, "amount": amount, "current": current})
		return false
	var next_value: int = current - amount
	_card_inventory[card_id] = next_value
	EventBus.inventory_card_changed.emit(card_id, -amount, next_value)
	return true


func grant_item(item_id: String, amount: int = 1, reason: String = "") -> int:
	if item_id.is_empty() or amount <= 0:
		return int(_item_inventory.get(item_id, 0))
	var next_value: int = int(_item_inventory.get(item_id, 0)) + amount
	_item_inventory[item_id] = next_value
	EventBus.item_granted.emit(item_id, amount, reason)
	LogService.add("INFO", "inventory", "item granted", {"item_id": item_id, "amount": amount, "reason": reason})
	return next_value


func consume_item(item_id: String, amount: int = 1, reason: String = "") -> bool:
	if item_id.is_empty() or amount <= 0:
		return false
	var current: int = int(_item_inventory.get(item_id, 0))
	if current < amount:
		LogService.add("WARN", "inventory", "item consume rejected", {"item_id": item_id, "amount": amount, "current": current})
		return false
	_item_inventory[item_id] = current - amount
	LogService.add("INFO", "inventory", "item consumed", {"item_id": item_id, "amount": amount, "reason": reason})
	return true


func get_card_count(card_id: String) -> int:
	return int(_card_inventory.get(card_id, 0))


func get_item_count(item_id: String) -> int:
	return int(_item_inventory.get(item_id, 0))


func get_card_snapshot() -> Dictionary:
	return _card_inventory.duplicate(true)


func get_item_snapshot() -> Dictionary:
	return _item_inventory.duplicate(true)
