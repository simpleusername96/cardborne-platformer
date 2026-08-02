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
	var output := LocalSteering.new().adjusted_velocity(live[0], Vector2(150.0, 0.0), grid, live)
	_expect(output.is_finite(), "dense overlap fixture remains finite with the eight-neighbor bound")
	_expect(LocalSteering.MAX_OVERLAP_NEIGHBORS == 8, "local steering inspects at most eight overlaps per cadence")


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
