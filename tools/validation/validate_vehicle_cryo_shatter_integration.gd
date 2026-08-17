extends SceneTree

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const PrimaryPayload = preload("res://scripts/combat/vehicle_primary_payload_profile.gd")
const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "main scene loads for Cryo shatter integration")
	if packed == null:
		_finish()
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var run = root.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active")
	if run == null:
		_finish()
		return
	run.call("_reset_run", false)
	run.call("_clear_enemies")
	run.call("_clear_projectiles")
	run.run_build.reset()
	run.run_build.apply(&"cryo_slow")
	var profile := PrimaryPayload.from_build(run.run_build)
	var enemy: EnemyState = run.call("_make_enemy", {
		"id":"cryo_shatter_target",
		"role":&"chaser",
		"pos":run.player_position + Vector2(180.0, 0.0),
		"active":true,
	})
	_expect(enemy != null and bool(run.call("_append_enemy", enemy)), "Cryo target enters collision truth")
	if enemy == null:
		_finish()
		return
	enemy.health = 1000.0
	enemy.max_health = 1000.0
	run.call("_rebuild_enemy_runtime_indexes")
	for hit_index in 3:
		_expect(
			run.projectile_store.add_player({
				"pos":enemy.pos - Vector2(24.0, 0.0),
				"velocity":Vector2.RIGHT * 500.0,
				"radius":run.PRIMARY_PROJECTILE_RADIUS,
				"damage":1.0,
				"structure_damage":1.0,
				"life":1.0,
				"owner":"player_primary",
				"primary_payload":profile,
				"combat_action_serial":hit_index + 1,
			}),
			"Cryo primary hit %d enters the fixed projectile pool" % (hit_index + 1)
		)
		run.call("_update_projectiles", 0.05)
	_expect(
		is_equal_approx(enemy.health, 979.0)
			and not enemy.statuses.has(&"chill"),
		"three primary hits apply three direct damage plus one 18-damage shatter and consume Chill"
	)
	var telemetry: Dictionary = run.stage_telemetry.stage_snapshot()
	_expect(
		is_equal_approx(float(telemetry["outgoing"].get(&"cryo_shatter", 0.0)), 18.0)
			and is_equal_approx(float(telemetry["attributes"].get(&"cryo", 0.0)), 18.0),
		"Cryo shatter records one player-owned Cryo damage contribution"
	)
	_expect(
		int(telemetry["status_applications"].get(&"chill", 0)) == 3,
		"all three Chill applications remain visible to bounded telemetry"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_CRYO_SHATTER_INTEGRATION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
