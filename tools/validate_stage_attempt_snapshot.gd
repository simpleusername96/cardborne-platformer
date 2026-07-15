extends SceneTree

const NORMAL_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const BOSS_STAGE_PATH := "res://scenes/stages/boss/SlimeCourt.tscn"

var _failures: Array[String] = []
var _run_state: Node
var _profile_state: Node
var _settled_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	_expect(
		_run_state != null and _profile_state != null and signal_bus != null,
		"stage attempt fixture needs state autoloads"
	)
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
	signal_bus.run_settled.connect(_on_run_settled)
	_validate_normal_attempt_restore()
	_validate_boss_attempt_identity()
	_finish()


func _validate_normal_attempt_restore() -> void:
	_expect(_run_state.start_new_run(0, 77531), "normal snapshot fixture should start")
	var pre_attempt_reward := RewardTransaction.new(
		&"snapshot_pre_attempt_economy",
		&"snapshot_fixture",
		{"coin": 10, "salvage": 2}
	)
	_expect(
		(_run_state.apply_reward_transaction(pre_attempt_reward) as RewardResult).applied,
		"pre-attempt merchant economy should apply"
	)
	_run_state.consumable_charges = 0
	_expect(
		bool(_run_state.buy_merchant_potion(&"snapshot_pre_attempt_potion").get("ok", false)),
		"pre-attempt merchant transaction should apply"
	)
	var capture: Dictionary = _run_state.capture_stage_attempt(NORMAL_STAGE_PATH, false)
	_expect(bool(capture.get("ok", false)), "normal attempt capture should succeed")
	var attempt := _run_state.get_stage_attempt_snapshot() as StageAttemptSnapshot
	_expect(attempt != null and attempt.is_valid(), "normal attempt should be typed and valid")
	if attempt == null or not attempt.is_valid():
		return
	var baseline := attempt.to_dictionary()
	var baseline_run: Dictionary = baseline["run_state"]
	var baseline_profile: Dictionary = baseline["profile_resources"]

	var copy := attempt.to_dictionary()
	(copy["run_state"] as Dictionary)["coins"] = 99999
	(copy["run_state"] as Dictionary)["run_salvage"] = 99999
	((copy["run_state"] as Dictionary)["applied_merchant_transaction_ids"] as Dictionary).clear()
	((copy["profile_resources"] as Dictionary)["ranged_supplies"] as Dictionary)["arrows"] = 0
	var fresh := attempt.to_dictionary()
	_expect(
		int((fresh["run_state"] as Dictionary)["coins"]) == int(baseline_run["coins"]),
		"attempt run facts should be deep-copy safe"
	)
	_expect(
		int((fresh["run_state"] as Dictionary)["run_salvage"])
		== int(baseline_run["run_salvage"]),
		"attempt run salvage should be deep-copy safe"
	)
	_expect(
		((fresh["run_state"] as Dictionary)["applied_merchant_transaction_ids"] as Dictionary)
		== baseline_run["applied_merchant_transaction_ids"],
		"attempt merchant IDs should be deep-copy safe"
	)
	_expect(
		int(((fresh["profile_resources"] as Dictionary)["ranged_supplies"] as Dictionary)["arrows"])
		== int((baseline_profile["ranged_supplies"] as Dictionary)["arrows"]),
		"attempt profile resources should be deep-copy safe"
	)

	var reward := RewardTransaction.new(&"snapshot_retry_coin", &"snapshot_fixture", {"coin": 6})
	_expect(
		(_run_state.apply_reward_transaction(reward) as RewardResult).applied,
		"first attempt reward should apply"
	)
	_run_state.damage_player(2)
	_run_state.consumable_charges = 0
	_run_state.grant_unsettled_material("rusted_scrap", 3)
	_expect(
		bool(_run_state.sell_run_salvage(&"snapshot_post_capture_sale").get("ok", false)),
		"post-capture salvage sale should apply"
	)
	_expect(
		bool(_profile_state.consume_equipment_condition(&"traveler_sword", 8.0).get("ok", false)),
		"fixture should consume equipment condition"
	)
	_expect(
		bool(_profile_state.spend_ranged_supply(&"arrows", 2).get("ok", false)),
		"fixture should consume ranged supply"
	)

	var invalid_data := attempt.to_dictionary()
	(invalid_data["run_state"] as Dictionary).erase("coins")
	var invalid := StageAttemptSnapshot.new(invalid_data)
	_expect(not invalid.is_valid(), "incomplete attempt should be invalid")
	var live_coins: int = int(_run_state.coins)
	var live_supplies: Dictionary = _profile_state.get_ranged_supplies()
	_run_state.set("_stage_attempt_snapshot", invalid)
	var rejected: Dictionary = _run_state.restore_stage_attempt()
	_expect(not bool(rejected.get("ok", false)), "incomplete restore should fail closed")
	_expect(_run_state.coins == live_coins, "failed restore should not mutate run facts")
	_expect(
		_profile_state.get_ranged_supplies() == live_supplies,
		"failed restore should not mutate profile resources"
	)

	var missing_condition_data := attempt.to_dictionary()
	var missing_conditions := (
		(missing_condition_data["profile_resources"] as Dictionary)["equipment_conditions"]
		as Dictionary
	)
	_expect(not missing_conditions.is_empty(), "fixture should capture condition equipment")
	if not missing_conditions.is_empty():
		missing_conditions.erase(missing_conditions.keys()[0])
		var incomplete_conditions := StageAttemptSnapshot.new(missing_condition_data)
		_expect(
			incomplete_conditions.is_valid(),
			"condition omission should reach live-profile completeness validation"
		)
		var conditions_before: Dictionary = _profile_state.get_crafted_equipment()
		live_coins = int(_run_state.coins)
		live_supplies = _profile_state.get_ranged_supplies()
		_run_state.set("_stage_attempt_snapshot", incomplete_conditions)
		var condition_rejected: Dictionary = _run_state.restore_stage_attempt()
		_expect(
			not bool(condition_rejected.get("ok", false)),
			"restore should reject an omitted equipment condition"
		)
		_expect(_run_state.coins == live_coins, "condition rejection must not mutate run facts")
		_expect(
			_profile_state.get_ranged_supplies() == live_supplies
			and _profile_state.get_crafted_equipment() == conditions_before,
			"condition rejection must not mutate profile resources"
		)

	_run_state.set("_stage_attempt_snapshot", attempt)
	var restored: Dictionary = _run_state.restore_stage_attempt()
	_expect(bool(restored.get("ok", false)), "complete attempt should restore atomically")
	_expect(_run_state.run_seed == int(baseline["run_seed"]), "restore should preserve run seed")
	_expect(_run_state.current_stage_index == int(baseline["stage_index"]), "restore should preserve stage")
	_expect(_run_state.current_health == int(baseline_run["current_health"]), "restore should reset health")
	_expect(_run_state.coins == int(baseline_run["coins"]), "restore should reset coins")
	_expect(
		_run_state.get_run_salvage() == int(baseline_run["run_salvage"]),
		"restore should reset run salvage"
	)
	_expect(
		_run_state.get_applied_merchant_transaction_ids()
		== (baseline_run["applied_merchant_transaction_ids"] as Dictionary).keys(),
		"restore should reset merchant transaction IDs"
	)
	_expect(
		_run_state.get_unsettled_materials() == baseline_run["unsettled_materials"],
		"restore should reset unsettled materials"
	)
	_expect(
		_run_state.consumable_charges == int(baseline_run["consumable_charges"]),
		"restore should reset consumable charges"
	)
	_expect(
		_profile_state.get_ranged_supplies() == baseline_profile["ranged_supplies"],
		"restore should reset ranged supplies"
	)
	var crafted: Dictionary = _profile_state.get_crafted_equipment()
	for model_id in baseline_profile["equipment_conditions"]:
		_expect(
			is_equal_approx(
				float((crafted[model_id] as Dictionary)["condition"]),
				float((baseline_profile["equipment_conditions"] as Dictionary)[model_id])
			),
			"restore should reset %s condition" % model_id
		)
	_expect(not _run_state.has_terminal_settlement(), "attempt restore must remain non-terminal")

	var replay := _run_state.apply_reward_transaction(reward) as RewardResult
	var replay_coins: int = int(_run_state.coins)
	var duplicate := _run_state.apply_reward_transaction(reward) as RewardResult
	_expect(replay.applied and duplicate.duplicate, "rolled-back reward should replay exactly once")
	_expect(
		replay_coins == int(baseline_run["coins"]) + 6 and _run_state.coins == replay_coins,
		"reward replay should not duplicate economy"
	)

	var first_end: Dictionary = _run_state.settle_run_death(&"fixture_end_expedition")
	var duplicate_end: Dictionary = _run_state.settle_run_death(&"fixture_duplicate_end")
	_expect(bool(first_end.get("ok", false)), "explicit death settlement should succeed")
	_expect(bool(duplicate_end.get("duplicate", false)), "duplicate death settlement should be idempotent")
	_expect(_settled_count == 1, "explicit death settlement should publish once")


