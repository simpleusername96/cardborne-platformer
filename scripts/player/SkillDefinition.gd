class_name SkillDefinition
extends AttackDefinition

const EXECUTION_DIRECT := &"direct"
const EXECUTION_GROUND_SHOCKWAVE := &"ground_shockwave"
const EXECUTION_SELF_BUFF := &"self_buff"
const EXECUTION_MODES: Array[StringName] = [
	EXECUTION_DIRECT,
	EXECUTION_GROUND_SHOCKWAVE,
	EXECUTION_SELF_BUFF,
]

@export_range(1, 3, 1) var skill_slot: int = 1
@export_range(0.0, 2000.0, 1.0) var movement_distance: float = 0.0
@export var frontal_guard_during_active: bool = false
@export_range(1, 16, 1) var max_targets: int = 1
@export var execution_mode: StringName = EXECUTION_DIRECT
@export_range(0.0, 1000.0, 1.0) var effect_distance: float = 0.0
@export_range(8.0, 80.0, 1.0) var ground_probe_depth: float = 30.0
@export var launch_light_targets: bool = false

@export_group("Self Buff")
@export var grants_guard: bool = false
@export_range(0.0, 20.0, 0.05) var heavy_empower_window: float = 0.0
@export_range(0.1, 1.0, 0.01) var heavy_startup_scale: float = 1.0
@export_range(0.0, 1.0, 0.05) var heavy_echo_damage_scale: float = 0.0


func validate_definition() -> PackedStringArray:
	var errors := super.validate_definition()
	if skill_slot < 1 or skill_slot > 3:
		errors.append("Skill '%s' slot must be between 1 and 3." % id)
	if movement_distance < 0.0:
		errors.append("Skill '%s' movement distance cannot be negative." % id)
	if max_targets <= 0:
		errors.append("Skill '%s' needs a positive target cap." % id)
	if not EXECUTION_MODES.has(execution_mode):
		errors.append("Skill '%s' uses unsupported execution mode '%s'." % [id, execution_mode])
	if execution_mode == EXECUTION_GROUND_SHOCKWAVE:
		if effect_distance <= 0.0 or active_time <= 0.0:
			errors.append("Ground shockwave skill '%s' needs distance and active travel time." % id)
		if movement_distance > 0.0:
			errors.append("Ground shockwave skill '%s' cannot also move the player." % id)
	if execution_mode == EXECUTION_SELF_BUFF:
		if base_damage != 0 or stagger != 0 or not is_zero_approx(active_time):
			errors.append("Self-buff skill '%s' must use an instant, non-damaging active phase." % id)
		if not grants_guard and heavy_empower_window <= 0.0:
			errors.append("Self-buff skill '%s' needs at least one declared buff." % id)
	if heavy_empower_window > 0.0:
		if heavy_startup_scale >= 1.0 or heavy_echo_damage_scale <= 0.0:
			errors.append("Skill '%s' needs a faster Heavy scale and positive echo scale." % id)
	elif heavy_startup_scale < 1.0 or heavy_echo_damage_scale > 0.0:
		errors.append("Skill '%s' cannot define Heavy modifiers without an empower window." % id)
	if launch_light_targets and execution_mode != EXECUTION_GROUND_SHOCKWAVE:
		errors.append("Skill '%s' can launch light targets only as a ground shockwave." % id)
	return errors
