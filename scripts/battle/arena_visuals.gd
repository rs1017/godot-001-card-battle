extends Node3D
## Arena visuals built from KayKit assets with GLTF runtime fallback.

const TILE_PATH: String = "res://assets/kaykit/medieval-hexagon/addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass.gltf"
const ROAD_PATH: String = "res://assets/kaykit/medieval-hexagon/addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/roads/hex_road_A.gltf"
const RIVER_PATH: String = "res://assets/kaykit/medieval-hexagon/addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/rivers/hex_river_crossing_A.gltf"
const BRIDGE_PATH: String = "res://assets/kaykit/medieval-hexagon/addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/neutral/building_bridge_A.gltf"
const BACK_MOUNTAIN_PATH: String = "res://assets/kaykit/medieval-hexagon/addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/nature/mountain_C_grass.gltf"

const TILE_SCALE: Vector3 = Vector3(2.35, 2.35, 2.35)
const BRIDGE_SCALE: Vector3 = Vector3(1.8, 1.8, 1.8)
const MOUNTAIN_SCALE: Vector3 = Vector3(2.8, 2.8, 2.8)
const GRID_X: Array[int] = [-9, -6, -3, 0, 3, 6, 9]
const GRID_Z: Array[int] = [-12, -9, -6, -3, 0, 3, 6, 9, 12]
static var _failed_model_paths: Dictionary = {}


func _ready() -> void:
	_hide_legacy_floor()
	_build_ground()
	_build_river()
	_build_roads()
	_build_bridges()
	_build_backdrop()


func _hide_legacy_floor() -> void:
	var floor_mesh: Node3D = get_node_or_null("../ArenaFloor/FloorMesh")
	if floor_mesh:
		floor_mesh.visible = false


func _build_ground() -> void:
	for z in GRID_Z:
		for x in GRID_X:
			_add_asset(TILE_PATH, Vector3(float(x), -0.02, float(z)), TILE_SCALE)


func _build_river() -> void:
	for x in GRID_X:
		_add_asset(RIVER_PATH, Vector3(float(x), 0.0, 0.0), TILE_SCALE)


func _build_roads() -> void:
	for z in GRID_Z:
		_add_asset(ROAD_PATH, Vector3(-3.0, 0.01, float(z)), TILE_SCALE)
		_add_asset(ROAD_PATH, Vector3(3.0, 0.01, float(z)), TILE_SCALE)


func _build_bridges() -> void:
	_add_asset(BRIDGE_PATH, Vector3(-3.0, 0.02, 0.0), BRIDGE_SCALE)
	_add_asset(BRIDGE_PATH, Vector3(3.0, 0.02, 0.0), BRIDGE_SCALE)


func _build_backdrop() -> void:
	_add_asset(BACK_MOUNTAIN_PATH, Vector3(-7.0, 0.0, -14.5), MOUNTAIN_SCALE, 0.0)
	_add_asset(BACK_MOUNTAIN_PATH, Vector3(7.0, 0.0, 14.5), MOUNTAIN_SCALE, 180.0)


func _add_asset(path: String, position: Vector3, scale_value: Vector3, rot_y_deg: float = 0.0) -> void:
	var node: Node3D = _load_model_scene(path)
	if not node:
		node = _create_fallback_tile(path)
	add_child(node)
	node.position = position
	node.scale = scale_value
	node.rotation_degrees.y = rot_y_deg


func _load_model_scene(path: String) -> Node3D:
	if _failed_model_paths.has(path):
		return null

	if path.ends_with(".gltf") or path.ends_with(".glb"):
		var abs_path: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(abs_path):
			_failed_model_paths[path] = true
			return null
		var doc: GLTFDocument = GLTFDocument.new()
		var state: GLTFState = GLTFState.new()
		if doc.append_from_file(abs_path, state) == OK:
			return doc.generate_scene(state) as Node3D
		_failed_model_paths[path] = true
		return null

	if not ResourceLoader.exists(path):
		_failed_model_paths[path] = true
		return null

	var scene: PackedScene = load(path) as PackedScene
	if scene:
		return scene.instantiate()
	if path.ends_with(".gltf") or path.ends_with(".glb"):
		_failed_model_paths[path] = true
	return null


func _create_fallback_tile(path: String) -> Node3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2.4, 0.12, 2.4)
	mesh_instance.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if path.find("river") >= 0:
		mat.albedo_color = Color(0.18, 0.4, 0.75, 1.0)
	elif path.find("road") >= 0:
		mat.albedo_color = Color(0.45, 0.38, 0.25, 1.0)
	else:
		mat.albedo_color = Color(0.33, 0.56, 0.29, 1.0)
	mesh_instance.material_override = mat
	return mesh_instance
