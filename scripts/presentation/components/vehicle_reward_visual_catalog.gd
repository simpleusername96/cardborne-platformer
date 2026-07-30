class_name VehicleRewardVisualCatalog
extends RefCounted

## Reward and pickup presentation descriptors. Spawn budgets, collection,
## effects, persistence, and reward value stay in reward/gameplay owners.

const DESCRIPTORS := {
	&"reward_crate": {"shape": &"slab", "glyph": &"crate", "color": &"player_reward"},
	&"experience_small": {"shape": &"diamond", "glyph": &"experience", "color": &"player_reward"},
	&"experience_medium": {"shape": &"diamond", "glyph": &"experience", "color": &"player_reward"},
	&"experience_large": {"shape": &"diamond", "glyph": &"experience", "color": &"player_reward"},
	&"repair": {"shape": &"plus_cut", "glyph": &"repair", "color": &"support"},
	&"experience_recall": {"shape": &"inward_chevrons", "glyph": &"recall", "color": &"system"},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
