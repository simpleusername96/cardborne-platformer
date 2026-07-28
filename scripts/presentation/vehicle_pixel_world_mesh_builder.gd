class_name VehiclePixelWorldMeshBuilder
extends Node2D

## Geometry-fed pixel world presentation. Authoritative floor, water, cover,
## and boundary segments stay owned by stage layout data; this node only
## rebuilds repeat-textured visual chunks when that immutable fingerprint
## changes.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const StampCatalog = preload(
	"res://scripts/presentation/vehicle_world_stamp_catalog.gd"
)

const FLOOR_TEXTURE := preload("res://pixel-art-production/runtime/tiles/hangar-floor.png")
const WALL_TEXTURE := preload("res://pixel-art-production/runtime/tiles/hangar-wall.png")
const WATER_TEXTURE := preload("res://pixel-art-production/runtime/tiles/hangar-water.png")
const TILE_VARIATION_SHADER := preload(
	"res://shaders/space_hangar_tile_variation.gdshader"
)
# The approved 192 px material masters render at a quiet 384 world-pixel period,
# keeping their authored 1 px details on a crisp 2 world-pixel grid.
const REPEAT_TILE_UV_SCALE := 0.5
const DECORATION_BUDGET := 48
const STRUCTURE_COUNT := 28
const PROP_COUNT := 10
const WEAR_COUNT := 4
const FLOOR_CLEARANCE := 640.0
const FLOOR_DECORATION_SPACING := 180.0

var _stage_id: StringName = &""
var _layout_fingerprint := -1
var _chunk_count := 0
var _decoration_count := 0
var _decoration_roles := {
	&"structure":0,
	&"prop":0,
	&"wear":0,
}
var _decoration_anchors: Dictionary = {}
var _decoration_records: Array[Dictionary] = []
var _decoration_errors := PackedStringArray()
var _tile_variation_material: ShaderMaterial


func configure(stage_id: StringName, layout: Object) -> void:
	var fingerprint := int(layout.fingerprint) if layout != null else 0
	if _stage_id == stage_id and _layout_fingerprint == fingerprint:
		return
	_stage_id = stage_id
	_layout_fingerprint = fingerprint
	_rebuild(layout)


func debug_contract() -> Dictionary:
	return {
		"stage_id":_stage_id,
		"layout_fingerprint":_layout_fingerprint,
		"chunk_count":_chunk_count,
		"chunk_budget_ok":_chunk_count <= 60,
		"decoration_count":_decoration_count,
		"decoration_budget":DECORATION_BUDGET,
		"decoration_budget_ok":_decoration_count <= DECORATION_BUDGET,
		"decoration_roles":_decoration_roles.duplicate(),
		"decoration_anchors":_decoration_anchors.duplicate(),
		"decoration_records":_decoration_records.duplicate(true),
		"decoration_errors":_decoration_errors.duplicate(),
		"stamp_catalog":StampCatalog.debug_contract(),
		"geometry_fed":true,
		"collision_owner":"vehicle_stage_geometry",
		"decoration_collision_nodes":0,
		"repeat_tile_uv_scale":REPEAT_TILE_UV_SCALE,
		"deterministic_tile_variation":_tile_variation_material != null,
		"tile_variation_period":384.0,
	}


func _rebuild(layout: Object) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_chunk_count = 0
	_decoration_count = 0
	_decoration_roles = {
		&"structure":0,
		&"prop":0,
		&"wear":0,
	}
	_decoration_anchors.clear()
	_decoration_records.clear()
	_decoration_errors.clear()
	_tile_variation_material = ShaderMaterial.new()
	_tile_variation_material.shader = TILE_VARIATION_SHADER
	_tile_variation_material.set_shader_parameter(
		"variation_seed",
		float(posmod(_layout_fingerprint, 997))
	)
	for region in Rules.get_floor_regions(_stage_id):
		_add_polygon(
			PackedVector2Array(region["polygon"]),
			FLOOR_TEXTURE,
			Color.WHITE
		)
	for water in Rules.get_water_rects(_stage_id):
		_add_polygon(
			PackedVector2Array(StageGeometry.rect_polygon(water)),
			WATER_TEXTURE,
			Color.WHITE
		)
	for polygon in Rules.get_cover_polygons(false, _stage_id):
		_add_polygon(PackedVector2Array(polygon), WALL_TEXTURE, Color.WHITE, 2)
	if layout != null:
		for rectangle in layout.cover_rects:
			_add_polygon(
				PackedVector2Array(StageGeometry.rect_polygon(rectangle)),
				WALL_TEXTURE,
				Color.WHITE,
				2
			)
		var segments: PackedVector2Array = layout.geometry_snapshot.wall_segments
		_add_boundary_batch(segments, Art.WALL_SHADOW_OFFSET, Art.WALL_SHADOW, 0)
		_add_boundary_batch(segments, Vector2.ZERO, Art.WALL_FILL, 1)
		_add_decorations(layout)


