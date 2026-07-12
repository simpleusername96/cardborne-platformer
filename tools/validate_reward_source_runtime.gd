extends SceneTree

const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const ROOM_CATALOG := preload("res://data/generation/lower_ruins_room_catalog.tres")
const STAGE_PROFILE := preload("res://data/generation/ruin_approach_profile.tres")
const ENEMY_CATALOG := preload("res://data/enemies/enemy_catalog.tres")
const HAZARD_CATALOG := preload("res://data/hazards/hazard_catalog.tres")
const REWARD_CATALOG := preload("res://data/rewards/reward_catalog.tres")
const CHARACTER_CATALOG := preload("res://data/characters/character_catalog.tres")
const SPAWNER_SCRIPT_PATH := "res://scripts/stages/production/StageRuntimeContentSpawner.gd"

var _failures: Array[String] = []
var _profile_state: Node
var _run_state: Node
var _spawner_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_profile_state != null and _run_state != null, "reward fixture needs profile/run autoloads")
	if _profile_state == null or _run_state == null:
		_finish()
		return
	_spawner_script = load(SPAWNER_SCRIPT_PATH) as Script
	_expect(_spawner_script != null, "reward fixture should load runtime content spawner")
	_profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_validate_reward_role_round_trip()
	await _validate_visual_class_selection()
	await _validate_single_claim_and_replay()
	_validate_material_node_scope()
	_validate_equipment_discovery()
	_validate_production_equipment_pools()
	_finish()


func _validate_reward_role_round_trip() -> void:
	var planned := PlannedReward.new(
		&"fixture_reward",
		&"fixture_room",
		&"fixture_anchor",
		&"optional_cache_ruin",
		1,
		1,
		&"optional_route"
	)
	var restored := PlannedReward.from_dictionary(planned.to_dictionary())
	_expect(restored.reward_role == &"optional_route", "planned reward should round-trip reward_role")

	var limits := MovementMetrics.route_limits_for_profiles(CHARACTER_CATALOG.profiles)
	limits["minimum_headroom"] = 100.0
	limits["allowed_required_abilities"] = [
		"baseline", "double_jump", "dash", "crouch", "climb",
	]
	var topology := StagePlanner.new().build_plan(ROOM_CATALOG, STAGE_PROFILE, 1471, 0, limits)
	var combat := StageEncounterAllocator.new().allocate(topology, ROOM_CATALOG, STAGE_PROFILE, ENEMY_CATALOG)
	var allocated := StageContentAllocator.new().allocate(
		combat,
		ROOM_CATALOG,
		STAGE_PROFILE,
		HAZARD_CATALOG,
		REWARD_CATALOG
	) if combat != null else null
	_expect(allocated != null, "production allocator should build a role fixture")
	if allocated == null:
		return
	for placement in allocated.get_rewards():
		var room := allocated.get_room(placement.room_id)
		var template := ROOM_CATALOG.get_room_by_id(room.template_id) if room != null else null
		var anchor := template.get_reward_anchor_by_id(placement.anchor_id) if template != null else null
		_expect(anchor != null and placement.reward_role == anchor.reward_role, "allocator should preserve anchor reward_role")
	var replayed := StagePlan.from_json(allocated.to_json())
	_expect(replayed != null and replayed.to_json() == allocated.to_json(), "stage plan should preserve reward roles")


func _validate_visual_class_selection() -> void:
	var generic := _instantiate_reward_source(&"stage_reward")
	var chest := _instantiate_reward_source(&"cache_reward")
	var optional := _instantiate_reward_source(&"optional_route")
	var material := _instantiate_reward_source(&"material_node")
	for source in [generic, chest, optional, material]:
		root.add_child(source)
	await process_frame
	_expect(generic is StageRewardInteractable and not generic is ChestInteractable, "generic role should use base reward source")
	_expect(chest is ChestInteractable and optional is ChestInteractable, "cache and optional route should use chests")
	_expect(material is MaterialNode, "material_node role should use MaterialNode")
	_expect(generic.prompt_text != chest.prompt_text and chest.prompt_text != material.prompt_text, "reward source prompts should be distinct")
	_expect(generic.visual_color != chest.visual_color and chest.visual_color != material.visual_color, "reward source colors should be distinct")
	_expect(
		generic.get_node("Visual").polygon != chest.get_node("Visual").polygon
		and chest.get_node("Visual").polygon != material.get_node("Visual").polygon,
		"reward source silhouettes should be distinct"
	)
	for source in [generic, chest, optional, material]:
		source.queue_free()
	await process_frame


