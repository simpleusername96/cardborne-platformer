extends SceneTree

const Director = preload("res://scripts/encounters/vehicle_engagement_director.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_patterns_and_gates()
	_validate_lifecycle_and_reuse()
	_validate_determinism_and_debt()
	_validate_capacity_and_reset()
	_finish()


func _request(id: String, ordinal: int, expected: float = 3.0) -> Dictionary:
	return {"id":id, "ordinal":ordinal, "eligible_sectors":[0, 1, 2, 3, 4], "heading_sector":0, "expected_time":expected, "expiry_time":expected + 5.0, "anchor":Vector2(10.0, 20.0), "gate_radius":520.0}


func _validate_patterns_and_gates() -> void:
	_expect(Director.pattern_sectors(Director.BROAD_CRESCENT, 4) == PackedInt32Array([2, 3, 4, 5, 6]), "crescent has the locked five-sector front pattern")
	_expect(Director.pattern_sectors(Director.TWO_OFFSET_STREAMS, 4, 0) == PackedInt32Array([2, 3]), "offset streams alternate left first")
	_expect(Director.pattern_sectors(Director.TWO_OFFSET_STREAMS, 4, 1) == PackedInt32Array([5, 6]), "offset streams alternate right second")
	_expect(is_equal_approx(Director.gate_radius(&"pursuit"), 520.0), "pursuit gate radius is fixed")
	_expect(is_equal_approx(Director.gate_radius(&"standoff", Vector2(330.0, 500.0)), 430.0), "standoff gate radius clamps midpoint")
	_expect(is_equal_approx(Director.expiry_time(10.0, 30.0), 28.0), "expiry uses the locked upper clamp")
	var director := Director.new()
	director.configure(4)
	var gated := director.reserve(_request("sector_gate", 0))
	var gated_reservation := director.reservation(gated)
	var selected_sector := int(gated_reservation["sector"])
	var expected_gate := Vector2(10.0, 20.0) + Vector2.from_angle(
		(float(selected_sector) + 0.5) * TAU / 8.0 - PI
	) * 520.0
	_expect(
		Vector2(gated_reservation["gate"]).is_equal_approx(expected_gate),
		"selected sector produces its own fixed approach gate"
	)
	var invalid := _request("invalid", 0)
	invalid["gate_valid_by_sector"] = {0:false, 1:false, 2:false, 3:false, 4:false}
	_expect(bool(director.reserve(invalid).get("no_gate", false)), "invalid geometry falls back without blocking birth")


func _validate_lifecycle_and_reuse() -> void:
	var director := Director.new()
	director.configure(99)
	var handle := director.reserve(_request("life", 0))
	_expect(not handle.is_empty(), "reserve succeeds")
	_expect(director.confirm(handle), "confirm transitions reserved to materialized")
	_expect(director.complete(handle), "complete releases materialized reservation")
	_expect(not director.confirm(handle), "stale released handle is rejected")
	var reused := director.reserve(_request("reuse", 1))
	_expect(int(reused["generation"]) != int(handle["generation"]) or int(reused["slot"]) != int(handle["slot"]), "reused reservation has a distinct stable handle")
	_expect(director.cancel(reused), "cancel releases reserved reservation")
	director.reset()
	var after_reset := director.reserve(_request("after_reset", 2))
	_expect(
		not director.confirm(handle),
		"reset rejects every pre-reset handle"
	)
	_expect(not after_reset.is_empty(), "reset permits a new generation reservation")


func _validate_determinism_and_debt() -> void:
	var left := Director.new()
	var right := Director.new()
	left.configure(12345)
	right.configure(12345)
	var left_trace := []
	var right_trace := []
	for ordinal in 12:
		left_trace.append(left.reserve(_request("replay", ordinal, 2.0 + ordinal * 0.5)))
		right_trace.append(right.reserve(_request("replay", ordinal, 2.0 + ordinal * 0.5)))
	_expect(var_to_str(left_trace) == var_to_str(right_trace), "replay fingerprints are deterministic")
	var debug := {}
	left.fill_debug(debug)
	for debt in PackedByteArray(debug["sector_debt"]):
		_expect(debt <= Director.DEBT_MAX, "sector debt remains bounded")
	_expect(int(debug["live_count"]) == 12, "incremental counters reconcile live reservations")


func _validate_capacity_and_reset() -> void:
	var director := Director.new()
	director.configure(7)
	for ordinal in Director.CAPACITY:
		var request := _request("capacity", ordinal, 100.0 + float(ordinal) * 0.5)
		request["validation_allow_eta_saturation"] = true
		_expect(not director.reserve(request).is_empty(), "capacity slot %d reserves" % ordinal)
	_expect(director.reserve(_request("overflow", 321)).is_empty(), "capacity rejects overflow")
	director.reset()
	var debug := {}
	director.fill_debug(debug)
	_expect(int(debug["live_count"]) == 0, "reset clears live reservations")
	for load in PackedInt32Array(debug["reserved_load"]):
		_expect(load == 0, "reset clears packed load counters")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENGAGEMENT_DIRECTOR_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
