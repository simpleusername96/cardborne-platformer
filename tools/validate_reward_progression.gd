extends SceneTree

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_run_state != null, "reward fixture needs RunState autoload")
	if _run_state == null:
		_finish()
		return
	_expect(_run_state.reward_catalog.validate_catalog().is_empty(), "reward catalog should validate")
	_expect(
		_run_state.progression_catalog.validate_catalog().is_empty(),
		"run progression catalog should validate"
	)
	_validate_reward_replay()
	_validate_level_choice()
	_validate_overflow_and_caps()
	_finish()


func _validate_reward_replay() -> void:
	_expect(_run_state.start_new_run(0, 44021), "fixed-seed Warrior run should start")
	var table: RewardTable = _run_state.reward_catalog.get_table(&"drop_walker")
	var first := RewardService.resolve(table, &"44021:0:patrol:walker_a:0", 44021)
	var repeat := RewardService.resolve(table, &"44021:0:patrol:walker_a:0", 44021)
	_expect(
		first != null and first.to_dictionary() == repeat.to_dictionary(),
		"same seed and transaction ID should resolve the same reward"
	)
	var applied := RewardService.apply(first, _run_state)
	var xp_after_first: int = int(_run_state.current_xp)
	var coins_after_first: int = int(_run_state.coins)
	_expect(applied.applied and not applied.duplicate, "first reward application should commit")
	_expect(xp_after_first == 6, "Walker reward should grant exactly 6 XP")
	var duplicate := RewardService.apply(first, _run_state)
	_expect(not duplicate.applied and duplicate.duplicate, "replayed transaction should be idempotent")
	_expect(
		int(_run_state.current_xp) == xp_after_first and int(_run_state.coins) == coins_after_first,
		"duplicate reward must not mutate run currency"
	)
	var invalid := RewardTransaction.new(&"invalid_reward", &"fixture", {"unknown": 4})
	var invalid_result := RewardService.apply(invalid, _run_state)
	_expect(not invalid_result.applied, "unknown reward currency should fail closed")


func _validate_level_choice() -> void:
	var charger_table: RewardTable = _run_state.reward_catalog.get_table(&"drop_charger")
	var clear_table: RewardTable = _run_state.reward_catalog.get_table(&"stage_clear_ruin_approach")
	RewardService.apply(
		RewardService.resolve(charger_table, &"44021:0:charge:charger_a:1", 44021),
		_run_state
	)
	RewardService.apply(
		RewardService.resolve(clear_table, &"44021:0:stage:clear:0", 44021),
		_run_state
	)
	_expect(_run_state.current_xp == 30, "M1 enemies and stage clear should total 30 XP")
	_expect(_run_state.run_level == 2, "30 XP should resolve run level 2")
	_expect(_run_state.get_pending_level_choice_count() == 1, "level 2 should queue one choice")
	var offer: Array[StringName] = _run_state.get_pending_level_offer()
	_expect(offer.size() == 3, "level reward should offer exactly three choices")
	_expect(offer[0] != offer[1] and offer[1] != offer[2], "eligible level choices should be unique")
	var chosen := offer[0]
	var result: Dictionary = _run_state.choose_micro_upgrade(chosen)
	_expect(bool(result.get("ok", false)), "offered micro-upgrade should commit")
	_expect(_run_state.get_pending_level_choice_count() == 0, "choice should settle one pending level")
	_expect(
		not _run_state.get_effective_build_snapshot().get_source_effects(chosen).is_empty(),
		"chosen micro-upgrade should appear in build source breakdown"
	)
	var snapshot: Dictionary = _run_state.get_run_snapshot().to_dictionary()
	snapshot["coins"] = 99999
	_expect(_run_state.coins != 99999, "run snapshots should be copy-safe")


func _validate_overflow_and_caps() -> void:
	_expect(_run_state.start_new_run(0, 7), "overflow fixture run should start")
	var overflow := RewardTransaction.new(&"overflow", &"fixture", {"xp": 250})
	RewardService.apply(overflow, _run_state)
	_expect(_run_state.run_level == 6, "250 XP should resolve level 6")
	_expect(_run_state.get_pending_level_choice_count() == 5, "overflow XP should queue five choices")
	var capped: Dictionary = {}
	for upgrade in _run_state.progression_catalog.micro_upgrades:
		capped[String(upgrade.id)] = upgrade.max_stacks
	var fallback := ProgressionOfferService.build_offer(
		_run_state.progression_catalog,
		capped,
		7,
		99
	)
	_expect(fallback.size() == 3, "capped offer should still contain three choices")
	for upgrade_id in fallback:
		_expect(upgrade_id == &"micro_recovery", "capped offer should use recovery choices")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("REWARD_PROGRESSION_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
