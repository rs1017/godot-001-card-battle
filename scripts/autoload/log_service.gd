extends Node
## 시스템 공통 로그 서비스

const MAX_ENTRIES: int = 500

var _entries: Array[Dictionary] = []


func add(level: String, category: String, message: String, payload: Dictionary = {}) -> void:
	var entry: Dictionary = {
		"timestamp": Time.get_unix_time_from_system(),
		"level": level,
		"category": category,
		"message": message,
		"payload": payload.duplicate(true),
	}
	_entries.append(entry)
	if _entries.size() > MAX_ENTRIES:
		_entries.pop_front()
	if get_node_or_null("/root/EventBus"):
		EventBus.system_log_added.emit(level, category, message, int(entry["timestamp"]))


func get_recent(limit: int = 50) -> Array[Dictionary]:
	if limit <= 0:
		return []
	var start: int = maxi(0, _entries.size() - limit)
	return _entries.slice(start, _entries.size())


func clear() -> void:
	_entries.clear()


func get_persistence_state() -> Dictionary:
	return {
		"entries": _entries.duplicate(true),
	}


func apply_persistence_state(state: Dictionary) -> void:
	_entries = state.get("entries", []).duplicate(true)
