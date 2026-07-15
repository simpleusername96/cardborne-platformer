extends Node

signal phase_changed(phase_name: String)

const MAIN_MENU_PATH := "res://scenes/ui/production/MainMenu.tscn"
const HERO_PREPARATION_PATH := "res://scenes/ui/production/HeroPreparation.tscn"
const PRODUCTION_HUD_PATH := "res://scenes/ui/production/ProductionHUD.tscn"
const RUN_RESULT_PATH := "res://scenes/ui/production/RunResult.tscn"
const LEVEL_REWARD_PATH := "res://scenes/ui/production/LevelReward.tscn"
const CARD_REWARD_PATH := "res://scenes/ui/production/CardReward.tscn"
const FORGE_SCREEN_PATH := "res://scenes/ui/production/ForgeScreen.tscn"
const MERCHANT_SCREEN_PATH := "res://scenes/ui/production/MerchantScreen.tscn"
const ARSENAL_TRIAL_PATH := "res://scenes/stages/trial/ArsenalTrial.tscn"
const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const SAFE_INTERMISSION_PATH := "res://scenes/stages/intermission/SafeIntermission.tscn"
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
var _last_profile_id: StringName = &"traveler"
var _pending_stage_clear_receipt: Dictionary = {}
var _intermission_overlay_open := false
var _interaction_heading := "TRAVELER FORGE"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.stage_cleared.connect(_on_stage_cleared)
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.boss_defeated.connect(_on_boss_defeated)
	SignalBus.forge_requested.connect(_on_intermission_forge_requested)
	SignalBus.merchant_requested.connect(_on_intermission_merchant_requested)


func register_ui_roots(p_screen_root: Control, p_hud_root: Control) -> void:
	screen_root = p_screen_root
	hud_root = p_hud_root


func start() -> void:
	show_main_menu()


