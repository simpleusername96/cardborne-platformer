extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const MAIN_SCENE := "res://scenes/main/Main.tscn"
const MIN_LANDING_WIDTH := 220.0
const FALLBACK_MAX_STEP_DELTA := 80.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main := load(MAIN_SCENE) as PackedScene
	_expect(packed_main != null, "main scene should load for production stage validation")
	if packed_main == null:
		_finish()
		return

	var main_instance := packed_main.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	var run_director := root.get_node_or_null("RunDirector")
	var game := root.get_node_or_null("Game")
	var run_state := root.get_node_or_null("RunState")
	_expect(run_director != null and game != null and run_state != null, "production autoloads should exist")
	if run_director == null or game == null or run_state == null:
		_finish()
		return
	_expect(run_director.start_production_run(0), "production run should start")
	await process_frame
	await process_frame
	var stage = game.current_stage
	_expect(stage != null, "production stage should instantiate through Game")
	if stage == null:
		_finish()
		return

	_expect(stage.has_method("complete_stage"), "production stage should expose StageBase completion")
	_expect(stage.stage_id == "lower_ruins_entry", "production stage id should be stable")
	_expect(game.current_stage_path == STAGE_PATH, "production run should use the production stage path")
	_expect(stage.get_node_or_null("PlayerSpawn") != null, "production stage needs PlayerSpawn")
	_expect(stage.get_node_or_null("Actors") != null, "production stage needs Actors container")
	var exit := stage.get_node_or_null("ExitGate") as Area2D
	_expect(exit != null and bool(exit.get_meta("critical_exit", false)), "production stage needs a critical exit gate")

	var surfaces: Array = stage.get_critical_surface_contract()
	var route_limits: Dictionary = run_state.call(&"get_required_route_limits")
	var max_step_delta := float(route_limits.get("max_required_ledge", FALLBACK_MAX_STEP_DELTA))
	_expect(surfaces.size() >= 3, "critical route should contain authored support masses")
	for surface_index in surfaces.size():
		var surface: Dictionary = surfaces[surface_index]
		var width := float(surface.get("width", 0.0))
		var top := float(surface.get("top", 0.0))
		_expect(width >= MIN_LANDING_WIDTH, "critical landing %s is too narrow" % surface.get("id", surface_index))
		_expect(top < 720.0, "critical terrain must extend into the visible play area")
		var body_name := "CriticalSurface_%02d_%s" % [surface_index, surface["id"]]
		var body := stage.get_node_or_null("Terrain/%s" % body_name) as StaticBody2D
		_expect(body != null, "critical terrain body %s should exist" % body_name)
		if body != null:
			var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var visual := body.get_node_or_null("RockVisual") as Polygon2D
			_expect(collision != null and collision.shape is RectangleShape2D, "%s needs rectangle collision" % body_name)
			_expect(visual != null, "%s needs filled rock visual" % body_name)
			if collision != null and collision.shape is RectangleShape2D:
				var rectangle := collision.shape as RectangleShape2D
				_expect(is_equal_approx(rectangle.size.x, width), "%s collision width must match support" % body_name)
				_expect(rectangle.size.y > 720.0 - top, "%s must be filled below the viewport" % body_name)

		if surface_index == 0:
			continue
		var previous: Dictionary = surfaces[surface_index - 1]
		var previous_end := float(previous["x"]) + float(previous["width"])
		_expect(is_equal_approx(previous_end, float(surface["x"])), "critical surfaces must have no horizontal gap")
		_expect(absf(float(previous["top"]) - top) <= max_step_delta, "critical step exceeds shared movement contract")

	if exit != null and not surfaces.is_empty():
		var exit_surface: Dictionary = surfaces[-1]
		var exit_x: float = exit.global_position.x
		_expect(
			exit_x >= float(exit_surface["x"]) and exit_x <= float(exit_surface["x"]) + float(exit_surface["width"]),
			"exit gate must stand on the final critical surface"
		)

	if exit != null and stage.player != null:
		exit.call(&"interact", stage.player)
		await process_frame
		await process_frame
		_expect(run_director.get_phase_name() == "run_result", "exit interaction should complete the production run")
		_expect(game.current_stage == null, "completed production run should unload its stage")
	else:
		_expect(false, "production route needs an exit and spawned player for completion validation")

	run_director.show_main_menu()
	main_instance.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PRODUCTION_STAGE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
