extends SceneTree

const Telemetry = preload("res://scripts/performance/vehicle_engagement_telemetry.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")

var failures: Array[String] = []


class FakeRuntime extends RefCounted:
	var metrics := {}

	func consume_engagement_telemetry(output: Dictionary) -> void:
		output.clear()
		output.merge(metrics, true)
		metrics = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_empty()
	_validate_stationary()
	_validate_moving_and_events()
	_validate_reset()
	_validate_capacity()
	_validate_engagement_shell()
	_validate_runtime_hooks()
	_validate_long_delta_and_stationary_tail()
	_finish()


func _validate_empty() -> void:
	var telemetry := Telemetry.new()
	telemetry.advance(0.25, FakeRuntime.new(), [], Vector2.ZERO, Vector2.RIGHT * 120.0)
	var snapshot := telemetry.snapshot()
	_expect(int(snapshot["samples"]) == 1, "empty telemetry samples at 4 Hz")
	_expect(
		PackedInt32Array(snapshot["engagement_sector_counts"]).size() == 8
		and int(snapshot["largest_empty_gap_sectors"]) == 8,
		"empty telemetry reports eight empty sectors"
	)
	_expect(
		float(Dictionary(snapshot["rear_hemisphere_engaged_share"])["mean"]) == 0.0,
		"empty moving sample has zero rear share"
	)


func _validate_stationary() -> void:
	var telemetry := Telemetry.new()
	telemetry.advance(
		0.25, FakeRuntime.new(), [_enemy(Vector2(100.0, 0.0))], Vector2.ZERO, Vector2.ZERO
	)
	var snapshot := telemetry.snapshot()
	_expect(
		int(snapshot["stationary_samples"]) == 1
		and Dictionary(snapshot["rear_hemisphere_engaged_share"])["mean"] == null,
		"stationary player does not invent a velocity-relative rear hemisphere"
	)


func _validate_moving_and_events() -> void:
	var runtime := FakeRuntime.new()
	runtime.metrics = {
		"births":4, "gate_completions":2, "active_reservations":7,
		"expiries":1, "cancellations":3, "director_cpu_ms":0.5,
	}
	var telemetry := Telemetry.new()
	telemetry.advance(
		0.25,
		runtime,
		[_enemy(Vector2(100.0, 0.0)), _enemy(Vector2(-100.0, 0.0)), _enemy(Vector2(0.0, 100.0))],
		Vector2.ZERO,
		Vector2.RIGHT * 160.0
	)
	telemetry.advance(0.25, runtime, [], Vector2.ZERO, Vector2.RIGHT * 160.0)
	var snapshot := telemetry.snapshot()
	var sectors := PackedInt32Array(snapshot["engagement_sector_counts"])
	var total := 0
	for count in sectors:
		total += count
	var births: Dictionary = snapshot["births_per_half_second"]
	var gates: Dictionary = snapshot["gate_completions_per_half_second"]
	_expect(total == 3, "moving telemetry aggregates each engaged actor into one of eight sectors")
	_expect(
		is_equal_approx(float(Dictionary(snapshot["rear_hemisphere_engaged_share"])["mean"]), 1.0 / 6.0),
		"moving telemetry measures rear share relative to velocity"
	)
	_expect(
		int(Array(births["buckets"])[0]) == 4 and int(Array(gates["buckets"])[0]) == 2,
		"births and gate completions use half-second buckets"
	)
	_expect(
		int(snapshot["active_reservations_max"]) == 7
		and int(snapshot["expiry_count"]) == 1
		and int(snapshot["cancel_count"]) == 3
		and int(Dictionary(snapshot["director_cpu_ms"])["samples"]) == 1,
		"runtime lifecycle and CPU metrics are additive"
	)


func _validate_reset() -> void:
	var telemetry := Telemetry.new()
	telemetry.advance(0.25, FakeRuntime.new(), [_enemy(Vector2(-10.0, 0.0))], Vector2.ZERO, Vector2.RIGHT * 100.0)
	telemetry.reset()
	var reset := telemetry.snapshot()
	_expect(
		int(reset["samples"]) == 0
		and int(reset["active_reservations_max"]) == 0
		and PackedInt32Array(reset["engagement_sector_counts"])[0] == 0,
		"fresh telemetry reset has no retained diagnostics"
	)


func _validate_capacity() -> void:
	var enemies: Array[Dictionary] = []
	for index in 320:
		enemies.append(_enemy(Vector2(100.0, float(index - 160))))
	var telemetry := Telemetry.new()
	telemetry.advance(0.25, FakeRuntime.new(), enemies, Vector2.ZERO, Vector2.RIGHT * 120.0)
	var sectors := PackedInt32Array(telemetry.snapshot()["engagement_sector_counts"])
	var total := 0
	for count in sectors:
		total += count
	_expect(total == 320, "capacity-bound telemetry counts all 320 active actors without actor retention")


func _validate_engagement_shell() -> void:
	var telemetry := Telemetry.new()
	telemetry.advance(
		0.25,
		FakeRuntime.new(),
		[_enemy(Vector2(899.0, 0.0)), _enemy(Vector2(901.0, 0.0))],
		Vector2.ZERO,
		Vector2.RIGHT * 120.0
	)
	var sectors := PackedInt32Array(telemetry.snapshot()["engagement_sector_counts"])
	var total := 0
	for count in sectors:
		total += count
	_expect(
		total == 1,
		"engagement distribution keeps a stable 900-pixel observation shell"
	)


func _validate_runtime_hooks() -> void:
	var runtime := Runtime.new()
	runtime.set_engagement_telemetry_enabled(true)
	runtime.note_engagement_gate_completion()
	runtime.note_engagement_expiry()
	runtime.note_engagement_cancellation()
	runtime.note_engagement_director_cpu_usec(250)
	var output := {}
	runtime.consume_engagement_telemetry(output)
	_expect(
		int(output["gate_completions"]) == 1
		and int(output["expiries"]) == 1
		and int(output["cancellations"]) == 1
		and is_equal_approx(float(output["director_cpu_ms"]), 0.25),
		"phase-2 lifecycle and precise director CPU hooks are independently measurable"
	)


func _validate_long_delta_and_stationary_tail() -> void:
	var telemetry := Telemetry.new()
	var rear_group := [
		_enemy(Vector2(-100.0, -10.0)),
		_enemy(Vector2(-100.0, 0.0)),
		_enemy(Vector2(-100.0, 10.0)),
	]
	telemetry.advance(0.25, FakeRuntime.new(), rear_group, Vector2.ZERO, Vector2.RIGHT * 120.0)
	telemetry.advance(0.25, FakeRuntime.new(), rear_group, Vector2.ZERO, Vector2.ZERO)
	telemetry.advance(10.0, FakeRuntime.new(), [], Vector2.ZERO, Vector2.RIGHT * 120.0)
	var snapshot := telemetry.snapshot()
	_expect(
		float(snapshot["longest_rear_tail_interval_seconds"]) == 0.25,
		"stationary input closes a rear-tail interval instead of extending it"
	)
	_expect(
		int(snapshot["skipped_samples"]) > 0
		and int(snapshot["samples"]) <= 6,
		"long deltas use a bounded deterministic sampling catch-up"
	)


static func _enemy(position: Vector2) -> Dictionary:
	return {"pos":position, "alive":true, "active":true, "counts_active_cap":true}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENGAGEMENT_TELEMETRY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
