class_name VehicleRewardVisualCatalog
extends RefCounted

## Reward and pickup presentation descriptors. Spawn budgets, collection,
## effects, persistence, and reward value stay in reward/gameplay owners.

const DESCRIPTORS := {
	&"experience_small": {
		"asset": &"pickup/experience_master",
		"shape": &"mechanical_shard_tier_1",
		"glyph": &"experience",
		"color": &"player_reward",
	},
	&"experience_medium": {
		"asset": &"pickup/experience_master",
		"shape": &"mechanical_shard_tier_2",
		"glyph": &"experience",
		"color": &"player_reward",
	},
	&"experience_large": {
		"asset": &"pickup/experience_master",
		"shape": &"mechanical_shard_tier_3",
		"glyph": &"experience",
		"color": &"player_reward",
	},
	&"experience_recall": {
		"asset": &"pickup/experience_recall",
		"shape": &"three_way_inward_chevrons",
		"glyph": &"recall",
		"color": &"system",
	},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