func _validate_single_claim_and_replay() -> void:
	_expect(_run_state.start_new_run(0, 8107), "claim fixture run should start")
	var source := _instantiate_reward_source(&"cache_reward")
	source.configure_reward(
		&"cache_reward", &"optional_cache_ruin", &"8107:0:cache:one", _run_state, REWARD_CATALOG
	)
	var contexts: Array[Dictionary] = []
	source.claimed.connect(func(context: Dictionary) -> void: contexts.append(context))
	root.add_child(source)
	var coins_before: int = _run_state.coins
	source.interact(null)
	var coins_after: int = _run_state.coins
	source.interact(null)
	_expect(source.is_claimed(), "successful source should become claimed")
	_expect(contexts.size() == 1, "one source should emit one local claimed context")
	_expect(coins_after > coins_before and _run_state.coins == coins_after, "repeat interaction should not settle twice")
	_expect(contexts[0]["reward_role"] == "cache_reward", "claimed context should preserve role metadata")

	var replay := _instantiate_reward_source(&"cache_reward")
	replay.configure_reward(
		&"cache_reward", &"optional_cache_ruin", &"8107:0:cache:one", _run_state, REWARD_CATALOG
	)
	var replay_contexts: Array[Dictionary] = []
	replay.claimed.connect(func(context: Dictionary) -> void: replay_contexts.append(context))
	root.add_child(replay)
	replay.interact(null)
	replay.interact(null)
	_expect(replay_contexts.size() == 1 and replay_contexts[0]["duplicate"], "recreated source should settle replay once as duplicate")
	_expect(_run_state.coins == coins_after, "replayed source should not mutate rewards")
	source.queue_free()
	replay.queue_free()
	await process_frame


func _validate_material_node_scope() -> void:
	_profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_run_state.start_new_run(0, 8203)
	_run_state.coins = 30
	_run_state.begin_rest_forge()
	_run_state.buy_rest_consumable(&"salvage_kit")
	_expect(bool(_run_state.use_consumable().get("ok", false)), "salvage-kit fixture should activate")
	var chest := RewardService.apply(
		RewardTransaction.new(&"scope:chest", &"optional_cache_ruin", {"rusted_scrap": 1}),
		_run_state
	)
	_expect(int(chest.grants.get("rusted_scrap", 0)) == 1, "chest material must not consume salvage kit")
	var material := RewardService.apply(
		RewardTransaction.new(&"scope:material", &"material_cavern_ruin", {"rusted_scrap": 1}),
		_run_state
	)
	_expect(int(material.grants.get("rusted_scrap", 0)) == 2, "material node should consume salvage kit exactly once")


func _validate_equipment_discovery() -> void:
	_profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_run_state.start_new_run(0, 8309)
	var equipment_entry := RewardEntry.new()
	equipment_entry.reward_type = RewardEntry.TYPE_EQUIPMENT_DISCOVERY
	equipment_entry.content_id = &"bell_hammer"
	equipment_entry.minimum_amount = 1
	equipment_entry.maximum_amount = 1
	var table := RewardTable.new()
	table.id = &"equipment_fixture"
	table.display_name = "Equipment Fixture"
	table.entries = [equipment_entry]
	_expect(table.validate_definition().is_empty(), "typed equipment reward table should validate")

	var first_transaction := RewardService.resolve(table, &"equipment:first", 8309)
	_expect(first_transaction.get_grants().is_empty(), "equipment must not be encoded as currency")
	_expect(first_transaction.get_equipment_discoveries() == [&"bell_hammer"], "equipment grant should remain structured")
	var first := RewardService.apply(first_transaction, _run_state)
	_expect(first.applied and _profile_state.owns_equipment("bell_hammer"), "first discovery should unlock equipment")
	_expect(first.equipment_discoveries.size() == 1, "result should expose structured equipment settlement")
	var profile_transaction_id := String(first.equipment_discoveries[0]["profile_transaction_id"])
	_expect(profile_transaction_id == "reward:equipment:first:equipment:00:bell_hammer", "profile transaction ID should be stable and derived")

	var salvage_before: int = _profile_state.get_material_count("rusted_scrap")
	var second := RewardService.apply(
		RewardService.resolve(table, &"equipment:second", 8309),
		_run_state
	)
	_expect(second.applied, "distinct duplicate discovery should settle")
	_expect(_profile_state.get_material_count("rusted_scrap") == salvage_before + 4, "owned Bell Hammer should use existing four-scrap salvage")
	var replay := RewardService.apply(
		RewardService.resolve(table, &"equipment:second", 8309),
		_run_state
	)
	_expect(replay.duplicate, "equipment reward replay should be idempotent")
	_expect(_profile_state.get_material_count("rusted_scrap") == salvage_before + 4, "equipment replay must not salvage twice")

	var invalid_ids: Array[StringName] = [&"missing_equipment"]
	var coins_before: int = _run_state.coins
	var invalid := RewardService.apply(
		RewardTransaction.new(&"equipment:invalid", &"fixture", {"coin": 3}, invalid_ids),
		_run_state
	)
	_expect(not invalid.applied and not invalid.duplicate, "unknown equipment should fail closed")
	_expect(_run_state.coins == coins_before, "invalid equipment should reject currency before mutation")
	_expect(not _run_state.has_applied_reward(&"equipment:invalid"), "invalid equipment transaction should remain unsettled")

	var malformed := RewardEntry.new()
	malformed.reward_type = RewardEntry.TYPE_EQUIPMENT_DISCOVERY
	malformed.content_id = &"bell_hammer"
	malformed.maximum_amount = 2
	_expect(not malformed.validate_definition().is_empty(), "equipment discovery amount ranges should reject")


