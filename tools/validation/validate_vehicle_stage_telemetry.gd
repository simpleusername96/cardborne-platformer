extends SceneTree

const Telemetry = preload("res://scripts/combat/vehicle_stage_telemetry.gd")
const Sources = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")
const ReportBuilder = preload("res://scripts/combat/vehicle_stage_report_builder.gd")

var _failures: Array[String] = []


func _init() -> void:
	var telemetry := Telemetry.new()
	telemetry.reset_run()
	telemetry.record_outgoing(&"primary", &"kinetic", 18.0)
	telemetry.record_outgoing(&"primary", &"kinetic", 6.5)
	telemetry.record_outgoing(&"elemental_status", &"thermal", 2.0)
	telemetry.record_status_application(&"burn")
	telemetry.record_status_application(&"chill")
	telemetry.record_incoming(&"projectile", 7.0)
	telemetry.record_defeat(&"needle_drone", &"armored")
	var frozen := telemetry.freeze_stage()
	_expect(is_equal_approx(float(frozen["outgoing"][&"primary"]), 24.5), "applied outgoing damage accumulates exactly")
	_expect(
		is_equal_approx(
			float(frozen["attributes"][&"kinetic"]) + float(frozen["attributes"][&"thermal"]),
			26.5
		),
		"attribute partition matches the outgoing total"
	)
	var report := ReportBuilder.build(frozen, {})
	_expect(
		is_equal_approx(float(report["total_outgoing"]), float(report["total_attributes"])),
		"source and attribute report totals agree"
	)
	var control_only_chill := false
	for row_variant in Array(report["attributes"]):
		var row := Dictionary(row_variant)
		if (
			StringName(row["id"]) == &"cryo"
			and int(row["applications"]) == 1
			and int(row["percentage_tenths"]) == 0
		):
			control_only_chill = true
	_expect(control_only_chill, "control-only chill remains visible without invented damage")
	_expect(int(frozen["defeats"][&"needle_drone"]) == 1, "base archetype defeat is counted")
	_expect(
		int(frozen["elites"][&"needle_drone:armored"]) == 1,
		"elite trait remains nested under its base archetype"
	)
	_expect(StringName(frozen["last_incoming_source"]) == &"projectile", "last incoming source is retained")
	telemetry.record_outgoing(&"primary", &"kinetic", 99.0)
	_expect(is_equal_approx(float(telemetry.stage_snapshot()["outgoing"][&"primary"]), 24.5), "frozen stage snapshot is immutable")
	telemetry.reset_stage()
	_expect(telemetry.stage_snapshot()["outgoing"].is_empty(), "stage reset clears stage counters")
	_expect(is_equal_approx(float(telemetry.run_snapshot()["outgoing"][&"primary"]), 123.5), "stage reset preserves run totals")
	_expect(Sources.outgoing_id("player_primary") == &"primary", "primary source ID is stable")
	_expect(Sources.outgoing_id("unknown-runtime-copy") == &"other", "unknown outgoing source is visible Other")
	_expect(Sources.incoming_id("Titan beam", true) == &"boss", "boss incoming source is stable")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_STAGE_TELEMETRY_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
