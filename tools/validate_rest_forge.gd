extends SceneTree

const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and run_state != null, "rest/forge fixture needs autoloads")
	if profile_state == null or run_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_validate_shop_and_forge(run_state)
	_validate_replacement_confirmation(run_state)
	_validate_economy_tradeoff(run_state)
	_validate_consumable_scopes(run_state)
	_finish()


func _validate_shop_and_forge(run_state: Node) -> void:
	_expect(run_state.start_new_run(0, 8821), "rest fixture run should start")
	run_state.coins = 60
	run_state.current_health = run_state.max_health - 3
	_expect(bool(run_state.begin_rest_forge().get("ok", false)), "rest should begin")
	var coins_before: int = run_state.coins
	var heal: Dictionary = run_state.buy_rest_heal()
	_expect(bool(heal.get("ok", false)), "affordable heal should commit")
	_expect(run_state.coins == coins_before - 8, "heal should charge eight coins")
	_expect(run_state.current_health == run_state.max_health - 1, "heal should restore exactly two")
	var consumable: Dictionary = run_state.buy_rest_consumable(&"dash_tonic")
	_expect(bool(consumable.get("ok", false)), "one consumable purchase should commit")
	_expect(
		not bool(run_state.buy_rest_consumable(&"small_potion").get("ok", true)),
		"second consumable purchase at one rest should reject"
	)
	var dash_before: float = run_state.get_effective_stat("dash_cooldown")
	_expect(bool(run_state.use_consumable().get("ok", false)), "equipped dash tonic should be usable")
	_expect(
		is_equal_approx(run_state.get_effective_stat("dash_cooldown"), dash_before - 0.12),
		"dash tonic preview/runtime effect should match"
	)

	var offer_result: Dictionary = run_state.begin_forge_offer(&"iron_cleaver")
	_expect(bool(offer_result.get("ok", false)), "equipped weapon should produce forge offer")
	var offer: Array = run_state.get_rest_forge_snapshot()["forge_offer"]
	_expect(offer.size() == 3, "forge should expose exactly three choices")
	var first_offer_ids := _offer_ids(offer)
	run_state.begin_forge_offer(&"traveler_jacket")
	run_state.begin_forge_offer(&"iron_cleaver")
	offer = run_state.get_rest_forge_snapshot()["forge_offer"]
	_expect(
		_offer_ids(offer) == first_offer_ids,
		"switching equipped items must not provide free forge rerolls"
	)
	var selected_affix := StringName(offer[0]["id"])
	for row in offer:
		var definition: ForgeAffixDefinition = run_state.forge_catalog.get_affix(
			StringName(row["id"])
		)
		if definition != null and not definition.build_effects.is_empty():
			selected_affix = definition.id
			break
	var forge_cost_before: int = run_state.coins
	var forged: Dictionary = run_state.commit_forge_affix(&"iron_cleaver", selected_affix)
	_expect(bool(forged.get("ok", false)), "offered forge affix should commit")
	_expect(run_state.coins == forge_cost_before - 15, "forge should charge exactly fifteen coins")
	_expect(
		String(run_state.get_rest_forge_snapshot()["temporary_affixes"].get("iron_cleaver", "")) == String(selected_affix),
		"forge should record one affix on the selected item"
	)


func _validate_replacement_confirmation(run_state: Node) -> void:
	run_state.end_rest_forge()
	run_state.coins += 30
	run_state.begin_rest_forge()
	var offer_result: Dictionary = run_state.begin_forge_offer(&"iron_cleaver")
	_expect(bool(offer_result.get("ok", false)), "reforge should produce alternatives")
	var offer: Array = run_state.get_rest_forge_snapshot()["forge_offer"]
	var replacement_id := StringName(offer[0]["id"])
	var before_coins: int = run_state.coins
	var preview: Dictionary = run_state.commit_forge_affix(&"iron_cleaver", replacement_id)
	_expect(bool(preview.get("requires_confirmation", false)), "replacement should require confirmation")
	_expect(run_state.coins == before_coins, "replacement preview should not charge")
	var confirmed: Dictionary = run_state.commit_forge_affix(&"iron_cleaver", replacement_id, true)
	_expect(bool(confirmed.get("ok", false)), "confirmed replacement should commit")
	_expect(run_state.coins == before_coins - 15, "confirmed replacement should charge once")


func _validate_economy_tradeoff(run_state: Node) -> void:
	run_state.start_new_run(0, 9917)
	run_state.coins = 20
	run_state.current_health = run_state.max_health - 2
	run_state.begin_rest_forge()
	_expect(bool(run_state.buy_rest_heal().get("ok", false)), "twenty-coin fixture should afford healing")
	run_state.begin_forge_offer(&"iron_cleaver")
	var offer: Array = run_state.get_rest_forge_snapshot()["forge_offer"]
	_expect(not offer.is_empty(), "economy fixture should still present forge choices")
	if not offer.is_empty():
		_expect(
			not bool(run_state.commit_forge_affix(
				&"iron_cleaver", StringName(offer[0]["id"])
			).get("ok", true)),
			"ordinary twenty-coin budget should not buy both heal and forge"
		)


func _validate_consumable_scopes(run_state: Node) -> void:
	run_state.start_new_run(0, 12013)
	run_state.coins = 30
	run_state.begin_rest_forge()
	run_state.buy_rest_consumable(&"dash_tonic")
	var base_dash: float = run_state.get_effective_stat("dash_cooldown")
	_expect(bool(run_state.use_consumable().get("ok", false)), "dash tonic should activate")
	_expect(
		is_equal_approx(run_state.get_effective_stat("dash_cooldown"), base_dash - 0.12),
		"dash tonic should affect only the active stage"
	)
	run_state.begin_stage_card_reward()
	var card_offer: Array = run_state.get_pending_card_offer()
	_expect(not card_offer.is_empty(), "stage-scope fixture should produce a card offer")
	if not card_offer.is_empty():
		run_state.choose_card(card_offer[0])
		_expect(run_state.advance_stage_after_card_reward(), "card commit should advance the stage")
		_expect(
			is_equal_approx(run_state.get_effective_stat("dash_cooldown"), base_dash),
			"dash tonic should expire when its stage advances"
		)

	run_state.start_new_run(0, 12014)
	run_state.coins = 20
	run_state.begin_rest_forge()
	run_state.buy_rest_consumable(&"salvage_kit")
	_expect(bool(run_state.use_consumable().get("ok", false)), "salvage kit should activate")
	var enemy_drop := RewardService.apply(
		RewardTransaction.new(&"salvage_enemy", &"drop_leaper", {"sky_thread": 1}),
		run_state
	)
	_expect(int(enemy_drop.grants.get("sky_thread", 0)) == 1, "enemy drops cannot consume salvage kit")
	var material_node := RewardService.apply(
		RewardTransaction.new(&"salvage_node", &"material_cavern_ruin", {"rusted_scrap": 1}),
		run_state
	)
	_expect(int(material_node.grants.get("rusted_scrap", 0)) == 2, "next material node should gain +1 material")


func _finish() -> void:
	if _failures.is_empty():
		print("REST_FORGE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _offer_ids(rows: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for row in rows:
		ids.append(StringName(row["id"]))
	return ids


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
