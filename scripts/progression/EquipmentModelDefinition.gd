class_name EquipmentModelDefinition
extends Resource

const SLOT_MELEE := &"melee"
const SLOT_RANGED := &"ranged"
const SLOT_SHIELD := &"shield"
const SLOT_ARMOR := &"armor"
const SLOTS: Array[StringName] = [SLOT_MELEE, SLOT_RANGED, SLOT_SHIELD, SLOT_ARMOR]
const GRADE_ONE_MAX_CONDITION := 100

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var presentation_key: StringName
@export var slot: StringName
@export_multiline var behavior_description: String
@export_multiline var weakness_description: String

@export_group("Attack Tuning")
@export var attack_definition: AttackDefinition
@export var damage: int = 0
@export var stagger_damage: int = 0
@export var reach: float = 0.0
@export var startup_seconds: float = 0.0
@export var recovery_seconds: float = 0.0

@export_group("Melee Tuning")
@export var combo_finisher_hit: int = 0
@export var combo_finisher_width_multiplier: float = 1.0
@export var close_range_penalty_distance: float = 0.0
@export var tip_reward_length: float = 0.0

@export_group("Ranged Tuning")
@export var ranged_resource_id: StringName
@export var starting_ranged_resource: int = 0
@export var maximum_ranged_resource: int = 0
@export var reload_seconds: float = 0.0
@export var dash_cancels_reload: bool = false

@export_group("Shield Tuning")
@export var guard_stability: int = 0
@export var guard_angle_degrees: float = 0.0
# Zero preserves an unspecified model-specific window; it does not add a runtime policy.
@export var precise_guard_window_seconds: float = 0.0
@export var guard_move_speed_multiplier: float = 1.0
@export var blocks_jump_while_guarding: bool = false
@export var normal_block_condition_cost: int = 0
@export var heavy_block_condition_cost: int = 0
@export var precise_block_condition_cost: int = 0

@export_group("Condition")
@export var has_condition: bool = false
@export var grade_one_max_condition: int = 0

@export_group("Armor Tuning")
@export var max_health_bonus: int = 0
@export var knockback_reduction_fraction: float = 0.0
@export var dash_cooldown_addition_seconds: float = 0.0


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Equipment model ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Equipment model '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Equipment model '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Equipment model '%s' tag" % id, tags, true)
	ContentId.validate(errors, "Equipment model '%s' presentation key" % id, presentation_key)
	if slot not in SLOTS:
		errors.append("Equipment model '%s' has unsupported slot '%s'." % [id, slot])
	if not tags.has(&"equipment_model"):
		errors.append("Equipment model '%s' needs the equipment_model tag." % id)
	if slot in SLOTS and not tags.has(slot):
		errors.append("Equipment model '%s' needs its slot tag '%s'." % [id, slot])
	if behavior_description.strip_edges().is_empty():
		errors.append("Equipment model '%s' needs a behavior description." % id)
	if weakness_description.strip_edges().is_empty():
		errors.append("Equipment model '%s' needs an explicit weakness." % id)
	_validate_common_values(errors)

	match slot:
		SLOT_MELEE:
			_validate_melee(errors)
		SLOT_RANGED:
			_validate_ranged(errors)
		SLOT_SHIELD:
			_validate_shield(errors)
		SLOT_ARMOR:
			_validate_armor(errors)
	return errors


func tuning_snapshot() -> Dictionary:
	return {
		"damage": damage,
		"stagger_damage": stagger_damage,
		"reach": reach,
		"startup_seconds": startup_seconds,
		"recovery_seconds": recovery_seconds,
		"combo_finisher_hit": combo_finisher_hit,
		"combo_finisher_width_multiplier": combo_finisher_width_multiplier,
		"close_range_penalty_distance": close_range_penalty_distance,
		"tip_reward_length": tip_reward_length,
		"ranged_resource_id": ranged_resource_id,
		"starting_ranged_resource": starting_ranged_resource,
		"maximum_ranged_resource": maximum_ranged_resource,
		"reload_seconds": reload_seconds,
		"dash_cancels_reload": dash_cancels_reload,
		"guard_stability": guard_stability,
		"guard_angle_degrees": guard_angle_degrees,
		"precise_guard_window_seconds": precise_guard_window_seconds,
		"guard_move_speed_multiplier": guard_move_speed_multiplier,
		"blocks_jump_while_guarding": blocks_jump_while_guarding,
		"normal_block_condition_cost": normal_block_condition_cost,
		"heavy_block_condition_cost": heavy_block_condition_cost,
		"precise_block_condition_cost": precise_block_condition_cost,
		"has_condition": has_condition,
		"grade_one_max_condition": grade_one_max_condition,
		"max_health_bonus": max_health_bonus,
		"knockback_reduction_fraction": knockback_reduction_fraction,
		"dash_cooldown_addition_seconds": dash_cooldown_addition_seconds,
	}


