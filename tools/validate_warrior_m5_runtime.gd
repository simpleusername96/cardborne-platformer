extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT_PATH := "res://scripts/enemies/EnemyBase.gd"
const WARRIOR_KIT := preload("res://data/characters/warrior_kit.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const BELL_HAMMER := preload("res://data/equipment/items/bell_hammer.tres")
const COPPER_CHARM := preload("res://data/equipment/items/copper_charm.tres")
const SPRING_CHARM := preload("res://data/equipment/items/spring_charm.tres")

var _failures: Array[String] = []
var _world: Node2D
var _player: Variant
var _enemy: Variant
var _run_state: Node
var _last_hit: DamageInfo


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	var game := root.get_node_or_null("/root/Game")
	_expect(_run_state != null and game != null, "M5 Warrior fixture needs production autoloads")
	if _run_state == null or game == null:
		_finish()
		return
	game.ensure_input_map()
	_validate_typed_kit()
	await _validate_ground_splitter()
	await _validate_ground_splitter_stops_at_gap()
	await _validate_ground_splitter_stops_at_wall()
	await _validate_rally_use_and_expiry()
	await _validate_broad_guard()
	await _validate_driving_rush()
	await _validate_fracture()
	await _validate_aftershock()
	await _validate_steady_feet()
	await _validate_last_bastion()
	await _validate_equipment_behaviors()
	await _validate_parent_runtime_integration()
	_finish()


func _validate_typed_kit() -> void:
	_expect(WARRIOR_KIT.validate_definition().is_empty(), "complete Warrior kit should validate")
	var splitter := WARRIOR_KIT.get_skill_by_slot(2)
	var rally := WARRIOR_KIT.get_skill_by_slot(3)
	_expect(splitter != null and rally != null, "Warrior should expose all three skill slots")
	if splitter != null:
		_expect(
			_is_timing(splitter, 0.34, 0.35, 0.42, 8.0),
			"Ground Splitter should keep its exact timing and cooldown"
		)
		_expect(splitter.base_damage == 3, "Ground Splitter should deal exactly 3 damage")
		_expect(
			splitter.execution_mode == SkillDefinition.EXECUTION_GROUND_SHOCKWAVE,
			"Ground Splitter should use typed ground-shockwave execution"
		)
	if rally != null:
		_expect(
			_is_timing(rally, 0.25, 0.0, 0.25, 14.0),
			"Rally should keep its exact instant timing and cooldown"
		)
		_expect(
			is_equal_approx(rally.heavy_empower_window, 5.0)
			and is_equal_approx(rally.heavy_startup_scale, 0.7)
			and is_equal_approx(rally.heavy_echo_damage_scale, 0.5),
			"Rally should declare its exact Heavy empowerment"
		)


func _validate_ground_splitter() -> void:
	await _create_fixture()
	_enemy = _spawn_enemy(Vector2(135.0, 100.0), 20, true)
	await _physics_steps(2)
	await _press_action("skill_2")
	await _physics_steps(38)
	_expect(int(_enemy.current_health) == 17, "Ground Splitter should deal 3 damage once")
	_expect(_last_hit != null and not _last_hit.critical, "Ground Splitter cannot critical")
	_expect(_last_hit != null and _last_hit.secondary_hit == false, "Ground Splitter is a primary hit")
	_expect(
		_last_hit != null and _last_hit.knockback.y < -300.0,
		"Ground Splitter should apply launch knockback to a light enemy"
	)
	await _clear_fixture()


func _validate_ground_splitter_stops_at_gap() -> void:
	await _create_fixture([], false)
	_add_static_rect(Vector2(-40.0, 112.0), Vector2(200.0, 24.0), "StartFloor")
	_add_static_rect(Vector2(190.0, 112.0), Vector2(160.0, 24.0), "FarFloor")
	_enemy = _spawn_enemy(Vector2(165.0, 100.0), 20, true)
	await _physics_steps(2)
	await _press_action("skill_2")
	await _physics_steps(72)
	_expect(int(_enemy.current_health) == 20, "Ground Splitter should stop before a gap")
	await _clear_fixture()


func _validate_ground_splitter_stops_at_wall() -> void:
	await _create_fixture()
	_add_static_rect(Vector2(100.0, 54.0), Vector2(20.0, 116.0), "BlockingWall")
	_enemy = _spawn_enemy(Vector2(155.0, 100.0), 20, true)
	await _physics_steps(2)
	await _press_action("skill_2")
	await _physics_steps(72)
	_expect(int(_enemy.current_health) == 20, "Ground Splitter should stop at a solid wall")
	await _clear_fixture()


func _validate_rally_use_and_expiry() -> void:
	await _create_fixture()
	_enemy = _spawn_enemy(Vector2(58.0, 100.0), 20, false)
	await _physics_steps(2)
	var combat: Variant = _player.combat_controller
	var rally := WARRIOR_KIT.get_skill_by_slot(3)
	combat.call("_begin_attack", rally)
	_expect(combat.guarded_timer > 0.0, "Rally should arm Guard immediately")
	_expect(is_equal_approx(combat._rally_heavy_timer, 5.0), "Rally should arm a 5 second Heavy window")
	await _physics_steps(34)
	combat.call("_begin_attack", WARRIOR_KIT.heavy_attack)
	_expect(
		is_equal_approx(combat.phase_timer, 0.42 * 0.7),
		"Rally Heavy should start 30 percent faster"
	)
	_expect(is_zero_approx(combat._rally_heavy_timer), "Rally should clear when Heavy starts")
	await _physics_steps(70)
	_expect(int(_enemy.current_health) == 14, "Rally Heavy should add one nonrecursive 50 percent shockwave")
	await _clear_fixture()

	await _create_fixture()
	combat = _player.combat_controller
	combat.call("_begin_attack", rally)
	await _physics_steps(34)
	combat.update_combat(5.1)
	_expect(is_zero_approx(combat._rally_heavy_timer), "Rally should clear after 5 seconds")
	combat.call("_begin_attack", WARRIOR_KIT.heavy_attack)
	_expect(is_equal_approx(combat.phase_timer, 0.42), "expired Rally should not alter Heavy startup")
	await _clear_fixture()


func _validate_broad_guard() -> void:
	await _create_fixture(_mastery_effects([&"warrior_broad_guard"]))
	var combat: Variant = _player.combat_controller
	combat.guarded_timer = 1.0
	_player.receive_damage(DamageInfo.new(0, _enemy_source(), Vector2.ZERO, ["enemy_contact"]))
	_expect(combat.guarded_timer > 0.0, "zero-damage contact should not consume Broad Guard")
	var health_before: int = _run_state.current_health
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(2, _enemy_source(), Vector2.ZERO, ["enemy_projectile"]))
	_expect(_run_state.current_health == health_before, "Broad Guard should block one projectile")
	_expect(is_zero_approx(combat.guarded_timer), "Broad Guard projectile block should consume Guard")
	await _clear_fixture()


