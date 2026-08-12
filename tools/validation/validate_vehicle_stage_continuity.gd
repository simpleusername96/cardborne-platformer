extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
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
	var scene := packed.instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var run = scene.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active")
	if run != null:
		run.set_physics_process(false)
		run.set_process(false)
		_check_stage_one_continuation(run)
		run.call("_reset_run", false)
		_check_stage_five_immediate_result(run)
	scene.queue_free()
	await process_frame
	_finish()


func _check_stage_one_continuation(run) -> void:
	run.call("_reset_run", false)
	run.mode = run.RunMode.PLAYING
	run.selected_run_difficulty = &"hard"
	var preserved_position := Vector2(2874.0, 1932.0)
	var preserved_velocity := Vector2(84.0, -36.0)
	var preserved_hull_direction := Vector2(0.6, 0.8).normalized()
	var preserved_aim_direction := Vector2(-0.8, 0.6).normalized()
	var explored_cell := Vector2i(4, 7)
	run.player_position = preserved_position
	run.player_velocity = preserved_velocity
	run.player_hull_direction = preserved_hull_direction
	run.player_aim_direction = preserved_aim_direction
	run.player_health = 17.0
	run.player_invulnerable = 0.23
	run.player_dash_cooldown = 0.7
	run.player_dash_timer = 0.11
	run.active_weapon_runtime.cooldown_remaining = 6.4
	run.secondary_runtime.seeker_cooldown = 0.8
	run.run_build.apply(&"chassis_speed")
	run.visited_cells[explored_cell] = true
	var field_fingerprint := int(run.field_layout.fingerprint)
	var terrain_before := hash(var_to_str(run.terrain_runtime.snapshot()))
	var old_facility_carrier := String(
		run.reinforcement_facility_runtime.snapshot()["carrier_id"]
	)

	var ordinary := _append_enemy(run, {
		"id":"continuity_ordinary",
		"role":&"chaser",
		"pos":preserved_position + Vector2(220.0, 0.0),
		"active":true,
	})
	var facility_child := _append_enemy(run, {
		"id":"continuity_old_facility_child",
		"role":&"chaser",
		"pos":preserved_position + Vector2(260.0, 0.0),
		"active":true,
		"summoned":true,
		"carrier_id":old_facility_carrier,
		"zone":&"reinforcement_facility",
	})
	var boss_add := _append_enemy(run, {
		"id":"continuity_boss_add",
		"role":&"beam_sentinel",
		"pos":preserved_position + Vector2(300.0, 0.0),
		"active":true,
		"summoned":true,
		"zone":&"boss_system",
	})
	run.projectile_store.add_player(_projectile(preserved_position, "player_primary"))
	run.projectile_store.add_hostile(_projectile(preserved_position, "ordinary_enemy"), false)
	run.projectile_store.add_hostile(_projectile(preserved_position, "boss_pattern"), true)
	run.denied_zones.clear()
	run.denied_zones.append({"id":"ordinary_zone", "owner_kind":&"ordinary"})
	run.denied_zones.append({"id":"boss_zone", "owner_kind":&"stage_boss"})
	run.experience_runtime.spawn_shard(preserved_position, 5, &"")
	var shard_count: int = run.experience_runtime.shards.size()
	run.stage_flow.state = StageFlow.State.COMPLETE
	run.call("_complete_stage")

	_expect(
		run.current_stage_id == &"stage_2"
			and run.mode == run.RunMode.PLAYING
			and run.stage_flow.state == StageFlow.State.ORDINARY,
		"Stage 1 boss completion enters Stage 2 ordinary play in the same call stack"
	)
	_expect(
		run.player_position.is_equal_approx(preserved_position)
			and run.player_velocity.is_equal_approx(preserved_velocity)
			and run.player_hull_direction.is_equal_approx(preserved_hull_direction)
			and run.player_aim_direction.is_equal_approx(preserved_aim_direction),
		"continuation preserves position, motion, hull facing, and manual aim"
	)
	_expect(
		is_equal_approx(run.player_health, run.call("_player_max_health"))
			and is_equal_approx(run.player_invulnerable, 0.23)
			and is_equal_approx(run.player_dash_cooldown, 0.7)
			and is_equal_approx(run.player_dash_timer, 0.11)
			and is_equal_approx(run.active_weapon_runtime.cooldown_remaining, 6.4)
			and is_equal_approx(run.secondary_runtime.seeker_cooldown, 0.8),
		"boss clear changes only HP and preserves every active cooldown/protection timer"
	)
	_expect(
		ordinary.alive and facility_child.alive and not boss_add.alive,
		"ordinary and old-facility actors survive while boss-owned actors retire"
	)
	var projectile_snapshot: Dictionary = run.projectile_store.debug_snapshot()
	_expect(
		int(projectile_snapshot["player"]) == 1
			and int(projectile_snapshot["ordinary_hostile"]) == 1
			and int(projectile_snapshot["boss_hostile"]) == 0
			and run.projectile_store.validate_counts(),
		"continuation preserves player/ordinary projectiles and retires only boss reserve"
	)
	_expect(
		run.denied_zones.size() == 1
			and String(run.denied_zones[0]["id"]) == "ordinary_zone",
		"typed zone retirement removes only stage-boss damage ownership"
	)
	_expect(
		run.experience_runtime.shards.size() == shard_count
			and run.run_build.has(&"chassis_speed")
			and run.visited_cells.has(explored_cell)
			and int(run.field_layout.fingerprint) == field_fingerprint
			and hash(var_to_str(run.terrain_runtime.snapshot())) == terrain_before,
		"XP, build, exploration, field identity, and run-fixed terrain survive"
	)
	_expect(
		not run.reinforcement_facility_runtime.owns_child(old_facility_carrier)
			and run.reinforcement_facility_runtime.snapshot()["carrier_id"] != old_facility_carrier
			and run.debug_reinforcement_facility_count_matches(),
		"new facility ownership excludes the previous stage child"
	)
	_expect(
		run.completed_stage_reports.size() == 1
			and run._ui.debug_hud_visible()
			and not run._ui.debug_surface_visible("report"),
		"stage history is recorded without opening a reward or report modal"
	)
	run.call("_update_encounter", 0.0)
	var cue_snapshot: Dictionary = run.encounter_runtime.debug_snapshot()
	_expect(
		is_equal_approx(float(cue_snapshot["first_cue_time"]), 0.0)
			and not String(cue_snapshot["activated_packets"][0]).contains("scout"),
		"next-stage cue starts immediately and skips the deployment packet"
	)
	run.call("_update_encounter", 0.9)
	var spawn_snapshot: Dictionary = run.encounter_runtime.debug_snapshot()
	_expect(
		is_equal_approx(float(spawn_snapshot["first_spawn_time"]), 0.9),
		"first continuation birth retains the fair 0.9 second warning"
	)
	run.call("_pause_run")
	run.call("_resume_run")
	_expect(run.mode == run.RunMode.PLAYING, "pause resumes directly to continuous play")