func _validate_common_values(errors: PackedStringArray) -> void:
	if damage < 0 or stagger_damage < 0:
		errors.append("Equipment model '%s' damage values cannot be negative." % id)
	if starting_ranged_resource < 0 or maximum_ranged_resource < 0:
		errors.append("Equipment model '%s' ranged resource values cannot be negative." % id)
	if grade_one_max_condition < 0:
		errors.append("Equipment model '%s' condition cannot be negative." % id)
	if (
		normal_block_condition_cost < 0
		or heavy_block_condition_cost < 0
		or precise_block_condition_cost < 0
	):
		errors.append("Equipment model '%s' block condition costs cannot be negative." % id)
	if max_health_bonus < 0:
		errors.append("Equipment model '%s' max-health bonus cannot be negative." % id)
	for value in [
		reach,
		startup_seconds,
		recovery_seconds,
		combo_finisher_width_multiplier,
		close_range_penalty_distance,
		tip_reward_length,
		reload_seconds,
		guard_angle_degrees,
		precise_guard_window_seconds,
		guard_move_speed_multiplier,
		knockback_reduction_fraction,
		dash_cooldown_addition_seconds,
	]:
		if not is_finite(value) or value < 0.0:
			errors.append("Equipment model '%s' has a non-finite or negative tuning value." % id)
			break
	if combo_finisher_width_multiplier < 1.0:
		errors.append("Equipment model '%s' combo width multiplier cannot be below 1." % id)
	if guard_move_speed_multiplier <= 0.0 or guard_move_speed_multiplier > 1.0:
		errors.append("Equipment model '%s' guard movement multiplier must be above 0 and at most 1." % id)
	if knockback_reduction_fraction >= 1.0:
		errors.append("Equipment model '%s' knockback reduction must be below 1." % id)


func _validate_melee(errors: PackedStringArray) -> void:
	_validate_positive_attack(errors)
	_validate_attack_reference(errors, false)
	if recovery_seconds <= 0.0:
		errors.append("Melee model '%s' needs positive recovery." % id)
	if not has_condition or grade_one_max_condition != GRADE_ONE_MAX_CONDITION:
		errors.append("Melee model '%s' needs Grade 1 condition 100." % id)
	if _has_ranged_tuning() or _has_guard_tuning() or _has_armor_tuning():
		errors.append("Melee model '%s' contains tuning owned by another slot." % id)
	if combo_finisher_hit == 0 and not is_equal_approx(combo_finisher_width_multiplier, 1.0):
		errors.append("Melee model '%s' has a combo multiplier without a finisher hit." % id)
	if combo_finisher_hit > 0 and combo_finisher_width_multiplier <= 1.0:
		errors.append("Melee model '%s' finisher needs a width increase." % id)
	if combo_finisher_hit < 0:
		errors.append("Melee model '%s' combo finisher hit cannot be negative." % id)
	if (close_range_penalty_distance > 0.0) != (tip_reward_length > 0.0):
		errors.append("Melee model '%s' needs both close-penalty and tip-reward distances." % id)
	if close_range_penalty_distance >= reach or tip_reward_length > reach:
		errors.append("Melee model '%s' range modifiers must fit inside its reach." % id)


func _validate_ranged(errors: PackedStringArray) -> void:
	_validate_positive_attack(errors)
	_validate_attack_reference(errors, true)
	ContentId.validate(errors, "Ranged model '%s' resource ID" % id, ranged_resource_id)
	if starting_ranged_resource <= 0 or maximum_ranged_resource < starting_ranged_resource:
		errors.append("Ranged model '%s' needs valid positive starting/max resources." % id)
	if recovery_seconds <= 0.0 and reload_seconds <= 0.0:
		errors.append("Ranged model '%s' needs positive recovery or reload." % id)
	if dash_cancels_reload and reload_seconds <= 0.0:
		errors.append("Ranged model '%s' cannot cancel a nonexistent reload." % id)
	if has_condition or grade_one_max_condition != 0:
		errors.append("Ranged model '%s' cannot own equipment condition." % id)
	if _has_melee_tuning() or _has_guard_tuning() or _has_armor_tuning():
		errors.append("Ranged model '%s' contains tuning owned by another slot." % id)


