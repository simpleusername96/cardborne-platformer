class_name VehicleFieldSurfacePatternCompiler
extends RefCounted

## Deterministically compiles presentation-only field panels. The caller keeps
## collision, navigation, cover, and terrain truth in their existing owners.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const MODULE_SIZE := 288.0
const GUTTER := 12.0
const CHAMFER := 18.0
const INSET_MARGIN := 30.0
const SERVICE_RAIL_WIDTH := 5.0
const MAX_SERVICE_RAILS := 24
const PLAYER_DETAIL_CLEARANCE := 420.0
const PANEL_ALPHA_MIN := 0.34
const PANEL_ALPHA_STEP := 0.04
const PANEL_ALPHA_MAX := PANEL_ALPHA_MIN + PANEL_ALPHA_STEP * 3.0
const MODULE_CELL_SIZES: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(1, 2),
	Vector2i(2, 2),
]


static func compile(
	field_id: StringName,
	layout_fingerprint: int,
	walkable_rects: Array[Rect2],
	void_rects: Array[Rect2],
	cover_rects: Array[Rect2],
	player_start: Vector2
) -> Dictionary:
	var modules: Array[Dictionary] = []
	var layers: Array[Dictionary] = []
	if walkable_rects.is_empty():
		return _empty_contract()

	var cell_bounds := _cell_bounds(walkable_rects)
	var available := {}
	for cell_y in range(cell_bounds.position.y, cell_bounds.end.y):
		for cell_x in range(cell_bounds.position.x, cell_bounds.end.x):
			var cell := Vector2i(cell_x, cell_y)
			var panel_rect := _module_rect(cell, Vector2i.ONE).grow(-GUTTER * 0.5)
			if not _surface_fragments(
				panel_rect,
				walkable_rects,
				void_rects
			).is_empty():
				available[cell] = true

	var claimed := {}
	for cell_y in range(cell_bounds.position.y, cell_bounds.end.y):
		for cell_x in range(cell_bounds.position.x, cell_bounds.end.x):
			var cell := Vector2i(cell_x, cell_y)
			if not available.has(cell) or claimed.has(cell):
				continue
			var cell_hash := _cell_hash(
				field_id,
				layout_fingerprint,
				cell
			)
			var selected_size := Vector2i.ONE
			for candidate_size in _candidate_sizes(
				field_id,
				cell_hash,
				cell
			):
				if _can_place(
					cell,
					candidate_size,
					available,
					claimed,
					walkable_rects,
					void_rects
				):
					selected_size = candidate_size
					break
			for offset_y in selected_size.y:
				for offset_x in selected_size.x:
					claimed[cell + Vector2i(offset_x, offset_y)] = true
			var module := _module_descriptor(
				field_id,
				cell,
				selected_size,
				cell_hash,
				walkable_rects,
				void_rects,
				cover_rects,
				player_start
			)
			if not Array(module.get("fragments", [])).is_empty():
				modules.append(module)

	_assign_service_rails(modules)
	var type_counts := {}
	var module_records: Array[Dictionary] = []
	var service_rail_count := 0
	for module_index in modules.size():
		var module := modules[module_index]
		var module_type := String(module["type"])
		type_counts[module_type] = int(type_counts.get(module_type, 0)) + 1
		for fragment_value in Array(module["fragments"]):
			var fragment := Rect2(fragment_value)
			layers.append({
				"kind": &"panel",
				"module_index": module_index,
				"points": Art.stepped_rect(fragment, CHAMFER),
				"color": _panel_color(int(module["variant"])),
			})
		if bool(module["has_inset"]):
			var inset_rect := Rect2(module["panel_rect"]).grow(-INSET_MARGIN)
			if inset_rect.has_area():
				layers.append({
					"kind": &"inset",
					"module_index": module_index,
					"points": Art.stepped_rect(inset_rect, CHAMFER * 0.55),
					"color": Color(Art.SPACE_BLACK, 0.18),
				})
		if bool(module["has_service_rail"]):
			service_rail_count += 1
			layers.append({
				"kind": &"service_rail",
				"module_index": module_index,
				"points": _service_rail_points(field_id, module),
				"color": Color(_field_accent(field_id), 0.26),
			})
		module_records.append({
			"cell": module["cell"],
			"size": module["size"],
			"variant": module["variant"],
			"orientation": module["orientation"],
			"fragments": module["fragments"],
			"has_inset": module["has_inset"],
			"has_service_rail": module["has_service_rail"],
		})

	return {
		"presentation_only": true,
		"hash_inputs": PackedStringArray([
			"field_id",
			"layout_fingerprint",
			"cell_x",
			"cell_y",
		]),
		"module_size": MODULE_SIZE,
		"gutter": GUTTER,
		"panel_alpha_range": Vector2(PANEL_ALPHA_MIN, PANEL_ALPHA_MAX),
		"allowed_module_sizes": MODULE_CELL_SIZES.duplicate(),
		"modules": modules,
		"module_count": modules.size(),
		"module_type_counts": type_counts,
		"layers": layers,
		"service_rail_count": service_rail_count,
		"service_rail_budget": MAX_SERVICE_RAILS,
		"fingerprint": var_to_str(module_records).sha256_text(),
	}