func _add_polygon(
	points: PackedVector2Array,
	texture: Texture2D,
	color: Color,
	child_z: int = 0
) -> void:
	if points.size() < 3:
		return
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.texture = texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	polygon.texture_scale = Vector2.ONE * REPEAT_TILE_UV_SCALE
	polygon.material = _tile_variation_material
	polygon.color = color
	polygon.z_index = child_z
	add_child(polygon)
	_chunk_count += 1


func _add_boundary_batch(
	segments: PackedVector2Array,
	offset: Vector2,
	color: Color,
	child_z: int
) -> void:
	var segment_count := segments.size() / 2
	if segment_count <= 0:
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.instance_count = segment_count
	multimesh.visible_instance_count = segment_count
	multimesh.mesh = Visuals.pixel_quad_mesh()
	multimesh.custom_aabb = AABB(
		Vector3(-8192.0, -8192.0, -1.0),
		Vector3(16384.0, 16384.0, 2.0)
	)
	for index in segment_count:
		var from := segments[index * 2] + offset
		var to := segments[index * 2 + 1] + offset
		var vector := to - from
		var length := vector.length()
		if length <= 0.001:
			continue
		var direction := vector / length
		var perpendicular := direction.rotated(PI * 0.5)
		multimesh.set_instance_transform_2d(
			index,
			Transform2D(
				direction * (length * 0.5),
				perpendicular * (Art.WALL_RAIL_WIDTH * 0.5),
				from + vector * 0.5
			)
		)
		multimesh.set_instance_color(index, color)
	var instance := MultiMeshInstance2D.new()
	instance.multimesh = multimesh
	instance.z_index = child_z
	add_child(instance)
	_chunk_count += 1


