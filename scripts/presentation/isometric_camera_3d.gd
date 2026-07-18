class_name IsometricCameraRig3D
extends Node3D

const DEFAULT_LOCAL_OFFSET := Vector3(13.0, 16.0, 13.0)

@export_node_path("Node3D") var target_path := NodePath("../Traveler")
@export var follow_speed := 8.0
@export var center_limit := Vector2(3.5, 3.5)
@export var look_height := 0.8

var room_bounds := Rect2(Vector2(-3.5, -3.5), Vector2(7.0, 7.0))

@onready var camera: Camera3D = $Camera3D
@onready var follow_target: Node3D = get_node(target_path)


func _ready() -> void:
	global_position = _desired_center()
	camera.position = DEFAULT_LOCAL_OFFSET
	camera.look_at(global_position + Vector3.UP * look_height, Vector3.UP)


func _process(delta: float) -> void:
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(_desired_center(), weight)


func set_room_bounds(bounds: Rect2) -> void:
	room_bounds = bounds


func snap_to_target() -> void:
	global_position = _desired_center()


func _desired_center() -> Vector3:
	return Vector3(
		clampf(follow_target.global_position.x, room_bounds.position.x, room_bounds.end.x),
		0.0,
		clampf(follow_target.global_position.z, room_bounds.position.y, room_bounds.end.y),
	)
