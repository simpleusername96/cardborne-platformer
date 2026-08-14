extends SceneTree

const TransitionRuntime = preload(
	"res://scripts/vehicle/vehicle_stage_transition_runtime.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	_validate_rejected_begin_is_inert()
	_validate_continuation_order()
	_validate_final_order()
	_validate_no_boss_continuation_order()
	if failures.is_empty():
		print("VEHICLE_STAGE_TRANSITION_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _validate_rejected_begin_is_inert() -> void:
	var runtime := TransitionRuntime.new()
	var before := runtime.debug_snapshot()
	var rejected := runtime.begin(0, 5, &"invalid", 4)
	_expect(
		not bool(rejected["accepted"])
			and runtime.debug_snapshot() == before,
		"an invalid completion kind cannot mutate transition state"
	)


func _validate_continuation_order() -> void:
	var runtime := TransitionRuntime.new()
	var begin_receipt := runtime.begin(
		0, 5, TransitionRuntime.COMPLETION_AFTER_BOSS, 10
	)
	_expect(bool(begin_receipt["accepted"]), "continuation begins once")
	_expect(
		not bool(runtime.begin(0, 5, TransitionRuntime.COMPLETION_AFTER_BOSS, 10)["accepted"]),
		"duplicate begin is rejected"
	)
	_expect(runtime.advance(10).is_empty(), "lethal tick performs no transition step")
	var commands: Array[StringName] = []
	for serial in range(11, 16):
		var receipt := runtime.advance(serial)
		_expect(TransitionRuntime.valid_command(receipt), "continuation command receipt is valid")
		commands.append(StringName(receipt["command"]))
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
	var begin_receipt := runtime.begin(
		4, 5, TransitionRuntime.COMPLETION_AFTER_BOSS, 20
	)
	_expect(
		bool(begin_receipt["accepted"])
			and bool(begin_receipt["has_next_stage"]) == false,
		"final transition begins"
	)
	var commands: Array[StringName] = []
	for serial in range(21, 25):
		var receipt := runtime.advance(serial)
		_expect(TransitionRuntime.valid_command(receipt), "terminal command receipt is valid")
		commands.append(StringName(receipt["command"]))
	_expect(
		commands == [
			&"defeat_flush_complete", &"capture_report",
			&"build_final_result", &"show_final_result"
		],
		"final result is separated from defeat and report capture"
	)
	_expect(not runtime.active(), "final transition returns to idle")


func _validate_no_boss_continuation_order() -> void:
	var runtime := TransitionRuntime.new()
	var no_boss_receipt := runtime.begin(
		0, 5, TransitionRuntime.COMPLETION_WITHOUT_BOSS, 30
	)
	_expect(
		bool(no_boss_receipt["accepted"])
			and StringName(no_boss_receipt["completion_kind"])
				== TransitionRuntime.COMPLETION_WITHOUT_BOSS,
		"no-boss completion uses the same bounded continuation owner"
	)
	var commands: Array[StringName] = []
	for serial in range(31, 36):
		var receipt := runtime.advance(serial)
		_expect(
			TransitionRuntime.valid_command(receipt)
				and int(receipt["stage_index"]) == 0
				and int(receipt["next_stage_index"]) == 1
				and not bool(receipt["terminal"]),
			"no-boss continuation preserves its stage receipt"
		)
		commands.append(StringName(receipt["command"]))
	_expect(
		commands == [
			&"defeat_flush_complete",
			&"capture_report",
			&"prepare_continuation",
			&"configure_world",
			&"finalize_continuation",
		],
		"no-boss completion follows the ordinary continuation sequence"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