static func _empty_contract() -> Dictionary:
	return {
		"presentation_only": true,
		"hash_inputs": PackedStringArray([
			"field_id",
			"layout_fingerprint",
			"cell_x",
			"cell_y",
		]),
		"module_size": MODULE_SIZE,
		"gutter": GUTTER,
		"panel_alpha_range": Vector2(PANEL_ALPHA_MIN, PANEL_ALPHA_MAX),
		"allowed_module_sizes": MODULE_CELL_SIZES.duplicate(),
		"modules": [],
		"module_count": 0,
		"module_type_counts": {},
		"layers": [],
		"service_rail_count": 0,
		"service_rail_budget": MAX_SERVICE_RAILS,
		"fingerprint": var_to_str([]).sha256_text(),
	}


static func _module_descriptor(
	field_id: StringName,
	cell: Vector2i,
	size: Vector2i,
	cell_hash: int,
	walkable_rects: Array[Rect2],
	void_rects: Array[Rect2],
	cover_rects: Array[Rect2],
	player_start: Vector2
) -> Dictionary:
	var raw_rect := _module_rect(cell, size)
	var panel_rect := raw_rect.grow(-GUTTER * 0.5)
	var fragments := _surface_fragments(
		panel_rect,
		walkable_rects,
		void_rects
	)
	var detail_safe := (
		is_equal_approx(_rects_area(fragments), panel_rect.get_area())
		and not _intersects_any(panel_rect, cover_rects)
		and not _circle_overlaps_rect(
			player_start,
			PLAYER_DETAIL_CLEARANCE,
			panel_rect
		)
	)
	var variant := posmod(cell_hash, 4)
	return {
		"cell": cell,
		"size": size,
		"type": _module_type(size),
		"rect": raw_rect,
		"panel_rect": panel_rect,
		"fragments": fragments,
		"variant": variant,
		"orientation": posmod(cell_hash >> 5, 4) * 90,
		"rail_score": posmod(cell_hash >> 11, 104729),
		"detail_safe": detail_safe,
		"has_inset": detail_safe and variant in [1, 3],
		"has_service_rail": false,
	}


static func _assign_service_rails(modules: Array[Dictionary]) -> void:
	var candidates: Array[int] = []
	for index in modules.size():
		if bool(modules[index]["detail_safe"]):
			candidates.append(index)
	candidates.sort_custom(
		func(left: int, right: int) -> bool:
			var left_module := modules[left]
			var right_module := modules[right]
			var left_score := int(left_module["rail_score"])
			var right_score := int(right_module["rail_score"])
			if left_score != right_score:
				return left_score < right_score
			var left_cell := Vector2i(left_module["cell"])
			var right_cell := Vector2i(right_module["cell"])
			return (
				left_cell.y < right_cell.y
				or (
					left_cell.y == right_cell.y
					and left_cell.x < right_cell.x
				)
			)
	)
	var target_count := mini(
		MAX_SERVICE_RAILS,
		maxi(1, ceili(float(modules.size()) / 8.0))
	)
	for selection_index in mini(target_count, candidates.size()):
		modules[candidates[selection_index]]["has_service_rail"] = true


static func _candidate_sizes(
	field_id: StringName,
	cell_hash: int,
	cell: Vector2i
) -> Array[Vector2i]:
	match field_id:
		&"tidal_archive_field":
			if posmod(cell_hash, 5) == 0:
				return [Vector2i.ONE, Vector2i(2, 1)]
			return [Vector2i(2, 1), Vector2i.ONE]
		&"storm_drydock_field":
			if posmod(cell.x + cell.y + posmod(cell_hash, 2), 2) == 0:
				return [
					Vector2i(2, 2),
					Vector2i(1, 2),
					Vector2i.ONE,
				]
			return [
				Vector2i(1, 2),
				Vector2i(2, 2),
				Vector2i.ONE,
			]
		_:
			if posmod(cell_hash, 5) == 0:
				return [Vector2i.ONE, Vector2i(2, 2)]
			return [Vector2i(2, 2), Vector2i.ONE]


