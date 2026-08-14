extends SceneTree

const RUN_PATH := "res://scripts/vehicle/vehicle_run.gd"
const FLOW_PATH := "res://scripts/encounters/vehicle_stage_flow.gd"
const TRANSITION_PATH := (
	"res://scripts/vehicle/vehicle_stage_transition_runtime.gd"
)
const BOSS_PATH := "res://scripts/bosses/vehicle_boss_runtime.gd"
const REWARD_PATH := "res://scripts/rewards/vehicle_reward_runtime.gd"
const FIXTURE_PATH := (
	"res://scripts/vehicle/vehicle_campaign_fixture_facade.gd"
)
const GATEWAY_PATH := "res://scripts/vehicle/vehicle_run_capture_gateway.gd"

var _failures: Array[String] = []


func _initialize() -> void:
	var run_source := FileAccess.get_file_as_string(RUN_PATH)
	var flow_source := FileAccess.get_file_as_string(FLOW_PATH)
	var transition_source := FileAccess.get_file_as_string(TRANSITION_PATH)
	var boss_source := FileAccess.get_file_as_string(BOSS_PATH)
	var reward_source := FileAccess.get_file_as_string(REWARD_PATH)
	var fixture_source := FileAccess.get_file_as_string(FIXTURE_PATH)
	var gateway_source := FileAccess.get_file_as_string(GATEWAY_PATH)

	_expect(
		flow_source.contains("COMMAND_COMPLETE_WITHOUT_BOSS")
			and flow_source.contains("COMMAND_COMPLETE_AFTER_BOSS")
			and flow_source.contains("static func valid_receipt("),
		"StageFlow owns quota and boss-completion receipt policy"
	)
	_expect(
		transition_source.contains("func begin(")
			and transition_source.contains("func advance(")
			and transition_source.contains("static func valid_command("),
		"transition runtime owns next/terminal command order and validation"
	)
	var complete_start := run_source.find("func _complete_stage(")
	var transition_begin := run_source.find(
		"stage_transition_runtime.begin(", complete_start
	)
	var completion_latch := run_source.find("stage_complete = true", complete_start)
	_expect(
		complete_start >= 0
			and transition_begin > complete_start
			and completion_latch > transition_begin,
		"VehicleRun accepts the transition receipt before committing world teardown"
	)
	_expect(
		not run_source.contains("func _advance_stage()")
			and not run_source.contains("func _begin_next_stage_continuation()"),
		"VehicleRun must not keep a second direct stage-continuation path"
	)
	var boss_update_start := run_source.find("func _update_stage_boss(")
	var boss_update_end := run_source.find("\nfunc ", boss_update_start + 1)
	var boss_update_source := run_source.substr(
		boss_update_start, boss_update_end - boss_update_start
	)
	_expect(
		boss_source.contains("func advance_direct_phase(")
			and boss_update_source.contains("boss_runtime.advance_direct_phase(")
			and not boss_update_source.contains("if phase =="),
		"BossRuntime owns phase decisions while VehicleRun executes returned actions"
	)
	_expect(
		reward_source.contains("func campaign_receipt(")
			and reward_source.contains("static func valid_campaign_receipt("),
		"reward runtime publishes its queue state without UI-owned inference"
	)
	_expect(
		fixture_source.contains("func complete_current_stage(")
			and fixture_source.contains("func campaign_digest(")
			and gateway_source.contains("_campaign_fixture.prepare_stage(")
			and not gateway_source.contains("_run.stage_flow.state ="),
		"capture and validation campaign setup is isolated behind one fixture facade"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_CAMPAIGN_OWNERSHIP_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
