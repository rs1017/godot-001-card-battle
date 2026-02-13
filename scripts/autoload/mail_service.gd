extends Node
## 우편 시스템

var _mailbox: Dictionary = {}


func send_mail(user_id: String, title: String, body: String, attachments: Dictionary = {}) -> String:
	if user_id.is_empty() or title.is_empty():
		return ""
	if not _mailbox.has(user_id):
		_mailbox[user_id] = []
	var mail_id: String = "mail_%d_%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	var mail: Dictionary = {
		"mail_id": mail_id,
		"title": title,
		"body": body,
		"attachments": attachments.duplicate(true),
		"claimed": false,
	}
	(_mailbox[user_id] as Array).append(mail)
	EventBus.mail_received.emit(mail_id, title)
	return mail_id


func get_mailbox(user_id: String = "") -> Array:
	var key: String = user_id
	if key.is_empty():
		key = AuthService.get_active_user_id()
	if key.is_empty() or not _mailbox.has(key):
		return []
	return (_mailbox[key] as Array).duplicate(true)


func claim_mail(mail_id: String) -> bool:
	var user_id: String = AuthService.get_active_user_id()
	if user_id.is_empty() or mail_id.is_empty() or not _mailbox.has(user_id):
		return false
	var mails: Array = _mailbox[user_id]
	for i in mails.size():
		var mail: Dictionary = mails[i]
		if String(mail.get("mail_id", "")) != mail_id:
			continue
		if bool(mail.get("claimed", false)):
			return false
		var attachments: Dictionary = mail.get("attachments", {})
		for item_id: String in attachments.keys():
			InventoryService.grant_item(item_id, int(attachments[item_id]), "mail_claim")
		mail["claimed"] = true
		mails[i] = mail
		_mailbox[user_id] = mails
		EventBus.mail_claimed.emit(mail_id, attachments)
		return true
	return false


func get_persistence_state() -> Dictionary:
	return {
		"mailbox": _mailbox.duplicate(true),
	}


func apply_persistence_state(state: Dictionary) -> void:
	_mailbox = state.get("mailbox", {}).duplicate(true)
