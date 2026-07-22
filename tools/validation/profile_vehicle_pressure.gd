extends SceneTree

## Repeatable CPU pressure sample for the maximum authored vehicle-stage cap.
## This is evidence, not a cross-hardware unit assertion.

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const WARMUP_STEPS := 30
const MEASURED_STEPS := 300


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
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
	for enemy in stage.enemies:
		enemy["active"] = false
	stage.call("_activate_capture_zone", "approach")
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
	print("VEHICLE_PRESSURE_PROFILE active_capped=%d cap=%d steps=%d step_ms=%.3f within_8ms=%s" % [
		active_capped,
		EncounterDirector.active_cap(StageCatalog.STAGE_IDS[2]),
		MEASURED_STEPS,
		step_ms,
		str(step_ms < 8.0),
	])
	stage.queue_free()
	quit()
