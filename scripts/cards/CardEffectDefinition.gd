class_name CardEffectDefinition
extends Resource

const SUPPORTED_TYPES: Array[StringName] = [
	&"repeat_hit",
	&"spawn_damage_trail",
	&"add_damage",
	&"add_stagger",
	&"reduce_longest_skill_cooldown",
	&"area_damage",
	&"ground_shockwave",
	&"arm_next_heavy",
	&"split_projectile",
	&"delayed_target_strike",
	&"repeat_attack_path",
	&"detonation_mark",
]

@export var effect_type: StringName
@export_range(0, 99, 1) var damage: int = 0
@export_range(0, 999, 1) var stagger: int = 0
@export_range(0.0, 2.0, 0.01) var damage_scale: float = 0.0
@export_range(0.0, 2.0, 0.01) var stagger_scale: float = 0.0
@export_range(0.0, 10.0, 0.01) var delay: float = 0.0
@export_range(0.0, 10.0, 0.01) var duration: float = 0.0
@export_range(0.0, 10.0, 0.01) var seconds: float = 0.0
@export_range(0.0, 1000.0, 1.0) var distance: float = 0.0
@export_range(0.1, 1.0, 0.01) var startup_scale: float = 1.0
@export var damage_by_stack: PackedInt32Array = PackedInt32Array()
@export var radius_by_stack: PackedFloat32Array = PackedFloat32Array()
@export_range(1, 16, 1) var hits_per_target: int = 1
@export_range(1, 16, 1) var projectile_count: int = 1
@export_range(0.0, 90.0, 1.0) var angle_degrees: float = 0.0
@export_range(0, 8, 1) var required_distinct_verbs: int = 0
@export var proc_effects: bool = false
@export var exclude_primary_target: bool = false
@export var uninterruptible_startup: bool = false


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if not SUPPORTED_TYPES.has(effect_type):
		errors.append("Card effect type '%s' is unsupported." % effect_type)
	for value in [damage_scale, stagger_scale, delay, duration, seconds, distance, startup_scale]:
		if not is_finite(value) or value < 0.0:
			errors.append("Card effect '%s' has an invalid numeric value." % effect_type)
			break
	match effect_type:
		&"repeat_hit":
			if delay <= 0.0 or damage_scale <= 0.0 or stagger_scale < 0.0 or proc_effects:
				errors.append("Repeat-hit effect needs delayed non-recursive damage scaling.")
		&"spawn_damage_trail":
			if duration <= 0.0 or damage_by_stack.is_empty() or hits_per_target != 1:
				errors.append("Dash trail needs duration, stack damage, and one hit per target.")
			for stack_damage in damage_by_stack:
				if stack_damage <= 0:
					errors.append("Dash-trail stack damage must be positive.")
					break
		&"add_damage":
			if damage <= 0:
				errors.append("Add-damage effect needs positive damage.")
		&"add_stagger":
			if stagger <= 0:
				errors.append("Add-stagger effect needs positive stagger.")
		&"reduce_longest_skill_cooldown":
			if seconds <= 0.0:
				errors.append("Cooldown reduction needs positive seconds.")
		&"area_damage":
			if damage <= 0 or radius_by_stack.is_empty():
				errors.append("Area damage needs damage and stack radius values.")
			for stack_radius in radius_by_stack:
				if not is_finite(stack_radius) or stack_radius <= 0.0:
					errors.append("Area-damage stack radius must be positive and finite.")
					break
		&"ground_shockwave":
			if damage <= 0 or stagger <= 0 or distance <= 0.0 or duration <= 0.0:
				errors.append("Ground shockwave needs damage, stagger, distance, and duration.")
			if proc_effects:
				errors.append("Ground shockwave must be non-recursive.")
		&"arm_next_heavy":
			if duration <= 0.0 or startup_scale >= 1.0 or not uninterruptible_startup:
				errors.append("Heavy arm effect needs a window, faster startup, and interruption guard.")
		&"split_projectile":
			if damage <= 0 or projectile_count < 2 or angle_degrees <= 0.0 or proc_effects:
				errors.append("Projectile split needs damage, count, angle, and non-recursive output.")
		&"delayed_target_strike":
			if damage <= 0 or delay <= 0.0 or proc_effects:
				errors.append("Delayed target strike needs damage, delay, and non-recursive output.")
		&"repeat_attack_path":
			if damage_scale <= 0.0 or proc_effects:
				errors.append("Attack-path repeat needs non-recursive damage scaling.")
		&"detonation_mark":
			if damage <= 0 or duration <= 0.0 or distance <= 0.0 or required_distinct_verbs <= 0:
				errors.append("Detonation mark needs damage, duration, radius, and verb count.")
	return errors
