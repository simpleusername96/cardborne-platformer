extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT := "res://scripts/enemies/EnemyBase.gd"

var _failures: Array[String] = []
var _world: Node2D
var _player: Variant
var _enemy: Variant
var _run_state: Node
var _last_hit: DamageInfo


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("/root/Game")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(game != null and _run_state != null, "combat fixture needs production autoloads")
	if game == null or _run_state == null:
		_finish()
		return
	game.ensure_input_map()
	_run_state.call("start_new_run", 0)

	_world = Node2D.new()
	_world.name = "WarriorCombatFixture"
	root.add_child(_world)
	_add_static_rect(Vector2(0.0, 112.0), Vector2(900.0, 24.0))
	if not _spawn_combatants():
		_finish()
		return
	await _physics_steps(5)

	await _validate_cleave_and_breaker()
	_validate_resolve_guard()
	await _validate_shield_rush()

	_world.queue_free()
	await process_frame
	_finish()


func _spawn_combatants() -> bool:
	var packed_player := load(PLAYER_SCENE) as PackedScene
	var enemy_script := load(ENEMY_SCRIPT) as Script
	_expect(packed_player != null, "combat fixture should load player scene")
	_expect(enemy_script != null, "combat fixture should load enemy base")
	if packed_player == null or enemy_script == null:
		return false

	_player = packed_player.instantiate()
	_enemy = enemy_script.new()
	_player.position = Vector2(0.0, 100.0)
	_enemy.position = Vector2(55.0, 100.0)
	_enemy.name = "TrainingTarget"
	_enemy.max_health = 20
	_enemy.stagger_capacity = 40
	_enemy.hit_knockback_multiplier = 0.0
	_enemy.auto_reset_on_defeat = false
	_world.add_child(_player)
	_world.add_child(_enemy)
	_enemy.damaged.connect(_on_enemy_damaged)

	var contact_hitbox := _enemy.get_node_or_null("ContactHitbox") as Hitbox
	if contact_hitbox != null:
		contact_hitbox.set_active(false)
	return true


func _validate_cleave_and_breaker() -> void:
	await _perform_action("attack", 31)
	_expect(_enemy.current_health == 18, "Cleave should deal exactly 2 damage")
	_expect(_enemy.stagger_meter == 20, "Cleave should add exactly 20 stagger")
	_expect(_last_hit != null and not _last_hit.critical, "Cleave should not roll a critical hit")

	await _perform_action("attack", 31)
	_expect(_enemy.current_health == 16, "second Cleave should deal exactly 2 damage")
	_expect(_enemy.is_staggered(), "two Cleaves should stagger a 40-capacity target")

	await _perform_action("heavy_attack", 27)
	_expect(_last_hit != null and _last_hit.critical, "Breaker should crit a staggered target")
	_expect(_last_hit != null and _last_hit.amount == 6, "critical Breaker should deal exactly 6 damage")
	_expect(_enemy.current_health == 10, "critical Breaker should leave the target at 10 HP")
	_expect(
		_player.combat_controller.guarded_timer > 0.0,
		"landing Breaker should arm Resolve Guard"
	)


func _validate_resolve_guard() -> void:
	_player.invulnerability_timer = 0.0
	var health_before: int = int(_run_state.get("current_health"))
	var source := Node2D.new()
	source.position = _player.position + Vector2(80.0, 0.0)
	_world.add_child(source)
	_player.receive_damage(DamageInfo.new(2, source, Vector2.ZERO, ["enemy_contact"]))
	_expect(
		int(_run_state.get("current_health")) == health_before - 1,
		"Resolve Guard should reduce the next 2-damage hit to 1"
	)
	_expect(
		_player.combat_controller.guarded_rearm_timer > 0.0,
		"consuming Resolve Guard should start its rearm timer"
	)
	source.queue_free()


func _validate_shield_rush() -> void:
	_player.combat_controller.reset_combat_state()
	_player.invulnerability_timer = 0.0
	_player.position = Vector2(-120.0, 100.0)
	_player.velocity = Vector2.ZERO
	await _physics_steps(3)
	var start_x: float = _player.position.x
	await _press_action("skill_1")
	await _physics_steps(11)
	_expect(
		_player.combat_controller.phase == PlayerCombatController.Phase.ACTIVE,
		"Shield Rush should enter its active phase after startup"
	)
	_expect(_player.position.x > start_x, "Shield Rush should move the player forward")

	var health_before: int = int(_run_state.get("current_health"))
	var source := Node2D.new()
	source.position = _player.position + Vector2(80.0, 0.0)
	_world.add_child(source)
	_player.receive_damage(DamageInfo.new(2, source, Vector2.ZERO, ["enemy_contact"]))
	_expect(
		int(_run_state.get("current_health")) == health_before,
		"active Shield Rush should block frontal enemy contact damage"
	)
	source.queue_free()
	await _physics_steps(24)


func _perform_action(action_name: String, settle_frames: int) -> void:
	await _press_action(action_name)
	await _physics_steps(settle_frames)


func _press_action(action_name: String) -> void:
	Input.action_press(action_name)
	await physics_frame
	await process_frame
	Input.action_release(action_name)


func _on_enemy_damaged(_damaged_enemy: Variant, damage_info: DamageInfo) -> void:
	_last_hit = damage_info


func _add_static_rect(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "Floor"
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
	Input.action_release("attack")
	Input.action_release("heavy_attack")
	Input.action_release("skill_1")
	if _failures.is_empty():
		print("WARRIOR_COMBAT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
