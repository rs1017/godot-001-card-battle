extends CharacterBody3D
## 미니언 엔티티
## 카드 데이터로 초기화되어 레인을 따라 이동하며 전투합니다.

enum Team { PLAYER, ENEMY }

signal minion_died(minion: CharacterBody3D)

var team: Team = Team.PLAYER
var _card_data: CardData
var _waypoints: Array[Vector3] = []
var _current_waypoint_index: int = 0
var _animation_player: AnimationPlayer

@onready var model_container: Node3D = $ModelContainer
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: HealthBar3D = $HealthBar3D
@onready var aggro_area: Area3D = $AggroArea
@onready var state_machine: StateMachine = $StateMachine


const GRAVITY: float = 20.0
static var _failed_model_paths: Dictionary = {}


func _ready() -> void:
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	# 중력 적용
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		move_and_slide()


func setup(card_data: CardData, p_team: Team, lane_waypoints: Array[Vector3]) -> void:
	_card_data = card_data
	team = p_team
	_waypoints = lane_waypoints
	_current_waypoint_index = 0

	# 체력 설정
	health_component.max_health = card_data.health
	health_component.current_health = card_data.health

	# 체력바 연결
	health_bar.setup(health_component)

	# 충돌 레이어 설정 (Layer N = bit N-1 = 2^(N-1))
	# Layer 2: PlayerMinion=2, Layer 3: EnemyMinion=4
	# Layer 4: PlayerTower=8, Layer 5: EnemyTower=16
	if team == Team.PLAYER:
		collision_layer = 2        # Layer 2: PlayerMinion
		collision_mask = 4 | 1     # Layer 3: EnemyMinion + Environment
		_setup_area_layers(aggro_area, 0, 4 | 16)  # detect EnemyMinion + EnemyTower
	else:
		collision_layer = 4        # Layer 3: EnemyMinion
		collision_mask = 2 | 1     # Layer 2: PlayerMinion + Environment
		_setup_area_layers(aggro_area, 0, 2 | 8)   # detect PlayerMinion + PlayerTower

	# 적 팀이면 웨이포인트 반전 (반대 방향으로 이동)
	if team == Team.ENEMY:
		_waypoints.reverse()

	# 모델 로드
	_load_model()

	# 스테이트 머신 설정 및 시작
	state_machine.setup(self, _animation_player)
	state_machine.start()


func get_card_data() -> CardData:
	return _card_data


func is_dead() -> bool:
	return health_component.is_dead


func _load_model() -> void:
	if not _card_data or _card_data.kaykit_model_path.is_empty():
		_create_fallback_model()
		return

	if _failed_model_paths.has(_card_data.kaykit_model_path):
		_create_fallback_model()
		return

	if not ResourceLoader.exists(_card_data.kaykit_model_path):
		push_error("[Minion] Model not found: %s" % _card_data.kaykit_model_path)
		_failed_model_paths[_card_data.kaykit_model_path] = true
		_create_fallback_model()
		return

	var model_instance: Node3D = _load_model_scene(_card_data.kaykit_model_path)
	if not model_instance:
		push_error("[Minion] Failed to load model: %s" % _card_data.kaykit_model_path)
		_failed_model_paths[_card_data.kaykit_model_path] = true
		_create_fallback_model()
		return

	model_instance.scale = Vector3(0.6, 0.6, 0.6)

	# 적 팀은 플레이어 방향(+Z)을 바라보도록 회전
	if team == Team.ENEMY:
		model_instance.rotation_degrees.y = 180.0

	model_container.add_child(model_instance)

	# AnimationPlayer 찾기
	_animation_player = _find_animation_player(model_instance)
	if not _animation_player:
		# 직접 경로로 시도
		_animation_player = model_instance.get_node_or_null("AnimationPlayer")

	if _animation_player:
		_play_anim_safe(_card_data.anim_idle)
	else:
		push_warning("[Minion] No AnimationPlayer found for %s" % _card_data.card_name)


