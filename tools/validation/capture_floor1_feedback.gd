extends SceneTree

const OUTPUT_DIR := "res://.godot/floor1-feedback-captures"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture_room(
		&"foundry_approach",
		&"foundry_south",
		"floor1-feedback-foundry.png",
		Vector3(0.0, 0.0, -2.0),
	)
	await _capture_room(
		&"foundry_approach",
		&"foundry_south",
		"floor1-feedback-foundry-960x540.png",
		Vector3(0.0, 0.0, -2.0),
		Vector2i(960, 540),
	)
	await _capture_room(
		&"pressure_vault",
		&"pressure_south",
		"floor1-feedback-pressure-entry.png",
		Vector3.INF,
	)
	quit(0)


func _capture_room(
	room_id: StringName,
	entry_socket_id: StringName,
	file_name: String,
	traveler_override: Vector3,
	viewport_size: Vector2i = Vector2i(1280, 720),
) -> void:
	root.size = viewport_size
	var pivot := (load("res://scenes/main/PivotRoot.tscn") as PackedScene).instantiate()
	root.add_child(pivot)
	await _physics_frames(4)
	var runtime := pivot.get_node("FloorRuntime3D") as FloorRuntime3D
	await runtime._on_transition_requested(room_id, entry_socket_id)
	if traveler_override != Vector3.INF:
		runtime.traveler.global_position = traveler_override
		runtime.camera_rig.snap_to_target()
	await _physics_frames(30)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Rendered floor feedback capture requires a display driver")
		quit(1)
		return
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name)))
	if result != OK:
		push_error("Could not save %s: %s" % [file_name, error_string(result)])
		quit(1)
		return
	pivot.queue_free()
	await process_frame


func _physics_frames(count: int) -> void:
	for _index in count:
		await physics_frame