func _validate_production_equipment_pools() -> void:
	_profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_expect(_run_state.start_new_run(0, 8401), "production equipment fixture should start")
	var cache := REWARD_CATALOG.get_table(&"optional_cache_ruin")
	_expect(
		cache != null
		and cache.equipment_pool_id == RewardTable.EQUIPMENT_POOL_STAGE_CACHE
		and is_equal_approx(cache.equipment_pool_chance, 1.0),
		"optional cache should expose one guaranteed typed stage-cache policy"
	)
	var first := RewardService.resolve_with_context(
		cache,
		&"8401:0:cache:first",
		8401,
		_run_state.get_reward_resolution_context()
	)
	var first_ids := first.get_equipment_discoveries()
	_expect(first_ids.size() == 1, "first stage cache should discover one compatible item")
	if first_ids.size() == 1:
		var item := EQUIPMENT_CATALOG.get_item(first_ids[0])
		_expect(item != null and item.is_compatible(&"warrior"), "cache item should fit Warrior")
		_expect(RewardService.apply(first, _run_state).applied, "stage cache discovery should apply")

	var second := RewardService.resolve_with_context(
		cache,
		&"8401:0:cache:second",
		8401,
		_run_state.get_reward_resolution_context()
	)
	_expect(
		second.get_equipment_discoveries().is_empty(),
		"later cache rewards in the same stage should not add a second item"
	)

	_run_state.current_stage_index = 1
	var stage_two := RewardService.resolve_with_context(
		cache,
		&"8401:1:cache:first",
		8401,
		_run_state.get_reward_resolution_context()
	)
	_expect(
		stage_two.get_equipment_discoveries() == [&"spring_charm"],
		"Stage 2 cache should resolve the authored shared Spring Charm"
	)

	var sentry := REWARD_CATALOG.get_table(&"drop_sentry")
	_expect(
		sentry != null
		and sentry.equipment_pool_id == RewardTable.EQUIPMENT_POOL_COMPATIBLE_NON_BOSS
		and is_equal_approx(sentry.equipment_pool_chance, 0.1),
		"Sentry should expose the typed ten-percent equipment policy"
	)
	var sentry_hits := 0
	for seed in 1000:
		var transaction := RewardService.resolve_with_context(
			sentry,
			StringName("sentry:fixture:%04d" % seed),
			seed,
			_run_state.get_reward_resolution_context()
		)
		if not transaction.get_equipment_discoveries().is_empty():
			sentry_hits += 1
	_expect(
		sentry_hits >= 70 and sentry_hits <= 130,
		"Sentry equipment policy should remain near ten percent across deterministic seeds"
	)


func _instantiate_reward_source(reward_role: StringName) -> StageRewardInteractable:
	if _spawner_script == null:
		return null
	return _spawner_script.call("instantiate_reward_source", reward_role) as StageRewardInteractable


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("REWARD_SOURCE_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