func show_main_menu() -> void:
	if phase == RunPhase.Value.LOADOUT:
		_set_phase(RunPhase.Value.PREPARATION)
	elif phase not in [
		RunPhase.Value.BOOT,
		RunPhase.Value.MAIN_MENU,
		RunPhase.Value.PREPARATION,
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
	menu.connect(&"new_run_requested", show_hero_preparation)
	menu.connect(&"settings_requested", func() -> void: Game.set_settings_open(true))
	menu.connect(&"quit_requested", func() -> void: get_tree().quit())
	_set_phase(RunPhase.Value.MAIN_MENU)


func show_hero_preparation() -> void:
	_prepare_non_gameplay_phase()
	var preparation := _show_screen(HERO_PREPARATION_PATH)
	if preparation == null:
		return
	preparation.connect(&"back_requested", show_main_menu)
	preparation.connect(&"start_requested", _on_preparation_start_requested)
	preparation.connect(&"tutorial_requested", start_arsenal_trial)
	preparation.connect(
		&"equipment_command_requested",
		_on_preparation_equipment_command_requested
	)
	preparation.connect(
		&"spirit_stone_equip_requested",
		_on_preparation_spirit_stone_requested
	)
	preparation.connect(&"settings_requested", func() -> void: Game.set_settings_open(true))
	_set_phase(RunPhase.Value.PREPARATION)


func start_arsenal_trial() -> bool:
	if phase != RunPhase.Value.PREPARATION or not _roots_are_ready():
		return false
	Game.close_overlays()
	if not RunState.start_new_run(0):
		_present_preparation_result({
			"ok": false,
			"message": "The Arsenal Trial could not prepare the Traveler.",
		})
		return false
	if not _set_phase(RunPhase.Value.TRIAL_LOADING):
		return false
	_clear_screen()
	_clear_hud()
	current_hud = _instantiate_control(PRODUCTION_HUD_PATH)
	if current_hud == null:
		_set_phase(RunPhase.Value.PREPARATION)
		show_hero_preparation()
		return false
	hud_root.add_child(current_hud)
	var trial := Game.load_stage(ARSENAL_TRIAL_PATH)
	if trial == null:
		_clear_hud()
		_set_phase(RunPhase.Value.PREPARATION)
		show_hero_preparation()
		return false
	trial.call("configure_baseline_resolution_target", ProfileState, &"resolve_tutorial")
	trial.connect(&"trial_resolved", _on_arsenal_trial_resolved)
	if not _set_phase(RunPhase.Value.TRIAL_ACTIVE):
		Game.unload_current_stage()
		_clear_hud()
		show_hero_preparation()
		return false
	return true


func _on_arsenal_trial_resolved(_outcome: StringName) -> void:
	if phase != RunPhase.Value.TRIAL_ACTIVE:
		return
	Game.unload_current_stage()
	_clear_hud()
	if _set_phase(RunPhase.Value.PREPARATION):
		show_hero_preparation()


func _on_preparation_start_requested() -> void:
	var tutorial := ProfileState.get_tutorial_state()
	if not bool(tutorial.get("resolved", false)):
		var skip_result := ProfileState.resolve_tutorial(false, &"tutorial:baseline")
		if not bool(skip_result.get("ok", false)):
			_present_preparation_result(skip_result)
			return
	start_production_run(&"traveler")


func _on_preparation_equipment_command_requested(
	action: StringName,
	model_id: StringName,
	slot_id: StringName
) -> void:
	_present_preparation_result(_execute_equipment_action(action, model_id, slot_id))


func _on_preparation_spirit_stone_requested(stone_id: StringName) -> void:
	_present_preparation_result(
		_execute_equipment_action(&"equip", stone_id, &"spirit_stone")
	)


func _present_preparation_result(result: Dictionary) -> void:
	if current_screen != null and current_screen.has_method("show_command_result"):
		current_screen.call("show_command_result", result)


func start_production_run(profile_reference: Variant = &"traveler") -> bool:
	if not _roots_are_ready():
		return false
	if phase in [RunPhase.Value.RUN_DEATH, RunPhase.Value.RUN_CLEAR]:
		_set_phase(RunPhase.Value.PREPARATION)
	if phase == RunPhase.Value.MAIN_MENU:
		_set_phase(RunPhase.Value.PREPARATION)
	if phase == RunPhase.Value.PREPARATION:
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

	_last_profile_id = &"traveler"
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
	var attempt_capture: Dictionary = RunState.capture_stage_attempt(stage_path, false)
	if not bool(attempt_capture.get("ok", false)):
		Game.unload_current_stage()
		_fail_active_run(
			"Stage attempt could not be captured: %s"
			% attempt_capture.get("message", "Unknown error."),
			&"attempt_capture_failed"
		)
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
	var attempt_capture: Dictionary = RunState.capture_stage_attempt(stage_path, true)
	if not bool(attempt_capture.get("ok", false)):
		Game.unload_current_stage()
		_fail_active_run(
			"Boss attempt could not be captured: %s"
			% attempt_capture.get("message", "Unknown error."),
			&"attempt_capture_failed"
		)
		return false
	if not _set_phase(RunPhase.Value.BOSS_ACTIVE):
		Game.unload_current_stage()
		_fail_active_run("Boss could not become active.", &"boss_activation_failed")
		return false
	return true


func _load_safe_intermission() -> bool:
	if RunState.current_stage_index <= 0 or RunState.current_stage_index > NORMAL_STAGE_COUNT:
		_fail_active_run(
			"Safe Intermission requires a completed normal-stage reward.",
			&"invalid_intermission_boundary"
		)
		return false
	if not _set_phase(RunPhase.Value.INTERMISSION_LOADING):
		return false
	_clear_screen()
	_clear_hud()
	current_hud = _instantiate_control(PRODUCTION_HUD_PATH)
	if current_hud == null:
		_fail_active_run("Intermission HUD failed to initialize.", &"hud_initialization_failed")
		return false
	hud_root.add_child(current_hud)
	var intermission := Game.load_stage(SAFE_INTERMISSION_PATH) as SafeIntermission
	if intermission == null or not intermission.is_setup_complete():
		Game.unload_current_stage()
		_fail_active_run("Safe Intermission failed to initialize.", &"intermission_load_failed")
		return false
	intermission.continue_requested.connect(_on_intermission_continue_requested)
	_intermission_overlay_open = false
	if not _set_phase(RunPhase.Value.INTERMISSION_ACTIVE):
		Game.unload_current_stage()
		_fail_active_run("Safe Intermission could not become active.", &"intermission_activation_failed")
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
	if terminal_reason == &"player_defeated" and phase in [
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.BOSS_ACTIVE,
	]:
		_present_retry_decision()
		return
	_end_expedition(terminal_reason)


func retry_current_stage() -> bool:
	if phase != RunPhase.Value.RETRY_DECISION:
		return false
	var attempt := RunState.get_stage_attempt_snapshot()
	if attempt == null or not attempt.is_valid():
		_end_expedition(&"retry_snapshot_missing")
		return false
	var stage_path := attempt.get_stage_path()
	var boss_attempt := attempt.is_boss_attempt()
	var expected_path := BOSS_STAGE_PATH if boss_attempt else normal_stage_path_for_index(
		attempt.get_stage_index()
	)
	if stage_path != expected_path:
		_end_expedition(&"retry_stage_mismatch")
		return false

	Game.set_reward_choice_open(false)
	_clear_screen()
	var restore: Dictionary = RunState.restore_stage_attempt()
	if not bool(restore.get("ok", false)):
		push_error("Stage retry restore failed: %s" % restore.get("message", "Unknown error."))
		_end_expedition(&"retry_restore_failed")
		return false
	_pending_stage_clear_receipt.clear()
	_intermission_overlay_open = false
	return _load_boss_stage() if boss_attempt else _load_production_stage()


func end_expedition(reason: StringName = &"player_defeated") -> bool:
	if phase != RunPhase.Value.RETRY_DECISION:
		return false
	return _end_expedition(reason)


func _present_retry_decision() -> bool:
	if phase == RunPhase.Value.RETRY_DECISION:
		return true
	if phase not in [RunPhase.Value.STAGE_ACTIVE, RunPhase.Value.BOSS_ACTIVE]:
		return false
	if not RunState.has_stage_attempt_snapshot():
		return _end_expedition(&"retry_snapshot_missing")
	if not _set_phase(RunPhase.Value.RETRY_DECISION):
		return false
	Game.unload_current_stage()
	_clear_hud()
	var result := _show_screen(RUN_RESULT_PATH)
	if result == null:
		return _end_expedition(&"retry_ui_failed")
	var profile_name := String(
		RunState.get_hero_combat_loadout_snapshot().get("display_name", "Traveler")
	)
	result.call(
		&"configure_retry_decision",
		profile_name,
		RunState.get_stage_attempt_snapshot_data()
	)
	result.connect(&"retry_requested", retry_current_stage)
	result.connect(&"end_requested", func() -> void: end_expedition())
	Game.set_reward_choice_open(true)
	return true


func _end_expedition(reason: StringName) -> bool:
	if phase not in [
		RunPhase.Value.STAGE_LOADING,
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.LEVEL_REWARD,
		RunPhase.Value.STAGE_CARD_REWARD,
		RunPhase.Value.INTERMISSION_LOADING,
		RunPhase.Value.INTERMISSION_ACTIVE,
		RunPhase.Value.BOSS_LOADING,
		RunPhase.Value.BOSS_ACTIVE,
		RunPhase.Value.RETRY_DECISION,
	]:
		return false
	Game.set_reward_choice_open(false)
	var settlement: Dictionary = RunState.settle_run_death(reason)
	if not bool(settlement.get("ok", false)):
		push_error("Run death settlement failed: %s" % settlement.get("message", "Unknown error."))
		return false
	var terminal := settlement.get("settlement") as RunSettlementSnapshot
	if terminal == null or terminal.get_outcome() != RunSettlementSnapshot.OUTCOME_DEATH:
		return false
	if not _set_phase(RunPhase.Value.RUN_DEATH):
		return false
	_present_run_result(false)
	return true


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
	var profile_name := String(
		RunState.get_hero_combat_loadout_snapshot().get("display_name", "Traveler")
	)
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
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.BOSS_ACTIVE,
	]:
		call_deferred("_present_retry_decision")


