class_name VehicleUiGlyphCatalog
extends RefCounted

## Action, minimap, and preview glyph catalog. Upgrade-family access remains a
## compatibility route while VehicleUpgradeGlyphRenderer owns its geometry.

const UpgradeGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd"
)

const CORE_GLYPHS: Array[StringName] = [
	&"primary", &"seeker", &"dash", &"emp", &"secondary", &"breach_ready",
	&"player", &"enemy", &"elite", &"boss", &"stationary", &"pickup",
	&"crate", &"repair", &"recall", &"target", &"locked_silhouette",
]

# Compatibility surface for current registry/sheet callers. The renderer is the
# single geometry recipe owner.
const UPGRADE_FAMILY_GLYPHS := UpgradeGlyphRenderer.FAMILY_RECIPES


static func descriptor_ids() -> Array[StringName]:
	return CORE_GLYPHS.duplicate()


static func upgrade_family_ids() -> Array[StringName]:
	return UpgradeGlyphRenderer.family_ids()


static func upgrade_family_descriptor(family: StringName) -> Dictionary:
	return UpgradeGlyphRenderer.recipe(family)
