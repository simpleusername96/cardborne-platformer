extends SceneTree

const Telemetry = preload("res://scripts/combat/vehicle_stage_telemetry.gd")
const Sources = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")

var _failures: Array[String] = []


func _init() -> void:
	var telemetry := Telemetry.new()
	telemetry.reset_run()
	telemetry.record_outgoing(&"primary", 18.0)
	telemetry.record_outgoing(&"primary", 6.5)
	telemetry.record_outgoing(&"elemental_status", 2.0)
	telemetry.record_incoming(&"projectile", 7.0)
	telemetry.record_defeat(&"needle_drone", &"armored")
	var frozen := telemetry.freeze_stage()
	_expect(is_equal_approx(float(frozen["outgoing"][&"primary"]), 24.5), "applied outgoing damage accumulates exactly")
	_expect(int(frozen["defeats"][&"needle_drone"]) == 1, "base archetype defeat is counted")
	_expect(int(frozen["elites"][&"armored"]) == 1, "elite trait remains a secondary count")
	_expect(StringName(frozen["last_incoming_source"]) == &"projectile", "last incoming source is retained")
	telemetry.record_outgoing(&"primary", 99.0)
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
