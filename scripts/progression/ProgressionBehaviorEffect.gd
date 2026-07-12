class_name ProgressionBehaviorEffect
extends Resource

const SOURCE_SCOPE_EQUIPMENT := "equipment"
const SOURCE_SCOPE_MASTERY := "mastery"
const LIMIT_ONCE_PER_STAGE := &"once_per_stage"

const SUPPORTED_TYPES: Array[StringName] = [
	&"modify_attack",
	&"quick_shot_repeat",
	&"power_shot_max_damage",
	&"twin_cut_second_bleed",
	&"shadow_lunge_distance",
	&"minimum_stat_value",
	&"reduce_first_card_reroll_cost",
	&"first_post_double_jump_attack_stagger",
	&"full_health_encounter_clear_guard",
	&"guard_blocks_projectile",
	&"shield_rush_carries_light_targets",
	&"wall_impact_stagger",
	&"breaker_applies_fractured",
	&"ground_splitter_aftershock",
	&"guard_knockback_scale",
	&"once_per_stage_one_health_guard_and_skill_reset",
	&"post_dash_quick_shot_startup_scale",
	&"full_charge_extra_pierce",
	&"transfer_consumed_mark",
	&"vault_air_control_restore",
	&"rain_final_arrow_bonus",
	&"mark_consume_reduce_longest_skill",
	&"lunge_kill_refund_dash",
	&"smoke_duration",
	&"smoke_slow",
	&"kunai_return_count",
	&"back_hit_flow_stack",
	&"no_damage_death_mark_resets_smoke_step",
]

const PARAMETER_FIELDS: Array[StringName] = [
	&"target_id",
	&"value",
	&"damage",
	&"stagger",
	&"damage_delta",
	&"distance_delta",
	&"delay",
	&"damage_scale",
	&"recovery",
	&"duration",
	&"radius",
	&"seconds",
	&"internal_cooldown",
	&"limit",
]

const ALLOWED_PARAMETERS := {
	&"modify_attack": [&"target_id", &"damage", &"stagger", &"recovery"],
	&"quick_shot_repeat": [&"target_id", &"delay", &"damage_scale"],
	&"power_shot_max_damage": [&"target_id", &"damage_delta"],
	&"twin_cut_second_bleed": [&"target_id", &"damage", &"duration"],
	&"shadow_lunge_distance": [&"target_id", &"distance_delta"],
	&"minimum_stat_value": [&"target_id", &"value"],
	&"reduce_first_card_reroll_cost": [&"value"],
	&"first_post_double_jump_attack_stagger": [&"stagger"],
	&"full_health_encounter_clear_guard": [&"duration", &"limit"],
	&"guard_blocks_projectile": [],
	&"shield_rush_carries_light_targets": [],
	&"wall_impact_stagger": [&"stagger"],
	&"breaker_applies_fractured": [&"damage", &"duration"],
	&"ground_splitter_aftershock": [&"damage"],
	&"guard_knockback_scale": [&"value"],
	&"once_per_stage_one_health_guard_and_skill_reset": [&"target_id", &"limit"],
	&"post_dash_quick_shot_startup_scale": [&"value"],
	&"full_charge_extra_pierce": [&"value"],
	&"transfer_consumed_mark": [&"duration", &"radius"],
	&"vault_air_control_restore": [&"value"],
	&"rain_final_arrow_bonus": [&"damage", &"stagger"],
	&"mark_consume_reduce_longest_skill": [&"seconds", &"internal_cooldown"],
	&"lunge_kill_refund_dash": [&"internal_cooldown"],
	&"smoke_duration": [&"value"],
	&"smoke_slow": [],
	&"kunai_return_count": [&"value"],
	&"back_hit_flow_stack": [&"value"],
	&"no_damage_death_mark_resets_smoke_step": [],
}

const EXPECTED_TARGETS := {
	&"modify_attack": &"warrior_breaker",
	&"quick_shot_repeat": &"archer_quick_shot",
	&"power_shot_max_damage": &"archer_power_shot",
	&"twin_cut_second_bleed": &"assassin_twin_cut",
	&"shadow_lunge_distance": &"assassin_shadow_lunge",
	&"minimum_stat_value": &"max_health",
	&"once_per_stage_one_health_guard_and_skill_reset": &"warrior_shield_rush",
}

const EQUIPMENT_ONLY_TYPES: Array[StringName] = [
	&"modify_attack",
	&"quick_shot_repeat",
	&"power_shot_max_damage",
	&"shadow_lunge_distance",
	&"minimum_stat_value",
	&"reduce_first_card_reroll_cost",
	&"first_post_double_jump_attack_stagger",
	&"full_health_encounter_clear_guard",
]

const MASTERY_ONLY_TYPES: Array[StringName] = [
	&"guard_blocks_projectile",
	&"shield_rush_carries_light_targets",
	&"wall_impact_stagger",
	&"breaker_applies_fractured",
	&"ground_splitter_aftershock",
	&"guard_knockback_scale",
	&"once_per_stage_one_health_guard_and_skill_reset",
	&"post_dash_quick_shot_startup_scale",
	&"full_charge_extra_pierce",
	&"transfer_consumed_mark",
	&"vault_air_control_restore",
	&"rain_final_arrow_bonus",
	&"mark_consume_reduce_longest_skill",
	&"lunge_kill_refund_dash",
	&"smoke_duration",
	&"smoke_slow",
	&"kunai_return_count",
	&"back_hit_flow_stack",
	&"no_damage_death_mark_resets_smoke_step",
]

