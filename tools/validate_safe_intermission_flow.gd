extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const SAFE_INTERMISSION_PATH := "res://scenes/stages/intermission/SafeIntermission.tscn"

var _failures: Array[String] = []
var _unexpected_stage_clears := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	var run_director := root.get_node_or_null("/root/RunDirector")
	var game := root.get_node_or_null("/root/Game")
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	_expect(
		run_state != null and run_director != null and game != null and signal_bus != null,
		"Safe Intermission fixture needs production autoloads."
	)
	if run_state == null or run_director == null or game == null or signal_bus == null:
		_finish()
		return
	signal_bus.stage_cleared.connect(func(_stage_id: String) -> void:
		_unexpected_stage_clears += 1
	)

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	_expect(packed_main != null, "Safe Intermission fixture should load Main.")
	if packed_main == null:
		_finish()
		return
	var main := packed_main.instantiate()
	root.add_child(main)
	await process_frame
	_expect(run_director.start_production_run(0), "Production run should start.")
	await process_frame
	await process_frame

	for completed_stage_index in RunPhase.NORMAL_STAGE_COUNT:
		_expect(
			run_director.get_phase_name() == "stage_active",
			"Normal stage %d should be active before its reward." % (completed_stage_index + 1)
		)
		var begin: Dictionary = run_state.begin_stage_card_reward()
		_expect(bool(begin.get("ok", false)), "Stage %d card reward should begin." % (completed_stage_index + 1))
		var offer: Array = run_state.get_pending_card_offer()
		_expect(offer.size() == 3, "Stage %d should offer three cards." % (completed_stage_index + 1))
		if offer.is_empty():
			break
		var chosen: Dictionary = run_state.choose_card(offer[0])
		_expect(bool(chosen.get("ok", false)), "Stage %d card should commit." % (completed_stage_index + 1))
		game.unload_current_stage()
		_expect(
			run_director.call("_set_phase", RunPhase.Value.STAGE_CARD_REWARD),
			"Stage %d should reach its card-reward phase." % (completed_stage_index + 1)
		)
		run_director.call("_on_card_continue_requested")
		await process_frame
		await process_frame
		_expect(run_director.get_phase_name() == "intermission_active", "Every card reward should enter Safe Intermission.")
		_expect(game.current_stage_path == SAFE_INTERMISSION_PATH, "Every transition should load the same safe map.")
		var intermission: Node = game.current_stage
		_expect(
			intermission != null
			and intermission.has_method("is_setup_complete")
			and bool(intermission.call("is_setup_complete")),
			"Safe Intermission should be playable."
		)
		if intermission == null:
			break
		_expect(
			intermission.has_method("has_combat_content")
			and not bool(intermission.call("has_combat_content")),
			"Safe Intermission cannot own combat content."
		)
		var hud_layout: Dictionary = run_director.current_hud.call("get_layout_snapshot")
		_expect(
			String(hud_layout.get("objective_detail", "")) == "Prepare, then continue",
			"Safe Intermission HUD should never present a combat objective."
		)
		_expect(
			intermission.find_children("*", "ForgeStationInteractable", true, false).size() == 1,
			"Safe Intermission should own one Forge NPC."
		)
		var merchants := intermission.find_children("*", "MerchantInteractable", true, false)
		_expect(merchants.size() == 1, "Safe Intermission should own one Merchant NPC.")

		if completed_stage_index == 0 and not merchants.is_empty():
			var trade_funds := RewardTransaction.new(
				&"safe_intermission_fixture:potion_funds",
				&"safe_intermission_fixture",
				{"coin": 20}
			)
			_expect(
				(run_state.apply_reward_transaction(trade_funds) as RewardResult).applied,
				"Merchant fixture should fund two potion intents."
			)
			run_state.consumable_charges = 0
			merchants[0].call("interact", intermission.get("player"))
			await process_frame
			_expect(game.reward_choice_open and paused, "Merchant should pause intermission movement.")
			_expect(
				run_director.current_screen != null
				and run_director.current_screen.has_method("configure")
				and run_director.current_screen.has_signal("buy_potion_requested"),
				"Merchant NPC should open MerchantScreen."
			)
			run_director.call("_on_merchant_buy_potion_requested")
			await process_frame
			_expect(
				run_state.coins == 10 and run_state.consumable_charges == 1,
				"First intermission potion purchase should apply."
			)
			var escape := InputEventAction.new()
			escape.action = &"pause"
			escape.pressed = true
			run_director.current_screen.call("_unhandled_input", escape)
			await process_frame
			_expect(not game.reward_choice_open and not paused, "Escape should close Merchant and resume movement.")
			_expect(game.current_stage == intermission, "Closing Merchant should retain Safe Intermission.")

			# Simulate using A in the safe map, then reopen: the second purchase must
			# own a new transaction ID instead of being rejected as a duplicate.
			run_state.consumable_charges = 0
			merchants[0].call("interact", intermission.get("player"))
			await process_frame
			run_director.call("_on_merchant_buy_potion_requested")
			await process_frame
			_expect(
				run_state.coins == 0 and run_state.consumable_charges == 1,
				"Second intermission potion purchase should apply as a new intent."
			)
			_expect(
				run_state.get_applied_merchant_transaction_ids().size() == 2,
				"Two purchases should retain two distinct transaction IDs."
			)
			run_director.current_screen.call("_unhandled_input", escape)
			await process_frame
			_expect(not game.reward_choice_open and not paused, "Second Escape should restore movement.")

		intermission.call("complete_stage")
		await process_frame
		await process_frame
		_expect(_unexpected_stage_clears == 0, "Intermission Continue must not emit another stage clear.")
		if completed_stage_index < RunPhase.NORMAL_STAGE_COUNT - 1:
			_expect(run_director.get_phase_name() == "stage_active", "Intermission should load the next normal stage.")
			_expect(int(run_state.current_stage_index) == completed_stage_index + 1, "Stage index should advance exactly once.")
		else:
			_expect(run_director.get_phase_name() == "boss_active", "Final intermission should load the boss.")
			_expect(run_state.has_stage_attempt_snapshot(), "Boss should capture a post-intermission attempt.")

	run_director.show_main_menu()
	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	if _failures.is_empty():
		print("SAFE_INTERMISSION_FLOW_VALIDATION_OK visits=3 forge=1 merchant=1 boss=true")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
