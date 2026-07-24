extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "main scene loads")
	if packed == null:
		_finish(); return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var run = root.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active")
	if run != null:
		run.call("_reset_run", false)
		_expect(run.current_stage_id == &"stage_1" and run.player_position == Vector2(3600,2160), "run begins at shared center")
		_expect(run.MINIMAP_COLS == 20 and run.MINIMAP_ROWS == 12, "run uses 20x12 explored minimap")
		_expect(run.ORDINARY_DECISION_BUCKET_COUNT == 6, "ordinary high-cost decisions are distributed at 10 Hz")
		_expect(run._camera.zoom == Vector2.ONE, "gameplay camera keeps zoom 1")
		var initial_fingerprint := int(run.field_layout.fingerprint)
		run.run_build.apply(&"tuned_thrusters")
		run.visited_cells[Vector2i(2,2)] = true
		run.current_stage_index = 1
		run.current_stage_id = Catalog.STAGE_IDS[1]
		run.call("_reset_run", false, true, true)
		_expect(int(run.field_layout.fingerprint) == initial_fingerprint, "stage transition preserves run-scoped field geometry")
		_expect(run.run_build.has(&"tuned_thrusters") and run.visited_cells.has(Vector2i(2,2)), "stage transition preserves build and exploration")
		_expect(run.player_position == Vector2(3600,2160), "stage transition respawns at center")
		var hud: Dictionary = run.call("_build_hud_snapshot")
		_expect(hud["minimap"]["cols"] == 20 and hud["guidebook"].has("categories"), "HUD exposes minimap and guide snapshots")
		var ui = run.get_node_or_null("VehicleStageUI")
		_expect(ui != null and ui._guide_panel.debug_contract()["categories"] == 5, "guidebook modal is connected")
		_check_simulation_lod_contract(run)
		_check_boss_progression_gate(run)
		run.call("_reset_run", false, true, true)
		_check_boss_hit_recovery(run)
	root.queue_free()
	await process_frame
	_finish()


func _check_simulation_lod_contract(run) -> void:
	run._simulation_lod_bucket = 0
	var moving_even := EnemyState.new()
	moving_even.phase = &"move"
	moving_even.runtime_slot = 0
	moving_even.pos = run.player_position
	var moving_odd := EnemyState.new()
	moving_odd.phase = &"move"
	moving_odd.runtime_slot = 1
	moving_odd.pos = run.player_position
	var committed_odd := EnemyState.new()
	committed_odd.phase = &"startup"
	committed_odd.runtime_slot = 1
	committed_odd.pos = run.player_position + Vector2(1200.0, 0.0)
	var distant := EnemyState.new()
	distant.phase = &"move"
	distant.runtime_slot = 0
	distant.pos = run.player_position + Vector2(1200.0, 0.0)
	_expect(
		is_equal_approx(float(run.call("_ordinary_enemy_motion_delta", moving_even, 1.0 / 60.0)), 1.0 / 30.0),
		"ordinary locomotion integrates on its alternating 30 Hz slot"
	)
	_expect(
		is_zero_approx(float(run.call("_ordinary_enemy_motion_delta", moving_odd, 1.0 / 60.0))),
		"the other ordinary locomotion slot waits for the next physics tick"
	)
	run._far_enemy_simulation_bucket = 0
	_expect(
		is_equal_approx(float(run.call("_ordinary_enemy_motion_delta", distant, 1.0 / 60.0)), 1.0 / 20.0),
		"distant non-committed locomotion integrates on its 20 Hz slot"
	)
	_expect(
		is_equal_approx(float(run.call("_ordinary_enemy_motion_delta", committed_odd, 1.0 / 60.0)), 1.0 / 60.0),
		"attack startup bypasses locomotion LOD and remains at 60 Hz"
	)


func _check_boss_progression_gate(run) -> void:
	run.call("_start_stage_boss")
	_expect(run.call("_find_enemy_by_id", "stage_boss") == null, "boss cannot spawn before ordinary defeats")
	run.stage_flow.defeats = run.stage_flow.quota - 1
	run.call("_start_stage_boss")
	_expect(run.call("_find_enemy_by_id", "stage_boss") == null, "boss remains blocked one defeat before quota")
	_expect(run.stage_flow.record_countable_defeat(), "final ordinary defeat begins the boss warning")
	run.call("_update_stage_progression", 1.5)
	_expect(run.call("_find_enemy_by_id", "stage_boss") != null, "boss spawns only after quota and warning")


