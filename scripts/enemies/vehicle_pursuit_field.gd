class_name VehiclePursuitField
extends RefCounted

## Shared incremental reverse-cost fields. Mobile actors sample packed arrays;
## no actor owns an individual path search.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

const CELL_SIZE := 96.0
const GRID_WIDTH := 75
const GRID_HEIGHT := 45
const CELL_COUNT := GRID_WIDTH * GRID_HEIGHT
const REBUILD_INTERVAL := 0.20
const MAX_REBUILD_CELLS_PER_TICK := 1024
const UNREACHABLE := 1 << 28
const CARDINALS: Array[Vector2i] = [
	Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
]


class CostField:
	extends RefCounted

	var radius := 36.0
	var walkable := PackedByteArray()
	var active_costs := PackedInt32Array()
	var build_costs := PackedInt32Array()
	var queue := PackedInt32Array()
	var cursor := 0
	var queue_size := 0
	var target_index := -1
	var pending_index := -1
	var building := false
	var ready := false
	var requested := false

	func _init(value: float) -> void:
		radius = value
		walkable.resize(CELL_COUNT)
		active_costs.resize(CELL_COUNT)
		active_costs.fill(-1)
		build_costs.resize(CELL_COUNT)
		build_costs.fill(-1)
		queue.resize(CELL_COUNT)


var _stage_id: StringName = &"stage_1"
var _player_cell := Vector2i(-99999, -99999)
var _player_position := Vector2.ZERO
var _rebuild_cooldown := 0.0
var _ordinary := CostField.new(36.0)
var _boss := CostField.new(76.0)
var _rebuild_count := 0
var _runtime_cover_rects: Array[Rect2] = []


func reset(stage_id: StringName, runtime_cover_rects: Array[Rect2] = []) -> void:
	_stage_id = stage_id
	_runtime_cover_rects = runtime_cover_rects.duplicate()
	_player_cell = Vector2i(-99999, -99999)
	_player_position = Vector2.ZERO
	_rebuild_cooldown = 0.0
	_rebuild_count = 0
	_compile_walkability(_ordinary)
	_compile_walkability(_boss)
	_clear_cost_field(_ordinary)
	_clear_cost_field(_boss)


func update(delta: float, player_position: Vector2) -> void:
	_player_position = player_position
	_rebuild_cooldown = maxf(0.0, _rebuild_cooldown - maxf(0.0, delta))
	var next_cell := _world_to_cell(player_position)
	var next_index := _index(next_cell)
	if next_cell != _player_cell and next_index >= 0:
		_player_cell = next_cell
		_queue_target(_ordinary, next_index)
		if _boss.requested:
			_queue_target(_boss, next_index)
	if not _ordinary.building and _ordinary.pending_index >= 0 and _rebuild_cooldown <= 0.0:
		_begin_rebuild(_ordinary, _ordinary.pending_index)
		_rebuild_cooldown = REBUILD_INTERVAL
	var remaining := MAX_REBUILD_CELLS_PER_TICK
	remaining -= _advance_rebuild(_ordinary, remaining)
	if _boss.requested and not _boss.building and _boss.pending_index >= 0:
		_begin_rebuild(_boss, _boss.pending_index)
	if remaining > 0 and _boss.requested:
		_advance_rebuild(_boss, remaining)


func request_rebuild() -> void:
	_compile_walkability(_ordinary)
	_compile_walkability(_boss)
	var target_index := _index(_world_to_cell(_player_position))
	_queue_target(_ordinary, target_index)
	if _boss.requested:
		_queue_target(_boss, target_index)
	_rebuild_cooldown = 0.0


func direction_at(position: Vector2, radius: float) -> Vector2:
	var field := _field_for(radius)
	_ensure_requested(field)
	if not field.ready:
		return Vector2.ZERO
	var cell := _world_to_cell(position)
	var current_index := _index(cell)
	if current_index < 0:
		return Vector2.ZERO
	var current_cost := field.active_costs[current_index]
	if current_cost < 0:
		return Vector2.ZERO
	var best_cell := cell
	var best_cost := current_cost
	for offset in CARDINALS:
		var candidate := cell + offset
		var candidate_index := _index(candidate)
		if candidate_index < 0:
			continue
		var candidate_cost := field.active_costs[candidate_index]
		if candidate_cost >= 0 and candidate_cost < best_cost:
			best_cost = candidate_cost
			best_cell = candidate
	if best_cell == cell:
		return Vector2.ZERO
	return (_cell_center(best_cell) - position).normalized()


