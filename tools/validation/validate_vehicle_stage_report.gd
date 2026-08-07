extends SceneTree

const Builder = preload("res://scripts/combat/vehicle_stage_report_builder.gd")
const ReportPanel = preload("res://scripts/ui/vehicle_stage_report_panel.gd")
const ResultPanel = preload("res://scripts/ui/vehicle_result_panel.gd")

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
			"clear_time":83.0,
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
		is_equal_approx(float(report["clear_time"]), 83.0)
			and is_equal_approx(float(report["hull"]), 72.0),
		"report freezes clear time and remaining hull"
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
			"clear_time":83.0,
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
	var garage_requested := [0]
	panel.continued.connect(func() -> void: continued[0] += 1)
	panel.garage_requested.connect(func() -> void: garage_requested[0] += 1)
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
	panel.call("_process", 0.36)
	panel.call("_on_continue")
	_expect(continued[0] == 1 and garage_requested[0] == 0, "successful report emits only continue")
	panel.open(failure_report)
	await process_frame
	contract = panel.debug_contract()
	_expect(bool(contract["incoming_visible"]), "failure report reveals incoming damage")
	_expect(int(contract["incoming_rows"]) == 3, "failure report renders the bounded top-three recap")
	_expect(bool(contract["last_hit_present"]), "failure report renders the last-hit recap")
	_expect(int(contract["fixed_actions"]) == 1, "failure report keeps one fixed action")
	panel.call("_process", 0.36)
	panel.call("_on_continue")
	_expect(continued[0] == 1 and garage_requested[0] == 1, "failure report emits only garage intent")
	panel.queue_free()

	var result := ResultPanel.new()
	get_root().add_child(result)
	await process_frame
	var result_garage := [0]
	var result_replay := [0]
	result.garage_requested.connect(func() -> void: result_garage[0] += 1)
	result.replay_requested.connect(func() -> void: result_replay[0] += 1)
	_expect(result.open({
		"stage_number":5,
		"stage_title_key":"STAGE_DROWNED_RUINS_5",
		"has_next_stage":false,
		"time":"4:18",
		"health_ratio":0.72,
		"upgrade":"UPGRADE_SPLIT_MUZZLE_TITLE",
		"primary_hits":41,
		"dash_uses":7,
		"installations":3,
	}), "final result accepts a complete summary")
	await process_frame
	var result_contract := result.debug_contract()
	_expect(int(result_contract["summary_text_rows"]) == 1, "final result uses one summary TextRow")
	_expect(int(result_contract["summary_values"]) == 3, "final summary preserves all three values")
	_expect(int(result_contract["summary_surfaces"]) == 0, "final summary and detail sections remain unboxed")
	_expect(int(result_contract["focusables"]) == 2, "final result preserves Garage and Replay actions")
	_expect(bool(result_contract["performance_visible"]), "final result preserves performance values")
	_expect(bool(result_contract["reward_visible"]), "final result preserves reward values")
	_expect(bool(result_contract["initial_focus_is_garage"]), "final result initially focuses Garage")
	_expect(StringName(result_contract["primary_variation"]) == &"PrimaryButton", "Garage remains the primary command")
	_expect(StringName(result_contract["secondary_variation"]) == &"SecondaryButton", "Replay remains the secondary command")
	var joined_summary := " ".join(PackedStringArray(result_contract["summary_texts"]))
	_expect("4:18" in joined_summary and "72" in joined_summary, "final summary preserves time and hull values")
	_expect("41" in String(result_contract["performance_text"]) and "7" in String(result_contract["performance_text"]) and "3" in String(result_contract["performance_text"]), "performance section preserves all three counters")
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		result.refresh_localized_content()
		result_contract = result.debug_contract()
		var visible_text := " ".join(PackedStringArray(result_contract["summary_texts"])) + " " + String(result_contract["performance_text"]) + " " + String(result_contract["reward_text"]) + " " + String(result_contract["primary_action"]) + " " + String(result_contract["secondary_action"])
		_expect("RESULT_" not in visible_text and "UPGRADE_" not in visible_text, "%s final result contains no raw localization key" % locale)
	(result.get("_first_button") as Button).pressed.emit()
	(result.get("_replay_button") as Button).pressed.emit()
	_expect(result_garage[0] == 1 and result_replay[0] == 1, "final commands preserve Garage and Replay signals")
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
