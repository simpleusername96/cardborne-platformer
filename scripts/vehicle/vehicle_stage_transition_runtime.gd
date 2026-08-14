class_name VehicleStageTransitionRuntime
extends RefCounted

## Owns the bounded order and next/terminal policy of campaign transitions.
## VehicleRun executes returned commands because it owns live SceneTree mutation.

enum Phase {
	IDLE,
	WAIT_FOR_DEFEAT_FLUSH,
	CAPTURE_REPORT,
	PREPARE_CONTINUATION,
	CONFIGURE_WORLD,
	FINALIZE_CONTINUATION,
	BUILD_FINAL_RESULT,
	SHOW_FINAL_RESULT,
}

var _phase := Phase.IDLE
var _has_next_stage := false
var _stage_index := -1
var _stage_count := 0
var _completion_kind: StringName = &""
var _last_step_physics_serial := -1

const COMPLETION_WITHOUT_BOSS: StringName = &"without_boss"
const COMPLETION_AFTER_BOSS: StringName = &"after_boss"
const COMPLETION_KINDS: Array[StringName] = [
	COMPLETION_WITHOUT_BOSS, COMPLETION_AFTER_BOSS,
]
const COMMANDS: Array[StringName] = [
	&"defeat_flush_complete",
	&"capture_report",
	&"prepare_continuation",
	&"configure_world",
	&"finalize_continuation",
	&"build_final_result",
	&"show_final_result",
]


func reset() -> void:
	_phase = Phase.IDLE
	_has_next_stage = false
	_stage_index = -1
	_stage_count = 0
	_completion_kind = &""
	_last_step_physics_serial = -1


func begin(
	stage_index: int,
	stage_count: int,
	completion_kind: StringName,
	physics_serial: int
) -> Dictionary:
	if (
		_phase != Phase.IDLE
		or stage_index < 0
		or stage_count <= 0
		or stage_index >= stage_count
		or completion_kind not in COMPLETION_KINDS
	):
		return _begin_receipt(false)
	_stage_index = stage_index
	_stage_count = stage_count
	_completion_kind = completion_kind
	_has_next_stage = stage_index < stage_count - 1
	_phase = Phase.WAIT_FOR_DEFEAT_FLUSH
	_last_step_physics_serial = physics_serial
	return _begin_receipt(true)


func advance(physics_serial: int) -> Dictionary:
	if _phase == Phase.IDLE or physics_serial <= _last_step_physics_serial:
		return {}
	_last_step_physics_serial = physics_serial
	var command: StringName = &""
	match _phase:
		Phase.WAIT_FOR_DEFEAT_FLUSH:
			_phase = Phase.CAPTURE_REPORT
			command = &"defeat_flush_complete"
		Phase.CAPTURE_REPORT:
			_phase = (
				Phase.PREPARE_CONTINUATION
				if _has_next_stage
				else Phase.BUILD_FINAL_RESULT
			)
			command = &"capture_report"
		Phase.PREPARE_CONTINUATION:
			_phase = Phase.CONFIGURE_WORLD
			command = &"prepare_continuation"
		Phase.CONFIGURE_WORLD:
			_phase = Phase.FINALIZE_CONTINUATION
			command = &"configure_world"
		Phase.FINALIZE_CONTINUATION:
			command = &"finalize_continuation"
			var receipt := _command_receipt(command)
			reset()
			return receipt
		Phase.BUILD_FINAL_RESULT:
			_phase = Phase.SHOW_FINAL_RESULT
			command = &"build_final_result"
		Phase.SHOW_FINAL_RESULT:
			command = &"show_final_result"
			var receipt := _command_receipt(command)
			reset()
			return receipt
	return _command_receipt(command)


static func valid_command(receipt: Dictionary) -> bool:
	return (
		receipt.has("command")
		and receipt.has("stage_index")
		and receipt.has("stage_count")
		and receipt.has("next_stage_index")
		and receipt.has("has_next_stage")
		and receipt.has("terminal")
		and receipt.has("completion_kind")
		and int(receipt["stage_index"]) >= 0
		and int(receipt["stage_count"]) > int(receipt["stage_index"])
		and StringName(receipt["command"]) in COMMANDS
		and StringName(receipt["completion_kind"]) in COMPLETION_KINDS
		and bool(receipt["terminal"]) == not bool(receipt["has_next_stage"])
		and int(receipt["next_stage_index"]) == (
			int(receipt["stage_index"]) + 1
			if bool(receipt["has_next_stage"])
			else -1
		)
	)


func _begin_receipt(accepted: bool) -> Dictionary:
	return {
		"accepted":accepted,
		"stage_index":_stage_index,
		"stage_count":_stage_count,
		"has_next_stage":_has_next_stage,
		"completion_kind":_completion_kind,
	}


func _command_receipt(command: StringName) -> Dictionary:
	return {
		"command":command,
		"stage_index":_stage_index,
		"stage_count":_stage_count,
		"next_stage_index":_stage_index + 1 if _has_next_stage else -1,
		"has_next_stage":_has_next_stage,
		"terminal":not _has_next_stage,
		"completion_kind":_completion_kind,
	}


func active() -> bool:
	return _phase != Phase.IDLE


func debug_snapshot() -> Dictionary:
	return {
		"active":active(),
		"phase":_phase,
		"has_next_stage":_has_next_stage,
		"stage_index":_stage_index,
		"stage_count":_stage_count,
		"completion_kind":_completion_kind,
		"last_step_physics_serial":_last_step_physics_serial,
	}
