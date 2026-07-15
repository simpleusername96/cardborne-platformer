extends SceneTree

var _failures: Array[String] = []
var _run_director: Node
var _run_state: Node
var _profile_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_director = root.get_node_or_null("/root/RunDirector")
	_run_state = root.get_node_or_null("/root/RunState")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_expect(
		_run_director != null and _run_state != null and _profile_state != null,
		"boss flow fixture needs production autoloads"
	)
	if _run_director == null or _run_state == null or _profile_state == null:
		_finish()
		return
	_profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_validate_phase_contract()
	_validate_third_card_boundary()
	_validate_victory_gate()
	await _validate_boss_clear_integration()
	_finish()


func _validate_phase_contract() -> void:
	_expect(
		RunPhase.can_transition(
			RunPhase.Value.STAGE_ACTIVE,
			RunPhase.Value.STAGE_CARD_REWARD
		),
		"Stage 3 clear should enter its normal card reward"
	)
	_expect(
		RunPhase.can_transition(
			RunPhase.Value.STAGE_CARD_REWARD,
			RunPhase.Value.INTERMISSION_LOADING
		),
		"the third card continuation should enter intermission loading"
	)
	_expect(
		RunPhase.can_transition(
			RunPhase.Value.INTERMISSION_LOADING,
			RunPhase.Value.INTERMISSION_ACTIVE
		),
		"the final Safe Intermission should become active"
	)
	_expect(
		RunPhase.can_transition(
			RunPhase.Value.INTERMISSION_ACTIVE,
			RunPhase.Value.BOSS_LOADING
		),
		"leaving the final Safe Intermission should enter boss loading"
	)
	_expect(
		RunPhase.can_transition(RunPhase.Value.BOSS_LOADING, RunPhase.Value.BOSS_ACTIVE),
		"successful boss loading should enter active boss play"
	)
	_expect(
		RunPhase.can_transition(RunPhase.Value.BOSS_ACTIVE, RunPhase.Value.RUN_CLEAR),
		"only active boss play should reach run clear"
	)
	var boss_loading_edges: Array = RunPhase.LEGAL_TRANSITIONS.get(
		RunPhase.Value.BOSS_LOADING,
		[]
	)
	_expect(
		boss_loading_edges.size() == 2
		and boss_loading_edges.has(RunPhase.Value.BOSS_ACTIVE)
		and boss_loading_edges.has(RunPhase.Value.RUN_DEATH),
		"boss loading should transition only to active play or failure/death"
	)
	_expect(
		RunPhase.can_transition(RunPhase.Value.BOSS_LOADING, RunPhase.Value.RUN_DEATH),
		"boss loading failure should terminate without victory"
	)
	for early_phase in [
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.LEVEL_REWARD,
		RunPhase.Value.STAGE_CARD_REWARD,
		RunPhase.Value.INTERMISSION_LOADING,
		RunPhase.Value.INTERMISSION_ACTIVE,
		RunPhase.Value.BOSS_LOADING,
	]:
		_expect(
			not RunPhase.can_transition(early_phase, RunPhase.Value.RUN_CLEAR),
			"%s must not report early victory" % RunPhase.name_of(early_phase)
		)


func _validate_third_card_boundary() -> void:
	_expect(_run_state.start_new_run(0, 88008), "third-card fixture run should start")
	_run_state.current_stage_index = 2
	var begin: Dictionary = _run_state.begin_stage_card_reward()
	_expect(bool(begin.get("ok", false)), "Stage 3 should receive a card offer")
	var offer: Array[StringName] = _run_state.get_pending_card_offer()
	_expect(offer.size() == 3, "Stage 3 should receive exactly three card choices")
	if offer.is_empty():
		return
	var chosen := offer[0]
	var committed: Dictionary = _run_state.choose_card(chosen)
	_expect(bool(committed.get("ok", false)), "the third card should commit once")
	_expect(_run_state.advance_stage_after_card_reward(), "third-card Continue should advance")
	_expect(_run_state.current_stage_index == 3, "third-card Continue should reach boss index 3")
	_expect(
		not _run_state.advance_stage_after_card_reward(),
		"duplicate third-card Continue should not advance again"
	)
	_expect(_run_state.current_stage_index == 3, "duplicate Continue should keep boss index 3")
	_expect(
		not bool(_run_state.begin_stage_card_reward().get("ok", false)),
		"the boss boundary should not expose a fourth card reward"
	)
	_expect(
		String(_run_director.call("normal_stage_path_for_index", 3)).is_empty(),
		"normal stage loading must reject index 3"
	)
	_expect(
		String(_run_director.call("stage_path_for_index", 3))
		== "res://scenes/stages/boss/SlimeCourt.tscn",
		"boss index 3 should resolve only to canonical Slime Court"
	)
	for normal_index in 3:
		_expect(
			String(_run_director.call("normal_stage_path_for_index", normal_index))
			== "res://scenes/stages/production/ProductionStageHost.tscn",
			"normal stage index %d should retain the production host" % normal_index
		)
