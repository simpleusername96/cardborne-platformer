class_name VehicleRewardFacilityVisualRecipes
extends RefCounted

## Normalized, presentation-only recipes for rewards, pickups, and facilities.
## Callers provide semantic colors and scale; gameplay geometry stays elsewhere.

const REWARD_IDS: Array[StringName] = [
	&"reward_crate",
	&"experience_small",
	&"experience_medium",
	&"experience_large",
	&"repair",
	&"experience_recall",
]

const FACILITY_IDS: Array[StringName] = [
	&"repair_field",
	&"transit_gate",
	&"overdrive_field",
	&"arc_surge_strip",
	&"breakable_bulkhead",
]

const VALID_PLANE_ROLES: Array[StringName] = [
	&"perimeter",
	&"main_mass",
	&"secondary_mass",
	&"function_inset",
	&"hard_highlight",
]


static func recipe_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append_array(REWARD_IDS)
	ids.append_array(FACILITY_IDS)
	return ids


static func reward_ids() -> Array[StringName]:
	return REWARD_IDS.duplicate()


static func facility_ids() -> Array[StringName]:
	return FACILITY_IDS.duplicate()


static func has_recipe(recipe_id: StringName) -> bool:
	return recipe_id in REWARD_IDS or recipe_id in FACILITY_IDS


static func recipe(recipe_id: StringName) -> Dictionary:
	match recipe_id:
		&"reward_crate":
			return _reward_crate_recipe()
		&"experience_small":
			return _experience_small_recipe()
		&"experience_medium":
			return _experience_medium_recipe()
		&"experience_large":
			return _experience_large_recipe()
		&"repair":
			return _repair_pickup_recipe()
		&"experience_recall":
			return _experience_recall_recipe()
		&"repair_field":
			return _repair_field_recipe()
		&"transit_gate":
			return _transit_gate_recipe()
		&"overdrive_field":
			return _overdrive_field_recipe()
		&"arc_surge_strip":
			return _arc_surge_strip_recipe()
		&"breakable_bulkhead":
			return _breakable_bulkhead_recipe()
	return {}


static func category(recipe_id: StringName) -> StringName:
	return StringName(recipe(recipe_id).get("category", &""))


static func shape_id(recipe_id: StringName) -> StringName:
	return StringName(recipe(recipe_id).get("shape", &""))


static func color_role(recipe_id: StringName) -> StringName:
	return StringName(recipe(recipe_id).get("color_role", &""))


