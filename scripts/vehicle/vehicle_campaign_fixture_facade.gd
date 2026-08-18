class_name VehicleCampaignFixtureFacade
extends RefCounted

## Drives campaign fixtures through production owners while keeping capture and
## validation code away from VehicleRun's transition internals.

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const TransitionRuntime = preload(
	"res://scripts/vehicle/vehicle_stage_transition_runtime.gd"
)

var _run: Node


func _init(run: Node) -> void:
	_run = run


func prepare_stage(stage_index: int, preserve_upgrades: bool = false) -> bool:
	if (
		not is_instance_valid(_run)
		or stage_index < 0
		or stage_index >= StageCatalog.STAGE_IDS.size()
	):
		return false
	_run.current_stage_index = stage_index
	_run.current_stage_id = StageCatalog.STAGE_IDS[stage_index]
	_run._reset_run(false, true, preserve_upgrades)
	_run.capture_set_mode(&"playing")
	_run.player_position = Rules.player_start(_run.current_stage_id)
	_run.player_invulnerable = 99.0
	_run._camera.zoom = Rules.GAMEPLAY_CAMERA_ZOOM
	_run._ui.show_gameplay()
	return true


func prepare_boss_entry(stage_index: int) -> VehicleEnemyState:
	if (
		stage_index < 0
		or stage_index >= StageCatalog.STAGE_IDS.size()
		or not StageCatalog.has_boss(StageCatalog.STAGE_IDS[stage_index])
	):
		return null
	if not prepare_stage(stage_index, true):
		return null
	_run._clear_enemies()
	_run._clear_projectiles()
	_run.denied_zones.clear()
	_run.player_position = Rules.player_start(_run.current_stage_id)
	_run.boss_arrival_position = (
		_run._active_tactical_layout.boss_arrival_anchors[0]
		if _run.field_layout != null
		else StageCatalog.boss_arrival_anchors(_run.current_stage_id)[0]
	)
	_run.stage_flow.configure(stage_index, 1, true)
	var quota_receipt: Dictionary = _run.stage_flow.record_countable_defeat()
	if (
		not StageFlow.valid_receipt(quota_receipt)
		or StringName(quota_receipt["command"])
			!= StageFlow.COMMAND_BEGIN_BOSS_WARNING
	):
		return null
	var entry_receipt: Dictionary = _run.stage_flow.advance(1.5)
	if (
		not StageFlow.valid_receipt(entry_receipt)
		or StringName(entry_receipt["command"]) != StageFlow.COMMAND_ENTER_BOSS
	):
		return null
	_run._start_stage_boss()
	return _run._find_enemy_by_id("boss_actor")


func complete_current_stage(completion_kind: StringName) -> bool:
	var stage_has_boss := StageCatalog.has_boss(_run.current_stage_id)
	if (
		(completion_kind == TransitionRuntime.COMPLETION_WITHOUT_BOSS and stage_has_boss)
		or (completion_kind == TransitionRuntime.COMPLETION_AFTER_BOSS and not stage_has_boss)
	):
		return false
	if completion_kind == TransitionRuntime.COMPLETION_WITHOUT_BOSS:
		_run.stage_flow.configure(_run.current_stage_index, 1, false)
		var quota_receipt: Dictionary = _run.stage_flow.record_countable_defeat()
		if (
			not StageFlow.valid_receipt(quota_receipt)
			or StringName(quota_receipt["command"])
				!= StageFlow.COMMAND_COMPLETE_WITHOUT_BOSS
		):
			return false
	elif completion_kind == TransitionRuntime.COMPLETION_AFTER_BOSS:
		_run.stage_flow.configure(_run.current_stage_index, 1, true)
		_run.stage_flow.record_countable_defeat()
		_run.stage_flow.advance(1.5)
		var boss_receipt: Dictionary = _run.stage_flow.record_boss_defeat()
		if (
			not StageFlow.valid_receipt(boss_receipt)
			or StringName(boss_receipt["command"])
				!= StageFlow.COMMAND_COMPLETE_AFTER_BOSS
		):
			return false
	else:
		return false
	_run._complete_stage(completion_kind)
	return _run.stage_transition_runtime.active()


func drain_transition(step_count: int) -> void:
	if _run._flush_defeated_enemies() > 0:
		_run.enemy_grid.sync(_run.enemies)
	for _step in maxi(0, step_count):
		_run._physics_serial += 1
		_run._advance_stage_transition()


func campaign_digest() -> Dictionary:
	return {
		"stage_index":_run.current_stage_index,
		"stage_id":_run.current_stage_id,
		"stage_flow":_run.stage_flow.snapshot(),
		"transition":_run.stage_transition_runtime.debug_snapshot(),
		"reward":_run.reward_runtime.campaign_receipt(),
		"completed_report_count":_run.completed_stage_reports.size(),
		"stage_complete":_run.stage_complete,
		"boss_started":_run.boss_started,
		"mode":_run.mode,
	}
