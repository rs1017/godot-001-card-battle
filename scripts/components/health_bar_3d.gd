class_name HealthBar3D extends Node3D
## 3D 빌보드 체력바
## SubViewport + Sprite3D로 구현합니다.

@onready var sub_viewport: SubViewport = $SubViewport
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar
@onready var hp_label: Label = $SubViewport/ProgressBar/Label

var _health_component: HealthComponent


func _ready() -> void:
	sprite_3d.texture = sub_viewport.get_texture()


func setup(health_component: HealthComponent) -> void:
	_health_component = health_component
	_health_component.health_changed.connect(_on_health_changed)
	progress_bar.max_value = _health_component.max_health
	progress_bar.value = _health_component.current_health
	_update_label()


func _on_health_changed(current: int, max_hp: int) -> void:
	progress_bar.max_value = max_hp
	progress_bar.value = current
	_update_label()

	if current <= 0:
		hide()


func _update_label() -> void:
	if hp_label and _health_component:
		hp_label.text = "%d/%d" % [_health_component.current_health, _health_component.max_health]