static func layers(recipe_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for layer_variant in Array(recipe(recipe_id).get("layers", [])):
		var source := Dictionary(layer_variant)
		var polygons: Array[PackedVector2Array] = []
		for polygon_variant in Array(source.get("polygons", [])):
			polygons.append(PackedVector2Array(polygon_variant))
		result.append({
			"plane":StringName(source.get("plane", &"")),
			"polygons":polygons,
		})
	return result


## Flattened polygon commands can feed a retained mesh compiler directly.
static func polygon_commands(recipe_id: StringName) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	for layer in layers(recipe_id):
		var plane := StringName(layer.get("plane", &""))
		for polygon_variant in Array(layer.get("polygons", [])):
			commands.append({
				"plane":plane,
				"points":PackedVector2Array(polygon_variant),
			})
	return commands


## Resolves normalized commands for either mesh or CanvasItem adapters.
static func resolved_polygon_commands(
	recipe_id: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	var safe_scale := maxf(0.0, scale)
	for command in polygon_commands(recipe_id):
		var plane := StringName(command.get("plane", &""))
		resolved.append({
			"plane":plane,
			"points":_transform_points(
				PackedVector2Array(command.get("points", PackedVector2Array())),
				center,
				safe_scale
			),
			"color":_plane_color(plane, palette),
		})
	return resolved


## Must be invoked from the target CanvasItem's draw pass.
static func draw_recipe(
	canvas_item: CanvasItem,
	recipe_id: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> Rect2:
	for command in resolved_polygon_commands(
		recipe_id,
		center,
		scale,
		palette
	):
		canvas_item.draw_colored_polygon(
			PackedVector2Array(command.get("points", PackedVector2Array())),
			Color(command.get("color", Color.WHITE))
		)
	return transformed_bounds(recipe_id, center, scale)


static func normalized_bounds(recipe_id: StringName) -> Rect2:
	var result := Rect2()
	var has_result := false
	for command in polygon_commands(recipe_id):
		var command_bounds := _points_bounds(
			PackedVector2Array(command.get("points", PackedVector2Array()))
		)
		if not command_bounds.has_area():
			continue
		result = command_bounds if not has_result else result.merge(command_bounds)
		has_result = true
	return result


static func transformed_bounds(
	recipe_id: StringName,
	center: Vector2 = Vector2.ZERO,
	scale: float = 1.0
) -> Rect2:
	var bounds := normalized_bounds(recipe_id)
	var safe_scale := maxf(0.0, scale)
	return Rect2(
		center + bounds.position * safe_scale,
		bounds.size * safe_scale
	)


## The perimeter polygons are the grayscale silhouette signature.
static func signature(recipe_id: StringName) -> Array[PackedVector2Array]:
	for layer in layers(recipe_id):
		if StringName(layer.get("plane", &"")) != &"perimeter":
			continue
		var result: Array[PackedVector2Array] = []
		for polygon_variant in Array(layer.get("polygons", [])):
			result.append(PackedVector2Array(polygon_variant))
		return result
	return []


static func plane_roles(recipe_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for layer in layers(recipe_id):
		result.append(StringName(layer.get("plane", &"")))
	return result


static func plane_count(recipe_id: StringName) -> int:
	return layers(recipe_id).size()


static func validate_recipes() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := recipe_ids()
	if ids.size() != 11:
		errors.append("reward/facility recipe registry must contain eleven IDs")
	var seen_ids := {}
	var seen_signatures := {}
	for recipe_id in ids:
		if seen_ids.has(recipe_id):
			errors.append("duplicate reward/facility recipe ID: %s" % recipe_id)
			continue
		seen_ids[recipe_id] = true
		var visual_recipe := recipe(recipe_id)
		var recipe_layers := layers(recipe_id)
		if visual_recipe.is_empty():
			errors.append("missing reward/facility recipe: %s" % recipe_id)
			continue
		var recipe_category := category(recipe_id)
		if recipe_category not in [&"reward", &"facility"]:
			errors.append("%s has an invalid visual category" % recipe_id)
		if recipe_id in REWARD_IDS and recipe_category != &"reward":
			errors.append("%s must remain a reward recipe" % recipe_id)
		if recipe_id in FACILITY_IDS and recipe_category != &"facility":
			errors.append("%s must remain a facility recipe" % recipe_id)
		if color_role(recipe_id) == &"":
			errors.append("%s is missing a caller-owned semantic color role" % recipe_id)
		var shape := String(shape_id(recipe_id)).to_lower()
		for forbidden in ["diamond", "star", "generic", "fallback"]:
			if forbidden in shape:
				errors.append("%s uses forbidden generic identity: %s" % [recipe_id, shape])
		if recipe_layers.size() < 3 or recipe_layers.size() > 5:
			errors.append("%s must use three to five visual planes" % recipe_id)
		var seen_planes := {}
		for layer in recipe_layers:
			var plane := StringName(layer.get("plane", &""))
			if plane not in VALID_PLANE_ROLES:
				errors.append("%s has unsupported plane role: %s" % [recipe_id, plane])
			if seen_planes.has(plane):
				errors.append("%s repeats plane role: %s" % [recipe_id, plane])
			seen_planes[plane] = true
			var polygons := Array(layer.get("polygons", []))
			if polygons.is_empty():
				errors.append("%s has an empty %s plane" % [recipe_id, plane])
			for polygon_variant in polygons:
				var points := PackedVector2Array(polygon_variant)
				if points.size() < 3:
					errors.append("%s %s plane has fewer than three points" % [recipe_id, plane])
					continue
				if Geometry2D.triangulate_polygon(points).is_empty():
					errors.append("%s %s plane does not triangulate" % [recipe_id, plane])
				for point in points:
					if (
						not is_finite(point.x)
						or not is_finite(point.y)
						or absf(point.x) > 1.25
						or absf(point.y) > 1.25
					):
						errors.append("%s %s plane leaves normalized bounds" % [recipe_id, plane])
						break
		for required_plane in [&"perimeter", &"main_mass"]:
			if not seen_planes.has(required_plane):
				errors.append("%s is missing required plane %s" % [recipe_id, required_plane])
		var bounds := normalized_bounds(recipe_id)
		if not bounds.has_area():
			errors.append("%s has empty normalized bounds" % recipe_id)
		var recipe_signature := signature(recipe_id)
		if recipe_signature.is_empty():
			errors.append("%s has no perimeter silhouette signature" % recipe_id)
		else:
			var signature_key := var_to_str(recipe_signature)
			if seen_signatures.has(signature_key):
				errors.append(
					"%s duplicates the silhouette signature of %s"
					% [recipe_id, seen_signatures[signature_key]]
				)
			seen_signatures[signature_key] = recipe_id
	if not recipe(&"missing_recipe").is_empty():
		errors.append("unknown reward/facility IDs must not use a fallback recipe")
	return errors


static func _reward_crate_recipe() -> Dictionary:
	var outer := _stepped_slab(Vector2(1.0, 0.78), 0.18)
	return _make_recipe(
		&"reward",
		&"mechanical_crate_slab",
		&"player_reward",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_scale_points(outer, Vector2(0.88, 0.82))]),
			_layer(&"secondary_mass", [
				_rect(Vector2(-0.68, 0.0), Vector2(0.12, 0.48)),
				_rect(Vector2(0.68, 0.0), Vector2(0.12, 0.48)),
			]),
			_layer(&"function_inset", [
				PackedVector2Array([
					Vector2(-0.34, -0.25), Vector2(0.22, -0.25),
					Vector2(0.40, -0.06), Vector2(0.40, 0.18),
					Vector2(0.22, 0.32), Vector2(-0.34, 0.32),
					Vector2(-0.48, 0.12), Vector2(-0.48, -0.10),
				]),
			]),
			_layer(&"hard_highlight", [
				PackedVector2Array([
					Vector2(-0.48, -0.56), Vector2(0.38, -0.56),
					Vector2(0.52, -0.44), Vector2(-0.58, -0.44),
				]),
			]),
		]
	)


static func _experience_small_recipe() -> Dictionary:
	var outer := PackedVector2Array([
		Vector2(-0.18, -0.66), Vector2(0.34, -0.52),
		Vector2(0.54, -0.12), Vector2(0.28, 0.52),
		Vector2(-0.24, 0.70), Vector2(-0.50, 0.24),
		Vector2(-0.40, -0.34),
	])
	return _make_recipe(
		&"reward",
		&"mechanical_shard_tier_1",
		&"player_reward",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_scale_points(outer, Vector2(0.72, 0.76))]),
			_layer(&"hard_highlight", [
				PackedVector2Array([
					Vector2(-0.22, -0.46), Vector2(0.18, -0.36),
					Vector2(0.26, -0.20), Vector2(-0.28, -0.30),
				]),
			]),
		]
	)


