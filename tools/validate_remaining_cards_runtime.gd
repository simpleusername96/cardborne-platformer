extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const ENEMY_SCRIPT_PATH := "res://scripts/enemies/EnemyBase.gd"
const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const CARD_PATHS: Array[String] = [
	"res://data/cards/kinetic_refund.tres",
	"res://data/cards/second_wind.tres",
	"res://data/cards/last_stand.tres",
	"res://data/cards/treasure_instinct.tres",
]

var _failures: Array[String] = []
var _run_state: Variant
var _signal_bus: Node
var _profile_state: Node
var _world: Node2D
var _player: Variant
var _combat: Variant
var _runtime: Variant
var _kit: CharacterKit
var _enemy_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _prepare_run_state():
		_finish()
		return
	await _create_fixture()
	if _player == null:
		_finish()
		return
	await _validate_kinetic_refund()
	_validate_second_wind()
	_validate_last_stand()
	await _validate_treasure_instinct()
	await _clear_fixture()
	await _validate_treasure_ui_flow()
	_finish()


func _prepare_run_state() -> bool:
	_run_state = root.get_node_or_null("/root/RunState")
	_signal_bus = root.get_node_or_null("/root/SignalBus")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	if _run_state == null or _signal_bus == null or _profile_state == null:
		_expect(false, "remaining-card fixture needs profile, run, and signal autoloads")
		return false
	_profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	var catalog := _run_state.card_catalog as CardCatalog
	_enemy_script = load(ENEMY_SCRIPT_PATH) as Script
	if catalog == null or _enemy_script == null:
		_expect(false, "remaining-card fixture needs production catalogs and enemy script")
		return false
	var stacks: Dictionary = {}
	for path in CARD_PATHS:
		var card := load(path) as CardDefinition
		if card == null:
			_expect(false, "fixture card should load from %s" % path)
			continue
		_expect(
			catalog.get_card(card.id) == card,
			"production catalog should own remaining card %s" % card.id
		)
		stacks[String(card.id)] = 1
	if not _run_state.call("start_new_run", 0, 74017):
		_expect(false, "fixture should start a Warrior run")
		return false
	_run_state.set("_card_stacks", stacks)
	return true


func _create_fixture() -> void:
	_world = Node2D.new()
	_world.name = "RemainingCardsFixture"
	root.add_child(_world)
	_add_floor()
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	_player = player_scene.instantiate() if player_scene != null else null
	_expect(_player != null, "player fixture should instantiate")
	if _player == null:
		return
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	await _physics_steps(2)
	_combat = _player.get_node("CombatController")
	_runtime = _player.get_node("CardRuntime")
	_kit = _run_state.selected_profile.combat_kit
	_expect(_combat != null and _runtime != null and _kit != null, "player fixture should expose card/combat contracts")


func _validate_kinetic_refund() -> void:
	_combat.reset_combat_state()
	_combat.begin_stage()
	_expect(_combat.call("_begin_attack", _kit.heavy_attack), "kinetic fixture should begin Heavy")
	var first := _spawn_enemy(Vector2(60.0, 100.0), 60)
	var second := _spawn_enemy(Vector2(90.0, 100.0), 60)
	await _physics_steps(2)
	_combat.apply_runtime_hit(first, _kit.heavy_attack)
	_combat.apply_runtime_hit(first, _kit.heavy_attack)
	_combat.apply_runtime_hit(second, _kit.heavy_attack, {}, true)
	var one_target_event: Dictionary = _combat.call("_make_action_event", &"completed")
	_expect(int(one_target_event.get("target_count", 0)) == 1, "duplicate and secondary hits should count as one target")
	var initial_cooldowns := _seed_skill_cooldowns(5.0)
	_runtime.notify_attack_completed(one_target_event)
	_expect(_cooldowns_match(initial_cooldowns), "one target should not trigger Kinetic Refund")

	_combat.apply_runtime_hit(second, _kit.heavy_attack)
	var two_target_event: Dictionary = _combat.call("_make_action_event", &"completed")
	_expect(int(two_target_event.get("target_count", 0)) == 2, "two distinct primary targets should be counted")
	_runtime.notify_attack_completed(two_target_event)
	_expect(_cooldowns_match(_offset_cooldowns(initial_cooldowns, -1.0)), "Kinetic Refund should trim every active skill")
	var snapshot: Dictionary = _runtime.get_state_snapshot()
	_expect(
		is_equal_approx(float(snapshot.get("internal_cooldowns", {}).get("kinetic_refund", 0.0)), 3.0),
		"Kinetic Refund should start its three-second internal cooldown"
	)

	var during_icd := _current_skill_cooldowns()
	var next_event := two_target_event.duplicate(true)
	next_event["action_serial"] = int(two_target_event["action_serial"]) + 1
	_runtime.notify_attack_completed(next_event)
	_expect(_cooldowns_match(during_icd), "Kinetic Refund internal cooldown should block another activation")
	_runtime.call("_process", 3.1)
	var after_icd_event := two_target_event.duplicate(true)
	after_icd_event["action_serial"] = int(two_target_event["action_serial"]) + 2
	_runtime.notify_attack_completed(after_icd_event)
	_expect(_cooldowns_match(_offset_cooldowns(during_icd, -1.0)), "Kinetic Refund should become ready after three seconds")


