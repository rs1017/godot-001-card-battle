extends Node
## 트리거 서비스

var _listeners: Dictionary = {}


func register_listener(trigger_id: String, callback: Callable) -> void:
	if trigger_id.is_empty() or not callback.is_valid():
		return
	if not _listeners.has(trigger_id):
		_listeners[trigger_id] = []
	var bucket: Array = _listeners[trigger_id]
	bucket.append(callback)
	_listeners[trigger_id] = bucket


func unregister_listener(trigger_id: String, callback: Callable) -> void:
	if not _listeners.has(trigger_id):
		return
	var bucket: Array = _listeners[trigger_id]
	for i in range(bucket.size() - 1, -1, -1):
		if bucket[i] == callback:
			bucket.remove_at(i)
	_listeners[trigger_id] = bucket


func fire(trigger_id: String, payload: Dictionary = {}) -> void:
	if trigger_id.is_empty():
		return
	EventBus.trigger_fired.emit(trigger_id, payload)
	if not _listeners.has(trigger_id):
		return
	for callback in _listeners[trigger_id]:
		if callback is Callable and callback.is_valid():
			callback.call(payload)
