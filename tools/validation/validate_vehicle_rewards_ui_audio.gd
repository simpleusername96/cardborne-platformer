extends SceneTree

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const RewardRuntime = preload("res://scripts/rewards/vehicle_reward_runtime.gd")
const VehicleRun = preload("res://scripts/vehicle/vehicle_run.gd")
const UpgradePanel = preload("res://scripts/ui/vehicle_upgrade_choice_panel.gd")
const AudioDirector = preload("res://scripts/presentation/vehicle_audio_director.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")
const LayoutGenerator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

var failures: Array[String] = []
var confirmed_count := 0


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS %s" % message)
	else:
		failures.append(message)
		print("FAIL %s" % message)


func _validate_reward_runtime() -> void:
	var rewards := RewardRuntime.new()
	_expect(rewards.is_idle(), "reward runtime starts without an active transaction")
	_expect(rewards.enqueue(&"boss"), "reward runtime accepts a pending source")
	_expect(not rewards.enqueue(&"boss"), "reward runtime suppresses duplicate pending sources")
	_expect(rewards.pop_pending() == &"boss", "reward queue preserves its source identity")
	_expect(not rewards.has_pending(), "popping the only source empties the reward queue")

	_expect(rewards.begin(&"stage_1", &"boss") == 0, "first mandatory reward offer uses serial zero")
	_expect(not rewards.enqueue(&"boss"), "active reward sources cannot be queued again")
	_expect(rewards.begin(&"stage_1", &"field_boss") == -1, "an active offer cannot be replaced or rerolled")
	_expect(rewards.claim(&"stage_1") == &"boss", "claim resolves the active reward")
	_expect(rewards.claim(&"stage_1").is_empty(), "one reward transaction can be claimed exactly once")
	_expect(rewards.has_claimed(&"stage_1", &"boss"), "claimed rewards retain a stage-scoped terminal outcome")
	_expect(rewards.outcome(&"stage_1", &"boss") == &"claimed", "claimed is the only terminal reward outcome")
	_expect(rewards.begin(&"stage_1", &"boss") == -1, "resolved rewards cannot reopen")

	_expect(rewards.begin(&"stage_1", &"field_boss") == 1, "offer serials advance across mandatory reward sources")
	_expect(rewards.claim(&"stage_1") == &"field_boss", "every authored reward completes through claim")
	_expect(
		rewards.outcome(&"stage_1", &"field_boss") == &"claimed"
			and rewards.has_claimed(&"stage_1", &"field_boss"),
		"authored rewards have one claimed terminal outcome"
	)
	_expect(rewards.enqueue(&"queued_reward"), "stage reset fixture queues a reward")
	rewards.reset_stage()
	_expect(
		rewards.is_idle() and not rewards.has_pending(),
		"stage reset clears active and pending reward state"
	)
	_expect(
		rewards.has_claimed(&"stage_1", &"boss")
			and rewards.has_claimed(&"stage_1", &"field_boss"),
		"stage reset preserves run-scoped terminal outcomes"
	)
	_expect(rewards.begin(&"stage_2", &"boss") == 2, "stage reset preserves the offer serial")
	rewards.reset_stage()
	_expect(rewards.begin(&"stage_3", &"boss") == 3, "stage reset clears an active transaction")

	rewards.reset_run()
	_expect(
		rewards.is_idle()
			and not rewards.has_pending()
			and not rewards.has_claimed(&"stage_1", &"boss"),
		"run reset clears all reward transaction state"
	)
	_expect(
		rewards.begin(&"stage_1", RewardRuntime.LEVEL_UP_SOURCE) == 0,
		"run reset restarts the deterministic offer serial"
	)
	_expect(rewards.claim(&"stage_1") == RewardRuntime.LEVEL_UP_SOURCE, "level-up reward completes through claim")
	_expect(rewards.claim(&"stage_1").is_empty(), "level-up reward also claims exactly once")
	_expect(
		not rewards.is_resolved(&"stage_1", RewardRuntime.LEVEL_UP_SOURCE),
		"level-up transactions do not create stage terminal outcomes"
	)