func _validate_second_wind() -> void:
	_combat.reset_combat_state()
	_combat.begin_stage()
	_run_state.max_health = 6
	_run_state.current_health = 3
	var room_a := _room_context(&"room_a")
	_signal_bus.emit_signal("required_room_encounter_started", room_a)
	_signal_bus.emit_signal("required_room_encounter_cleared", room_a)
	_expect(_run_state.current_health == 4, "Second Wind should heal one after a damage-free required room")
	_signal_bus.emit_signal("required_room_encounter_cleared", room_a)
	_expect(_run_state.current_health == 4, "Second Wind should apply once per room")

	var room_b := _room_context(&"room_b")
	_signal_bus.emit_signal("required_room_encounter_started", room_b)
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(1, null, Vector2.ZERO, ["fixture"]))
	_expect(_run_state.current_health == 3, "fixture damage should commit one health")
	_signal_bus.emit_signal("required_room_encounter_cleared", room_b)
	_expect(_run_state.current_health == 3, "Second Wind should reject a damaged room")

	var room_c := _room_context(&"room_c")
	_signal_bus.emit_signal("required_room_encounter_started", room_c)
	_combat.notify_player_health_damage({
		"amount": 0,
		"previous_health": _run_state.current_health,
		"current_health": _run_state.current_health,
	})
	_signal_bus.emit_signal("required_room_encounter_cleared", room_c)
	_expect(_run_state.current_health == 4, "zero damage should not invalidate Second Wind")


func _validate_last_stand() -> void:
	_combat.reset_combat_state()
	_combat.begin_stage()
	var skill := _kit.get_skill_by_slot(1)
	_expect(skill != null, "Last Stand fixture needs Skill 1")
	if skill == null:
		return
	_run_state.max_health = 6
	_run_state.current_health = 3
	_player.invulnerability_timer = 0.0
	_combat.set("_cooldowns", {String(skill.id): 4.0})
	_player.receive_damage(DamageInfo.new(2, null, Vector2.ZERO, ["fixture"]))
	_expect(_run_state.current_health == 1, "Last Stand should require damage leaving exactly one health")
	_expect(_player.invulnerability_timer >= 1.19, "Last Stand should grant 1.2 seconds of invulnerability")
	_expect(is_zero_approx(_combat.get_cooldown_remaining(skill.id)), "Last Stand should reset Skill 1")
	_expect(bool(_runtime.get_state_snapshot().get("last_stand_used", false)), "Last Stand should expose its stage ledger")

	_run_state.current_health = 3
	_player.invulnerability_timer = 0.0
	_combat.set("_cooldowns", {String(skill.id): 4.0})
	_player.receive_damage(DamageInfo.new(2, null, Vector2.ZERO, ["fixture"]))
	_expect(_combat.get_cooldown_remaining(skill.id) == 4.0, "Last Stand should trigger once per stage")
	_expect(_player.invulnerability_timer < 1.19, "a spent Last Stand should grant only normal hit invulnerability")

	_combat.begin_stage()
	_run_state.current_health = 3
	_player.invulnerability_timer = 0.0
	_combat.set("_cooldowns", {String(skill.id): 4.0})
	_player.receive_damage(DamageInfo.new(2, null, Vector2.ZERO, ["fixture"]))
	_expect(is_zero_approx(_combat.get_cooldown_remaining(skill.id)), "begin_stage should reset Last Stand scope")

	_combat.begin_stage()
	_run_state.current_health = 1
	_player.invulnerability_timer = 0.0
	_combat.notify_player_health_damage({"amount": 0, "previous_health": 1, "current_health": 1})
	_expect(not bool(_runtime.get_state_snapshot().get("last_stand_used", false)), "starting at one health should not trigger Last Stand")
	_run_state.current_health = 3
	_player.invulnerability_timer = 1.0
	_player.receive_damage(DamageInfo.new(2, null, Vector2.ZERO, ["fixture"]))
	_expect(_run_state.current_health == 3, "invulnerability should block fixture damage")
	_expect(not bool(_runtime.get_state_snapshot().get("last_stand_used", false)), "blocked damage should not trigger Last Stand")


