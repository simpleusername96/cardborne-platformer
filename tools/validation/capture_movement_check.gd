extends SceneTree

const READY_CAPTURES := {
	"movement-check-960x540.png": Vector2i(960, 540),
	"movement-check-1280x720.png": Vector2i(1280, 720),
	"movement-check-1920x1080.png": Vector2i(1920, 1080),
}
const STATE_CAPTURES := {
	"movement-check-facing-1280x720.png": &"moving_facing",
	"movement-check-melee-assist-1280x720.png": &"melee_assist",
	"movement-check-ranged-assist-1280x720.png": &"ranged_assist",
	"movement-check-guard-1280x720.png": &"guard",
	"movement-check-southeast-edge-1280x720.png": &"southeast_edge",
	"movement-check-northwest-edge-1280x720.png": &"northwest_edge",
	"movement-check-pause-1280x720.png": &"pause",
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := ProjectSettings.globalize_path("res://build/validation")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for file_name in READY_CAPTURES:
		await _capture(file_name, READY_CAPTURES[file_name], output_dir)
	for file_name in STATE_CAPTURES:
		await _capture(file_name, Vector2i(1280, 720), output_dir, STATE_CAPTURES[file_name])
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
	await _physics_frames(3)
	var sandbox: CombatSandbox3D = pivot.get_node("CombatSandbox3D")
	sandbox.training_pulse.state = TrainingPulse3D.PulseState.STARTUP
	sandbox.training_pulse.elapsed = 0.35
	sandbox.traveler.action_traced.emit("Ready")
	await _prepare_state(state, sandbox)
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("Rendered capture requires a non-headless display driver")
		quit(1)
		return
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("Could not save %s: %s" % [file_name, error_string(error)])

	_release_action_keys()
	paused = false
	pivot.queue_free()
	await process_frame


func _prepare_state(state: StringName, sandbox: CombatSandbox3D) -> void:
	var traveler := sandbox.traveler
	var targets: Array[DamageableDummy3D] = [
		sandbox.get_node("NearTarget"),
		sandbox.get_node("RangedTarget"),
		sandbox.get_node("OccludedTarget"),
	]
	match state:
		&"ready":
			await _process_frames(8)
		&"moving_facing":
			_park_targets(targets)
			_send_key(KEY_RIGHT, true)
			_send_key(KEY_UP, true)
			await _physics_frames(18)
			_send_key(KEY_RIGHT, false)
			_send_key(KEY_UP, false)
			await _physics_frames(2)
			traveler.action_traced.emit("Facing follows movement")
		&"melee_assist":
			_park_targets(targets)
			traveler.global_position = Vector3.ZERO
			traveler.combat_facing = Vector3.FORWARD
			var direction := Vector3(sin(deg_to_rad(55.0)), 0, -cos(deg_to_rad(55.0))).normalized()
			targets[0].global_position = direction * 1.45
			await _physics_frames(2)
			_send_key(KEY_SHIFT, true)
			await _physics_frames(2)
			_send_key(KEY_SHIFT, false)
			await _physics_frames(6)
		&"ranged_assist":
			_park_targets(targets)
			traveler.global_position = Vector3.ZERO
			traveler.combat_facing = Vector3.FORWARD
			var direction := Vector3(sin(deg_to_rad(20.0)), 0, -cos(deg_to_rad(20.0))).normalized()
			targets[1].global_position = direction * 6.0
			await _physics_frames(2)
			_send_key(KEY_Z, true)
			await _physics_frames(2)
			_send_key(KEY_Z, false)
			await _physics_frames(3)
		&"guard":
			_send_key(KEY_X, true)
			await _physics_frames(2)
		&"southeast_edge":
			traveler.global_position = Vector3(9.2, 0, 9.2)
			traveler.action_traced.emit("South / east cutaway")
			await _process_seconds(1.0)
		&"northwest_edge":
			traveler.global_position = Vector3(-9.2, 0, -9.2)
			traveler.action_traced.emit("North / west camera clamp")
			await _process_seconds(1.0)
		&"pause":
			_send_key(KEY_ESCAPE, true)
			await process_frame
			_send_key(KEY_ESCAPE, false)
			await process_frame


func _park_targets(targets: Array[DamageableDummy3D]) -> void:
	for index in targets.size():
		targets[index].global_position = Vector3(40.0 + index * 3.0, 0, 40.0)
		targets[index].reset_dummy()


func _release_action_keys() -> void:
	for keycode: Key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE, KEY_SHIFT, KEY_Z, KEY_X, KEY_C, KEY_ESCAPE]:
		_send_key(keycode, false)


func _physics_frames(count: int) -> void:
	for _index in count:
		await physics_frame


func _process_frames(count: int) -> void:
	for _index in count:
		await process_frame


func _process_seconds(duration: float) -> void:
	await create_timer(duration).timeout


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
