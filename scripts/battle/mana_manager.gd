extends Node
## 마나 관리 시스템
## 시간에 따라 마나 자동 리젠, 카드 사용 시 소비

signal mana_changed(current: float, max_mana: float)

const MAX_MANA: float = 10.0
const START_MANA: float = 5.0
const BASE_REGEN_RATE: float = 0.33
const MAX_REGEN_RATE: float = 1.0
const REGEN_ACCEL_TIME: float = 120.0  # 2분에 걸쳐 최대 리젠 도달

var current_mana: float = START_MANA
var _elapsed_time: float = 0.0


func _ready() -> void:
	current_mana = START_MANA
	mana_changed.emit(current_mana, MAX_MANA)


func _process(delta: float) -> void:
	_elapsed_time += delta

	# 시간에 따른 가속 리젠
	var regen_rate: float = lerpf(BASE_REGEN_RATE, MAX_REGEN_RATE, minf(_elapsed_time / REGEN_ACCEL_TIME, 1.0))
	current_mana = minf(current_mana + regen_rate * delta, MAX_MANA)
	mana_changed.emit(current_mana, MAX_MANA)


func can_afford(cost: int) -> bool:
	return current_mana >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	current_mana -= cost
	mana_changed.emit(current_mana, MAX_MANA)
	return true


func get_mana_int() -> int:
	return int(current_mana)


func reset() -> void:
	current_mana = START_MANA
	_elapsed_time = 0.0
	mana_changed.emit(current_mana, MAX_MANA)
