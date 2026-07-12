extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT_PATH := "res://scripts/enemies/EnemyBase.gd"
const ASSASSIN_PROFILE := preload("res://data/characters/assassin_profile.tres")
const ASSASSIN_KIT := preload("res://data/characters/assassin_kit.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")

var _failures: Array[String] = []
var _world: Node2D
var _player: Variant
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	var game := root.get_node_or_null("/root/Game")
	_expect(_run_state != null and game != null, "Assassin fixture needs production autoloads")
	if _run_state == null or game == null:
		_finish()
		return
	game.ensure_input_map()
	await _validate_twin_cut_release_and_hold()
	await _validate_flow_contract()
	await _validate_shadow_lunge_rear_and_wall()
	await _validate_smoke_step()
	await _validate_kunai_cap_and_returns()
	await _validate_death_mark()
	_finish()


func _validate_twin_cut_release_and_hold() -> void:
	await _create_fixture()
	var enemy: Variant = _spawn_enemy(Vector2(45.0, 100.0), 20, true)
	await _physics_steps(2)
	await _tap_action("attack")
	await _physics_steps(34)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(enemy.current_health == 19, "released Twin Cut should hit exactly once")
	_expect(not bool(snapshot.get("twin_second_fired", true)), "released Twin Cut should not fire hit two")
	_expect(int(snapshot.get("twin_hit_counts", {}).get("1", 0)) == 1, "Twin Cut hit one should own its ledger")
	_expect(int(snapshot.get("twin_hit_counts", {}).get("2", 0)) == 0, "released Twin Cut should leave hit-two ledger empty")
	await _clear_fixture()

	await _create_fixture()
	enemy = _spawn_enemy(Vector2(45.0, 100.0), 20, true)
	await _physics_steps(2)
	Input.action_press("attack")
	await _physics_steps(24)
	Input.action_release("attack")
	await _physics_steps(14)
	snapshot = _player.combat_controller.get_state_snapshot()
	_expect(enemy.current_health == 18, "held Twin Cut should apply both one-damage hits")
	_expect(bool(snapshot.get("twin_second_committed", false)), "held Twin Cut should commit after first recovery")
	_expect(bool(snapshot.get("twin_second_fired", false)), "held Twin Cut should fire at the authored offset")
	_expect(int(snapshot.get("twin_hit_counts", {}).get("2", 0)) == 1, "Twin Cut hit two should own a separate ledger")
	await _clear_fixture()


func _validate_flow_contract() -> void:
	await _create_fixture()
	var enemy: Variant = _spawn_enemy(Vector2(80.0, 100.0), 80, true)
	await _physics_steps(2)
	var combat: Variant = _player.combat_controller
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	_expect(_flow_stacks(combat) == 1, "the first primary verb should grant one Flow")
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	_expect(_flow_stacks(combat) == 1, "same-verb repeats should not grant Flow")
	combat.character_runtime.update(1.0)
	var timer_before := float(combat.get_state_snapshot().get("flow_time", 0.0))
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.heavy_attack)
	_expect(_flow_stacks(combat) == 2, "a different Heavy verb should grant Flow")
	_expect(float(combat.get_state_snapshot().get("flow_time", 0.0)) > timer_before, "qualifying hits should refresh the shared Flow window")
	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.get_skill_by_slot(2))
	_expect(_flow_stacks(combat) == 3, "three distinct primary verbs should cap Flow at three")

	var health_before := int(enemy.current_health)
	var consumed: DamageInfo = _direct_primary_hit(combat, enemy, ASSASSIN_KIT.heavy_attack)
	_expect(consumed != null and consumed.amount == 5, "the consuming noncritical Heavy should gain exactly 2 damage")
	_expect(enemy.current_health == health_before - 5, "Flow bonus should resolve through the primary damage path")
	_expect(_flow_stacks(combat) == 0, "the first confirmed damaging Heavy should consume all Flow")
	var secondary: DamageInfo = _direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack, true)
	_expect(secondary != null and secondary.secondary_hit, "fixture should issue a secondary hit")
	_expect(_flow_stacks(combat) == 0, "secondary damage should not grant Flow")

	_direct_primary_hit(combat, enemy, ASSASSIN_KIT.basic_attack)
	combat.character_runtime.update(3.01)
	_expect(_flow_stacks(combat) == 0, "Flow expiry should remove every stack")
	_expect(is_zero_approx(float(combat.get_state_snapshot().get("flow_time", 1.0))), "expired Flow should expose zero time")
	await _clear_fixture()


