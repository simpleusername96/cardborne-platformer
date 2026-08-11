class_name VehicleBossPracticeSession
extends RefCounted

## Debug-only, rewardless owner for deterministic production-boss QA.

const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")

var active := false
var stage_id: StringName = &"stage_1"
var field_id: StringName = &"drowned_ruin_field"
var phase := 1
var pattern := "full"
var invulnerable := false
var loop_wait := 0.0


func configure(request: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var requested_stage := StringName(request.get("stage_id", &"stage_1"))
	var requested_field := StringName(request.get("field_id", &"drowned_ruin_field"))
	var requested_phase := int(request.get("phase", 1))
	var requested_pattern := String(request.get("pattern", "full"))
	if requested_stage not in StageCatalog.STAGE_IDS:
		errors.append("unknown practice stage: %s" % requested_stage)
	if requested_field not in FieldRegistry.FIELD_IDS:
		errors.append("unknown practice field: %s" % requested_field)
	if requested_phase < 1 or requested_phase > 3:
		errors.append("unknown practice phase: %d" % requested_phase)
	if (
		requested_pattern != "full"
		and not Patterns.PATTERNS.has(StringName(requested_pattern))
	):
		errors.append("unknown practice pattern: %s" % requested_pattern)
	if not errors.is_empty():
		active = false
		return errors
	stage_id = requested_stage
	field_id = requested_field
	phase = requested_phase
	pattern = requested_pattern
	invulnerable = bool(request.get("invulnerable", false))
	active = true
	loop_wait = 0.0
	return errors


func is_pattern_loop() -> bool:
	return active and pattern != "full"


func stop() -> void:
	active = false
	loop_wait = 0.0


func health_ratio() -> float:
	return [0.80, 0.50, 0.20][clampi(phase - 1, 0, 2)]


func snapshot() -> Dictionary:
	return {
		"active":active,
		"stage_id":stage_id,
		"field_id":field_id,
		"phase":phase,
		"pattern":pattern,
		"invulnerable":invulnerable,
		"rewards_enabled":false,
		"persistence_enabled":false,
	}
