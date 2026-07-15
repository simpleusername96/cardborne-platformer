extends Node

var stage_root: Node
var ui_root: CanvasLayer
var current_stage: Node
var current_stage_path: String = ""
var pause_menu_open: bool = false
var settings_open: bool = false
var reward_choice_open: bool = false


func _ready() -> void:
	ensure_input_map()


func register_roots(p_stage_root: Node, p_ui_root: CanvasLayer) -> void:
	stage_root = p_stage_root
	ui_root = p_ui_root


func load_stage(scene_path: String) -> Node:
	if stage_root == null:
		push_error("Game.load_stage called before stage_root is registered.")
		return null

	unload_current_stage()

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Unable to load stage scene: %s" % scene_path)
		return null

	current_stage = packed_scene.instantiate()
	current_stage_path = scene_path
	stage_root.add_child(current_stage)
	return current_stage


func unload_current_stage() -> void:
	if current_stage != null and is_instance_valid(current_stage):
		if current_stage.get_parent() != null:
			current_stage.get_parent().remove_child(current_stage)
		current_stage.queue_free()
	current_stage = null
	current_stage_path = ""


func reload_current_stage() -> bool:
	if current_stage_path.is_empty():
		return false
	var stage_path := current_stage_path
	return load_stage(stage_path) != null


func set_settings_open(is_open: bool) -> void:
	if settings_open == is_open:
		return
	settings_open = is_open
	_sync_pause_state()
	SignalBus.settings_visibility_changed.emit(settings_open)


func toggle_settings_popup() -> void:
	set_settings_open(not settings_open)


func set_pause_menu_open(is_open: bool) -> void:
	if pause_menu_open == is_open and not (not is_open and settings_open):
		return
	pause_menu_open = is_open
	if not is_open and settings_open:
		settings_open = false
		SignalBus.settings_visibility_changed.emit(false)
	_sync_pause_state()
	SignalBus.pause_visibility_changed.emit(pause_menu_open)


func set_reward_choice_open(is_open: bool) -> void:
	if reward_choice_open == is_open:
		return
	reward_choice_open = is_open
	_sync_pause_state()


func close_overlays() -> void:
	var settings_was_open := settings_open
	var pause_was_open := pause_menu_open
	settings_open = false
	pause_menu_open = false
	reward_choice_open = false
	_sync_pause_state()
	if settings_was_open:
		SignalBus.settings_visibility_changed.emit(false)
	if pause_was_open:
		SignalBus.pause_visibility_changed.emit(false)


func _sync_pause_state() -> void:
	# Always-processing overlays keep gameplay frozen until their transaction closes.
	get_tree().paused = pause_menu_open or settings_open or reward_choice_open


func ensure_input_map() -> void:
	InputBindings.ensure_input_map()


func get_input_guide_text() -> String:
	return InputBindings.get_input_guide_text()


func get_input_binding_lines() -> Array[String]:
	return InputBindings.get_input_binding_lines()


func get_input_binding_rows() -> Array[Dictionary]:
	return InputBindings.get_input_binding_rows()


func get_action_binding_text(action_name: String, fallback: String = "unbound") -> String:
	return InputBindings.get_binding_text(action_name, fallback)


func get_input_action_label(action_name: String) -> String:
	return InputBindings.get_action_label(action_name)


func remap_action_to_event(action_name: String, event: InputEventKey) -> Dictionary:
	return InputBindings.remap_action_to_event(action_name, event)


func restore_action_default(action_name: String) -> Dictionary:
	return InputBindings.restore_action_default(action_name)


func restore_all_input_defaults() -> void:
	InputBindings.restore_all_defaults()
