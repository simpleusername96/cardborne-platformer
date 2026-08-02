extends SceneTree

const Grid = preload("res://scripts/combat/vehicle_spatial_grid.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x51A71A1
	var live: Array[EnemyState] = []
	for index in EnemyStore.MAX_LIVE_HOSTILES:
		var enemy := EnemyState.new()
		enemy.id = "grid_%d" % index
		enemy.runtime_slot = index
		enemy.spatial_slot = index
		enemy.runtime_generation = 1
		enemy.alive = true
		enemy.active = index % 11 != 0
		enemy.pos = Vector2(rng.randf_range(0.0, 5600.0), rng.randf_range(0.0, 3400.0))
		enemy.radius = rng.randf_range(8.0, 86.0)
		enemy.projectile_hit_radius = enemy.radius + rng.randf_range(0.0, 36.0)
		live.append(enemy)
	var grid := Grid.new()
	grid.configure(Rect2(0.0, 0.0, 5600.0, 3400.0), 160.0)
	grid.rebuild(live)
	_expect(grid.columns == 35 and grid.rows == 22, "grid uses the locked 35x22 dimensions")
	_expect(
		Grid.MAX_TRACKED_ACTORS == EnemyStore.MAX_LIVE_HOSTILES,
		"grid preallocates stamps for the complete bounded enemy store"
	)

	var candidates: Array[EnemyState] = []
	var capacity_target := live[-1]
	capacity_target.active = true
	capacity_target.pos = Vector2(2800.0, 1700.0)
	capacity_target.radius = 24.0
	grid.rebuild(live)
	grid.query_segment_into(
		Vector2(2500.0, 1700.0),
		Vector2(3100.0, 1700.0),
		7.0,
		live,
		candidates
	)
	_expect(
		capacity_target in candidates,
		"segment queries retain enemies in the final live-capacity slot"
	)
	var interceptor := live[0]
	interceptor.active = true
	interceptor.role = &"interceptor_tower"
	interceptor.pos = Vector2(2800.0, 1800.0)
	interceptor.radius = 34.0
	interceptor.projectile_hit_radius = 50.0
	grid.rebuild(live)
	grid.query_segment_cells_into(
		Vector2(2500.0, 1700.0),
		Vector2(3100.0, 1700.0),
		7.0,
		live,
		candidates,
		PackedInt32Array(),
		PackedFloat32Array()
	)
	_expect(
		interceptor in candidates,
		"segment broadphase preserves the interceptor projectile radius"
	)

	for query_index in 120:
		var center := Vector2(rng.randf_range(-80.0, 5680.0), rng.randf_range(-80.0, 3480.0))
		var radius := rng.randf_range(24.0, 520.0)
		grid.query_radius_into(center, radius, live, candidates)
		_expect_unique(candidates, "radius query %d" % query_index)
		for enemy in live:
			if not bool(enemy["alive"]) or not bool(enemy["active"]):
				continue
			var target_radius := maxf(enemy.radius, enemy.projectile_hit_radius)
			if center.distance_to(enemy.pos) <= radius + target_radius:
				_expect(enemy in candidates, "radius query %d contains every exact hit" % query_index)

	for query_index in 120:
		var from := Vector2(rng.randf_range(-80.0, 5680.0), rng.randf_range(-80.0, 3480.0))
		var to := Vector2(rng.randf_range(-80.0, 5680.0), rng.randf_range(-80.0, 3480.0))
		var padding := rng.randf_range(2.0, 32.0)
		var group_ends := PackedInt32Array()
		var group_exit_t := PackedFloat32Array()
		grid.query_segment_cells_into(
			from,
			to,
			padding,
			live,
			candidates,
			group_ends,
			group_exit_t
		)
		_expect_unique(candidates, "segment query %d" % query_index)
		_expect(
			group_ends.size() == group_exit_t.size()
				and not group_ends.is_empty()
				and group_ends[-1] == candidates.size(),
			"ordered segment query %d exposes complete cell groups"
			% query_index
		)
		for enemy in live:
			if not bool(enemy["alive"]) or not bool(enemy["active"]):
				continue
			var target_radius := maxf(enemy.radius, enemy.projectile_hit_radius)
			if Rules.point_segment_distance(enemy.pos, from, to) <= padding + target_radius:
				_expect(enemy in candidates, "segment query %d contains every exact hit" % query_index)

	var moved := live[17]
	var old_position := moved.pos
	moved.pos = Vector2(5320.0, 3180.0)
	grid.sync(live)
	grid.query_radius_into(
		moved.pos,
		8.0,
		live,
		candidates
	)
	_expect(moved in candidates, "incremental sync inserts a moved actor in its new cells")
	grid.query_radius_into(
		old_position,
		8.0,
		live,
		candidates
	)
	_expect(moved not in candidates, "incremental sync removes a moved actor from old cells")

	var replaced := live[31]
	var replaced_slot := replaced.spatial_slot
	var replacement := EnemyState.new()
	replacement.id = "grid_reused"
	replacement.runtime_slot = replaced.runtime_slot
	replacement.spatial_slot = replaced_slot
	replacement.runtime_generation = replaced.runtime_generation + 1
	replacement.alive = true
	replacement.active = true
	replacement.pos = Vector2(180.0, 180.0)
	replacement.radius = 18.0
	replacement.projectile_hit_radius = 18.0
	live[31] = replacement
	grid.sync(live)
	grid.query_radius_into(
		replacement.pos,
		8.0,
		live,
		candidates
	)
	_expect(
		replacement in candidates and replaced not in candidates,
		"generation sync replaces a pooled actor without stale membership"
	)
	var snapshot := grid.debug_snapshot()
	_expect(
		int(snapshot["active_members"]) > 0,
		"incremental grid reports active membership"
	)
	_finish()


func _expect_unique(candidates: Array[EnemyState], context: String) -> void:
	var seen := {}
	for enemy in candidates:
		var enemy_id := enemy.id
		_expect(not seen.has(enemy_id), "%s has no duplicate candidate" % context)
		seen[enemy_id] = true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SPATIAL_GRID_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