static func _experience_medium_recipe() -> Dictionary:
	var outer := PackedVector2Array([
		Vector2(-0.30, -0.84), Vector2(0.34, -0.68),
		Vector2(0.66, -0.22), Vector2(0.54, 0.34),
		Vector2(0.10, 0.78), Vector2(-0.46, 0.68),
		Vector2(-0.70, 0.12), Vector2(-0.56, -0.48),
	])
	return _make_recipe(
		&"reward",
		&"mechanical_shard_tier_2",
		&"player_reward",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_scale_points(outer, Vector2(0.76, 0.78))]),
			_layer(&"secondary_mass", [
				PackedVector2Array([
					Vector2(-0.36, -0.10), Vector2(0.30, -0.30),
					Vector2(0.42, 0.02), Vector2(0.02, 0.46),
					Vector2(-0.34, 0.34),
				]),
			]),
			_layer(&"hard_highlight", [
				PackedVector2Array([
					Vector2(-0.30, -0.60), Vector2(0.20, -0.48),
					Vector2(0.34, -0.30), Vector2(-0.36, -0.42),
				]),
			]),
		]
	)


static func _experience_large_recipe() -> Dictionary:
	var outer := PackedVector2Array([
		Vector2(-0.38, -1.00), Vector2(0.30, -0.86),
		Vector2(0.76, -0.42), Vector2(0.82, 0.18),
		Vector2(0.46, 0.78), Vector2(-0.18, 1.00),
		Vector2(-0.72, 0.66), Vector2(-0.90, 0.04),
		Vector2(-0.70, -0.60),
	])
	return _make_recipe(
		&"reward",
		&"mechanical_shard_tier_3",
		&"player_reward",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_scale_points(outer, Vector2(0.78, 0.80))]),
			_layer(&"secondary_mass", [
				PackedVector2Array([
					Vector2(-0.48, -0.18), Vector2(0.30, -0.46),
					Vector2(0.54, -0.14), Vector2(0.30, 0.42),
					Vector2(-0.26, 0.62), Vector2(-0.54, 0.30),
				]),
			]),
			_layer(&"function_inset", [
				PackedVector2Array([
					Vector2(-0.22, -0.22), Vector2(0.18, -0.28),
					Vector2(0.34, 0.02), Vector2(0.10, 0.30),
					Vector2(-0.28, 0.20), Vector2(-0.38, -0.04),
				]),
			]),
			_layer(&"hard_highlight", [
				PackedVector2Array([
					Vector2(-0.34, -0.72), Vector2(0.16, -0.62),
					Vector2(0.38, -0.42), Vector2(-0.40, -0.54),
				]),
			]),
		]
	)


