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
		_expect(StageCatalog.pickup_blueprint(stage_id).size() == 8, "%s has eight authored pickups" % stage_id)
		_expect(StageCatalog.crate_blueprint(stage_id).size() == 5, "%s has five authored crates" % stage_id)
		_expect(StageCatalog.reward_anchors(stage_id).size() == 4, "%s has four reward anchors" % stage_id)
	var kinds: Dictionary = {}
	for item in StageCatalog.pickup_blueprint(&"flooded_works"):
		kinds[StringName(item["kind"])] = true
	for crate in StageCatalog.crate_blueprint(&"flooded_works"):
		kinds[StringName(crate["drop"])] = true
	for required_kind in [&"repair", &"attack_boost", &"coolant", &"overdrive", &"barrier", &"seeker_battery", &"capacitor_cell", &"magnet_field"]:
		_expect(kinds.has(required_kind), "field catalog exposes %s" % required_kind)
	kinds[&"major_repair"] = true # Field-boss-only reward, intentionally absent from loose placement.
	_expect(kinds.size() == 9, "field item contract exposes exactly nine families")

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
	var major_repair: Dictionary = stage.debug_pickup_contract(&"major_repair")
	_expect(float(major_repair["health"]) >= 100.0, "major repair restores its field-boss health grant")
	_expect(float(stage.debug_pickup_contract(&"coolant")["coolant_timer"]) >= 8.0, "coolant grants its firing cadence window")
	_expect(bool(stage.debug_pickup_contract(&"seeker_battery")["passive_reset"]), "seeker battery resets the passive cooldown")
	_expect(int(stage.debug_pickup_contract(&"capacitor_cell")["capacitor_shots"]) == 3, "capacitor cell grants three opening shots")
	_expect(float(stage.debug_pickup_contract(&"magnet_field")["magnet_timer"]) >= 10.0, "magnet field grants its collection window")
	var route: Dictionary = stage.debug_multistage_contract()
	_expect(int(route["final_upgrade_count"]) == 9, "full route grants nine mandatory upgrades")
	_expect(int(route["claimed_reward_count"]) == 9, "full route resolves nine mandatory reward transactions")
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
