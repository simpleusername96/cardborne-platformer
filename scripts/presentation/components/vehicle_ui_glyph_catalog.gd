class_name VehicleUiGlyphCatalog
extends RefCounted

## Action, upgrade-family, minimap, and preview glyph ownership. Layout,
## localization, focus, and control state stay in their UI owners.

const SOURCE_FAMILIES: Array[StringName] = [
	&"hud_action_icons",
	&"minimap_world_markers",
	&"guidebook_previews",
	&"upgrade_card_icons",
	&"world_targeting_markers",
	&"ui_frame_system",
	&"dynamic_combat_ui",
]

const CORE_GLYPHS: Array[StringName] = [
	&"primary", &"seeker", &"dash", &"emp", &"secondary", &"breach_ready",
	&"player", &"enemy", &"elite", &"boss", &"stationary", &"pickup",
	&"crate", &"repair", &"recall", &"target", &"locked_silhouette",
]


static func source_family_ids() -> Array[StringName]:
	return SOURCE_FAMILIES.duplicate()


static func descriptor_ids() -> Array[StringName]:
	return CORE_GLYPHS.duplicate()
