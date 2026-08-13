class_name VehicleSpatialGrid
extends RefCounted

## Incremental uniform broadphase for live dynamic enemies. Buckets store stable
## pool slots plus a reuse generation; callers still perform exact geometry.

const DEFAULT_CELL_SIZE := 160.0
const LOCAL_QUERY_CELL_SIZE := 120.0
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const MAX_TRACKED_ACTORS := EnemyStore.MAX_LIVE_HOSTILES
const MAX_MEMBER_CELLS := 9
const LOCAL_OVERLAP_LIMIT := 8
const LOCAL_OVERLAP_DISTANCE := 120.0
const LOCAL_OVERLAP_DISTANCE_SQUARED := (
	LOCAL_OVERLAP_DISTANCE * LOCAL_OVERLAP_DISTANCE
)
const FLAG_ALIVE := 1
const FLAG_ACTIVE := 2

var bounds := Rect2()
var cell_size := DEFAULT_CELL_SIZE
var columns := 0
var rows := 0

var _cells: Array[Array] = []
var _local_cells: Array[Array] = []
var _local_columns := 0
var _local_rows := 0
var _touched_cells := PackedInt32Array()
var _touched_flags := PackedByteArray()
var _actors: Array[EnemyState] = []
var _member_generations := PackedInt32Array()
var _member_active := PackedByteArray()
var _member_min_x := PackedInt32Array()
var _member_min_y := PackedInt32Array()
var _member_max_x := PackedInt32Array()
var _member_max_y := PackedInt32Array()
var _member_counts := PackedByteArray()
var _member_cells := PackedInt32Array()
var _member_positions := PackedInt32Array()
var _local_member_active := PackedByteArray()
var _local_member_cells := PackedInt32Array()
var _local_member_positions := PackedInt32Array()
var _seen_sync := PackedInt32Array()
var _positions := PackedVector2Array()
var _radii := PackedFloat32Array()
var _sync_id := 0
var _query_stamps := PackedInt32Array()
var _query_id := 0
var _nearest_query_distances := PackedFloat32Array()
var _maximum_local_body_radius := 0.0
var _generation_rejects := 0
var _local_overlap_generations := PackedInt32Array()
var _local_overlap_valid := PackedInt32Array()
var _local_overlap_counts := PackedByteArray()
var _local_overlap_neighbor_slots := PackedInt32Array()
var _local_overlap_distances := PackedFloat64Array()
var _local_overlap_separation_directions := PackedVector2Array()
var _local_snapshot_positions := PackedVector2Array()
var _local_snapshot_body_radii := PackedFloat64Array()
var _local_snapshot_actor_ids := PackedStringArray()
var _local_snapshot_generations := PackedInt32Array()
var _local_snapshot_valid := PackedInt32Array()
var _local_overlap_build_serial := 0
var _local_overlap_builds := 0
var _legacy_nearest_query_calls := 0
var last_overlap_snapshot_ms := 0.0
var last_overlap_query_ms := 0.0