func _validate_victory_gate() -> void:
	var original_phase: int = int(_run_director.get("phase"))
	for early_phase in [
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.STAGE_CARD_REWARD,
		RunPhase.Value.BOSS_LOADING,
	]:
		_run_director.set("phase", early_phase)
		_run_director.call("show_run_result", true)
		_expect(
			int(_run_director.get("phase")) == early_phase,
			"show_run_result(true) should be rejected from %s" % RunPhase.name_of(early_phase)
		)
	_run_director.set("phase", original_phase)
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	_expect(
		signal_bus != null
		and signal_bus.has_signal("boss_defeated")
		and signal_bus.has_signal("run_settled"),
		"boss defeat and terminal settlement facts should have SignalBus contracts"
	)


func _validate_boss_clear_integration() -> void:
	var original_reward_catalog: RewardCatalog = _run_state.get("reward_catalog")
	_run_state.set("reward_catalog", _boss_reward_catalog())
	var screen_root := Control.new()
	var hud_root := Control.new()
	root.add_child(screen_root)
	root.add_child(hud_root)
	_run_director.call("register_ui_roots", screen_root, hud_root)
	for next_phase in [
		RunPhase.Value.MAIN_MENU,
		RunPhase.Value.PREPARATION,
		RunPhase.Value.LOADOUT,
		RunPhase.Value.STAGE_LOADING,
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.STAGE_CARD_REWARD,
		RunPhase.Value.INTERMISSION_LOADING,
		RunPhase.Value.INTERMISSION_ACTIVE,
		RunPhase.Value.BOSS_LOADING,
		RunPhase.Value.BOSS_ACTIVE,
	]:
		_expect(
			bool(_run_director.call("_set_phase", next_phase)),
			"phase path should enter %s" % RunPhase.name_of(next_phase)
		)
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	signal_bus.boss_defeated.emit(&"boss_clear_slime_king")
	await process_frame
	_expect(_run_director.get_phase_name() == "run_clear", "active boss defeat should clear the run")
	_expect(_profile_state.get_material_count("boss_core") == 1, "boss clear should grant one core")
	var terminal: Dictionary = _run_state.get_terminal_settlement_snapshot()
	_expect(bool(terminal.get("victory", false)), "boss clear should publish victory settlement")
	_expect(
		screen_root.get_node_or_null("RunResult") != null,
		"boss clear should mount the production result screen"
	)
	signal_bus.boss_defeated.emit(&"boss_clear_slime_king")
	await process_frame
	_expect(_profile_state.get_material_count("boss_core") == 1, "duplicate boss fact should be ignored")
	_run_state.set("reward_catalog", original_reward_catalog)
	screen_root.queue_free()
	hud_root.queue_free()


func _boss_reward_catalog() -> RewardCatalog:
	var core := RewardEntry.new()
	core.content_id = &"boss_core"
	var table := RewardTable.new()
	table.id = &"boss_clear_slime_king"
	table.display_name = "Slime King Clear"
	table.entries.append(core)
	var catalog := RewardCatalog.new()
	catalog.id = &"boss_flow_fixture"
	catalog.display_name = "Boss Flow Fixture"
	catalog.tables.append(table)
	return catalog


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BOSS_RUN_FLOW_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