static func _can_place(
	cell: Vector2i,
	size: Vector2i,
	available: Dictionary,
	claimed: Dictionary,
	walkable_rects: Array[Rect2],
	void_rects: Array[Rect2]
) -> bool:
	for offset_y in size.y:
		for offset_x in size.x:
			var occupied_cell := cell + Vector2i(offset_x, offset_y)
			if (
				not available.has(occupied_cell)
				or claimed.has(occupied_cell)
			):
				return false
	if size == Vector2i.ONE:
		return true
	var panel_rect := _module_rect(cell, size).grow(-GUTTER * 0.5)
	return is_equal_approx(
		_rects_area(_surface_fragments(
			panel_rect,
			walkable_rects,
			void_rects
		)),
		panel_rect.get_area()
	)


static func _surface_fragments(
	panel_rect: Rect2,
	walkable_rects: Array[Rect2],
	void_rects: Array[Rect2]
) -> Array[Rect2]:
	var x_values: Array[float] = [
		panel_rect.position.x,
		panel_rect.end.x,
	]
	var y_values: Array[float] = [
		panel_rect.position.y,
		panel_rect.end.y,
	]
	for rectangle in walkable_rects:
		_append_partition_edges(
			x_values,
			y_values,
			panel_rect,
			rectangle
		)
	for rectangle in void_rects:
		_append_partition_edges(
			x_values,
			y_values,
			panel_rect,
			rectangle
		)
	x_values = _sorted_unique(x_values)
	y_values = _sorted_unique(y_values)

	var result: Array[Rect2] = []
	var active: Array[Rect2] = []
	for y_index in y_values.size() - 1:
		var row_rects: Array[Rect2] = []
		var run_start := -1
		for x_index in x_values.size() - 1:
			var atom := Rect2(
				Vector2(x_values[x_index], y_values[y_index]),
				Vector2(
					x_values[x_index + 1] - x_values[x_index],
					y_values[y_index + 1] - y_values[y_index]
				)
			)
			var occupied := (
				atom.has_area()
				and _point_in_surface(
					atom.get_center(),
					walkable_rects,
					void_rects
				)
			)
			if occupied and run_start < 0:
				run_start = x_index
			var run_ends := (
				run_start >= 0
				and (
					not occupied
					or x_index == x_values.size() - 2
				)
			)
			if not run_ends:
				continue
			var end_index := x_index + 1 if occupied else x_index
			row_rects.append(Rect2(
				Vector2(x_values[run_start], y_values[y_index]),
				Vector2(
					x_values[end_index] - x_values[run_start],
					y_values[y_index + 1] - y_values[y_index]
				)
			))
			run_start = -1

		var continued := PackedByteArray()
		continued.resize(active.size())
		var next_active: Array[Rect2] = []
		for row_rect in row_rects:
			var matching_index := -1
			for active_index in active.size():
				var candidate := active[active_index]
				if (
					continued[active_index] == 0
					and is_equal_approx(
						candidate.position.x,
						row_rect.position.x
					)
					and is_equal_approx(
						candidate.size.x,
						row_rect.size.x
					)
					and is_equal_approx(
						candidate.end.y,
						row_rect.position.y
					)
				):
					matching_index = active_index
					break
			if matching_index < 0:
				next_active.append(row_rect)
				continue
			var continued_rect := active[matching_index]
			continued_rect.size.y += row_rect.size.y
			next_active.append(continued_rect)
			continued[matching_index] = 1
		for active_index in active.size():
			if continued[active_index] == 0:
				result.append(active[active_index])
		active = next_active
	result.append_array(active)
	return result


static func _append_partition_edges(
	x_values: Array[float],
	y_values: Array[float],
	panel_rect: Rect2,
	rectangle: Rect2
) -> void:
	if not panel_rect.intersects(rectangle, true):
		return
	x_values.append(clampf(
		rectangle.position.x,
		panel_rect.position.x,
		panel_rect.end.x
	))
	x_values.append(clampf(
		rectangle.end.x,
		panel_rect.position.x,
		panel_rect.end.x
	))
	y_values.append(clampf(
		rectangle.position.y,
		panel_rect.position.y,
		panel_rect.end.y
	))
	y_values.append(clampf(
		rectangle.end.y,
		panel_rect.position.y,
		panel_rect.end.y
	))


static func _sorted_unique(values: Array[float]) -> Array[float]:
	values.sort()
	var result: Array[float] = []
	for value in values:
		if result.is_empty() or not is_equal_approx(result[-1], value):
			result.append(value)
	return result


