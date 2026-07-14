extends Node

signal phase_changed(phase_name: String)

const MAIN_MENU_PATH := "res://scenes/ui/production/MainMenu.tscn"
const CHARACTER_SELECT_PATH := "res://scenes/ui/production/CharacterSelect.tscn"
const PRODUCTION_HUD_PATH := "res://scenes/ui/production/ProductionHUD.tscn"
const RUN_RESULT_PATH := "res://scenes/ui/production/RunResult.tscn"
const LEVEL_REWARD_PATH := "res://scenes/ui/production/LevelReward.tscn"
const CARD_REWARD_PATH := "res://scenes/ui/production/CardReward.tscn"
const REST_FORGE_PATH := "res://scenes/ui/production/RestForge.tscn"
const TREASURE_CHOICE_PATH := "res://scenes/ui/production/TreasureChoice.tscn"
const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const BOSS_STAGE_PATH := "res://scenes/stages/boss/SlimeCourt.tscn"
const REWARD_RECEIPT_PRESENTER := preload(
	"res://scripts/ui/production/RewardReceiptPresenter.gd"
)
const BOSS_CLEAR_REWARD_TABLE_ID := RunSettlementService.DEFAULT_BOSS_REWARD_TABLE_ID
const NORMAL_STAGE_COUNT := RunPhase.NORMAL_STAGE_COUNT

var phase: RunPhase.Value = RunPhase.Value.BOOT
var screen_root: Control
var hud_root: Control
var current_screen: Control
var current_hud: Control
var _last_profile_id: StringName = &"warrior"
var _treasure_choice_screen: Control
var _pending_stage_clear_receipt: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.stage_cleared.connect(_on_stage_cleared)
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.boss_defeated.connect(_on_boss_defeated)
	SignalBus.reward_preview_replacement_requested.connect(_on_treasure_choice_requested)


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
		var settlement: Dictionary = RunState.settle_run_death(&"run_abandoned")
		var terminal := settlement.get("settlement") as RunSettlementSnapshot
		if (
			not bool(settlement.get("ok", false))
			or terminal == null
			or terminal.get_outcome() != RunSettlementSnapshot.OUTCOME_DEATH
			or not _set_phase(RunPhase.Value.RUN_DEATH)
		):
			push_error("Active run could not settle before returning to the main menu.")
			return
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
	character_select.connect(&"equipment_action_requested", _on_equipment_action_requested)
	character_select.connect(&"mastery_purchase_requested", _on_mastery_purchase_requested)
	character_select.connect(&"mastery_respec_requested", _on_mastery_respec_requested)
	character_select.connect(&"persistence_retry_requested", _on_persistence_retry_requested)
	_set_phase(RunPhase.Value.CHARACTER_SELECT)


func start_production_run(profile_reference: Variant) -> bool:
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
	var profile_index := _profile_index_for_reference(profile_reference)
	if profile_index < 0:
		_report_start_error("Character is unavailable.")
		return false
	Game.close_overlays()
	if not RunState.start_new_run(profile_index):
		_report_start_error("Loadout is invalid. Check the highlighted slot.")
		return false

	_last_profile_id = StringName(RunState.selected_profile.id)
	return _load_production_stage()


func _load_production_stage() -> bool:
	var stage_path := normal_stage_path_for_index(RunState.current_stage_index)
	if stage_path.is_empty():
		_fail_active_run(
			"Refused to load normal stage index %d." % RunState.current_stage_index,
			&"invalid_stage_index"
		)
		return false
	if not _set_phase(RunPhase.Value.STAGE_LOADING):
		return false
	_clear_screen()
	_clear_hud()
	current_hud = _instantiate_control(PRODUCTION_HUD_PATH)
	if current_hud == null:
		_fail_active_run("Gameplay HUD failed to initialize.", &"hud_initialization_failed")
		return false
	hud_root.add_child(current_hud)

	var loaded_stage := Game.load_stage(stage_path)
	if loaded_stage == null:
		_fail_active_run("Normal stage failed to load.", &"stage_load_failed")
		return false
	if (
		loaded_stage.has_method("is_setup_complete")
		and not bool(loaded_stage.call("is_setup_complete"))
	):
		Game.unload_current_stage()
		_fail_active_run("Stage generation failed.", &"stage_initialization_failed")
		return false
	if not _set_phase(RunPhase.Value.STAGE_ACTIVE):
		Game.unload_current_stage()
		_fail_active_run("Normal stage could not become active.", &"stage_activation_failed")
		return false
	return true


