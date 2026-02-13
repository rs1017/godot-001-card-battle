extends Node3D
## 데미지 넘버 팝업
## 3D 공간에서 위로 떠오르며 사라지는 숫자를 표시합니다.

var _label: Label3D
var _velocity: Vector3 = Vector3(0, 2, 0)
var _lifetime: float = 0.0
const MAX_LIFETIME: float = 0.8


static func create(parent: Node3D, damage: int, pos: Vector3) -> void:
	var instance: Node3D = Node3D.new()
	instance.set_script(load("res://scripts/components/damage_number.gd"))
	parent.add_child(instance)
	instance.global_position = pos + Vector3(randf_range(-0.3, 0.3), 2.0, 0)
	instance._setup(damage)


func _setup(damage: int) -> void:
	_label = Label3D.new()
	_label.text = str(damage)
	_label.font_size = 48
	_label.modulate = Color(1.0, 0.3, 0.2)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.pixel_size = 0.01
	add_child(_label)


func _process(delta: float) -> void:
	_lifetime += delta
	position += _velocity * delta
	_velocity.y *= 0.95  # 감속

	# 페이드 아웃
	var alpha: float = 1.0 - (_lifetime / MAX_LIFETIME)
	if _label:
		_label.modulate.a = maxf(alpha, 0.0)

	if _lifetime >= MAX_LIFETIME:
		queue_free()
