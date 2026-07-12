extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT_PATH := "res://scripts/enemies/EnemyBase.gd"
const ASSASSIN_PROFILE := preload("res://data/characters/assassin_profile.tres")
const ASSASSIN_KIT := preload("res://data/characters/assassin_kit.tres")
const AFTERIMAGE := preload("res://data/cards/assassin_afterimage.tres")
const RED_SEQUENCE := preload("res://data/cards/assassin_red_sequence.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const HOOKED_BLADES := preload("res://data/equipment/items/hooked_blades.tres")

var _failures: Array[String] = []
var _world: Node2D
var _player: Variant
var _run_state: Node
var _base_card_catalog: CardCatalog


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	var game := root.get_node_or_null("/root/Game")
	_expect(_run_state != null and game != null, "Assassin progression fixture needs autoloads")
	if _run_state == null or game == null:
		_finish()
		return
	game.ensure_input_map()
	_base_card_catalog = _run_state.card_catalog
	await _validate_bleed_sources_and_hooked_distance()
	await _validate_slipstream()
	await _validate_lingering_smoke()
	await _validate_fan_return_and_opportunist()
	await _validate_perfect_exit()
	await _validate_afterimage()
	await _validate_red_sequence()
	await _validate_reset_cleanup()
	_finish()


func _validate_bleed_sources_and_hooked_distance() -> void:
	var effects := _mastery_effects([&"assassin_serrated_second"])
	for effect in HOOKED_BLADES.behavior_effects:
		effects.append(effect)
	await _create_fixture(effects)
	var enemy: Variant = _spawn_enemy(Vector2(45.0, 100.0), 30, true)
	await _physics_steps(2)
	Input.action_press("attack")
	await _physics_steps(24)
	Input.action_release("attack")
	await _physics_steps(14)
	_expect(enemy.current_health == 28, "Twin Cut should preserve two primary one-damage hits")
	_expect(enemy._delayed_damage.size() == 2, "mastery and Hooked Blades should own separate bleed sources")
	_expect(enemy._delayed_damage.has("assassin_serrated_second"), "Serrated Second should register its source")
	_expect(enemy._delayed_damage.has("hooked_blades"), "Hooked Blades should register its source")
	await _physics_steps(125)
	_expect(enemy.current_health == 26, "both source-scoped bleeds should deal one damage after two seconds")
	await _clear_fixture()

	await _create_fixture(HOOKED_BLADES.behavior_effects)
	await _physics_steps(2)
	var start_x: float = _player.global_position.x
	await _tap_action("heavy_attack")
	await _physics_steps(58)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(absf((_player.global_position.x - start_x) - 130.0) <= 10.0, "Hooked Blades should reduce Lunge to about 130 pixels")
	_expect(absf(float(snapshot.get("motion_distance", 0.0)) - 130.0) <= 10.0, "Hooked Lunge snapshot should report its reduced distance")
	await _clear_fixture()


func _validate_slipstream() -> void:
	await _create_fixture(_mastery_effects([&"assassin_slipstream"]))
	var combat: Variant = _player.combat_controller
	var first: Variant = _spawn_enemy(Vector2(80.0, 100.0), 3, true)
	await _physics_steps(1)
	_player.dash_charges_left = 0
	_direct_primary_hit(combat, first, ASSASSIN_KIT.heavy_attack)
	var snapshot: Dictionary = combat.get_state_snapshot()
	_expect(_player.dash_charges_left == 1, "Slipstream should refund one missing dash charge")
	_expect(float(snapshot.get("slipstream_cooldown", 0.0)) > 4.9, "successful Slipstream should start its five-second ICD")
	_player.dash_charges_left = 0
	var second: Variant = _spawn_enemy(Vector2(120.0, 100.0), 3, true)
	_direct_primary_hit(combat, second, ASSASSIN_KIT.heavy_attack)
	_expect(_player.dash_charges_left == 0, "Slipstream should not refund during its ICD")
	await _clear_fixture()


func _validate_lingering_smoke() -> void:
	await _create_fixture(_mastery_effects([&"assassin_lingering_smoke"]))
	var enemy: Variant = _spawn_enemy(Vector2(5.0, 100.0), 20, true)
	await _physics_steps(2)
	await _tap_action("skill_1")
	await _physics_steps(7)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(float(snapshot.get("decoy_time", 0.0)) > 1.0, "Lingering Smoke should extend the decoy to 1.3 seconds")
	await _physics_steps(2)
	_expect(is_equal_approx(enemy.external_speed_scale, 0.65), "enemies entering Lingering Smoke should slow to 65 percent")
	_expect(enemy.external_slow_timer > 0.5, "Lingering Smoke slow should last 0.6 seconds")
	await _clear_fixture()


func _validate_fan_return_and_opportunist() -> void:
	await _create_fixture(_mastery_effects([&"assassin_fan_return"]))
	await _physics_steps(2)
	await _tap_action("skill_2")
	await _physics_steps(58)
	_expect(
		int(_player.combat_controller.get_state_snapshot().get("kunai_returns_spawned", 0)) == 2,
		"Fan Return should spawn exactly two returning Kunai"
	)
	await _clear_fixture()

	await _create_fixture(_mastery_effects([&"assassin_opportunist"]))
	_player.global_position = Vector2(100.0, 100.0)
	var enemy: Variant = _spawn_enemy(Vector2(0.0, 100.0), 50, true)
	await _physics_steps(2)
	var combat: Variant = _player.combat_controller
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	_expect(int(combat.get_state_snapshot().get("flow_stacks", 0)) == 2, "rear distinct hit should add base Flow plus Opportunist")
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	_expect(int(combat.get_state_snapshot().get("flow_stacks", 0)) == 3, "same-verb rear hit should still add Opportunist Flow and cap at three")
	await _clear_fixture()


func _validate_perfect_exit() -> void:
	var effects := _mastery_effects([&"assassin_perfect_exit"])
	await _create_fixture(effects)
	var enemy: Variant = _spawn_enemy(Vector2(100.0, 100.0), 80, true)
	await _physics_steps(2)
	await _tap_action("skill_3")
	await _physics_steps(32)
	var combat: Variant = _player.combat_controller
	combat._cooldowns[String(AssassinCombatRuntime.SMOKE_STEP_ID)] = 4.0
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.heavy_attack)
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.get_skill_by_slot(2))
	_expect(not combat._cooldowns.has(String(AssassinCombatRuntime.SMOKE_STEP_ID)), "Perfect Exit should reset Smoke after a no-damage mark")
	await _clear_fixture()

	await _create_fixture(effects)
	enemy = _spawn_enemy(Vector2(100.0, 100.0), 80, true)
	await _physics_steps(2)
	await _tap_action("skill_3")
	await _physics_steps(32)
	combat = _player.combat_controller
	combat._cooldowns[String(AssassinCombatRuntime.SMOKE_STEP_ID)] = 4.0
	combat.character_runtime.notify_player_damaged(1)
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.heavy_attack)
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.get_skill_by_slot(2))
	_expect(combat._cooldowns.has(String(AssassinCombatRuntime.SMOKE_STEP_ID)), "Perfect Exit should preserve Smoke cooldown after positive damage")
	await _clear_fixture()