static func _repair_pickup_recipe() -> Dictionary:
	var outer := _plus_cut(Vector2.ZERO, 0.94, 0.36, 0.12)
	return _make_recipe(
		&"reward",
		&"layered_repair_plus_cut",
		&"support",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_scale_points(outer, Vector2(0.84, 0.84))]),
			_layer(&"secondary_mass", [
				_rect(Vector2(-1.02, 0.0), Vector2(0.14, 0.20)),
				_rect(Vector2(1.02, 0.0), Vector2(0.14, 0.20)),
			]),
			_layer(&"function_inset", [
				_plus_cut(Vector2.ZERO, 0.50, 0.18, 0.0),
			]),
			_layer(&"hard_highlight", [
				PackedVector2Array([
					Vector2(-0.24, -0.70), Vector2(0.20, -0.70),
					Vector2(0.28, -0.58), Vector2(-0.24, -0.58),
				]),
			]),
		]
	)


static func _experience_recall_recipe() -> Dictionary:
	var centers := [
		Vector2(0.0, -0.54),
		Vector2(-0.56, 0.42),
		Vector2(0.56, 0.42),
	]
	var directions := [
		Vector2.DOWN,
		Vector2(0.78, -0.62),
		Vector2(-0.78, -0.62),
	]
	var outer: Array[PackedVector2Array] = []
	var main: Array[PackedVector2Array] = []
	for index in centers.size():
		var piece := _chevron(
			Vector2(centers[index]),
			Vector2(directions[index]),
			0.58,
			0.48,
			0.22
		)
		outer.append(piece)
		main.append(_scale_about(piece, Vector2(centers[index]), 0.72))
	return _make_recipe(
		&"reward",
		&"three_way_inward_chevrons",
		&"system",
		[
			_layer(&"perimeter", outer),
			_layer(&"main_mass", main),
			_layer(&"secondary_mass", [
				_rect(Vector2(0.0, -0.78), Vector2(0.14, 0.08)),
				_rect(Vector2(-0.76, 0.56), Vector2(0.10, 0.13)),
				_rect(Vector2(0.76, 0.56), Vector2(0.10, 0.13)),
			]),
			_layer(&"function_inset", [
				PackedVector2Array([
					Vector2(-0.18, -0.10), Vector2(0.10, -0.18),
					Vector2(0.24, 0.02), Vector2(0.12, 0.22),
					Vector2(-0.16, 0.20), Vector2(-0.26, 0.02),
				]),
			]),
			_layer(&"hard_highlight", [
				PackedVector2Array([
					Vector2(-0.12, -0.78), Vector2(0.10, -0.72),
					Vector2(0.14, -0.62), Vector2(-0.12, -0.68),
				]),
			]),
		]
	)


