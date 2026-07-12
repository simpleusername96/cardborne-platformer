class_name EnemyTuningProfile
extends Resource

const NORMAL_DAMAGE := 1
const FLOAT_TOLERANCE := 0.0001

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var stage_id: StringName

@export_group("Authored Ratio Bounds")
@export var minimum_health_ratio: float = 1.0
@export var maximum_health_ratio: float = 1.0
@export var minimum_warning_ratio: float = 1.0
@export var maximum_warning_ratio: float = 1.0
@export var minimum_active_ratio: float = 1.0
@export var maximum_active_ratio: float = 1.0
@export var minimum_recovery_ratio: float = 1.0
@export var maximum_recovery_ratio: float = 1.0
@export var minimum_cadence_ratio: float = 1.0
@export var maximum_cadence_ratio: float = 1.0
@export var minimum_speed_or_range_ratio: float = 1.0
@export var maximum_speed_or_range_ratio: float = 1.0
@export var maximum_stagger_capacity_ratio: float = 1.0
@export var allowed_damage: Array[int] = [NORMAL_DAMAGE]


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Enemy tuning profile ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Enemy tuning profile '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Enemy tuning profile '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Enemy tuning profile '%s' tag" % id, tags, true)
	ContentId.validate(errors, "Enemy tuning profile '%s' stage ID" % id, stage_id)

	_validate_ratio_bounds(errors, "health", minimum_health_ratio, maximum_health_ratio)
	_validate_ratio_bounds(errors, "warning", minimum_warning_ratio, maximum_warning_ratio)
	_validate_ratio_bounds(errors, "active", minimum_active_ratio, maximum_active_ratio)
	_validate_ratio_bounds(errors, "recovery", minimum_recovery_ratio, maximum_recovery_ratio)
	_validate_ratio_bounds(errors, "cadence", minimum_cadence_ratio, maximum_cadence_ratio)
	_validate_ratio_bounds(
		errors,
		"speed or range",
		minimum_speed_or_range_ratio,
		maximum_speed_or_range_ratio
	)
	if not is_finite(maximum_stagger_capacity_ratio) or maximum_stagger_capacity_ratio <= 0.0:
		errors.append(
			"Enemy tuning profile '%s' maximum stagger capacity ratio must be finite and positive."
			% id
		)

	if allowed_damage.is_empty():
		errors.append("Enemy tuning profile '%s' needs at least one allowed damage value." % id)
	var seen_damage: Dictionary = {}
	for damage_value in allowed_damage:
		if damage_value != NORMAL_DAMAGE:
			errors.append(
				"Enemy tuning profile '%s' damage value must be exactly %d."
				% [id, NORMAL_DAMAGE]
			)
		if seen_damage.has(damage_value):
			errors.append("Enemy tuning profile '%s' repeats damage value %d." % [id, damage_value])
		seen_damage[damage_value] = true

	return errors


