class_name VehicleDefenseVisualCatalog
extends RefCounted

## Defensive and area-effect identities are deliberately topology-distinct.
## Protection and damage rules stay in their gameplay owners.

const DESCRIPTORS := {
	&"barrier": {
		"asset": &"state/player_barrier_plate",
		"topology": &"segmented_forward_plates",
		"function": &"defense",
	},
	&"ion_field": {
		"asset": &"state/player_ion_emitter",
		"topology": &"hex_lightning_emitter",
		"function": &"offense",
	},
	&"generator_shield": {
		"asset": &"state/enemy_generator_shield_source",
		"topology": &"radial_source_nodes",
		"function": &"enemy_shield_source",
	},
	&"shield_escort": {
		"asset": &"state/enemy_shield_escort_plate",
		"topology": &"forward_slab",
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