func _on_boss_defeated(reward_table_id: StringName) -> void:
	if phase == RunPhase.Value.BOSS_ACTIVE:
		call_deferred("_settle_reported_boss_defeat", reward_table_id)


func _settle_reported_boss_defeat(reward_table_id: StringName) -> void:
	if phase == RunPhase.Value.BOSS_ACTIVE:
		# Death wins if lethal damage and boss defeat are reported in the same
		# frame, regardless of deferred callback order.
		if RunState.current_health <= 0:
			_present_retry_decision()
			return
		_settle_boss_victory(reward_table_id)


func _settle_stage_clear(stage_id: String) -> void:
	if phase != RunPhase.Value.STAGE_ACTIVE:
		return
	# A clear fact can race the lethal-hit fact in the same frame. Never award a
	# stage clear or enter rewards from a defeated attempt.
	if RunState.current_health <= 0:
		_present_retry_decision()
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
	if not RunState.advance_stage_after_card_reward():
		_set_card_reward_error("Choose a card before continuing.")
		return
	_load_safe_intermission()


func _set_card_reward_error(message: String) -> void:
	if current_screen != null and current_screen.has_method("set_commit_error"):
		current_screen.call("set_commit_error", message)


func _on_intermission_forge_requested(context: Dictionary) -> void:
	if (
		phase != RunPhase.Value.INTERMISSION_ACTIVE
		or _intermission_overlay_open
		or current_screen != null
	):
		return
	_intermission_overlay_open = true
	_interaction_heading = String(context.get("heading", "TRAVELER FORGE"))
	var forge := _show_screen(FORGE_SCREEN_PATH)
	if forge == null:
		_intermission_overlay_open = false
		return
	Game.set_reward_choice_open(true)
	_connect_forge_screen(forge)
	forge.call("configure", ProfileState.get_preparation_snapshot(), {}, _interaction_heading)