func _add_decorations(layout: Object) -> void:
	var snapshot: Object = layout.geometry_snapshot
	var player_start := Vector2(snapshot.get("player_start"))
	var boundary_candidates := _boundary_candidates(
		PackedVector2Array(snapshot.get("wall_segments")),
		player_start
	)
	var boundary_cursor := 0
	while boundary_cursor < boundary_candidates.size() and _role_count(&"structure") < 16:
		_add_boundary_stamp(boundary_candidates[boundary_cursor])
		boundary_cursor += 1
	var covers: Array[Rect2] = []
	covers.assign(layout.cover_rects)
	covers.sort_custom(
		func(left: Rect2, right: Rect2) -> bool:
			return _rect_order(left, right, player_start)
	)
	for cover in covers.slice(0, mini(8, covers.size())):
		var stamp_id := &"cover_wide" if cover.size.x >= 320.0 else &"cover_small"
		_add_stamp(
			stamp_id,
			&"cover",
			cover.get_center(),
			Vector2(
				minf(cover.size.x * 0.82, 256.0) / 64.0,
				minf(cover.size.y * 0.72, 144.0) / 64.0
			),
			2
		)
	var zones: Array = Array(snapshot.get("terrain_zones"))
	for zone_value in zones:
		var zone := Dictionary(zone_value)
		if (
			StringName(zone.get("kind", &"")) != &"breakable_bulkhead"
			or not zone.has("rect")
		):
			continue
		var rectangle := Rect2(zone["rect"])
		var horizontal := rectangle.size.x >= rectangle.size.y
		_add_stamp(
			&"bulkhead_h" if horizontal else &"bulkhead_v",
			&"bulkhead",
			rectangle.get_center(),
			Vector2(
				minf(rectangle.size.x, 224.0) / 64.0,
				minf(rectangle.size.y, 224.0) / 64.0
			),
			2
		)
		if _anchor_count(&"bulkhead") >= 2:
			break
	var feature_slots: Array[Dictionary] = []
	for zone_value in zones:
		var zone := Dictionary(zone_value)
		if StringName(zone.get("kind", &"")) != &"arc_surge" or not zone.has("rect"):
			continue
		var rectangle := Rect2(zone["rect"])
		var horizontal := rectangle.size.x >= rectangle.size.y
		var axis := Vector2.RIGHT if horizontal else Vector2.DOWN
		var slot_count := mini(2 - feature_slots.size(), 2)
		for index in slot_count:
			var offset := (
				(float(index) - float(slot_count - 1) * 0.5)
				* minf(rectangle.size.x if horizontal else rectangle.size.y, 420.0)
				* 0.42
			)
			feature_slots.append({
				"position":rectangle.get_center() + axis * offset,
				"horizontal":horizontal,
			})
		if feature_slots.size() >= 2:
			break
	for slot in feature_slots:
		var horizontal := bool(slot["horizontal"])
		_add_stamp(
			&"service_bay_h" if horizontal else &"service_bay_v",
			&"feature",
			Vector2(slot["position"]),
			Vector2(2.6, 1.6) if horizontal else Vector2(1.6, 2.6),
			2
		)
	while (
		boundary_cursor < boundary_candidates.size()
		and _role_count(&"structure") < STRUCTURE_COUNT
	):
		_add_boundary_stamp(boundary_candidates[boundary_cursor])
		boundary_cursor += 1
	var floor_positions := _floor_decoration_positions(snapshot, covers, player_start)
	var prop_ids: Array[StringName] = [
		&"hatch_round",
		&"vent_round",
		&"console_small",
		&"console_wide",
		&"cargo_small",
		&"cargo_wide",
		&"machinery_small",
		&"machinery_tall",
		&"warning_plate",
		&"terminal",
	]
	for index in mini(PROP_COUNT, floor_positions.size()):
		_add_stamp(
			prop_ids[index],
			&"floor_flat",
			floor_positions[index],
			Vector2.ONE * 2.0,
			3
		)
	var wear_ids: Array[StringName] = [
		&"wear_scrape_a",
		&"wear_scrape_b",
		&"wear_chip_a",
		&"wear_chip_b",
	]
	for index in WEAR_COUNT:
		var position_index := PROP_COUNT + index
		if position_index >= floor_positions.size():
			break
		_add_stamp(
			wear_ids[index],
			&"floor_flat",
			floor_positions[position_index],
			Vector2.ONE * 2.0,
			0
		)
	if _role_count(&"structure") != STRUCTURE_COUNT:
		_decoration_errors.append("Structure decoration count is not 28.")
	if _role_count(&"prop") != PROP_COUNT:
		_decoration_errors.append("Prop decoration count is not 10.")
	if _role_count(&"wear") != WEAR_COUNT:
		_decoration_errors.append("Wear decoration count is not 4.")


func _add_boundary_stamp(candidate: Dictionary) -> void:
	var horizontal := bool(candidate["horizontal"])
	var index := _anchor_count(&"boundary")
	var ids := (
		[&"frame_h", &"rail_h", &"inner_cap_h"]
		if horizontal
		else [&"frame_v", &"rail_v", &"inner_cap_v"]
	)
	var segment_length := float(candidate["length"])
	var scale := (
		Vector2(clampf(segment_length / 64.0, 1.5, 2.8), 2.0)
		if horizontal
		else Vector2(2.0, clampf(segment_length / 64.0, 1.5, 2.8))
	)
	_add_stamp(
		ids[index % ids.size()],
		&"boundary",
		Vector2(candidate["position"]),
		scale,
		2
	)


