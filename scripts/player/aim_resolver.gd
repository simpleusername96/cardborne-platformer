class_name AimResolver
extends RefCounted

const STICK_DEADZONE := 0.25

var last_non_zero_aim := Vector2.RIGHT


func resolve(actor_position: Vector2, mouse_world: Vector2, stick_aim: Vector2) -> Vector2:
	var requested := stick_aim
	if requested.length() < STICK_DEADZONE:
		requested = mouse_world - actor_position
	if requested.length_squared() > 0.0001:
		last_non_zero_aim = requested.normalized()
	return last_non_zero_aim
