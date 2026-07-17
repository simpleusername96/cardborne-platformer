class_name Traveler
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal potion_changed(charges: int)
signal action_traced(label: String)
signal dash_started()

@export var max_health := 100

var health := 100
var spawn_position := Vector2.ZERO
var aim_direction := Vector2.RIGHT
var _motor := PlayerMotor.new()

@onready var player_input: PlayerInput = $PlayerInput
@onready var actions: PlayerActionController = $PlayerActionController


func _ready() -> void:
	spawn_position = global_position
	health = max_health
	actions.setup(self)
	actions.action_started.connect(action_traced.emit)
	actions.potion_consumed.connect(potion_changed.emit)
	health_changed.emit(health, max_health)
	potion_changed.emit(actions.potion_charges)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var frame := player_input.sample(global_position)
	aim_direction = frame.aim
	var was_dashing := _motor.is_dashing
	actions.tick(frame, delta, _motor.can_act())
	_motor.tick(self, frame.movement, frame.aim, frame.dash_pressed, delta, actions.actions_lock_movement())
	if not was_dashing and _motor.is_dashing:
		dash_started.emit()
		action_traced.emit("Dash")
	queue_redraw()


func receive_damage(amount: int, source_id: StringName) -> bool:
	if _motor.is_invulnerable():
		action_traced.emit("Dodged %s" % source_id)
		return false
	actions.cancel_committed_action_on_damage()
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	action_traced.emit("-%d · %s" % [amount, source_id])
	if health <= 0:
		reset_training()
	return true


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func reset_training() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	health = max_health
	_motor.reset()
	actions.reset()
	health_changed.emit(health, max_health)
	action_traced.emit("Training reset")


func set_validation_aim(direction: Vector2) -> void:
	player_input.set_validation_aim(direction)


func _draw() -> void:
	draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 22.0, Color(0.02, 0.04, 0.05, 0.48))
	var facing := aim_direction.normalized()
	var side := Vector2(-facing.y, facing.x)
	if _motor.is_dashing:
		draw_set_transform(-_motor.dash_direction * 24.0, 0.0, Vector2(1.0, 2.2))
		draw_circle(Vector2.ZERO, 12.0, Color(0.384, 0.663, 0.71, 0.18))
	var walk_bob := sin(Time.get_ticks_msec() * 0.018) * 1.5 if velocity.length() > 24.0 and not _motor.is_dashing else 0.0
	draw_set_transform(Vector2(0, walk_bob), 0.0, Vector2.ONE)
	var body := PackedVector2Array([
		facing * 21.0 + side * 11.0,
		-facing * 16.0 + side * 14.0,
		-facing * 20.0 - side * 14.0,
		facing * 21.0 - side * 11.0,
	])
	draw_polygon(body, PackedColorArray([Color("263136")]))
	draw_circle(-facing * 5.0, 10.0, Color("f0f1e8"))
	draw_polygon(PackedVector2Array([facing * 24.0 + side * 5.0, facing * 24.0 - side * 5.0, facing * 34.0]), PackedColorArray([Color("d9654f")]))
	var weapon_direction := facing
	if is_instance_valid(actions) and actions.state == PlayerActionController.ActionState.MELEE:
		var duration := 0.38 if actions.combo_step == 1 else 0.46
		var swing := clampf(actions.elapsed / duration, 0.0, 1.0)
		weapon_direction = facing.rotated(lerpf(-1.2, 1.15, swing))
		if actions.activation_fired:
			draw_arc(facing * 10.0, 44.0, facing.angle() - 0.95, facing.angle() + 0.95, 20, Color(0.831, 0.639, 0.247, 0.38), 7.0)
	var weapon_side := Vector2(-weapon_direction.y, weapon_direction.x)
	draw_line(weapon_direction * 8.0 - weapon_side * 12.0, weapon_direction * 34.0 - weapon_side * 12.0, Color("d4a33f"), 5.0)
	draw_circle(weapon_direction * 38.0 - weapon_side * 12.0, 3.5, Color("f0f1e8"))
	if is_instance_valid(actions) and actions.state == PlayerActionController.ActionState.RANGED:
		draw_line(-side * 13.0, facing * 28.0, Color("62a9b5"), 3.0)
	if is_instance_valid(actions) and actions.state == PlayerActionController.ActionState.POTION:
		draw_circle(-side * 20.0, 7.0, Color("d4a33f"))