static func _repair_field_recipe() -> Dictionary:
	var outer := _circle(Vector2.ZERO, 1.0)
	return _make_recipe(
		&"facility",
		&"circular_floor_pad_plus_cut",
		&"support",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_circle(Vector2.ZERO, 0.91)]),
			_layer(&"function_inset", [
				_plus_cut(Vector2.ZERO, 0.54, 0.20, 0.06),
			]),
			_layer(&"hard_highlight", [
				_rect(Vector2(0.0, -0.73), Vector2(0.24, 0.05)),
			]),
		]
	)


static func _transit_gate_recipe() -> Dictionary:
	var left := _chevron(Vector2(-0.58, 0.0), Vector2.RIGHT, 0.92, 0.88, 0.34)
	var right := _chevron(Vector2(0.58, 0.0), Vector2.LEFT, 0.92, 0.88, 0.34)
	return _make_recipe(
		&"facility",
		&"opposing_transit_chevrons",
		&"system",
		[
			_layer(&"perimeter", [left, right]),
			_layer(&"main_mass", [
				_scale_about(left, Vector2(-0.58, 0.0), 0.74),
				_scale_about(right, Vector2(0.58, 0.0), 0.74),
			]),
			_layer(&"secondary_mass", [
				_rect(Vector2(-0.98, 0.0), Vector2(0.12, 0.42)),
				_rect(Vector2(0.98, 0.0), Vector2(0.12, 0.42)),
			]),
			_layer(&"function_inset", [
				PackedVector2Array([
					Vector2(-0.28, -0.13), Vector2(0.28, -0.13),
					Vector2(0.40, 0.0), Vector2(0.28, 0.13),
					Vector2(-0.28, 0.13), Vector2(-0.40, 0.0),
				]),
			]),
			_layer(&"hard_highlight", [
				_rect(Vector2(-0.56, -0.56), Vector2(0.22, 0.06)),
				_rect(Vector2(0.56, -0.56), Vector2(0.22, 0.06)),
			]),
		]
	)


static func _overdrive_field_recipe() -> Dictionary:
	var outer := _circle(Vector2.ZERO, 1.0)
	return _make_recipe(
		&"facility",
		&"circular_floor_pad_forward_chevron",
		&"player_reward",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_circle(Vector2.ZERO, 0.91)]),
			_layer(&"function_inset", [
				_chevron(Vector2.ZERO, Vector2.RIGHT, 1.12, 0.88, 0.38),
			]),
			_layer(&"hard_highlight", [
				_rect(Vector2(0.0, -0.73), Vector2(0.24, 0.05)),
			]),
		]
	)


