extends SceneTree

const TransitionRuntime = preload(
	"res://scripts/vehicle/vehicle_stage_transition_runtime.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	_validate_continuation_order()
	_validate_final_order()
	if failures.is_empty():
		print("VEHICLE_STAGE_TRANSITION_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _validate_continuation_order() -> void:
	var runtime := TransitionRuntime.new()
	_expect(runtime.begin(true, 10), "continuation begins once")
	_expect(not runtime.begin(true, 10), "duplicate begin is rejected")
	_expect(runtime.advance(10) == &"", "lethal tick performs no transition step")
	var commands: Array[StringName] = []
	for serial in range(11, 16):
		commands.append(runtime.advance(serial))
	_expect(
		commands == [
			&"defeat_flush_complete",
			&"capture_report",
			&"prepare_continuation",
			&"configure_world",
			&"finalize_continuation",
		],
		"continuation work advances one ordered step per physics tick"
	)
	_expect(not runtime.active(), "continuation returns to idle")


func _validate_final_order() -> void:
	var runtime := TransitionRuntime.new()
	_expect(runtime.begin(false, 20), "final transition begins")
	var commands: Array[StringName] = []
	for serial in range(21, 25):
		commands.append(runtime.advance(serial))
	_expect(
		commands == [
			&"defeat_flush_complete", &"capture_report",
			&"build_final_result", &"show_final_result"
		],
		"final result is separated from defeat and report capture"
	)
	_expect(not runtime.active(), "final transition returns to idle")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
