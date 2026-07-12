extends Node

signal phase_changed(phase_name: String)

const MAIN_MENU_PATH := "res://scenes/ui/production/MainMenu.tscn"
const CHARACTER_SELECT_PATH := "res://scenes/ui/production/CharacterSelect.tscn"
const PRODUCTION_HUD_PATH := "res://scenes/ui/production/ProductionHUD.tscn"
const RUN_RESULT_PATH := "res://scenes/ui/production/RunResult.tscn"
const LEVEL_REWARD_PATH := "res://scenes/ui/production/LevelReward.tscn"
const CARD_REWARD_PATH := "res://scenes/ui/production/CardReward.tscn"
const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"

var phase: RunPhase.Value = RunPhase.Value.BOOT
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
	if phase == RunPhase.Value.LOADOUT:
		_set_phase(RunPhase.Value.CHARACTER_SELECT)
	elif phase not in [
		RunPhase.Value.BOOT,
		RunPhase.Value.MAIN_MENU,
		RunPhase.Value.CHARACTER_SELECT,
		RunPhase.Value.RUN_DEATH,
		RunPhase.Value.RUN_CLEAR,
	]:
		_set_phase(RunPhase.Value.RUN_DEATH)
	_prepare_non_gameplay_phase()
	var menu := _show_screen(MAIN_MENU_PATH)
	if menu == null:
		return
	menu.connect(&"new_run_requested", show_character_select)
	menu.connect(&"settings_requested", func() -> void: Game.set_settings_open(true))
	menu.connect(&"quit_requested", func() -> void: get_tree().quit())
	_set_phase(RunPhase.Value.MAIN_MENU)


func show_character_select() -> void:
	_prepare_non_gameplay_phase()
	var character_select := _show_screen(CHARACTER_SELECT_PATH)
	if character_select == null:
		return
	character_select.connect(&"back_requested", show_main_menu)
	character_select.connect(&"run_requested", start_production_run)
	_set_phase(RunPhase.Value.CHARACTER_SELECT)


func start_production_run(profile_index: int) -> bool:
	if not _roots_are_ready():
		return false
	if phase in [RunPhase.Value.RUN_DEATH, RunPhase.Value.RUN_CLEAR]:
		_set_phase(RunPhase.Value.CHARACTER_SELECT)
	if phase == RunPhase.Value.MAIN_MENU:
		_set_phase(RunPhase.Value.CHARACTER_SELECT)
	if phase == RunPhase.Value.CHARACTER_SELECT:
		_set_phase(RunPhase.Value.LOADOUT)
	if phase != RunPhase.Value.LOADOUT:
		return false
	Game.set_settings_open(false)
	if not RunState.start_new_run(profile_index):
		SignalBus.status_message_changed.emit("Unable to start run: invalid character build")
		return false

	_last_profile_index = RunState.selected_profile_index
	return _load_production_stage()


func _load_production_stage() -> bool:
	if not _set_phase(RunPhase.Value.STAGE_LOADING):
		return false
	_clear_screen()
	_clear_hud()
	current_hud = _instantiate_control(PRODUCTION_HUD_PATH)
	if current_hud == null:
		show_main_menu()
		return false
	hud_root.add_child(current_hud)

	var loaded_stage := Game.load_stage(PRODUCTION_STAGE_PATH)
	if loaded_stage == null:
		show_main_menu()
		return false
	if (
		loaded_stage.has_method("is_setup_complete")
		and not bool(loaded_stage.call("is_setup_complete"))
	):
		Game.unload_current_stage()
		SignalBus.status_message_changed.emit("Stage generation failed")
		show_main_menu()
		return false
	_set_phase(RunPhase.Value.STAGE_ACTIVE)
	return true


func show_run_result(victory: bool) -> void:
	var terminal_phase := RunPhase.Value.RUN_CLEAR if victory else RunPhase.Value.RUN_DEATH
	if phase not in [
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.LEVEL_REWARD,
		RunPhase.Value.STAGE_CARD_REWARD,
		RunPhase.Value.BOSS_ACTIVE,
	]:
		return
	if not _set_phase(terminal_phase):
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


func get_phase_name() -> String:
	return RunPhase.name_of(phase)


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


