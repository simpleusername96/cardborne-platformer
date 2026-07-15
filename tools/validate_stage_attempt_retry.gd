extends SceneTree

const MAIN_SCENE := "res://scenes/main/Main.tscn"
const NORMAL_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const INTERMISSION_PATH := "res://scenes/stages/intermission/SafeIntermission.tscn"
const BOSS_STAGE_PATH := "res://scenes/stages/boss/SlimeCourt.tscn"

var _failures: Array[String] = []
var _run_director: Node
var _run_state: Node
var _profile_state: Node
var _game: Node
var _signal_bus: Node
var _settled_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed_main := load(MAIN_SCENE) as PackedScene
	_expect(packed_main != null, "retry fixture should load the production shell")
	if packed_main == null:
		_finish()
		return
	var main := packed_main.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_run_director = root.get_node_or_null("/root/RunDirector")
	_run_state = root.get_node_or_null("/root/RunState")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_game = root.get_node_or_null("/root/Game")
	_signal_bus = root.get_node_or_null("/root/SignalBus")
	_expect(
		_run_director != null
		and _run_state != null
		and _profile_state != null
		and _game != null
		and _signal_bus != null,
		"retry fixture needs production autoloads"
	)
	if _failures.size() > 0:
		_finish()
		return
	_profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_signal_bus.run_settled.connect(_on_run_settled)

	if OS.get_environment("CARDBORNE_RETRY_BOSS_ONLY") != "1":
		await _validate_normal_stage_retry(main)
	await _validate_boss_retry()

	_game.close_overlays()
	_game.unload_current_stage()
	main.queue_free()
	await process_frame
	_finish()


func _validate_normal_stage_retry(main: Node) -> void:
	_run_director.show_hero_preparation()
	await process_frame
	_expect(
		_run_director.start_production_run(&"traveler"),
		"normal retry fixture should start Stage 1"
	)
	await process_frame
	await process_frame
	_expect(_run_director.get_phase_name() == "stage_active", "Stage 1 should become active")
	_expect(_game.current_stage_path == NORMAL_STAGE_PATH, "Stage 1 should use the production host")
	var first_stage: WeakRef = weakref(_game.current_stage)
	var attempt := _run_state.get_stage_attempt_snapshot() as StageAttemptSnapshot
	_expect(attempt != null and attempt.is_valid(), "Stage 1 should capture a typed attempt")
	if attempt == null or not attempt.is_valid():
		return
	var baseline := attempt.to_dictionary()
	var baseline_run: Dictionary = baseline["run_state"]
	var baseline_profile: Dictionary = baseline["profile_resources"]
	_validate_copy_safety(attempt)
	_validate_incomplete_restore_is_atomic(attempt)

	var attempt_reward := RewardTransaction.new(
		&"retry_fixture_coin",
		&"retry_fixture",
		{"coin": 7}
	)
	var first_reward := _run_state.apply_reward_transaction(attempt_reward) as RewardResult
	_expect(first_reward.applied, "first attempt reward should apply")
	_run_state.consumable_charges = 0
	_run_state.grant_unsettled_material("rusted_scrap", 2)
	var condition_change: Dictionary = _profile_state.consume_equipment_condition(
		&"traveler_sword",
		9.0
	)
	var supply_change: Dictionary = _profile_state.spend_ranged_supply(&"arrows", 3)
	_expect(bool(condition_change.get("ok", false)), "fixture should consume sword condition")
	_expect(bool(supply_change.get("ok", false)), "fixture should consume ranged supplies")

	# Queue the clear callback first to prove lethal damage wins a same-frame
	# clear/death race and cannot grant a reward from the defeated attempt.
	_signal_bus.stage_cleared.emit(String(_game.current_stage.get("stage_id")))
	_run_state.damage_player(999)
	_signal_bus.player_died.emit()
	await process_frame
	await process_frame
	_expect(
		_run_director.get_phase_name() == "retry_decision",
		"lethal Stage 1 damage should enter a non-terminal retry decision"
	)
	_expect(not _run_state.has_terminal_settlement(), "retry decision must not settle the run")
	_expect(_settled_count == 0, "same-frame duplicate death must not settle the run")
	_expect(_game.current_stage == null, "retry decision should unload the defeated world")
	_expect(_game.reward_choice_open, "retry decision should block gameplay input")
	var result := main.get_node_or_null("UILayer/ScreenRoot/RunResult") as Control
	_expect(result != null, "retry decision should mount the existing result surface")
	if result != null:
		var display: Dictionary = result.call("get_display_snapshot")
		_expect(bool(display.get("retry_decision", false)), "result surface should expose retry-decision mode")
		_expect(display.get("retry_action", "") == _t("Retry Stage"), "primary action should retry this stage")
		_expect(display.get("secondary_action", "") == _t("End Expedition"), "secondary action should end explicitly")

	_signal_bus.player_died.emit()
	await process_frame
	_expect(_run_director.get_phase_name() == "retry_decision", "duplicate death should keep one decision")
	_expect(not _run_state.has_terminal_settlement(), "duplicate death must not settle behind the decision")

	_expect(_run_director.retry_current_stage(), "Retry Stage should restore and reload Stage 1")
	await process_frame
	await process_frame
	_expect(_run_director.get_phase_name() == "stage_active", "Stage 1 retry should return to active play")
	_expect(_game.current_stage_path == NORMAL_STAGE_PATH, "Stage 1 retry should keep the scene path")
	_expect(first_stage.get_ref() == null, "Stage 1 retry should discard the defeated world instance")
	_expect(_run_state.run_seed == int(baseline["run_seed"]), "Stage 1 retry should preserve the run seed")
	_expect(_run_state.current_stage_index == int(baseline["stage_index"]), "Stage 1 retry should preserve the stage index")
	_assert_restored_run_state(baseline_run)
	_assert_restored_profile_resources(baseline_profile)
	_expect(not _run_state.has_terminal_settlement(), "successful retry should keep the run unsettled")

	var replay_reward := _run_state.apply_reward_transaction(attempt_reward) as RewardResult
	var replay_coins: int = int(_run_state.coins)
	var duplicate_reward := _run_state.apply_reward_transaction(attempt_reward) as RewardResult
	_expect(replay_reward.applied, "restored world should reapply its rolled-back reward once")
	_expect(duplicate_reward.duplicate, "same-attempt duplicate reward should be rejected")
	_expect(
		replay_coins == int(baseline_run["coins"]) + 7 and _run_state.coins == replay_coins,
		"retry and duplicate reward paths must not accumulate extra coin"
	)

	_run_state.damage_player(999)
	await process_frame
	await process_frame
	_expect(_run_director.get_phase_name() == "retry_decision", "second death should offer the same choice")
	_expect(_run_director.end_expedition(), "End Expedition should settle from the retry decision")
	await process_frame
	_expect(_run_director.get_phase_name() == "run_death", "End Expedition should enter terminal death")
	_expect(_run_state.has_terminal_settlement(), "End Expedition should create a terminal settlement")
	_expect(_settled_count == 1, "End Expedition should publish exactly one settlement")
	_expect(not _run_director.end_expedition(), "duplicate End Expedition should be ignored")
	_expect(_settled_count == 1, "duplicate End Expedition must not publish another settlement")


