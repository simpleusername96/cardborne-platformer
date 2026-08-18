extends SceneTree

const StageScene = preload("res://scenes/run/VehicleRun.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage = StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	stage.player_position = Vector2(3600.0, 2160.0)
	var probe_position := Vector2.ZERO
	for direction_index in 16:
		var candidate: Vector2 = (
			Vector2(stage.player_position)
			+ Vector2.RIGHT.rotated(TAU * float(direction_index) / 16.0) * 1500.0
		)
		var inward_step: Vector2 = (
			Vector2(stage.player_position) - candidate
		).normalized() * 64.0
		var visible_world: Rect2 = stage.call("_visible_world_rect", 64.0)
		if (
			not visible_world.has_point(candidate)
			and Vector2(stage.call("_move_actor", candidate, inward_step, 32.0, false))
				!= candidate
		):
			probe_position = candidate
			break
	_expect(not probe_position.is_zero_approx(), "fixture finds one collision-clear off-screen regroup lane")
	var enemy = stage.call("_make_enemy", {
		"id":"gap_probe",
		"role":&"ordinary_edge_01",
		"pos":probe_position,
		"active":true,
	})
	enemy.active = true
	enemy.phase = &"move"
	stage.set("_diagnostic_visible_gap_active", true)
	stage.set("_diagnostic_visible_gap_started", 0.0)
	stage.set("active_run_elapsed_seconds", 2.0)
	var before: float = Vector2(enemy.pos).distance_to(Vector2(stage.player_position))
	stage.call("_apply_engagement_gap_steering", enemy, 0.25, false)
	var after: float = Vector2(enemy.pos).distance_to(Vector2(stage.player_position))
	_expect(after < before, "an off-screen mobile hostile regroups by movement after the gap delay")
	_expect(enemy.movement_reason == &"engagement_gap_regroup", "regroup movement publishes its reason")
	var committed_position: Vector2 = enemy.pos
	enemy.phase = &"startup"
	stage.call("_apply_engagement_gap_steering", enemy, 0.25, false)
	_expect(enemy.pos == committed_position, "committed attacks are never retargeted by gap steering")
	stage.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENGAGEMENT_GAP_STEERING_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