func _load_boss_stage() -> bool:
	var stage_path := stage_path_for_index(RunState.current_stage_index)
	if RunState.current_stage_index != NORMAL_STAGE_COUNT or stage_path != BOSS_STAGE_PATH:
		_fail_active_run(
			"Boss loading requires all three normal-stage rewards.",
			&"invalid_boss_boundary"
		)
		return false
	if not _set_phase(RunPhase.Value.BOSS_LOADING):
		return false
	_clear_screen()
	_clear_hud()
	current_hud = _instantiate_control(PRODUCTION_HUD_PATH)
	if current_hud == null:
		_fail_active_run("Boss HUD failed to initialize.", &"boss_hud_initialization_failed")
		return false
	hud_root.add_child(current_hud)

	var loaded_stage := Game.load_stage(stage_path)
	if loaded_stage == null:
		_fail_active_run("Slime Court failed to load.", &"boss_load_failed")
		return false
	if (
		loaded_stage.has_method("is_setup_complete")
		and not bool(loaded_stage.call("is_setup_complete"))
	):
		Game.unload_current_stage()
		_fail_active_run("Slime Court failed to initialize.", &"boss_initialization_failed")
		return false
	if not _set_phase(RunPhase.Value.BOSS_ACTIVE):
		Game.unload_current_stage()
		_fail_active_run("Boss could not become active.", &"boss_activation_failed")
		return false
	return true


func show_run_result(
	victory: bool,
	terminal_reason: StringName = &"player_defeated",
	boss_reward_table_id: StringName = BOSS_CLEAR_REWARD_TABLE_ID
) -> void:
	if victory:
		_settle_boss_victory(boss_reward_table_id)
		return
	if phase not in [
		RunPhase.Value.STAGE_LOADING,
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.LEVEL_REWARD,
		RunPhase.Value.STAGE_CARD_REWARD,
		RunPhase.Value.REST_FORGE,
		RunPhase.Value.BOSS_LOADING,
		RunPhase.Value.BOSS_ACTIVE,
	]:
		return
	var settlement: Dictionary = RunState.settle_run_death(terminal_reason)
	if not bool(settlement.get("ok", false)):
		push_error("Run death settlement failed: %s" % settlement.get("message", "Unknown error."))
		return
	var terminal := settlement.get("settlement") as RunSettlementSnapshot
	if terminal == null or terminal.get_outcome() != RunSettlementSnapshot.OUTCOME_DEATH:
		return
	if not _set_phase(RunPhase.Value.RUN_DEATH):
		return
	_present_run_result(false)


func _settle_boss_victory(reward_table_id: StringName) -> bool:
	# Victory is legal only after the authored boss reports defeat during active play.
	if phase != RunPhase.Value.BOSS_ACTIVE:
		return false
	var settlement: Dictionary = RunState.settle_run_victory(reward_table_id)
	if not bool(settlement.get("ok", false)):
		_fail_active_run(
			"Boss victory settlement failed: %s"
			% settlement.get("message", "Unknown error."),
			&"boss_settlement_failed"
		)
		return false
	var terminal := settlement.get("settlement") as RunSettlementSnapshot
	if terminal == null or not terminal.is_victory():
		return false
	if not _set_phase(RunPhase.Value.RUN_CLEAR):
		return false
	_present_run_result(true)
	return true


func _present_run_result(victory: bool) -> void:
	Game.unload_current_stage()
	_clear_hud()
	var result := _show_screen(RUN_RESULT_PATH)
	if result == null:
		show_main_menu()
		return
	var profile_name := "Adventurer"
	if RunState.selected_profile != null:
		profile_name = RunState.selected_profile.display_name
	result.call(
		&"configure",
		victory,
		profile_name,
		RunState.get_terminal_settlement_snapshot()
	)
	result.connect(&"menu_requested", show_main_menu)
	result.connect(&"retry_requested", func() -> void: start_production_run(_last_profile_id))


func _fail_active_run(message: String, reason: StringName) -> void:
	push_error(message)
	SignalBus.status_message_changed.emit(message)
	show_run_result(false, reason)


func normal_stage_path_for_index(stage_index: int) -> String:
	return PRODUCTION_STAGE_PATH if stage_index >= 0 and stage_index < NORMAL_STAGE_COUNT else ""


func stage_path_for_index(stage_index: int) -> String:
	if stage_index == NORMAL_STAGE_COUNT:
		return BOSS_STAGE_PATH
	return normal_stage_path_for_index(stage_index)


func get_phase_name() -> String:
	return RunPhase.name_of(phase)


func _prepare_non_gameplay_phase() -> void:
	if not _roots_are_ready():
		return
	Game.close_overlays()
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
	if current_screen != null and current_screen == _treasure_choice_screen:
		_resolve_treasure_choice_fallback(
			"Treasure choice closed; normal chest reward applied."
		)
	_treasure_choice_screen = null
	Game.set_reward_choice_open(false)
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
	if phase in [
		RunPhase.Value.STAGE_LOADING,
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.BOSS_LOADING,
		RunPhase.Value.BOSS_ACTIVE,
	]:
		call_deferred("show_run_result", false)


