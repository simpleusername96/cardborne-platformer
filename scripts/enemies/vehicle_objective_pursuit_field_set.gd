class_name VehicleObjectivePursuitFieldSet
extends RefCounted

## Bounded reverse-cost routing for the single active static objective. The
## compiled ordinary-enemy walkability mask is reused across device respawns.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

const CELL_SIZE := 96.0
const GRID_WIDTH := 75
const GRID_HEIGHT := 45
const CELL_COUNT := GRID_WIDTH * GRID_HEIGHT
const MAX_TARGET_FIELDS := 1
const MAX_COMBINED_CELLS_PER_TICK := 512
const ORDINARY_RADIUS := 36.0
const CARDINALS: Array[Vector2i] = [
	Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
]


class ObjectiveField:
	extends RefCounted

	var device_id: StringName = &""
	var target_position := Vector2.ZERO
	var active_costs := PackedInt32Array()
	var build_costs := PackedInt32Array()
	var queue := PackedInt32Array()
	var cursor := 0
	var queue_size := 0
	var target_index := -1
	var pending_index := -1
	var building := false
	var ready := false

	func _init(next_device_id: StringName) -> void:
		device_id = next_device_id
		active_costs.resize(CELL_COUNT)
		active_costs.fill(-1)
		build_costs.resize(CELL_COUNT)
		build_costs.fill(-1)
		queue.resize(CELL_COUNT)


var _stage_id: StringName = &"stage_1"
var _walkable := PackedByteArray()
var _fields: Array[ObjectiveField] = []
var _round_robin_cursor := 0
var _last_processed_cells := 0
var _rebuild_count := 0
var _runtime_cover_rects: Array[Rect2] = []


func _init() -> void:
	_walkable.resize(CELL_COUNT)


func reset(stage_id: StringName, runtime_cover_rects: Array[Rect2] = []) -> void:
	_stage_id = stage_id
	_runtime_cover_rects = runtime_cover_rects.duplicate()
	_fields.clear()
	_round_robin_cursor = 0
	_last_processed_cells = 0
	_rebuild_count = 0
	_compile_walkability()


func update(
	_targets: Dictionary,
	record_receipt: bool = false
) -> void:
	_sync_targets(_targets)
	if record_receipt:
		_last_processed_cells = 0
	if _fields.is_empty():
		return
	var remaining := MAX_COMBINED_CELLS_PER_TICK
	var field_count := _fields.size()
	for offset in field_count:
		var field_index := posmod(_round_robin_cursor + offset, field_count)
		var field := _fields[field_index]
		if not field.building and field.pending_index >= 0:
			_begin_rebuild(field, field.pending_index)
		var fields_left := field_count - offset
		var share := maxi(1, remaining / maxi(1, fields_left))
		var processed := _advance_rebuild(field, share)
		remaining -= processed
		if record_receipt:
			_last_processed_cells += processed
		if remaining <= 0:
			break
	_round_robin_cursor = posmod(_round_robin_cursor + 1, field_count)


func direction_at(
	device_id: StringName,
	position: Vector2,
	_radius: float
) -> Vector2:
	var field := _field_by_id(device_id)
	if field == null or not field.ready:
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


func path_cost(device_id: StringName, position: Vector2) -> int:
	var field := _field_by_id(device_id)
	var index := _index(_world_to_cell(position))
	if field == null or not field.ready or index < 0:
		return -1
	return field.active_costs[index]


func last_processed_cells() -> int:
	return _last_processed_cells


func debug_snapshot() -> Dictionary:
	var records: Array[Dictionary] = []
	for field in _fields:
		records.append({
			"device_id":field.device_id,
			"target_position":field.target_position,
			"building":field.building,
			"ready":field.ready,
			"reachable":_reachable_count(field),
		})
	return {
		"target_capacity":MAX_TARGET_FIELDS,
		"target_count":_fields.size(),
		"cell_capacity":CELL_COUNT,
		"max_combined_cells_per_tick":MAX_COMBINED_CELLS_PER_TICK,
		"last_processed_cells":_last_processed_cells,
		"rebuild_count":_rebuild_count,
		"fields":records,
	}


