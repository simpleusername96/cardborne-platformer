class_name SkillDefinition
extends AttackDefinition

const EXECUTION_DIRECT := &"direct"
const EXECUTION_GROUND_SHOCKWAVE := &"ground_shockwave"
const EXECUTION_SELF_BUFF := &"self_buff"
const EXECUTION_PROJECTILE_FAN := &"projectile_fan"
const EXECUTION_AREA_BARRAGE := &"area_barrage"
const EXECUTION_TETHER := &"tether"
const EXECUTION_DECOY_STEP := &"decoy_step"
const EXECUTION_TARGET_MARK := &"target_mark"
const EXECUTION_MODES: Array[StringName] = [
	EXECUTION_DIRECT,
	EXECUTION_GROUND_SHOCKWAVE,
	EXECUTION_SELF_BUFF,
	EXECUTION_PROJECTILE_FAN,
	EXECUTION_AREA_BARRAGE,
	EXECUTION_TETHER,
	EXECUTION_DECOY_STEP,
	EXECUTION_TARGET_MARK,
]

@export_range(1, 3, 1) var skill_slot: int = 1
@export_range(0.0, 2000.0, 1.0) var movement_distance: float = 0.0
@export var frontal_guard_during_active: bool = false
@export_range(1, 16, 1) var max_targets: int = 1
@export var execution_mode: StringName = EXECUTION_DIRECT
@export_range(0.0, 1000.0, 1.0) var effect_distance: float = 0.0
@export_range(8.0, 80.0, 1.0) var ground_probe_depth: float = 30.0
@export var launch_light_targets: bool = false

@export_group("Pattern")
@export_range(1, 16, 1) var projectile_count: int = 1
@export var projectile_angles: PackedFloat32Array = PackedFloat32Array()
@export_range(0.0, 2.0, 0.01) var projectile_interval: float = 0.0
@export_range(0.0, 3.0, 0.01) var warning_time: float = 0.0
@export_range(0.0, 1000.0, 1.0) var effect_radius: float = 0.0
@export_range(1, 16, 1) var per_target_hit_cap: int = 1

@export_group("Control")
@export_range(0.0, 20.0, 0.05) var status_duration: float = 0.0
@export_range(0.0, 20.0, 0.05) var decoy_duration: float = 0.0
@export_range(0.0, 1000.0, 1.0) var pull_distance: float = 0.0
@export_range(0.0, 1000.0, 1.0) var targeting_range: float = 0.0
@export_range(0.0, 5.0, 0.01) var invulnerability_time: float = 0.0
@export_range(0, 8, 1) var required_distinct_verbs: int = 0

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
	if execution_mode == EXECUTION_PROJECTILE_FAN:
		if (
			projectile_count < 2
			or projectile_angles.size() != projectile_count
			or projectile_speed <= 0.0
			or projectile_range <= 0.0
		):
			errors.append("Projectile fan skill '%s' needs a complete projectile pattern." % id)
	if execution_mode == EXECUTION_AREA_BARRAGE:
		if (
			projectile_count < 2
			or warning_time <= 0.0
			or effect_radius <= 0.0
			or per_target_hit_cap <= 0
		):
			errors.append("Area barrage skill '%s' needs warning, area, and hit-cap data." % id)
	if execution_mode == EXECUTION_TETHER:
		if pull_distance <= 0.0 or targeting_range <= 0.0:
			errors.append("Tether skill '%s' needs targeting range and pull distance." % id)
	if execution_mode == EXECUTION_DECOY_STEP:
		if movement_distance <= 0.0 or decoy_duration <= 0.0 or invulnerability_time <= 0.0:
			errors.append("Decoy-step skill '%s' needs movement, decoy, and invulnerability data." % id)
	if execution_mode == EXECUTION_TARGET_MARK:
		if status_duration <= 0.0 or targeting_range <= 0.0 or required_distinct_verbs <= 0:
			errors.append("Target-mark skill '%s' needs range, duration, and verb count." % id)
	return errors
