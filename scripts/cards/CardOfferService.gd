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
	return _compose_offer(catalog, profile_id, eligible)


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
		triggers.append(&"heavy_ground_impact")
	if profile.combat_kit.guarded_duration > 0.0:
		triggers.append(&"guard_consumed")
	if not profile.combat_kit.skills.is_empty():
		triggers.append(&"skill_kill")
	# Character-only cards remain filtered by compatibility; the offer service only
	# declares which runtime-owned trigger families a complete kit can publish.
	triggers.append_array([
		&"archer_power_shot_terminated",
		&"archer_mark_consumed",
		&"assassin_shadow_lunge_completed",
		&"assassin_flow_consumed",
	])
	return triggers


static func _compose_offer(
	catalog: CardCatalog,
	profile_id: StringName,
	eligible: Array[StringName]
) -> Array[StringName]:
	var selected: Array[StringName] = []
	var character_card := _first_matching_card(catalog, profile_id, eligible, false)
	var shared_card := _first_matching_card(catalog, profile_id, eligible, true)
	if not character_card.is_empty():
		selected.append(character_card)
	if not shared_card.is_empty() and not selected.has(shared_card):
		selected.append(shared_card)
	for card_id in eligible:
		if selected.size() >= CHOICE_COUNT:
			break
		if not selected.has(card_id):
			selected.append(card_id)
	var offer: Array[StringName] = []
	for card_id in eligible:
		if selected.has(card_id):
			offer.append(card_id)
	return offer


static func _first_matching_card(
	catalog: CardCatalog,
	profile_id: StringName,
	eligible: Array[StringName],
	wants_shared: bool
) -> StringName:
	for card_id in eligible:
		var card := catalog.get_card(card_id)
		if card == null:
			continue
		var is_shared := card.compatibility.has(&"shared")
		if is_shared == wants_shared and (is_shared or card.compatibility.has(profile_id)):
			return card_id
	return &""
