class_name VehicleEnemyFamilyTraitCatalog
extends RefCounted

## Canonical five-family, two-trait vocabulary and weighted pack rollout.
## Shared trait cadence belongs to the pack runtime; this catalog owns no live state.

const FAMILIES: Array[StringName] = [
	&"pursuer", &"charger", &"emitter", &"defender", &"coordinator",
]
const TRAITS_BY_FAMILY := {
	&"pursuer": [&"splitter", &"frenzy"],
	&"charger": [&"double", &"self_destruct"],
	&"emitter": [&"artillery", &"slow"],
	&"defender": [&"bulwark", &"reflector"],
	&"coordinator": [&"blink", &"pack_feed"],
}
const BASE_TRAIT_WEIGHT := 4
const SPECIAL_TRAIT_WEIGHT := 3
const TRAIT_WEIGHT_TOTAL := BASE_TRAIT_WEIGHT + SPECIAL_TRAIT_WEIGHT * 2
const SIZE_PERCENT_BY_TIER := {1: 100, 2: 125, 3: 150}
const PACK_MIN_SIZE := 4
const PACK_MAX_SIZE := 8
const EMITTERS_PER_DEFENDER := 4
const TACTIC_BY_FAMILY := {
	&"pursuer": &"swarm_screen",
	&"charger": &"spearhead",
	&"emitter": &"crossfire_convoy",
	&"defender": &"shielded_column",
	&"coordinator": &"shepherd_pack",
}

const FRENZY_SPEED_MULTIPLIER := 1.15
const FRENZY_CADENCE_MULTIPLIER := 0.85
const SLOW_DURATION := 1.5
const SLOW_MOVEMENT_MULTIPLIER := 0.65
const BULWARK_INTERVAL := 8.0
const BULWARK_ACTIVE_DURATION := 2.5
const BULWARK_RADIUS := 250.0
const BULWARK_VISUAL_PERCENT := 135
const REFLECTOR_INTERVAL := 7.0
const REFLECTOR_ACTIVE_DURATION := 2.0
const BLINK_INTERVAL := 9.0
const BLINK_WARNING_DURATION := 0.9
const PACK_FEED_MAX_STACKS := 5
const PACK_FEED_HEAL_RATIO := 0.10
const PACK_FEED_DAMAGE_PER_STACK := 0.08
const PACK_FEED_SPEED_PER_STACK := 0.04


static func archetype(family: StringName, tier: int) -> StringName:
	if family not in FAMILIES or tier not in SIZE_PERCENT_BY_TIER:
		return &""
	return StringName("ordinary_%s_t%d" % [String(family), tier])


static func tier_for_stage(stage_index: int) -> int:
	return clampi(stage_index / 4 + 1, 1, 3)


static func traits(family: StringName) -> Array[StringName]:
	var values: Array[StringName] = []
	for value in Array(TRAITS_BY_FAMILY.get(family, [])):
		values.append(StringName(value))
	return values


static func trait_belongs_to_family(family: StringName, trait_id: StringName) -> bool:
	return trait_id.is_empty() or trait_id in Array(TRAITS_BY_FAMILY.get(family, []))


static func trait_for_pack(family: StringName, stage_index: int, pack_ordinal: int) -> StringName:
	# Preserve the stage-owned family mix, then choose base/trait 1/trait 2 as
	# a deterministic weighted draw (4:3:3). The seed keeps authored packets
	# reproducible while allowing every stage, including stage 1, to show traits.
	var family_traits := traits(family)
	if family_traits.size() != 2:
		return &""
	var roll := posmod(hash("%s:%d:%d" % [String(family), stage_index, pack_ordinal]), TRAIT_WEIGHT_TOTAL)
	if roll < BASE_TRAIT_WEIGHT:
		return &""
	if roll < BASE_TRAIT_WEIGHT + SPECIAL_TRAIT_WEIGHT:
		return family_traits[0]
	return family_traits[1]


static func tactic_for_family(family: StringName) -> StringName:
	return StringName(TACTIC_BY_FAMILY.get(family, &"swarm_screen"))


static func required_defenders(emitter_count: int) -> int:
	return ceili(float(maxi(0, emitter_count)) / float(EMITTERS_PER_DEFENDER))


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_traits := {}
	if FAMILIES.size() != 5:
		errors.append("ordinary family catalog must contain exactly five families")
	for family in FAMILIES:
		var family_traits := traits(family)
		if family_traits.size() != 2:
			errors.append("family must expose exactly two traits: %s" % family)
		for trait_id in family_traits:
			if seen_traits.has(trait_id):
				errors.append("trait must belong to only one family: %s" % trait_id)
			seen_traits[trait_id] = family
	if TRAIT_WEIGHT_TOTAL != 10:
		errors.append("ordinary trait weights must total ten")
	if BASE_TRAIT_WEIGHT != 4 or SPECIAL_TRAIT_WEIGHT != 3:
		errors.append("ordinary trait weights must remain base/trait1/trait2 = 4/3/3")
	for tier in SIZE_PERCENT_BY_TIER:
		if int(SIZE_PERCENT_BY_TIER[tier]) != [100, 125, 150][int(tier) - 1]:
			errors.append("tier size ladder must remain 100/125/150")
	return errors