func _validate_afterimage() -> void:
	await _create_fixture([], [AFTERIMAGE])
	_player.global_position = Vector2(180.0, 100.0)
	_player.facing = -1
	var enemy: Variant = _spawn_enemy(Vector2(100.0, 100.0), 30, true)
	await _physics_steps(2)
	var start_x: float = _player.global_position.x
	await _tap_action("heavy_attack")
	await _physics_steps(58)
	_expect(enemy.current_health == 22, "clean rear Lunge should deal 5 plus rounded 3 Afterimage damage")
	_expect(absf(absf(_player.global_position.x - start_x) - 150.0) <= 10.0, "Afterimage should not add player movement")
	await _clear_fixture()

	await _create_fixture([], [AFTERIMAGE])
	_add_static_rect(Vector2(76.0, 45.0), Vector2(20.0, 110.0), "AfterimageWall")
	enemy = _spawn_enemy(Vector2(42.0, 100.0), 30, true)
	await _physics_steps(2)
	await _tap_action("heavy_attack")
	await _physics_steps(58)
	_expect(enemy.current_health == 27, "wall-blocked Lunge should not trigger Afterimage")
	await _clear_fixture()


func _validate_red_sequence() -> void:
	await _create_fixture([], [RED_SEQUENCE])
	var marked: Variant = _spawn_enemy(Vector2(80.0, 100.0), 100, true)
	var nearby: Variant = _spawn_enemy(Vector2(130.0, 100.0), 30, true)
	await _physics_steps(2)
	var combat: Variant = _player.combat_controller
	_direct_primary_hit(combat, marked, ASSASSIN_KIT.basic_attack)
	_direct_primary_hit(combat, marked, ASSASSIN_KIT.heavy_attack)
	_direct_primary_hit(combat, marked, ASSASSIN_KIT.get_skill_by_slot(2))
	_expect(int(combat.get_state_snapshot().get("flow_stacks", 0)) == 3, "Red Sequence fixture should build three Flow")
	_direct_primary_hit(combat, marked, ASSASSIN_KIT.heavy_attack)
	_expect(int(combat.get_state_snapshot().get("red_sequence_mark_count", 0)) == 1, "Flow consumer should arm one Red Sequence mark")
	var marked_before := int(marked.current_health)
	var nearby_before := int(nearby.current_health)
	_direct_primary_hit(combat, marked, ASSASSIN_KIT.heavy_attack)
	_expect(int(combat.get_state_snapshot().get("red_sequence_mark_count", 0)) == 1, "same verb should not detonate Red Sequence")
	_direct_primary_hit(combat, marked, ASSASSIN_KIT.basic_attack)
	_expect(marked.current_health == marked_before - 7, "same Heavy plus distinct basic and area should resolve exact marked-target damage")
	_expect(nearby.current_health == nearby_before - 3, "Red Sequence should deal 3 secondary area damage")
	_expect(int(combat.get_state_snapshot().get("red_sequence_mark_count", 1)) == 0, "Red Sequence should clear after one detonation")
	await _clear_fixture()