func _sync_targets(targets: Dictionary) -> void:
	for index in range(_fields.size() - 1, -1, -1):
		if not targets.has(_fields[index].device_id):
			_fields.remove_at(index)
	var target_ids: Array = targets.keys()
	target_ids.sort_custom(func(left: Variant, right: Variant) -> bool:
		return String(left) < String(right)
	)
	for target_id_variant in target_ids:
		if _fields.size() >= MAX_TARGET_FIELDS:
			break
		var target_id := StringName(target_id_variant)
		if _field_by_id(target_id) != null:
			continue
		_fields.append(ObjectiveField.new(target_id))
	for field in _fields:
		var next_position := Vector2(targets.get(field.device_id, field.target_position))
		var next_index := _nearest_walkable_index(_index(_world_to_cell(next_position)))
		field.target_position = next_position
		if next_index < 0:
			continue
		if field.building:
			if next_index != field.target_index:
				field.pending_index = next_index
		elif not field.ready or next_index != field.target_index:
			field.pending_index = next_index


func _field_by_id(device_id: StringName) -> ObjectiveField:
	for field in _fields:
		if field.device_id == device_id:
			return field
	return null


func _begin_rebuild(field: ObjectiveField, target_index: int) -> void:
	field.build_costs.fill(-1)
	field.cursor = 0
	field.queue_size = 1
	field.queue[0] = target_index
	field.build_costs[target_index] = 0
	field.target_index = target_index
	field.pending_index = -1
	field.building = true


func _advance_rebuild(field: ObjectiveField, budget: int) -> int:
	if not field.building or budget <= 0:
		return 0
	var processed := 0
	while field.cursor < field.queue_size and processed < budget:
		var current_index := field.queue[field.cursor]
		field.cursor += 1
		processed += 1
		var next_cost := field.build_costs[current_index] + 1
		var x := current_index % GRID_WIDTH
		var next_index := current_index - 1
		if x > 0:
			_offer_cell(field, next_index, next_cost)
		next_index = current_index + 1
		if x + 1 < GRID_WIDTH:
			_offer_cell(field, next_index, next_cost)
		next_index = current_index - GRID_WIDTH
		if current_index >= GRID_WIDTH:
			_offer_cell(field, next_index, next_cost)
		next_index = current_index + GRID_WIDTH
		if next_index < CELL_COUNT:
			_offer_cell(field, next_index, next_cost)
	if field.cursor >= field.queue_size:
		var previous := field.active_costs
		field.active_costs = field.build_costs
		field.build_costs = previous
		field.ready = true
		field.building = false
		_rebuild_count += 1
	return processed


func _offer_cell(field: ObjectiveField, index: int, cost: int) -> void:
	if _walkable[index] == 0 or field.build_costs[index] >= 0:
		return
	field.build_costs[index] = cost
	field.queue[field.queue_size] = index
	field.queue_size += 1


func _compile_walkability() -> void:
	_walkable.fill(0)
	var bounds := Rules.world_rect(_stage_id)
	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			var index := y * GRID_WIDTH + x
			var center := _cell_center(Vector2i(x, y))
			if not bounds.has_point(center):
				continue
			var blocked := false
			for cover in _runtime_cover_rects:
				if Rules.circle_overlaps_rect(center, ORDINARY_RADIUS, cover):
					blocked = true
					break
			if not blocked and Rules.is_position_walkable(center, ORDINARY_RADIUS, _stage_id):
				_walkable[index] = 1


func _nearest_walkable_index(origin_index: int) -> int:
	if origin_index >= 0 and _walkable[origin_index] == 1:
		return origin_index
	var origin := _cell(origin_index)
	for ring in range(1, 7):
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if absi(x) != ring and absi(y) != ring:
					continue
				var candidate := _index(origin + Vector2i(x, y))
				if candidate >= 0 and _walkable[candidate] == 1:
					return candidate
	return -1


func _reachable_count(field: ObjectiveField) -> int:
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
