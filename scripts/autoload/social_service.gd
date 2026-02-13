extends Node
## 친구/파티/길드 서비스

const PARTY_MAX_MEMBERS: int = 4
const GUILD_MAX_MEMBERS: int = 30

var _friend_requests: Array[Dictionary] = []
var _friends: Dictionary = {}
var _party: Dictionary = {"party_id": "", "leader": "", "members": []}
var _guild: Dictionary = {"guild_id": "", "leader": "", "members": []}


func send_friend_request(target_user_id: String) -> bool:
	var from_user: String = AuthService.get_active_user_id()
	if from_user.is_empty() or target_user_id.is_empty() or from_user == target_user_id:
		return false
	if is_friend(target_user_id):
		return false
	for req in _friend_requests:
		if req["from"] == from_user and req["to"] == target_user_id:
			return false
	_friend_requests.append({"from": from_user, "to": target_user_id})
	EventBus.friend_request_sent.emit(from_user, target_user_id)
	return true


func accept_friend_request(from_user_id: String) -> bool:
	var me: String = AuthService.get_active_user_id()
	if me.is_empty() or from_user_id.is_empty():
		return false
	var found_idx: int = -1
	for i in _friend_requests.size():
		var req: Dictionary = _friend_requests[i]
		if req["from"] == from_user_id and req["to"] == me:
			found_idx = i
			break
	if found_idx == -1:
		return false
	_friend_requests.remove_at(found_idx)
	_add_friend_pair(me, from_user_id)
	EventBus.friend_status_changed.emit(me, from_user_id, "accepted")
	return true


func is_friend(user_id: String) -> bool:
	var me: String = AuthService.get_active_user_id()
	if me.is_empty():
		return false
	var my_set: Dictionary = _friends.get(me, {})
	return bool(my_set.get(user_id, false))


func create_party() -> String:
	var leader: String = AuthService.get_active_user_id()
	if leader.is_empty():
		return ""
	_party = {
		"party_id": "party_%d" % Time.get_unix_time_from_system(),
		"leader": leader,
		"members": [leader],
	}
	EventBus.party_updated.emit(_party["party_id"], PackedStringArray(_party["members"]))
	return String(_party["party_id"])


func add_party_member(user_id: String) -> bool:
	if _party["party_id"] == "" or user_id.is_empty():
		return false
	var members: Array = _party["members"]
	if members.has(user_id) or members.size() >= PARTY_MAX_MEMBERS:
		return false
	members.append(user_id)
	_party["members"] = members
	EventBus.party_updated.emit(_party["party_id"], PackedStringArray(members))
	return true


func create_guild(guild_id: String) -> bool:
	var leader: String = AuthService.get_active_user_id()
	if leader.is_empty() or guild_id.is_empty():
		return false
	_guild = {
		"guild_id": guild_id,
		"leader": leader,
		"members": [leader],
	}
	EventBus.guild_updated.emit(guild_id, PackedStringArray(_guild["members"]))
	return true


func add_guild_member(user_id: String) -> bool:
	if _guild["guild_id"] == "" or user_id.is_empty():
		return false
	var members: Array = _guild["members"]
	if members.has(user_id) or members.size() >= GUILD_MAX_MEMBERS:
		return false
	members.append(user_id)
	_guild["members"] = members
	EventBus.guild_updated.emit(_guild["guild_id"], PackedStringArray(members))
	return true


func _add_friend_pair(a: String, b: String) -> void:
	if not _friends.has(a):
		_friends[a] = {}
	if not _friends.has(b):
		_friends[b] = {}
	_friends[a][b] = true
	_friends[b][a] = true
