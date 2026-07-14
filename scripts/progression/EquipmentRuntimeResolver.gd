class_name EquipmentRuntimeResolver
extends RefCounted

const GRADE_ONE := &"grade_1"
const GRADE_TWO := &"grade_2"
const WORN_MULTIPLIER := 0.85
const WORN_RECOVERY_MULTIPLIER := 1.10


static func resolve(
	model: EquipmentModelDefinition,
	crafted_state: Dictionary
) -> Dictionary:
	if model == null:
		return _invalid(&"missing_model", "Equipment model is unavailable.")
	var grade_id := StringName(str(crafted_state.get("grade_id", "")))
	if grade_id not in [GRADE_ONE, GRADE_TWO]:
		return _invalid(&"invalid_grade", "Equipment grade is unsupported.")

	var grade_two := grade_id == GRADE_TWO
	var maximum_condition := maximum_condition_for(model, grade_id)
	var condition := 0.0
	if model.has_condition:
		var raw_condition: Variant = crafted_state.get("condition", maximum_condition)
		if not (raw_condition is int or raw_condition is float):
			return _invalid(&"invalid_condition", "Equipment condition must be numeric.")
		condition = clampf(float(raw_condition), 0.0, float(maximum_condition))
	var worn := model.has_condition and is_zero_approx(condition)

	var damage := model.damage + (
		EquipmentProgressionCatalog.GRADE_TWO_DAMAGE_BONUS if grade_two and model.damage > 0 else 0
	)
	if worn and model.slot == EquipmentModelDefinition.SLOT_MELEE:
		damage = maxi(int(floor(float(damage) * WORN_MULTIPLIER)), 1)
	var stagger := model.stagger_damage
	if grade_two and stagger > 0:
		stagger = maxi(
			int(round(float(stagger) * EquipmentProgressionCatalog.GRADE_TWO_STAGGER_MULTIPLIER)),
			1
		)
	var guard_stability := model.guard_stability
	if grade_two and guard_stability > 0:
		guard_stability = maxi(
			int(round(
				float(guard_stability)
				* EquipmentProgressionCatalog.GRADE_TWO_STABILITY_MULTIPLIER
			)),
			1
		)
	if worn and model.slot == EquipmentModelDefinition.SLOT_SHIELD:
		guard_stability = maxi(int(round(float(guard_stability) * WORN_MULTIPLIER)), 1)
	var recovery_seconds := model.recovery_seconds
	if worn:
		recovery_seconds *= WORN_RECOVERY_MULTIPLIER
	var max_health_bonus := model.max_health_bonus
	if grade_two and model.slot == EquipmentModelDefinition.SLOT_ARMOR:
		max_health_bonus += EquipmentProgressionCatalog.GRADE_TWO_ARMOR_HEALTH_BONUS

	return {
		"ok": true,
		"code": "resolved",
		"model_id": String(model.id),
		"slot": String(model.slot),
		"grade_id": String(grade_id),
		"condition": condition,
		"maximum_condition": maximum_condition,
		"condition_ratio": condition / float(maximum_condition) if maximum_condition > 0 else 1.0,
		"worn": worn,
		"damage": damage,
		"stagger_damage": stagger,
		"reach": model.reach,
		"startup_seconds": model.startup_seconds,
		"recovery_seconds": recovery_seconds,
		"ranged_resource_id": String(model.ranged_resource_id),
		"starting_ranged_resource": model.starting_ranged_resource,
		"maximum_ranged_resource": model.maximum_ranged_resource,
		"stage_minimum_ranged_resource": model.stage_minimum_ranged_resource,
		"reload_seconds": model.reload_seconds,
		"dash_cancels_reload": model.dash_cancels_reload,
		"guard_stability": guard_stability,
		"guard_angle_degrees": model.guard_angle_degrees,
		"precise_guard_window_seconds": model.precise_guard_window_seconds,
		"guard_move_speed_multiplier": model.guard_move_speed_multiplier,
		"blocks_jump_while_guarding": model.blocks_jump_while_guarding,
		"normal_block_condition_cost": model.normal_block_condition_cost,
		"heavy_block_condition_cost": model.heavy_block_condition_cost,
		"precise_block_condition_cost": model.precise_block_condition_cost,
		"max_health_bonus": max_health_bonus,
		"knockback_reduction_fraction": model.knockback_reduction_fraction,
		"dash_cooldown_addition_seconds": model.dash_cooldown_addition_seconds,
	}


static func maximum_condition_for(
	model: EquipmentModelDefinition,
	grade_id: StringName
) -> int:
	if model == null or not model.has_condition:
		return 0
	if grade_id == GRADE_TWO:
		return int(round(
			float(model.grade_one_max_condition)
			* EquipmentProgressionCatalog.GRADE_TWO_CONDITION_MULTIPLIER
		))
	return model.grade_one_max_condition


static func _invalid(code: StringName, message: String) -> Dictionary:
	return {"ok": false, "code": String(code), "message": message}
