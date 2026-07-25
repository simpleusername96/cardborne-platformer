class_name VehicleStageTacticalLayout
extends RefCounted

## Immutable stage-scoped placement truth shared by simulation and presentation.

const BROADPHASE_CELL_SIZE := 320.0
const BROADPHASE_MARGIN := 96.0
const GeometrySnapshot = preload("res://scripts/vehicle/vehicle_field_geometry_snapshot.gd")

var stage_id: StringName = &""
var fingerprint := 0
var cover_ids: Array[StringName] = []
var cover_rects: Array[Rect2] = []
var ordinary_spawn_anchors: Array[Vector2] = []
var boss_arrival_anchors: Array[Vector2] = []
var support_sockets: Array[Vector2] = []
var encounter_seed := 0
var used_fallback := false
var geometry_snapshot: VehicleFieldGeometrySnapshot

var _objects: Dictionary = {}
var _cover_cells: Dictionary = {}
var _cover_seen_serial := PackedInt32Array()
var _cover_query_serial := 0
var _empty_cover_indices: Array[int] = []


func configure(
	next_stage_id: StringName,
	field_definition: Dictionary,
	selected_cover_ids: Array[StringName],
	selected_cover_rects: Array[Rect2],
	ordinary_anchors: Array[Vector2],
	boss_anchors: Array[Vector2],
	objects: Dictionary,
	selected_support_sockets: Array[Vector2],
	selected_encounter_seed: int,
	fallback: bool
) -> void:
	stage_id = next_stage_id
	cover_ids = selected_cover_ids.duplicate()
	cover_rects = selected_cover_rects.duplicate()
	ordinary_spawn_anchors = ordinary_anchors.duplicate()
	boss_arrival_anchors = boss_anchors.duplicate()
	_objects = objects.duplicate(true)
	support_sockets = selected_support_sockets.duplicate()
	encounter_seed = selected_encounter_seed
	used_fallback = fallback
	geometry_snapshot = GeometrySnapshot.new()
	geometry_snapshot.configure(field_definition, cover_rects)
	_build_cover_broadphase()
	fingerprint = hash(var_to_str(canonical_blueprint()))


func stationary_blueprint() -> Array[Dictionary]:
	return _duplicate_specs("stationary")


func pickup_blueprint() -> Array[Dictionary]:
	return _duplicate_specs("pickups")


func crate_blueprint() -> Array[Dictionary]:
	return _duplicate_specs("crates")


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
	return {
		"stage_id":String(stage_id),
		"cover_ids":Array(cover_ids),
		"covers":Array(cover_rects),
		"ordinary_anchors":Array(ordinary_spawn_anchors),
		"boss_anchors":Array(boss_arrival_anchors),
		"stationary":_canonical_specs("stationary"),
		"pickups":_canonical_specs("pickups"),
		"crates":_canonical_specs("crates"),
		"support_sockets":Array(support_sockets),
		"encounter_seed":encounter_seed,
		"used_fallback":used_fallback,
	}


func debug_snapshot() -> Dictionary:
	return {
		"stage_id":stage_id,
		"fingerprint":fingerprint,
		"cover_ids":cover_ids.duplicate(),
		"cover_count":cover_rects.size(),
		"ordinary_anchor_count":ordinary_spawn_anchors.size(),
		"boss_anchor_count":boss_arrival_anchors.size(),
		"support_socket_count":support_sockets.size(),
		"encounter_seed":encounter_seed,
		"used_fallback":used_fallback,
	}


func _duplicate_specs(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in Array(_objects.get(key, [])):
		result.append(Dictionary(value).duplicate(true))
	return result


func _canonical_specs(key: String) -> Array[Dictionary]:
	var result := _duplicate_specs(key)
	result.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a["id"]) < String(b["id"])
	)
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