func _validate_treasure_instinct() -> void:
	_combat.begin_stage()
	var requests: Array[Dictionary] = []
	var claims: Array[Dictionary] = []
	var capture_request := func(request: Dictionary) -> void:
		requests.append(request.duplicate(true))
	var capture_claim := func(context: Dictionary) -> void:
		claims.append(context.duplicate(true))
	_signal_bus.connect("reward_preview_replacement_requested", capture_request)
	_signal_bus.connect("optional_route_chest_claimed", capture_claim)

	var required := _spawn_chest(&"required_chest", false)
	var required_coins: int = _run_state.coins
	required.interact(_player)
	_expect(required.is_claimed(), "required-route chest should settle immediately")
	_expect(_run_state.coins > required_coins, "required-route chest should apply its normal reward")
	_expect(requests.is_empty() and claims.is_empty(), "required-route chest should not trigger Treasure Instinct")

	var optional := _spawn_chest(&"optional_chest_a", true)
	var replacement_coins: int = _run_state.coins
	optional.interact(_player)
	_expect(not optional.is_claimed(), "optional chest should wait for the Treasure Instinct choice")
	_expect(requests.size() == 1, "optional chest should publish one replacement request")
	if requests.size() == 1:
		var request := requests[0]
		_expect(request.get("request_id") == &"optional_chest_a", "Treasure request should retain source identity")
		var options: Array = request.get("options", [])
		_expect(options.size() == 2, "Treasure choice should show normal and replacement rewards")
		if options.size() == 2:
			_expect(options[0].get("id") == TreasureChoiceService.NORMAL_CHOICE_ID, "first choice should retain the normal reward")
			_expect(options[1].get("id") == TreasureChoiceService.REPLACEMENT_CHOICE_ID, "second choice should be the compatible replacement")
	var wrong_request: Dictionary = _run_state.commit_optional_chest_choice(
		&"different_chest",
		TreasureChoiceService.NORMAL_CHOICE_ID
	)
	_expect(not bool(wrong_request.get("ok", false)), "another chest ID must not consume the pending choice")
	var wrong_choice: Dictionary = _run_state.commit_optional_chest_choice(
		&"optional_chest_a",
		&"unsupported_choice"
	)
	_expect(not bool(wrong_choice.get("ok", false)), "unknown choice IDs must not consume the pending chest")
	_expect(not optional.is_claimed() and _run_state.coins == replacement_coins, "rejected choice commands must leave the chest pending")
	var replacement_result: Dictionary = _run_state.commit_optional_chest_choice(
		&"optional_chest_a",
		TreasureChoiceService.REPLACEMENT_CHOICE_ID
	)
	_expect(bool(replacement_result.get("ok", false)), "replacement choice should commit")
	_expect(optional.is_claimed(), "committed Treasure choice should settle its source chest")
	_expect(_run_state.coins == replacement_coins, "replacement choice must not duplicate normal chest currency")
	_expect(_run_state.has_applied_reward(&"optional_chest_a"), "replacement should consume the chest transaction ID")
	_expect(claims.size() == 1 and claims[0].get("choice_id") == TreasureChoiceService.REPLACEMENT_CHOICE_ID, "optional chest should publish its committed choice once")
	_expect(not claims[0].has("equipment_catalog"), "public chest claims should hide reward-resolution internals")
	var replacement_kind := StringName(replacement_result.get("replacement_kind", &""))
	_expect(replacement_kind in [&"equipment", &"forge"], "replacement should resolve to equipment or forge")
	if replacement_kind == &"equipment":
		_expect(not replacement_result.get("equipment_discoveries", []).is_empty(), "equipment replacement should persist one discovery")
	elif replacement_kind == &"forge":
		_expect(not _run_state.get_run_snapshot().to_dictionary().get("temporary_affixes", {}).is_empty(), "forge replacement should alter the effective build")
	optional.interact(_player)
	_expect(requests.size() == 1 and claims.size() == 1, "settled chest interaction should remain idempotent")
	_expect(
		not bool(_run_state.commit_optional_chest_choice(
			&"optional_chest_a",
			TreasureChoiceService.REPLACEMENT_CHOICE_ID
		).get("ok", false)),
		"a committed Treasure choice must not settle twice"
	)

	var second_optional := _spawn_chest(&"optional_chest_b", true)
	var normal_coins: int = _run_state.coins
	second_optional.interact(_player)
	_expect(requests.size() == 2, "a distinct optional chest should create a distinct choice")
	var normal_result: Dictionary = _run_state.commit_optional_chest_choice(
		&"optional_chest_b",
		TreasureChoiceService.NORMAL_CHOICE_ID
	)
	_expect(bool(normal_result.get("ok", false)), "normal Treasure choice should commit")
	_expect(second_optional.is_claimed() and _run_state.coins > normal_coins, "normal choice should apply the original chest reward")
	_expect(
		claims.size() == 2 and claims[1].get("choice_id") == TreasureChoiceService.NORMAL_CHOICE_ID,
		"each optional chest should publish exactly one committed claim"
	)
	_profile_state.discover_equipment(&"bell_hammer", &"treasure_fixture:bell_hammer")
	_profile_state.discover_equipment(&"runner_cloak", &"treasure_fixture:runner_cloak")
	var forge_chest := _spawn_chest(&"optional_chest_forge", true)
	var forge_coins: int = _run_state.coins
	forge_chest.interact(_player)
	_expect(requests.size() == 3, "owned equipment should still produce a forge replacement")
	if requests.size() == 3:
		var forge_options: Array = requests[2].get("options", [])
		_expect(
			forge_options.size() == 2 and forge_options[1].get("kind") == &"forge",
			"exhausted equipment choices should fall back to a compatible forge"
		)
	var forge_result: Dictionary = _run_state.commit_optional_chest_choice(
		&"optional_chest_forge",
		TreasureChoiceService.REPLACEMENT_CHOICE_ID
	)
	_expect(bool(forge_result.get("ok", false)), "forge replacement should commit")
	_expect(forge_result.get("replacement_kind") == &"forge", "forge fallback should retain its result kind")
	_expect(forge_chest.is_claimed() and _run_state.coins == forge_coins, "free forge should replace normal chest currency")
	_expect(
		not _run_state.get_run_snapshot().to_dictionary().get("temporary_affixes", {}).is_empty(),
		"free forge should change the active run build"
	)
	var reset_chest := _spawn_chest(&"optional_chest_reset", true)
	reset_chest.interact(_player)
	_expect(not _run_state.get_pending_optional_chest_choice().is_empty(), "fixture should hold one pending choice before reset")
	_expect(
		_run_state.cancel_optional_chest_choice(&"optional_chest_reset", "fixture cancellation"),
		"pending Treasure choice should support explicit cancellation"
	)
	_expect(reset_chest.interaction_enabled and not reset_chest.is_claimed(), "cancelled choice should reopen its chest")
	reset_chest.interact(_player)
	_expect(not _run_state.get_pending_optional_chest_choice().is_empty(), "reopened chest should create a fresh pending choice")
	_expect(_run_state.start_new_run(0, 74019), "fixture should start a replacement run")
	_expect(_run_state.get_pending_optional_chest_choice().is_empty(), "new run should clear a stale Treasure choice")
	_signal_bus.disconnect("reward_preview_replacement_requested", capture_request)
	_signal_bus.disconnect("optional_route_chest_claimed", capture_claim)
	await process_frame


