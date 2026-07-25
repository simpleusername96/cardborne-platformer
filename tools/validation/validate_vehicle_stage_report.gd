extends SceneTree

const Builder = preload("res://scripts/combat/vehicle_stage_report_builder.gd")
const ReportPanel = preload("res://scripts/ui/vehicle_stage_report_panel.gd")

var _failures: Array[String] = []


func _init() -> void:
	var telemetry := {
		"outgoing":{
			&"primary":41.0,
			&"passive_seeker":17.0,
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
			"title_key":"STAGE_2_TITLE",
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
	var crowded := {}
	for index in 12:
		crowded[StringName("source_%02d" % index)] = float(index + 1)
	var crowded_report := Builder.build(
		{"outgoing":crowded},
		{"number":1, "title_key":"STAGE_1_TITLE", "has_next_stage":true}
	)
	_expect(crowded_report["outgoing"].size() == 8, "more than eight sources collapse to seven plus Other")
	_expect(StringName(crowded_report["outgoing"][-1]["id"]) == &"other", "collapsed row uses stable Other ID")
	var panel := ReportPanel.new()
	get_root().add_child(panel)
	await process_frame
	panel.open(report)
	var contract := panel.debug_contract()
	_expect(is_equal_approx(float(contract["guard"]), 0.35), "report blocks carried input for 0.35 seconds")
	_expect(int(contract["defeats"]) == 2, "panel receives frozen defeat rows")
	_expect(int(contract["attributes"]) == 3, "panel receives all attribute rows")
	panel.queue_free()
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
