extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT_PATH := "res://scripts/enemies/EnemyBase.gd"
const CARD_PATHS: Array[String] = [
	"res://data/cards/kinetic_refund.tres",
	"res://data/cards/second_wind.tres",
	"res://data/cards/last_stand.tres",
	"res://data/cards/treasure_instinct.tres",
]

var _failures: Array[String] = []
var _run_state: Variant
var _signal_bus: Node
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
	_validate_treasure_instinct()
	await _clear_fixture()
	_finish()


func _prepare_run_state() -> bool:
	_run_state = root.get_node_or_null("/root/RunState")
	_signal_bus = root.get_node_or_null("/root/SignalBus")
	if _run_state == null or _signal_bus == null:
		_expect(false, "remaining-card fixture needs RunState and SignalBus")
		return false
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
	var capture := func(request: Dictionary) -> void:
		requests.append(request.duplicate(true))
	_signal_bus.connect("reward_preview_replacement_requested", capture)
	_signal_bus.emit_signal("optional_route_chest_claimed", {
		"request_id": &"required_chest",
		"room_id": &"room_main",
		"optional_route": false,
	})
	_expect(requests.is_empty(), "Treasure Instinct should ignore required-route rewards")
	var optional_context := {
		"request_id": &"optional_chest_a",
		"stage_index": _run_state.current_stage_index,
		"room_id": &"room_optional",
		"source_id": &"cache_a",
		"optional_route": true,
	}
	_signal_bus.emit_signal("optional_route_chest_claimed", optional_context)
	_expect(requests.size() == 1, "Treasure Instinct should publish one replacement request")
	if requests.size() == 1:
		var request := requests[0]
		_expect(request.get("selection_policy") == &"replace_normal_reward", "Treasure choice should replace the normal reward")
		_expect(request.get("choice_pool") == &"compatible_equipment_or_forge", "Treasure choice should use the compatible preview pool")
		_expect(int(request.get("additional_choice_count", 0)) == 1, "Treasure choice should add one preview")
		_expect(request.get("request_id") == &"optional_chest_a", "Treasure request should retain source identity")
	_signal_bus.emit_signal("optional_route_chest_claimed", optional_context)
	_expect(requests.size() == 1, "a repeated chest claim should not duplicate the request")
	_expect(
		_runtime.get_state_snapshot().get("treasure_request_ids") == ["optional_chest_a"],
		"Treasure request ledger should be visible"
	)
	_combat.begin_stage()
	_signal_bus.emit_signal("optional_route_chest_claimed", optional_context)
	_expect(requests.size() == 2, "begin_stage should reset Treasure Instinct request scope")
	_signal_bus.disconnect("reward_preview_replacement_requested", capture)


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