func _validate_driving_rush() -> void:
	await _create_fixture(_mastery_effects([&"warrior_driving_rush"]))
	_add_static_rect(Vector2(120.0, 54.0), Vector2(20.0, 116.0), "RushWall")
	_enemy = _spawn_enemy(Vector2(50.0, 100.0), 20, true)
	await _physics_steps(2)
	await _press_action("skill_1")
	await _physics_steps(38)
	_expect(int(_enemy.current_health) == 18, "Driving Rush should preserve Shield Rush damage")
	_expect(int(_enemy.stagger_meter) == 55, "wall-carried target should receive 20 extra stagger")
	_expect(not bool(_enemy._forced_carry_active), "Driving Rush should release its target at the wall")
	await _clear_fixture()


func _validate_fracture() -> void:
	await _create_fixture(_mastery_effects([&"warrior_fracture"]))
	_enemy = _spawn_enemy(Vector2(58.0, 100.0), 30, false)
	await _physics_steps(2)
	await _press_action("heavy_attack")
	await _physics_steps(70)
	_expect(int(_enemy.current_health) == 26, "Fracture Breaker should preserve base damage")
	_expect(float(_enemy.fractured_timer) > 0.0, "Breaker should apply Fractured for 4 seconds")
	_player.combat_controller.reset_combat_state()
	await _press_action("skill_2")
	await _physics_steps(50)
	_expect(int(_enemy.current_health) == 22, "next skill should consume Fractured for 1 extra damage")
	_expect(is_zero_approx(_enemy.fractured_timer), "Fractured should clear on the next skill hit")
	await _clear_fixture()