func _validate_boss_retry() -> void:
	_expect(_run_state.start_new_run(0, 99173), "boss retry fixture should start a fresh run")
	_run_state.current_stage_index = RunPhase.NORMAL_STAGE_COUNT
	_run_director.set("phase", RunPhase.Value.STAGE_CARD_REWARD)
	_expect(
		bool(_run_director.call("_load_safe_intermission")),
		"boss retry fixture should enter the final Safe Intermission"
	)
	await process_frame
	await process_frame
	_expect(
		_run_director.get_phase_name() == "intermission_active",
		"final reward boundary should become an active intermission"
	)
	_expect(
		_game.current_stage_path == INTERMISSION_PATH,
		"boss boundary should preserve the authored Safe Intermission"
	)
	_run_director.call("_on_intermission_continue_requested")
	await process_frame
	await process_frame
	_expect(_run_director.get_phase_name() == "boss_active", "boss should become active")
	_expect(_game.current_stage_path == BOSS_STAGE_PATH, "boss should use canonical Slime Court")
	var first_boss: WeakRef = weakref(_game.current_stage)
	var attempt := _run_state.get_stage_attempt_snapshot() as StageAttemptSnapshot
	_expect(
		attempt != null and attempt.is_valid() and attempt.is_boss_attempt(),
		"boss loading should capture a typed boss attempt"
	)
	if attempt == null or not attempt.is_valid():
		return
	var baseline := attempt.to_dictionary()
	var boss_reward := RewardTransaction.new(
		&"retry_fixture_boss_coin",
		&"retry_fixture",
		{"coin": 11}
	)
	_expect(
		(_run_state.apply_reward_transaction(boss_reward) as RewardResult).applied,
		"boss attempt reward should apply before defeat"
	)
	# Boss victory is also deferred; a same-frame lethal hit must retain retry.
	_signal_bus.boss_defeated.emit(RunSettlementService.DEFAULT_BOSS_REWARD_TABLE_ID)
	_run_state.damage_player(999)
	await process_frame
	await process_frame
	_expect(_run_director.get_phase_name() == "retry_decision", "boss defeat should offer retry")
	_expect(not _run_state.has_terminal_settlement(), "boss retry decision must remain non-terminal")
	_expect(_run_director.retry_current_stage(), "Retry Stage should restore and reload Slime Court")
	await process_frame
	await process_frame
	_expect(_run_director.get_phase_name() == "boss_active", "boss retry should return to active boss play")
	_expect(_game.current_stage_path == BOSS_STAGE_PATH, "boss retry should keep Slime Court")
	_expect(first_boss.get_ref() == null, "boss retry should discard the defeated boss world")
	_expect(_run_state.run_seed == int(baseline["run_seed"]), "boss retry should preserve the seed")
	_expect(
		_run_state.current_stage_index == RunPhase.NORMAL_STAGE_COUNT,
		"boss retry should preserve the boss boundary"
	)
	var replay := _run_state.apply_reward_transaction(boss_reward) as RewardResult
	var duplicate := _run_state.apply_reward_transaction(boss_reward) as RewardResult
	_expect(replay.applied and duplicate.duplicate, "boss retry reward should replay once without duplication")


