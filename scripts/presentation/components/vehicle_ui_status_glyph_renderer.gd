class_name VehicleUiStatusGlyphRenderer
extends RefCounted

## Code-native status glyphs used only by the compact gameplay HUD. Each ID
## owns one meaning and is deliberately separate from action/minimap recipes.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const STATUS_IDS: Array[StringName] = [&"stage_progress", &"total_defeats"]
const STATUS_RECIPES := {
	&"stage_progress":{
		"shape":&"offset_deck_stack",
		"commands":[
			{"tone":&"secondary", "points":[
				Vector2(-0.92, -0.56), Vector2(0.42, -0.56),
				Vector2(0.42, 0.36), Vector2(-0.92, 0.36),
			]},
			{"tone":&"secondary", "points":[
				Vector2(-0.62, -0.30), Vector2(0.72, -0.30),
				Vector2(0.72, 0.62), Vector2(-0.62, 0.62),
			]},
			{"tone":&"primary", "points":[
				Vector2(-0.32, -0.78), Vector2(0.92, -0.78),
				Vector2(0.92, 0.18), Vector2(-0.32, 0.18),
			]},
			{"tone":&"highlight", "points":[
				Vector2(-0.12, -0.56), Vector2(0.70, -0.56),
				Vector2(0.70, -0.40), Vector2(-0.12, -0.40),
			]},
		],
	},
	&"total_defeats":{
		"shape":&"compact_skull",
		"commands":[
			{"tone":&"primary", "points":[
				Vector2(-0.72, -0.34), Vector2(-0.48, -0.76),
				Vector2(0.48, -0.76), Vector2(0.72, -0.34),
				Vector2(0.64, 0.30), Vector2(0.34, 0.56),
				Vector2(-0.34, 0.56), Vector2(-0.64, 0.30),
			]},
			{"tone":&"secondary", "points":[
				Vector2(-0.36, 0.42), Vector2(0.36, 0.42),
				Vector2(0.28, 0.84), Vector2(0.08, 0.66),
				Vector2(-0.08, 0.84), Vector2(-0.28, 0.66),
			]},
			{"tone":&"cutout", "points":[
				Vector2(-0.46, -0.26), Vector2(-0.12, -0.34),
				Vector2(-0.18, 0.02), Vector2(-0.50, 0.06),
			]},
			{"tone":&"cutout", "points":[
				Vector2(0.12, -0.34), Vector2(0.46, -0.26),
				Vector2(0.50, 0.06), Vector2(0.18, 0.02),
			]},
		],
	},
}


static func status_ids() -> Array[StringName]:
	return STATUS_IDS.duplicate()


static func recipe(status_id: StringName) -> Dictionary:
	if not STATUS_RECIPES.has(status_id):
		return {}
	return Dictionary(STATUS_RECIPES[status_id]).duplicate(true)


static func draw_glyph(
	canvas_item: CanvasItem,
	status_id: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> int:
	var drawn_commands := 0
	for command_variant in Array(recipe(status_id).get("commands", [])):
		var command := Dictionary(command_variant)
		var points := PackedVector2Array()
		for point_variant in Array(command.get("points", [])):
			points.append(center + Vector2(point_variant) * scale)
		if points.size() < 3:
			continue
		canvas_item.draw_colored_polygon(
			points,
			_tone_color(StringName(command.get("tone", &"primary")), palette)
		)
		drawn_commands += 1
	return drawn_commands


static func validate_recipes() -> PackedStringArray:
	var errors := PackedStringArray()
	if STATUS_RECIPES.size() != STATUS_IDS.size():
		errors.append("status glyph recipe count must match status IDs")
	for status_id in STATUS_IDS:
		if not STATUS_RECIPES.has(status_id):
			errors.append("missing status glyph recipe: %s" % status_id)
			continue
		var commands := Array(recipe(status_id).get("commands", []))
		if commands.size() < 3:
			errors.append("%s status glyph needs at least three readable planes" % status_id)
		for command_variant in commands:
			if Array(Dictionary(command_variant).get("points", [])).size() < 3:
				errors.append("%s status glyph contains an invalid polygon" % status_id)
	return errors


static func _tone_color(tone: StringName, palette: Dictionary) -> Color:
	var primary := Color(palette.get(&"primary", Art.TEXT_PRIMARY))
	match tone:
		&"secondary":
			return Color(palette.get(&"secondary", primary))
		&"highlight":
			return Color(palette.get(&"highlight", primary))
		&"cutout":
			return Color(palette.get(&"cutout", Art.COBALT_VOID))
	return primary
