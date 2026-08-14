extends SceneTree

const Builder = preload("res://scripts/combat/vehicle_stage_report_builder.gd")
const ResultBuilder = preload("res://scripts/combat/vehicle_run_result_builder.gd")
const ReportPanel = preload("res://scripts/ui/vehicle_stage_report_panel.gd")
const ResultPanel = preload("res://scripts/ui/vehicle_result_panel.gd")
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const BuildSnapshotBuilder = preload("res://scripts/cards/vehicle_build_snapshot_builder.gd")

var _failures: Array[String] = []


func _init() -> void:
	var telemetry := {
		"outgoing":{
			&"primary":41.0,
			&"seeker":17.0,
			&"emp":9.0,
		},
		"attributes":{
			&"kinetic":58.0,
			&"arc":9.0,
		},
		"status_applications":{&"chill":3},
		"incoming":{&"projectile":20.0, &"contact":5.0},
		"defeats":{&"scrap_drone":12, &"needle_drone":4},
		"elites":{&"needle_drone:armored":1},
		"last_incoming_source":&"projectile",
		"last_incoming_damage":7.0,
	}
	var report := Builder.build(
		telemetry,
		{
			"number":2,
			"title_key":"STAGE_DROWNED_RUINS_2",
			"has_next_stage":true,
			"run_time_seconds":183.0,
			"hull":72.0,
			"max_hull":120.0,
		}
	)
	var percentage_total := 0
	for row in report["outgoing"]:
		percentage_total += int(row["percentage_tenths"])
	_expect(percentage_total == 1000, "largest-remainder percentages sum to exactly 100.0 percent")
	_expect(
		is_equal_approx(float(report["total_outgoing"]), 67.0),
		"report exposes exact total applied outgoing damage"
	)
	_expect(
		is_equal_approx(float(report["total_outgoing"]), float(report["total_attributes"])),
		"source and attribute totals are identical partitions"
	)
	_expect(
		report["attributes"].size() == 3,
		"attribute report preserves two damage rows and control-only cryo"
	)
	_expect(report["defeats"].size() == 2, "defeat rows preserve base archetypes")
	_expect(
		int(report["defeats"][1]["elite_count"]) == 1,
		"elite count is nested under the defeated base archetype"
	)
	_expect(
		is_equal_approx(float(report["run_time_seconds"]), 183.0)
			and is_equal_approx(float(report["hull"]), 72.0),
		"report freezes total run time and remaining hull"
	)
	_expect(report["incoming"].size() == 2, "incoming recap is bounded and present")
	var failure_telemetry := telemetry.duplicate(true)
	failure_telemetry["incoming"] = {
		&"boss":50.0,
		&"projectile":20.0,
		&"contact":4.0,
		&"denial":3.0,
		&"environment":2.0,
	}
	var failure_report := Builder.build(
		failure_telemetry,
		{
			"number":2,
			"title_key":"STAGE_DROWNED_RUINS_2",
			"has_next_stage":false,
			"run_time_seconds":183.0,
			"hull":0.0,
			"max_hull":120.0,
		},
		true
	)
	_expect(failure_report["incoming"].size() == 3, "failure recap is bounded to the top three incoming rows")
	_expect(StringName(failure_report["incoming"][-1]["id"]) == &"other", "remaining incoming sources collapse into Other")
	_expect(StringName(failure_report["last_incoming_source"]) == &"projectile", "failure recap preserves the last-hit source")
	_expect(is_equal_approx(float(failure_report["last_incoming_damage"]), 7.0), "failure recap preserves exact last-hit damage")
	var crowded := {}
	for index in 12:
		crowded[StringName("source_%02d" % index)] = float(index + 1)
	var crowded_report := Builder.build(
		{"outgoing":crowded},
		{"number":1, "title_key":"STAGE_DROWNED_RUINS_1", "has_next_stage":true}
	)
	_expect(crowded_report["outgoing"].size() == 8, "more than eight sources collapse to seven plus Other")
	_expect(StringName(crowded_report["outgoing"][-1]["id"]) == &"other", "collapsed row uses stable Other ID")
	var panel := ReportPanel.new()
	get_root().add_child(panel)
	await process_frame
	var continued := [0]
	panel.continued.connect(func() -> void: continued[0] += 1)
	panel.open(report)
	var contract := panel.debug_contract()
	_expect(is_equal_approx(float(contract["guard"]), 0.35), "report blocks carried input for 0.35 seconds")
	_expect(int(contract["defeats"]) == 2, "panel receives frozen defeat rows")
	_expect(int(contract["attributes"]) == 3, "panel receives all attribute rows")
	_expect(Vector2(contract["continue_size"]) == Vector2(300.0, 48.0), "report continuation uses one compact primary action")
	_expect(int(contract["wide_dividers"]) == 2, "wide report keeps two restrained column dividers")
	_expect(int(contract["wide_columns"]) == 3, "wide report preserves three independently scrollable columns")
	_expect(int(contract["compact_tabs"]) == 3, "compact report preserves three category tabs")
	_expect(int(contract["scroll_views"]) == 7, "report owns one body scroll plus three wide and three compact metric views")
	_expect(int(contract["shared_text_rows"]) > 0, "report metrics use shared TextRows")
	_expect(int(contract["decorated_metric_rows"]) == 0, "report metrics have no decorative panel shell")
	_expect(int(contract["semantic_icons"]) > 0, "report preserves semantic enemy and affinity icons")
	_expect(not bool(contract["incoming_visible"]), "successful report omits the failure-only incoming section")
	_expect(int(contract["fixed_actions"]) == 1, "report exposes exactly one fixed action")
	_expect("03:03" in String(contract["summary_text"]), "report formats cumulative run time")
	panel.call("_process", 0.36)
	panel.call("_on_continue")
	_expect(continued[0] == 1, "successful report emits its single continue intent")
	panel.open(failure_report)
	await process_frame
	contract = panel.debug_contract()
	_expect(bool(contract["incoming_visible"]), "failure report reveals incoming damage")
	_expect(int(contract["incoming_rows"]) == 3, "failure report renders the bounded top-three recap")
	_expect(bool(contract["last_hit_present"]), "failure report renders the last-hit recap")
	_expect(int(contract["fixed_actions"]) == 1, "failure report keeps one fixed action")
	panel.call("_process", 0.36)
	panel.call("_on_continue")
	_expect(continued[0] == 2, "failure report emits the same single lifecycle intent")
	panel.queue_free()

	var result := ResultPanel.new()
	get_root().add_child(result)
	await process_frame
	var deployment_requested := [0]
	result.deployment_requested.connect(func() -> void: deployment_requested[0] += 1)
	var final_records: Array = []
	for stage_index in 5:
		var stage_record := report.duplicate(true)
		stage_record["stage_number"] = stage_index + 1
		stage_record["has_next_stage"] = stage_index < 4
		final_records.append(stage_record)
	var result_catalog := UpgradeCatalog.new()
	var result_build := RunBuild.new(result_catalog)
	for upgrade_id in [&"pickup_radius", &"thermal_burst", &"homing_missiles"]:
		result_build.apply(upgrade_id)
	var final_result := ResultBuilder.build(final_records, {
		"active_run_elapsed_seconds":258.0,
		"hull":86.0,
		"max_hull":120.0,
		"health_ratio":0.72,
		"primary_hits":41,
		"dash_uses":7,
		"installations":3,
		"build_snapshot":BuildSnapshotBuilder.build(
			result_build, result_catalog, [], [], {}
		),
		"loadout":{},
	})
	_expect(result.open(final_result), "final result accepts a complete aggregate")
	await process_frame
	var result_contract := result.debug_contract()
	_expect(
		int(result_contract["focusables"]) == 5,
		"final result exposes three acquired cells, diagnostic export, and Deployment"
	)
	_expect(bool(result_contract["initial_focus_is_deployment"]), "final result initially focuses Deployment")
	_expect(StringName(result_contract["primary_variation"]) == &"PrimaryButton", "Deployment is the primary command")
	_expect(int(result_contract["wide_columns"]) == 3 and int(result_contract["compact_tabs"]) == 3, "final result reuses responsive report body")
	_expect(bool(result_contract["build_visible"]), "final result displays the frozen build rail")
	var result_rail := Dictionary(result_contract["build_rail"])
	_expect(
		int(result_rail["section_count"]) == 6
			and int(result_rail["cell_count"]) == 17
			and int(result_rail["filled_count"]) == 3,
		"final result reuses all six grouped categories and the frozen acquired build"
	)
	_expect(
		not bool(result_rail["heading_visible"])
			and float(result_rail["viewport_minimum_height"]) <= 280.0
			and is_equal_approx(float(result_rail["cell_size"]), 20.0),
		"final result uses the dense rail needed to show all categories at 720p"
	)
	_expect("4:18" in String(result_contract["summary_text"]), "final summary preserves cumulative active time")
	_expect("86 / 120" in String(result_contract["summary_text"]), "final summary displays exact current and maximum Hull")
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		result.refresh_localized_content()
		result_contract = result.debug_contract()
		var visible_text := String(result_contract["summary_text"]) + " " + String(result_contract["loadout_text"]) + " " + String(result_contract["reward_text"]) + " " + String(result_contract["primary_action"])
		_expect("RESULT_" not in visible_text, "%s final result contains no raw localization key" % locale)
	(result.get("_deployment") as Button).pressed.emit()
	_expect(deployment_requested[0] == 1, "final command routes directly to Deployment")
	result.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_STAGE_REPORT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
