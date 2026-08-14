extends SceneTree

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const VehicleRun = preload("res://scripts/vehicle/vehicle_run.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_state_reset_contract()
	_validate_shield_sources()
	_validate_movement_reasons()
	_finish()


func _validate_state_reset_contract() -> void:
	var store := EnemyStore.new()
	var enemy: EnemyState = store.acquire()
	_expect(enemy.shielded == false, "fresh enemy begins unshielded")
	_expect(enemy.shield_source == &"none", "fresh enemy source is none")
	_expect(enemy.movement_reason == &"none", "fresh enemy movement reason is none")
	enemy.id = "diagnostic_reuse"
	enemy.alive = true
	enemy.active = true
	enemy.shielded = true
	enemy.shield_source = &"generator"
	enemy.movement_reason = &"pursuit_role"
	_expect(store.add(enemy), "diagnostic enemy enters store")
	enemy.alive = false
	store.queue_defeat(enemy)
	store.flush_defeated()
	var reused: EnemyState = store.acquire()
	_expect(reused.shielded == false, "reused enemy clears shield state")
	_expect(reused.shield_source == &"none", "reused enemy source clears")
	_expect(reused.movement_reason == &"none", "reused enemy movement reason clears")


func _validate_shield_sources() -> void:
	var run := VehicleRun.new()
	var enemy := EnemyState.new()
	var assignments := {"generator_target": &"generator"}
	enemy.id = "generator_target"
	run.call("_apply_enemy_shield", enemy, assignments)
	_expect(enemy.shielded and enemy.shield_source == &"generator", "generator assignment reports generator")
	assignments = {"escort_target": &"shield_escort"}
	enemy.id = "escort_target"
	run.call("_apply_enemy_shield", enemy, assignments)
	_expect(enemy.shielded and enemy.shield_source == &"shield_escort", "escort assignment reports shield escort")
	enemy.collective_mode = &"shield"
	enemy.collective_phase = &"execute"
	run.call("_apply_enemy_shield", enemy, {})
	_expect(enemy.shielded and enemy.shield_source == &"collective_tactic", "collective assignment reports collective tactic")
	enemy.collective_phase = &"dormant"
	run.call("_apply_enemy_shield", enemy, {})
	_expect(not enemy.shielded and enemy.shield_source == &"none", "absent assignment reports none")


func _validate_movement_reasons() -> void:
	var run := VehicleRun.new()
	var enemy := EnemyState.new()
	enemy.pos = Vector2.ZERO
	enemy.speed = 100.0
	enemy.collective_target = Vector2(100.0, 0.0)
	enemy.collective_phase = &"gather"
	_expect(bool(run.call("_update_collective_enemy", enemy, 0.1)), "collective gather is handled")
	_expect(enemy.movement_reason == &"collective_gather", "gather reason is exposed")
	enemy.collective_phase = &"lock"
	run.call("_update_collective_enemy", enemy, 0.1)
	_expect(enemy.movement_reason == &"collective_lock", "lock reason is exposed")
	enemy.collective_phase = &"execute"
	enemy.collective_mode = &"support"
	run.call("_update_collective_enemy", enemy, 0.1)
	_expect(enemy.movement_reason == &"collective_execute", "execute reason is exposed")
	enemy.collective_phase = &"dormant"
	enemy.movement_family = &"pursuit"
	enemy.role = &"chaser"
	run.player_position = Vector2(300.0, 0.0)
	run.call("_desired_enemy_velocity", enemy, false)
	_expect(enemy.movement_reason == &"pursuit_role", "pursuit role reason is exposed")
	run.call("_desired_enemy_velocity", enemy, true)
	_expect(enemy.movement_reason == &"recovery", "recovery reason is exposed")
	enemy.reposition_time = 0.25
	enemy.reposition_dir = Vector2.RIGHT
	run.call("_move_enemy_with_recovery", enemy, Vector2.RIGHT * enemy.speed, 0.1)
	_expect(enemy.movement_reason == &"wall_reposition", "wall reposition reason is exposed")
	var snapshot := enemy.behavior_diagnostics()
	_expect(snapshot["movement_reason"] == &"wall_reposition", "snapshot exposes movement reason")
	_expect(snapshot["shield_source"] == &"none", "snapshot exposes shield source")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_BEHAVIOR_DIAGNOSTICS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
