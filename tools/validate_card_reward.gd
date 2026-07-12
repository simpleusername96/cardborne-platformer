extends SceneTree

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_run_state != null, "card reward fixture needs RunState autoload")
	if _run_state == null:
		_finish()
		return
	_validate_catalog_and_offer()
	_validate_reroll_and_commit()
	_validate_offer_reproduction()
	_finish()


func _validate_catalog_and_offer() -> void:
	var catalog: CardCatalog = _run_state.get("card_catalog") as CardCatalog
	_expect(catalog != null, "card catalog should load")
	if catalog == null:
		return
	_expect(catalog.validate_catalog().is_empty(), "first card catalog should validate")
	_expect(catalog.cards.size() == 15, "first run should register the complete card catalog")
	var first := CardOfferService.build_offer(catalog, &"warrior", {}, 93117, 0, 0)
	var repeat := CardOfferService.build_offer(catalog, &"warrior", {}, 93117, 0, 0)
	_expect(first == repeat, "identical card offer inputs should reproduce exactly")
	_expect(first.size() == 3, "card offers should contain exactly three choices")
	_expect(_all_unique(first), "card offer choices should be unique")
	for profile in _run_state.profiles:
		var triggers := CardOfferService.supported_triggers_for_profile(profile)
		var profile_offer := CardOfferService.build_offer(
			catalog,
			profile.id,
			{},
			93117,
			0,
			0,
			[],
			triggers
		)
		_expect(profile_offer.size() == 3, "%s should receive a complete live offer" % profile.id)
		var has_shared := false
		var has_character_card := false
		for card_id in profile_offer:
			var card := catalog.get_card(card_id)
			_expect(card != null and triggers.has(card.trigger), "%s cannot receive a dead card" % profile.id)
			if card != null:
				has_shared = has_shared or card.compatibility.has(&"shared")
				has_character_card = has_character_card or (
					card.compatibility.has(StringName(profile.id))
					and not card.compatibility.has(&"shared")
				)
		_expect(has_shared, "%s offer should contain a shared card" % profile.id)
		_expect(has_character_card, "%s offer should contain a character card" % profile.id)


func _validate_reroll_and_commit() -> void:
	_expect(_run_state.call("start_new_run", 0, 93117), "fixed-seed card run should start")
	var begin: Dictionary = _run_state.call("begin_stage_card_reward")
	_expect(bool(begin.get("ok", false)), "stage card reward should begin")
	var original: Array[StringName] = _run_state.call("get_pending_card_offer")
	_expect(original.size() == 3 and _all_unique(original), "pending offer should be three unique cards")

	var invalid: Dictionary = _run_state.call("choose_card", &"not_offered")
	_expect(not bool(invalid.get("ok", false)), "an unoffered card should fail closed")
	_expect(_run_state.call("get_card_stacks").is_empty(), "failed choice must not mutate stacks")

	var funding := RewardTransaction.new(&"card_fixture_coins", &"fixture", {"coin": 30})
	var funded := RewardService.apply(funding, _run_state)
	_expect(funded.applied and int(_run_state.get("coins")) == 30, "fixture coins should apply once")
	var rerolled: Dictionary = _run_state.call("reroll_card_offer")
	var next_offer: Array[StringName] = _run_state.call("get_pending_card_offer")
	_expect(bool(rerolled.get("ok", false)), "affordable first reroll should succeed")
	_expect(
		next_offer.size() == 3 and not _same_choice_set(next_offer, original),
		"reroll should produce a different complete choice set"
	)
	_expect(int(_run_state.get("coins")) == 18, "reroll should deduct exactly 12 coins")
	var second_reroll: Dictionary = _run_state.call("reroll_card_offer")
	_expect(not bool(second_reroll.get("ok", false)), "second stage reroll should fail")
	_expect(int(_run_state.get("coins")) == 18, "failed reroll must not spend coins")

	var selected := next_offer[0]
	var committed: Dictionary = _run_state.call("choose_card", selected)
	_expect(bool(committed.get("ok", false)), "offered card should commit")
	_expect(int(_run_state.call("get_card_stack", selected)) == 1, "card commit should add one stack")
	var duplicate: Dictionary = _run_state.call("choose_card", selected)
	_expect(not bool(duplicate.get("ok", false)), "one reward cannot commit twice")
	_expect(int(_run_state.call("get_card_stack", selected)) == 1, "duplicate commit must not add a stack")
	_expect(_run_state.call("advance_stage_after_card_reward"), "committed reward should unlock next stage")
	_expect(int(_run_state.get("current_stage_index")) == 1, "card continuation should advance stage index")

	var snapshot: Dictionary = _run_state.call("get_run_snapshot").to_dictionary()
	var cards: Dictionary = snapshot.get("cards", {})
	cards[String(selected)] = 99
	_expect(
		int(_run_state.call("get_card_stack", selected)) == 1,
		"card stacks in run snapshots should be copy-safe"
	)


func _validate_offer_reproduction() -> void:
	_expect(_run_state.call("start_new_run", 0, 93117), "reproduction run should restart")
	_run_state.call("begin_stage_card_reward")
	var original: Array[StringName] = _run_state.call("get_pending_card_offer")
	RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins_repeat", &"fixture", {"coin": 30}),
		_run_state
	)
	_run_state.call("reroll_card_offer")
	var rerolled: Array[StringName] = _run_state.call("get_pending_card_offer")

	_expect(_run_state.call("start_new_run", 0, 93117), "second reproduction run should restart")
	_run_state.call("begin_stage_card_reward")
	var repeated_original: Array[StringName] = _run_state.call("get_pending_card_offer")
	RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins_repeat", &"fixture", {"coin": 30}),
		_run_state
	)
	_run_state.call("reroll_card_offer")
	var repeated_reroll: Array[StringName] = _run_state.call("get_pending_card_offer")
	_expect(original == repeated_original, "initial stage offer should reproduce after restart")
	_expect(rerolled == repeated_reroll, "rerolled stage offer should reproduce after restart")

	_expect(_run_state.call("start_new_run", 1, 77), "Archer card run should start")
	RewardService.apply(
		RewardTransaction.new(&"fallback_reroll_coins", &"fixture", {"coin": 20}),
		_run_state
	)
	_run_state.call("begin_stage_card_reward")
	var archer_coins := int(_run_state.get("coins"))
	_expect(_run_state.call("can_reroll_card_offer"), "Archer should have enough live cards to reroll")
	var archer_reroll: Dictionary = _run_state.call("reroll_card_offer")
	_expect(bool(archer_reroll.get("ok", false)), "Archer reroll should succeed")
	_expect(int(_run_state.get("coins")) == archer_coins - 12, "Archer reroll should spend exact cost")


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
		print("CARD_REWARD_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
