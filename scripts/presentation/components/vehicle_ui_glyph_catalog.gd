class_name VehicleUiGlyphCatalog
extends RefCounted

## Action, minimap, and preview glyph catalog. Upgrade-family access remains a
## compatibility route while VehicleUpgradeGlyphRenderer owns its geometry.

const UpgradeGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd"
)
const ActionGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_ui_action_glyph_renderer.gd"
)

const CORE_GLYPHS: Array[StringName] = [
	&"primary", &"seeker", &"dash", &"emp", &"secondary", &"breach_ready",
	&"player", &"enemy", &"elite", &"boss", &"stationary", &"pickup",
	&"crate", &"repair", &"recall", &"target", &"locked_silhouette",
]

# Compatibility surface for current registry/sheet callers. The renderer is the
# single geometry recipe owner.
const UPGRADE_FAMILY_GLYPHS := UpgradeGlyphRenderer.FAMILY_RECIPES
const ACTION_GLYPHS := ActionGlyphRenderer.ACTION_RECIPES


static func descriptor_ids() -> Array[StringName]:
	return CORE_GLYPHS.duplicate()


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


static func validate_action_recipes() -> PackedStringArray:
	return ActionGlyphRenderer.validate_recipes()


static func upgrade_family_ids() -> Array[StringName]:
	return UpgradeGlyphRenderer.family_ids()


static func upgrade_family_descriptor(family: StringName) -> Dictionary:
	return UpgradeGlyphRenderer.recipe(family)
