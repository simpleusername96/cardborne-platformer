class_name PlayerInput
extends Node

signal command_frame_ready(frame: PlayerCommandFrame)

var _aim_resolver := AimResolver.new()
var _override_aim := Vector2.ZERO


func sample(actor_position: Vector2) -> PlayerCommandFrame:
	var frame := PlayerCommandFrame.new()
	frame.movement = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var stick_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var mouse_world := _mouse_world_position()
	if _override_aim.length_squared() > 0.0001:
		stick_aim = _override_aim
		mouse_world = actor_position + _override_aim
	frame.aim = _aim_resolver.resolve(actor_position, mouse_world, stick_aim)
	frame.melee_pressed = Input.is_action_just_pressed("melee")
	frame.ranged_pressed = Input.is_action_just_pressed("ranged")
	frame.dash_pressed = Input.is_action_just_pressed("dash")
	frame.interact_pressed = Input.is_action_just_pressed("interact")
	frame.potion_pressed = Input.is_action_just_pressed("potion")
	command_frame_ready.emit(frame)
	return frame


func set_validation_aim(direction: Vector2) -> void:
	_override_aim = direction.normalized() if direction.length_squared() > 0.0001 else Vector2.ZERO


func _mouse_world_position() -> Vector2:
	var viewport_position := get_viewport().get_mouse_position()
	return get_viewport().get_canvas_transform().affine_inverse() * viewport_position
