extends SceneTree

const CAPTURES := {
	"movement-check-960x540.png": Vector2i(960, 540),
	"movement-check-1280x720.png": Vector2i(1280, 720),
	"movement-check-1920x1080.png": Vector2i(1920, 1080),
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := ProjectSettings.globalize_path("res://build/validation")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for file_name in CAPTURES:
		await _capture(file_name, CAPTURES[file_name], output_dir)
	await _capture("movement-check-guard-1280x720.png", Vector2i(1280, 720), output_dir, &"guard")
	await _capture("movement-check-pause-1280x720.png", Vector2i(1280, 720), output_dir, &"pause")
	quit(0)


func _capture(
	file_name: String,
	viewport_size: Vector2i,
	output_dir: String,
	state: StringName = &"ready",
) -> void:
	root.size = viewport_size
	var packed: PackedScene = load("res://scenes/main/PivotRoot.tscn")
	var pivot := packed.instantiate()
	root.add_child(pivot)
	await process_frame
	await physics_frame
	var sandbox: CombatSandbox3D = pivot.get_node("CombatSandbox3D")
	sandbox.training_pulse.state = TrainingPulse3D.PulseState.STARTUP
	sandbox.training_pulse.elapsed = 0.35
	sandbox.traveler.action_traced.emit("Ready")
	if state == &"guard":
		_send_key(KEY_SHIFT, true)
		await physics_frame
	elif state == &"pause":
		_send_key(KEY_ESCAPE, true)
		await process_frame
		_send_key(KEY_ESCAPE, false)
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Rendered capture requires a non-headless display driver")
		quit(1)
		return
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("Could not save %s: %s" % [file_name, error_string(error)])
	if state == &"guard":
		_send_key(KEY_SHIFT, false)
	elif state == &"pause":
		_send_key(KEY_ESCAPE, true)
		await process_frame
		_send_key(KEY_ESCAPE, false)
		await process_frame
	pivot.queue_free()
	await process_frame


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