static func _cell_bounds(walkable_rects: Array[Rect2]) -> Rect2i:
	var bounds := walkable_rects[0]
	for index in range(1, walkable_rects.size()):
		bounds = bounds.merge(walkable_rects[index])
	var minimum := Vector2i(
		floori(bounds.position.x / MODULE_SIZE),
		floori(bounds.position.y / MODULE_SIZE)
	)
	var maximum := Vector2i(
		ceili(bounds.end.x / MODULE_SIZE),
		ceili(bounds.end.y / MODULE_SIZE)
	)
	return Rect2i(minimum, maximum - minimum)


static func _module_rect(cell: Vector2i, size: Vector2i) -> Rect2:
	return Rect2(
		Vector2(cell) * MODULE_SIZE,
		Vector2(size) * MODULE_SIZE
	)


static func _module_type(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]


static func _cell_hash(
	field_id: StringName,
	layout_fingerprint: int,
	cell: Vector2i
) -> int:
	var source := "%s|%d|%d|%d" % [
		String(field_id),
		layout_fingerprint,
		cell.x,
		cell.y,
	]
	return source.sha256_text().substr(0, 12).hex_to_int()


static func _panel_color(variant: int) -> Color:
	return Color(
		Art.RAISED,
		PANEL_ALPHA_MIN + float(variant) * PANEL_ALPHA_STEP
	)


static func _service_rail_points(
	field_id: StringName,
	module: Dictionary
) -> PackedVector2Array:
	var rectangle := Rect2(module["panel_rect"]).grow(-42.0)
	var orientation := int(module["orientation"])
	match field_id:
		&"tidal_archive_field":
			var y_offset := (
				-rectangle.size.y * 0.16
				if orientation in [0, 90]
				else rectangle.size.y * 0.16
			)
			return _line_quad(
				Vector2(rectangle.position.x, rectangle.get_center().y + y_offset),
				Vector2(rectangle.end.x, rectangle.get_center().y + y_offset),
				SERVICE_RAIL_WIDTH
			)
		&"storm_drydock_field":
			var descends := orientation in [0, 180]
			return _line_quad(
				(
					rectangle.position
					if descends
					else Vector2(rectangle.position.x, rectangle.end.y)
				),
				(
					rectangle.end
					if descends
					else Vector2(rectangle.end.x, rectangle.position.y)
				),
				SERVICE_RAIL_WIDTH
			)
		_:
			if orientation in [0, 180]:
				return _line_quad(
					Vector2(rectangle.position.x, rectangle.get_center().y),
					Vector2(rectangle.end.x, rectangle.get_center().y),
					SERVICE_RAIL_WIDTH
				)
			return _line_quad(
				Vector2(rectangle.get_center().x, rectangle.position.y),
				Vector2(rectangle.get_center().x, rectangle.end.y),
				SERVICE_RAIL_WIDTH
			)


static func _line_quad(
	from: Vector2,
	to: Vector2,
	width: float
) -> PackedVector2Array:
	var vector := to - from
	if vector.is_zero_approx():
		return PackedVector2Array()
	var side := vector.normalized().rotated(PI * 0.5) * width * 0.5
	return PackedVector2Array([
		from - side,
		to - side,
		to + side,
		from + side,
	])


static func _point_in_surface(
	point: Vector2,
	walkable_rects: Array[Rect2],
	void_rects: Array[Rect2]
) -> bool:
	var walkable := false
	for rectangle in walkable_rects:
		if rectangle.has_point(point):
			walkable = true
			break
	if not walkable:
		return false
	for rectangle in void_rects:
		if rectangle.has_point(point):
			return false
	return true


static func _intersects_any(
	rectangle: Rect2,
	rectangles: Array[Rect2]
) -> bool:
	for other in rectangles:
		if rectangle.intersects(other, true):
			return true
	return false


static func _circle_overlaps_rect(
	center: Vector2,
	radius: float,
	rectangle: Rect2
) -> bool:
	var closest := Vector2(
		clampf(center.x, rectangle.position.x, rectangle.end.x),
		clampf(center.y, rectangle.position.y, rectangle.end.y)
	)
	return center.distance_squared_to(closest) < radius * radius


static func _rects_area(rectangles: Array[Rect2]) -> float:
	var result := 0.0
	for rectangle in rectangles:
		result += rectangle.get_area()
	return result


static func _field_accent(field_id: StringName) -> Color:
	match field_id:
		&"tidal_archive_field":
			return Art.SUPPORT
		&"storm_drydock_field":
			return Art.PLAYER_REWARD
	return Art.SYSTEM
