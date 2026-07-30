class_name VehiclePickupContact
extends RefCounted

## Pure swept-circle contact test. Collection effects, activation, spawn, and
## reward budgets remain in VehicleRun and reward owners.

const EPSILON := 0.0001


static func should_collect(
	active: bool,
	motion_start: Vector2,
	motion_end: Vector2,
	player_radius: float,
	pickup_position: Vector2,
	pickup_radius: float
) -> bool:
	if not active:
		return false
	return swept_circle_overlap(
		motion_start,
		motion_end,
		player_radius,
		pickup_position,
		pickup_radius
	)


static func swept_circle_overlap(
	motion_start: Vector2,
	motion_end: Vector2,
	player_radius: float,
	pickup_position: Vector2,
	pickup_radius: float
) -> bool:
	var combined_radius := maxf(0.0, player_radius) + maxf(0.0, pickup_radius)
	var motion := motion_end - motion_start
	var length_squared := motion.length_squared()
	var closest := motion_start
	if length_squared > EPSILON:
		var progress := clampf(
			(pickup_position - motion_start).dot(motion) / length_squared,
			0.0,
			1.0
		)
		closest = motion_start + motion * progress
	return (
		closest.distance_squared_to(pickup_position)
		<= combined_radius * combined_radius + EPSILON
	)
