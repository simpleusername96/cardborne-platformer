extends SceneTree

const Run = preload("res://scripts/vehicle/vehicle_run.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var run = Run.new()
	run.player_position = Vector2(600.0, 0.0)
	_validate_ranged_specialists(run)
	_validate_bombing_runner(run)
	_validate_scavenger(run)
	_finish()


func _enemy(id: String, role: StringName, position: Vector2) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = id
	enemy.role = role
	enemy.archetype = role
	enemy.pos = position
	enemy.speed = 160.0
	enemy.radius = 20.0
	enemy.alive = true
	enemy.active = true
	enemy.committed_dir = Vector2.RIGHT
	enemy.committed_target = Vector2(600.0, 0.0)
	return enemy


func _validate_ranged_specialists(run) -> void:
	var rail := _enemy("rail", &"rail_sniper", Vector2.ZERO)
	run.call("_begin_enemy_active", rail)
	_expect(run.hostile_projectiles.size() == 1, "rail sniper creates one committed hostile shot")
	_expect(rail.phase == &"recovery" and rail.reposition_time > 0.0, "rail sniper enters relocation recovery after firing")

	var orbit := _enemy("orbit", &"orbit_gunner", Vector2.ZERO)
	run.call("_begin_enemy_active", orbit)
	for _tick in 3:
		run.call("_update_enemy_active", orbit, 0.13)
	_expect(run.hostile_projectiles.size() == 4, "orbit gunner creates exactly one three-shot burst")
	_expect(orbit.phase == &"recovery", "orbit gunner enters recovery after the burst")


func _validate_bombing_runner(run) -> void:
	var bomber := _enemy("bomber", &"bombing_runner", Vector2.ZERO)
	run.call("_begin_enemy_active", bomber)
	_expect(run.denied_zones.size() == 3, "bombing runner schedules exactly three delayed ground bursts")
	_expect(run.denied_zones.all(func(zone): return StringName(zone["owner_kind"]) == &"ordinary" and float(zone["warning"]) > 0.0), "bombing ground bursts remain ordinary-owned warning zones")
	run.call("_update_enemy_active", bomber, 0.8)
	_expect(bomber.phase == &"recovery", "bombing runner completes its forward pass before recovering")


func _validate_scavenger(run) -> void:
	var scavenger := _enemy("scavenger", &"wreck_scavenger", Vector2.ZERO)
	var victim := _enemy("victim", &"shooter", Vector2(120.0, 0.0))
	run.enemies.append(scavenger)
	for _count in SpecialistRuntime.WRECK_SCAVENGER_MAX_STACKS + 2:
		run.call("_notify_wreck_scavengers_of_defeat", victim)
	_expect(run.call("_wreck_scavenger_stack_count", scavenger) == SpecialistRuntime.WRECK_SCAVENGER_MAX_STACKS, "wreck scavenger claims nearby eligible deaths before retirement and caps at five")
	_expect(is_equal_approx(float(run.call("_wreck_scavenger_damage_multiplier", scavenger)), 1.6), "five wreck stacks apply the configured damage modifier")
	_expect(is_equal_approx(float(run.call("_wreck_scavenger_speed_multiplier", scavenger)), 1.25), "five wreck stacks apply the configured speed modifier")
	_expect(is_equal_approx(float(run.call("_wreck_scavenger_attack_interval_multiplier", scavenger)), 0.8), "five wreck stacks apply the configured cooldown modifier")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SPECIALIST_ENEMY_INTEGRATION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