func _load_model_scene(path: String) -> Node3D:
	if path.ends_with(".glb") or path.ends_with(".gltf"):
		var doc: GLTFDocument = GLTFDocument.new()
		var state: GLTFState = GLTFState.new()
		var abs_path: String = ProjectSettings.globalize_path(path)
		if doc.append_from_file(abs_path, state) == OK:
			return doc.generate_scene(state) as Node3D
	var resource: Resource = load(path)
	if resource is PackedScene:
		return (resource as PackedScene).instantiate()
	if resource is Mesh:
		var mesh_node: MeshInstance3D = MeshInstance3D.new()
		mesh_node.mesh = resource as Mesh
		return mesh_node
	return null


func _create_fallback_model() -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.0
	mesh_instance.mesh = capsule
	mesh_instance.position = Vector3(0, 0.8, 0)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if team == Team.PLAYER:
		mat.albedo_color = Color(0.25, 0.55, 0.95)
	else:
		mat.albedo_color = Color(0.95, 0.35, 0.25)
	mesh_instance.material_override = mat
	model_container.add_child(mesh_instance)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result: AnimationPlayer = _find_animation_player(child)
		if result:
			return result
	return null


func _play_anim_safe(anim_name: String) -> void:
	if _animation_player and _animation_player.has_animation(anim_name):
		_animation_player.play(anim_name)
	elif _animation_player:
		# 폴백: 애니메이션 목록의 첫 번째 재생
		var anims: PackedStringArray = _animation_player.get_animation_list()
		if not anims.is_empty():
			for a in anims:
				if anim_name.to_lower() in a.to_lower():
					_animation_player.play(a)
					return
			push_warning("[Minion] Animation '%s' not found, available: %s" % [anim_name, str(anims)])


func _setup_area_layers(area: Area3D, layer: int, mask: int) -> void:
	area.collision_layer = layer
	area.collision_mask = mask


func move_along_waypoints(_delta: float) -> void:
	if _current_waypoint_index >= _waypoints.size():
		return

	var target_pos: Vector3 = _waypoints[_current_waypoint_index]
	target_pos.y = global_position.y

	var direction: Vector3 = (target_pos - global_position).normalized()
	var distance: float = global_position.distance_to(target_pos)

	if distance < 0.5:
		_current_waypoint_index += 1
		if _current_waypoint_index >= _waypoints.size():
			return
		target_pos = _waypoints[_current_waypoint_index]
		target_pos.y = global_position.y
		direction = (target_pos - global_position).normalized()

	# 이동 방향 바라보기
	var look_pos: Vector3 = global_position + direction
	look_pos.y = global_position.y
	if look_pos.distance_to(global_position) > 0.01:
		look_at(look_pos)

	# 수평 이동 + 중력 보존
	var grav_y: float = velocity.y if not is_on_floor() else 0.0
	velocity = direction * _card_data.move_speed
	velocity.y = grav_y
	move_and_slide()


func find_closest_enemy() -> Node:
	var bodies: Array[Node3D] = aggro_area.get_overlapping_bodies()
	var closest: Node = null
	var closest_dist: float = INF

	for body in bodies:
		if body == self:
			continue

		# 미니언인지 확인
		if body is CharacterBody3D and body.has_method("is_dead"):
			if body.is_dead():
				continue
			# 다른 팀인지 확인
			if body.has_method("get_card_data") and body.get("team") != null:
				if body.team != team:
					var dist: float = global_position.distance_to(body.global_position)
					if dist < closest_dist:
						closest_dist = dist
						closest = body

		# 타워인지 확인
		elif body is StaticBody3D and body.has_node("HealthComponent"):
			var tower_health: HealthComponent = body.get_node("HealthComponent")
			if not tower_health.is_dead:
				var tower_team = body.get("team")
				# enum 값을 int로 비교 (PLAYER=0, ENEMY=1)
				if tower_team != null and int(tower_team) != int(team):
					var dist: float = global_position.distance_to(body.global_position)
					if dist < closest_dist:
						closest_dist = dist
						closest = body

	return closest


func _on_died() -> void:
	minion_died.emit(self)
	EventBus.minion_killed.emit(self, null)
	state_machine.transition_to("DeathState")