func path_cost(position: Vector2, radius: float) -> int:
	var field := _field_for(radius)
	_ensure_requested(field)
	var index := _index(_world_to_cell(position))
	if not field.ready or index < 0:
		return -1
	return field.active_costs[index]


func debug_snapshot() -> Dictionary:
	return {
		"cell_size":CELL_SIZE,
		"grid_size":Vector2i(GRID_WIDTH, GRID_HEIGHT),
		"max_rebuild_cells_per_tick":MAX_REBUILD_CELLS_PER_TICK,
		"rebuild_interval":REBUILD_INTERVAL,
		"rebuild_count":_rebuild_count,
		"ordinary_reachable":_reachable_count(_ordinary),
		"boss_reachable":_reachable_count(_boss),
		"ordinary_building":_ordinary.building,
		"boss_building":_boss.building,
	}


func _field_for(radius: float) -> CostField:
	return _boss if radius >= 60.0 else _ordinary


func _ensure_requested(field: CostField) -> void:
	if field.requested:
		return
	field.requested = true
	var target_index := _index(_world_to_cell(_player_position))
	_queue_target(field, target_index)


func _queue_target(field: CostField, requested_index: int) -> void:
	if requested_index < 0:
		return
	var nearest := _nearest_walkable_index(field, requested_index)
	if nearest < 0:
		return
	if field.building:
		if nearest != field.target_index:
			field.pending_index = nearest
		return
	if field.ready and nearest == field.target_index:
		return
	field.pending_index = nearest


func _begin_rebuild(field: CostField, target_index: int) -> void:
	field.build_costs.fill(-1)
	field.cursor = 0
	field.queue_size = 1
	field.queue[0] = target_index
	field.build_costs[target_index] = 0
	field.target_index = target_index
	field.pending_index = -1
	field.building = true


func _advance_rebuild(field: CostField, budget: int) -> int:
	if not field.building or budget <= 0:
		return 0
	var processed := 0
	while field.cursor < field.queue_size and processed < budget:
		var current_index := field.queue[field.cursor]
		field.cursor += 1
		processed += 1
		var current_cell := _cell(current_index)
		var next_cost := field.build_costs[current_index] + 1
		for offset in CARDINALS:
			var next_index := _index(current_cell + offset)
			if (
				next_index < 0
				or field.walkable[next_index] == 0
				or field.build_costs[next_index] >= 0
			):
				continue
			field.build_costs[next_index] = next_cost
			field.queue[field.queue_size] = next_index
			field.queue_size += 1
	if field.cursor >= field.queue_size:
		var previous := field.active_costs
		field.active_costs = field.build_costs
		field.build_costs = previous
		field.ready = true
		field.building = false
		_rebuild_count += 1
	return processed


func _compile_walkability(field: CostField) -> void:
	field.walkable.fill(0)
	var bounds := Rules.world_rect(_stage_id)
	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			var index := y * GRID_WIDTH + x
			var center := _cell_center(Vector2i(x, y))
			if not bounds.has_point(center):
				continue
			var blocked := false
			for cover in _runtime_cover_rects:
				if Rules.circle_overlaps_rect(center, field.radius, cover):
					blocked = true
					break
			if not blocked and Rules.is_position_walkable(center, field.radius, _stage_id):
				field.walkable[index] = 1


func _clear_cost_field(field: CostField) -> void:
	field.active_costs.fill(-1)
	field.build_costs.fill(-1)
	field.cursor = 0
	field.queue_size = 0
	field.target_index = -1
	field.pending_index = -1
	field.building = false
	field.ready = false
	field.requested = field.radius < 60.0


func _nearest_walkable_index(field: CostField, origin_index: int) -> int:
	if origin_index >= 0 and field.walkable[origin_index] == 1:
		return origin_index
	var origin := _cell(origin_index)
	for ring in range(1, 7):
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if absi(x) != ring and absi(y) != ring:
					continue
				var candidate := _index(origin + Vector2i(x, y))
				if candidate >= 0 and field.walkable[candidate] == 1:
					return candidate
	return -1


func _reachable_count(field: CostField) -> int:
	if not field.ready:
		return 0
	var result := 0
	for value in field.active_costs:
		if value >= 0:
			result += 1
	return result


func _index(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_WIDTH or cell.y >= GRID_HEIGHT:
		return -1
	return cell.y * GRID_WIDTH + cell.x


func _cell(index: int) -> Vector2i:
	if index < 0:
		return Vector2i(-1, -1)
	return Vector2i(index % GRID_WIDTH, floori(float(index) / float(GRID_WIDTH)))


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / CELL_SIZE), floori(position.y / CELL_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE
