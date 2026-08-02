class_name VehicleEnemyLocalSteering
extends RefCounted

## Resolves actual ordinary-enemy body penetration without maintaining spacing.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SEARCH_RADIUS := 120.0
const MAX_OVERLAP_NEIGHBORS := 8
const ROLE_WEIGHT := 0.55
const SEPARATION_WEIGHT := 0.45

var _query_buffer: Array[EnemyState] = []
var _overlaps: Array[Dictionary] = []


func adjusted_velocity(
	enemy: EnemyState,
	role_velocity: Vector2,
	spatial_grid,
	live_enemies: Array[EnemyState]
) -> Vector2:
	if role_velocity.length_squared() <= 0.001:
		return role_velocity
	spatial_grid.query_radius_into(enemy.pos, SEARCH_RADIUS, live_enemies, _query_buffer)
	_overlaps.clear()
	for candidate in _query_buffer:
		if (
			candidate == enemy
			or not candidate.alive
			or not candidate.active
			or candidate.role in [&"stage_boss", &"boss_pylon"]
		):
			continue
		var offset := enemy.pos - candidate.pos
		var distance_squared := offset.length_squared()
		var combined_radius := enemy.radius + candidate.radius
		if distance_squared >= combined_radius * combined_radius:
			continue
		var distance := sqrt(distance_squared)
		_overlaps.append({
			"enemy":candidate,
			"distance_squared":distance_squared,
			"penetration":combined_radius - distance,
			"direction":_separation_direction(enemy, candidate, offset, distance),
		})
	_overlaps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["distance_squared"]), float(b["distance_squared"])):
			return float(a["distance_squared"]) < float(b["distance_squared"])
		return String(a["enemy"].id) < String(b["enemy"].id)
	)
	if _overlaps.is_empty():
		return role_velocity
	var separation := Vector2.ZERO
	var strongest: Dictionary = _overlaps[0]
	for index in mini(MAX_OVERLAP_NEIGHBORS, _overlaps.size()):
		var overlap: Dictionary = _overlaps[index]
		separation += Vector2(overlap["direction"]) * float(overlap["penetration"])
		if (
			float(overlap["penetration"]) > float(strongest["penetration"])
			or (
				is_equal_approx(float(overlap["penetration"]), float(strongest["penetration"]))
				and String(overlap["enemy"].id) < String(strongest["enemy"].id)
			)
		):
			strongest = overlap
	if separation.length_squared() <= 0.0001:
		separation = Vector2(strongest["direction"])
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
