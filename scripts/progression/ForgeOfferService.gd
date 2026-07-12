class_name ForgeOfferService
extends RefCounted


static func build_offer(
	catalog: ForgeCatalog,
	slot_id: StringName,
	run_seed: int,
	stage_index: int,
	item_id: StringName,
	sequence: int,
	current_affix_id: StringName = &""
) -> Array[StringName]:
	var offer: Array[StringName] = []
	if catalog == null:
		return offer
	var candidates := catalog.get_eligible(slot_id)
	if current_affix_id != &"":
		candidates = candidates.filter(
			func(affix: ForgeAffixDefinition) -> bool: return affix.id != current_affix_id
		)
	if candidates.size() < catalog.offer_size:
		return offer
	var rng := RandomNumberGenerator.new()
	rng.seed = RewardService.stable_seed(
		run_seed,
		"forge:%d:%s:%d" % [stage_index, item_id, sequence]
	)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var candidate := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = candidate
	for index in catalog.offer_size:
		offer.append(candidates[index].id)
	return offer
