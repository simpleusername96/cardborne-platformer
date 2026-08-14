extends SceneTree

const Buffer = preload("res://scripts/performance/vehicle_slow_tick_receipt_buffer.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_fixed_slow_tail_receipts()
	_validate_pressure_observation_gate()
	_finish()


func _validate_fixed_slow_tail_receipts() -> void:
	var buffer := Buffer.new()
	var coarse := PackedFloat64Array()
	coarse.resize(Buffer.coarse_field_count())
	var scalars := PackedInt32Array()
	scalars.resize(Buffer.scalar_field_count())
	for serial in Buffer.CAPACITY + 4:
		coarse[0] = float(serial) * 0.25
		scalars[0] = serial
		buffer.record(serial, float(serial), coarse, scalars)
	_expect(buffer.retained_count() == Buffer.CAPACITY, "slow receipts retain exactly the fixed top-32 capacity")
	var receipts := buffer.finalized_receipts()
	_expect(receipts.size() == Buffer.CAPACITY, "finalization emits only retained slow receipts")
	var slowest := Dictionary(receipts[0]) if not receipts.is_empty() else {}
	var last := Dictionary(receipts[-1]) if not receipts.is_empty() else {}
	_expect(
		int(slowest.get("physics_serial", -1)) == Buffer.CAPACITY + 3
			and int(last.get("physics_serial", -1)) == 4,
		"receipt finalization orders the retained tail from slowest to fastest"
	)
	var coarse_result := Dictionary(slowest.get("coarse_ms", {}))
	_expect(
		coarse_result.has("encounter_and_pursuit_ms")
			and int(slowest.get("exact_enemy_count", -1)) == Buffer.CAPACITY + 3,
		"finalization names coarse timing and fixed scalar evidence fields"
	)
	buffer.clear()
	for serial in 3:
		buffer.record(serial, 7.0, coarse, scalars)
	var tied := buffer.finalized_receipts()
	_expect(
		int(Dictionary(tied[0]).get("physics_serial", -1)) == 0
			and int(Dictionary(tied[2]).get("physics_serial", -1)) == 2,
		"equal-duration receipts use deterministic ascending physics serial order"
	)


func _validate_pressure_observation_gate() -> void:
	var runtime := Runtime.new()
	runtime.configure(&"validation", [], &"hard")
	var inactive := runtime.tick(0.0, 5, [], Vector2.ZERO, Rect2(-10, -10, 20, 20), [], 3)
	_expect(
		Dictionary(runtime.debug_snapshot().get("pressure", {})).is_empty() == false
			and int(Dictionary(runtime.debug_snapshot()["pressure"]).get("active", -1)) == 0,
		"disabled pressure observation skips diagnostic active-enemy scanning"
	)
	_expect(
		not runtime.pressure_scan_happened()
			and not runtime.pressure_observation_enabled(),
		"disabled runtime reports zero pressure-scan work"
	)
	runtime.set_pressure_observation_enabled(true)
	runtime.tick(0.0, 5, [], Vector2.ZERO, Rect2(-10, -10, 20, 20), [], 3)
	_expect(
		int(Dictionary(runtime.debug_snapshot()["pressure"]).get("active", -1)) == 5,
		"enabled pressure observation preserves the pressure schema"
	)
	_expect(
		runtime.pressure_scan_happened()
			and runtime.pressure_observation_enabled(),
		"enabled runtime exposes one scalar scan receipt without another snapshot"
	)
	runtime.set_pressure_observation_enabled(false)
	_expect(
		int(Dictionary(runtime.debug_snapshot()["pressure"]).get("active", -1)) == 0
			and inactive is Dictionary,
		"disabling observation clears stale diagnostic pressure without changing tick output"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SLOW_TICK_RECEIPTS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
