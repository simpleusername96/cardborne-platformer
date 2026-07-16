extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux/fixed_stage"
const MAIN_SCENE := "res://scenes/main/Main.tscn"
const CAPTURE_RUN_SEED := 73021
const SETTLE_FRAMES := 20
const DEBUG_OVERLAY_SCRIPT = preload("res://tools/WorldProofDebugOverlay.gd")

var _captures: Array[Dictionary] = [
	{"name": "ruin_start", "size": Vector2i(1280, 720), "stage_index": 0, "target": &"start"},
	{"name": "ruin_shooter_split", "size": Vector2i(1280, 720), "stage_index": 0, "target": &"lr_shooter_overlook", "anchor": &"GroundRecovery"},
	{"name": "ruin_route_choice", "size": Vector2i(1280, 720), "stage_index": 0, "target": &"choice"},
	{"name": "ruin_optional_forward_rejoin", "size": Vector2i(1280, 720), "stage_index": 0, "target": &"lr_destructible_cache", "anchor": &"ReturnRope"},
	{"name": "ruin_broken_descent", "size": Vector2i(1280, 720), "stage_index": 0, "target": &"lr_broken_bridge", "anchor": &"DescentPreview"},
	{"name": "ruin_charge_reengage", "size": Vector2i(1280, 720), "stage_index": 0, "target": &"lr_charge_lane", "anchor": &"ChargeRead"},
	{"name": "ruin_exit_release", "size": Vector2i(1280, 720), "stage_index": 0, "target": &"lr_exit_ascent", "anchor": &"EntryRecovery"},
	{"name": "flooded_route_choice", "size": Vector2i(1280, 720), "stage_index": 1, "target": &"choice"},
	{"name": "flooded_optional_cache", "size": Vector2i(1280, 720), "stage_index": 1, "target": &"fw_sunken_cache"},
	{"name": "flooded_poison_visual_baseline", "size": Vector2i(1280, 720), "stage_index": 1, "target": &"fw_poison_timing", "anchor": &"PoisonSafeRecovery", "baseline": true, "hazard_state": &"active"},
	{"name": "flooded_poison_visual_proof", "size": Vector2i(1280, 720), "stage_index": 1, "target": &"fw_poison_timing", "anchor": &"PoisonSafeRecovery", "hazard_state": &"active"},
	{"name": "flooded_poison_visual_debug", "size": Vector2i(1280, 720), "stage_index": 1, "target": &"fw_poison_timing", "anchor": &"PoisonSafeRecovery", "hazard_state": &"active", "debug": true},
	{"name": "sanctum_route_choice", "size": Vector2i(1280, 720), "stage_index": 2, "target": &"bs_twin_reliquary_choice", "anchor": &"UpperReturnRecovery"},
	{"name": "sanctum_crypt_recovery", "size": Vector2i(1280, 720), "stage_index": 2, "target": &"bs_material_crypt", "anchor": &"CryptBasinRecovery"},
	{"name": "sanctum_crypt_recovery_compact", "size": Vector2i(960, 540), "stage_index": 2, "target": &"bs_material_crypt", "anchor": &"CryptBasinRecovery"},
	{"name": "sanctum_reliquary_return", "size": Vector2i(1280, 720), "stage_index": 2, "target": &"bs_reliquary_cache", "anchor": &"CacheReturnRecovery"},
]
var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var capture_filter := OS.get_environment("CAPTURE_NAME")
	for capture in _captures:
		if not capture_filter.is_empty() and capture_filter != String(capture["name"]):
			continue
		await _capture(capture)
	quit(1 if _failed else 0)