func _validate_shadow_lunge_rear_and_wall() -> void:
	await _create_fixture()
	_player.global_position = Vector2(180.0, 100.0)
	_player.facing = -1
	var enemy: Variant = _spawn_enemy(Vector2(100.0, 100.0), 30, true)
	await _physics_steps(2)
	var start_x: float = _player.global_position.x
	await _tap_action("heavy_attack")
	await _physics_steps(58)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(enemy.current_health == 25, "rear Shadow Lunge should critical for 5 damage")
	_expect(absf(absf(_player.global_position.x - start_x) - 150.0) <= 10.0, "Shadow Lunge should travel about 150 pixels")
	_expect(not bool(snapshot.get("motion_hit_wall", true)), "open Shadow Lunge should record a clean completion")
	await _clear_fixture()

	await _create_fixture()
	_add_static_rect(Vector2(76.0, 45.0), Vector2(20.0, 110.0), "LungeWall")
	await _physics_steps(2)
	start_x = _player.global_position.x
	await _tap_action("heavy_attack")
	await _physics_steps(58)
	snapshot = _player.combat_controller.get_state_snapshot()
	_expect(_player.global_position.x < 62.0, "Shadow Lunge should stop before solid terrain")
	_expect(_player.global_position.x >= start_x, "wall collision should not displace Shadow Lunge backward")
	_expect(bool(snapshot.get("motion_hit_wall", false)), "blocked Shadow Lunge should record wall completion")
	await _clear_fixture()


func _validate_smoke_step() -> void:
	await _create_fixture()
	var enemy: Variant = _spawn_enemy(Vector2(220.0, 100.0), 20, true)
	await _physics_steps(2)
	var start_x: float = _player.global_position.x
	await _tap_action("skill_1")
	await _physics_steps(6)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(_player.invulnerability_timer > 0.0, "Smoke Step should grant active-phase invulnerability")
	_expect(float(snapshot.get("decoy_time", 0.0)) > 0.0, "Smoke Step should expose active decoy time")
	var decoys: Array[Node] = get_nodes_in_group("enemy_decoy")
	_expect(decoys.size() == 1, "Smoke Step should create one enemy-decoy target")
	if not decoys.is_empty():
		_expect(enemy.get_priority_target() == decoys[0], "enemies should prefer the active Smoke decoy")
	var health_before := int(_run_state.current_health)
	_player.receive_damage(DamageInfo.new(2, enemy, Vector2.ZERO, ["enemy_contact"]))
	_expect(_run_state.current_health == health_before, "Smoke active invulnerability should block incoming damage")
	await _physics_steps(25)
	_expect(absf((_player.global_position.x - start_x) - 120.0) <= 10.0, "Smoke Step should travel about 120 collision-safe pixels")
	await _clear_fixture()


func _validate_kunai_cap_and_returns() -> void:
	await _create_fixture()
	var enemy: Variant = _spawn_enemy(Vector2(48.0, 100.0), 20, true)
	await _physics_steps(2)
	await _tap_action("skill_2")
	await _physics_steps(16)
	_expect(
		enemy.current_health == 17,
		"one Kunai activation should cap one target at three damage (health %d)"
		% int(enemy.current_health)
	)
	await _clear_fixture()

	await _create_fixture(_mastery_effects([&"assassin_fan_return"]))
	await _physics_steps(2)
	await _tap_action("skill_2")
	await _physics_steps(58)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(int(snapshot.get("kunai_returns_spawned", 0)) == 2, "Fan Return should reverse exactly two max-range projectiles")
	await _physics_steps(55)
	snapshot = _player.combat_controller.get_state_snapshot()
	_expect(int(snapshot.get("kunai_returns_spawned", 0)) == 2, "returned Kunai should not recurse into more returns")
	await _clear_fixture()


