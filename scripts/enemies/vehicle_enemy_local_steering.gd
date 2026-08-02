class_name VehicleEnemyLocalSteering
extends RefCounted

## Resolves actual ordinary-enemy body penetration without maintaining spacing.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SEARCH_RADIUS := 120.0
const MAX_OVERLAP_NEIGHBORS := 8
const ROLE_WEIGHT := 0.55
const SEPARATION_WEIGHT := 0.45

var _query_buffer: Array[EnemyState] = []


func adjusted_velocity(
	enemy: EnemyState,
	role_velocity: Vector2,
	spatial_grid,
	live_enemies: Array[EnemyState]
) -> Vector2:
	if role_velocity.length_squared() <= 0.001:
		return role_velocity
	spatial_grid.query_nearest_overlaps_into(
		enemy,
		SEARCH_RADIUS,
		live_enemies,
		MAX_OVERLAP_NEIGHBORS,
		_query_buffer
	)
	if _query_buffer.is_empty():
		return role_velocity
	var separation := Vector2.ZERO
	var strongest_enemy: EnemyState = null
	var strongest_penetration := -1.0
	var strongest_direction := Vector2.ZERO
	for candidate in _query_buffer:
		var offset := enemy.pos - candidate.pos
		var distance_squared := offset.length_squared()
		var combined_radius := enemy.radius + candidate.radius
		var distance := sqrt(distance_squared)
		var penetration := combined_radius - distance
		var direction := _separation_direction(enemy, candidate, offset, distance)
		separation += direction * penetration
		if (
			penetration > strongest_penetration
			or (
				is_equal_approx(penetration, strongest_penetration)
				and (
					strongest_enemy == null
					or candidate.id < strongest_enemy.id
				)
			)
		):
			strongest_enemy = candidate
			strongest_penetration = penetration
			strongest_direction = direction
	if separation.length_squared() <= 0.0001:
		separation = strongest_direction
	var separation_velocity := separation.normalized() * role_velocity.length()
	return (
		role_velocity * ROLE_WEIGHT
		+ separation_velocity * SEPARATION_WEIGHT
	).limit_length(role_velocity.length())
func _separation_direction(
	enemy: EnemyState,
	candidate: EnemyState,
	offset: Vector2,
	distance: float
) -> Vector2:
	if distance > 0.0001:
		return offset / distance
	var first_id := String(enemy.id)
	var second_id := String(candidate.id)
	var ordered := first_id + ":" + second_id if first_id < second_id else second_id + ":" + first_id
	var angle := float(wrapi(hash(ordered), 0, 4096)) / 4096.0 * TAU
	var direction := Vector2.RIGHT.rotated(angle)
	return direction if first_id < second_id else -direction
