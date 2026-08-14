class_name VehicleStageTransitionRuntime
extends RefCounted

## Owns the bounded order of post-boss work. VehicleRun remains the executor
## because it owns the live stage, enemy, presentation, and report state.

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
var _last_step_physics_serial := -1


func reset() -> void:
	_phase = Phase.IDLE
	_has_next_stage = false
	_last_step_physics_serial = -1


func begin(has_next_stage: bool, physics_serial: int) -> bool:
	if _phase != Phase.IDLE:
		return false
	_has_next_stage = has_next_stage
	_phase = Phase.WAIT_FOR_DEFEAT_FLUSH
	_last_step_physics_serial = physics_serial
	return true


func advance(physics_serial: int) -> StringName:
	if _phase == Phase.IDLE or physics_serial <= _last_step_physics_serial:
		return &""
	_last_step_physics_serial = physics_serial
	match _phase:
		Phase.WAIT_FOR_DEFEAT_FLUSH:
			_phase = Phase.CAPTURE_REPORT
			return &"defeat_flush_complete"
		Phase.CAPTURE_REPORT:
			_phase = (
				Phase.PREPARE_CONTINUATION
				if _has_next_stage
				else Phase.BUILD_FINAL_RESULT
			)
			return &"capture_report"
		Phase.PREPARE_CONTINUATION:
			_phase = Phase.CONFIGURE_WORLD
			return &"prepare_continuation"
		Phase.CONFIGURE_WORLD:
			_phase = Phase.FINALIZE_CONTINUATION
			return &"configure_world"
		Phase.FINALIZE_CONTINUATION:
			reset()
			return &"finalize_continuation"
		Phase.BUILD_FINAL_RESULT:
			_phase = Phase.SHOW_FINAL_RESULT
			return &"build_final_result"
		Phase.SHOW_FINAL_RESULT:
			reset()
			return &"show_final_result"
	return &""


func active() -> bool:
	return _phase != Phase.IDLE


func debug_snapshot() -> Dictionary:
	return {
		"active":active(),
		"phase":_phase,
		"has_next_stage":_has_next_stage,
		"last_step_physics_serial":_last_step_physics_serial,
	}