func _spawn_chest(request_id: StringName, optional_route: bool) -> ChestInteractable:
	var chest := ChestInteractable.new()
	chest.configure_reward(
		&"cache_reward",
		&"optional_cache_ruin",
		request_id,
		_run_state,
		_run_state.reward_catalog,
		{
			"request_id": request_id,
			"stage_index": _run_state.current_stage_index,
			"room_id": &"room_optional" if optional_route else &"room_main",
			"source_id": StringName("source_%s" % request_id),
			"optional_route": optional_route,
		}
	)
	_world.add_child(chest)
	return chest


func _validate_treasure_ui_flow() -> void:
	var main_scene := load(MAIN_SCENE_PATH) as PackedScene
	var main := main_scene.instantiate() if main_scene != null else null
	_expect(main != null, "Treasure UI fixture should instantiate Main")
	if main == null:
		return
	root.add_child(main)
	await process_frame
	await process_frame
	var run_director := root.get_node_or_null("/root/RunDirector")
	var game := root.get_node_or_null("/root/Game")
	_expect(run_director != null and game != null, "Treasure UI fixture needs production directors")
	if run_director == null or game == null:
		return
	run_director.show_character_select()
	await process_frame
	_expect(run_director.start_production_run(0), "Treasure UI fixture should start a production run")
	await process_frame
	await physics_frame
	_run_state.set("_card_stacks", {"treasure_instinct": 1})
	var stage: Variant = game.current_stage
	var chest: ChestInteractable
	if stage != null:
		for reward in stage.get_spawned_rewards():
			if reward is ChestInteractable and bool(reward.get_claim_context().get("optional_route", false)):
				chest = reward
				break
	_expect(chest != null, "production Stage 1 should expose an optional chest")
	if chest == null:
		return
	var director_request := Callable(run_director, "_on_treasure_choice_requested")
	var director_was_connected := _signal_bus.is_connected(
		"reward_preview_replacement_requested",
		director_request
	)
	_expect(director_was_connected, "production director should listen for Treasure choices")
	if director_was_connected:
		_signal_bus.disconnect("reward_preview_replacement_requested", director_request)
	var synchronous_fallback := func(snapshot: Dictionary) -> void:
		_run_state.commit_optional_chest_choice(
			StringName(snapshot.get("request_id", &"")),
			TreasureChoiceService.NORMAL_CHOICE_ID
		)
	_signal_bus.connect("reward_preview_replacement_requested", synchronous_fallback)
	var init_failure_chest := ChestInteractable.new()
	init_failure_chest.configure_reward(
		&"cache_reward",
		&"optional_cache_ruin",
		&"treasure_ui_init_failure",
		_run_state,
		_run_state.reward_catalog,
		{
			"request_id": &"treasure_ui_init_failure",
			"stage_index": _run_state.current_stage_index,
			"room_id": &"ui_init_failure_room",
			"source_id": &"ui_init_failure_source",
			"optional_route": true,
		}
	)
	stage.add_child(init_failure_chest)
	var init_failure_coins: int = _run_state.coins
	init_failure_chest.interact(stage.player)
	_signal_bus.disconnect("reward_preview_replacement_requested", synchronous_fallback)
	if director_was_connected:
		_signal_bus.connect("reward_preview_replacement_requested", director_request)
	_expect(init_failure_chest.is_claimed(), "synchronous UI fallback should settle its source chest")
	_expect(_run_state.coins > init_failure_coins, "synchronous UI fallback should preserve normal reward")
	_expect(_run_state.get_pending_optional_chest_choice().is_empty(), "synchronous UI fallback should not leave pending state")
	_expect(not init_failure_chest.interaction_enabled, "settled fallback chest should remain disabled")

	var fallback_chest := ChestInteractable.new()
	fallback_chest.configure_reward(
		&"cache_reward",
		&"optional_cache_ruin",
		&"treasure_ui_fallback",
		_run_state,
		_run_state.reward_catalog,
		{
			"request_id": &"treasure_ui_fallback",
			"stage_index": _run_state.current_stage_index,
			"room_id": &"ui_fallback_room",
			"source_id": &"ui_fallback_source",
			"optional_route": true,
		}
	)
	stage.add_child(fallback_chest)
	var fallback_coins: int = _run_state.coins
	fallback_chest.interact(stage.player)
	await process_frame
	_expect(game.reward_choice_open, "fallback fixture should open the Treasure modal")
	run_director.call("_clear_screen")
	await process_frame
	_expect(fallback_chest.is_claimed(), "closing the modal should settle the normal fallback")
	_expect(_run_state.coins > fallback_coins, "modal fallback should preserve the normal chest reward")
	_expect(_run_state.get_pending_optional_chest_choice().is_empty(), "modal fallback should clear pending state")
	_expect(not game.reward_choice_open and not root.get_tree().paused, "modal fallback should resume gameplay")

	var coins_before: int = _run_state.coins
	chest.interact(stage.player)
	await process_frame
	var choice_screen: Control = run_director.current_screen
	_expect(game.reward_choice_open and root.get_tree().paused, "Treasure choice should pause gameplay")
	_expect(choice_screen != null and choice_screen.name == "TreasureChoice", "Treasure choice should mount its production modal")
	var replacement_button: Button
	if choice_screen != null:
		_expect(choice_screen.find_child("Choice_normal_reward", true, false) != null, "modal should expose the normal reward")
		replacement_button = choice_screen.find_child(
			"Choice_treasure_replacement",
			true,
			false
		) as Button
		_expect(replacement_button != null, "modal should expose the replacement reward")
	var pending: Dictionary = _run_state.get_pending_optional_chest_choice()
	if choice_screen != null and replacement_button != null:
		choice_screen.set("_request_id", &"wrong_ui_request")
		replacement_button.emit_signal("pressed")
		await process_frame
		_expect(game.reward_choice_open and root.get_tree().paused, "rejected UI commit should keep gameplay paused")
		_expect(run_director.current_screen == choice_screen, "rejected UI commit should keep the modal mounted")
		_expect(not replacement_button.disabled, "rejected UI commit should restore button input")
		choice_screen.set("_request_id", StringName(pending.get("request_id", &"")))
		replacement_button.emit_signal("pressed")
	await process_frame
	_expect(not game.reward_choice_open and not root.get_tree().paused, "committed Treasure choice should resume gameplay")
	_expect(run_director.current_screen == null, "committed Treasure choice should remove its modal")
	_expect(chest.is_claimed(), "production modal commitment should settle the source chest")
	_expect(_run_state.coins == coins_before, "production replacement should discard normal chest currency")
	game.close_overlays()
	game.unload_current_stage()
	main.queue_free()
	await process_frame


