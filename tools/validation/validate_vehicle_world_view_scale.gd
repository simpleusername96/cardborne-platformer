extends SceneTree

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Run = preload("res://scripts/vehicle/vehicle_run.gd")
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
	var run: Run = scene.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active")
	if run == null:
		_finish()
		return
	_expect(
		Rules.GAMEPLAY_CAMERA_ZOOM == Vector2(0.5, 0.5)
			and run._camera.zoom == Rules.GAMEPLAY_CAMERA_ZOOM,
		"gameplay authority presents world actors at half screen scale"
	)
	_expect(
		Rules.PLAYER_RADIUS == 24.0
			and run.FAR_SIMULATION_DISTANCE == 820.0
			and run.THREAT_SCAN_DISTANCE == 1200.0,
		"camera scale does not rewrite collision or minimum scheduling constants"
	)
	for viewport_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		get_root().content_scale_size = viewport_size
		get_root().size = viewport_size
		run._camera.position_smoothing_enabled = false
		run._camera.position = run.player_position
		run._camera.force_update_scroll()
		await process_frame
		var visible: Rect2 = run.call("_visible_world_rect", 0.0)
		var expected_world_size := Vector2(viewport_size) / Rules.GAMEPLAY_CAMERA_ZOOM
		_expect(
			visible.size.is_equal_approx(expected_world_size),
			"%s viewport maps to the exact doubled world extent; got %s"
			% [viewport_size, visible.size]
		)
		run.call("_refresh_visible_world_runtime_ranges")
		var farthest := _farthest_corner_distance(visible, run.player_position)
		_expect(
			sqrt(run._near_simulation_distance_squared) + 0.5
				>= farthest + run.VISIBLE_SIMULATION_MARGIN,
			"%s keeps every visible actor on near simulation cadence" % viewport_size
		)
		_expect(
			run._runtime_threat_scan_distance
				>= farthest + run.THREAT_OFFSCREEN_BAND - 0.01,
			"%s preserves the offscreen radar warning band" % viewport_size
		)
	run.queue_free()
	await process_frame
	_finish()


func _farthest_corner_distance(rect: Rect2, origin: Vector2) -> float:
	var maximum := 0.0
	for corner in [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]:
		maximum = maxf(maximum, origin.distance_to(corner))
	return maximum


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_WORLD_VIEW_SCALE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
