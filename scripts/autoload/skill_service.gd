extends Node
## 스킬 시스템(기본)

var _skill_defs: Dictionary = {
	"fireball": {"mana_cost": 3.0, "cooldown": 4.0, "trigger": "on_skill_fireball"},
	"heal": {"mana_cost": 2.0, "cooldown": 5.0, "trigger": "on_skill_heal"},
}
var _caster_mana: Dictionary = {}
var _cooldown_until: Dictionary = {}


func set_caster_mana(caster_id: String, mana: float) -> void:
	if caster_id.is_empty():
		return
	_caster_mana[caster_id] = mana


func get_caster_mana(caster_id: String) -> float:
	return float(_caster_mana.get(caster_id, 0.0))


func request_cast(caster_id: String, skill_id: String, target_id: String = "") -> bool:
	EventBus.skill_cast_requested.emit(caster_id, skill_id, target_id)
	if caster_id.is_empty() or not _skill_defs.has(skill_id):
		EventBus.skill_cast_result.emit(false, skill_id, "E_SKILL_INVALID")
		return false
	var now: float = Time.get_unix_time_from_system()
	var cd_key: String = "%s:%s" % [caster_id, skill_id]
	if now < float(_cooldown_until.get(cd_key, 0.0)):
		EventBus.skill_cast_result.emit(false, skill_id, "E_SKILL_COOLDOWN")
		return false
	var spec: Dictionary = _skill_defs[skill_id]
	var mana_cost: float = float(spec["mana_cost"])
	var mana_now: float = get_caster_mana(caster_id)
	if mana_now < mana_cost:
		EventBus.skill_cast_result.emit(false, skill_id, "E_SKILL_NO_MANA")
		return false
	_caster_mana[caster_id] = mana_now - mana_cost
	_cooldown_until[cd_key] = now + float(spec["cooldown"])
	TriggerService.fire(String(spec["trigger"]), {"caster_id": caster_id, "skill_id": skill_id, "target_id": target_id})
	EventBus.skill_cast_result.emit(true, skill_id, "OK")
	return true


func get_persistence_state() -> Dictionary:
	return {
		"caster_mana": _caster_mana.duplicate(true),
		"cooldown_until": _cooldown_until.duplicate(true),
	}


func apply_persistence_state(state: Dictionary) -> void:
	_caster_mana = state.get("caster_mana", {}).duplicate(true)
	_cooldown_until = state.get("cooldown_until", {}).duplicate(true)
