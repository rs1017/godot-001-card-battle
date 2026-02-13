extends Node
## 메타 서비스 상태 영속화

const SAVE_PATH: String = "user://meta_state_v1.json"


func save_all() -> bool:
	var payload: Dictionary = {
		"version": 1,
		"saved_unix": int(Time.get_unix_time_from_system()),
		"auth": AuthService.get_persistence_state(),
		"inventory": InventoryService.get_persistence_state(),
		"chat": ChatService.get_persistence_state(),
		"social": SocialService.get_persistence_state(),
		"skill": SkillService.get_persistence_state(),
		"mail": MailService.get_persistence_state(),
		"log": LogService.get_persistence_state(),
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		LogService.add("ERROR", "persistence", "save failed: cannot open file", {"path": SAVE_PATH})
		return false
	file.store_string(JSON.stringify(payload, "\t", false))
	LogService.add("INFO", "persistence", "save success", {"path": SAVE_PATH})
	return true


func load_all() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		LogService.add("WARN", "persistence", "load skipped: file missing", {"path": SAVE_PATH})
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		LogService.add("ERROR", "persistence", "load failed: cannot open file", {"path": SAVE_PATH})
		return false
	var raw: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		LogService.add("ERROR", "persistence", "load failed: invalid json")
		return false
	var data: Dictionary = parsed
	AuthService.apply_persistence_state(data.get("auth", {}))
	InventoryService.apply_persistence_state(data.get("inventory", {}))
	ChatService.apply_persistence_state(data.get("chat", {}))
	SocialService.apply_persistence_state(data.get("social", {}))
	SkillService.apply_persistence_state(data.get("skill", {}))
	MailService.apply_persistence_state(data.get("mail", {}))
	LogService.apply_persistence_state(data.get("log", {}))
	LogService.add("INFO", "persistence", "load success", {"path": SAVE_PATH})
	return true


func get_save_path() -> String:
	return SAVE_PATH
