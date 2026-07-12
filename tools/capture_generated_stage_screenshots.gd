extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux/generated_stage"
const MAIN_SCENE := "res://scenes/main/Main.tscn"

var _captures: Array[Dictionary] = [
	{"name": "desktop_seed1103_start", "size": Vector2i(1280, 720), "seed": 1103, "target": &"start"},
	{"name": "desktop_seed1103_choice", "size": Vector2i(1280, 720), "seed": 1103, "target": &"choice"},
	{"name": "desktop_seed1103_optional", "size": Vector2i(1280, 720), "seed": 1103, "target": &"optional"},
	{"name": "desktop_seed1103_exit", "size": Vector2i(1280, 720), "seed": 1103, "target": &"exit"},
	{"name": "compact_seed29017_choice", "size": Vector2i(960, 540), "seed": 29017, "target": &"choice"},
	{"name": "compact_seed29017_optional", "size": Vector2i(960, 540), "seed": 29017, "target": &"optional"},
	{"name": "sanctum_desktop_choice", "size": Vector2i(1280, 720), "seed": 41000, "stage_index": 2, "target": &"choice"},
	{"name": "sanctum_desktop_gate_loop", "size": Vector2i(1280, 720), "seed": 41000, "stage_index": 2, "target": &"bs_gate_switch_loop"},
	{"name": "sanctum_desktop_hazard", "size": Vector2i(1280, 720), "seed": 41000, "stage_index": 2, "target": &"hazard"},
	{"name": "sanctum_desktop_combat", "size": Vector2i(1280, 720), "seed": 41000, "stage_index": 2, "target": &"combat"},
	{"name": "sanctum_desktop_exit", "size": Vector2i(1280, 720), "seed": 41000, "stage_index": 2, "target": &"exit"},
	{"name": "sanctum_compact_choice", "size": Vector2i(960, 540), "seed": 41000, "stage_index": 2, "target": &"choice"},
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
		push_error("Generated stage capture needs production autoloads.")
		_failed = true
		return
	director.show_main_menu()
	await process_frame
	director.start_production_run(0)
	run_state.run_seed = int(capture["seed"])
	run_state.current_stage_index = int(capture.get("stage_index", 0))
	game.reload_current_stage()
	for _frame in 4:
		await process_frame
	var stage: Variant = game.current_stage
	if stage == null or not stage.is_setup_complete():
		push_error("Generated stage capture failed for seed %d." % capture["seed"])
		_failed = true
		return
	var planned_room := _target_room(stage.get_stage_plan(), capture["target"])
	var host: RoomTemplateHost = stage.get_room_host(planned_room.id) if planned_room != null else null
	if host == null:
		push_error("Capture target '%s' is unavailable." % capture["target"])
		_failed = true
		return
	var focus := _focus_position(host, planned_room.role)
	stage.player.respawn_at(focus, 0.0)
	if stage.player.camera != null:
		stage.player.camera.reset_smoothing()
	for _frame in 5:
		await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	if image == null or image.save_png(path) != OK:
		push_error("Unable to save generated stage capture '%s'." % capture["name"])
		_failed = true
	director.show_main_menu()
	main.queue_free()
	await process_frame


func _target_room(plan: StagePlan, target: StringName) -> PlannedRoom:
	for room in plan.get_rooms():
		if room.id == target or room.template_id == target:
			return room
		if target == &"optional" and not room.required_route:
			return room
		if room.role == target:
			return room
	return null


func _focus_position(host: RoomTemplateHost, role: StringName) -> Vector2:
	if role == &"start":
		var spawn := host.get_anchor(&"Objective", &"PlayerSpawn")
		if spawn != null:
			return spawn.global_position
	var recoveries := host.get_typed_anchors(&"Recovery")
	if not recoveries.is_empty():
		return recoveries[0].global_position
	return host.global_position + Vector2(560.0, 560.0)