static func _arc_surge_strip_recipe() -> Dictionary:
	var outer := _stepped_slab(Vector2(1.18, 0.54), 0.16)
	return _make_recipe(
		&"facility",
		&"broken_arc_rail",
		&"arc",
		[
			_layer(&"perimeter", [outer]),
			_layer(&"main_mass", [_scale_points(outer, Vector2(0.92, 0.78))]),
			_layer(&"secondary_mass", [
				_rect(Vector2(-0.76, 0.0), Vector2(0.18, 0.30)),
				_rect(Vector2(0.0, 0.0), Vector2(0.18, 0.30)),
				_rect(Vector2(0.76, 0.0), Vector2(0.18, 0.30)),
			]),
			_layer(&"function_inset", [
				PackedVector2Array([
					Vector2(-0.96, -0.08), Vector2(-0.42, -0.30),
					Vector2(-0.56, -0.06), Vector2(-0.04, 0.08),
					Vector2(0.26, -0.24), Vector2(0.18, 0.04),
					Vector2(0.96, 0.20), Vector2(0.38, 0.34),
					Vector2(0.50, 0.12), Vector2(-0.06, 0.28),
					Vector2(-0.30, 0.04), Vector2(-0.42, 0.24),
				]),
			]),
			_layer(&"hard_highlight", [
				_rect(Vector2(0.0, -0.36), Vector2(0.72, 0.05)),
			]),
		]
	)


static func _breakable_bulkhead_recipe() -> Dictionary:
	var left := PackedVector2Array([
		Vector2(-1.16, -0.50), Vector2(-1.00, -0.78),
		Vector2(-0.12, -0.78), Vector2(-0.28, -0.42),
		Vector2(-0.06, -0.14), Vector2(-0.30, 0.16),
		Vector2(-0.12, 0.44), Vector2(-0.30, 0.78),
		Vector2(-1.00, 0.78), Vector2(-1.16, 0.50),
	])
	var right := PackedVector2Array([
		Vector2(0.12, -0.78), Vector2(1.00, -0.78),
		Vector2(1.16, -0.50), Vector2(1.16, 0.50),
		Vector2(1.00, 0.78), Vector2(0.12, 0.78),
		Vector2(0.30, 0.44), Vector2(0.06, 0.14),
		Vector2(0.30, -0.16), Vector2(0.08, -0.44),
	])
	return _make_recipe(
		&"facility",
		&"fracture_split_bulkhead",
		&"raised",
		[
			_layer(&"perimeter", [left, right]),
			_layer(&"main_mass", [
				_scale_about(left, Vector2(-0.62, 0.0), 0.88),
				_scale_about(right, Vector2(0.62, 0.0), 0.88),
			]),
			_layer(&"secondary_mass", [
				_rect(Vector2(-0.88, 0.0), Vector2(0.12, 0.50)),
				_rect(Vector2(0.88, 0.0), Vector2(0.12, 0.50)),
			]),
			_layer(&"function_inset", [
				PackedVector2Array([
					Vector2(-0.18, -0.56), Vector2(0.02, -0.26),
					Vector2(-0.12, -0.04), Vector2(0.12, 0.24),
					Vector2(-0.04, 0.52), Vector2(0.26, 0.18),
					Vector2(0.08, -0.08), Vector2(0.24, -0.34),
				]),
			]),
			_layer(&"hard_highlight", [
				_rect(Vector2(-0.68, -0.56), Vector2(0.24, 0.06)),
				_rect(Vector2(0.68, -0.56), Vector2(0.24, 0.06)),
			]),
		]
	)


static func _make_recipe(
	recipe_category: StringName,
	shape: StringName,
	semantic_color_role: StringName,
	recipe_layers: Array
) -> Dictionary:
	return {
		"category":recipe_category,
		"shape":shape,
		"color_role":semantic_color_role,
		"layers":recipe_layers,
	}


static func _layer(plane: StringName, polygons: Array) -> Dictionary:
	var packed: Array[PackedVector2Array] = []
	for polygon_variant in polygons:
		packed.append(PackedVector2Array(polygon_variant))
	return {"plane":plane, "polygons":packed}


static func _stepped_slab(half_extent: Vector2, cut: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half_extent.x + cut, -half_extent.y),
		Vector2(half_extent.x - cut, -half_extent.y),
		Vector2(half_extent.x, -half_extent.y + cut),
		Vector2(half_extent.x, half_extent.y - cut),
		Vector2(half_extent.x - cut, half_extent.y),
		Vector2(-half_extent.x + cut, half_extent.y),
		Vector2(-half_extent.x, half_extent.y - cut),
		Vector2(-half_extent.x, -half_extent.y + cut),
	])


