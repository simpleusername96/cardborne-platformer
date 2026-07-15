extends SceneTree

const STAGE_SALVAGE := {
	&"stage_clear_ruin_approach": 3,
	&"stage_clear_flooded_works": 4,
	&"stage_clear_broken_sanctum": 5,
}

var _failures: Array[String] = []
var _run_state: Node
var _profile_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_expect(_run_state != null and _profile_state != null, "merchant fixture needs state autoloads")
	if not _failures.is_empty():
		_finish()
		return
	_profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_validate_stage_salvage_tables()
	_validate_run_only_salvage()
	_validate_potion_purchase()
	_validate_salvage_sale()
	_validate_settlement_reporting()
	_finish()


func _validate_stage_salvage_tables() -> void:
	for table_id in STAGE_SALVAGE:
		var table: RewardTable = _run_state.reward_catalog.get_table(table_id)
		_expect(table != null, "%s should exist" % table_id)
		if table == null:
			continue
		var transaction: RewardTransaction = RewardService.resolve(
			table,
			StringName("merchant_fixture:%s" % table_id),
			43117
		)
		_expect(transaction != null, "%s should resolve" % table_id)
		if transaction != null:
			_expect(
				int(transaction.get_grants().get("salvage", 0)) == int(STAGE_SALVAGE[table_id]),
				"%s should grant deterministic salvage" % table_id
			)


func _validate_run_only_salvage() -> void:
	_expect(_run_state.start_new_run(0, 43118), "salvage fixture should start")
	var profile_before: Dictionary = _profile_state.get_materials()
	var reward := RewardTransaction.new(
		&"merchant_fixture:salvage_only",
		&"merchant_fixture",
		{"salvage": 3}
	)
	var result := _run_state.apply_reward_transaction(reward) as RewardResult
	_expect(result != null and result.applied, "salvage reward should apply")
	_expect(_run_state.get_run_salvage() == 3, "salvage reward should increase run salvage")
	_expect(
		_profile_state.get_materials() == profile_before,
		"run salvage must not enter persistent materials"
	)
	var snapshot: Dictionary = _run_state.get_run_snapshot().to_dictionary()
	_expect(int(snapshot.get("run_salvage", -1)) == 3, "run snapshot should report salvage")
	_expect(_run_state.start_new_run(0, 43119), "new run should reset salvage")
	_expect(_run_state.get_run_salvage() == 0, "run salvage should reset per run")
	_expect(
		_run_state.get_applied_merchant_transaction_ids().is_empty(),
		"merchant IDs should reset per run"
	)


func _validate_potion_purchase() -> void:
	var full_preview: Dictionary = _run_state.get_merchant_snapshot()["buy_potion"]
	_expect(int(full_preview.get("price", 0)) == 10, "potion preview should expose price 10")
	_expect(
		not bool(full_preview.get("eligible", true))
		and String(full_preview.get("failure_code", "")) == "potion_full",
		"full potion preview should explain ineligibility"
	)

	_run_state.consumable_charges = 0
	var poor_preview: Dictionary = _run_state.get_merchant_snapshot()["buy_potion"]
	_expect(
		not bool(poor_preview.get("eligible", true))
		and String(poor_preview.get("failure_code", "")) == "insufficient_coins",
		"poor potion preview should explain missing coins"
	)
	var rejected: Dictionary = _run_state.buy_merchant_potion(&"merchant_fixture:buy:poor")
	_expect(not bool(rejected.get("ok", true)), "ineligible purchase should reject")
	_expect(_run_state.coins == 0 and _run_state.consumable_charges == 0, "rejected purchase must be atomic")

	var coin_reward := RewardTransaction.new(
		&"merchant_fixture:potion_coins",
		&"merchant_fixture",
		{"coin": 10}
	)
	_expect(
		(_run_state.apply_reward_transaction(coin_reward) as RewardResult).applied,
		"potion coin fixture should apply"
	)
	# A rejected ID remains reusable after the player fixes the failure condition.
	var purchase: Dictionary = _run_state.buy_merchant_potion(&"merchant_fixture:buy:poor")
	_expect(bool(purchase.get("ok", false)), "eligible potion purchase should apply")
	_expect(_run_state.coins == 0 and _run_state.consumable_charges == 1, "purchase should spend 10 and refill one charge")
	_expect(
		int((purchase.get("receipt", {}) as Dictionary).get("price", 0)) == 10,
		"purchase receipt should expose price"
	)
	var receipt_copy: Dictionary = (purchase.get("receipt", {}) as Dictionary).duplicate(true)
	(receipt_copy["after"] as Dictionary)["coins"] = 9999
	_expect(_run_state.coins == 0, "receipt dictionaries should be copy-safe")

	var duplicate: Dictionary = _run_state.buy_merchant_potion(&"merchant_fixture:buy:poor")
	_expect(
		not bool(duplicate.get("ok", true)) and bool(duplicate.get("duplicate", false)),
		"duplicate purchase should be rejected and marked duplicate"
	)
	_expect(_run_state.coins == 0 and _run_state.consumable_charges == 1, "duplicate purchase must not mutate")

	# Drinking the charge in the safe map makes a second purchase a new intent.
	_run_state.consumable_charges = 0
	var second_coin_reward := RewardTransaction.new(
		&"merchant_fixture:potion_coins_second",
		&"merchant_fixture",
		{"coin": 10}
	)
	_expect(
		(_run_state.apply_reward_transaction(second_coin_reward) as RewardResult).applied,
		"second potion coin fixture should apply"
	)
	var second_purchase: Dictionary = _run_state.buy_merchant_potion(
		&"merchant_fixture:buy:two"
	)
	_expect(bool(second_purchase.get("ok", false)), "a new potion intent should apply")
	_expect(
		_run_state.coins == 0 and _run_state.consumable_charges == 1,
		"second purchase should spend its own 10 coins and refill the charge"
	)