func configure(world_bounds: Rect2, requested_cell_size: float = DEFAULT_CELL_SIZE) -> void:
	bounds = world_bounds
	cell_size = maxf(1.0, requested_cell_size)
	columns = maxi(1, ceili(bounds.size.x / cell_size))
	rows = maxi(1, ceili(bounds.size.y / cell_size))
	_cells.clear()
	_cells.resize(columns * rows)
	for index in _cells.size():
		_cells[index] = []
	_local_columns = maxi(1, ceili(bounds.size.x / LOCAL_QUERY_CELL_SIZE))
	_local_rows = maxi(1, ceili(bounds.size.y / LOCAL_QUERY_CELL_SIZE))
	_local_cells.clear()
	_local_cells.resize(_local_columns * _local_rows)
	for index in _local_cells.size():
		_local_cells[index] = []
	_touched_cells.clear()
	_touched_flags.resize(_cells.size())
	_touched_flags.fill(0)
	_actors.clear()
	_actors.resize(MAX_TRACKED_ACTORS)
	_member_generations.resize(MAX_TRACKED_ACTORS)
	_member_generations.fill(0)
	_member_active.resize(MAX_TRACKED_ACTORS)
	_member_active.fill(0)
	_member_min_x.resize(MAX_TRACKED_ACTORS)
	_member_min_y.resize(MAX_TRACKED_ACTORS)
	_member_max_x.resize(MAX_TRACKED_ACTORS)
	_member_max_y.resize(MAX_TRACKED_ACTORS)
	_member_counts.resize(MAX_TRACKED_ACTORS)
	_member_counts.fill(0)
	_member_cells.resize(MAX_TRACKED_ACTORS * MAX_MEMBER_CELLS)
	_member_positions.resize(MAX_TRACKED_ACTORS * MAX_MEMBER_CELLS)
	_local_member_active.resize(MAX_TRACKED_ACTORS)
	_local_member_active.fill(0)
	_local_member_cells.resize(MAX_TRACKED_ACTORS)
	_local_member_positions.resize(MAX_TRACKED_ACTORS)
	_seen_sync.resize(MAX_TRACKED_ACTORS)
	_seen_sync.fill(0)
	_positions.resize(MAX_TRACKED_ACTORS)
	_radii.resize(MAX_TRACKED_ACTORS)
	_sync_id = 0
	_query_stamps.resize(MAX_TRACKED_ACTORS)
	_query_stamps.fill(0)
	_nearest_query_distances.resize(MAX_TRACKED_ACTORS)
	_local_overlap_generations.resize(MAX_TRACKED_ACTORS)
	_local_overlap_generations.fill(0)
	_local_overlap_valid.resize(MAX_TRACKED_ACTORS)
	_local_overlap_valid.fill(0)
	_local_overlap_counts.resize(MAX_TRACKED_ACTORS)
	_local_overlap_counts.fill(0)
	_local_overlap_neighbor_slots.resize(
		MAX_TRACKED_ACTORS * LOCAL_OVERLAP_LIMIT
	)
	_local_overlap_neighbor_slots.fill(-1)
	_local_overlap_distances.resize(
		MAX_TRACKED_ACTORS * LOCAL_OVERLAP_LIMIT
	)
	_local_overlap_separation_directions.resize(MAX_TRACKED_ACTORS)
	_local_snapshot_positions.resize(MAX_TRACKED_ACTORS)
	_local_snapshot_body_radii.resize(MAX_TRACKED_ACTORS)
	_local_snapshot_actor_ids.resize(MAX_TRACKED_ACTORS)
	_local_snapshot_generations.resize(MAX_TRACKED_ACTORS)
	_local_snapshot_generations.fill(0)
	_local_snapshot_valid.resize(MAX_TRACKED_ACTORS)
	_local_snapshot_valid.fill(0)
	_local_overlap_build_serial = 0
	_maximum_local_body_radius = 0.0
	_query_id = 0
	_generation_rejects = 0
	_local_overlap_builds = 0
	_legacy_nearest_query_calls = 0
	last_overlap_snapshot_ms = 0.0
	last_overlap_query_ms = 0.0


func rebuild(live: Array[EnemyState]) -> void:
	if _cells.is_empty():
		return
	for cell_index in _touched_cells:
		_cells[cell_index].clear()
		_touched_flags[cell_index] = 0
	_touched_cells.clear()
	for bucket in _local_cells:
		bucket.clear()
	_member_active.fill(0)
	_local_member_active.fill(0)
	_member_generations.fill(0)
	_member_counts.fill(0)
	_local_overlap_valid.fill(0)
	_local_overlap_counts.fill(0)
	_local_snapshot_valid.fill(0)
	for slot in MAX_TRACKED_ACTORS:
		_actors[slot] = null
	sync(live)


func sync(live: Array[EnemyState]) -> void:
	if _cells.is_empty():
		return
	_begin_sync()
	for enemy in live:
		var slot := _stable_slot(enemy)
		if slot < 0 or slot >= MAX_TRACKED_ACTORS:
			continue
		_seen_sync[slot] = _sync_id
		update_actor(enemy)
	for slot in MAX_TRACKED_ACTORS:
		if _member_active[slot] == 0 or _seen_sync[slot] == _sync_id:
			continue
		_remove_membership(slot)
		_actors[slot] = null
		_member_generations[slot] = 0