func _on_boss_defeated(reward_table_id: StringName) -> void:
	if phase == RunPhase.Value.BOSS_ACTIVE:
		call_deferred("_settle_reported_boss_defeat", reward_table_id)


func _on_treasure_choice_requested(snapshot: Dictionary) -> void:
	if phase != RunPhase.Value.STAGE_ACTIVE:
		return
	if not _roots_are_ready():
		_resolve_treasure_choice_fallback(
			"Treasure choice UI roots were unavailable; normal chest reward applied."
		)
		return
	var choice_screen := _show_screen(TREASURE_CHOICE_PATH)
	if choice_screen == null:
		_resolve_treasure_choice_fallback(
			"Treasure choice UI was unavailable; normal chest reward applied."
		)
		return
	_treasure_choice_screen = choice_screen
	Game.set_reward_choice_open(true)
	choice_screen.connect(&"choice_requested", _on_treasure_choice_committed)
	choice_screen.call("configure", snapshot)


func _on_treasure_choice_committed(request_id: StringName, choice_id: StringName) -> void:
	if phase != RunPhase.Value.STAGE_ACTIVE or not Game.reward_choice_open:
		return
	var result := RunState.commit_optional_chest_choice(request_id, choice_id)
	if not bool(result.get("ok", false)):
		if current_screen != null and current_screen.has_method("set_commit_error"):
			current_screen.call(
				"set_commit_error",
				String(result.get("message", "Treasure choice failed."))
			)
		return
	_clear_screen()


func _resolve_treasure_choice_fallback(message: String) -> bool:
	var pending := RunState.get_pending_optional_chest_choice()
	if pending.is_empty():
		return true
	var request_id := StringName(pending.get("request_id", &""))
	var result := RunState.commit_optional_chest_choice(
		request_id,
		TreasureChoiceService.NORMAL_CHOICE_ID
	)
	if bool(result.get("ok", false)):
		SignalBus.status_message_changed.emit(message)
		return true
	RunState.cancel_optional_chest_choice(
		request_id,
		String(result.get("message", "Treasure choice was cancelled."))
	)
	SignalBus.status_message_changed.emit(
		String(result.get("message", "Treasure choice was cancelled; reopen the chest."))
	)
	return false


func _settle_reported_boss_defeat(reward_table_id: StringName) -> void:
	if phase == RunPhase.Value.BOSS_ACTIVE:
		_settle_boss_victory(reward_table_id)


func _settle_stage_clear(stage_id: String) -> void:
	if phase != RunPhase.Value.STAGE_ACTIVE:
		return
	var table_id := StringName("stage_clear_%s" % stage_id)
	if Game.current_stage != null and Game.current_stage.has_method("get_clear_reward_table_id"):
		table_id = Game.current_stage.call("get_clear_reward_table_id")
	var table := RunState.reward_catalog.get_table(table_id)
	if table == null:
		_fail_active_run(
			"Stage '%s' has no clear reward table '%s'." % [stage_id, table_id],
			&"stage_reward_missing"
		)
		return
	var transaction_id := StringName("%d:%d:%s:stage_clear:0" % [
		RunState.run_seed,
		RunState.current_stage_index,
		stage_id,
	])
	var transaction := RewardService.resolve(table, transaction_id, RunState.run_seed)
	var result := RewardService.apply(transaction, RunState)
	if not result.applied and not result.duplicate:
		_fail_active_run(
			"Stage clear reward failed: %s" % result.message,
			&"stage_reward_failed"
		)
		return
	if result.applied:
		_pending_stage_clear_receipt = result.to_dictionary()
		_pending_stage_clear_receipt["reward_role"] = "stage_clear"
		_pending_stage_clear_receipt["source_id"] = String(table_id)
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
		_fail_active_run("Level reward UI failed to initialize.", &"level_reward_ui_failed")
		return
	_present_pending_stage_clear_receipt(level_reward)
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
		_fail_active_run(
			"Card reward failed: %s" % begin_result.get("message", "Unknown error."),
			&"card_reward_initialization_failed"
		)
		return
	if not _set_phase(RunPhase.Value.STAGE_CARD_REWARD):
		return
	var card_reward := _show_screen(CARD_REWARD_PATH)
	if card_reward == null:
		_fail_active_run("Card reward UI failed to initialize.", &"card_reward_ui_failed")
		return
	_present_pending_stage_clear_receipt(card_reward)
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