func _validate_death_mark() -> void:
	await _create_fixture()
	var behind: Variant = _spawn_enemy(Vector2(-35.0, 100.0), 30, true)
	var ahead: Variant = _spawn_enemy(Vector2(100.0, 100.0), 50, true)
	await _physics_steps(2)
	await _tap_action("skill_3")
	await _physics_steps(32)
	var combat: Variant = _player.combat_controller
	var snapshot: Dictionary = combat.get_state_snapshot()
	_expect(int(snapshot.get("death_mark_count", 0)) == 1, "Death Mark should mark exactly one target")
	_expect(ahead.get_node_or_null("AssassinDeathMark") != null, "Death Mark should select the nearest valid forward target")
	_expect(behind.get_node_or_null("AssassinDeathMark") == null, "Death Mark should ignore targets behind the player")
	_direct_primary_hit(combat, ahead, ASSASSIN_KIT.basic_attack)
	_direct_primary_hit(combat, ahead, ASSASSIN_KIT.basic_attack)
	_direct_primary_hit(combat, ahead, ASSASSIN_KIT.heavy_attack)
	snapshot = combat.get_state_snapshot()
	_expect(int(snapshot.get("death_mark_count", 0)) == 1, "duplicate verbs should not advance Death Mark")
	var death_marks: Array = snapshot.get("death_marks", [])
	_expect(
		not death_marks.is_empty()
		and int((death_marks[0] as Dictionary).get("distinct_verbs", 0)) == 2,
		"Death Mark should expose two distinct verbs"
	)
	var health_before := int(ahead.current_health)
	_direct_primary_hit(combat, ahead, ASSASSIN_KIT.get_skill_by_slot(2))
	_expect(ahead.current_health == health_before - 5, "third distinct verb should add a 4-damage detonation")
	_expect(int(ahead.stagger_meter) >= 40, "Death Mark detonation should add 40 stagger")
	_expect(int(combat.get_state_snapshot().get("death_mark_count", 1)) == 0, "Death Mark should clear after detonation")
	await _clear_fixture()


func _create_fixture(effects: Array = []) -> void:
	_expect(_run_state.start_new_run(2, 66061), "Assassin fixture run should start")
	_world = Node2D.new()
	_world.name = "AssassinCombatFixture"
	root.add_child(_world)
	_add_static_rect(Vector2(0.0, 112.0), Vector2(2200.0, 24.0), "Floor")
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	_expect(player_scene != null, "Assassin fixture should load Player")
	if player_scene == null:
		return
	_player = player_scene.instantiate()
	_expect(_player != null, "Assassin fixture should instantiate Player")
	if _player == null:
		return
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	await _physics_steps(2)
	var profile := ASSASSIN_PROFILE.duplicate(true) as CharacterProfile
	profile.combat_kit = ASSASSIN_KIT
	_player.combat_controller.configure(profile, profile.to_stats_dictionary(), effects)
	_player.facing = 1


func _spawn_enemy(position: Vector2, health: int, lightweight: bool) -> Variant:
	var enemy_script := load(ENEMY_SCRIPT_PATH) as Script
	_expect(enemy_script != null, "Assassin fixture should load EnemyBase")
	if enemy_script == null:
		return null
	var enemy: Variant = enemy_script.new()
	_expect(enemy != null, "Assassin fixture should instantiate EnemyBase")
	if enemy == null:
		return null
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


func _flow_stacks(combat: Variant) -> int:
	return int(combat.get_state_snapshot().get("flow_stacks", 0))


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	for action_name in ["attack", "heavy_attack", "skill_1", "skill_2", "skill_3"]:
		Input.action_release(action_name)
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	if _failures.is_empty():
		print("ASSASSIN_COMBAT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
