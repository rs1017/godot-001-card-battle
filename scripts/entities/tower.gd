extends StaticBody3D
## 타워 엔티티
## 적 미니언을 자동 공격하며, 파괴 시 게임 종료를 트리거합니다.

enum Team { PLAYER, ENEMY }

signal tower_destroyed(tower: StaticBody3D)

@export var team: Team = Team.PLAYER
@export var tower_damage: int = 30
@export var model_path: String = ""

@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: HealthBar3D = $HealthBar3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var model_container: Node3D = $ModelContainer
static var _failed_model_paths: Dictionary = {}


func _ready() -> void:
	# 충돌 레이어 설정 (Layer N = 2^(N-1))
	# Layer 4: PlayerTower=8, Layer 5: EnemyTower=16
	# Layer 2: PlayerMinion=2, Layer 3: EnemyMinion=4
	if team == Team.PLAYER:
		collision_layer = 8    # Layer 4: PlayerTower
		_setup_area_layers(detection_area, 0, 4)  # detect EnemyMinion (Layer 3)
	else:
		collision_layer = 16   # Layer 5: EnemyTower
		_setup_area_layers(detection_area, 0, 2)  # detect PlayerMinion (Layer 2)

	# 체력바 설정
	health_bar.setup(health_component)

	# 공격 타이머 연결
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

	# 사망 연결
	health_component.died.connect(_on_died)

	# 모델 로드
	_load_model()


func _load_model() -> void:
	if model_path.is_empty():
		_create_fallback_model()
		return
	if _failed_model_paths.has(model_path):
		_create_fallback_model()
		return
	if not ResourceLoader.exists(model_path):
		push_warning("[Tower] Model not found: %s" % model_path)
		_failed_model_paths[model_path] = true
		# 폴백: 간단한 박스 메시 생성
		_create_fallback_model()
		return
	var model_instance: Node3D = _load_model_scene(model_path)
	if model_instance:
		model_instance.scale = Vector3(1.5, 1.5, 1.5)
		model_container.add_child(model_instance)
	else:
		_failed_model_paths[model_path] = true
		_create_fallback_model()


func _load_model_scene(path: String) -> Node3D:
	var scene: PackedScene = load(path) as PackedScene
	if scene:
		return scene.instantiate()
	if path.ends_with(".glb") or path.ends_with(".gltf"):
		var doc: GLTFDocument = GLTFDocument.new()
		var state: GLTFState = GLTFState.new()
		if doc.append_from_file(path, state) == OK:
			return doc.generate_scene(state) as Node3D
	return null


func _create_fallback_model() -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2, 4, 2)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(0, 2, 0)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if team == Team.PLAYER:
		mat.albedo_color = Color(0.3, 0.4, 0.8)
	else:
		mat.albedo_color = Color(0.8, 0.3, 0.3)
	mesh_instance.material_override = mat
	model_container.add_child(mesh_instance)


func _setup_area_layers(area: Area3D, layer: int, mask: int) -> void:
	area.collision_layer = layer
	area.collision_mask = mask


func _on_attack_timer_timeout() -> void:
	if health_component.is_dead:
		return

	var target: Node = _find_closest_enemy()
	if target:
		var target_health: HealthComponent = target.get_node_or_null("HealthComponent")
		if target_health:
			target_health.take_damage(tower_damage, self)


func _find_closest_enemy() -> Node:
	var bodies: Array[Node3D] = detection_area.get_overlapping_bodies()
	var closest: Node = null
	var closest_dist: float = INF

	for body in bodies:
		if body is CharacterBody3D and body.has_node("HealthComponent"):
			var h: HealthComponent = body.get_node("HealthComponent")
			if not h.is_dead:
				var dist: float = global_position.distance_to(body.global_position)
				if dist < closest_dist:
					closest_dist = dist
					closest = body

	return closest


func _on_died() -> void:
	tower_destroyed.emit(self)
	EventBus.tower_destroyed.emit(self)
