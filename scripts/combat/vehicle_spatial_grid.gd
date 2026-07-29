class_name VehicleSpatialGrid
extends RefCounted

## Reused uniform broadphase for live dynamic enemies. Buckets contain current
## live-store slots; callers still perform exact circle/segment geometry.

const DEFAULT_CELL_SIZE := 160.0
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const MAX_TRACKED_ACTORS := EnemyStore.MAX_LIVE_HOSTILES

var bounds := Rect2()
var cell_size := DEFAULT_CELL_SIZE
var columns := 0
var rows := 0

var _cells: Array[Array] = []
var _touched_cells := PackedInt32Array()
var _touched_flags := PackedByteArray()
var _query_stamps := PackedInt32Array()
var _query_id := 0


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
	_query_stamps.resize(MAX_TRACKED_ACTORS)
	_query_stamps.fill(0)
	_query_id = 0


func rebuild(live: Array[EnemyState]) -> void:
	if _cells.is_empty():
		return
	for cell_index in _touched_cells:
		_cells[cell_index].clear()
		_touched_flags[cell_index] = 0
	_touched_cells.clear()
	for slot in live.size():
		var enemy: EnemyState = live[slot]
		if not enemy.alive or not enemy.active:
			continue
		var position := enemy.pos
		var radius := maxf(enemy.radius, enemy.projectile_hit_radius)
		var min_cell := _cell_for(position - Vector2(radius, radius))
		var max_cell := _cell_for(position + Vector2(radius, radius))
		for y in range(min_cell.y, max_cell.y + 1):
			for x in range(min_cell.x, max_cell.x + 1):
				var cell_index := y * columns + x
				if _touched_flags[cell_index] == 0:
					_touched_flags[cell_index] = 1
					_touched_cells.append(cell_index)
				_cells[cell_index].append(slot)


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


func debug_snapshot() -> Dictionary:
	return {
		"columns": columns,
		"rows": rows,
		"cell_size": cell_size,
		"touched_cells": _touched_cells.size(),
	}


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
			for slot_value in _cells[y * columns + x]:
				var slot := int(slot_value)
				if slot < 0 or slot >= live.size() or slot >= _query_stamps.size():
					continue
				if _query_stamps[slot] == _query_id:
					continue
				_query_stamps[slot] = _query_id
				var enemy: EnemyState = live[slot]
				if enemy.alive and enemy.active:
					output.append(enemy)


func _cell_for(position: Vector2) -> Vector2i:
	var local := position - bounds.position
	return Vector2i(
		clampi(floori(local.x / cell_size), 0, columns - 1),
		clampi(floori(local.y / cell_size), 0, rows - 1)
	)