func _run() -> void:
	_validate_reward_runtime()
	var layout := LayoutGenerator.generate(0xC4A2B0, StageCatalog.STAGE_IDS)
	for stage_id in StageCatalog.STAGE_IDS:
		var stage_pickups := layout.pickup_blueprint(stage_id)
		_expect(stage_pickups.size() == 14, "%s has ten repairs and four experience recalls" % stage_id)
		_expect(stage_pickups.filter(func(item: Dictionary) -> bool: return StringName(item["kind"]) == &"repair").size() == 10, "%s pickup set contains exactly ten repairs" % stage_id)
		_expect(stage_pickups.filter(func(item: Dictionary) -> bool: return StringName(item["kind"]) == &"experience_recall").size() == 4, "%s pickup set contains exactly four experience recalls" % stage_id)
	var kinds: Dictionary = {}
	for item in layout.pickup_blueprint(&"stage_1"):
		kinds[StringName(item["kind"])] = true
	for required_kind in [&"repair", &"experience_recall"]:
		_expect(kinds.has(required_kind), "field catalog exposes %s" % required_kind)
	_expect(kinds.size() == 2, "field item contract exposes exactly two families")

	var panel := UpgradePanel.new()
	root.add_child(panel)
	var cards: Array[Dictionary] = []
	for index in 3:
		cards.append({
			"id":StringName("card_%d" % index),
			"title_key":"UPGRADE_CHASSIS_SPEED_TITLE",
			"description_key":"UPGRADE_CHASSIS_SPEED_DESC",
			"category_key":"UPGRADE_CATEGORY_CHASSIS",
			"category":&"chassis",
			"current_level":0,
			"next_level":1,
			"max_level":3,
			"effect_rows":[{
				"stat_key":"UPGRADE_STAT_MOVE_SPEED_MULTIPLIER",
				"operation":"multiply",
				"current":1.0,
				"next":1.08,
			}],
			"change_kind":&"stats",
			"change_label_key":"",
			"artwork_asset_id":&"upgrade/mobility_thruster",
		})
	panel.confirmed.connect(func(_id: StringName) -> void: confirmed_count += 1)
	panel.open(cards)
	var choice_contract := panel.debug_contract()
	_expect(bool(choice_contract["structured_cards"]), "upgrade offers render through structured card components")
	var card_contracts_valid := true
	for card_variant in Array(choice_contract["cards"]):
		var card := Dictionary(card_variant)
		card_contracts_valid = (
			card_contracts_valid
			and int(card["effect_rows"]) == 1
			and bool(card["level_visible"])
			and int(card["value_rows"]) >= 2
			and not bool(card["dossier_split"])
			and not bool(card["vertical_dossier"])
			and not bool(card["footer_visible"])
			and bool(card["description_visible"])
			and int(card["summary_max_lines"]) == 1
			and int(card["body_divider_count"]) == 0
			and int(card["pip_slots"]) == 0
			and int(card["stage_pip_count"]) == 0
			and bool(card["mouse_passthrough"])
		)
	_expect(
		card_contracts_valid,
		"every offer row exposes a one-line summary, one numeric delta, no stage pips, and parent-owned pointer input"
	)
	_expect((panel.get("_confirm") as Button).disabled, "upgrade confirm begins disabled")
	panel.call("_process", 0.36)
	panel.call("_select", 0)
	_expect(not (panel.get("_confirm") as Button).disabled, "selection enables explicit confirm")
	_expect(confirmed_count == 0, "selection alone never applies an upgrade")
	panel.call("_confirm_selected")
	panel.call("_confirm_selected")
	_expect(confirmed_count == 1, "duplicate confirmation emits once")
	panel.open(cards.slice(0, 2))
	panel.call("_process", 0.36)
	panel.call("_select", 2)
	_expect(
		int(panel.debug_contract()["visible_card_count"]) == 2
			and int(panel.debug_contract()["selected_index"]) == -1,
		"two-card tail centers only visible cards and rejects a hidden third shortcut"
	)
	panel.open(cards.slice(0, 1))
	_expect(
		int(panel.debug_contract()["visible_card_count"]) == 1,
		"one-card tail exposes one mandatory visible choice"
	)
	panel.free()

	var audio := AudioDirector.new()
	root.add_child(audio)
	await process_frame
	_expect(audio.has_all_required(), "all twelve stored WAV streams load")
	_expect(AudioDirector.FILES.size() == 12, "audio contract contains exactly twelve stored sounds")
	audio.shutdown()
	audio.free()

	var stage := StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	stage.set("player_health", 20.0)
	stage.call("_collect_pickup", {"active": true, "kind": &"repair", "pos": Vector2.ZERO, "heal_amount": 70.0})
	_expect(is_equal_approx(float(stage.get("player_health")), 90.0), "repair restores its doubled authored hull amount")
	stage.call("_collect_pickup", {"active": true, "kind": &"experience_recall", "pos": Vector2.ZERO})
	_expect(float(stage.get("experience_recall_timer")) >= 0.65, "experience recall starts the global shard pull window")
	var experience_runtime: RefCounted = stage.get("experience_runtime")
	_expect(int(experience_runtime.call("required_experience")) == 6, "a fresh run starts with a 6-XP level threshold")
	var recall_start := Vector2(stage.get("player_position"))
	experience_runtime.call("spawn_shard", recall_start + Vector2(900.0, 0.0), 2)
	for recall_frame in 40:
		if recall_frame == 10:
			stage.set("player_position", recall_start + Vector2(240.0, -90.0))
		elif recall_frame == 26:
			stage.set("player_position", recall_start + Vector2(420.0, 110.0))
		stage.call("_update_experience", 1.0 / 60.0)
	var recall_snapshot: Dictionary = experience_runtime.call("snapshot")
	_expect(
		int(recall_snapshot["shard_count"]) == 0
			and int(recall_snapshot["experience"]) == 2,
		"stage recall collects at the ship's current position after dash-like movement"
	)
	var stage_ui: CanvasLayer = stage.get("_ui")
	stage_ui.call("show_deployment", &"pulse_cannon")
	var ui_contract: Dictionary = stage_ui.call("debug_ui_contract", 1280.0)
	_expect(
		Vector2(ui_contract["action_rail_size"]) == Vector2.ZERO
			and int(ui_contract["action_slot_count"]) == 3
			and not bool(ui_contract["shows_primary_slot"])
			and Vector2(ui_contract["status_cluster_size"]) == Vector2(246.0, 40.0)
			and int(ui_contract["status_cluster_background_geometry_count"]) == 0,
		"top-left panel-free cluster owns Dash, Seeker, and the active weapon without a bottom rail"
	)
	_expect(
		Vector2(ui_contract["health_cluster_size"]) == Vector2(1280.0, 54.0)
			and bool(ui_contract["health_panel_free"])
			and bool(ui_contract["status_cluster_panel_free"])
			and is_equal_approx(float(ui_contract["meter_gap"]), 0.0)
			and bool(Dictionary(ui_contract["health_meter"])["has_experience_geometry"])
			and int(ui_contract["live_upgrade_icon_count"]) == 0
			and not bool(ui_contract["has_live_upgrade_rail"])
			and not bool(ui_contract["edge_boss_health_visible"])
			and not bool(ui_contract["edge_target_health_visible"]),
		"full-width HP/EXP and semantic status items are panel-free with no live build rail or duplicated edge health"
	)
	_expect(bool(ui_contract["top_clusters_do_not_overlap"]), "top HUD clusters do not overlap at 1280 pixels")
	_expect(not bool(ui_contract["deployment_has_difficulty_ui"]), "deployment exposes no difficulty choice")
	_expect(int(ui_contract["deployment_control_rows"]) == 4, "deployment preserves four complete control rows")
	var settings_contract: Dictionary = stage_ui.call("debug_gameplay_settings_contract")
	_expect(int(settings_contract["difficulty_controls"]) == 0, "in-run settings expose no difficulty selector")
	_expect(not bool(settings_contract["difficulty_copy_visible"]), "in-run settings contain no obsolete difficulty copy")
	_expect(
		not stage_ui.has_method("debug_status_orbit_contract"),
		"persistent status orbit and its debug compatibility surface are removed"
	)
	stage_ui.call("clear_notifications")
	for message in ["first", "second", "third", "fourth", "fifth", "sixth", "seventh"]:
		stage_ui.call("notify", message, 2.4, Color.WHITE)
	var notification_contract := Dictionary(stage_ui.call("debug_notification_contract"))
	_expect(
		bool(notification_contract["active"])
			and String(notification_contract["active_message"]) == "first"
			and int(notification_contract["queue_cap"]) == 5
			and int(notification_contract["queue_size"]) == 5
			and Array(notification_contract["queued_messages"]) == [
				"third", "fourth", "fifth", "sixth", "seventh",
			]
			and StringName(notification_contract["surface_variation"])
				== &"ToastSurface"
			and bool(notification_contract["input_passthrough"]),
		"notification queue preserves order and cap on one input-transparent Toast surface"
	)
	stage_ui.call("clear_notifications")
	experience_runtime.set("pending_level_ups", 1)
	var stage_rewards: RefCounted = stage.get("reward_runtime")
	stage_rewards.call("enqueue", &"boss")
	stage.set("mode", VehicleRun.RunMode.PLAYING)
	stage.call("_advance_reward_queue")
	_expect(
		StringName(stage_rewards.call("current_source")) == RewardRuntime.LEVEL_UP_SOURCE
			and bool(stage_rewards.call("has_pending")),
		"level-up rewards take priority over queued authored rewards"
	)
	stage.call("_resolve_reward_transaction")
	stage.set("mode", VehicleRun.RunMode.PLAYING)
	stage.call("_advance_reward_queue")
	_expect(
		StringName(stage_rewards.call("current_source")) == &"boss",
		"the authored reward opens after pending level-ups resolve"
	)
	stage.call("_resolve_reward_transaction")
	experience_runtime = null
	stage_rewards = null
	stage_ui = null
	stage.queue_free()
	stage = null
	audio = null
	panel = null
	await process_frame
	await process_frame
	if failures.is_empty():
		print("VEHICLE_REWARDS_UI_AUDIO_VALIDATION_OK")
		quit(0)
	else:
		push_error("Vehicle reward/UI/audio validation failed: %s" % [failures])
		quit(1)
