extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "main scene loads")
	if packed == null:
		_finish()
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var run = root.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active")
	if run != null:
		run.set_physics_process(false)
		run.set_process(false)
		_check_reward_recall_gate(run)
		run.call("_reset_run", false)
		_check_stage_one_to_three(run)
		run.call("_reset_run", false)
		_check_stage_five_no_offer_completion(run)
	root.queue_free()
	await process_frame
	_finish()


func _check_reward_recall_gate(run) -> void:
	run.mode = run.RunMode.PLAYING
	run.pending_stage_completion = true
	run.experience_recall_timer = 0.65
	run.experience_runtime.pending_level_ups = 1
	run.call("_advance_reward_queue")
	_expect(
		run.mode == run.RunMode.PLAYING,
		"recalled XP resolves before a mandatory level-up card can open"
	)
	run.experience_recall_timer = 0.0
	run.call("_advance_reward_queue")
	_expect(
		run.mode == run.RunMode.UPGRADE,
		"mandatory level-up card opens after XP recall completes"
	)


func _check_stage_one_to_three(run) -> void:
	var preserved_position := Vector2(2874.0, 1932.0)
	var preserved_hull_direction := Vector2(0.6, 0.8).normalized()
	var preserved_aim_direction := Vector2(-0.8, 0.6).normalized()
	var explored_cell := Vector2i(4, 7)
	run.mode = run.RunMode.PLAYING
	run.selected_run_difficulty = &"hard"
	run.player_position = preserved_position
	run.player_hull_direction = preserved_hull_direction
	run.player_aim_direction = preserved_aim_direction
	run.player_health = 17.0
	run.run_build.apply(&"chassis_speed")
	run.visited_cells[explored_cell] = true
	var field_fingerprint := int(run.field_layout.fingerprint)
	var run_feature_fingerprint := hash(
		var_to_str(run.field_layout.run_feature_blueprint())
	)
	var hazard_center := Vector2.ZERO
	for feature in run.field_layout.run_feature_blueprint():
		if StringName(feature.get("kind", &"")) == &"hazard_zone":
			hazard_center = Rect2(feature["rect"]).get_center()
			break
	run.terrain_runtime.hazard_damage_for_actor(
		"transition_fixture",
		hazard_center,
		hazard_center,
		24.0,
		&"ordinary",
		0.0
	)
	run.stage_flow.state = StageFlow.State.REWARDS
	run.call("_finalize_stage_completion")

	_expect(run.current_stage_id == &"stage_2", "Stage 1 clear advances directly to Stage 2")
	_expect(
		run.mode == run.RunMode.STAGE_TRANSITION,
		"Stage 1 clear enters the non-modal transition mode"
	)
	_expect(
		run.stage_flow.state == StageFlow.State.TRANSITION,
		"stage flow owns an explicit transition state"
	)
	_expect(run.player_position.is_equal_approx(preserved_position), "transition preserves player position")
	_expect(
		run.player_hull_direction.is_equal_approx(preserved_hull_direction)
			and run.player_aim_direction.is_equal_approx(preserved_aim_direction),
		"transition preserves hull facing and manual aim"
	)
	_expect(
		run.run_build.has(&"chassis_speed")
			and run.selected_run_difficulty == &"hard",
		"transition preserves build and run difficulty"
	)
	_expect(
		run.visited_cells.has(explored_cell)
			and int(run.field_layout.fingerprint) == field_fingerprint,
		"transition preserves exploration and run-scoped field identity"
	)
	_expect(
		hash(var_to_str(run.field_layout.run_feature_blueprint()))
			== run_feature_fingerprint
		and int(run.terrain_runtime.hazard_runtime_snapshot()["tracked_actor_count"]) == 0,
		"transition preserves run-fixed walls/hazards and clears exposure"
	)
	_expect(
		run.mystery_device_runtime.devices.size() == 3,
		"Stage 2 configures three fresh mystery devices"
	)
	_expect(
		is_equal_approx(run.player_health, run.call("_player_max_health"))
			and run.player_invulnerable >= 1.2,
		"transition fully repairs the hull and grants the authored safety window"
	)
	_expect(run.pickups.size() == 6 and run.crates.size() == 8, "Stage 2 items refresh to six loose and eight crates")
	_expect(run.completed_stage_reports.size() == 1, "Stage 1 telemetry is retained in run history")
	var ui = run.get_node_or_null("VehicleStageUI")
	_expect(
		ui != null
			and not ui.has_method("show_stage_transition")
			and not ui.has_method("hide_stage_transition")
			and not ui.has_method("debug_transition_banner"),
		"automatic stage progression exposes no redundant transition-banner API"
	)
	_expect(
		ui != null
			and ui.debug_hud_visible()
			and not ui.debug_surface_visible("report"),
		"Stage 1 success keeps the HUD visible and never opens the report modal"
	)
	run.call("_pause_run")
	_expect(
		run.mode == run.RunMode.PAUSED,
		"pause preserves transition state without a banner layer"
	)
	run.call("_resume_run")
	_expect(
		run.mode == run.RunMode.STAGE_TRANSITION
			and ui.debug_hud_visible(),
		"resuming restores automatic transition play with only the regular HUD"
	)

	run.call("_update_encounter", 0.35)
	var cue_snapshot: Dictionary = run.encounter_runtime.debug_snapshot()
	var cues_at_transition_start := _timeline_count(
		Array(cue_snapshot["timeline"]),
		&"cue",
		0.35
	)
	_expect(cues_at_transition_start == 4, "Stage 2 starts four arrival cues at 0.35 seconds")
	_expect(
		is_equal_approx(float(cue_snapshot["first_cue_time"]), 0.35),
		"Stage 2 first arrival cue uses the transition timeline"
	)
	_expect(
		not String(cue_snapshot["activated_packets"][0]).contains("scout"),
		"Stage 2 skips the deployment tutorial scout"
	)
	run.call("_update_encounter", 1.0)
	var spawn_snapshot: Dictionary = run.encounter_runtime.debug_snapshot()
	_expect(
		is_equal_approx(float(spawn_snapshot["first_spawn_time"]), 1.35),
		"Stage 2 begins hostile spawning at 1.35 seconds"
	)
	_expect(run.call("_active_mobile_count") == 4, "transition spawn scheduler admits four due enemies per tick")
	run.call("_update_stage_progression", 1.6)
	_expect(
		run.mode == run.RunMode.PLAYING
			and run.stage_flow.state == StageFlow.State.ORDINARY,
		"transition settles into ordinary play without a continue input"
	)

	var stage_2_position: Vector2 = Vector2(run.player_position) + Vector2(84.0, -52.0)
	run.player_position = stage_2_position
	run.player_health = 9.0
	run.stage_flow.state = StageFlow.State.REWARDS
	run.stage_complete = false
	run.call("_finalize_stage_completion")
	_expect(
		run.current_stage_id == &"stage_3"
			and run.mode == run.RunMode.STAGE_TRANSITION,
		"Stage 2 clear repeats the same automatic transition into Stage 3"
	)
	_expect(run.player_position.is_equal_approx(stage_2_position), "Stage 2→3 also preserves player position")
	_expect(
		hash(var_to_str(run.field_layout.run_feature_blueprint()))
			== run_feature_fingerprint,
		"Stage 3 keeps the same run-fixed inner walls and hazards"
	)
	_expect(
		run.run_build.has(&"chassis_speed")
			and run.visited_cells.has(explored_cell)
			and run.completed_stage_reports.size() == 2,
		"Stage 2→3 preserves build, exploration, and both telemetry snapshots"
	)
	_expect(
		int(run.terrain_runtime.hazard_runtime_snapshot()["tracked_actor_count"]) == 0,
		"Stage 2→3 clears stage-local hazard exposure"
	)