func _capture(capture: Dictionary) -> void:
	print("FIXED_STAGE_CAPTURE_BEGIN %s" % capture["name"])
	root.size = capture["size"]
	DisplayServer.window_set_size(capture["size"])
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(main)
	for _frame in 3:
		await process_frame
	var game := root.get_node_or_null("/root/Game")
	var director := root.get_node_or_null("/root/RunDirector")
	var run_state := root.get_node_or_null("/root/RunState")
	if game == null or director == null or run_state == null:
		push_error("Fixed stage capture needs production autoloads.")
		_failed = true
		return
	director.show_main_menu()
	await process_frame
	director.start_production_run(0)
	run_state.run_seed = CAPTURE_RUN_SEED
	run_state.current_stage_index = int(capture.get("stage_index", 0))
	game.reload_current_stage()
	for _frame in 4:
		await process_frame
	var stage: Variant = game.current_stage
	if stage == null or not stage.is_setup_complete():
		push_error("Fixed stage capture failed for stage %d." % int(capture.get("stage_index", 0)))
		_failed = true
		return
	var planned_room := _target_room(stage.get_stage_plan(), capture["target"])
	var host: RoomTemplateHost = stage.get_room_host(planned_room.id) if planned_room != null else null
	if host == null:
		push_error("Capture target '%s' is unavailable." % capture["target"])
		_failed = true
		return
	var focus := _focus_position(host, planned_room.role, StringName(capture.get("anchor", &"")))
	stage.player.respawn_at(focus, 0.0)
	if bool(capture.get("baseline", false)):
		_apply_visual_baseline(stage, host)
	_set_hazard_state(stage, host, StringName(capture.get("hazard_state", &"")))
	if bool(capture.get("debug", false)):
		var overlay := DEBUG_OVERLAY_SCRIPT.new()
		stage.add_child(overlay)
		overlay.configure(stage, host)
	if stage.player.camera != null:
		stage.player.camera.reset_smoothing()
	for _frame in SETTLE_FRAMES:
		await process_frame
	for _pass in 3:
		RenderingServer.force_draw(false)
		await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	if image == null or image.save_png(path) != OK:
		push_error("Unable to save fixed stage capture '%s'." % capture["name"])
		_failed = true
	else:
		print("FIXED_STAGE_CAPTURE_SAVED %s" % path)
	director.show_main_menu()
	main.queue_free()
	await process_frame


func _apply_visual_baseline(stage: Node, host: RoomTemplateHost) -> void:
	var backdrop := stage.get_node_or_null("Backdrop") as CanvasItem
	if backdrop != null:
		for child in backdrop.get_children():
			if child is CanvasItem:
				(child as CanvasItem).visible = false
		backdrop.set("_fallback_active", true)
		backdrop.queue_redraw()
	for node in host.find_children("ProductionTerrainVisual", "Sprite2D", true, false):
		(node as Sprite2D).visible = false
	for node in host.find_children("*", "Polygon2D", true, false):
		var path := String(host.get_path_to(node))
		if path.begins_with("Terrain/") or path.begins_with("OneWay/"):
			(node as Polygon2D).visible = true
	for node in host.find_children("*", "Line2D", true, false):
		var path := String(host.get_path_to(node))
		if path.begins_with("Terrain/") or path.begins_with("OneWay/"):
			(node as Line2D).visible = true
	for hazard in stage.get_spawned_hazards():
		if Rect2(host.global_position, Vector2(1280.0, 720.0)).grow(160.0).has_point(hazard.global_position):
			var visual_root := hazard.get_node_or_null("VisualRoot") as CanvasItem
			var fallback := hazard.get_node_or_null("Visual") as CanvasItem
			if visual_root != null:
				visual_root.visible = false
			if fallback != null:
				fallback.visible = true


func _set_hazard_state(stage: Node, host: RoomTemplateHost, state: StringName) -> void:
	if state == &"":
		return
	var room_bounds := Rect2(host.global_position, Vector2(1280.0, 720.0)).grow(160.0)
	for hazard in stage.get_spawned_hazards():
		if not room_bounds.has_point(hazard.global_position):
			continue
		if state == &"active" and hazard is TimedPoisonVent:
			hazard.reset_hazard()
			hazard.advance_time(hazard.warning_time + 0.01)
		elif state == &"warning" and hazard is CrumblingPlatform:
			hazard.reset_platform()
			hazard.trigger_collapse()


func _target_room(plan: StagePlan, target: StringName) -> PlannedRoom:
	for room in plan.get_rooms():
		if room.id == target or room.template_id == target:
			return room
		if target == &"optional" and not room.required_route:
			return room
		if room.role == target:
			return room
	return null


func _focus_position(host: RoomTemplateHost, role: StringName, anchor_name: StringName) -> Vector2:
	if anchor_name != &"":
		for group_name in ["Recovery", "Objective"]:
			var requested := host.get_node_or_null(
				"Anchors/%s/%s" % [group_name, anchor_name]
			) as Node2D
			if requested != null:
				return requested.global_position
	if role == &"start":
		var spawn := host.get_anchor(&"Objective", &"PlayerSpawn")
		if spawn != null:
			return spawn.global_position
	var recoveries := host.get_typed_anchors(&"Recovery")
	if not recoveries.is_empty():
		return recoveries[0].global_position
	return host.global_position + Vector2(560.0, 560.0)