func _on_intermission_merchant_requested(context: Dictionary) -> void:
	if (
		phase != RunPhase.Value.INTERMISSION_ACTIVE
		or _intermission_overlay_open
		or current_screen != null
	):
		return
	_intermission_overlay_open = true
	_interaction_heading = String(context.get("heading", "TRAVELING MERCHANT"))
	var merchant := _show_screen(MERCHANT_SCREEN_PATH)
	if merchant == null:
		_intermission_overlay_open = false
		return
	Game.set_reward_choice_open(true)
	_connect_merchant_screen(merchant)
	merchant.call("configure", _merchant_view_snapshot(), {}, _interaction_heading)


func _connect_forge_screen(forge: Control) -> void:
	forge.connect(&"equipment_action_requested", _on_forge_equipment_action_requested)
	forge.connect(&"leave_requested", _on_forge_leave_requested)


func _on_forge_equipment_action_requested(
	action: StringName,
	model_id: StringName,
	slot_id: StringName
) -> void:
	var result := _execute_equipment_action(action, model_id, slot_id)
	if current_screen != null and current_screen.has_method("configure"):
		current_screen.call(
			"configure",
			ProfileState.get_preparation_snapshot(),
			result,
			_interaction_heading
		)


func _execute_equipment_action(
	action: StringName,
	model_id: StringName,
	slot_id: StringName
) -> Dictionary:
	var result: Dictionary
	match action:
		&"craft":
			result = ProfileState.craft_equipment(model_id)
		&"recraft":
			result = ProfileState.recraft_equipment(model_id)
		&"repair":
			result = ProfileState.repair_equipment(model_id)
		&"equip":
			result = ProfileState.equip_hero_item(slot_id, model_id)
		_:
			result = {"ok": false, "message": "Forge action is unavailable."}
	if bool(result.get("ok", false)):
		var sync := RunState.synchronize_hero_profile()
		if not bool(sync.get("ok", false)):
			result = sync
	return result


