extends SceneTree

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const RewardRuntime = preload("res://scripts/rewards/vehicle_reward_runtime.gd")
const VehicleRun = preload("res://scripts/vehicle/vehicle_run.gd")
const UpgradePanel = preload("res://scripts/ui/vehicle_upgrade_choice_panel.gd")
const AudioDirector = preload("res://scripts/presentation/vehicle_audio_director.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
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

	_expect(rewards.begin(&"stage_1", &"boss", false) == 0, "first reward offer uses serial zero")
	_expect(not rewards.enqueue(&"boss"), "active reward sources cannot be queued again")
	_expect(rewards.claim(&"stage_1") == &"boss", "claim resolves the active reward")
	_expect(rewards.has_claimed(&"stage_1", &"boss"), "claimed rewards retain a stage-scoped terminal outcome")
	_expect(rewards.begin(&"stage_1", &"boss", false) == -1, "resolved rewards cannot reopen")

	_expect(rewards.begin(&"stage_1", &"field_boss", true) == 1, "offer serials advance across reward sources")
	_expect(rewards.decline(&"stage_1"), "optional rewards can be declined")
	_expect(
		rewards.outcome(&"stage_1", &"field_boss") == &"declined"
			and not rewards.has_claimed(&"stage_1", &"field_boss"),
		"declined and claimed outcomes remain distinct"
	)
	_expect(rewards.enqueue(&"queued_reward"), "stage reset fixture queues a reward")
	rewards.reset_stage()
	_expect(
		rewards.is_idle() and not rewards.has_pending(),
		"stage reset clears active and pending reward state"
	)
	_expect(
		rewards.has_claimed(&"stage_1", &"boss"),
		"stage reset preserves run-scoped terminal outcomes"
	)
	_expect(rewards.begin(&"stage_2", &"boss", false) == 2, "stage reset preserves the offer serial")
	rewards.reset_stage()
	_expect(rewards.begin(&"stage_3", &"boss", false) == 3, "stage reset clears an active transaction")

	rewards.reset_run()
	_expect(
		rewards.is_idle()
			and not rewards.has_pending()
			and not rewards.has_claimed(&"stage_1", &"boss"),
		"run reset clears all reward transaction state"
	)
	_expect(
		rewards.begin(&"stage_1", RewardRuntime.LEVEL_UP_SOURCE, false) == 0,
		"run reset restarts the deterministic offer serial"
	)
	rewards.claim(&"stage_1")
	_expect(
		not rewards.is_resolved(&"stage_1", RewardRuntime.LEVEL_UP_SOURCE),
		"level-up transactions do not create stage terminal outcomes"
	)


func _run() -> void:
	_validate_reward_runtime()
	var layout := LayoutGenerator.generate(0xC4A2B0, StageCatalog.STAGE_IDS)
	for stage_id in StageCatalog.STAGE_IDS:
		var stage_pickups := layout.pickup_blueprint(stage_id)
		var stage_crates := layout.crate_blueprint(stage_id)
		_expect(stage_pickups.size() == 6, "%s has four repairs and two experience recalls" % stage_id)
		_expect(layout.crate_blueprint(stage_id).size() == 8, "%s has eight authored crates" % stage_id)
		_expect(stage_pickups.filter(func(item: Dictionary) -> bool: return StringName(item["kind"]) == &"repair").size() == 4, "%s pickup set contains exactly four repairs" % stage_id)
		_expect(stage_pickups.filter(func(item: Dictionary) -> bool: return StringName(item["kind"]) == &"experience_recall").size() == 2, "%s pickup set contains exactly two experience recalls" % stage_id)
		_expect(stage_crates.filter(func(item: Dictionary) -> bool: return StringName(item["drop"]) == &"repair").size() == 6, "%s crate set contains exactly six repairs" % stage_id)
		_expect(stage_crates.filter(func(item: Dictionary) -> bool: return StringName(item["drop"]) == &"experience_recall").size() == 2, "%s crate set contains exactly two experience recalls" % stage_id)
	var kinds: Dictionary = {}
	for item in layout.pickup_blueprint(&"stage_1"):
		kinds[StringName(item["kind"])] = true
	for crate in layout.crate_blueprint(&"stage_1"):
		kinds[StringName(crate["drop"])] = true
	for required_kind in [&"repair", &"experience_recall"]:
		_expect(kinds.has(required_kind), "field catalog exposes %s" % required_kind)
	_expect(kinds.size() == 2, "field item contract exposes exactly two families")

	var panel := UpgradePanel.new()
	root.add_child(panel)
	var cards: Array[Dictionary] = []
	for index in 3:
		cards.append({
			"id":StringName("card_%d" % index),
			"title_key":"UPGRADE_KINETIC_ROUNDS_TITLE",
			"summary_key":"UPGRADE_KINETIC_ROUNDS_DESC",
			"family_key":"UPGRADE_FAMILY_PRIMARY",
			"family":&"primary",
			"current_level":0,
			"next_level":1,
			"max_level":3,
			"effect_rows":[{
				"stat_key":"UPGRADE_STAT_PRIMARY_DAMAGE_MULTIPLIER",
				"operation":"multiply",
				"current":1.0,
				"next":1.15,
			}],
			"behavior_change_key":"",
		})
	panel.confirmed.connect(func(_id: StringName) -> void: confirmed_count += 1)
	panel.open(cards, false)
	var choice_contract := panel.debug_contract()
	_expect(bool(choice_contract["structured_cards"]), "upgrade offers render through structured card components")
	var card_contracts_valid := true
	for card_variant in Array(choice_contract["cards"]):
		var card := Dictionary(card_variant)
		card_contracts_valid = (
			card_contracts_valid
			and int(card["value_rows"]) == 1
			and int(card["pip_slots"]) == 3
			and bool(card["mouse_passthrough"])
		)
	_expect(
		card_contracts_valid,
		"every card exposes one numeric delta, three pips, and parent-owned pointer input"
	)
	_expect((panel.get("_confirm") as Button).disabled, "upgrade confirm begins disabled")
	panel.call("_process", 0.36)
	panel.call("_select", 0)
	_expect(not (panel.get("_confirm") as Button).disabled, "selection enables explicit confirm")
	_expect(confirmed_count == 0, "selection alone never applies an upgrade")
	panel.call("_confirm_selected")
	panel.call("_confirm_selected")
	_expect(confirmed_count == 1, "duplicate confirmation emits once")
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
	stage.call("_collect_pickup", {"active": true, "kind": &"repair", "pos": Vector2.ZERO, "heal_amount": 35.0})
	_expect(is_equal_approx(float(stage.get("player_health")), 55.0), "repair restores its authored hull amount")
	stage.call("_collect_pickup", {"active": true, "kind": &"experience_recall", "pos": Vector2.ZERO})
	_expect(float(stage.get("experience_recall_timer")) >= 0.65, "experience recall starts the global shard pull window")
	var experience_runtime: RefCounted = stage.get("experience_runtime")
	_expect(int(experience_runtime.call("required_experience")) == 12, "a fresh run starts with a 12-XP level threshold")
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
	stage_ui.call("show_deployment", &"pulse_cannon", RunDifficulty.HARD)
	var ui_contract: Dictionary = stage_ui.call("debug_ui_contract", 1280.0)
	_expect(Vector2(ui_contract["action_rail_size"]) == Vector2(148.0, 44.0), "action rail uses the bottom-center auxiliary-action contract")
	_expect(Vector2(ui_contract["health_cluster_size"]) == Vector2(216.0, 74.0), "health and XP share the readable hull cluster")
	_expect(bool(ui_contract["top_clusters_do_not_overlap"]), "top HUD clusters do not overlap at 1280 pixels")
	_expect(int(ui_contract["deployment_difficulty_choices"]) == 3, "deployment exposes exactly three difficulty choices")
	_expect(float(ui_contract["deployment_difficulty_min_height"]) >= 44.0, "difficulty choices meet the minimum interaction height")
	_expect(StringName(ui_contract["deployment_difficulty"]) == RunDifficulty.HARD, "deployment renders Hard as the selected baseline")
	var settings_contract: Dictionary = stage_ui.call("debug_gameplay_settings_contract")
	_expect(int(settings_contract["difficulty_controls"]) == 0, "in-run settings expose no difficulty selector")
	_expect(bool(settings_contract["difficulty_lock_visible"]), "in-run settings explain the deployment lock")
	var orbit_contract: Dictionary = stage_ui.call("debug_status_orbit_contract")
	_expect(int(orbit_contract["maximum_badges"]) == 2, "status orbit exposes only the two retained cycle badges")
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
