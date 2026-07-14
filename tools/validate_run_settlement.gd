extends SceneTree

class FakeProfileState:
	extends Node

	var materials: Dictionary = {"rusted_scrap": 5}

	func get_materials() -> Dictionary:
		return materials.duplicate(true)

	func grant_material(material_id: String, amount: int) -> bool:
		materials[material_id] = int(materials.get(material_id, 0)) + amount
		return true

	func get_profile_snapshot() -> Dictionary:
		return {
			"hero_loadout": ProfileData.DEFAULT_HERO_LOADOUT.duplicate(true),
			"crafted_equipment": ProfileData.DEFAULT_CRAFTED_EQUIPMENT.duplicate(true),
			"unlocked_blueprints": ProfileData.DEFAULT_BLUEPRINTS.duplicate(),
			"unlocked_spirit_stones": ["ember_spirit_stone"],
			"ranged_supplies": ProfileData.DEFAULT_RANGED_SUPPLIES.duplicate(true),
		}


class FakeRunState:
	extends Node

	var reward_catalog: RewardCatalog
	var profile_state: FakeProfileState
	var facts: Dictionary
	var apply_calls: int
	var last_transaction: RewardTransaction
	var _applied_transactions: Dictionary = {}

	func _init(profile: FakeProfileState, catalog: RewardCatalog) -> void:
		profile_state = profile
		reward_catalog = catalog
		facts = {
			"seed": 8123,
			"profile_id": "traveler",
			"stage_index": 3,
			"health": 4,
			"max_health": 6,
			"level": 4,
			"xp": 88,
			"coins": 21,
			"materials": {"rusted_scrap": 3},
			"cards": {"dash_wake": 1},
			"micro_upgrades": {"micro_power": 2},
			"effective_stats": {"max_health": 6, "attack_power": 1.2},
			"consumable_id": "small_potion",
			"consumable_charges": 0,
		}

	func get_run_snapshot() -> RunSnapshot:
		return RunSnapshot.new(facts)

	func apply_reward_transaction(transaction: RewardTransaction) -> RewardResult:
		apply_calls += 1
		last_transaction = transaction
		if transaction == null or transaction.id == &"":
			return RewardResult.new(false, false, &"", {}, "Invalid fixture transaction.")
		var key := String(transaction.id)
		if _applied_transactions.has(key):
			return RewardResult.new(false, true, transaction.id, {}, "Duplicate fixture reward.")
		var grants := transaction.get_grants()
		var run_materials: Dictionary = facts.get("materials", {}).duplicate(true)
		for material_id in grants:
			var amount := int(grants[material_id])
			profile_state.grant_material(String(material_id), amount)
			run_materials[String(material_id)] = (
				int(run_materials.get(String(material_id), 0)) + amount
			)
		facts["materials"] = run_materials
		_applied_transactions[key] = true
		return RewardResult.new(true, false, transaction.id, grants, "Fixture reward applied.")


var _failures: Array[String] = []
var _settled_signal_count: int


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_isolated_settlement()
	_validate_failure_and_death()
	_validate_run_state_restart()
	_finish()


