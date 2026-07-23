class_name VehiclePursuitField
extends RefCounted

## Shared reverse-cost navigation field. All mobile actors sample the same
## low-frequency grid instead of running one path search per enemy.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

const CELL_SIZE := 96.0
const REBUILD_INTERVAL := 0.20
const CARDINALS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _stage_id: StringName = &"stage_1"
var _player_cell := Vector2i(-99999, -99999)
var _player_position := Vector2.ZERO
var _rebuild_cooldown := 0.0
var _costs_by_radius: Dictionary = {}
var _walkable_by_radius: Dictionary = {}
var _rebuild_count := 0
var _large_rebuild_pending := false


func reset(stage_id: StringName) -> void:
	_stage_id = stage_id
	_player_cell = Vector2i(-99999, -99999)
	_player_position = Vector2.ZERO
	_rebuild_cooldown = 0.0
	_costs_by_radius.clear()
	_walkable_by_radius.clear()
	_large_rebuild_pending = false


func update(delta: float, player_position: Vector2) -> void:
	_rebuild_cooldown = maxf(0.0, _rebuild_cooldown - maxf(0.0, delta))
	if _large_rebuild_pending:
		_player_position = player_position
		_costs_by_radius[76] = _build_costs(player_position, 76.0)
		_large_rebuild_pending = false
		return
	var next_cell := _world_to_cell(player_position)
	if next_cell == _player_cell and not _costs_by_radius.is_empty():
		return
	if _rebuild_cooldown > 0.0:
		return
	_player_cell = next_cell
	_player_position = player_position
	_costs_by_radius[36] = _build_costs(player_position, 36.0)
	# An already-needed boss field is refreshed on the following physics tick so
	# two complete reverse fields never rebuild in one frame.
	_large_rebuild_pending = _costs_by_radius.has(76)
	_rebuild_cooldown = REBUILD_INTERVAL
	_rebuild_count += 1


func request_rebuild() -> void:
	_rebuild_cooldown = 0.0
	_player_cell = Vector2i(-99999, -99999)


func direction_at(position: Vector2, radius: float) -> Vector2:
	var key := 76 if radius >= 60.0 else 36
	_ensure_costs(key)
	var costs: Dictionary = _costs_by_radius.get(key, {})
	if costs.is_empty():
		return Vector2.ZERO
	var cell := _world_to_cell(position)
	var current_cost := int(costs.get(cell, 1 << 28))
	var best_cell := cell
	var best_cost := current_cost
	for offset in CARDINALS:
		var candidate := cell + offset
		var candidate_cost := int(costs.get(candidate, 1 << 28))
		if candidate_cost < best_cost:
			best_cost = candidate_cost
			best_cell = candidate
	if best_cell == cell:
		return Vector2.ZERO
	return (_cell_center(best_cell) - position).normalized()


func path_cost(position: Vector2, radius: float) -> int:
	var key := 76 if radius >= 60.0 else 36
	_ensure_costs(key)
	return int(Dictionary(_costs_by_radius.get(key, {})).get(_world_to_cell(position), -1))


func debug_snapshot() -> Dictionary:
	return {
		"cell_size":CELL_SIZE,
		"rebuild_interval":REBUILD_INTERVAL,
		"rebuild_count":_rebuild_count,
		"ordinary_reachable":Dictionary(_costs_by_radius.get(36, {})).size(),
		"boss_reachable":Dictionary(_costs_by_radius.get(76, {})).size(),
	}


func _build_costs(player_position: Vector2, radius: float) -> Dictionary:
	var start := _nearest_walkable_cell(_world_to_cell(player_position), radius)
	if start.x < 0:
		return {}
	var costs := {start:0}
	var queue: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		var next_cost := int(costs[current]) + 1
		for offset in CARDINALS:
			var next := current + offset
			if costs.has(next) or not _cell_walkable(next, radius):
				continue
			costs[next] = next_cost
			queue.append(next)
	return costs


func _ensure_costs(key: int) -> void:
	if _costs_by_radius.has(key) or _player_cell.x < 0:
		return
	_costs_by_radius[key] = _build_costs(_player_position, float(key))


func _nearest_walkable_cell(origin: Vector2i, radius: float) -> Vector2i:
	if _cell_walkable(origin, radius):
		return origin
	for ring in range(1, 7):
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if absi(x) != ring and absi(y) != ring:
					continue
				var candidate := origin + Vector2i(x, y)
				if _cell_walkable(candidate, radius):
					return candidate
	return Vector2i(-1, -1)


func _cell_walkable(cell: Vector2i, radius: float) -> bool:
	var key := 76 if radius >= 60.0 else 36
	if not _walkable_by_radius.has(key):
		_walkable_by_radius[key] = _build_walkable_cells(float(key))
	return Dictionary(_walkable_by_radius[key]).has(cell)


func _build_walkable_cells(radius: float) -> Dictionary:
	var result := {}
	var bounds := Rules.world_rect(_stage_id)
	var min_cell := _world_to_cell(bounds.position)
	var max_cell := _world_to_cell(bounds.end - Vector2.ONE)
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(x, y)
			if Rules.is_position_walkable(_cell_center(cell), radius, _stage_id):
				result[cell] = true
	return result


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / CELL_SIZE), floori(position.y / CELL_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE
