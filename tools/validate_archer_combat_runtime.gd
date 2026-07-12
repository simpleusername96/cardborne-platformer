extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT := "res://scripts/enemies/EnemyBase.gd"
const ARCHER_PROFILE := preload("res://data/characters/archer_profile.tres")
const ARCHER_KIT := preload("res://data/characters/archer_kit.tres")

var _failures: Array[String] = []
var _world: Node2D
var _player: Variant
var _enemies: Array = []
var _last_hits: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("/root/Game")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(game != null and run_state != null, "Archer fixture needs production autoloads")
	if game == null or run_state == null:
		_finish()
		return
	game.call("ensure_input_map")
	run_state.call("start_new_run", 0)

	_world = Node2D.new()
	_world.name = "ArcherCombatFixture"
	root.add_child(_world)
	_add_static_rect(Vector2(0.0, 112.0), Vector2(3000.0, 24.0), "Floor")
	_add_static_rect(Vector2(620.0, 0.0), Vector2(24.0, 1000.0), "Wall")
	if not _spawn_combatants():
		_finish()
		return
	await _physics_steps(5)
	_configure_archer([])

	await _validate_quick_shot()
	await _validate_marked_power_shot()
	await _validate_power_shot_target_cap()
	await _validate_rain_field_cap()
	await _validate_threadline_enemy_pull()
	await _validate_threadline_terrain_pull()
	_validate_cleanup()

	_world.queue_free()
	await process_frame
	_finish()


func _spawn_combatants() -> bool:
	var packed_player := load(PLAYER_SCENE) as PackedScene
	var enemy_script := load(ENEMY_SCRIPT) as Script
	_expect(packed_player != null, "Archer fixture should load the Player scene")
	_expect(enemy_script != null, "Archer fixture should load EnemyBase")
	if packed_player == null or enemy_script == null:
		return false
	_player = packed_player.instantiate()
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	for index in 3:
		var enemy: Variant = enemy_script.new()
		enemy.name = "ArcherTarget%d" % (index + 1)
		enemy.position = Vector2(180.0 + float(index) * 220.0, 100.0)
		enemy.max_health = 30
		enemy.stagger_capacity = 999
		enemy.hit_knockback_multiplier = 0.0
		enemy.auto_reset_on_defeat = false
		_world.add_child(enemy)
		enemy.damaged.connect(_on_enemy_damaged.bind(enemy))
		var contact := enemy.get_node_or_null("ContactHitbox") as Hitbox
		if contact != null:
			contact.set_active(false)
		_enemies.append(enemy)
	return true


func _configure_archer(effects: Array) -> void:
	var profile := ARCHER_PROFILE.duplicate(true) as CharacterProfile
	profile.combat_kit = ARCHER_KIT
	var stats := profile.to_base_stats_dictionary()
	_player.stats = stats
	_player.combat_controller.configure(profile, stats, effects)
	_expect(
		_player.combat_controller.character_runtime is ArcherCombatRuntime,
		"Archer profile fixture should instantiate ArcherCombatRuntime"
	)


func _validate_quick_shot() -> void:
	_reset_arena([Vector2(190.0, 100.0), Vector2(900.0, 100.0), Vector2(1100.0, 100.0)])
	await _press_action("attack")
	await _physics_steps(35)
	_expect(_enemies[0].current_health == 29, "Quick Shot should deal exactly 1 damage")
	var hit := _last_hits.get(_enemies[0].get_instance_id()) as DamageInfo
	_expect(hit != null and hit.attack_id == &"archer_quick_shot", "Quick Shot should resolve through its typed attack ID")
	_expect(hit != null and not hit.secondary_hit, "Quick Shot should be a primary hit")


func _validate_marked_power_shot() -> void:
	_reset_arena([Vector2(190.0, 100.0), Vector2(900.0, 100.0), Vector2(1100.0, 100.0)])
	await _press_action("skill_1")
	await _physics_steps(42)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(int(snapshot.get("hunter_mark_count", 0)) == 1, "Vault Shot should place one Hunter's Mark on its target")

	var health_before: int = int(_enemies[0].current_health)
	await _hold_action("heavy_attack", 52)
	await _physics_steps(30)
	var hit := _last_hits.get(_enemies[0].get_instance_id()) as DamageInfo
	_expect(hit != null and hit.critical, "Full-charge Power Shot should critically hit a marked target")
	_expect(hit != null and hit.amount == 6, "Marked full-charge Power Shot should deal 6 damage")
	_expect(_enemies[0].current_health == health_before - 6, "Power Shot should commit critical damage once")
	snapshot = _player.combat_controller.get_state_snapshot()
	_expect(int(snapshot.get("hunter_mark_count", 0)) == 0, "Critical Power Shot should consume Hunter's Mark")


func _validate_power_shot_target_cap() -> void:
	_reset_arena([Vector2(170.0, 100.0), Vector2(350.0, 100.0), Vector2(530.0, 100.0)])
	await _hold_action("heavy_attack", 52)
	await _physics_steps(55)
	_expect(_enemies[0].current_health == 26, "Power Shot should hit the first aligned target for 4")
	_expect(_enemies[1].current_health == 26, "Power Shot should pierce into the second aligned target")
	_expect(
		_enemies[2].current_health == 30,
		"Base Power Shot should stop before a third target (healths: %d/%d/%d)"
		% [_enemies[0].current_health, _enemies[1].current_health, _enemies[2].current_health]
	)


func _validate_rain_field_cap() -> void:
	_reset_arena([Vector2(220.0, 100.0), Vector2(900.0, 100.0), Vector2(1100.0, 100.0)])
	await _press_action("skill_2")
	await _physics_steps(125)
	_expect(_enemies[0].current_health == 27, "Rain Field should hit a centered target no more than three times")
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(int(snapshot.get("hunter_mark_count", 0)) == 1, "Rain Field should mark a target it hits")


func _validate_threadline_enemy_pull() -> void:
	_reset_arena([Vector2(220.0, 100.0), Vector2(900.0, 100.0), Vector2(1100.0, 100.0)])
	var start_x: float = float(_enemies[0].global_position.x)
	await _press_action("skill_3")
	await _physics_steps(18)
	_expect(start_x - _enemies[0].global_position.x >= 150.0, "Threadline should pull a light enemy up to 160 pixels")
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(int(snapshot.get("hunter_mark_count", 0)) == 1, "Threadline enemy contact should apply Hunter's Mark")


func _validate_threadline_terrain_pull() -> void:
	_reset_arena([Vector2(1000.0, 100.0), Vector2(1200.0, 100.0), Vector2(1400.0, 100.0)])
	_player.global_position = Vector2(300.0, -300.0)
	_player.velocity = Vector2.ZERO
	await _physics_steps(1)
	_player.dash_charges_left = 0
	_player.extra_jumps_left = 0
	var start_x: float = float(_player.global_position.x)
	await _press_action("skill_3")
	await _physics_steps(32)
	var travel := float(_player.global_position.x) - start_x
	_expect(travel > 100.0 and travel <= 160.5, "Terrain Threadline should use its bounded 160-pixel pull")
	_expect(_player.global_position.x < 608.0, "Terrain Threadline should stop before solid collision")
	_expect(
		_player.dash_charges_left == 0 and _player.extra_jumps_left == 0,
		"Terrain Threadline should not refresh jump or dash resources (dash %d, jump %d)"
		% [_player.dash_charges_left, _player.extra_jumps_left]
	)
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(bool(snapshot.get("threadline_active", false)), "Threadline snapshot should expose active terrain movement")
	await _physics_steps(12)
	_expect(
		float(_player.global_position.x) - start_x <= 160.5,
		"Threadline should not drift beyond its pull budget (travel %.2f)"
		% (float(_player.global_position.x) - start_x)
	)


func _validate_cleanup() -> void:
	_player.combat_controller.reset_combat_state()
	var snapshot: Dictionary = _player.combat_controller.get_state_snapshot()
	_expect(int(snapshot.get("hunter_mark_count", -1)) == 0, "Combat reset should clear Hunter's Marks")
	_expect(int(snapshot.get("rain_field_count", -1)) == 0, "Combat reset should clear Rain fields")
	_expect(not bool(snapshot.get("threadline_active", true)), "Combat reset should stop Threadline movement")


func _reset_arena(positions: Array[Vector2]) -> void:
	_player.combat_controller.reset_combat_state()
	_player.global_position = Vector2(0.0, 100.0)
	_player.velocity = Vector2.ZERO
	_player.facing = 1
	_last_hits.clear()
	for index in _enemies.size():
		var enemy: Variant = _enemies[index]
		enemy.reset_enemy()
		enemy.global_position = positions[index]
		var contact := enemy.get_node_or_null("ContactHitbox") as Hitbox
		if contact != null:
			contact.set_active(false)


func _press_action(action_name: String) -> void:
	Input.action_press(action_name)
	await physics_frame
	await process_frame
	Input.action_release(action_name)


func _hold_action(action_name: String, physics_steps: int) -> void:
	Input.action_press(action_name)
	await physics_frame
	await process_frame
	await _physics_steps(physics_steps)
	Input.action_release(action_name)


func _on_enemy_damaged(_enemy_signal: Variant, damage_info: DamageInfo, enemy: Variant) -> void:
	_last_hits[enemy.get_instance_id()] = damage_info


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


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	for action_name in ["attack", "heavy_attack", "skill_1", "skill_2", "skill_3"]:
		Input.action_release(action_name)
	if _failures.is_empty():
		print("ARCHER_COMBAT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