# Ratios are validation-only. This method never transforms the variant's exact values.
func validate_authored_variant(
	archetype: EnemyArchetypeDefinition,
	variant: EnemyVariantDefinition
) -> PackedStringArray:
	var errors := PackedStringArray()
	if archetype == null or variant == null:
		errors.append("Enemy tuning profile '%s' cannot validate null definitions." % id)
		return errors
	if variant.archetype_id != archetype.id:
		errors.append(
			"Enemy variant '%s' belongs to archetype '%s', not supplied archetype '%s'."
			% [variant.id, variant.archetype_id, archetype.id]
		)
	if variant.tuning_profile_id != id:
		errors.append(
			"Enemy variant '%s' references tuning profile '%s', not '%s'."
			% [variant.id, variant.tuning_profile_id, id]
		)
	if variant.stage_id != stage_id:
		errors.append(
			"Enemy variant '%s' stage '%s' does not match tuning stage '%s'."
			% [variant.id, variant.stage_id, stage_id]
		)

	_append_ratio_error(
		errors,
		variant.id,
		"health",
		float(variant.health),
		float(archetype.reference_health),
		minimum_health_ratio,
		maximum_health_ratio
	)
	_append_optional_ratio_error(
		errors,
		variant.id,
		"warning",
		variant.warning_time,
		archetype.reference_warning_time,
		minimum_warning_ratio,
		maximum_warning_ratio
	)
	_append_optional_ratio_error(
		errors,
		variant.id,
		"active",
		variant.active_time,
		archetype.reference_active_time,
		minimum_active_ratio,
		maximum_active_ratio
	)
	_append_optional_ratio_error(
		errors,
		variant.id,
		"recovery",
		variant.recovery_time,
		archetype.reference_recovery_time,
		minimum_recovery_ratio,
		maximum_recovery_ratio
	)
	_append_optional_ratio_error(
		errors,
		variant.id,
		"move speed",
		variant.move_speed,
		archetype.reference_move_speed,
		minimum_speed_or_range_ratio,
		maximum_speed_or_range_ratio
	)
	_append_optional_ratio_error(
		errors,
		variant.id,
		"charge speed",
		variant.charge_speed,
		archetype.reference_charge_speed,
		minimum_speed_or_range_ratio,
		maximum_speed_or_range_ratio
	)

	if archetype.reference_stagger_capacity <= 0:
		errors.append("Enemy archetype '%s' has no valid stagger reference." % archetype.id)
	else:
		var stagger_ratio := (
			float(variant.stagger_capacity) / float(archetype.reference_stagger_capacity)
		)
		if stagger_ratio > maximum_stagger_capacity_ratio + FLOAT_TOLERANCE:
			errors.append(
				"Enemy variant '%s' stagger capacity ratio %.3f exceeds maximum %.3f."
				% [variant.id, stagger_ratio, maximum_stagger_capacity_ratio]
			)

	if not allowed_damage.has(variant.damage):
		errors.append(
			"Enemy variant '%s' damage %d is not allowed by tuning profile '%s'."
			% [variant.id, variant.damage, id]
		)
	return errors


func _append_optional_ratio_error(
	errors: PackedStringArray,
	variant_id: StringName,
	label: String,
	exact_value: float,
	reference_value: float,
	minimum_ratio: float,
	maximum_ratio: float
) -> void:
	if is_zero_approx(exact_value) and is_zero_approx(reference_value):
		return
	if exact_value <= 0.0 or reference_value <= 0.0:
		errors.append(
			"Enemy variant '%s' %s and its archetype reference must both be positive when authored."
			% [variant_id, label]
		)
		return
	_append_ratio_error(
		errors,
		variant_id,
		label,
		exact_value,
		reference_value,
		minimum_ratio,
		maximum_ratio
	)


func _append_ratio_error(
	errors: PackedStringArray,
	variant_id: StringName,
	label: String,
	exact_value: float,
	reference_value: float,
	minimum_ratio: float,
	maximum_ratio: float
) -> void:
	if not is_finite(exact_value) or not is_finite(reference_value) or reference_value <= 0.0:
		errors.append("Enemy variant '%s' %s ratio cannot be evaluated." % [variant_id, label])
		return
	var ratio := exact_value / reference_value
	if ratio < minimum_ratio - FLOAT_TOLERANCE or ratio > maximum_ratio + FLOAT_TOLERANCE:
		errors.append(
			"Enemy variant '%s' %s ratio %.3f is outside %.3f-%.3f."
			% [variant_id, label, ratio, minimum_ratio, maximum_ratio]
		)


func _validate_ratio_bounds(
	errors: PackedStringArray,
	label: String,
	minimum_ratio: float,
	maximum_ratio: float
) -> void:
	if (
		not is_finite(minimum_ratio)
		or not is_finite(maximum_ratio)
		or minimum_ratio <= 0.0
		or maximum_ratio <= 0.0
		or minimum_ratio > maximum_ratio
	):
		errors.append(
			"Enemy tuning profile '%s' %s ratio bounds must be finite, positive, and ordered."
			% [id, label]
		)
