extends SceneTree

## Repeatable CPU pressure sample for the maximum authored vehicle-stage cap.
## This is evidence, not a cross-hardware unit assertion.

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const WARMUP_STEPS := 30
const MEASURED_STEPS := 300


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var standard_ok := bool(await _profile_preset(&"standard"))
	var onslaught_ok := bool(await _profile_preset(&"onslaught"))
	quit(0 if standard_ok and onslaught_ok else 1)


func _profile_preset(preset: StringName) -> bool:
	var packed := load("res://scenes/run/VehicleRun.tscn") as PackedScene
	var stage := packed.instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	stage.set_physics_process(false)
	stage.current_stage_index = 2
	stage.current_stage_id = StageCatalog.STAGE_IDS[2]
	stage.call("_reset_run", false, true, false)
	stage.mode = 1
	stage.encounter_runtime.preset = preset
	stage.encounter_runtime.current_beat = 4
	stage.call("_debug_append_packet_enemies", stage.encounter_runtime.active_cap() + 12)
	for enemy in stage.enemies:
		if bool(enemy.get("counts_active_cap", false)):
			enemy["active"] = true
			enemy["stun"] = 999.0
	stage.player_invulnerable = 999.0
	stage.call("_enforce_active_enemy_cap")
	for _index in WARMUP_STEPS:
		stage.call("_update_enemies", 1.0 / 60.0)
		stage.call("_update_projectiles", 1.0 / 60.0)

	var started := Time.get_ticks_usec()
	for _index in MEASURED_STEPS:
		stage.call("_update_enemies", 1.0 / 60.0)
		stage.call("_update_projectiles", 1.0 / 60.0)
	var elapsed := Time.get_ticks_usec() - started
	var active_capped := 0
	for enemy in stage.enemies:
		if bool(enemy["alive"]) and bool(enemy["active"]) and bool(enemy.get("counts_active_cap", false)):
			active_capped += 1
	var step_ms := elapsed / float(MEASURED_STEPS) / 1000.0
	var cap: int = int(stage.encounter_runtime.active_cap())
	print("VEHICLE_PRESSURE_PROFILE preset=%s active_capped=%d cap=%d steps=%d step_ms=%.3f within_8ms=%s" % [
		preset,
		active_capped,
		cap,
		MEASURED_STEPS,
		step_ms,
		str(step_ms < 8.0),
	])
	stage.queue_free()
	await process_frame
	return active_capped == cap and step_ms < 8.0
