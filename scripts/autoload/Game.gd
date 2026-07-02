extends Node

const MOTION_TEST_STAGE_PATH := "res://scenes/stages/MotionTestStage.tscn"

var stage_root: Node
var ui_root: CanvasLayer
var current_stage: Node
var current_stage_path: String = ""
var settings_open: bool = false


func _ready() -> void:
	ensure_input_map()
	SignalBus.player_died.connect(_on_player_died)


func register_roots(p_stage_root: Node, p_ui_root: CanvasLayer) -> void:
	stage_root = p_stage_root
	ui_root = p_ui_root


func start_motion_test() -> void:
	RunState.start_new_run(RunState.selected_profile_index)
	load_stage(MOTION_TEST_STAGE_PATH)


func load_stage(scene_path: String) -> void:
	if stage_root == null:
		push_error("Game.load_stage called before stage_root is registered.")
		return

	if current_stage != null and is_instance_valid(current_stage):
		current_stage.queue_free()

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Unable to load stage scene: %s" % scene_path)
		return

	current_stage = packed_scene.instantiate()
	current_stage_path = scene_path
	stage_root.add_child(current_stage)


func reload_current_stage() -> void:
	if current_stage_path.is_empty():
		load_stage(MOTION_TEST_STAGE_PATH)
	else:
		RunState.start_new_run(RunState.selected_profile_index)
		load_stage(current_stage_path)


func set_settings_open(is_open: bool) -> void:
	settings_open = is_open
	get_tree().paused = settings_open
	SignalBus.settings_visibility_changed.emit(settings_open)


func toggle_settings_popup() -> void:
	set_settings_open(not settings_open)


func ensure_input_map() -> void:
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("jump", [KEY_SPACE])
	_bind_keys("attack", [KEY_J])
	_bind_mouse_buttons("attack", [MOUSE_BUTTON_LEFT])
	_bind_keys("dash", [KEY_K, KEY_SHIFT])
	_bind_keys("crouch", [KEY_S, KEY_DOWN])
	_ensure_action("drop_through")
	_bind_keys("interact", [KEY_E, KEY_ENTER])
	_bind_keys("open_build_panel", [KEY_TAB])
	_bind_keys("pause", [KEY_ESCAPE])


func _ensure_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)


func _bind_keys(action_name: String, keys: Array[int]) -> void:
	_ensure_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _bind_mouse_buttons(action_name: String, buttons: Array[int]) -> void:
	_ensure_action(action_name)
	for button in buttons:
		var event := InputEventMouseButton.new()
		event.button_index = button
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _on_player_died() -> void:
	SignalBus.status_message_changed.emit("Player defeated")
	call_deferred("_reload_after_death")


func _reload_after_death() -> void:
	await get_tree().create_timer(0.7).timeout
	reload_current_stage()