func update_actor(enemy: EnemyState) -> void:
	if _cells.is_empty() or enemy == null:
		return
	var slot := _stable_slot(enemy)
	if slot < 0 or slot >= MAX_TRACKED_ACTORS:
		return
	var generation := maxi(1, enemy.runtime_generation)
	if (
		_actors[slot] != enemy
		or _member_generations[slot] != generation
	):
		_remove_membership(slot)
		_actors[slot] = enemy
		_member_generations[slot] = generation
	var flags := 0
	if enemy.alive:
		flags |= FLAG_ALIVE
	if enemy.active:
		flags |= FLAG_ACTIVE
	_positions[slot] = enemy.pos
	_radii[slot] = maxf(enemy.radius, enemy.projectile_hit_radius)
	if enemy.role == &"interceptor_tower":
		_radii[slot] = maxf(
			_radii[slot], AttackContract.INTERCEPTOR_PROJECTILE_RADIUS
		)
	if enemy.role != &"stage_boss":
		_maximum_local_body_radius = maxf(
			_maximum_local_body_radius, enemy.radius
		)
	if flags != (FLAG_ALIVE | FLAG_ACTIVE):
		_remove_membership(slot)
		return
	var radius := _radii[slot]
	var extent := Vector2(radius, radius)
	var position := _positions[slot]
	var min_cell := _cell_for(position - extent)
	var max_cell := _cell_for(position + extent)
	if (
		_member_active[slot] == 0
		or _member_min_x[slot] != min_cell.x
		or _member_min_y[slot] != min_cell.y
		or _member_max_x[slot] != max_cell.x
		or _member_max_y[slot] != max_cell.y
	):
		_remove_membership(slot)
		_add_membership(slot, min_cell, max_cell)
	_update_local_membership(slot, enemy)


func update_actor_position(enemy: EnemyState) -> void:
	## Updates cached coordinates without rebuilding membership when the actor
	## remains in the same broadphase cell and retains its collision radius.
	if _cells.is_empty() or enemy == null:
		return
	var slot := _stable_slot(enemy)
	if slot < 0 or slot >= MAX_TRACKED_ACTORS:
		return
	var generation := maxi(1, enemy.runtime_generation)
	var cached_radius := maxf(enemy.radius, enemy.projectile_hit_radius)
	if enemy.role == &"interceptor_tower":
		cached_radius = maxf(
			cached_radius, AttackContract.INTERCEPTOR_PROJECTILE_RADIUS
		)
	if (
		_actors[slot] != enemy
		or _member_generations[slot] != generation
		or _member_active[slot] == 0
		or cached_radius != _radii[slot]
		or not enemy.alive
		or not enemy.active
	):
		update_actor(enemy)
		return
	var extent := Vector2(cached_radius, cached_radius)
	var min_cell := _cell_for(enemy.pos - extent)
	var max_cell := _cell_for(enemy.pos + extent)
	if (
		_member_min_x[slot] != min_cell.x
		or _member_min_y[slot] != min_cell.y
		or _member_max_x[slot] != max_cell.x
		or _member_max_y[slot] != max_cell.y
	):
		update_actor(enemy)
		return
	_positions[slot] = enemy.pos
	_update_local_membership(slot, enemy)


func query_radius_into(center: Vector2, radius: float, live: Array[EnemyState], output: Array[EnemyState]) -> void:
	output.clear()
	if _cells.is_empty():
		return
	_begin_query()
	var extent := Vector2(radius, radius)
	_append_rect_candidates(Rect2(center - extent, extent * 2.0), live, output)


func query_nearest_overlaps_into(
	owner: EnemyState,
	search_radius: float,
	_live: Array[EnemyState],
	maximum_results: int,
	output: Array[EnemyState]
) -> void:
	## Bounded exact body-overlap query for local steering. Results are ordered
	## by center distance then stable actor ID without materializing all candidates.
	## Runtime steering uses the batched cache; this path remains a test oracle.
	_legacy_nearest_query_calls += 1
	output.clear()
	if _cells.is_empty() or owner == null or maximum_results <= 0:
		return
	var bounded_maximum := mini(maximum_results, MAX_TRACKED_ACTORS)
	var exact_overlap_extent := minf(
		maxf(0.0, search_radius),
		maxf(0.0, owner.radius) + _maximum_local_body_radius
	)
	var extent := Vector2.ONE * exact_overlap_extent
	var rectangle := Rect2(owner.pos - extent, extent * 2.0)
	var min_cell := _local_cell_for(rectangle.position)
	var max_cell := _local_cell_for(rectangle.end)
	var search_distance_squared := search_radius * search_radius
	var worst_result_index := -1
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			for slot_value in _local_cells[y * _local_columns + x]:
				var slot := int(slot_value)
				if slot < 0 or slot >= MAX_TRACKED_ACTORS:
					continue
				var candidate: EnemyState = _actors[slot]
				if (
					candidate == null
					or candidate == owner
					or not candidate.alive
					or not candidate.active
					or candidate.role == &"stage_boss"
					or _member_generations[slot] != maxi(1, candidate.runtime_generation)
				):
					continue
				var distance_squared := owner.pos.distance_squared_to(_positions[slot])
				var combined_radius := owner.radius + candidate.radius
				if (
					distance_squared > search_distance_squared
					or distance_squared >= combined_radius * combined_radius
				):
					continue
				worst_result_index = _offer_nearest_query_result(
					candidate,
					distance_squared,
					bounded_maximum,
					output,
					worst_result_index
				)
	_sort_nearest_query_results(output)


