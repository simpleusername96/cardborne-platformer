extends SceneTree

const ENEMY_SCRIPT := "res://scripts/enemies/EnemyBase.gd"
const DECOY_SCRIPT := "res://scripts/player/combat/CombatDecoy.gd"
const PROJECTILE_SCRIPT := "res://scripts/player/PlayerAttackProjectile.gd"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	world.name = "CharacterRuntimeContractFixture"
	root.add_child(world)

	var fallback_player := Node2D.new()
	fallback_player.add_to_group("player")
	fallback_player.global_position = Vector2(800.0, 0.0)
	world.add_child(fallback_player)

	var enemy: Variant = load(ENEMY_SCRIPT).new()
	enemy.name = "RuntimeEnemy"
	enemy.max_health = 3
	enemy.gravity = 0.0
	enemy.auto_reset_on_defeat = false
	world.add_child(enemy)
	await process_frame

	var decoy: Variant = load(DECOY_SCRIPT).new()
	decoy.duration = 0.4
	decoy.global_position = Vector2(40.0, 0.0)
	world.add_child(decoy)
	await process_frame
	_expect(enemy.get_priority_target() == decoy, "active decoy should take aim priority")

	enemy.apply_external_slow(0.05, 0.6)
	_expect(is_equal_approx(enemy.get_external_speed_scale(), 0.6), "slow should apply its scale")
	enemy.call("_physics_process", 0.08)
	_expect(is_equal_approx(enemy.get_external_speed_scale(), 1.0), "slow should expire cleanly")

	enemy.apply_delayed_damage(&"bleed_fixture", 0.04, 1, fallback_player)
	enemy.apply_delayed_damage(&"bleed_fixture", 0.06, 1, fallback_player)
	enemy.call("_physics_process", 0.07)
	_expect(enemy.current_health == 2, "same-source delayed damage should refresh instead of stack")

	var termination := {"reason": &""}
	var projectile: Variant = load(PROJECTILE_SCRIPT).new()
	projectile.velocity = Vector2(1000.0, 0.0)
	projectile.max_distance = 10.0
	projectile.lifetime = 1.0
	projectile.terminated.connect(func(reason: StringName, _position: Vector2, _hits: int) -> void:
		termination["reason"] = reason
	)
	world.add_child(projectile)
	projectile.call("_physics_process", 0.02)
	await process_frame
	_expect(termination["reason"] == &"max_range", "projectile should publish max-range termination")

	world.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("CHARACTER_RUNTIME_CONTRACT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