func _set_phase(next_phase: RunPhase.Value) -> bool:
	if next_phase == phase:
		return true
	if not RunPhase.can_transition(phase, next_phase):
		push_error(
			"Illegal run phase transition: %s -> %s"
			% [RunPhase.name_of(phase), RunPhase.name_of(next_phase)]
		)
		return false
	phase = next_phase
	phase_changed.emit(get_phase_name())
	return true


func _on_stage_cleared(stage_id: String) -> void:
	if phase == RunPhase.Value.STAGE_ACTIVE:
		call_deferred("_settle_stage_clear", stage_id)


func _on_player_died() -> void:
	if phase in [RunPhase.Value.STAGE_LOADING, RunPhase.Value.STAGE_ACTIVE, RunPhase.Value.BOSS_ACTIVE]:
		call_deferred("show_run_result", false)


func _settle_stage_clear(stage_id: String) -> void:
	if phase != RunPhase.Value.STAGE_ACTIVE:
		return
	var table := RunState.reward_catalog.get_table(&"stage_clear_ruin_approach")
	var transaction_id := StringName("%d:%d:%s:stage_clear:0" % [
		RunState.run_seed,
		RunState.current_stage_index,
		stage_id,
	])
	var transaction := RewardService.resolve(table, transaction_id, RunState.run_seed)
	var result := RewardService.apply(transaction, RunState)
	if not result.applied and not result.duplicate:
		push_error("Stage clear reward failed: %s" % result.message)
		show_run_result(true)
		return
	Game.unload_current_stage()
	_clear_hud()
	if RunState.get_pending_level_choice_count() > 0:
		_show_level_reward()
	else:
		_show_card_reward()


func _show_level_reward() -> void:
	if not _set_phase(RunPhase.Value.LEVEL_REWARD):
		return
	var level_reward := _show_screen(LEVEL_REWARD_PATH)
	if level_reward == null:
		show_run_result(true)
		return
	level_reward.connect(&"choice_requested", _on_level_choice_requested)


func _on_level_choice_requested(upgrade_id: StringName) -> void:
	if phase != RunPhase.Value.LEVEL_REWARD:
		return
	var result: Dictionary = RunState.choose_micro_upgrade(upgrade_id)
	if not bool(result.get("ok", false)):
		if current_screen != null and current_screen.has_method("set_commit_error"):
			current_screen.call("set_commit_error", str(result.get("message", "Choice failed.")))
		return
	if RunState.get_pending_level_choice_count() > 0:
		_show_level_reward()
	else:
		_show_card_reward()


func _show_card_reward() -> void:
	var begin_result := RunState.begin_stage_card_reward()
	if not bool(begin_result.get("ok", false)):
		push_error("Card reward failed: %s" % begin_result.get("message", "Unknown error."))
		show_run_result(true)
		return
	if not _set_phase(RunPhase.Value.STAGE_CARD_REWARD):
		return
	var card_reward := _show_screen(CARD_REWARD_PATH)
	if card_reward == null:
		show_run_result(true)
		return
	card_reward.connect(&"choice_requested", _on_card_choice_requested)
	card_reward.connect(&"reroll_requested", _on_card_reroll_requested)
	card_reward.connect(&"continue_requested", _on_card_continue_requested)


func _on_card_choice_requested(card_id: StringName) -> void:
	if phase != RunPhase.Value.STAGE_CARD_REWARD:
		return
	var result := RunState.choose_card(card_id)
	if not bool(result.get("ok", false)):
		_set_card_reward_error(str(result.get("message", "Choice failed.")))
		return
	if current_screen != null and current_screen.has_method("show_commit_result"):
		current_screen.call("show_commit_result", result)


func _on_card_reroll_requested() -> void:
	if phase != RunPhase.Value.STAGE_CARD_REWARD:
		return
	var result := RunState.reroll_card_offer()
	if not bool(result.get("ok", false)):
		_set_card_reward_error(str(result.get("message", "Reroll failed.")))
		return
	if current_screen != null and current_screen.has_method("refresh_offer"):
		current_screen.call("refresh_offer")


func _on_card_continue_requested() -> void:
	if phase != RunPhase.Value.STAGE_CARD_REWARD:
		return
	if not RunState.advance_stage_after_card_reward():
		_set_card_reward_error("Choose a card before continuing.")
		return
	_load_production_stage()


func _set_card_reward_error(message: String) -> void:
	if current_screen != null and current_screen.has_method("set_commit_error"):
		current_screen.call("set_commit_error", message)