func _validate_isolated_settlement() -> void:
	var profile := FakeProfileState.new()
	var run_state := FakeRunState.new(profile, _boss_reward_catalog(1))
	var service := RunSettlementService.new()
	service.reset(profile)
	profile.grant_material("rusted_scrap", 3)

	var first: Dictionary = service.settle_victory(
		run_state,
		profile,
		&"boss_clear_slime_king"
	)
	_expect(bool(first.get("ok", false)), "valid boss settlement should succeed")
	_expect(not bool(first.get("duplicate", false)), "first boss settlement should be new")
	_expect(run_state.apply_calls == 1, "victory should apply exactly one typed transaction")
	_expect(
		run_state.last_transaction != null
		and run_state.last_transaction.source_id == &"boss_clear_slime_king",
		"victory transaction should retain the boss reward table ID"
	)
	_expect(profile.materials.get("boss_core", 0) == 1, "victory should persist one Boss Core")
	var snapshot := first.get("settlement") as RunSettlementSnapshot
	_expect(snapshot != null and snapshot.is_victory(), "victory should create a typed snapshot")
	if snapshot != null:
		_expect(snapshot.get_value(&"seed") == 8123, "settlement should record the run seed")
		_expect(snapshot.get_value(&"profile_id") == "traveler", "settlement should record hero")
		_expect(snapshot.get_value(&"stage_reached") == 3, "boss settlement should record Stage 3")
		var build: Dictionary = snapshot.get_value(&"run_build", {})
		var economy: Dictionary = snapshot.get_value(&"run_economy", {})
		var boss_reward: Dictionary = snapshot.get_value(&"boss_reward", {})
		var material_delta: Dictionary = snapshot.get_value(&"persistent_material_delta", {})
		_expect(build.get("cards", {}).get("dash_wake", 0) == 1, "build facts should include cards")
		_expect(economy.get("coins", 0) == 21, "economy facts should include final coins")
		_expect(boss_reward.get("boss_core", 0) == 1, "boss facts should include one core")
		_expect(material_delta.get("rusted_scrap", 0) == 3, "material delta should retain prior rewards")
		_expect(material_delta.get("boss_core", 0) == 1, "material delta should include the boss core")
		build["cards"]["dash_wake"] = 99
		boss_reward["boss_core"] = 99
		_expect(
			snapshot.get_value(&"run_build", {}).get("cards", {}).get("dash_wake", 0) == 1,
			"settlement build facts should be copy-safe"
		)
		_expect(
			snapshot.get_value(&"boss_reward", {}).get("boss_core", 0) == 1,
			"settlement boss facts should be copy-safe"
		)

	var duplicate: Dictionary = service.settle_victory(run_state, profile)
	_expect(bool(duplicate.get("duplicate", false)), "duplicate boss defeat should be idempotent")
	_expect(run_state.apply_calls == 1, "duplicate boss defeat should not apply another transaction")
	_expect(profile.materials.get("boss_core", 0) == 1, "duplicate boss defeat should not add a core")
	var late_death: Dictionary = service.settle_death(run_state, profile)
	var retained := late_death.get("settlement") as RunSettlementSnapshot
	_expect(
		bool(late_death.get("duplicate", false)) and retained != null and retained.is_victory(),
		"the first terminal settlement should win over later death events"
	)
	run_state.free()
	profile.free()


func _validate_failure_and_death() -> void:
	var profile := FakeProfileState.new()
	profile.materials["boss_core"] = 1
	var early_run_state := FakeRunState.new(profile, _boss_reward_catalog(1))
	early_run_state.facts["stage_index"] = 2
	var early_service := RunSettlementService.new()
	early_service.reset(profile)
	var early: Dictionary = early_service.settle_victory(early_run_state, profile)
	_expect(not bool(early.get("ok", false)), "victory before the boss boundary should fail")
	_expect(early_run_state.apply_calls == 0, "early victory should not apply a reward")
	_expect(not early_service.has_settlement(), "early victory should not create settlement")
	early_run_state.free()

	var run_state := FakeRunState.new(profile, _boss_reward_catalog(2))
	var service := RunSettlementService.new()
	service.reset(profile)
	var failed: Dictionary = service.settle_victory(run_state, profile)
	_expect(not bool(failed.get("ok", false)), "invalid Boss Core reward should fail closed")
	_expect(not service.has_settlement(), "failed boss reward should not create victory")
	_expect(run_state.apply_calls == 0, "invalid boss reward should fail before application")

	run_state.facts = {
		"seed": 9001,
		"profile_id": "traveler",
		"stage_index": 1,
		"health": 0,
		"max_health": 6,
		"level": 2,
		"xp": 31,
		"coins": 9,
		"materials": {"rusted_scrap": 2},
		"cards": {"dash_wake": 1},
		"micro_upgrades": {},
		"effective_stats": {"max_health": 6},
		"consumable_id": "small_potion",
		"consumable_charges": 1,
	}
	profile.grant_material("rusted_scrap", 2)
	var death: Dictionary = service.settle_death(run_state, profile, &"player_defeated")
	var death_snapshot := death.get("settlement") as RunSettlementSnapshot
	_expect(bool(death.get("ok", false)), "failure path should settle as death")
	_expect(death_snapshot != null and not death_snapshot.is_victory(), "death must not report victory")
	_expect(profile.materials.get("boss_core", 0) == 1, "death should preserve an existing Boss Core")
	_expect(run_state.apply_calls == 0, "death should not create a boss reward transaction")
	if death_snapshot != null:
		var boss_reward: Dictionary = death_snapshot.get_value(&"boss_reward", {})
		var delta: Dictionary = death_snapshot.get_value(&"persistent_material_delta", {})
		_expect(boss_reward.get("boss_core", -1) == 0, "death settlement should create no Boss Core")
		_expect(delta.get("boss_core", -1) == 0, "death should preserve, not regrant, prior Boss Core")
	var duplicate_death: Dictionary = service.settle_death(run_state, profile)
	_expect(bool(duplicate_death.get("duplicate", false)), "duplicate death should be idempotent")
	run_state.free()
	profile.free()