func rebuild_local_overlap_cache(
	refresh_slots: PackedByteArray,
	measure_sections: bool = false
) -> void:
	## Captures one immutable boundary snapshot, then rebuilds only marked owner
	## rows from cells that can contain a body overlap. The candidate loop stays
	## inline because dispatching once per dense-cell candidate is a measured hot path.
	_local_overlap_builds += 1
	_local_overlap_build_serial += 1
	if _local_overlap_build_serial >= 0x7ffffffe:
		_local_overlap_valid.fill(0)
		_local_snapshot_valid.fill(0)
		_local_overlap_build_serial = 1
	var section_started := Time.get_ticks_usec() if measure_sections else 0
	for slot in MAX_TRACKED_ACTORS:
		var enemy: EnemyState = _actors[slot]
		if not _local_cache_actor_is_valid(slot, enemy):
			continue
		_local_snapshot_valid[slot] = _local_overlap_build_serial
		_local_snapshot_positions[slot] = _positions[slot]
		var generation := _member_generations[slot]
		if _local_snapshot_generations[slot] != generation:
			# Identity and body radius are immutable within one pooled generation.
			# Reuse them while only the position snapshot changes every tick.
			_local_snapshot_body_radii[slot] = maxf(0.0, enemy.radius)
			_local_snapshot_actor_ids[slot] = String(enemy.id)
			_local_snapshot_generations[slot] = generation
	if measure_sections:
		last_overlap_snapshot_ms = (
			float(Time.get_ticks_usec() - section_started) / 1000.0
		)
		section_started = Time.get_ticks_usec()
	else:
		last_overlap_snapshot_ms = 0.0
		last_overlap_query_ms = 0.0
	var owner_limit := mini(refresh_slots.size(), MAX_TRACKED_ACTORS)
	for owner_slot in owner_limit:
		if (
			refresh_slots[owner_slot] == 0
			or _local_snapshot_valid[owner_slot] != _local_overlap_build_serial
		):
			continue
		_local_overlap_valid[owner_slot] = _local_overlap_build_serial
		_local_overlap_generations[owner_slot] = _local_snapshot_generations[owner_slot]
		var owner_position := _local_snapshot_positions[owner_slot]
		var owner_radius := float(_local_snapshot_body_radii[owner_slot])
		var overlap_extent := minf(
			LOCAL_OVERLAP_DISTANCE,
			owner_radius + _maximum_local_body_radius
		)
		var extent := Vector2.ONE * overlap_extent
		var min_cell := _local_cell_for(owner_position - extent)
		var max_cell := _local_cell_for(owner_position + extent)
		var row_offset := owner_slot * LOCAL_OVERLAP_LIMIT
		var overlap_count := 0
		for cell_y in range(min_cell.y, max_cell.y + 1):
			for cell_x in range(min_cell.x, max_cell.x + 1):
				var bucket: Array = _local_cells[
					cell_y * _local_columns + cell_x
				]
				for candidate_slot_value in bucket:
					var candidate_slot := int(candidate_slot_value)
					if (
						candidate_slot < 0
						or candidate_slot >= MAX_TRACKED_ACTORS
						or owner_slot == candidate_slot
						or _local_snapshot_valid[candidate_slot]
							!= _local_overlap_build_serial
					):
						continue
					var distance_squared := owner_position.distance_squared_to(
						_local_snapshot_positions[candidate_slot]
					)
					var combined_radius := (
						owner_radius
						+ float(_local_snapshot_body_radii[candidate_slot])
					)
					if (
						distance_squared > LOCAL_OVERLAP_DISTANCE_SQUARED
						or distance_squared >= combined_radius * combined_radius
					):
						continue
					var insert_at := mini(
						overlap_count, LOCAL_OVERLAP_LIMIT - 1
					)
					if overlap_count >= LOCAL_OVERLAP_LIMIT:
						var worst_slot := _local_overlap_neighbor_slots[
							row_offset + insert_at
						]
						var worst_distance := _local_overlap_distances[
							row_offset + insert_at
						]
						if not (
							distance_squared < worst_distance
							or (
								is_equal_approx(distance_squared, worst_distance)
								and _local_snapshot_actor_ids[candidate_slot]
									< _local_snapshot_actor_ids[worst_slot]
							)
						):
							continue
					while insert_at > 0:
						var previous_index := row_offset + insert_at - 1
						var previous_slot := _local_overlap_neighbor_slots[
							previous_index
						]
						var previous_distance := _local_overlap_distances[
							previous_index
						]
						if not (
							distance_squared < previous_distance
							or (
								is_equal_approx(distance_squared, previous_distance)
								and _local_snapshot_actor_ids[candidate_slot]
									< _local_snapshot_actor_ids[previous_slot]
							)
						):
							break
						_local_overlap_neighbor_slots[
							row_offset + insert_at
						] = previous_slot
						_local_overlap_distances[
							row_offset + insert_at
						] = previous_distance
						insert_at -= 1
					_local_overlap_neighbor_slots[
						row_offset + insert_at
					] = candidate_slot
					_local_overlap_distances[
						row_offset + insert_at
					] = distance_squared
					if overlap_count < LOCAL_OVERLAP_LIMIT:
						overlap_count += 1
		_local_overlap_counts[owner_slot] = overlap_count
		_local_overlap_separation_directions[owner_slot] = (
			_local_separation_direction(
				owner_slot,
				row_offset,
				overlap_count,
				owner_position,
				owner_radius
			)
		)
	if measure_sections:
		last_overlap_query_ms = (
			float(Time.get_ticks_usec() - section_started) / 1000.0
		)


