extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
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
	root.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_RUN_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