func _check_stage_five_immediate_result(run) -> void:
	run.current_stage_index = Catalog.STAGE_IDS.size() - 1
	run.current_stage_id = Catalog.STAGE_IDS[run.current_stage_index]
	run.call("_reset_run", false, true, true)
	run._capture_mode = true
	run.mode = run.RunMode.PLAYING
	run.stage_flow.quota = 1
	run.stage_flow.defeats = 1
	run.stage_flow.state = StageFlow.State.BOSS_ACTIVE
	var boss: EnemyState = run.call("_make_enemy", {
		"id":"stage_5_continuity_boss",
		"role":&"stage_boss",
		"pos":run.player_position,
		"active":true,
	})
	_expect(boss != null and run.call("_append_enemy", boss), "Stage 5 boss fixture registers")
	if boss == null:
		return
	run.call(
		"_damage_enemy", boss, boss.max_health + 1.0, "validation",
		&"kinetic", true, true, false
	)
	_expect(
		run.mode == run.RunMode.RESULT
			and run.stage_complete
			and run.stage_flow.state == StageFlow.State.COMPLETE
			and run._ui.debug_surface_visible("result")
			and not run.reward_runtime.has_pending(),
		"Stage 5 boss defeat opens the clear result immediately without a boss card gate"
	)


func _append_enemy(run, spec: Dictionary) -> EnemyState:
	var enemy: EnemyState = run.call("_make_enemy", spec)
	_expect(enemy != null and run.call("_append_enemy", enemy), "fixture enemy registers: %s" % spec["id"])
	return enemy


func _projectile(position: Vector2, owner: String) -> Dictionary:
	return {
		"pos":position,
		"velocity":Vector2.RIGHT,
		"radius":5.0,
		"owner":owner,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_STAGE_CONTINUITY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