func cached_local_overlap_count(owner: EnemyState) -> int:
	var slot := _stable_slot(owner)
	if not _local_overlap_owner_is_valid(owner, slot):
		return 0
	return int(_local_overlap_counts[slot])


func cached_local_overlap_slot(owner: EnemyState, index: int) -> int:
	var owner_slot := _stable_slot(owner)
	if (
		not _local_overlap_owner_is_valid(owner, owner_slot)
		or index < 0
		or index >= int(_local_overlap_counts[owner_slot])
	):
		return -1
	return _local_overlap_neighbor_slots[
		owner_slot * LOCAL_OVERLAP_LIMIT + index
	]


func cached_local_overlap_distance_squared(owner: EnemyState, index: int) -> float:
	var owner_slot := _stable_slot(owner)
	if (
		not _local_overlap_owner_is_valid(owner, owner_slot)
		or index < 0
		or index >= int(_local_overlap_counts[owner_slot])
	):
		return INF
	return _local_overlap_distances[
		owner_slot * LOCAL_OVERLAP_LIMIT + index
	]


func cached_local_separation_direction(owner: EnemyState) -> Vector2:
	var slot := _stable_slot(owner)
	if not _local_overlap_owner_is_valid(owner, slot):
		return Vector2.ZERO
	return _local_overlap_separation_directions[slot]


func cached_local_position(slot: int) -> Vector2:
	return (
		_local_snapshot_positions[slot]
		if (
			slot >= 0
			and slot < MAX_TRACKED_ACTORS
			and _local_snapshot_valid[slot] == _local_overlap_build_serial
		)
		else Vector2.ZERO
	)


func cached_local_body_radius(slot: int) -> float:
	return (
		float(_local_snapshot_body_radii[slot])
		if (
			slot >= 0
			and slot < MAX_TRACKED_ACTORS
			and _local_snapshot_valid[slot] == _local_overlap_build_serial
		)
		else 0.0
	)


func cached_local_actor_id(slot: int) -> String:
	return (
		String(_local_snapshot_actor_ids[slot])
		if (
			slot >= 0
			and slot < MAX_TRACKED_ACTORS
			and _local_snapshot_valid[slot] == _local_overlap_build_serial
		)
		else ""
	)


func query_segment_into(from: Vector2, to: Vector2, padding: float, live: Array[EnemyState], output: Array[EnemyState]) -> void:
	output.clear()
	if _cells.is_empty():
		return
	_begin_query()
	var minimum := Vector2(minf(from.x, to.x), minf(from.y, to.y)) - Vector2(padding, padding)
	var maximum := Vector2(maxf(from.x, to.x), maxf(from.y, to.y)) + Vector2(padding, padding)
	_append_rect_candidates(Rect2(minimum, maximum - minimum), live, output)


