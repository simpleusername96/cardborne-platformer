class_name VehicleSpatialGrid
extends RefCounted

## Incremental uniform broadphase for live dynamic enemies. Buckets store stable
## pool slots plus a reuse generation; callers still perform exact geometry.

const DEFAULT_CELL_SIZE := 160.0
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const MAX_TRACKED_ACTORS := EnemyStore.MAX_LIVE_HOSTILES
const FLAG_ALIVE := 1
const FLAG_ACTIVE := 2

var bounds := Rect2()
var cell_size := DEFAULT_CELL_SIZE
var columns := 0
var rows := 0

var _cells: Array[Array] = []
var _touched_cells := PackedInt32Array()
var _touched_flags := PackedByteArray()
var _actors: Array[EnemyState] = []
var _member_generations := PackedInt32Array()
var _member_active := PackedByteArray()
var _member_min_x := PackedInt32Array()
var _member_min_y := PackedInt32Array()
var _member_max_x := PackedInt32Array()
var _member_max_y := PackedInt32Array()
var _seen_sync := PackedInt32Array()
var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _radii := PackedFloat32Array()
var _flags := PackedByteArray()
var _phase_codes := PackedByteArray()
var _phase_times := PackedFloat32Array()
var _sync_id := 0
var _query_stamps := PackedInt32Array()
var _query_id := 0
var _generation_rejects := 0


func configure(world_bounds: Rect2, requested_cell_size: float = DEFAULT_CELL_SIZE) -> void:
	bounds = world_bounds
	cell_size = maxf(1.0, requested_cell_size)
	columns = maxi(1, ceili(bounds.size.x / cell_size))
	rows = maxi(1, ceili(bounds.size.y / cell_size))
	_cells.clear()
	_cells.resize(columns * rows)
	for index in _cells.size():
		_cells[index] = []
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
	_seen_sync.resize(MAX_TRACKED_ACTORS)
	_seen_sync.fill(0)
	_positions.resize(MAX_TRACKED_ACTORS)
	_velocities.resize(MAX_TRACKED_ACTORS)
	_radii.resize(MAX_TRACKED_ACTORS)
	_flags.resize(MAX_TRACKED_ACTORS)
	_flags.fill(0)
	_phase_codes.resize(MAX_TRACKED_ACTORS)
	_phase_codes.fill(0)
	_phase_times.resize(MAX_TRACKED_ACTORS)
	_phase_times.fill(0.0)
	_sync_id = 0
	_query_stamps.resize(MAX_TRACKED_ACTORS)
	_query_stamps.fill(0)
	_query_id = 0
	_generation_rejects = 0


func rebuild(live: Array[EnemyState]) -> void:
	if _cells.is_empty():
		return
	for cell_index in _touched_cells:
		_cells[cell_index].clear()
		_touched_flags[cell_index] = 0
	_touched_cells.clear()
	_member_active.fill(0)
	_member_generations.fill(0)
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
		_flags[slot] = 0


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
	_velocities[slot] = enemy.velocity
	_radii[slot] = maxf(enemy.radius, enemy.projectile_hit_radius)
	_flags[slot] = flags
	_phase_codes[slot] = _phase_code(enemy.phase)
	_phase_times[slot] = enemy.phase_time
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


func query_radius_into(center: Vector2, radius: float, live: Array[EnemyState], output: Array[EnemyState]) -> void:
	output.clear()
	if _cells.is_empty():
		return
	_begin_query()
	var extent := Vector2(radius, radius)
	_append_rect_candidates(Rect2(center - extent, extent * 2.0), live, output)


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
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var cell_index := y * columns + x
			if _touched_flags[cell_index] == 0:
				_touched_flags[cell_index] = 1
				_touched_cells.append(cell_index)
			_cells[cell_index].append(slot)


func _remove_membership(slot: int) -> void:
	if slot < 0 or slot >= MAX_TRACKED_ACTORS or _member_active[slot] == 0:
		return
	for y in range(_member_min_y[slot], _member_max_y[slot] + 1):
		for x in range(_member_min_x[slot], _member_max_x[slot] + 1):
			_cells[y * columns + x].erase(slot)
	_member_active[slot] = 0


func _stable_slot(enemy: EnemyState) -> int:
	if enemy == null:
		return -1
	return enemy.spatial_slot if enemy.spatial_slot >= 0 else enemy.runtime_slot


func _phase_code(phase: StringName) -> int:
	match phase:
		&"move":
			return 1
		&"startup", &"boss_startup":
			return 2
		&"active", &"boss_active":
			return 3
		&"recovery", &"interrupted_recovery":
			return 4
		&"boss_read":
			return 5
		&"mine_armed":
			return 6
	return 0


func _cell_for(position: Vector2) -> Vector2i:
	var local := position - bounds.position
	return Vector2i(
		clampi(floori(local.x / cell_size), 0, columns - 1),
		clampi(floori(local.y / cell_size), 0, rows - 1)
	)
