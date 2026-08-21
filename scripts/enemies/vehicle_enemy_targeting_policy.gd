class_name VehicleEnemyTargetingPolicy
extends RefCounted

## Pure, bounded prediction for ordinary-enemy movement and attack commitment.
## It never owns an actor, queries world geometry, or changes a committed target.

const MIN_TARGET_SPEED := 80.0
const MovementPolicy = preload(
	"res://scripts/enemies/vehicle_enemy_movement_policy.gd"
)

const MOVEMENT_MAX_SECONDS := {
	MovementPolicy.PURSUIT:1.20,
	MovementPolicy.STANDOFF:0.85,
	MovementPolicy.ESCORT:0.60,
	MovementPolicy.SUPPORT:0.60,
}
const MOVEMENT_MAX_DISTANCE := {
	MovementPolicy.PURSUIT:280.0,
	MovementPolicy.STANDOFF:200.0,
	MovementPolicy.ESCORT:140.0,
	MovementPolicy.SUPPORT:140.0,
}
const ATTACK_MAX_LEAD_DISTANCE := {
	&"ordinary_edge_01":260.0,
	&"ordinary_lane_01":260.0,
	&"ordinary_gap_01":260.0,
	&"ordinary_fixed_ranged_01":260.0,
	&"ordinary_growth_01":320.0,
	&"ordinary_shield_01":260.0,
	&"ordinary_pulse_01":260.0,
	&"ordinary_fixed_ranged_02":260.0,
	&"ordinary_pull_01":260.0,
	&"ordinary_fixed_beam_01":220.0,
}


static func movement_focus(
	_movement_family: StringName,
	_origin: Vector2,
	pressure_focus: Vector2,
	_target_velocity: Vector2,
	_movement_speed: float
) -> Vector2:
	# Movement follows the current pack objective. Prediction remains attack-owned,
	# which avoids every member chasing a different future player position.
	return pressure_focus


static func attack_target(
	role: StringName,
	origin: Vector2,
	pressure_focus: Vector2,
	target_velocity: Vector2,
	startup_seconds: float,
	attack_speed: float
) -> Vector2:
	var maximum_distance := float(ATTACK_MAX_LEAD_DISTANCE.get(role, 0.0))
	if (
		maximum_distance <= 0.0
		or target_velocity.length() < MIN_TARGET_SPEED
	):
		return pressure_focus
	var startup := maxf(0.0, startup_seconds)
	var target_after_startup := pressure_focus + target_velocity * startup
	var travel_seconds := _intercept_seconds(
		target_after_startup - origin,
		target_velocity,
		maxf(0.0, attack_speed)
	)
	var predicted := target_after_startup + target_velocity * travel_seconds
	return pressure_focus + (predicted - pressure_focus).limit_length(maximum_distance)


static func _intercept_seconds(
	relative_position: Vector2,
	target_velocity: Vector2,
	attack_speed: float
) -> float:
	if attack_speed <= 0.001:
		return 0.0
	var a := target_velocity.length_squared() - attack_speed * attack_speed
	var b := 2.0 * relative_position.dot(target_velocity)
	var c := relative_position.length_squared()
	if absf(a) <= 0.001:
		if absf(b) <= 0.001:
			return 0.0
		return maxf(0.0, -c / b)
	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return 0.0
	var root := sqrt(discriminant)
	var first := (-b - root) / (2.0 * a)
	var second := (-b + root) / (2.0 * a)
	var result := INF
	if first >= 0.0:
		result = first
	if second >= 0.0:
		result = minf(result, second)
	return 0.0 if result == INF else result
