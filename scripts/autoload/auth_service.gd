extends Node
## 로그인/세션 서비스

const GUEST_PASSWORD: String = "guest"

var _active_user_id: String = ""
var _profiles: Dictionary = {}


func login(user_id: String, password: String) -> bool:
	if user_id.is_empty() or password.is_empty():
		LogService.add("WARN", "auth", "login rejected: empty credentials")
		EventBus.auth_login_result.emit(false, user_id, "E_AUTH_EMPTY")
		return false
	if password != GUEST_PASSWORD:
		LogService.add("WARN", "auth", "login rejected: wrong password", {"user_id": user_id})
		EventBus.auth_login_result.emit(false, user_id, "E_AUTH_INVALID")
		return false
	_active_user_id = user_id
	if not _profiles.has(user_id):
		_profiles[user_id] = {
			"display_name": user_id,
			"wallet": {
				"gold": 1000,
				"gem": 100,
			},
		}
	LogService.add("INFO", "auth", "login success", {"user_id": user_id})
	EventBus.auth_login_result.emit(true, user_id, "OK")
	return true


func logout() -> void:
	if _active_user_id.is_empty():
		return
	LogService.add("INFO", "auth", "logout", {"user_id": _active_user_id})
	_active_user_id = ""


func is_logged_in() -> bool:
	return not _active_user_id.is_empty()


func get_active_user_id() -> String:
	return _active_user_id


func get_wallet(currency: String) -> int:
	if not is_logged_in():
		return 0
	return int(_profiles[_active_user_id]["wallet"].get(currency, 0))


func try_spend(currency: String, amount: int) -> bool:
	if amount <= 0 or not is_logged_in():
		return false
	var wallet: Dictionary = _profiles[_active_user_id]["wallet"]
	var current: int = int(wallet.get(currency, 0))
	if current < amount:
		return false
	wallet[currency] = current - amount
	return true


func grant_currency(currency: String, amount: int) -> void:
	if amount <= 0 or not is_logged_in():
		return
	var wallet: Dictionary = _profiles[_active_user_id]["wallet"]
	wallet[currency] = int(wallet.get(currency, 0)) + amount
