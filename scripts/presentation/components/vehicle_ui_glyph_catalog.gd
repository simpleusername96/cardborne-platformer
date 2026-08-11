class_name VehicleUiGlyphCatalog
extends RefCounted

## Action, minimap, and preview glyph catalog. Upgrade content is semantic
## raster artwork and is intentionally not part of this UI-chrome catalog.

const ActionGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_ui_action_glyph_renderer.gd"
)
const StatusGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_ui_status_glyph_renderer.gd"
)

const MINIMAP_GLYPHS: Array[StringName] = [
	&"player",
	&"field_pickup",
	&"mystery_device",
	&"mobile_enemy",
	&"priority_enemy",
	&"boss",
	&"reinforcement_facility",
]
const CORE_GLYPHS: Array[StringName] = [
	&"primary", &"seeker", &"dash", &"emp", &"secondary", &"breach_ready",
	&"stage_progress", &"total_defeats",
	&"player", &"field_pickup", &"mystery_device",
	&"mobile_enemy", &"priority_enemy", &"boss", &"reinforcement_facility",
	&"repair", &"recall", &"target",
	&"locked_silhouette",
]

const ACTION_GLYPHS := ActionGlyphRenderer.ACTION_RECIPES


static func descriptor_ids() -> Array[StringName]:
	return CORE_GLYPHS.duplicate()


static func minimap_ids() -> Array[StringName]:
	return MINIMAP_GLYPHS.duplicate()


static func action_ids() -> Array[StringName]:
	return ActionGlyphRenderer.action_ids()


static func status_ids() -> Array[StringName]:
	return StatusGlyphRenderer.status_ids()


static func action_descriptor(action_id: StringName) -> Dictionary:
	return ActionGlyphRenderer.recipe(action_id)


static func append_action_mesh_geometry(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	action_id: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> int:
	return ActionGlyphRenderer.append_mesh_geometry(
		vertices,
		colors,
		indices,
		action_id,
		center,
		scale,
		palette
	)


static func draw_action_glyph(
	canvas_item: CanvasItem,
	action_id: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> int:
	return ActionGlyphRenderer.draw_glyph(
		canvas_item,
		action_id,
		center,
		scale,
		palette
	)


static func draw_status_glyph(
	canvas_item: CanvasItem,
	status_id: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> int:
	return StatusGlyphRenderer.draw_glyph(
		canvas_item, status_id, center, scale, palette
	)


static func validate_action_recipes() -> PackedStringArray:
	return ActionGlyphRenderer.validate_recipes()


static func validate_status_recipes() -> PackedStringArray:
	return StatusGlyphRenderer.validate_recipes()


static func validate_semantic_ownership() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	for glyph_id in CORE_GLYPHS:
		if seen.has(glyph_id):
			errors.append("duplicate core glyph semantic owner: %s" % glyph_id)
		seen[glyph_id] = true
	for status_id in status_ids():
		if status_id in action_ids():
			errors.append("status/action glyph meaning collision: %s" % status_id)
		if status_id not in CORE_GLYPHS:
			errors.append("status glyph missing from core catalog: %s" % status_id)
	for action_id in action_ids():
		if action_id not in CORE_GLYPHS:
			errors.append("action glyph missing from core catalog: %s" % action_id)
	return errors
