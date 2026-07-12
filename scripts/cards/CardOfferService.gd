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
	excluded_ids: Array[StringName] = []
) -> Array[StringName]:
	if catalog == null or profile_id == &"":
		return []
	var eligible: Array[StringName] = []
	for card in catalog.cards:
		if (
			card != null
			and card.is_compatible(profile_id)
			and int(stacks.get(String(card.id), 0)) < card.max_stacks
			and not excluded_ids.has(card.id)
		):
			eligible.append(card.id)
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