func query_segment_cells_into(
	from: Vector2,
	to: Vector2,
	padding: float,
	live: Array[EnemyState],
	output: Array[EnemyState],
	group_ends: PackedInt32Array,
	group_exit_t: PackedFloat32Array
) -> void:
	output.clear()
	group_ends.clear()
	group_exit_t.clear()
	if _cells.is_empty():
		return
	_begin_query()
	var start_cell := _cell_for(from)
	var end_cell := _cell_for(to)
	var current := start_cell
	var motion := to - from
	var step_x := 1 if motion.x > 0.0 else (-1 if motion.x < 0.0 else 0)
	var step_y := 1 if motion.y > 0.0 else (-1 if motion.y < 0.0 else 0)
	var t_delta_x := INF if step_x == 0 else cell_size / absf(motion.x)
	var t_delta_y := INF if step_y == 0 else cell_size / absf(motion.y)
	var boundary_x := (
		bounds.position.x + float(current.x + (1 if step_x > 0 else 0)) * cell_size
	)
	var boundary_y := (
		bounds.position.y + float(current.y + (1 if step_y > 0 else 0)) * cell_size
	)
	var t_max_x := INF if step_x == 0 else maxf(0.0, (boundary_x - from.x) / motion.x)
	var t_max_y := INF if step_y == 0 else maxf(0.0, (boundary_y - from.y) / motion.y)
	var padding_cells := ceili(maxf(0.0, padding) / cell_size)
	var safety := columns * rows + columns + rows
	while safety > 0:
		safety -= 1
		for y in range(
			maxi(0, current.y - padding_cells),
			mini(rows - 1, current.y + padding_cells) + 1
		):
			for x in range(
				maxi(0, current.x - padding_cells),
				mini(columns - 1, current.x + padding_cells) + 1
			):
				_append_cell_candidates(y * columns + x, live, output)
		var exit_t := 1.0 if current == end_cell else minf(t_max_x, t_max_y)
		group_ends.append(output.size())
		group_exit_t.append(clampf(exit_t, 0.0, 1.0))
		if current == end_cell:
			break
		if t_max_x < t_max_y:
			current.x = clampi(current.x + step_x, 0, columns - 1)
			t_max_x += t_delta_x
		elif t_max_y < t_max_x:
			current.y = clampi(current.y + step_y, 0, rows - 1)
			t_max_y += t_delta_y
		else:
			current.x = clampi(current.x + step_x, 0, columns - 1)
			current.y = clampi(current.y + step_y, 0, rows - 1)
			t_max_x += t_delta_x
			t_max_y += t_delta_y


func debug_snapshot() -> Dictionary:
	var active_members := 0
	for value in _member_active:
		active_members += int(value)
	return {
		"columns": columns,
		"rows": rows,
		"cell_size": cell_size,
		"touched_cells": _touched_cells.size(),
		"active_members": active_members,
		"sync_id": _sync_id,
		"generation_rejects": _generation_rejects,
		"packed_hot_slots": _actors.size(),
		"local_overlap_limit": LOCAL_OVERLAP_LIMIT,
		"local_overlap_capacity": _local_overlap_neighbor_slots.size(),
		"local_overlap_builds": _local_overlap_builds,
		"legacy_nearest_query_calls": _legacy_nearest_query_calls,
	}


func _begin_sync() -> void:
	_sync_id += 1
	if _sync_id < 0x7ffffffe:
		return
	_seen_sync.fill(0)
	_sync_id = 1


func _begin_query() -> void:
	_query_id += 1
	if _query_id < 0x7ffffffe:
		return
	_query_stamps.fill(0)
	_query_id = 1


func _append_rect_candidates(rect: Rect2, live: Array[EnemyState], output: Array[EnemyState]) -> void:
	var min_cell := _cell_for(rect.position)
	var max_cell := _cell_for(rect.end)
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			_append_cell_candidates(y * columns + x, live, output)


func _append_cell_candidates(
	cell_index: int,
	_live: Array[EnemyState],
	output: Array[EnemyState]
) -> void:
	for slot_value in _cells[cell_index]:
		var slot := int(slot_value)
		if slot < 0 or slot >= MAX_TRACKED_ACTORS:
			continue
		if _query_stamps[slot] == _query_id:
			continue
		_query_stamps[slot] = _query_id
		var enemy: EnemyState = _actors[slot]
		if (
			enemy == null
			or not enemy.alive
			or not enemy.active
			or _member_generations[slot] != maxi(1, enemy.runtime_generation)
		):
			_generation_rejects += 1
			continue
		output.append(enemy)