func _check_stage_five_no_offer_completion(run) -> void:
	run.current_stage_index = Catalog.STAGE_IDS.size() - 1
	run.current_stage_id = Catalog.STAGE_IDS[run.current_stage_index]
	run.mode = run.RunMode.PLAYING
	run.stage_complete = false
	run.pending_stage_completion = true
	run.experience_recall_timer = 0.0
	run.experience_runtime.clear_shards()
	run.experience_runtime.pending_level_ups = 0
	run.reward_runtime.reset_stage()
	run.stage_flow.state = StageFlow.State.REWARDS
	for definition in run.upgrade_catalog.all_definitions():
		run.run_build.levels[definition.id] = definition.max_level
	run.call("_open_upgrade_reward", &"boss")
	_expect(
		run.mode == run.RunMode.PLAYING
			and run.reward_runtime.has_claimed(run.current_stage_id, &"boss")
			and run.reward_runtime.is_idle(),
		"an exhausted Stage 5 offer resolves without trapping the run in upgrade mode"
	)
	run.call("_advance_reward_queue")
	_expect(
		run.mode == run.RunMode.RESULT
			and run.stage_complete
			and run.stage_flow.state == StageFlow.State.COMPLETE,
		"Stage 5 reaches the final result after an exhausted reward catalog"
	)


func _timeline_count(timeline: Array, kind: StringName, at_time: float) -> int:
	var count := 0
	for entry_value in timeline:
		var entry := Dictionary(entry_value)
		if (
			StringName(entry.get("kind", &"")) == kind
			and is_equal_approx(float(entry.get("time", -1.0)), at_time)
		):
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_STAGE_TRANSITION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