func _validate_aftershock() -> void:
	await _create_fixture(_mastery_effects([&"warrior_aftershock"]))
	_enemy = _spawn_enemy(Vector2(130.0, 100.0), 20, false)
	await _physics_steps(2)
	await _press_action("skill_2")
	await _physics_steps(80)
	_expect(int(_enemy.current_health) == 16, "Aftershock should add one delayed 1-damage hit")
	await _clear_fixture()


func _validate_steady_feet() -> void:
	await _create_fixture(_mastery_effects([&"warrior_steady_feet"]))
	var combat: Variant = _player.combat_controller
	combat.guarded_timer = 1.0
	var health_before: int = _run_state.current_health
	_player.receive_damage(DamageInfo.new(
		2,
		_enemy_source(),
		Vector2(200.0, -100.0),
		["enemy_contact"]
	))
	_expect(_run_state.current_health == health_before - 1, "Steady Feet should not alter Guard damage")
	_expect(_player.velocity.is_equal_approx(Vector2(100.0, -50.0)), "Steady Feet should halve guarded knockback")
	await _clear_fixture()


func _validate_last_bastion() -> void:
	await _create_fixture(_mastery_effects([&"warrior_last_bastion"]))
	var combat: Variant = _player.combat_controller
	var shield := WARRIOR_KIT.get_skill_by_slot(1)
	combat._cooldowns[String(shield.id)] = 4.0
	_player.receive_damage(DamageInfo.new(5, _enemy_source(), Vector2.ZERO, ["enemy_contact"]))
	_expect(_run_state.current_health == 1, "Last Bastion should not heal at 1 health")
	_expect(combat.guarded_timer > 0.0, "Last Bastion should arm Guard")
	_expect(not combat._cooldowns.has(String(shield.id)), "Last Bastion should reset Shield Rush")

	_run_state.heal_player(99)
	combat.guarded_timer = 0.0
	combat._cooldowns[String(shield.id)] = 4.0
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(5, _enemy_source(), Vector2.ZERO, ["enemy_contact"]))
	_expect(combat._cooldowns.has(String(shield.id)), "Last Bastion should trigger only once per stage")

	combat.begin_stage()
	_run_state.heal_player(99)
	combat.guarded_timer = 0.0
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(5, _enemy_source(), Vector2.ZERO, ["enemy_contact"]))
	_expect(not combat._cooldowns.has(String(shield.id)), "begin_stage should explicitly reset Last Bastion")
	await _clear_fixture()


func _validate_equipment_behaviors() -> void:
	await _create_fixture(BELL_HAMMER.behavior_effects)
	_enemy = _spawn_enemy(Vector2(58.0, 100.0), 30, false)
	await _physics_steps(2)
	var combat: Variant = _player.combat_controller
	var timing: Dictionary = combat.get_effective_timing(WARRIOR_KIT.heavy_attack)
	_expect(is_equal_approx(float(timing.get("startup", 0.0)), 0.42), "Bell Hammer should preserve Heavy startup")
	_expect(is_equal_approx(float(timing.get("recovery", 0.0)), 0.60), "Bell Hammer should add 0.12 recovery")
	await _press_action("heavy_attack")
	await _physics_steps(76)
	_expect(int(_enemy.current_health) == 25, "Bell Hammer Breaker should deal 5 damage")
	_expect(int(_enemy.stagger_meter) == 80, "Bell Hammer Breaker should deal 80 stagger")
	await _clear_fixture()

	await _create_fixture(SPRING_CHARM.behavior_effects)
	combat = _player.combat_controller
	_player.position.y = 40.0
	await _physics_steps(1)
	combat.notify_extra_jump_performed()
	combat.call("_begin_attack", WARRIOR_KIT.basic_attack)
	_expect(
		is_equal_approx(float(combat._active_attack_modifiers.get("stagger_additive", 0.0)), 15.0),
		"Spring Charm should add 15 stagger to the first aerial post-double-jump attack"
	)
	combat.reset_combat_state()
	combat.call("_begin_attack", WARRIOR_KIT.basic_attack)
	_expect(
		is_zero_approx(float(combat._active_attack_modifiers.get("stagger_additive", 0.0))),
		"Spring Charm should consume its one aerial attack bonus"
	)
	await _clear_fixture()

	_expect(
		PlayerProgressionEffectQuery.first_card_reroll_discount(COPPER_CHARM.behavior_effects) == 6,
		"Copper Charm should expose an exact 6-coin first-reroll discount query"
	)