func _offer_nearest_query_result(
	candidate: EnemyState,
	distance_squared: float,
	maximum_results: int,
	output: Array[EnemyState],
	worst_index: int
) -> int:
	if output.size() < maximum_results:
		output.append(candidate)
		_nearest_query_distances[output.size() - 1] = distance_squared
		return (
			_worst_nearest_query_index(output)
			if output.size() == maximum_results
			else -1
		)
	if worst_index < 0:
		worst_index = _worst_nearest_query_index(output)
	if not _nearest_query_value_is_better(
		candidate,
		distance_squared,
		output[worst_index],
		_nearest_query_distances[worst_index]
	):
		return worst_index
	output[worst_index] = candidate
	_nearest_query_distances[worst_index] = distance_squared
	return _worst_nearest_query_index(output)


func _worst_nearest_query_index(output: Array[EnemyState]) -> int:
	var worst_index := 0
	for index in range(1, output.size()):
		if _nearest_query_value_is_better(
			output[worst_index],
			_nearest_query_distances[worst_index],
			output[index],
			_nearest_query_distances[index]
		):
			worst_index = index
	return worst_index


func _nearest_query_value_is_better(
	candidate: EnemyState,
	distance_squared: float,
	other: EnemyState,
	other_distance_squared: float
) -> bool:
	return (
		distance_squared < other_distance_squared
		or (
			is_equal_approx(distance_squared, other_distance_squared)
			and candidate.id < other.id
		)
	)


func _sort_nearest_query_results(output: Array[EnemyState]) -> void:
	for index in range(1, output.size()):
		var candidate := output[index]
		var distance_squared := _nearest_query_distances[index]
		var insert_at := index
		while insert_at > 0 and _nearest_query_value_is_better(
			candidate,
			distance_squared,
			output[insert_at - 1],
			_nearest_query_distances[insert_at - 1]
		):
			output[insert_at] = output[insert_at - 1]
			_nearest_query_distances[insert_at] = (
				_nearest_query_distances[insert_at - 1]
			)
			insert_at -= 1
		output[insert_at] = candidate
		_nearest_query_distances[insert_at] = distance_squared


func _local_cache_actor_is_valid(slot: int, enemy: EnemyState) -> bool:
	return (
		slot >= 0
		and slot < MAX_TRACKED_ACTORS
		and enemy != null
		and enemy.alive
		and enemy.active
		and enemy.role != &"stage_boss"
		and _local_member_active[slot] != 0
		and _member_generations[slot] == maxi(1, enemy.runtime_generation)
	)


func _local_overlap_owner_is_valid(owner: EnemyState, slot: int) -> bool:
	return (
		owner != null
		and slot >= 0
		and slot < MAX_TRACKED_ACTORS
		and _local_overlap_valid[slot] == _local_overlap_build_serial
		and _local_overlap_generations[slot] == maxi(1, owner.runtime_generation)
	)


func _local_separation_direction(
	owner_slot: int,
	row_offset: int,
	overlap_count: int,
	owner_position: Vector2,
	owner_radius: float
) -> Vector2:
	if overlap_count <= 0:
		return Vector2.ZERO
	var separation := Vector2.ZERO
	var strongest_actor_id := ""
	var strongest_penetration := -1.0
	var strongest_direction := Vector2.ZERO
	var owner_id := String(_local_snapshot_actor_ids[owner_slot])
	for index in overlap_count:
		var candidate_slot := _local_overlap_neighbor_slots[row_offset + index]
		var candidate_id := String(_local_snapshot_actor_ids[candidate_slot])
		var offset := owner_position - _local_snapshot_positions[candidate_slot]
		var distance := offset.length()
		var penetration := (
			owner_radius
			+ float(_local_snapshot_body_radii[candidate_slot])
			- distance
		)
		var direction := _deterministic_separation_direction(
			owner_id, candidate_id, offset, distance
		)
		separation += direction * penetration
		if (
			penetration > strongest_penetration
			or (
				is_equal_approx(penetration, strongest_penetration)
				and (
					strongest_actor_id.is_empty()
					or candidate_id < strongest_actor_id
				)
			)
		):
			strongest_actor_id = candidate_id
			strongest_penetration = penetration
			strongest_direction = direction
	if separation.length_squared() <= 0.0001:
		separation = strongest_direction
	return separation.normalized()


