class_name PlayerMotor
extends RefCounted

const MAX_SPEED := 220.0
const ACCELERATION := 1600.0
const BRAKING := 2000.0
const DASH_SPEED := 520.0
const DASH_DURATION := 0.18
const DASH_INVULNERABILITY := 0.10
const DASH_RECOVERY := 0.12
const DASH_REUSE := 0.55

var last_facing := Vector2.RIGHT
var dash_direction := Vector2.RIGHT
var dash_elapsed := 0.0
var recovery_remaining := 0.0
var reuse_remaining := 0.0
var is_dashing := false


func tick(body: CharacterBody2D, movement: Vector2, aim: Vector2, dash_pressed: bool, delta: float, actions_locked: bool) -> void:
	reuse_remaining = maxf(0.0, reuse_remaining - delta)
	if aim.length_squared() > 0.0001:
		last_facing = aim.normalized()

	if is_dashing:
		var remaining := maxf(0.0, DASH_DURATION - dash_elapsed)
		var movement_fraction := minf(delta, remaining) / delta if delta > 0.0 else 0.0
		body.velocity = dash_direction * DASH_SPEED * movement_fraction
		body.move_and_slide()
		dash_elapsed += delta
		if dash_elapsed >= DASH_DURATION:
			is_dashing = false
			recovery_remaining = DASH_RECOVERY
			body.velocity = Vector2.ZERO
		return

	if recovery_remaining > 0.0:
		recovery_remaining = maxf(0.0, recovery_remaining - delta)
		body.velocity = body.velocity.move_toward(Vector2.ZERO, BRAKING * delta)
		body.move_and_slide()
		return

	if dash_pressed and reuse_remaining <= 0.0 and not actions_locked:
		dash_direction = _select_dash_direction(movement, aim)
		is_dashing = true
		dash_elapsed = 0.0
		reuse_remaining = DASH_REUSE
		body.velocity = dash_direction * DASH_SPEED
		body.move_and_slide()
		return

	var desired := Vector2.ZERO if actions_locked else normalized_velocity(movement)
	var rate := ACCELERATION if desired.length_squared() > 0.0 else BRAKING
	body.velocity = body.velocity.move_toward(desired, rate * delta)
	body.move_and_slide()


func normalized_velocity(input_direction: Vector2) -> Vector2:
	if input_direction.length_squared() <= 0.0001:
		return Vector2.ZERO
	return input_direction.normalized() * MAX_SPEED


func is_invulnerable() -> bool:
	return is_dashing and dash_elapsed <= DASH_INVULNERABILITY


func can_act() -> bool:
	return not is_dashing and recovery_remaining <= 0.0


func reset() -> void:
	dash_elapsed = 0.0
	recovery_remaining = 0.0
	reuse_remaining = 0.0
	is_dashing = false


func _select_dash_direction(movement: Vector2, aim: Vector2) -> Vector2:
	if movement.length_squared() > 0.0001:
		return movement.normalized()
	if aim.length_squared() > 0.0001:
		return aim.normalized()
	return last_facing