func _present_pending_stage_clear_receipt(screen: Control) -> void:
	if screen == null or _pending_stage_clear_receipt.is_empty():
		return
	var presenter := REWARD_RECEIPT_PRESENTER.new() as RewardReceiptPresenter
	presenter.name = "StageClearReceipt"
	screen.add_child(presenter)
	presenter.present(_pending_stage_clear_receipt)
	_pending_stage_clear_receipt.clear()


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
	var completed_stage_index := RunState.current_stage_index
	if not RunState.advance_stage_after_card_reward():
		_set_card_reward_error("Choose a card before continuing.")
		return
	match completed_stage_index:
		0:
			_load_production_stage()
		1:
			_show_rest_forge()
		2:
			_load_boss_stage()
		_:
			_fail_active_run("Invalid stage card continuation.", &"invalid_card_continuation")


func _set_card_reward_error(message: String) -> void:
	if current_screen != null and current_screen.has_method("set_commit_error"):
		current_screen.call("set_commit_error", message)


func _show_rest_forge() -> void:
	var begin_result := RunState.begin_rest_forge()
	if not bool(begin_result.get("ok", false)):
		_fail_active_run("Rest/forge failed to initialize.", &"rest_forge_initialization_failed")
		return
	if not _set_phase(RunPhase.Value.REST_FORGE):
		return
	var rest := _show_screen(REST_FORGE_PATH)
	if rest == null:
		_fail_active_run("Rest/forge UI failed to initialize.", &"rest_forge_ui_failed")
		return
	rest.connect(&"heal_requested", _on_rest_heal_requested)
	rest.connect(&"consumable_requested", _on_rest_consumable_requested)
	rest.connect(&"forge_item_requested", _on_forge_item_requested)
	rest.connect(&"forge_affix_requested", _on_forge_affix_requested)
	rest.connect(&"leave_requested", _on_rest_leave_requested)
	rest.call("configure", RunState.get_rest_forge_snapshot())


func _on_rest_heal_requested() -> void:
	_publish_rest_result(RunState.buy_rest_heal())


func _on_rest_consumable_requested(consumable_id: StringName) -> void:
	_publish_rest_result(RunState.buy_rest_consumable(consumable_id))


func _on_forge_item_requested(item_id: StringName) -> void:
	_publish_rest_result(RunState.begin_forge_offer(item_id))


func _on_forge_affix_requested(
	item_id: StringName,
	affix_id: StringName,
	confirm_replace: bool
) -> void:
	_publish_rest_result(RunState.commit_forge_affix(item_id, affix_id, confirm_replace))


func _publish_rest_result(result: Dictionary) -> void:
	if current_screen != null and current_screen.has_method("configure"):
		current_screen.call("configure", RunState.get_rest_forge_snapshot(), result)


func _on_rest_leave_requested() -> void:
	if phase != RunPhase.Value.REST_FORGE or not RunState.end_rest_forge():
		return
	_load_production_stage()


func _profile_index_for_reference(profile_reference: Variant) -> int:
	if profile_reference is int:
		return int(profile_reference) if int(profile_reference) >= 0 else -1
	if profile_reference is String or profile_reference is StringName:
		return RunState.character_catalog.get_profile_index(String(profile_reference))
	return -1


func _report_start_error(message: String) -> void:
	SignalBus.status_message_changed.emit(message)
	if current_screen != null and current_screen.has_method("set_start_error"):
		current_screen.call("set_start_error", message)


func _on_equipment_action_requested(
	character_id: StringName,
	slot_id: StringName,
	item_id: StringName,
	unlock: bool
) -> void:
	if phase not in [RunPhase.Value.CHARACTER_SELECT, RunPhase.Value.LOADOUT]:
		return
	var result := (
		ProfileState.purchase_equipment(item_id)
		if unlock
		else ProfileState.equip_item(character_id, slot_id, item_id)
	)
	_publish_profile_command_result(result)


func _on_mastery_purchase_requested(character_id: StringName, node_id: StringName) -> void:
	if phase not in [RunPhase.Value.CHARACTER_SELECT, RunPhase.Value.LOADOUT]:
		return
	_publish_profile_command_result(ProfileState.purchase_mastery(character_id, node_id))


func _on_mastery_respec_requested(character_id: StringName) -> void:
	if phase not in [RunPhase.Value.CHARACTER_SELECT, RunPhase.Value.LOADOUT]:
		return
	_publish_profile_command_result(ProfileState.respec_character(character_id))


func _publish_profile_command_result(result: Dictionary) -> void:
	if current_screen != null and current_screen.has_method("show_profile_command_result"):
		current_screen.call("show_profile_command_result", result)


func _on_persistence_retry_requested() -> void:
	var save_result := ProfileState.save_profile()
	save_result["persisted"] = bool(save_result.get("ok", false))
	_publish_profile_command_result(save_result)
