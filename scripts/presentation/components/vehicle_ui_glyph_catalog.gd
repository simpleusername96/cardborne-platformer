class_name VehicleUiGlyphCatalog
extends RefCounted

## Action, minimap, and preview glyph catalog. Upgrade content is semantic
## raster artwork and is intentionally not part of this UI-chrome catalog.

const ActionGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_ui_action_glyph_renderer.gd"
)

const MINIMAP_GLYPHS: Array[StringName] = [
	&"player", &"item", &"enemy", &"boss", &"facility",
]
const CORE_GLYPHS: Array[StringName] = [
	&"primary", &"seeker", &"dash", &"emp", &"secondary", &"breach_ready",
	&"player", &"item", &"enemy", &"boss", &"facility", &"repair", &"recall", &"target",
	&"locked_silhouette",
]

const ACTION_GLYPHS := ActionGlyphRenderer.ACTION_RECIPES


static func descriptor_ids() -> Array[StringName]:
	return CORE_GLYPHS.duplicate()


static func minimap_ids() -> Array[StringName]:
	return MINIMAP_GLYPHS.duplicate()


static func action_ids() -> Array[StringName]:
	return ActionGlyphRenderer.action_ids()


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


static func validate_action_recipes() -> PackedStringArray:
	return ActionGlyphRenderer.validate_recipes()