func _validate_reset_cleanup() -> void:
	await _create_fixture([], [RED_SEQUENCE])
	var enemy: Variant = _spawn_enemy(Vector2(80.0, 100.0), 100, true)
	await _physics_steps(2)
	var combat: Variant = _player.combat_controller
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.heavy_attack)
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.get_skill_by_slot(2))
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.heavy_attack)
	var runtime: Variant = combat.character_runtime
	runtime.prepare_attack(ASSASSIN_KIT.get_skill_by_slot(3), {})
	runtime.activate_attack(ASSASSIN_KIT.get_skill_by_slot(3))
	runtime.prepare_attack(ASSASSIN_KIT.get_skill_by_slot(1), {})
	runtime.activate_attack(ASSASSIN_KIT.get_skill_by_slot(1))
	runtime.prepare_attack(ASSASSIN_KIT.get_skill_by_slot(2), {})
	runtime.activate_attack(ASSASSIN_KIT.get_skill_by_slot(2))
	var before: Dictionary = combat.get_state_snapshot()
	_expect(int(before.get("red_sequence_mark_count", 0)) == 1, "reset fixture should own a Red Sequence mark")
	_expect(int(before.get("death_mark_count", 0)) == 1, "reset fixture should own a Death Mark")
	_expect(float(before.get("decoy_time", 0.0)) > 0.0, "reset fixture should own a decoy")
	_expect(int(before.get("owned_projectiles", 0)) == 5, "reset fixture should own five Kunai")
	combat.reset_combat_state()
	await process_frame
	var after: Dictionary = combat.get_state_snapshot()
	_expect(int(after.get("flow_stacks", -1)) == 0, "reset should clear Flow")
	_expect(int(after.get("death_mark_count", -1)) == 0, "reset should clear Death Marks")
	_expect(int(after.get("red_sequence_mark_count", -1)) == 0, "reset should clear Red Sequence marks")
	_expect(is_zero_approx(float(after.get("decoy_time", -1.0))), "reset should clear the decoy")
	_expect(int(after.get("owned_projectiles", -1)) == 0, "reset should clear owned projectiles")
	_expect(enemy.get_node_or_null("AssassinDeathMark") == null, "reset should remove target status visuals")
	await _clear_fixture()


