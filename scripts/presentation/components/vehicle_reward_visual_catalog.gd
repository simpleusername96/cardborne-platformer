class_name VehicleRewardVisualCatalog
extends RefCounted

## Reward and pickup presentation descriptors. Spawn budgets, collection,
## effects, persistence, and reward value stay in reward/gameplay owners.

const DESCRIPTORS := {
	&"reward_crate": {
		"recipe": &"reward_crate",
		"shape": &"stepped_mechanical_crate",
		"glyph": &"crate",
		"color": &"player_reward",
	},
	&"experience_small": {
		"recipe": &"experience_small",
		"shape": &"mechanical_shard_tier_1",
		"glyph": &"experience",
		"color": &"player_reward",
	},
	&"experience_medium": {
		"recipe": &"experience_medium",
		"shape": &"mechanical_shard_tier_2",
		"glyph": &"experience",
		"color": &"player_reward",
	},
	&"experience_large": {
		"recipe": &"experience_large",
		"shape": &"mechanical_shard_tier_3",
		"glyph": &"experience",
		"color": &"player_reward",
	},
	&"repair": {
		"recipe": &"repair",
		"shape": &"layered_repair_plus_cut",
		"glyph": &"repair",
		"color": &"support",
	},
	&"experience_recall": {
		"recipe": &"experience_recall",
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
