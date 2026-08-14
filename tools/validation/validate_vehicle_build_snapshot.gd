extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const Builder = preload("res://scripts/cards/vehicle_build_snapshot_builder.gd")
const SummaryPanel = preload("res://scripts/ui/vehicle_build_summary_panel.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := Catalog.new()
	var build := RunBuild.new(catalog)
	_expect(bool(build.apply(&"chassis_speed").get("applied", false)), "fixture upgrade applies")
	var stats: Array[Dictionary] = [
		{"id":&"speed", "label_key":"SHIP_STAT_SPEED", "value":build.stat(&"move_speed_multiplier", 280.0), "decimals":0, "unit_key":"SHIP_UNIT_PX_S"},
	]
	var snapshot := Builder.build(
		build,
		catalog,
		stats,
		[{"id":&"seeker", "level":1, "name_key":"SECONDARY_HOMING_MISSILES_NAME"}],
		{
			"health":100.0, "max_health":120.0, "level":2,
			"experience":4, "experience_required":8,
			"experience_complete":false,
		}
	)
	_expect(bool(snapshot["active"]), "build snapshot is explicitly active")
	_expect(snapshot["stats"].size() == 1, "effective stats are preserved")
	_expect(snapshot["upgrades"].size() == 1, "acquired upgrade appears once")
	_expect(Array(snapshot["categories"]).size() == 6, "snapshot freezes all six category groups")
	var capacities: Array[int] = []
	for category_variant in Array(snapshot["categories"]):
		capacities.append(int(Dictionary(category_variant)["capacity"]))
	_expect(capacities == [2, 5, 2, 3, 5, 4], "snapshot keeps locked category capacities")
	var chassis_category := Dictionary(Array(snapshot["categories"])[4])
	var chassis_slots: Array = chassis_category["slots"]
	_expect(
		StringName(Dictionary(chassis_slots[0])["slot_key"]) == &"slot_0"
			and StringName(Dictionary(chassis_slots[0])["record"].get("id", &"")) == &"chassis_speed",
		"snapshot packs the first acquired category card into its leftmost position"
	)
	var optional_build := RunBuild.new(catalog)
	optional_build.apply(&"orbiting_blades")
	optional_build.apply(&"electric_field")
	optional_build.apply(&"orbiting_blades")
	var optional_snapshot := Builder.build(optional_build, catalog, [], [], {})
	var secondary_slots: Array = Dictionary(Array(optional_snapshot["categories"])[1])["slots"]
	_expect(
		StringName(Dictionary(secondary_slots[0])["record"].get("id", &"")) == &"orbiting_blades"
			and StringName(Dictionary(secondary_slots[1])["record"].get("id", &"")) == &"electric_field"
			and Array(optional_snapshot["upgrades"]).size() == 2,
		"optional-secondary acquisition order packs from the left and flat projection remains unique"
	)
	var upgrade := Dictionary(snapshot["upgrades"][0])
	_expect(StringName(upgrade["id"]) == &"chassis_speed", "upgrade uses stable ID")
	_expect(
		StringName(upgrade["artwork_asset_id"]) != &"",
		"live build receipt includes semantic upgrade artwork"
	)
	_expect(int(upgrade["level"]) == 1 and int(upgrade["max_level"]) >= 1, "upgrade level and maximum are present")
	var original_value := float(snapshot["stats"][0]["value"])
	stats[0]["value"] = 1.0
	_expect(is_equal_approx(float(snapshot["stats"][0]["value"]), original_value), "snapshot does not alias gameplay input")
	var panel := SummaryPanel.new()
	get_root().add_child(panel)
	await process_frame
	var original_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	await process_frame
	panel.set_snapshot(snapshot)
	var active_contract := panel.debug_contract()
	_expect(int(active_contract["stat_groups"]) == 3, "active build uses three stable stat groups")
	_expect(int(active_contract["rendered_stats"]) == 1, "every supplied stat renders exactly once")
	_expect(bool(active_contract["summary_visible"]), "active build exposes the level, hull, and XP summary")
	_expect(
		String(active_contract["summary_level_text"]).begins_with("레벨")
			and String(active_contract["first_group_title"]).begins_with("기체"),
		"active build renders Korean summary and group copy"
	)
	TranslationServer.set_locale("en")
	await process_frame
	panel.set_snapshot(snapshot)
	var english_contract := panel.debug_contract()
	_expect(
		String(english_contract["summary_level_text"]).begins_with("Level")
			and String(english_contract["first_group_title"]).begins_with("Hull"),
		"active build refreshes dynamic and static copy in English"
	)
	var max_snapshot := snapshot.duplicate(true)
	max_snapshot["run_state"]["experience_complete"] = true
	panel.set_snapshot(max_snapshot)
	_expect(
		String(panel.debug_contract()["summary_xp_text"]) == "XP MAX",
		"paused Ship Status shares the explicit progression-complete state"
	)
	panel.set_snapshot({})
	var empty_contract := panel.debug_contract()
	_expect(bool(empty_contract["empty_only"]), "no-run build exposes one empty state without stale groups")
	_expect(int(empty_contract["rendered_stats"]) == 0, "no-run build retains no rendered stat rows")
	TranslationServer.set_locale(original_locale)
	panel.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_BUILD_SNAPSHOT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
