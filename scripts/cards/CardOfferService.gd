class_name CardOfferService
extends RefCounted

const CHOICE_COUNT := 3


static func build_offer(
	catalog: CardCatalog,
	profile_id: StringName,
	stacks: Dictionary,
	run_seed: int,
	stage_index: int,
	reroll_sequence: int,
	excluded_ids: Array[StringName] = [],
	supported_triggers: Array[StringName] = []
) -> Array[StringName]:
	var eligible := eligible_ids(
		catalog,
		profile_id,
		stacks,
		excluded_ids,
		supported_triggers
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = RewardService.stable_seed(
		run_seed,
		"card_offer:%d:%d" % [stage_index, reroll_sequence]
	)
	for index in range(eligible.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := eligible[index]
		eligible[index] = eligible[swap_index]
		eligible[swap_index] = held
	var offer: Array[StringName] = []
	for card_id in eligible:
		if offer.size() >= CHOICE_COUNT:
			break
		offer.append(card_id)
	return offer


static func eligible_ids(
	catalog: CardCatalog,
	profile_id: StringName,
	stacks: Dictionary,
	excluded_ids: Array[StringName] = [],
	supported_triggers: Array[StringName] = []
) -> Array[StringName]:
	var eligible: Array[StringName] = []
	if catalog == null or profile_id == &"":
		return eligible
	for card in catalog.cards:
		if (
			card != null
			and card.is_compatible(profile_id)
			and int(stacks.get(String(card.id), 0)) < card.max_stacks
			and not excluded_ids.has(card.id)
			and (supported_triggers.is_empty() or supported_triggers.has(card.trigger))
		):
			eligible.append(card.id)
	return eligible


static func supported_triggers_for_profile(profile: CharacterProfile) -> Array[StringName]:
	var triggers: Array[StringName] = [
		&"dash_completed",
		&"first_attack_after_extra_jump",
		&"hit_target_in_recovery",
	]
	if profile == null or profile.combat_kit == null:
		return triggers
	if profile.combat_kit.heavy_attack != null:
		triggers.append(&"heavy_hit_confirmed")
	if not profile.combat_kit.skills.is_empty():
		triggers.append(&"skill_kill")
	return triggers
