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
	_validate_local_overlap_cache()

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
	var position_only_target := live[18]
	position_only_target.active = true
	position_only_target.pos = Vector2(2800.0, 1700.0)
	position_only_target.radius = 4.0
	position_only_target.projectile_hit_radius = 4.0
	grid.rebuild(live)
	var position_only_old := position_only_target.pos
	position_only_target.pos = Vector2(2820.0, 1720.0)
	grid.update_actor_position(position_only_target)
	var position_only_probe := EnemyState.new()
	position_only_probe.pos = position_only_target.pos
	position_only_probe.radius = 4.0
	grid.query_nearest_overlaps_into(position_only_probe, 8.0, live, 8, candidates)
	_expect(
		position_only_target in candidates,
		"position-only updates expose an actor at its new coordinate"
	)
	position_only_probe.pos = position_only_old
	grid.query_nearest_overlaps_into(position_only_probe, 8.0, live, 8, candidates)
	_expect(
		position_only_target not in candidates,
		"position-only updates do not leave stale coordinates"
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


func _validate_local_overlap_cache() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x0B471C
	var live: Array[EnemyState] = []
	for index in EnemyStore.MAX_LIVE_HOSTILES:
		var enemy := EnemyState.new()
		enemy.id = "overlap_%03d" % index
		enemy.runtime_slot = index
		enemy.spatial_slot = index
		enemy.runtime_generation = 3
		enemy.alive = true
		enemy.active = true
		enemy.role = &"chaser"
		enemy.pos = Vector2(
			rng.randf_range(320.0, 1280.0),
			rng.randf_range(320.0, 1040.0)
		)
		enemy.radius = rng.randf_range(16.0, 42.0)
		enemy.projectile_hit_radius = enemy.radius
		live.append(enemy)
	live[7].active = false
	live[19].alive = false
	live[33].role = &"stage_boss"
	live[41].role = &"stage_boss"
	var grid := Grid.new()
	grid.configure(Rect2(0.0, 0.0, 1600.0, 1280.0), 160.0)
	grid.rebuild(live)
	var refresh_mask := PackedByteArray()
	refresh_mask.resize(EnemyStore.MAX_LIVE_HOSTILES)
	refresh_mask.fill(1)
	grid.rebuild_local_overlap_cache(refresh_mask)
	for owner in live:
		var oracle := _brute_local_overlaps(owner, live)
		var actual_count := grid.cached_local_overlap_count(owner)
		_expect(
			actual_count == oracle.size(),
			"packed overlap row %d matches brute-force count" % owner.runtime_slot
		)
		for index in mini(actual_count, oracle.size()):
			var expected: EnemyState = oracle[index]
			var actual_slot := grid.cached_local_overlap_slot(owner, index)
			_expect(
				grid.cached_local_actor_id(actual_slot) == String(expected.id),
				"packed overlap row %d index %d preserves ordered actor ID"
				% [owner.runtime_slot, index]
			)
			_expect(
				is_equal_approx(
					grid.cached_local_overlap_distance_squared(owner, index),
					owner.pos.distance_squared_to(expected.pos)
				),
				"packed overlap row %d index %d preserves distance"
				% [owner.runtime_slot, index]
			)
	var snapshot := grid.debug_snapshot()
	_expect(
		int(snapshot["local_overlap_limit"]) == 8
		and int(snapshot["local_overlap_capacity"])
			== EnemyStore.MAX_LIVE_HOSTILES * 8,
		"packed overlap storage is fixed at 320 rows of eight"
	)
	_expect(
		int(snapshot["legacy_nearest_query_calls"]) == 0,
		"batched cache construction performs no legacy per-owner query"
	)
	_expect(
		int(snapshot["local_overlap_snapshot_slots"])
			== EnemyStore.MAX_LIVE_HOSTILES - 4,
		"overlap snapshots visit only indexed valid local actors"
	)
	var fixed_capacity := int(snapshot["local_overlap_capacity"])
	for _iteration in 8:
		grid.rebuild_local_overlap_cache(refresh_mask)
	_expect(
		int(grid.debug_snapshot()["local_overlap_capacity"]) == fixed_capacity,
		"repeated saturated cache builds do not grow packed storage"
	)
	_validate_dense_partial_overlap_mask()
	_validate_local_overlap_edges()


func _validate_dense_partial_overlap_mask() -> void:
	var live: Array[EnemyState] = []
	for index in 24:
		live.append(_local_enemy(
			"dense_%02d" % index,
			index,
			Vector2(480.0, 480.0),
			36.0
		))
	var grid := Grid.new()
	grid.configure(Rect2(0.0, 0.0, 960.0, 960.0), 160.0)
	grid.rebuild(live)
	var mask := PackedByteArray()
	mask.resize(EnemyStore.MAX_LIVE_HOSTILES)
	mask.fill(0)
	var selected: Array[EnemyState] = [live[5], live[18]]
	for owner in selected:
		mask[owner.spatial_slot] = 1
	grid.rebuild_local_overlap_cache(mask)
	_expect(
		int(grid.debug_snapshot()["local_overlap_snapshot_slots"]) == live.size(),
		"partial owner masks retain every indexed local candidate snapshot"
	)
	for owner in live:
		if owner not in selected:
			_expect(
				grid.cached_local_overlap_count(owner) == 0
				and grid.cached_local_overlap_slot(owner, 0) == -1,
				"dense partial mask leaves unselected row %d invalid"
				% owner.runtime_slot
			)
			continue
		var oracle := _brute_local_overlaps(owner, live)
		var actual_count := grid.cached_local_overlap_count(owner)
		_expect(
			actual_count == Grid.LOCAL_OVERLAP_LIMIT
			and actual_count == oracle.size(),
			"dense selected row %d matches brute-force count"
			% owner.runtime_slot
		)
		for index in mini(actual_count, oracle.size()):
			var expected: EnemyState = oracle[index]
			var actual_slot := grid.cached_local_overlap_slot(owner, index)
			_expect(
				grid.cached_local_actor_id(actual_slot) == String(expected.id)
				and is_equal_approx(
					grid.cached_local_overlap_distance_squared(owner, index),
					owner.pos.distance_squared_to(expected.pos)
				),
				"dense selected row %d index %d matches ordered brute force"
				% [owner.runtime_slot, index]
			)


func _validate_local_overlap_edges() -> void:
	var live: Array[EnemyState] = []
	var cross_owner := _local_enemy("cross_owner", 0, Vector2(119.0, 119.0), 70.0)
	var cross_neighbor := _local_enemy("cross_neighbor", 1, Vector2(121.0, 121.0), 70.0)
	var search_edge := _local_enemy("search_edge", 2, Vector2(239.0, 119.0), 70.0)
	var same_cell := _local_enemy("same_cell", 3, Vector2(110.0, 119.0), 20.0)
	var tangent_owner := _local_enemy("tangent_owner", 4, Vector2(400.0, 400.0), 20.0)
	var tangent_neighbor := _local_enemy("tangent_neighbor", 5, Vector2(440.0, 400.0), 20.0)
	var zero_owner := _local_enemy("zero_owner", 6, Vector2(560.0, 560.0), 20.0)
	var zero_neighbor := _local_enemy("zero_neighbor", 7, Vector2(560.0, 560.0), 20.0)
	live.assign([
		cross_owner, cross_neighbor, search_edge, same_cell,
		tangent_owner, tangent_neighbor, zero_owner, zero_neighbor,
	])
	for index in 12:
		live.append(_local_enemy(
			"equal_%02d" % (11 - index),
			8 + index,
			Vector2(710.0, 700.0),
			30.0
		))
	var equal_owner := _local_enemy("equal_owner", 20, Vector2(700.0, 700.0), 30.0)
	live.append(equal_owner)
	var inactive := _local_enemy("inactive", 21, Vector2(702.0, 700.0), 30.0)
	inactive.active = false
	live.append(inactive)
	var dead := _local_enemy("dead", 22, Vector2(704.0, 700.0), 30.0)
	dead.alive = false
	live.append(dead)
	var boss := _local_enemy("boss", 23, Vector2(706.0, 700.0), 30.0)
	boss.role = &"stage_boss"
	live.append(boss)
	var second_boss := _local_enemy("second_boss", 24, Vector2(708.0, 700.0), 30.0)
	second_boss.role = &"stage_boss"
	live.append(second_boss)
	var grid := Grid.new()
	grid.configure(Rect2(0.0, 0.0, 1000.0, 1000.0), 160.0)
	grid.rebuild(live)
	var mask := PackedByteArray()
	mask.resize(EnemyStore.MAX_LIVE_HOSTILES)
	mask.fill(0)
	for owner in [cross_owner, tangent_owner, zero_owner, equal_owner]:
		mask[owner.spatial_slot] = 1
	grid.rebuild_local_overlap_cache(mask)
	var cross_ids := _cached_overlap_ids(grid, cross_owner)
	_expect(
		"cross_neighbor" in cross_ids
		and "same_cell" in cross_ids
		and "search_edge" in cross_ids,
		"same-cell, cross-cell, and exact 120-unit candidates are cached"
	)
	_expect(
		grid.cached_local_overlap_count(cross_neighbor) == 0,
		"unmasked candidates do not receive a directed cache row"
	)
	_expect(
		grid.cached_local_overlap_count(tangent_owner) == 0,
		"exact body tangency is not treated as penetration"
	)
	_expect(
		_cached_overlap_ids(grid, zero_owner) == ["zero_neighbor"],
		"zero-distance overlap remains a valid deterministic neighbor"
	)
	var equal_ids := _cached_overlap_ids(grid, equal_owner)
	_expect(equal_ids.size() == 8, "equal-distance rows retain only eight candidates")
	var sorted_equal_ids := equal_ids.duplicate()
	sorted_equal_ids.sort()
	_expect(
		equal_ids == sorted_equal_ids
		and "inactive" not in equal_ids
		and "dead" not in equal_ids
		and "boss" not in equal_ids
		and "pylon" not in equal_ids,
		"equal-distance rows use actor ID order and exclude invalid special actors"
	)
	var captured_position := grid.cached_local_position(cross_neighbor.spatial_slot)
	cross_neighbor.pos += Vector2(12.0, 0.0)
	grid.update_actor_position(cross_neighbor)
	_expect(
		grid.cached_local_position(cross_neighbor.spatial_slot) == captured_position,
		"published overlap positions remain immutable until the next batch"
	)
	var old_generation := cross_owner.runtime_generation
	cross_owner.runtime_generation += 1
	_expect(
		grid.cached_local_overlap_count(cross_owner) == 0,
		"owner generation reuse invalidates a previously published row"
	)
	cross_owner.runtime_generation = old_generation + 1
	grid.update_actor(cross_owner)
	grid.rebuild_local_overlap_cache(mask)
	_expect(
		grid.cached_local_overlap_count(cross_owner) > 0,
		"generation reuse publishes only the replacement generation"
	)


func _local_enemy(
	enemy_id: String,
	slot: int,
	position: Vector2,
	radius: float
) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = enemy_id
	enemy.runtime_slot = slot
	enemy.spatial_slot = slot
	enemy.runtime_generation = 1
	enemy.alive = true
	enemy.active = true
	enemy.role = &"chaser"
	enemy.pos = position
	enemy.radius = radius
	enemy.projectile_hit_radius = radius
	return enemy


func _cached_overlap_ids(grid: VehicleSpatialGrid, owner: EnemyState) -> Array[String]:
	var ids: Array[String] = []
	for index in grid.cached_local_overlap_count(owner):
		ids.append(grid.cached_local_actor_id(
			grid.cached_local_overlap_slot(owner, index)
		))
	return ids


func _brute_local_overlaps(
	owner: EnemyState,
	live: Array[EnemyState]
) -> Array[EnemyState]:
	var result: Array[EnemyState] = []
	if (
		owner == null
		or not owner.alive
		or not owner.active
		or owner.role == &"stage_boss"
	):
		return result
	for candidate in live:
		if (
			candidate == owner
			or not candidate.alive
			or not candidate.active
			or candidate.role == &"stage_boss"
		):
			continue
		var distance_squared := owner.pos.distance_squared_to(candidate.pos)
		var combined_radius := owner.radius + candidate.radius
		if (
			distance_squared <= Grid.LOCAL_OVERLAP_DISTANCE_SQUARED
			and distance_squared < combined_radius * combined_radius
		):
			result.append(candidate)
	result.sort_custom(
		func(first: EnemyState, second: EnemyState) -> bool:
			var first_distance := owner.pos.distance_squared_to(first.pos)
			var second_distance := owner.pos.distance_squared_to(second.pos)
			return (
				String(first.id) < String(second.id)
				if is_equal_approx(first_distance, second_distance)
				else first_distance < second_distance
			)
	)
	if result.size() > Grid.LOCAL_OVERLAP_LIMIT:
		result.resize(Grid.LOCAL_OVERLAP_LIMIT)
	return result


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
