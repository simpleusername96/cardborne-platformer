class_name VehicleUiActionGlyphRenderer
extends RefCounted

## Shared normalized recipes for the three auxiliary gameplay actions. Callers
## append the geometry into their own retained mesh so action identity does not
## add a CanvasItem or draw batch.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const ACTION_IDS: Array[StringName] = [&"seeker", &"dash", &"emp"]

const ACTION_RECIPES := {
	&"seeker":{
		"shape":&"guided_triad",
		"commands":[
			{
				"tone":&"primary",
				"points":[
					Vector2(-0.88, -0.22), Vector2(0.12, -0.22),
					Vector2(0.86, 0.00), Vector2(0.12, 0.22),
					Vector2(-0.88, 0.22), Vector2(-0.58, 0.00),
				],
			},
			{
				"tone":&"secondary",
				"points":[
					Vector2(-0.66, -0.78), Vector2(0.18, -0.58),
					Vector2(-0.48, -0.36), Vector2(-0.22, -0.58),
				],
			},
			{
				"tone":&"secondary",
				"points":[
					Vector2(-0.66, 0.78), Vector2(-0.22, 0.58),
					Vector2(-0.48, 0.36), Vector2(0.18, 0.58),
				],
			},
			{
				"tone":&"highlight",
				"points":[
					Vector2(-0.38, -0.07), Vector2(0.18, -0.07),
					Vector2(0.36, 0.00), Vector2(0.18, 0.07),
					Vector2(-0.38, 0.07),
				],
			},
		],
	},
	&"dash":{
		"shape":&"double_thrust_chevron",
		"commands":[
			{
				"tone":&"primary",
				"points":[
					Vector2(-0.94, -0.72), Vector2(-0.42, -0.72),
					Vector2(0.18, 0.00), Vector2(-0.42, 0.72),
					Vector2(-0.94, 0.72), Vector2(-0.34, 0.00),
				],
			},
			{
				"tone":&"secondary",
				"points":[
					Vector2(-0.10, -0.72), Vector2(0.42, -0.72),
					Vector2(0.94, 0.00), Vector2(0.42, 0.72),
					Vector2(-0.10, 0.72), Vector2(0.50, 0.00),
				],
			},
			{
				"tone":&"highlight",
				"points":[
					Vector2(-0.58, -0.43), Vector2(-0.43, -0.43),
					Vector2(-0.08, -0.04), Vector2(-0.20, 0.08),
				],
			},
		],
	},
	&"emp":{
		"shape":&"radial_pulse_core",
		"commands":[
			{
				"tone":&"primary",
				"points":[
					Vector2(0.00, -0.46), Vector2(0.46, 0.00),
					Vector2(0.00, 0.46), Vector2(-0.46, 0.00),
				],
			},
			{
				"tone":&"secondary",
				"points":[
					Vector2(-0.20, -0.96), Vector2(0.20, -0.96),
					Vector2(0.34, -0.56), Vector2(-0.34, -0.56),
				],
			},
			{
				"tone":&"secondary",
				"points":[
					Vector2(0.56, -0.34), Vector2(0.96, -0.20),
					Vector2(0.96, 0.20), Vector2(0.56, 0.34),
				],
			},
			{
				"tone":&"secondary",
				"points":[
					Vector2(-0.34, 0.56), Vector2(0.34, 0.56),
					Vector2(0.20, 0.96), Vector2(-0.20, 0.96),
				],
			},
			{
				"tone":&"secondary",
				"points":[
					Vector2(-0.96, -0.20), Vector2(-0.56, -0.34),
					Vector2(-0.56, 0.34), Vector2(-0.96, 0.20),
				],
			},
			{
				"tone":&"highlight",
				"points":[
					Vector2(0.00, -0.18), Vector2(0.18, 0.00),
					Vector2(0.00, 0.18), Vector2(-0.18, 0.00),
				],
			},
		],
	},
}


static func action_ids() -> Array[StringName]:
	return ACTION_IDS.duplicate()


static func recipe(action_id: StringName) -> Dictionary:
	if not ACTION_RECIPES.has(action_id):
		return {}
	return Dictionary(ACTION_RECIPES[action_id]).duplicate(true)


static func append_mesh_geometry(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	action_id: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> int:
	var glyph_recipe := recipe(action_id)
	var appended_commands := 0
	for command_variant in Array(glyph_recipe.get("commands", [])):
		var command := Dictionary(command_variant)
		var points := PackedVector2Array()
		for point_variant in Array(command.get("points", [])):
			points.append(center + Vector2(point_variant) * scale)
		var triangles := Geometry2D.triangulate_polygon(points)
		if triangles.is_empty():
			continue
		var offset := vertices.size()
		var color := _tone_color(
			StringName(command.get("tone", &"primary")),
			palette
		)
		for point in points:
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(color)
		for index in triangles:
			indices.append(offset + index)
		appended_commands += 1
	return appended_commands


static func normalized_bounds(action_id: StringName) -> Rect2:
	var result := Rect2()
	var has_result := false
	for command_variant in Array(recipe(action_id).get("commands", [])):
		var points := Array(Dictionary(command_variant).get("points", []))
		for point_variant in points:
			var point := Vector2(point_variant)
			var point_rect := Rect2(point, Vector2.ZERO)
			result = point_rect if not has_result else result.expand(point)
			has_result = true
	return result if has_result else Rect2()


static func validate_recipes() -> PackedStringArray:
	var errors := PackedStringArray()
	if ACTION_RECIPES.size() != ACTION_IDS.size():
		errors.append("action glyph recipe count must match the three action IDs")
	for action_id in ACTION_IDS:
		if not ACTION_RECIPES.has(action_id):
			errors.append("missing action glyph recipe: %s" % action_id)
			continue
		var commands := Array(recipe(action_id).get("commands", []))
		if commands.size() < 3:
			errors.append("%s action glyph needs at least three readable planes" % action_id)
		if not normalized_bounds(action_id).has_area():
			errors.append("%s action glyph has empty normalized bounds" % action_id)
		for command_variant in commands:
			var points := Array(Dictionary(command_variant).get("points", []))
			if points.size() < 3:
				errors.append("%s action glyph contains an invalid polygon" % action_id)
	return errors


static func _tone_color(tone: StringName, palette: Dictionary) -> Color:
	var primary := Color(palette.get(&"primary", Art.TEXT_PRIMARY))
	match tone:
		&"secondary":
			return Color(palette.get(&"secondary", primary))
		&"highlight":
			return Color(palette.get(&"highlight", primary))
	return primary
