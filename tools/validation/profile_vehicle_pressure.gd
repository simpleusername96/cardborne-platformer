extends SceneTree

## Fast subsystem trend sample. It excludes rendered-frame orchestration and is
## never release or user-visible smoothness evidence.

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const WARMUP_STEPS := 30
const MEASURED_STEPS := 300
const FIXED_DELTA := 1.0 / 60.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hard_ok := bool(await _profile_difficulty(RunDifficulty.HARD))
	quit(0 if hard_ok else 1)


func _profile_difficulty(difficulty: StringName) -> bool:
	var packed := load("res://scenes/run/VehicleRun.tscn") as PackedScene
	var stage := packed.instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	stage.set_physics_process(false)
	stage.current_stage_index = StageCatalog.STAGE_IDS.size() - 1
	stage.current_stage_id = StageCatalog.STAGE_IDS[-1]
	stage.selected_run_difficulty = difficulty
	stage.call("_reset_run", false, true, false)
	stage.mode = 1
	stage.encounter_runtime.current_beat = 4
	stage.call("_debug_append_packet_enemies", 320)
	var mobile_index := 0
	for enemy in stage.enemies:
		if enemy.counts_active_cap:
			enemy.active = true
			enemy.stun = 0.0
			var ring := mobile_index / 12
			var angle := TAU * float(mobile_index % 12) / 12.0
			var position: Vector2 = stage.player_position + Vector2.RIGHT.rotated(angle) * (260.0 + float(ring) * 95.0)
			enemy.pos = position
			enemy.home = position
			enemy.leash_rect = Rect2(stage.player_position - Vector2(1200.0, 1000.0), Vector2(2400.0, 2000.0))
			mobile_index += 1
	stage.player_invulnerable = 999.0
	stage.call("_enforce_active_enemy_cap")
	for shard_index in 192:
		stage.experience_runtime.spawn_shard(Vector2(4200.0 + float(shard_index % 12), 2600.0 + float(shard_index / 12)), 1)
	for _index in WARMUP_STEPS:
		stage.call("_update_enemies", FIXED_DELTA, stage.player_position)
		stage.call("_update_projectiles", FIXED_DELTA)
		stage.call("_update_experience", FIXED_DELTA)

	var moving_ms := _measure_steps(func() -> void:
		stage.call("_update_enemies", FIXED_DELTA, stage.player_position)
		stage.call("_update_projectiles", FIXED_DELTA)
		stage.call("_update_experience", FIXED_DELTA)
	)
	var ui = stage.get("_ui")
	var hud_ms := _measure_steps(func() -> void:
		ui.call("update_hud", stage.call("_build_hud_snapshot"))
	)
	var scheduler := _profile_saturated_scheduler(difficulty)
	var active_capped := 0
	for enemy in stage.enemies:
		if enemy.alive and enemy.active and enemy.counts_active_cap:
			active_capped += 1
	var scheduler_ms := float(scheduler["step_ms"])
	var combined_ms := moving_ms + hud_ms + scheduler_ms
	var cap: int = int(stage.encounter_runtime.active_cap())
	var shard_count: int = stage.experience_runtime.shards.size()
	var result := (
		active_capped == cap
		and shard_count == 192
		and int(scheduler["queued_windows"]) > 0
	)
	print("WARNING vehicle_pressure_microbenchmark excludes rendering and complete frame orchestration")
	print("vehicle_pressure_microbenchmark difficulty=%s active_capped=%d cap=%d shards=%d queued=%d steps=%d moving_ms=%.3f hud_ms=%.3f scheduler_ms=%.3f combined_ms=%.3f" % [
		difficulty,
		active_capped,
		cap,
		shard_count,
		int(scheduler["queued_windows"]),
		MEASURED_STEPS,
		moving_ms,
		hud_ms,
		scheduler_ms,
		combined_ms,
	])
	stage.queue_free()
	await process_frame
	return result


func _measure_steps(action: Callable) -> float:
	var started := Time.get_ticks_usec()
	for _index in MEASURED_STEPS:
		action.call()
	return (Time.get_ticks_usec() - started) / float(MEASURED_STEPS) / 1000.0


func _profile_saturated_scheduler(difficulty: StringName) -> Dictionary:
	var runtime := EncounterRuntime.new()
	runtime.configure(StageCatalog.STAGE_IDS[-1], StageCatalog.packets(StageCatalog.STAGE_IDS[-1]), difficulty)
	for event_id in [&"approach_entered", &"calibration_claimed", &"upper_route_entered", &"lower_route_entered", &"generators_complete"]:
		runtime.signal_event(event_id)
	runtime.tick(6.0, 999)
	var step_ms := _measure_steps(func() -> void:
		runtime.tick(FIXED_DELTA, 999)
	)
	return {
		"step_ms": step_ms,
		"queued_windows": int(runtime.debug_snapshot()["queued_windows"]),
	}