func _validate_salvage_sale() -> void:
	var salvage_reward := RewardTransaction.new(
		&"merchant_fixture:sale_salvage",
		&"merchant_fixture",
		{"salvage": 3}
	)
	_expect(
		(_run_state.apply_reward_transaction(salvage_reward) as RewardResult).applied,
		"sale salvage fixture should apply"
	)
	var sale_preview: Dictionary = _run_state.get_merchant_snapshot()["sell_run_salvage"]
	_expect(
		bool(sale_preview.get("eligible", false))
		and int(sale_preview.get("unit_price", 0)) == 4
		and int(sale_preview.get("quantity", 0)) == 3
		and int(sale_preview.get("price", 0)) == 12,
		"sale preview should expose all-salvage price"
	)
	var sale: Dictionary = _run_state.sell_run_salvage(&"merchant_fixture:sell:all")
	_expect(bool(sale.get("ok", false)), "eligible salvage sale should apply")
	_expect(_run_state.get_run_salvage() == 0 and _run_state.coins == 12, "sale should convert all salvage at four coins each")
	var duplicate: Dictionary = _run_state.sell_run_salvage(&"merchant_fixture:sell:all")
	_expect(
		not bool(duplicate.get("ok", true)) and bool(duplicate.get("duplicate", false)),
		"duplicate sale should be rejected and marked duplicate"
	)
	_expect(_run_state.get_run_salvage() == 0 and _run_state.coins == 12, "duplicate sale must not mutate")

	_expect(_run_state.grant_unsettled_material("rusted_scrap", 5), "persistent material fixture should grant")
	var materials_before: Dictionary = _run_state.get_unsettled_materials()
	var material_sale: Dictionary = _run_state.sell_run_salvage(&"merchant_fixture:sell:materials")
	_expect(not bool(material_sale.get("ok", true)), "persistent materials should not be merchant stock")
	_expect(
		String((material_sale.get("receipt", {}) as Dictionary).get("failure_code", "")) == "no_run_salvage",
		"material-only sale should explain missing run salvage"
	)
	_expect(
		_run_state.get_unsettled_materials() == materials_before and _run_state.coins == 12,
		"merchant must not sell persistent materials"
	)

	var merchant_snapshot: Dictionary = _run_state.get_merchant_snapshot()
	var ids: Array = merchant_snapshot.get("applied_transaction_ids", [])
	_expect(ids.size() == 3, "only applied merchant transactions should be reported")
	ids.clear()
	_expect(
		_run_state.get_applied_merchant_transaction_ids().size() == 3,
		"merchant snapshot IDs should be copy-safe"
	)


func _validate_settlement_reporting() -> void:
	var salvage_reward := RewardTransaction.new(
		&"merchant_fixture:settlement_salvage",
		&"merchant_fixture",
		{"salvage": 2}
	)
	_expect(
		(_run_state.apply_reward_transaction(salvage_reward) as RewardResult).applied,
		"settlement salvage fixture should apply"
	)
	var settlement: Dictionary = _run_state.settle_run_death(&"merchant_fixture_end")
	_expect(bool(settlement.get("ok", false)), "merchant fixture should settle")
	var report: Dictionary = settlement.get("snapshot", {})
	var economy: Dictionary = report.get("run_economy", {})
	_expect(int(economy.get("run_salvage", -1)) == 2, "settlement should report unsold run salvage")
	_expect(
		(economy.get("merchant_transaction_ids", []) as Array).size() == 3,
		"settlement should report applied merchant IDs"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MERCHANT_TRANSACTION_VALIDATION_OK salvage=3/4/5 potion=10 sale_rate=4 atomic=true")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