func _check_boss_hit_recovery(run) -> void:
	var boss: EnemyState = run.call("_make_enemy", {
		"id":"validation_boss", "role":&"stage_boss",
		"pos":run.player_position + Vector2(760.0, 0.0), "active":true,
	})
	boss["active"] = true
	boss["phase"] = "boss_startup"
	boss["phase_time"] = 1.0
	run.call("_append_enemy", boss)
	run.call("_damage_enemy", boss, 1.0, "validation", BossPatterns.STAGGER_THRESHOLD + 1.0)
	_expect(String(boss["phase"]) == "boss_startup" and is_zero_approx(float(boss["stagger"])), "routine hits cannot interrupt a boss attack")

	boss["phase"] = "boss_recovery"
	boss["vulnerable"] = 1.0
	run.call("_damage_enemy", boss, 1.0, "validation", BossPatterns.STAGGER_THRESHOLD)
	_expect(String(boss["phase"]) == "staggered", "recovery-window pressure can stagger the boss")
	run.call("_update_stage_boss", boss, BossPatterns.STAGGER_WINDOW + 0.01)
	_expect(String(boss["phase"]) == "boss_read", "boss exits stagger on its bounded timer")

	run.call("_clear_projectiles")
	boss["pos"] = run.player_position + Vector2(-420.0, 0.0)
	boss["phase"] = "boss_startup"
	boss["phase_time"] = 0.8
	boss["pattern"] = "current_fan"
	boss["pattern_index"] = 1
	boss["committed_dir"] = Vector2.UP
	boss["committed_target"] = run.player_position + Vector2(0.0, -240.0)
	AttackTelegraphs.refresh_boss(
		boss,
		"current_fan",
		Callable(run, "_runtime_attack_path_end"),
		Callable(run, "_runtime_charge_path_end")
	)
	run.call("_update_stage_boss", boss, 0.0)
	var warned_position := Vector2(boss["pos"])
	var warned_direction := Vector2(boss["committed_dir"])
	var warned_target := Vector2(boss["committed_target"])
	var warned_endpoint := Vector2(boss.attack_telegraphs[0]["to"])
	var player_before_warning_test := Vector2(run.player_position)
	run.player_position += Vector2(180.0, 120.0)
	run.player_velocity = Vector2(0.0, 180.0)
	run.call("_update_stage_boss", boss, 0.1)
	_expect(
		Vector2(boss["pos"]).is_equal_approx(warned_position)
			and Vector2(boss["committed_dir"]).is_equal_approx(warned_direction)
			and Vector2(boss["committed_target"]).is_equal_approx(warned_target)
			and Vector2(boss.attack_telegraphs[0]["to"]).is_equal_approx(warned_endpoint),
		"boss attack geometry remains fixed after its warning becomes visible"
	)
	_expect(
		float(boss.attack_telegraphs[0]["readiness"]) > 0.0,
		"boss warning readiness advances without moving its footprint"
	)
	run.player_position = player_before_warning_test
	run.call("_boss_begin_active", boss)
	var committed_origin := Vector2(boss["pos"])
	run.call("_boss_update_active", boss, 0.01)
	run.call("_boss_update_active", boss, BossPatterns.volley_interval("current_fan") + 0.01)
	_expect(run.call("_count_hostile_projectiles") >= 10, "boss fires repeated committed volleys instead of one inert shot")
	_expect(
		Vector2(boss["pos"]).is_equal_approx(committed_origin),
		"damaging boss attacks do not drift away from their warned origin"
	)

	run.call("_clear_projectiles")
	var ordinary_limit := Director.HOSTILE_PROJECTILE_CAP - Director.BOSS_PROJECTILE_RESERVE
	for index in ordinary_limit + 8:
		run.call(
			"_spawn_hostile_projectile",
			boss["pos"],
			Vector2.LEFT,
			1.0,
			100.0,
			"validation_ordinary",
			AttackContract.KINETIC
		)
	_expect(run.call("_count_hostile_projectiles") == ordinary_limit, "ordinary hostile shots preserve the boss projectile reserve")
	var before_boss_shot := int(run.call("_count_hostile_projectiles"))
	run.call(
		"_spawn_hostile_projectile",
		boss["pos"],
		Vector2.LEFT,
		1.0,
		100.0,
		"validation_boss",
		AttackContract.KINETIC,
		true
	)
	_expect(run.call("_count_hostile_projectiles") == before_boss_shot + 1, "boss attacks still fire when ordinary projectile pressure is saturated")


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_RUN_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
