class_name ProgressionOfferService
extends RefCounted

const CHOICE_COUNT := 3


static func build_offer(
	catalog: RunProgressionCatalog,
	stacks: Dictionary,
	run_seed: int,
	sequence: int
) -> Array[StringName]:
	var eligible: Array[StringName] = []
	for upgrade in catalog.micro_upgrades:
		if upgrade == null:
			continue
		if int(stacks.get(String(upgrade.id), 0)) < upgrade.max_stacks:
			eligible.append(upgrade.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = RewardService.stable_seed(run_seed, "level_offer:%d" % sequence)
	for index in range(eligible.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := eligible[index]
		eligible[index] = eligible[swap_index]
		eligible[swap_index] = held
	var offer: Array[StringName] = []
	for upgrade_id in eligible:
		if offer.size() >= CHOICE_COUNT:
			break
		offer.append(upgrade_id)
	while offer.size() < CHOICE_COUNT and catalog.recovery_choice != null:
		offer.append(catalog.recovery_choice.id)
	return offer
