extends SceneTree

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SpatialGrid = preload("res://scripts/combat/vehicle_spatial_grid.gd")
const LocalSteering = preload("res://scripts/enemies/vehicle_enemy_local_steering.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_non_overlap_identity()
	_validate_overlap_resolution()
	_validate_exact_overlap_determinism()
	_validate_neighbor_bound()
	_validate_randomized_oracle()
	_finish()


func _validate_non_overlap_identity() -> void:
	var live: Array[EnemyState] = [
		_enemy("self", 0, Vector2.ZERO),
		_enemy("near_not_touching", 1, Vector2(80.0, 0.0)),
	]
	var grid: VehicleSpatialGrid = _grid(live)
	var input := Vector2(140.0, 35.0)
	var output := LocalSteering.new().adjusted_velocity(live[0], input, grid, live)
	_expect(output == input, "non-overlap neighbors leave role velocity exactly unchanged")
	_expect(
		int(grid.debug_snapshot()["legacy_nearest_query_calls"]) == 0,
		"cached steering performs no per-owner nearest query"
	)


func _validate_overlap_resolution() -> void:
	var live: Array[EnemyState] = [
		_enemy("self", 0, Vector2.ZERO),
		_enemy("right_overlap", 1, Vector2(24.0, 0.0)),
	]
	var grid: VehicleSpatialGrid = _grid(live)
	var input := Vector2(200.0, 0.0)
	var output := LocalSteering.new().adjusted_velocity(live[0], input, grid, live)
	_expect(output.x < input.x, "actual overlap adds a separating component")
	_expect(output.length() <= input.length() + 0.001, "overlap steering never raises role speed")


func _validate_exact_overlap_determinism() -> void:
	var live: Array[EnemyState] = [
		_enemy("alpha", 0, Vector2.ZERO),
		_enemy("beta", 1, Vector2.ZERO),
	]
	var grid: VehicleSpatialGrid = _grid(live)
	var input := Vector2(120.0, 0.0)
	var steering := LocalSteering.new()
	var first := steering.adjusted_velocity(live[0], input, grid, live)
	var second := steering.adjusted_velocity(live[0], input, grid, live)
	_expect(first == second and first.is_finite(), "zero-distance overlap uses a stable finite direction")


func _validate_neighbor_bound() -> void:
	var live: Array[EnemyState] = [_enemy("center", 0, Vector2.ZERO)]
	for index in 12:
		live.append(_enemy(
			"neighbor_%02d" % index,
			index + 1,
			Vector2.RIGHT.rotated(TAU * float(index) / 12.0) * 18.0
		))
	var grid: VehicleSpatialGrid = _grid(live)
	var nearest: Array[EnemyState] = []
	grid.query_nearest_overlaps_into(live[0], 120.0, live, 8, nearest)
	_expect(nearest.size() == 8, "spatial broadphase returns at most eight exact overlaps")
	for index in range(1, nearest.size()):
		_expect(
			live[0].pos.distance_squared_to(nearest[index - 1].pos)
			<= live[0].pos.distance_squared_to(nearest[index].pos) + 0.001,
			"bounded overlap results remain nearest-first"
		)
	var output := LocalSteering.new().adjusted_velocity(live[0], Vector2(150.0, 0.0), grid, live)
	_expect(output.is_finite(), "dense overlap fixture remains finite with the eight-neighbor bound")
	_expect(LocalSteering.MAX_OVERLAP_NEIGHBORS == 8, "local steering inspects at most eight overlaps per cadence")


func _validate_randomized_oracle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xB47C4E
	var live: Array[EnemyState] = []
	for index in SpatialGrid.MAX_TRACKED_ACTORS:
		var enemy := _enemy(
			"random_%03d" % index,
			index,
			Vector2(
				rng.randf_range(-260.0, 260.0),
				rng.randf_range(-260.0, 260.0)
			)
		)
		enemy.radius = rng.randf_range(12.0, 38.0)
		enemy.projectile_hit_radius = enemy.radius
		live.append(enemy)
	var grid := _grid(live)
	var steering := LocalSteering.new()
	for owner in live:
		var role_velocity := Vector2(173.0, 41.0).rotated(
			float(owner.runtime_slot % 17) * 0.21
		)
		var actual := steering.adjusted_velocity(
			owner, role_velocity, grid, live, true
		)
		var expected := _brute_adjusted_velocity(owner, role_velocity, live)
		_expect(
			actual.distance_to(expected) <= 0.001,
			(
				"randomized slot %d adjusted velocity matches brute-force oracle "
				+ "(actual=%s expected=%s delta=%s)"
			)
			% [owner.runtime_slot, actual, expected, actual - expected]
		)
	_expect(
		int(grid.debug_snapshot()["legacy_nearest_query_calls"]) == 0,
		"randomized saturated steering uses only the packed cache"
	)


func _brute_adjusted_velocity(
	owner: EnemyState,
	role_velocity: Vector2,
	live: Array[EnemyState]
) -> Vector2:
	var candidates: Array[EnemyState] = []
	for candidate in live:
		if (
			candidate == owner
			or not candidate.alive
			or not candidate.active
			or candidate.role in [&"stage_boss", &"boss_pylon"]
		):
			continue
		var distance_squared := owner.pos.distance_squared_to(candidate.pos)
		var combined_radius := owner.radius + candidate.radius
		if (
			distance_squared <= LocalSteering.SEARCH_RADIUS * LocalSteering.SEARCH_RADIUS
			and distance_squared < combined_radius * combined_radius
		):
			candidates.append(candidate)
	candidates.sort_custom(
		func(first: EnemyState, second: EnemyState) -> bool:
			var first_distance := owner.pos.distance_squared_to(first.pos)
			var second_distance := owner.pos.distance_squared_to(second.pos)
			return (
				String(first.id) < String(second.id)
				if is_equal_approx(first_distance, second_distance)
				else first_distance < second_distance
			)
	)
	if candidates.size() > LocalSteering.MAX_OVERLAP_NEIGHBORS:
		candidates.resize(LocalSteering.MAX_OVERLAP_NEIGHBORS)
	if candidates.is_empty():
		return role_velocity
	var separation := Vector2.ZERO
	var strongest_id := ""
	var strongest_penetration := -1.0
	var strongest_direction := Vector2.ZERO
	for candidate in candidates:
		var offset := owner.pos - candidate.pos
		var distance := offset.length()
		var penetration := owner.radius + candidate.radius - distance
		var direction := _brute_separation_direction(
			String(owner.id), String(candidate.id), offset, distance
		)
		separation += direction * penetration
		if (
			penetration > strongest_penetration
			or (
				is_equal_approx(penetration, strongest_penetration)
				and (strongest_id.is_empty() or String(candidate.id) < strongest_id)
			)
		):
			strongest_id = String(candidate.id)
			strongest_penetration = penetration
			strongest_direction = direction
	if separation.length_squared() <= 0.0001:
		separation = strongest_direction
	var separation_velocity := separation.normalized() * role_velocity.length()
	return (
		role_velocity * LocalSteering.ROLE_WEIGHT
		+ separation_velocity * LocalSteering.SEPARATION_WEIGHT
	).limit_length(role_velocity.length())


func _brute_separation_direction(
	first_id: String,
	second_id: String,
	offset: Vector2,
	distance: float
) -> Vector2:
	if distance > 0.0001:
		return offset / distance
	var ordered := (
		first_id + ":" + second_id
		if first_id < second_id
		else second_id + ":" + first_id
	)
	var angle := float(wrapi(hash(ordered), 0, 4096)) / 4096.0 * TAU
	var direction := Vector2.RIGHT.rotated(angle)
	return direction if first_id < second_id else -direction


func _enemy(enemy_id: String, slot: int, position: Vector2) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = enemy_id
	enemy.role = &"chaser"
	enemy.pos = position
	enemy.radius = 20.0
	enemy.projectile_hit_radius = 20.0
	enemy.alive = true
	enemy.active = true
	enemy.runtime_slot = slot
	enemy.runtime_generation = 1
	return enemy


func _grid(live: Array[EnemyState]) -> VehicleSpatialGrid:
	var grid := SpatialGrid.new()
	grid.configure(Rect2(-500.0, -500.0, 1000.0, 1000.0), 80.0)
	grid.rebuild(live)
	var refresh_mask := PackedByteArray()
	refresh_mask.resize(SpatialGrid.MAX_TRACKED_ACTORS)
	refresh_mask.fill(1)
	grid.rebuild_local_overlap_cache(refresh_mask)
	return grid


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_LOCAL_STEERING_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
