class_name VehicleStageTacticalLayout
extends RefCounted

## Immutable stage-scoped placement truth shared by simulation and presentation.

const BROADPHASE_CELL_SIZE := 320.0
const BROADPHASE_MARGIN := 96.0
const FAST_MOTION_CELL_SIZE := 80.0
const FAST_MOTION_RADIUS := 36.0
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
var _safe_motion_cells_36: Dictionary = {}
var _fast_motion_min_cell := Vector2i.ZERO
var _fast_motion_width := 0
var _fast_motion_height := 0


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
	_build_fast_motion_clearance_mask()
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


func is_fast_motion_clear(from: Vector2, to: Vector2, radius: float) -> bool:
	## Returns true only for a same-cell sweep certified against this run's
	## selected covers and functional terrain. Larger actors and cross-cell
	## motion intentionally stay on the exact solver path.
	if geometry_snapshot == null or radius > FAST_MOTION_RADIUS:
		return false
	var from_cell := _fast_motion_cell(from)
	var to_cell := _fast_motion_cell(to)
	if (
		from_cell.x < _fast_motion_min_cell.x
		or from_cell.y < _fast_motion_min_cell.y
		or from_cell.x >= _fast_motion_min_cell.x + _fast_motion_width
		or from_cell.y >= _fast_motion_min_cell.y + _fast_motion_height
	):
		return false
	return from_cell == to_cell and bool(_safe_motion_cells_36.get(from_cell, false))


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
		"fast_motion_cell_size":FAST_MOTION_CELL_SIZE,
		"fast_motion_radius":FAST_MOTION_RADIUS,
		"fast_motion_safe_cell_count":_safe_motion_cells_36.size(),
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


func _build_fast_motion_clearance_mask() -> void:
	_safe_motion_cells_36.clear()
	if geometry_snapshot == null:
		_fast_motion_width = 0
		_fast_motion_height = 0
		return
	var bounds := geometry_snapshot.world_rect
	_fast_motion_min_cell = Vector2i(
		floori(bounds.position.x / FAST_MOTION_CELL_SIZE),
		floori(bounds.position.y / FAST_MOTION_CELL_SIZE)
	)
	var max_cell := Vector2i(
		floori((bounds.end.x - 1.0) / FAST_MOTION_CELL_SIZE),
		floori((bounds.end.y - 1.0) / FAST_MOTION_CELL_SIZE)
	)
	_fast_motion_width = max_cell.x - _fast_motion_min_cell.x + 1
	_fast_motion_height = max_cell.y - _fast_motion_min_cell.y + 1
	for cell_y in range(_fast_motion_min_cell.y, max_cell.y + 1):
		for cell_x in range(_fast_motion_min_cell.x, max_cell.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			var clearance_rect := Rect2(
				Vector2(cell) * FAST_MOTION_CELL_SIZE,
				Vector2.ONE * FAST_MOTION_CELL_SIZE
			).grow(FAST_MOTION_RADIUS)
			var inside_floor := false
			for floor_rect in geometry_snapshot.walkable_rects:
				if floor_rect.encloses(clearance_rect):
					inside_floor = true
					break
			if not inside_floor:
				continue
			var blocked := false
			for cover in geometry_snapshot.selected_cover_rects:
				if clearance_rect.intersects(cover, true):
					blocked = true
					break
			if blocked:
				continue
			for void_rect in geometry_snapshot.void_rects:
				if clearance_rect.intersects(void_rect, true):
					blocked = true
					break
			if blocked:
				continue
			for feature in geometry_snapshot.terrain_zones:
				if StringName(feature.get("kind", &"")) not in [&"structural_wall", &"breakable_bulkhead"]:
					continue
				if clearance_rect.intersects(Rect2(feature.get("rect", Rect2())), true):
					blocked = true
					break
			if not blocked:
				_safe_motion_cells_36[cell] = true


func _fast_motion_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / FAST_MOTION_CELL_SIZE),
		floori(position.y / FAST_MOTION_CELL_SIZE)
	)


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / BROADPHASE_CELL_SIZE),
		floori(position.y / BROADPHASE_CELL_SIZE)
	)
