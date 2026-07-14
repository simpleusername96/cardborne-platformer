extends SceneTree

const HERO_ID := &"traveler"
const LIVE_TRIGGERS: Array[StringName] = [
	&"dash_completed",
	&"first_attack_after_extra_jump",
	&"hit_target_in_recovery",
	&"required_room_encounter_cleared_without_damage",
	&"damage_left_one_health",
]

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_run_state != null, "card reward fixture needs RunState")
	if _run_state == null:
		_finish()
		return
	_validate_catalog_and_offer()
	_validate_reroll_and_commit()
	_validate_offer_reproduction()
	_finish()


func _validate_catalog_and_offer() -> void:
	var catalog := _run_state.get("card_catalog") as CardCatalog
	_expect(catalog != null, "production card catalog should load")
	if catalog == null:
		return
	_expect(catalog.validate_catalog().is_empty(), "production card catalog should validate")
	_expect(catalog.cards.size() == 5, "production should expose exactly five live cards")
	for card in catalog.cards:
		_expect(card.compatibility == [&"shared"], "%s should be shared by the Traveler" % card.id)
		_expect(LIVE_TRIGGERS.has(card.trigger), "%s should use a live Traveler trigger" % card.id)

	var first := CardOfferService.build_offer(catalog, HERO_ID, {}, 93117, 0, 0, [], LIVE_TRIGGERS)
	var repeat := CardOfferService.build_offer(catalog, HERO_ID, {}, 93117, 0, 0, [], LIVE_TRIGGERS)
	_expect(first == repeat, "identical card offer inputs should reproduce exactly")
	_expect(first.size() == 3 and _all_unique(first), "offers should contain three unique cards")
	var seen: Dictionary = {}
	for seed in 256:
		for card_id in CardOfferService.build_offer(
			catalog, HERO_ID, {}, seed, seed % 3, 0, [], LIVE_TRIGGERS
		):
			seen[String(card_id)] = true
	for card in catalog.cards:
		_expect(seen.has(String(card.id)), "%s should be reachable from production offers" % card.id)


func _validate_reroll_and_commit() -> void:
	_expect(_run_state.start_new_run(0, 93117), "fixed-seed Traveler run should start")
	var begin: Dictionary = _run_state.begin_stage_card_reward()
	_expect(bool(begin.get("ok", false)), "stage card reward should begin")
	var original: Array[StringName] = _run_state.get_pending_card_offer()
	_expect(original.size() == 3 and _all_unique(original), "pending offer should be complete")

	var invalid: Dictionary = _run_state.choose_card(&"not_offered")
	_expect(not bool(invalid.get("ok", false)), "an unoffered card should fail closed")
	_expect(_run_state.get_card_stacks().is_empty(), "failed choice must not mutate stacks")

	var funded := RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins", &"fixture", {"coin": 30}),
		_run_state
	)
	_expect(funded.applied and int(_run_state.get("coins")) == 30, "fixture coins should apply once")
	var rerolled: Dictionary = _run_state.reroll_card_offer()
	var next_offer: Array[StringName] = _run_state.get_pending_card_offer()
	_expect(bool(rerolled.get("ok", false)), "first affordable reroll should succeed")
	_expect(next_offer.size() == 3 and not _same_choice_set(next_offer, original), "reroll should visibly change the offer")
	_expect(int(_run_state.get("coins")) == 18, "reroll should deduct exactly 12 coins")
	_expect(not bool(_run_state.reroll_card_offer().get("ok", false)), "one stage allows one reroll")

	var selected := next_offer[0]
	var committed: Dictionary = _run_state.choose_card(selected)
	_expect(bool(committed.get("ok", false)), "an offered card should commit")
	_expect(int(_run_state.get_card_stack(selected)) == 1, "card commit should add one stack")
	_expect(not bool(_run_state.choose_card(selected).get("ok", false)), "one reward cannot commit twice")
	_expect(_run_state.advance_stage_after_card_reward(), "a committed reward should unlock the next stage")
	_expect(int(_run_state.get("current_stage_index")) == 1, "card continuation should advance one stage")


func _validate_offer_reproduction() -> void:
	_expect(_run_state.start_new_run(0, 93117), "reproduction run should restart")
	_run_state.begin_stage_card_reward()
	var original: Array[StringName] = _run_state.get_pending_card_offer()
	RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins_repeat", &"fixture", {"coin": 30}),
		_run_state
	)
	_run_state.reroll_card_offer()
	var rerolled: Array[StringName] = _run_state.get_pending_card_offer()

	_expect(_run_state.start_new_run(0, 93117), "second reproduction run should restart")
	_run_state.begin_stage_card_reward()
	var repeated_original: Array[StringName] = _run_state.get_pending_card_offer()
	RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins_repeat", &"fixture", {"coin": 30}),
		_run_state
	)
	_run_state.reroll_card_offer()
	var repeated_reroll: Array[StringName] = _run_state.get_pending_card_offer()
	_expect(original == repeated_original, "initial offer should reproduce after restart")
	_expect(rerolled == repeated_reroll, "rerolled offer should reproduce after restart")
	_expect(not _run_state.start_new_run(1, 77), "retired class profile indexes should fail closed")


func _all_unique(values: Array[StringName]) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(String(value)):
			return false
		seen[String(value)] = true
	return true


func _same_choice_set(first: Array[StringName], second: Array[StringName]) -> bool:
	if first.size() != second.size():
		return false
	for card_id in first:
		if not second.has(card_id):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("CARD_REWARD_VALIDATION_OK hero=traveler catalog=5 offer=3")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
