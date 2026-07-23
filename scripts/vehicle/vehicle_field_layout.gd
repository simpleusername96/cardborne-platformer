class_name VehicleFieldLayout
extends RefCounted

## Immutable, run-scoped placement truth shared by gameplay and presentation.

const BROADPHASE_CELL_SIZE := 320.0
const BROADPHASE_MARGIN := 96.0

var seed := 0
var fingerprint := 0
var cover_ids: Array[StringName] = []
var cover_rects: Array[Rect2] = []
var ordinary_spawn_anchors: Array[Vector2] = []
var boss_arrival_anchors: Array[Vector2] = []
var stage_objects: Dictionary = {}
var encounter_seeds: Dictionary = {}
var used_fallback := false

var _cover_cells: Dictionary = {}
var _cover_seen_serial := PackedInt32Array()
var _cover_query_serial := 0
var _empty_cover_indices: Array[int] = []


func configure(
	layout_seed: int,
	selected_cover_ids: Array[StringName],
	selected_cover_rects: Array[Rect2],
	ordinary_anchors: Array[Vector2],
	boss_anchors: Array[Vector2],
	objects_by_stage: Dictionary,
	seeds_by_stage: Dictionary,
	fallback: bool
) -> void:
	seed = layout_seed
	cover_ids = selected_cover_ids.duplicate()
	cover_rects = selected_cover_rects.duplicate()
	ordinary_spawn_anchors = ordinary_anchors.duplicate()
	boss_arrival_anchors = boss_anchors.duplicate()
	stage_objects = objects_by_stage.duplicate(true)
	encounter_seeds = seeds_by_stage.duplicate(true)
	used_fallback = fallback
	_build_cover_broadphase()
	fingerprint = hash(var_to_str(_fingerprint_blueprint()))


func stationary_blueprint(stage_id: StringName) -> Array[Dictionary]:
	return _duplicate_specs(stage_id, "stationary")


func pickup_blueprint(stage_id: StringName) -> Array[Dictionary]:
	return _duplicate_specs(stage_id, "pickups")


func crate_blueprint(stage_id: StringName) -> Array[Dictionary]:
	return _duplicate_specs(stage_id, "crates")


func encounter_seed(stage_id: StringName) -> int:
	return int(encounter_seeds.get(stage_id, seed))


func covers_near_motion_into(
	from: Vector2,
	to: Vector2,
	radius: float,
	result: Array[Rect2]
) -> Array[Rect2]:
	result.clear()
	_cover_query_serial += 1
	if _cover_query_serial == 2147483647:
		_cover_seen_serial.fill(0)
		_cover_query_serial = 1
	var swept := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
	var min_cell := _world_to_cell(swept.position)
	var max_cell := _world_to_cell(swept.end)
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var bucket: Array = _cover_cells.get(Vector2i(x, y), _empty_cover_indices)
			for index_value in bucket:
				var index := int(index_value)
				if _cover_seen_serial[index] == _cover_query_serial:
					continue
				_cover_seen_serial[index] = _cover_query_serial
				var rectangle := cover_rects[index]
				if swept.intersects(rectangle.grow(radius), true):
					result.append(rectangle)
	return result


func canonical_blueprint() -> Dictionary:
	var stages: Array[Dictionary] = []
	var stage_ids := stage_objects.keys()
	stage_ids.sort()
	for stage_id_value in stage_ids:
		var stage_id := StringName(stage_id_value)
		stages.append({
			"id":String(stage_id),
			"stationary":_canonical_specs(stage_id, "stationary"),
			"pickups":_canonical_specs(stage_id, "pickups"),
			"crates":_canonical_specs(stage_id, "crates"),
			"encounter_seed":encounter_seed(stage_id),
		})
	return {
		"seed":seed,
		"cover_ids":Array(cover_ids),
		"covers":Array(cover_rects),
		"ordinary_anchors":Array(ordinary_spawn_anchors),
		"boss_anchors":Array(boss_arrival_anchors),
		"stages":stages,
		"used_fallback":used_fallback,
	}


func debug_snapshot() -> Dictionary:
	return {
		"seed":seed,
		"fingerprint":fingerprint,
		"cover_ids":cover_ids.duplicate(),
		"cover_count":cover_rects.size(),
		"ordinary_anchor_count":ordinary_spawn_anchors.size(),
		"boss_anchor_count":boss_arrival_anchors.size(),
		"used_fallback":used_fallback,
	}


func _fingerprint_blueprint() -> Dictionary:
	var stages: Array[Dictionary] = []
	var stage_ids := stage_objects.keys()
	stage_ids.sort()
	for stage_id_value in stage_ids:
		var stage_id := StringName(stage_id_value)
		stages.append({
			"id":String(stage_id),
			"stationary":_canonical_specs(stage_id, "stationary"),
			"pickups":_canonical_specs(stage_id, "pickups"),
			"crates":_canonical_specs(stage_id, "crates"),
		})
	return {
		"cover_ids":Array(cover_ids),
		"covers":Array(cover_rects),
		"ordinary_anchors":Array(ordinary_spawn_anchors),
		"boss_anchors":Array(boss_arrival_anchors),
		"stages":stages,
	}


func _duplicate_specs(stage_id: StringName, key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var stage: Dictionary = stage_objects.get(stage_id, {})
	for value in Array(stage.get(key, [])):
		result.append(Dictionary(value).duplicate(true))
	return result


func _canonical_specs(stage_id: StringName, key: String) -> Array[Dictionary]:
	var result := _duplicate_specs(stage_id, key)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return result


func _build_cover_broadphase() -> void:
	_cover_cells.clear()
	_cover_seen_serial.resize(cover_rects.size())
	_cover_seen_serial.fill(0)
	_cover_query_serial = 0
	for index in cover_rects.size():
		var expanded := cover_rects[index].grow(BROADPHASE_MARGIN)
		var min_cell := _world_to_cell(expanded.position)
		var max_cell := _world_to_cell(expanded.end)
		for y in range(min_cell.y, max_cell.y + 1):
			for x in range(min_cell.x, max_cell.x + 1):
				var cell := Vector2i(x, y)
				if not _cover_cells.has(cell):
					_cover_cells[cell] = []
				_cover_cells[cell].append(index)


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / BROADPHASE_CELL_SIZE),
		floori(position.y / BROADPHASE_CELL_SIZE)
	)