func _on_forge_leave_requested() -> void:
	_close_intermission_overlay()


func _connect_merchant_screen(merchant: Control) -> void:
	merchant.connect(&"buy_potion_requested", _on_merchant_buy_potion_requested)
	merchant.connect(&"sell_salvage_requested", _on_merchant_sell_salvage_requested)
	merchant.connect(&"leave_requested", _close_intermission_overlay)


func _on_merchant_buy_potion_requested() -> void:
	_apply_merchant_transaction(&"buy_potion")


func _on_merchant_sell_salvage_requested() -> void:
	_apply_merchant_transaction(&"sell_all_salvage")


func _apply_merchant_transaction(kind: StringName) -> void:
	if phase != RunPhase.Value.INTERMISSION_ACTIVE or not _intermission_overlay_open:
		return
	var transaction_sequence := RunState.get_applied_merchant_transaction_ids().size() + 1
	var transaction_id := StringName("%d:intermission:%d:merchant:%d:%s" % [
		RunState.run_seed,
		RunState.current_stage_index,
		transaction_sequence,
		kind,
	])
	var receipt: Variant = RunState.apply_merchant_transaction(transaction_id, kind)
	var result: Dictionary = (
		receipt.to_dictionary()
		if receipt != null and receipt.has_method("to_dictionary")
		else {"ok": false, "message": "Merchant transaction failed."}
	)
	if current_screen != null and current_screen.has_method("configure"):
		current_screen.call(
			"configure",
			_merchant_view_snapshot(),
			result,
			_interaction_heading
		)


func _merchant_view_snapshot() -> Dictionary:
	var run_snapshot := RunState.get_run_snapshot().to_dictionary()
	run_snapshot["max_consumable_charges"] = RunState.MAX_CONSUMABLE_CHARGES
	run_snapshot["buy_potion"] = RunState.preview_merchant_transaction(&"buy_potion")
	run_snapshot["sell_all_salvage"] = RunState.preview_merchant_transaction(
		&"sell_all_salvage"
	)
	return run_snapshot


func _close_intermission_overlay() -> void:
	if phase != RunPhase.Value.INTERMISSION_ACTIVE or not _intermission_overlay_open:
		return
	_intermission_overlay_open = false
	_clear_screen()


func _on_intermission_continue_requested() -> void:
	if (
		phase != RunPhase.Value.INTERMISSION_ACTIVE
		or _intermission_overlay_open
		or current_screen != null
	):
		return
	Game.unload_current_stage()
	if RunState.current_stage_index < NORMAL_STAGE_COUNT:
		_load_production_stage()
	elif RunState.current_stage_index == NORMAL_STAGE_COUNT:
		_load_boss_stage()
	else:
		_fail_active_run("Invalid intermission continuation.", &"invalid_intermission_exit")


func _profile_index_for_reference(profile_reference: Variant) -> int:
	if profile_reference is int:
		return 0 if int(profile_reference) == 0 else -1
	if profile_reference is String or profile_reference is StringName:
		return 0 if String(profile_reference) == "traveler" else -1
	return -1


func _report_start_error(message: String) -> void:
	SignalBus.status_message_changed.emit(message)
	if current_screen != null and current_screen.has_method("set_start_error"):
		current_screen.call("set_start_error", message)
