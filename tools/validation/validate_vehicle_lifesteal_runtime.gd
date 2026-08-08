extends SceneTree

const LifestealRuntime = preload(
	"res://scripts/cards/vehicle_lifesteal_runtime.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	var runtime := LifestealRuntime.new()
	runtime.reset(2.0)
	_expect(
		is_equal_approx(runtime.consume(100.0, 120.0), 2.0),
		"level one restores two percent of applied damage"
	)
	_expect(
		is_equal_approx(runtime.remaining_budget(), 4.0),
		"healing consumes the shared recovery budget"
	)
	_expect(
		is_equal_approx(runtime.consume(400.0, 120.0), 4.0),
		"one burst cannot exceed the remaining six-Hull budget"
	)
	_expect(
		is_equal_approx(runtime.consume(100.0, 120.0), 0.0),
		"an exhausted budget blocks further recovery"
	)
	runtime.advance(0.5)
	_expect(
		is_equal_approx(runtime.remaining_budget(), 3.0),
		"the budget replenishes at six Hull per second"
	)
	runtime.reset(3.5)
	_expect(
		is_equal_approx(runtime.consume(100.0, 120.0), 3.5),
		"level two restores three and a half percent of applied damage"
	)
	runtime.reset(3.5)
	_expect(
		is_equal_approx(runtime.consume(100.0, 1.25), 1.25),
		"recovery never exceeds missing Hull"
	)
	runtime.reset(0.0)
	_expect(
		is_equal_approx(runtime.consume(100.0, 120.0), 0.0),
		"a build without Lifesteal cannot recover Hull"
	)
	runtime.reset(3.5)
	_expect(
		is_equal_approx(runtime.consume(0.0, 120.0), 0.0)
			and is_equal_approx(runtime.consume(-10.0, 120.0), 0.0)
			and is_equal_approx(runtime.consume(100.0, 0.0), 0.0),
		"non-damage receipts and full Hull cannot consume the budget"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_LIFESTEAL_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