static func _plus_cut(
	center: Vector2,
	extent: float,
	arm_half_width: float,
	corner_cut: float
) -> PackedVector2Array:
	var e := extent
	var a := arm_half_width
	var c := minf(corner_cut, maxf(0.0, (e - a) * 0.5))
	if c <= 0.001:
		return PackedVector2Array([
			center + Vector2(-a, -e),
			center + Vector2(a, -e),
			center + Vector2(a, -a),
			center + Vector2(e, -a),
			center + Vector2(e, a),
			center + Vector2(a, a),
			center + Vector2(a, e),
			center + Vector2(-a, e),
			center + Vector2(-a, a),
			center + Vector2(-e, a),
			center + Vector2(-e, -a),
			center + Vector2(-a, -a),
		])
	return PackedVector2Array([
		center + Vector2(-a + c, -e),
		center + Vector2(a - c, -e),
		center + Vector2(a, -e + c),
		center + Vector2(a, -a),
		center + Vector2(e - c, -a),
		center + Vector2(e, -a + c),
		center + Vector2(e, a - c),
		center + Vector2(e - c, a),
		center + Vector2(a, a),
		center + Vector2(a, e - c),
		center + Vector2(a - c, e),
		center + Vector2(-a + c, e),
		center + Vector2(-a, e - c),
		center + Vector2(-a, a),
		center + Vector2(-e + c, a),
		center + Vector2(-e, a - c),
		center + Vector2(-e, -a + c),
		center + Vector2(-e + c, -a),
		center + Vector2(-a, -a),
		center + Vector2(-a, -e + c),
	])


static func _chevron(
	center: Vector2,
	direction: Vector2,
	length: float,
	width: float,
	notch: float
) -> PackedVector2Array:
	var forward := direction.normalized()
	var side := forward.rotated(PI * 0.5)
	var front := center + forward * length * 0.5
	var back := center - forward * length * 0.5
	var shoulder := center - forward * length * 0.10
	var inner := center - forward * notch * 0.5
	return PackedVector2Array([
		front,
		shoulder - side * width * 0.5,
		back - side * width * 0.27,
		inner,
		back + side * width * 0.27,
		shoulder + side * width * 0.5,
	])


static func _rect(center: Vector2, half_extent: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-half_extent.x, -half_extent.y),
		center + Vector2(half_extent.x, -half_extent.y),
		center + Vector2(half_extent.x, half_extent.y),
		center + Vector2(-half_extent.x, half_extent.y),
	])


static func _circle(
	center: Vector2,
	radius: float,
	segments: int = 48
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_segments := maxi(12, segments)
	for index in safe_segments:
		points.append(
			center
			+ Vector2.RIGHT.rotated(
				TAU * float(index) / float(safe_segments)
			) * radius
		)
	return points


static func _scale_points(
	points: PackedVector2Array,
	scale: Vector2
) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point * scale)
	return result


static func _scale_about(
	points: PackedVector2Array,
	center: Vector2,
scale: float
) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(center + (point - center) * scale)
	return result


static func _transform_points(
	points: PackedVector2Array,
	center: Vector2,
scale: float
) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(center + point * scale)
	return result


static func _plane_color(plane: StringName, palette: Dictionary) -> Color:
	var accent := Color(palette.get(&"accent", Color.WHITE))
	match plane:
		&"perimeter":
			return Color(palette.get(&"perimeter", accent.darkened(0.72)))
		&"main_mass":
			return Color(palette.get(&"main_mass", accent))
		&"secondary_mass":
			return Color(
				palette.get(
					&"secondary_mass",
					palette.get(&"secondary", accent.darkened(0.28))
				)
			)
		&"function_inset":
			return Color(
				palette.get(
					&"function_inset",
					palette.get(&"surface", accent.darkened(0.56))
				)
			)
		&"hard_highlight":
			return Color(
				palette.get(
					&"hard_highlight",
					palette.get(&"highlight", accent.lightened(0.34))
				)
			)
	return accent


static func _points_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	return Rect2(minimum, maximum - minimum)