func _validate_shield(errors: PackedStringArray) -> void:
	if attack_definition != null:
		errors.append("Shield model '%s' cannot reference an attack definition." % id)
	if damage != 0 or stagger_damage != 0 or not is_zero_approx(reach):
		errors.append("Shield model '%s' cannot contain attack damage or reach." % id)
	if startup_seconds <= 0.0 or recovery_seconds <= 0.0:
		errors.append("Shield model '%s' needs positive raise and lower timing." % id)
	if guard_stability <= 0 or guard_angle_degrees <= 0.0 or guard_angle_degrees > 180.0:
		errors.append("Shield model '%s' needs valid stability and a frontal guard angle." % id)
	if not has_condition or grade_one_max_condition != GRADE_ONE_MAX_CONDITION:
		errors.append("Shield model '%s' needs Grade 1 condition 100." % id)
	if normal_block_condition_cost <= 0 or heavy_block_condition_cost <= 0:
		errors.append("Shield model '%s' needs positive normal and heavy condition costs." % id)
	if precise_block_condition_cost != 0:
		errors.append("Shield model '%s' precise guard cannot consume condition." % id)
	if _has_melee_tuning() or _has_ranged_tuning() or _has_armor_tuning():
		errors.append("Shield model '%s' contains tuning owned by another slot." % id)


func _validate_armor(errors: PackedStringArray) -> void:
	if attack_definition != null:
		errors.append("Armor model '%s' cannot reference an attack definition." % id)
	if (
		damage != 0
		or stagger_damage != 0
		or not is_zero_approx(reach)
		or not is_zero_approx(startup_seconds)
		or not is_zero_approx(recovery_seconds)
	):
		errors.append("Armor model '%s' cannot contain attack or guard timing." % id)
	if has_condition or grade_one_max_condition != 0:
		errors.append("Armor model '%s' cannot own equipment condition." % id)
	if _has_melee_tuning() or _has_ranged_tuning() or _has_guard_tuning():
		errors.append("Armor model '%s' contains tuning owned by another slot." % id)


func _validate_positive_attack(errors: PackedStringArray) -> void:
	if damage <= 0 or stagger_damage <= 0 or reach <= 0.0 or startup_seconds <= 0.0:
		errors.append("Attack model '%s' needs positive damage, stagger, reach, and startup." % id)


func _validate_attack_reference(errors: PackedStringArray, ranged: bool) -> void:
	if attack_definition == null:
		errors.append("Attack model '%s' needs an attack definition." % id)
		return
	for attack_error in attack_definition.validate_definition():
		errors.append("Attack model '%s': %s" % [id, attack_error])
	var expected_recovery := reload_seconds if ranged and recovery_seconds <= 0.0 else recovery_seconds
	if (
		attack_definition.base_damage != damage
		or attack_definition.stagger != stagger_damage
		or not is_equal_approx(attack_definition.startup_time, startup_seconds)
		or not is_equal_approx(attack_definition.recovery_time, expected_recovery)
	):
		errors.append("Attack model '%s' display tuning differs from its attack definition." % id)
	var definition_reach := (
		attack_definition.projectile_range
		if ranged
		else absf(attack_definition.hitbox_offset.x) + attack_definition.hitbox_size.x * 0.5
	)
	if not is_equal_approx(definition_reach, reach):
		errors.append("Attack model '%s' reach differs from its attack definition." % id)
	if ranged != (attack_definition.projectile_range > 0.0):
		errors.append("Attack model '%s' has the wrong melee/ranged attack contract." % id)


func _has_melee_tuning() -> bool:
	return (
		combo_finisher_hit != 0
		or not is_equal_approx(combo_finisher_width_multiplier, 1.0)
		or not is_zero_approx(close_range_penalty_distance)
		or not is_zero_approx(tip_reward_length)
	)


func _has_ranged_tuning() -> bool:
	return (
		ranged_resource_id != &""
		or starting_ranged_resource != 0
		or maximum_ranged_resource != 0
		or not is_zero_approx(reload_seconds)
		or dash_cancels_reload
	)


func _has_guard_tuning() -> bool:
	return (
		guard_stability != 0
		or not is_zero_approx(guard_angle_degrees)
		or not is_zero_approx(precise_guard_window_seconds)
		or not is_equal_approx(guard_move_speed_multiplier, 1.0)
		or blocks_jump_while_guarding
		or normal_block_condition_cost != 0
		or heavy_block_condition_cost != 0
		or precise_block_condition_cost != 0
	)


func _has_armor_tuning() -> bool:
	return (
		max_health_bonus != 0
		or not is_zero_approx(knockback_reduction_fraction)
		or not is_zero_approx(dash_cooldown_addition_seconds)
	)
