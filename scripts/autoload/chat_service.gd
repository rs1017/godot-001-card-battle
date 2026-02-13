extends Node
## 채팅 서비스

const CHANNEL_MAX_MESSAGES: int = 50

var _channels: Dictionary = {
	"global": [],
	"guild": [],
	"party": [],
	"private": [],
}


func send_message(channel_id: String, message: String) -> bool:
	if channel_id.is_empty() or message.strip_edges().is_empty():
		return false
	if not _channels.has(channel_id):
		_channels[channel_id] = []
	var sender_id: String = AuthService.get_active_user_id()
	if sender_id.is_empty():
		sender_id = "guest"
	var timestamp: int = int(Time.get_unix_time_from_system())
	var entry: Dictionary = {
		"sender_id": sender_id,
		"message": message,
		"timestamp": timestamp,
	}
	var bucket: Array = _channels[channel_id]
	bucket.append(entry)
	while bucket.size() > CHANNEL_MAX_MESSAGES:
		bucket.pop_front()
	_channels[channel_id] = bucket
	EventBus.chat_message_sent.emit(channel_id, sender_id, message, timestamp)
	return true


func get_messages(channel_id: String) -> Array:
	if not _channels.has(channel_id):
		return []
	return (_channels[channel_id] as Array).duplicate(true)
