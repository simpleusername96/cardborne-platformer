extends SceneTree

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const UpgradePanel = preload("res://scripts/ui/vehicle_upgrade_choice_panel.gd")
const AudioDirector = preload("res://scripts/presentation/vehicle_audio_director.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")

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


func _run() -> void:
	for stage_id in StageCatalog.STAGE_IDS:
		var stage_pickups := StageCatalog.pickup_blueprint(stage_id)
		var stage_crates := StageCatalog.crate_blueprint(stage_id)
		_expect(stage_pickups.size() == 3, "%s has two repairs and one experience recall" % stage_id)
		_expect(StageCatalog.crate_blueprint(stage_id).size() == 5, "%s has five authored crates" % stage_id)
		_expect(StageCatalog.reward_anchors(stage_id).size() == 4, "%s has four reward anchors" % stage_id)
		_expect(stage_pickups.filter(func(item: Dictionary) -> bool: return StringName(item["kind"]) == &"repair").size() == 2, "%s pickup set contains exactly two repairs" % stage_id)
		_expect(stage_pickups.filter(func(item: Dictionary) -> bool: return StringName(item["kind"]) == &"experience_recall").size() == 1, "%s pickup set contains exactly one experience recall" % stage_id)
		_expect(stage_crates.filter(func(item: Dictionary) -> bool: return StringName(item["drop"]) == &"repair").size() == 4, "%s crate set contains exactly four repairs" % stage_id)
		_expect(stage_crates.filter(func(item: Dictionary) -> bool: return StringName(item["drop"]) == &"experience_recall").size() == 1, "%s crate set contains exactly one experience recall" % stage_id)
	var kinds: Dictionary = {}
	for item in StageCatalog.pickup_blueprint(&"flooded_works"):
		kinds[StringName(item["kind"])] = true
	for crate in StageCatalog.crate_blueprint(&"flooded_works"):
		kinds[StringName(crate["drop"])] = true
	for required_kind in [&"repair", &"experience_recall"]:
		_expect(kinds.has(required_kind), "field catalog exposes %s" % required_kind)
	_expect(kinds.size() == 2, "field item contract exposes exactly two families")

	var panel := UpgradePanel.new()
	root.add_child(panel)
	var cards: Array[Dictionary] = []
	for index in 3:
		cards.append({"id": StringName("card_%d" % index), "title_key": "UPGRADE_KINETIC_ROUNDS_TITLE", "description_key": "UPGRADE_KINETIC_ROUNDS_DESC", "family_key": "UPGRADE_FAMILY_PRIMARY", "current_level": 0, "next_level": 1, "max_level": 3})
	panel.confirmed.connect(func(_id: StringName) -> void: confirmed_count += 1)
	panel.open(cards, false)
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
	_expect(audio.has_all_required(), "all thirteen stored WAV streams load")
	_expect(AudioDirector.FILES.size() == 13, "audio contract contains exactly thirteen stored sounds")
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
	_expect(int(experience_runtime.call("required_experience")) == 26, "a fresh run starts with a 26-XP level threshold")
	var stage_ui: CanvasLayer = stage.get("_ui")
	var ui_contract: Dictionary = stage_ui.call("debug_ui_contract", 1280.0)
	_expect(Vector2(ui_contract["action_rail_size"]) == Vector2(276.0, 60.0), "action rail uses the compact dock contract")
	_expect(Vector2(ui_contract["health_cluster_size"]) == Vector2(184.0, 54.0), "health and XP share the compact hull cluster")
	_expect(bool(ui_contract["top_clusters_do_not_overlap"]), "top HUD clusters do not overlap at 1280 pixels")
	var orbit_contract: Dictionary = stage_ui.call("debug_status_orbit_contract")
	_expect(int(orbit_contract["maximum_badges"]) == 3, "status orbit exposes at most three badges")
	stage.free()
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