func _add_stamp(
	stamp_id: StringName,
	anchor: StringName,
	position: Vector2,
	stamp_scale: Vector2,
	child_z: int
) -> void:
	if _decoration_count >= DECORATION_BUDGET:
		_decoration_errors.append("Decoration budget exceeded.")
		return
	var stamp := StampCatalog.stamp(stamp_id)
	if stamp.is_empty():
		_decoration_errors.append("Unknown stamp: %s" % stamp_id)
		return
	if StringName(stamp["allowed_anchor"]) != anchor:
		_decoration_errors.append(
			"Stamp %s cannot use anchor %s." % [stamp_id, anchor]
		)
		return
	var texture := stamp["texture"] as Texture2D
	if texture == null:
		_decoration_errors.append("Stamp texture is missing: %s" % stamp_id)
		return
	var sprite := Sprite2D.new()
	sprite.name = "Decoration%02d_%s" % [_decoration_count + 1, stamp_id]
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(stamp["region"])
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = position
	sprite.scale = stamp_scale
	sprite.z_index = child_z
	add_child(sprite)
	var role := StringName(stamp["role"])
	_decoration_count += 1
	_decoration_roles[role] = _role_count(role) + 1
	_decoration_anchors[anchor] = _anchor_count(anchor) + 1
	_decoration_records.append({
		"stamp_id":stamp_id,
		"role":role,
		"anchor":anchor,
		"position":position,
		"scale":stamp_scale,
	})


func _boundary_candidates(
	segments: PackedVector2Array,
	player_start: Vector2
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in segments.size() / 2:
		var from := segments[index * 2]
		var to := segments[index * 2 + 1]
		var vector := to - from
		if vector.length_squared() <= 1.0:
			continue
		result.append({
			"position":from + vector * 0.5,
			"length":vector.length(),
			"horizontal":absf(vector.x) >= absf(vector.y),
			"distance":(from + vector * 0.5).distance_squared_to(player_start),
		})
	result.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			var left_distance := float(left["distance"])
			var right_distance := float(right["distance"])
			if not is_equal_approx(left_distance, right_distance):
				return left_distance < right_distance
			var left_position := Vector2(left["position"])
			var right_position := Vector2(right["position"])
			return (
				left_position.y < right_position.y
				or (
					is_equal_approx(left_position.y, right_position.y)
					and left_position.x < right_position.x
				)
			)
	)
	return result


func _floor_decoration_positions(
	snapshot: Object,
	covers: Array[Rect2],
	player_start: Vector2
) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	for rectangle_value in Array(snapshot.get("walkable_rects")):
		var rectangle := Rect2(rectangle_value)
		for normalized_y in [0.16, 0.32, 0.5, 0.68, 0.84]:
			for normalized_x in [0.16, 0.32, 0.5, 0.68, 0.84]:
				candidates.append(
					rectangle.position
					+ rectangle.size * Vector2(normalized_x, normalized_y)
				)
	candidates.sort_custom(
		func(left: Vector2, right: Vector2) -> bool:
			var left_distance := left.distance_squared_to(player_start)
			var right_distance := right.distance_squared_to(player_start)
			if not is_equal_approx(left_distance, right_distance):
				return left_distance < right_distance
			return left.y < right.y or (
				is_equal_approx(left.y, right.y) and left.x < right.x
			)
	)
	var result: Array[Vector2] = []
	for position in candidates:
		if position.distance_to(player_start) < FLOOR_CLEARANCE:
			continue
		if _point_in_any_rect(position, covers, 72.0):
			continue
		if _point_in_any_rect(
			position,
			_typed_rects(Array(snapshot.get("water_rects"))),
			72.0
		):
			continue
		var too_close := false
		for selected in result:
			if selected.distance_to(position) < FLOOR_DECORATION_SPACING:
				too_close = true
				break
		if too_close:
			continue
		result.append(position)
		if result.size() >= PROP_COUNT + WEAR_COUNT:
			break
	return result


func _typed_rects(values: Array) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for value in values:
		result.append(Rect2(value))
	return result


func _point_in_any_rect(
	position: Vector2,
	rectangles: Array[Rect2],
	margin: float
) -> bool:
	for rectangle in rectangles:
		if rectangle.grow(margin).has_point(position):
			return true
	return false


func _rect_order(left: Rect2, right: Rect2, origin: Vector2) -> bool:
	var left_distance := left.get_center().distance_squared_to(origin)
	var right_distance := right.get_center().distance_squared_to(origin)
	if not is_equal_approx(left_distance, right_distance):
		return left_distance < right_distance
	return left.position.y < right.position.y or (
		is_equal_approx(left.position.y, right.position.y)
		and left.position.x < right.position.x
	)


func _role_count(role: StringName) -> int:
	return int(_decoration_roles.get(role, 0))


func _anchor_count(anchor: StringName) -> int:
	return int(_decoration_anchors.get(anchor, 0))