func _validate_boss_attempt_identity() -> void:
	_expect(_run_state.start_new_run(0, 77532), "boss snapshot fixture should start")
	_run_state.current_stage_index = RunPhase.NORMAL_STAGE_COUNT
	var capture: Dictionary = _run_state.capture_stage_attempt(BOSS_STAGE_PATH, true)
	_expect(bool(capture.get("ok", false)), "boss attempt capture should succeed")
	var attempt := _run_state.get_stage_attempt_snapshot() as StageAttemptSnapshot
	_expect(
		attempt != null
		and attempt.is_valid()
		and attempt.is_boss_attempt()
		and attempt.get_stage_path() == BOSS_STAGE_PATH,
		"boss attempt should retain its deterministic identity"
	)
	if attempt == null:
		return
	_run_state.damage_player(3)
	_expect(
		bool(_run_state.restore_stage_attempt().get("ok", false)),
		"boss attempt should restore without terminal settlement"
	)
	_expect(
		_run_state.current_stage_index == RunPhase.NORMAL_STAGE_COUNT
		and _run_state.run_seed == 77532,
		"boss restore should retain boss boundary and seed"
	)
	_expect(not _run_state.has_terminal_settlement(), "boss restore should remain non-terminal")


func _on_run_settled(_snapshot: Dictionary) -> void:
	_settled_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_ATTEMPT_SNAPSHOT_VALIDATION_OK deep_copy=true atomic=true settlement_once=true boss=true")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