func _validate_copy_safety(attempt: StageAttemptSnapshot) -> void:
	var copy := attempt.to_dictionary()
	(copy["run_state"] as Dictionary)["coins"] = 99999
	(copy["profile_resources"] as Dictionary)["ranged_supplies"] = {"arrows": 0}
	var fresh := attempt.to_dictionary()
	_expect(
		int((fresh["run_state"] as Dictionary)["coins"]) != 99999,
		"typed attempt should deep-copy run facts"
	)
	_expect(
		(fresh["profile_resources"] as Dictionary)["ranged_supplies"] != {"arrows": 0},
		"typed attempt should deep-copy profile resources"
	)


func _validate_incomplete_restore_is_atomic(valid_attempt: StageAttemptSnapshot) -> void:
	var invalid_data := valid_attempt.to_dictionary()
	(invalid_data["run_state"] as Dictionary).erase("coins")
	var invalid_attempt := StageAttemptSnapshot.new(invalid_data)
	_expect(not invalid_attempt.is_valid(), "incomplete attempt should fail validation")
	var coins_before: int = int(_run_state.coins)
	var supplies_before: Dictionary = _profile_state.get_ranged_supplies()
	_run_state.set("_stage_attempt_snapshot", invalid_attempt)
	var restore: Dictionary = _run_state.restore_stage_attempt()
	_expect(not bool(restore.get("ok", false)), "incomplete attempt restore should fail closed")
	_expect(_run_state.coins == coins_before, "failed restore must not mutate run state")
	_expect(
		_profile_state.get_ranged_supplies() == supplies_before,
		"failed restore must not mutate profile resources"
	)
	_run_state.set("_stage_attempt_snapshot", valid_attempt)


func _assert_restored_run_state(baseline: Dictionary) -> void:
	_expect(_run_state.current_health == int(baseline["current_health"]), "retry should restore health")
	_expect(_run_state.max_health == int(baseline["max_health"]), "retry should restore maximum health")
	_expect(_run_state.run_level == int(baseline["run_level"]), "retry should restore run level")
	_expect(_run_state.current_xp == int(baseline["current_xp"]), "retry should restore XP")
	_expect(_run_state.coins == int(baseline["coins"]), "retry should restore coins")
	_expect(
		_run_state.get_unsettled_materials() == baseline["unsettled_materials"],
		"retry should restore unsettled materials"
	)
	_expect(
		_run_state.get_card_stacks() == baseline["card_stacks"],
		"retry should restore cards"
	)
	_expect(
		_run_state.consumable_charges == int(baseline["consumable_charges"]),
		"retry should restore consumable charges"
	)


func _assert_restored_profile_resources(baseline: Dictionary) -> void:
	_expect(
		_profile_state.get_ranged_supplies() == baseline["ranged_supplies"],
		"retry should restore ranged supplies"
	)
	var crafted: Dictionary = _profile_state.get_crafted_equipment()
	for model_id in baseline["equipment_conditions"]:
		var state: Dictionary = crafted.get(model_id, {})
		_expect(
			is_equal_approx(
				float(state.get("condition", -1.0)),
				float((baseline["equipment_conditions"] as Dictionary)[model_id])
			),
			"retry should restore %s condition" % model_id
		)


func _on_run_settled(_snapshot: Dictionary) -> void:
	_settled_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _t(source: StringName, values: Array = []) -> String:
	var localization := root.get_node_or_null("/root/UILocalization")
	return String(localization.call("text", source, values)) if localization != null else String(source)


func _finish() -> void:
	if _failures.is_empty():
		var normal_result := (
			"skipped" if OS.get_environment("CARDBORNE_RETRY_BOSS_ONLY") == "1"
			else "restore+end_once"
		)
		print(
			"STAGE_ATTEMPT_RETRY_VALIDATION_OK normal=%s boss=deterministic deep_copy=true"
			% normal_result
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
