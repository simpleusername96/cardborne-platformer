extends Node

signal phase_changed(phase_name: String)

enum Phase {
	BOOT,
	MAIN_MENU,
	CHARACTER_SELECT,
	RUN_ACTIVE,
	RUN_RESULT,
}

const MAIN_MENU_PATH := "res://scenes/ui/production/MainMenu.tscn"
const CHARACTER_SELECT_PATH := "res://scenes/ui/production/CharacterSelect.tscn"
const PRODUCTION_HUD_PATH := "res://scenes/ui/production/ProductionHUD.tscn"
const RUN_RESULT_PATH := "res://scenes/ui/production/RunResult.tscn"
const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"

var phase: Phase = Phase.BOOT
var screen_root: Control
var hud_root: Control
var current_screen: Control
var current_hud: Control
var _last_profile_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.stage_cleared.connect(_on_stage_cleared)
	SignalBus.player_died.connect(_on_player_died)


func register_ui_roots(p_screen_root: Control, p_hud_root: Control) -> void:
	screen_root = p_screen_root
	hud_root = p_hud_root


func start() -> void:
	show_main_menu()


func show_main_menu() -> void:
	_prepare_non_gameplay_phase()
	var menu := _show_screen(MAIN_MENU_PATH)
	if menu == null:
		return
	menu.connect(&"new_run_requested", show_character_select)
	menu.connect(&"settings_requested", func() -> void: Game.set_settings_open(true))
	menu.connect(&"quit_requested", func() -> void: get_tree().quit())
	_set_phase(Phase.MAIN_MENU)


func show_character_select() -> void:
	_prepare_non_gameplay_phase()
	var character_select := _show_screen(CHARACTER_SELECT_PATH)
	if character_select == null:
		return
	character_select.connect(&"back_requested", show_main_menu)
	character_select.connect(&"run_requested", start_production_run)
	_set_phase(Phase.CHARACTER_SELECT)


func start_production_run(profile_index: int) -> bool:
	if not _roots_are_ready():
		return false
	Game.set_settings_open(false)
	if not RunState.start_new_run(profile_index):
		SignalBus.status_message_changed.emit("Unable to start run: invalid character build")
		return false

	_last_profile_index = RunState.selected_profile_index
	_clear_screen()
	_clear_hud()
	current_hud = _instantiate_control(PRODUCTION_HUD_PATH)
	if current_hud == null:
		show_main_menu()
		return false
	hud_root.add_child(current_hud)

	if Game.load_stage(PRODUCTION_STAGE_PATH) == null:
		show_main_menu()
		return false
	_set_phase(Phase.RUN_ACTIVE)
	return true


func show_run_result(victory: bool) -> void:
	if phase != Phase.RUN_ACTIVE:
		return
	Game.unload_current_stage()
	_clear_hud()
	var result := _show_screen(RUN_RESULT_PATH)
	if result == null:
		show_main_menu()
		return
	var profile_name := "Adventurer"
	if RunState.selected_profile != null:
		profile_name = RunState.selected_profile.display_name
	result.call(&"configure", victory, profile_name)
	result.connect(&"menu_requested", show_main_menu)
	result.connect(&"retry_requested", func() -> void: start_production_run(_last_profile_index))
	_set_phase(Phase.RUN_RESULT)


func get_phase_name() -> String:
	return Phase.keys()[phase].to_lower()


func _prepare_non_gameplay_phase() -> void:
	if not _roots_are_ready():
		return
	Game.set_settings_open(false)
	Game.unload_current_stage()
	_clear_hud()


func _show_screen(scene_path: String) -> Control:
	if not _roots_are_ready():
		return null
	_clear_screen()
	current_screen = _instantiate_control(scene_path)
	if current_screen != null:
		screen_root.add_child(current_screen)
	return current_screen


func _instantiate_control(scene_path: String) -> Control:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Unable to load production UI scene: %s" % scene_path)
		return null
	var instance := packed_scene.instantiate() as Control
	if instance == null:
		push_error("Production UI scene root must be Control: %s" % scene_path)
	return instance


func _clear_screen() -> void:
	current_screen = null
	_clear_children(screen_root)


func _clear_hud() -> void:
	current_hud = null
	_clear_children(hud_root)


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _roots_are_ready() -> bool:
	if screen_root != null and hud_root != null:
		return true
	push_error("RunDirector UI roots are not registered.")
	return false


func _set_phase(next_phase: Phase) -> void:
	phase = next_phase
	phase_changed.emit(get_phase_name())


func _on_stage_cleared(_stage_id: String) -> void:
	if phase == Phase.RUN_ACTIVE:
		call_deferred("show_run_result", true)


func _on_player_died() -> void:
	if phase == Phase.RUN_ACTIVE:
		call_deferred("show_run_result", false)
