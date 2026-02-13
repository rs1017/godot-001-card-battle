extends Node3D
## 레인 매니저
## 2개 레인의 웨이포인트를 관리합니다.

const LANE_LEFT: int = 0
const LANE_RIGHT: int = 1

@onready var left_lane: Node3D = $LeftLane
@onready var right_lane: Node3D = $RightLane


func get_waypoints(lane_index: int) -> Array[Vector3]:
	var lane_node: Node3D = left_lane if lane_index == LANE_LEFT else right_lane
	var waypoints: Array[Vector3] = []

	for child in lane_node.get_children():
		if child is Marker3D:
			waypoints.append(child.global_position)

	return waypoints


func get_spawn_position(lane_index: int, is_player: bool) -> Vector3:
	var waypoints: Array[Vector3] = get_waypoints(lane_index)
	if waypoints.is_empty():
		return Vector3.ZERO

	if is_player:
		return waypoints[0]
	else:
		return waypoints[-1]
