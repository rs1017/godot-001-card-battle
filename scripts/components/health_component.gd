class_name HealthComponent extends Node
## 체력 관리 컴포넌트

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health: int = 100
@export var current_health: int = 100:
	set(value):
		var old_health: int = current_health
		current_health = clampi(value, 0, max_health)
		if current_health != old_health:
			health_changed.emit(current_health, max_health)
			if current_health <= 0 and old_health > 0:
				died.emit()

var is_invincible: bool = false
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health


@export var show_damage_numbers: bool = true


func take_damage(amount: int, source: Node = null) -> void:
	if is_invincible or is_dead:
		return
	current_health -= amount
	damage_taken.emit(amount, source)

	# 데미지 넘버 표시
	if show_damage_numbers:
		var owner_node: Node = get_parent()
		if owner_node is Node3D:
			var DamageNumber = load("res://scripts/components/damage_number.gd")
			if DamageNumber:
				DamageNumber.create(owner_node, amount, owner_node.global_position)

	if current_health <= 0:
		is_dead = true


func heal(amount: int) -> void:
	if is_dead:
		return
	var old_health: int = current_health
	current_health += amount
	var actual_heal: int = current_health - old_health
	if actual_heal > 0:
		healed.emit(actual_heal)


func get_health_ratio() -> float:
	return float(current_health) / float(max_health) if max_health > 0 else 0.0


func is_alive() -> bool:
	return not is_dead
