extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
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
		_expect(run.current_stage_id == &"stage_1" and run.player_position == Vector2(2800,1700), "run begins at shared center")
		_expect(run.MINIMAP_COLS == 16 and run.MINIMAP_ROWS == 10, "run uses 16x10 explored minimap")
		_expect(run._camera.zoom == Vector2.ONE, "gameplay camera keeps zoom 1")
		var initial_fingerprint := Catalog.geometry_fingerprint(run.current_stage_id)
		run.run_build.apply(&"tuned_thrusters")
		run.visited_cells[Vector2i(2,2)] = true
		run.current_stage_index = 1
		run.current_stage_id = Catalog.STAGE_IDS[1]
		run.call("_reset_run", false, true, true)
		_expect(Catalog.geometry_fingerprint(run.current_stage_id) == initial_fingerprint, "stage transition preserves field geometry")
		_expect(run.run_build.has(&"tuned_thrusters") and run.visited_cells.has(Vector2i(2,2)), "stage transition preserves build and exploration")
		_expect(run.player_position == Vector2(2800,1700), "stage transition respawns at center")
		var hud: Dictionary = run.call("_build_hud_snapshot")
		_expect(hud["minimap"]["cols"] == 16 and hud["guidebook"].has("categories"), "HUD exposes minimap and guide snapshots")
		var ui = run.get_node_or_null("VehicleStageUI")
		_expect(ui != null and ui._guide_panel.debug_contract()["categories"] == 5, "guidebook modal is connected")
		_check_boss_hit_recovery(run)
	root.queue_free()
	await process_frame
	_finish()


func _check_boss_hit_recovery(run) -> void:
	var boss: Dictionary = run.call("_make_enemy", {
		"id":"validation_boss", "role":&"stage_boss",
		"pos":run.player_position + Vector2(760.0, 0.0), "active":true,
	})
	boss["active"] = true
	boss["phase"] = "boss_startup"
	boss["phase_time"] = 1.0
	run.enemies.append(boss)
	run.call("_damage_enemy", boss, 1.0, "validation", BossPatterns.STAGGER_THRESHOLD + 1.0)
	_expect(String(boss["phase"]) == "boss_startup" and is_zero_approx(float(boss["stagger"])), "routine hits cannot interrupt a boss attack")

	boss["phase"] = "boss_recovery"
	boss["vulnerable"] = 1.0
	run.call("_damage_enemy", boss, 1.0, "validation", BossPatterns.STAGGER_THRESHOLD)
	_expect(String(boss["phase"]) == "staggered", "recovery-window pressure can stagger the boss")
	run.call("_update_stage_boss", boss, BossPatterns.STAGGER_WINDOW + 0.01)
	_expect(String(boss["phase"]) == "boss_read", "boss exits stagger on its bounded timer")

	run.projectiles.clear()
	boss["pos"] = run.player_position + Vector2(-420.0, 0.0)
	boss["phase"] = "boss_startup"
	boss["phase_time"] = 0.8
	boss["pattern"] = "current_fan"
	boss["pattern_index"] = 1
	boss["committed_dir"] = Vector2.UP
	run.player_velocity = Vector2(0.0, 180.0)
	var before_track_position := Vector2(boss["pos"])
	run.call("_update_stage_boss", boss, 0.1)
	_expect(Vector2(boss["pos"]).distance_to(before_track_position) > 0.1, "boss moves while tracking during attack startup")
	_expect(Vector2(boss["committed_dir"]).dot((run.player_position - Vector2(boss["pos"])).normalized()) > 0.0, "boss startup aim turns toward the moving player")
	run.call("_boss_begin_active", boss)
	run.call("_boss_update_active", boss, 0.01)
	run.call("_boss_update_active", boss, BossPatterns.volley_interval("current_fan") + 0.01)
	_expect(run.call("_count_hostile_projectiles") >= 10, "boss fires repeated predictive volleys instead of one inert shot")

	run.projectiles.clear()
	var ordinary_limit := Director.HOSTILE_PROJECTILE_CAP - Director.BOSS_PROJECTILE_RESERVE
	for index in ordinary_limit + 8:
		run.call("_spawn_hostile_projectile", boss["pos"], Vector2.LEFT, 1.0, 100.0, "validation_ordinary", Color.WHITE)
	_expect(run.call("_count_hostile_projectiles") == ordinary_limit, "ordinary hostile shots preserve the boss projectile reserve")
	var before_boss_shot := int(run.call("_count_hostile_projectiles"))
	run.call("_spawn_hostile_projectile", boss["pos"], Vector2.LEFT, 1.0, 100.0, "validation_boss", Color.WHITE, true)
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
