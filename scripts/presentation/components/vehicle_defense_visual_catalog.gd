class_name VehicleDefenseVisualCatalog
extends RefCounted

## Code-native defensive feedback identities. Protection and damage rules stay
## in gameplay owners; this catalog never points at authored raster assets.

const DESCRIPTORS := {
	&"barrier": {
		"topology": &"open_ring",
		"function": &"defense",
	},
	&"ion_field": {
		"topology": &"radius_ring",
		"function": &"offense",
	},
	&"generator_shield": {
		"topology": &"source_tint",
		"function": &"enemy_shield_source",
	},
	&"shield_escort": {
		"topology": &"source_tint",
		"function": &"enemy_mobile_cover",
	},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for visual_id in DESCRIPTORS:
		ids.append(StringName(visual_id))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
