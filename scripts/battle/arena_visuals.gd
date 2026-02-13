extends Node3D
## Arena visual generator.


func _ready() -> void:
	_create_lane_paths()
	_create_river()
	_create_territory_lines()
	_create_side_walls()


func _create_lane_paths() -> void:
	_create_lane_strip(Vector3(-3, 0.01, 0), Vector3(1.5, 0.05, 22), Color(0.45, 0.4, 0.35, 0.6))
	_create_lane_strip(Vector3(3, 0.01, 0), Vector3(1.5, 0.05, 22), Color(0.45, 0.4, 0.35, 0.6))


func _create_lane_strip(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	add_child(mesh_instance)


func _create_river() -> void:
	var river: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(20, 0.08, 1.5)
	river.mesh = box

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.7, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	river.material_override = mat
	river.position = Vector3(0, 0.02, 0)
	add_child(river)

	_create_bridge(Vector3(-3, 0.05, 0))
	_create_bridge(Vector3(3, 0.05, 0))


func _create_bridge(pos: Vector3) -> void:
	var bridge: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2.0, 0.15, 2.0)
	bridge.mesh = box

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.25)
	bridge.material_override = mat
	bridge.position = pos
	add_child(bridge)


func _create_territory_lines() -> void:
	_create_line(Vector3(0, 0.02, 6), Vector3(20, 0.02, 0.1), Color(0.3, 0.5, 0.9, 0.4))
	_create_line(Vector3(0, 0.02, -6), Vector3(20, 0.02, 0.1), Color(0.9, 0.3, 0.3, 0.4))


func _create_line(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	add_child(mesh_instance)


func _create_side_walls() -> void:
	_create_wall_strip(Vector3(-9, 0.3, 0), Vector3(0.3, 0.6, 24), Color(0.3, 0.3, 0.3, 0.3))
	_create_wall_strip(Vector3(9, 0.3, 0), Vector3(0.3, 0.6, 24), Color(0.3, 0.3, 0.3, 0.3))


func _create_wall_strip(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	add_child(mesh_instance)