func _validate_run_state_restart() -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	var profile_state := root.get_node_or_null("/root/ProfileState")
	_expect(
		run_state != null and signal_bus != null and profile_state != null,
		"restart settlement fixture needs autoloads"
	)
	if run_state == null or signal_bus == null or profile_state == null:
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	var original_reward_catalog: RewardCatalog = run_state.get("reward_catalog")
	run_state.set("reward_catalog", _boss_reward_catalog(1))
	var callback := Callable(self, "_on_run_settled")
	if not signal_bus.run_settled.is_connected(callback):
		signal_bus.run_settled.connect(callback)
	_settled_signal_count = 0
	_expect(run_state.start_new_run(0, 7170), "victory integration fixture should start")
	run_state.current_stage_index = 3
	var victory: Dictionary = run_state.settle_run_victory(&"boss_clear_slime_king")
	var duplicate_victory: Dictionary = run_state.settle_run_victory(&"boss_clear_slime_king")
	_expect(bool(victory.get("ok", false)), "RunState should settle typed boss victory")
	_expect(
		bool(duplicate_victory.get("duplicate", false)),
		"RunState duplicate boss victory should be idempotent"
	)
	_expect(profile_state.get_material_count("boss_core") == 1, "RunState victory should grant one core")
	_expect(_settled_signal_count == 1, "victory settlement signal should emit exactly once")
	_expect(run_state.start_new_run(0, 7171), "new run should clear victory settlement")
	_expect(not run_state.has_terminal_settlement(), "new run should clear terminal victory")
	var first_death: Dictionary = run_state.settle_run_death(&"fixture_death")
	var duplicate_death: Dictionary = run_state.settle_run_death(&"fixture_duplicate")
	_expect(bool(first_death.get("ok", false)), "RunState should settle death")
	_expect(bool(duplicate_death.get("duplicate", false)), "RunState duplicate death should be idempotent")
	_expect(_settled_signal_count == 2, "each run should emit one terminal settlement signal")
	_expect(
		profile_state.get_material_count("boss_core") == 1,
		"death after restart should preserve the previously settled core"
	)
	var coins_before := int(run_state.coins)
	var blocked := run_state.call(
		"apply_reward_transaction",
		RewardTransaction.new(&"after_terminal", &"fixture", {"coin": 5})
	) as RewardResult
	_expect(not blocked.applied, "post-terminal rewards should be rejected")
	_expect(run_state.coins == coins_before, "post-terminal rewards should not mutate economy")
	run_state.set("reward_catalog", original_reward_catalog)
	_expect(run_state.start_new_run(0, 7172), "new run should restart after settlement")
	_expect(not run_state.has_terminal_settlement(), "new run should clear terminal settlement")
	_expect(run_state.get_terminal_settlement_snapshot().is_empty(), "restart snapshot should be empty")
	if signal_bus.run_settled.is_connected(callback):
		signal_bus.run_settled.disconnect(callback)


func _boss_reward_catalog(core_count: int) -> RewardCatalog:
	var core := RewardEntry.new()
	core.content_id = &"boss_core"
	core.minimum_amount = core_count
	core.maximum_amount = core_count
	var table := RewardTable.new()
	table.id = &"boss_clear_slime_king"
	table.display_name = "Slime King Clear"
	table.entries.append(core)
	var catalog := RewardCatalog.new()
	catalog.id = &"settlement_fixture"
	catalog.display_name = "Settlement Fixture"
	catalog.tables.append(table)
	return catalog


func _on_run_settled(_settlement: Dictionary) -> void:
	_settled_signal_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("RUN_SETTLEMENT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
