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
	_bind_keys("climb_up", [KEY_W, KEY_UP])
	_bind_keys("climb_down", [KEY_S, KEY_DOWN])
	_bind_keys("jump", [KEY_SPACE])
	_bind_keys("attack", [KEY_J])
	_bind_mouse_buttons("attack", [MOUSE_BUTTON_LEFT])
	_bind_keys("dash", [KEY_K, KEY_SHIFT])
	_bind_keys("crouch", [KEY_S, KEY_DOWN])
	_bind_keys("climb_cancel", [KEY_C])
	_ensure_action("drop_through")
	_bind_keys("interact", [KEY_E, KEY_ENTER])
	_bind_keys("open_build_panel", [KEY_TAB])
	_bind_keys("regenerate_landscape", [KEY_R])
	_bind_keys("replay_landscape", [KEY_T])
	_bind_keys("reset_testbed", [KEY_BACKSPACE])
	_bind_keys("pause", [KEY_ESCAPE])


func get_input_guide_text() -> String:
	return "\n".join([
		"Controls",
		"Move %s | Crouch/drop %s" % [_binding_text("move_left", "A/Left") + "/" + _binding_text("move_right", "D/Right"), _binding_text("crouch", "S/Down")],
		"Jump %s | Dash %s | Attack %s" % [_binding_text("jump", "Space"), _binding_text("dash", "K/Shift"), _binding_text("attack", "J/Mouse1")],
		"Climb %s/%s | Dismount %s" % [_binding_text("climb_up", "W/Up"), _binding_text("climb_down", "S/Down"), _binding_text("climb_cancel", "C")],
		"Interact %s | Profile %s" % [_binding_text("interact", "E/Enter"), _binding_text("open_build_panel", "Tab")],
		"Seed random %s | Replay %s | Settings %s" % [_binding_text("regenerate_landscape", "R"), _binding_text("replay_landscape", "T"), _binding_text("pause", "Esc")],
	])


func get_input_binding_lines() -> Array[String]:
	var actions: Array[Array] = [
		["move_left", "move left"],
		["move_right", "move right"],
		["jump", "jump"],
		["dash", "dash"],
		["attack", "attack"],
		["climb_up", "climb up"],
		["climb_down", "climb down"],
		["climb_cancel", "dismount"],
		["crouch", "crouch/drop"],
		["interact", "interact"],
		["open_build_panel", "profile debug"],
		["regenerate_landscape", "random seed"],
		["replay_landscape", "replay seed"],
		["reset_testbed", "checkpoint reset"],
		["pause", "settings"],
	]
	var lines: Array[String] = []
	for action in actions:
		var action_name := str(action[0])
		lines.append("%s: %s" % [str(action[1]), _binding_text(action_name, "unbound")])
	return lines


func _binding_text(action_name: String, fallback: String) -> String:
	if not InputMap.has_action(action_name):
		return fallback

	var labels: Array[String] = []
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
			labels.append(OS.get_keycode_string(keycode))
		elif event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			labels.append("Mouse%d" % mouse_event.button_index)

	if labels.is_empty():
		return fallback
	return "/".join(labels)


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
	call_deferred("_recover_after_death")


func _recover_after_death() -> void:
	await get_tree().create_timer(0.45).timeout
	if RunState.current_health > 0:
		return

	var active_stage := get_tree().get_first_node_in_group("active_stage")
	if active_stage != null and active_stage.has_method("respawn_player_after_defeat"):
		active_stage.respawn_player_after_defeat()
		return

	reload_current_stage()