@export var effect_type: StringName
@export var source_id: StringName
@export_enum("equipment", "mastery") var source_scope: String = SOURCE_SCOPE_EQUIPMENT
@export var target_id: StringName
@export var value: float = 0.0
@export var damage: int = 0
@export var stagger: int = 0
@export var damage_delta: int = 0
@export var distance_delta: float = 0.0
@export var delay: float = 0.0
@export var damage_scale: float = 0.0
@export var recovery: float = 0.0
@export var duration: float = 0.0
@export var radius: float = 0.0
@export var seconds: float = 0.0
@export var internal_cooldown: float = 0.0
@export var limit: StringName


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if not SUPPORTED_TYPES.has(effect_type):
		errors.append("Progression behavior effect type '%s' is unsupported." % effect_type)
		return errors
	ContentId.validate(errors, "Progression behavior source ID", source_id)
	if source_scope not in [SOURCE_SCOPE_EQUIPMENT, SOURCE_SCOPE_MASTERY]:
		errors.append("Progression behavior effect '%s' has invalid source scope '%s'." % [effect_type, source_scope])
	if EQUIPMENT_ONLY_TYPES.has(effect_type) and source_scope != SOURCE_SCOPE_EQUIPMENT:
		errors.append("Progression behavior effect '%s' is equipment-only." % effect_type)
	if MASTERY_ONLY_TYPES.has(effect_type) and source_scope != SOURCE_SCOPE_MASTERY:
		errors.append("Progression behavior effect '%s' is mastery-only." % effect_type)

	for numeric_value in [value, distance_delta, delay, damage_scale, recovery, duration, radius, seconds, internal_cooldown]:
		if not is_finite(numeric_value):
			errors.append("Progression behavior effect '%s' has a non-finite numeric value." % effect_type)
			break
	for nonnegative_value in [delay, damage_scale, recovery, duration, radius, seconds, internal_cooldown]:
		if nonnegative_value < 0.0:
			errors.append("Progression behavior effect '%s' has a negative bounded value." % effect_type)
			break
	if damage < 0 or stagger < 0:
		errors.append("Progression behavior effect '%s' has negative damage or stagger." % effect_type)

	var allowed: Array = ALLOWED_PARAMETERS[effect_type]
	for field_name in PARAMETER_FIELDS:
		if not allowed.has(field_name) and _parameter_is_set(field_name):
			errors.append("Progression behavior effect '%s' does not use '%s'." % [effect_type, field_name])

	if EXPECTED_TARGETS.has(effect_type):
		var expected_target: StringName = EXPECTED_TARGETS[effect_type]
		if target_id != expected_target:
			errors.append("Progression behavior effect '%s' must target '%s'." % [effect_type, expected_target])
	elif not target_id.is_empty():
		ContentId.validate(errors, "Progression behavior target ID", target_id)
	if not limit.is_empty() and limit != LIMIT_ONCE_PER_STAGE:
		errors.append("Progression behavior effect '%s' has unsupported limit '%s'." % [effect_type, limit])

	_validate_required_values(errors)
	return errors


func _validate_required_values(errors: PackedStringArray) -> void:
	match effect_type:
		&"modify_attack":
			_require(errors, damage > 0 and stagger > 0 and recovery > 0.0)
		&"quick_shot_repeat":
			_require(errors, delay > 0.0 and damage_scale > 0.0)
		&"power_shot_max_damage":
			_require(errors, damage_delta != 0)
		&"twin_cut_second_bleed":
			_require(errors, damage > 0 and (source_scope != SOURCE_SCOPE_MASTERY or duration > 0.0))
		&"shadow_lunge_distance":
			_require(errors, not is_zero_approx(distance_delta))
		&"minimum_stat_value", &"reduce_first_card_reroll_cost", &"guard_knockback_scale", \
		&"post_dash_quick_shot_startup_scale", &"full_charge_extra_pierce", \
		&"vault_air_control_restore", &"smoke_duration", &"kunai_return_count", \
		&"back_hit_flow_stack":
			_require(errors, value > 0.0)
		&"first_post_double_jump_attack_stagger", &"wall_impact_stagger":
			_require(errors, stagger > 0)
		&"full_health_encounter_clear_guard":
			_require(errors, duration > 0.0 and limit == LIMIT_ONCE_PER_STAGE)
		&"breaker_applies_fractured":
			_require(errors, duration > 0.0 and damage > 0)
		&"ground_splitter_aftershock":
			_require(errors, damage > 0)
		&"once_per_stage_one_health_guard_and_skill_reset":
			_require(errors, limit == LIMIT_ONCE_PER_STAGE)
		&"transfer_consumed_mark":
			_require(errors, duration > 0.0 and radius > 0.0)
		&"rain_final_arrow_bonus":
			_require(errors, damage > 0 and stagger > 0)
		&"mark_consume_reduce_longest_skill":
			_require(errors, seconds > 0.0 and internal_cooldown > 0.0)
		&"lunge_kill_refund_dash":
			_require(errors, internal_cooldown > 0.0)


func _require(errors: PackedStringArray, condition: bool) -> void:
	if not condition:
		errors.append("Progression behavior effect '%s' is missing required positive parameters." % effect_type)


func _parameter_is_set(field_name: StringName) -> bool:
	match field_name:
		&"target_id":
			return not target_id.is_empty()
		&"limit":
			return not limit.is_empty()
		&"damage":
			return damage != 0
		&"stagger":
			return stagger != 0
		&"damage_delta":
			return damage_delta != 0
		_:
			return not is_zero_approx(float(get(field_name)))