func _create_fixture(effects: Array = [], cards: Array = []) -> void:
	_expect(_run_state.start_new_run(2, 66107), "Assassin progression run should start")
	_install_cards(cards)
	_world = Node2D.new()
	_world.name = "AssassinProgressionFixture"
	root.add_child(_world)
	_add_static_rect(Vector2(0.0, 112.0), Vector2(2200.0, 24.0), "Floor")
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	_expect(player_scene != null, "Assassin progression fixture should load Player")
	if player_scene == null:
		return
	_player = player_scene.instantiate()
	_expect(_player != null, "Assassin progression fixture should instantiate Player")
	if _player == null:
		return
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	await _physics_steps(2)
	var profile := ASSASSIN_PROFILE.duplicate(true) as CharacterProfile
	profile.combat_kit = ASSASSIN_KIT
	_player.combat_controller.configure(profile, profile.to_stats_dictionary(), effects)
	_player.facing = 1


func _install_cards(cards: Array) -> void:
	var catalog := CardCatalog.new()
	catalog.id = &"assassin_progression_fixture_cards"
	catalog.display_name = "Assassin Progression Fixture Cards"
	catalog.cards = _base_card_catalog.cards.duplicate()
	var stacks: Dictionary = {}
	for value in cards:
		var card := value as CardDefinition
		if card == null:
			continue
		catalog.cards.append(card)
		stacks[String(card.id)] = 1
	_run_state.card_catalog = catalog
	_run_state.set("_card_stacks", stacks)


func _spawn_enemy(position: Vector2, health: int, lightweight: bool) -> Variant:
	var enemy_script := load(ENEMY_SCRIPT_PATH) as Script
	_expect(enemy_script != null, "Assassin progression fixture should load EnemyBase")
	if enemy_script == null:
		return null
	var enemy: Variant = enemy_script.new()
	enemy.position = position
	enemy.max_health = health
	enemy.stagger_capacity = 999
	enemy.hit_knockback_multiplier = 0.0
	enemy.auto_reset_on_defeat = false
	enemy.lightweight = lightweight
	_world.add_child(enemy)
	var contact := enemy.get_node_or_null("ContactHitbox") as Hitbox
	if contact != null:
		contact.set_active(false)
	return enemy


func _direct_primary_hit(
	combat: Variant,
	target: Node,
	definition: AttackDefinition,
	secondary: bool = false
) -> DamageInfo:
	combat._action_serial += 1
	return combat.apply_runtime_hit(target, definition, {}, secondary, {
		"action_serial": combat._action_serial,
		"verb_id": definition.id,
		"attack_direction": _player.facing,
	})


func _mastery_effects(node_ids: Array[StringName]) -> Array:
	var effects: Array = []
	for node_id in node_ids:
		var node := MASTERY_CATALOG.get_node(node_id)
		_expect(node != null, "mastery node '%s' should exist" % node_id)
		if node != null:
			for effect in node.behavior_effects:
				effects.append(effect)
	return effects


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
	await physics_frame
	await process_frame
	Input.action_release(action_name)


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _add_static_rect(center: Vector2, size: Vector2, node_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	_world.add_child(body)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)


func _clear_fixture() -> void:
	for action_name in ["attack", "heavy_attack", "skill_1", "skill_2", "skill_3"]:
		Input.action_release(action_name)
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	await process_frame
	_world = null
	_player = null
	_run_state.card_catalog = _base_card_catalog
	_run_state.set("_card_stacks", {})


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	for action_name in ["attack", "heavy_attack", "skill_1", "skill_2", "skill_3"]:
		Input.action_release(action_name)
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	if _run_state != null:
		_run_state.card_catalog = _base_card_catalog
		_run_state.set("_card_stacks", {})
	if _failures.is_empty():
		print("ASSASSIN_PROGRESSION_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