func _validate_parent_runtime_integration() -> void:
	await _create_fixture(_mastery_effects([&"warrior_steady_feet"]))
	var combat: Variant = _player.combat_controller
	combat.guarded_timer = 1.0
	_run_state.set("_forge_guard_remaining", 1)
	_run_state.set("_forge_guard_value", 1)
	var health_before: int = _run_state.current_health
	_player.receive_damage(DamageInfo.new(
		3,
		_enemy_source(),
		Vector2(200.0, -100.0),
		["enemy_contact"]
	))
	_expect(
		_run_state.current_health == health_before - 1,
		"incoming damage should resolve Warrior Guard before temporary Forge Guard"
	)
	_expect(
		_player.velocity.is_equal_approx(Vector2(100.0, -50.0)),
		"Forge Guard should preserve Steady Feet knockback scaling"
	)
	_run_state.damage_player(2)
	var damaged_health: int = _run_state.current_health
	await _press_action("use_consumable")
	await _physics_steps(1)
	_expect(_run_state.current_health == damaged_health + 2, "consumable input should call RunState.use_consumable")
	_expect(int(_run_state.consumable_charges) == 0, "consumable input should spend one charge")
	await _clear_fixture()


func _create_fixture(effects: Array = [], add_floor: bool = true) -> void:
	_expect(_run_state.start_new_run(0, 55103), "Warrior fixture run should start")
	_world = Node2D.new()
	_world.name = "WarriorM5Fixture"
	root.add_child(_world)
	if add_floor:
		_add_static_rect(Vector2(100.0, 112.0), Vector2(800.0, 24.0), "Floor")
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	_expect(player_scene != null, "Warrior fixture should load the player scene")
	if player_scene == null:
		return
	_player = player_scene.instantiate()
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	await _physics_steps(2)
	_player.combat_controller.configure(
		_run_state.selected_profile,
		_run_state.get_effective_stats(),
		effects
	)


func _spawn_enemy(position: Vector2, health: int, lightweight: bool) -> Variant:
	var enemy_script := load(ENEMY_SCRIPT_PATH) as Script
	_expect(enemy_script != null, "Warrior fixture should load EnemyBase")
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
	enemy.damaged.connect(_on_enemy_damaged)
	var contact := enemy.get_node_or_null("ContactHitbox") as Hitbox
	if contact != null:
		contact.set_active(false)
	return enemy


func _mastery_effects(node_ids: Array[StringName]) -> Array:
	var effects: Array = []
	for node_id in node_ids:
		var node := MASTERY_CATALOG.get_node(node_id)
		_expect(node != null, "mastery node '%s' should exist" % node_id)
		if node != null:
			for effect in node.behavior_effects:
				effects.append(effect)
	return effects


func _enemy_source() -> Node2D:
	var source := Node2D.new()
	source.position = _player.position + Vector2(80.0, 0.0)
	_world.add_child(source)
	return source


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


func _press_action(action_name: String) -> void:
	Input.action_press(action_name)
	await physics_frame
	await process_frame
	Input.action_release(action_name)


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
	_enemy = null
	_last_hit = null


func _on_enemy_damaged(_damaged_enemy: Variant, damage_info: DamageInfo) -> void:
	_last_hit = damage_info


func _is_timing(
	definition: AttackDefinition,
	startup: float,
	active: float,
	recovery: float,
	cooldown: float
) -> bool:
	return (
		is_equal_approx(definition.startup_time, startup)
		and is_equal_approx(definition.active_time, active)
		and is_equal_approx(definition.recovery_time, recovery)
		and is_equal_approx(definition.cooldown, cooldown)
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	for action_name in ["attack", "heavy_attack", "skill_1", "skill_2", "skill_3", "use_consumable"]:
		Input.action_release(action_name)
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	if _failures.is_empty():
		print("WARRIOR_M5_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