func _seed_skill_cooldowns(base: float) -> Dictionary:
	var cooldowns: Dictionary = {}
	for index in _kit.skills.size():
		var skill := _kit.skills[index]
		if skill != null:
			cooldowns[String(skill.id)] = base + float(index)
	_combat.set("_cooldowns", cooldowns.duplicate(true))
	return cooldowns


func _current_skill_cooldowns() -> Dictionary:
	var cooldowns: Dictionary = {}
	for skill in _kit.skills:
		if skill != null:
			cooldowns[String(skill.id)] = _combat.get_cooldown_remaining(skill.id)
	return cooldowns


func _offset_cooldowns(source: Dictionary, offset: float) -> Dictionary:
	var result: Dictionary = {}
	for key in source:
		result[key] = maxf(float(source[key]) + offset, 0.0)
	return result


func _cooldowns_match(expected: Dictionary) -> bool:
	var actual := _current_skill_cooldowns()
	if actual.size() != expected.size():
		return false
	for key in expected:
		if not is_equal_approx(float(actual.get(key, -1.0)), float(expected[key])):
			return false
	return true


func _room_context(room_id: StringName) -> Dictionary:
	return {
		"stage_id": &"fixture_stage",
		"stage_index": _run_state.current_stage_index,
		"room_id": room_id,
		"required_encounter_ids": ["%s_enemy" % room_id],
	}


func _spawn_enemy(position: Vector2, health: int) -> Node:
	var enemy: Variant = _enemy_script.new()
	enemy.position = position
	enemy.max_health = health
	enemy.stagger_capacity = 999
	enemy.hit_knockback_multiplier = 0.0
	enemy.auto_reset_on_defeat = false
	_world.add_child(enemy)
	return enemy


func _add_floor() -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(100.0, 112.0)
	body.collision_layer = 1
	body.collision_mask = 0
	_world.add_child(body)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(700.0, 24.0)
	collision.shape = rectangle
	body.add_child(collision)


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _clear_fixture() -> void:
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	await process_frame
	_world = null
	_player = null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _run_state != null:
		_run_state.call("start_new_run", 0, 74018)
	if _failures.is_empty():
		print("REMAINING_CARDS_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