func _deterministic_separation_direction(
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


func _add_membership(
	slot: int,
	min_cell: Vector2i,
	max_cell: Vector2i
) -> void:
	_member_active[slot] = 1
	_member_min_x[slot] = min_cell.x
	_member_min_y[slot] = min_cell.y
	_member_max_x[slot] = max_cell.x
	_member_max_y[slot] = max_cell.y
	var member_count := 0
	var member_offset := slot * MAX_MEMBER_CELLS
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			assert(member_count < MAX_MEMBER_CELLS)
			var cell_index := y * columns + x
			if _touched_flags[cell_index] == 0:
				_touched_flags[cell_index] = 1
				_touched_cells.append(cell_index)
			_member_cells[member_offset + member_count] = cell_index
			_member_positions[member_offset + member_count] = _cells[cell_index].size()
			_cells[cell_index].append(slot)
			member_count += 1
	_member_counts[slot] = member_count


func _remove_membership(slot: int) -> void:
	if slot < 0 or slot >= MAX_TRACKED_ACTORS:
		return
	_remove_local_membership(slot)
	if _member_active[slot] == 0:
		return
	var member_offset := slot * MAX_MEMBER_CELLS
	for membership_index in _member_counts[slot]:
		var cell_index := _member_cells[member_offset + membership_index]
		var position := _member_positions[member_offset + membership_index]
		var bucket: Array = _cells[cell_index]
		var last_position := bucket.size() - 1
		if position < 0 or position > last_position:
			continue
		var moved_slot := int(bucket[last_position])
		if position != last_position:
			bucket[position] = moved_slot
			_replace_member_position(moved_slot, cell_index, last_position, position)
		bucket.pop_back()
	_member_counts[slot] = 0
	_member_active[slot] = 0


func _update_local_membership(slot: int, enemy: EnemyState) -> void:
	if enemy.role == &"stage_boss":
		_remove_local_membership(slot)
		return
	var next_cell := _local_cell_for(enemy.pos)
	var next_cell_index := next_cell.y * _local_columns + next_cell.x
	if (
		_local_member_active[slot] != 0
		and _local_member_cells[slot] == next_cell_index
	):
		return
	_remove_local_membership(slot)
	_local_member_active[slot] = 1
	_local_member_cells[slot] = next_cell_index
	var bucket: Array = _local_cells[next_cell_index]
	_local_member_positions[slot] = bucket.size()
	bucket.append(slot)


func _remove_local_membership(slot: int) -> void:
	if _local_member_active[slot] == 0:
		return
	var cell_index := _local_member_cells[slot]
	var position := _local_member_positions[slot]
	var bucket: Array = _local_cells[cell_index]
	var last_position := bucket.size() - 1
	if position >= 0 and position <= last_position:
		var moved_slot := int(bucket[last_position])
		if position != last_position:
			bucket[position] = moved_slot
			_local_member_positions[moved_slot] = position
		bucket.pop_back()
	_local_member_active[slot] = 0


func _replace_member_position(
	slot: int,
	cell_index: int,
	old_position: int,
	new_position: int
) -> void:
	var member_offset := slot * MAX_MEMBER_CELLS
	for membership_index in _member_counts[slot]:
		var flat_index := member_offset + membership_index
		if (
			_member_cells[flat_index] == cell_index
			and _member_positions[flat_index] == old_position
		):
			_member_positions[flat_index] = new_position
			return


func _stable_slot(enemy: EnemyState) -> int:
	if enemy == null:
		return -1
	return enemy.spatial_slot if enemy.spatial_slot >= 0 else enemy.runtime_slot


func _cell_for(position: Vector2) -> Vector2i:
	var local := position - bounds.position
	return Vector2i(
		clampi(floori(local.x / cell_size), 0, columns - 1),
		clampi(floori(local.y / cell_size), 0, rows - 1)
	)


func _local_cell_for(position: Vector2) -> Vector2i:
	var local := position - bounds.position
	return Vector2i(
		clampi(floori(local.x / LOCAL_QUERY_CELL_SIZE), 0, _local_columns - 1),
		clampi(floori(local.y / LOCAL_QUERY_CELL_SIZE), 0, _local_rows - 1)
	)
