class_name EquipmentProgressionService
extends RefCounted

const ACTION_CRAFT := &"craft"
const ACTION_RECRAFT := &"recraft"
const ACTION_REPAIR := &"repair"
const ACTION_STAGE_ENTRY_MAINTENANCE := &"stage_entry_maintenance"

const GRADE_ONE_ID := &"grade_1"
const GRADE_TWO_ID := &"grade_2"

const CODE_READY := &"ready"
const CODE_MISSING_CATALOG := &"missing_catalog"
const CODE_MISSING_PROFILE := &"missing_profile"
const CODE_MISSING_MODEL := &"missing_model"
const CODE_MISSING_BLUEPRINT := &"missing_blueprint"
const CODE_MISSING_RECIPE := &"missing_recipe"
const CODE_MISSING_MATERIAL := &"missing_material"
const CODE_BLUEPRINT_LOCKED := &"blueprint_locked"
const CODE_ALREADY_CRAFTED := &"already_crafted"
const CODE_NOT_CRAFTED := &"not_crafted"
const CODE_ALREADY_GRADE_TWO := &"already_grade_two"
const CODE_UNSUPPORTED_GRADE := &"unsupported_grade"
const CODE_INVALID_EQUIPMENT_STATE := &"invalid_equipment_state"
const CODE_CONDITIONLESS_MODEL := &"conditionless_model"
const CODE_FULL_CONDITION := &"full_condition"
const CODE_INSUFFICIENT_MATERIALS := &"insufficient_materials"
const CODE_MAINTENANCE_NOT_REQUIRED := &"maintenance_not_required"

const REPAIR_FRACTION := 0.35
const FREE_MAINTENANCE_FRACTION := 0.25
const MAINTENANCE_SLOTS: Array[StringName] = [
	EquipmentModelDefinition.SLOT_MELEE,
	EquipmentModelDefinition.SLOT_SHIELD,
]


static func preview_craft(
	catalog: EquipmentProgressionCatalog,
	profile: ProfileData,
	model_id: StringName
) -> Dictionary:
	var snapshot := _base_snapshot(ACTION_CRAFT, model_id, GRADE_ONE_ID)
	if catalog == null:
		return _outcome(snapshot, false, CODE_MISSING_CATALOG, "Equipment catalog is unavailable.")
	var model := catalog.get_model(model_id)
	if model == null:
		return _outcome(snapshot, false, CODE_MISSING_MODEL, "Equipment model is unavailable.")
	_populate_model(snapshot, model)
	snapshot["result_state"] = _new_equipment_state(model, GRADE_ONE_ID)

	var blueprint := catalog.get_blueprint_for_model(model_id)
	if blueprint == null:
		return _outcome(snapshot, false, CODE_MISSING_BLUEPRINT, "Equipment blueprint is unavailable.")
	_populate_blueprint(snapshot, blueprint)
	if profile == null:
		return _outcome(snapshot, false, CODE_MISSING_PROFILE, "Profile is unavailable.")

	var resolution := _resolve_recipe_costs(
		catalog,
		profile,
		blueprint,
		MaterialDefinition.GRADE_ONE
	)
	_apply_cost_resolution(snapshot, resolution)
	if not bool(resolution["ok"]):
		return _outcome(snapshot, false, resolution["code"], resolution["reason"])
	if not _profile_has_blueprint(profile, model_id):
		return _outcome(snapshot, false, CODE_BLUEPRINT_LOCKED, "Equipment blueprint is locked.")
	if _has_crafted_equipment(profile, model_id):
		var current_state := _crafted_state(profile, model_id)
		if not current_state.is_empty():
			snapshot["current_state"] = _equipment_state(model, current_state)
		return _outcome(snapshot, false, CODE_ALREADY_CRAFTED, "Equipment is already crafted.")
	if _has_shortage(snapshot["shortages"]):
		return _outcome(
			snapshot,
			false,
			CODE_INSUFFICIENT_MATERIALS,
			"Required crafting materials are missing."
		)
	return _outcome(snapshot, true, CODE_READY, "Equipment can be crafted.")


static func preview_recraft(
	catalog: EquipmentProgressionCatalog,
	profile: ProfileData,
	model_id: StringName
) -> Dictionary:
	var snapshot := _base_snapshot(ACTION_RECRAFT, model_id, GRADE_TWO_ID)
	if catalog == null:
		return _outcome(snapshot, false, CODE_MISSING_CATALOG, "Equipment catalog is unavailable.")
	var model := catalog.get_model(model_id)
	if model == null:
		return _outcome(snapshot, false, CODE_MISSING_MODEL, "Equipment model is unavailable.")
	_populate_model(snapshot, model)

	var blueprint := catalog.get_blueprint_for_model(model_id)
	if blueprint == null:
		return _outcome(snapshot, false, CODE_MISSING_BLUEPRINT, "Equipment blueprint is unavailable.")
	_populate_blueprint(snapshot, blueprint)
	if profile == null:
		return _outcome(snapshot, false, CODE_MISSING_PROFILE, "Profile is unavailable.")

	var resolution := _resolve_recipe_costs(
		catalog,
		profile,
		blueprint,
		MaterialDefinition.GRADE_TWO
	)
	_apply_cost_resolution(snapshot, resolution)
	if not bool(resolution["ok"]):
		return _outcome(snapshot, false, resolution["code"], resolution["reason"])
	if not _profile_has_blueprint(profile, model_id):
		return _outcome(snapshot, false, CODE_BLUEPRINT_LOCKED, "Equipment blueprint is locked.")
	if not _has_crafted_equipment(profile, model_id):
		return _outcome(snapshot, false, CODE_NOT_CRAFTED, "Equipment has not been crafted.")
	var current_state := _crafted_state(profile, model_id)
	if current_state.is_empty():
		return _outcome(
			snapshot,
			false,
			CODE_INVALID_EQUIPMENT_STATE,
			"Crafted equipment state is invalid."
		)
	snapshot["current_state"] = _equipment_state(model, current_state)
	var current_grade := StringName(current_state.get("grade_id", &""))
	if current_grade == GRADE_TWO_ID:
		snapshot["result_state"] = snapshot["current_state"].duplicate(true)
		return _outcome(snapshot, false, CODE_ALREADY_GRADE_TWO, "Equipment is already Grade 2.")
	if current_grade != GRADE_ONE_ID:
		return _outcome(snapshot, false, CODE_UNSUPPORTED_GRADE, "Equipment grade is unsupported.")

	# A full Grade 2 recipe fabricates a replacement at its new maximum condition.
	snapshot["result_state"] = _new_equipment_state(model, GRADE_TWO_ID)
	if _has_shortage(snapshot["shortages"]):
		return _outcome(
			snapshot,
			false,
			CODE_INSUFFICIENT_MATERIALS,
			"Required recrafting materials are missing."
		)
	return _outcome(snapshot, true, CODE_READY, "Equipment can be recrafted to Grade 2.")


static func preview_repair(
	catalog: EquipmentProgressionCatalog,
	profile: ProfileData,
	model_id: StringName
) -> Dictionary:
	var snapshot := _base_snapshot(ACTION_REPAIR, model_id, &"")
	if catalog == null:
		return _outcome(snapshot, false, CODE_MISSING_CATALOG, "Equipment catalog is unavailable.")
	var model := catalog.get_model(model_id)
	if model == null:
		return _outcome(snapshot, false, CODE_MISSING_MODEL, "Equipment model is unavailable.")
	_populate_model(snapshot, model)

	var blueprint := catalog.get_blueprint_for_model(model_id)
	if blueprint == null:
		return _outcome(snapshot, false, CODE_MISSING_BLUEPRINT, "Equipment blueprint is unavailable.")
	_populate_blueprint(snapshot, blueprint)
	if profile == null:
		return _outcome(snapshot, false, CODE_MISSING_PROFILE, "Profile is unavailable.")
	if not _has_crafted_equipment(profile, model_id):
		return _outcome(snapshot, false, CODE_NOT_CRAFTED, "Equipment has not been crafted.")
	var current_state := _crafted_state(profile, model_id)
	if current_state.is_empty():
		return _outcome(
			snapshot,
			false,
			CODE_INVALID_EQUIPMENT_STATE,
			"Crafted equipment state is invalid."
		)
	var grade_id := StringName(current_state.get("grade_id", &""))
	var material_grade := material_grade_for_grade_id(grade_id)
	snapshot["grade_id"] = grade_id
	snapshot["material_grade"] = material_grade
	snapshot["current_state"] = _equipment_state(model, current_state)
	snapshot["result_state"] = snapshot["current_state"].duplicate(true)
	if not model.has_condition:
		return _outcome(snapshot, false, CODE_CONDITIONLESS_MODEL, "Equipment does not use condition.")
	if material_grade == 0:
		return _outcome(snapshot, false, CODE_UNSUPPORTED_GRADE, "Equipment grade is unsupported.")
	if not _profile_has_blueprint(profile, model_id):
		return _outcome(snapshot, false, CODE_BLUEPRINT_LOCKED, "Equipment blueprint is locked.")

	var resolution := _resolve_repair_cost(catalog, profile, blueprint, material_grade)
	_apply_cost_resolution(snapshot, resolution)
	if not bool(resolution["ok"]):
		return _outcome(snapshot, false, resolution["code"], resolution["reason"])
	var maximum := maximum_condition(model, grade_id)
	var current := float(snapshot["current_state"]["condition"])
	var repair_amount := maximum * REPAIR_FRACTION
	snapshot["repair_amount"] = repair_amount
	snapshot["result_state"]["condition"] = minf(current + repair_amount, maximum)
	snapshot["condition_delta"] = float(snapshot["result_state"]["condition"]) - current
	if current >= maximum or is_equal_approx(current, maximum):
		return _outcome(snapshot, false, CODE_FULL_CONDITION, "Equipment condition is already full.")
	if _has_shortage(snapshot["shortages"]):
		return _outcome(
			snapshot,
			false,
			CODE_INSUFFICIENT_MATERIALS,
			"The repair material is missing."
		)
	return _outcome(snapshot, true, CODE_READY, "Equipment can be repaired.")


static func preview_stage_entry_maintenance(
	catalog: EquipmentProgressionCatalog,
	profile: ProfileData
) -> Dictionary:
	var snapshot := _base_snapshot(ACTION_STAGE_ENTRY_MAINTENANCE, &"", &"")
	snapshot["model_ids"] = []
	snapshot["grade_ids"] = {}
	snapshot["entries"] = []
	snapshot["current_state"] = {"equipment": {}}
	snapshot["result_state"] = {"equipment": {}}
	if catalog == null:
		return _outcome(snapshot, false, CODE_MISSING_CATALOG, "Equipment catalog is unavailable.")
	if profile == null:
		return _outcome(snapshot, false, CODE_MISSING_PROFILE, "Profile is unavailable.")

	var changed := false
	var first_failure: Dictionary = {}
	for slot_id in MAINTENANCE_SLOTS:
		var model_id := StringName(_value_for_id(profile.hero_loadout, slot_id, &""))
		var entry := _preview_free_maintenance_model(catalog, profile, model_id)
		snapshot["entries"].append(entry)
		snapshot["model_ids"].append(model_id)
		snapshot["grade_ids"][model_id] = entry["grade_id"]
		snapshot["current_state"]["equipment"][model_id] = entry["current_state"].duplicate(true)
		snapshot["result_state"]["equipment"][model_id] = entry["result_state"].duplicate(true)
		if bool(entry["can_execute"]):
			changed = true
		elif entry["code"] != CODE_MAINTENANCE_NOT_REQUIRED and first_failure.is_empty():
			first_failure = entry
	if not first_failure.is_empty():
		return _outcome(snapshot, false, first_failure["code"], first_failure["reason"])
	if not changed:
		return _outcome(
			snapshot,
			false,
			CODE_MAINTENANCE_NOT_REQUIRED,
			"Equipped melee and shield condition are already at least 25%."
		)
	return _outcome(snapshot, true, CODE_READY, "Free stage-entry maintenance is available.")


static func maximum_condition(model: EquipmentModelDefinition, grade_id: StringName) -> float:
	if model == null or not model.has_condition:
		return 0.0
	match material_grade_for_grade_id(grade_id):
		MaterialDefinition.GRADE_ONE:
			return float(model.grade_one_max_condition)
		MaterialDefinition.GRADE_TWO:
			return float(roundi(
				model.grade_one_max_condition
				* EquipmentProgressionCatalog.GRADE_TWO_CONDITION_MULTIPLIER
			))
	return 0.0


static func material_grade_for_grade_id(grade_id: StringName) -> int:
	match grade_id:
		GRADE_ONE_ID:
			return MaterialDefinition.GRADE_ONE
		GRADE_TWO_ID:
			return MaterialDefinition.GRADE_TWO
	return 0


static func _preview_free_maintenance_model(
	catalog: EquipmentProgressionCatalog,
	profile: ProfileData,
	model_id: StringName
) -> Dictionary:
	var snapshot := _base_snapshot(ACTION_STAGE_ENTRY_MAINTENANCE, model_id, &"")
	var model := catalog.get_model(model_id)
	if model == null:
		return _outcome(snapshot, false, CODE_MISSING_MODEL, "Equipped equipment model is unavailable.")
	_populate_model(snapshot, model)
	if not model.has_condition:
		return _outcome(snapshot, false, CODE_CONDITIONLESS_MODEL, "Equipped equipment does not use condition.")
	if not _has_crafted_equipment(profile, model_id):
		return _outcome(snapshot, false, CODE_NOT_CRAFTED, "Equipped equipment has not been crafted.")
	var current_state := _crafted_state(profile, model_id)
	if current_state.is_empty():
		return _outcome(
			snapshot,
			false,
			CODE_INVALID_EQUIPMENT_STATE,
			"Crafted equipment state is invalid."
		)
	var grade_id := StringName(current_state.get("grade_id", &""))
	snapshot["grade_id"] = grade_id
	snapshot["material_grade"] = material_grade_for_grade_id(grade_id)
	snapshot["current_state"] = _equipment_state(model, current_state)
	snapshot["result_state"] = snapshot["current_state"].duplicate(true)
	var maximum := maximum_condition(model, grade_id)
	if maximum <= 0.0:
		return _outcome(snapshot, false, CODE_UNSUPPORTED_GRADE, "Equipment grade is unsupported.")
	var threshold := maximum * FREE_MAINTENANCE_FRACTION
	snapshot["maintenance_threshold"] = threshold
	if float(snapshot["current_state"]["condition"]) >= threshold:
		return _outcome(
			snapshot,
			false,
			CODE_MAINTENANCE_NOT_REQUIRED,
			"Equipment condition is already at least 25%."
		)
	snapshot["result_state"]["condition"] = threshold
	return _outcome(snapshot, true, CODE_READY, "Equipment will be maintained to 25% condition.")


static func _base_snapshot(
	action: StringName,
	model_id: StringName,
	grade_id: StringName
) -> Dictionary:
	return {
		"action": action,
		"model_id": model_id,
		"model": {},
		"blueprint_id": &"",
		"recipe_id": &"",
		"grade_id": grade_id,
		"material_grade": material_grade_for_grade_id(grade_id),
		"current_state": _empty_equipment_state(),
		"result_state": _empty_equipment_state(),
		"costs": {},
		"owned_amounts": {},
		"shortages": {},
		"can_execute": false,
		"code": CODE_MISSING_MODEL,
		"reason": "Equipment model is unavailable.",
	}


static func _populate_model(snapshot: Dictionary, model: EquipmentModelDefinition) -> void:
	snapshot["model"] = {
		"id": model.id,
		"display_name": model.display_name,
		"slot": model.slot,
		"behavior_description": model.behavior_description,
		"weakness_description": model.weakness_description,
		"has_condition": model.has_condition,
	}


static func _populate_blueprint(
	snapshot: Dictionary,
	blueprint: EquipmentBlueprintDefinition
) -> void:
	snapshot["blueprint_id"] = blueprint.id
	if blueprint.recipe != null:
		snapshot["recipe_id"] = blueprint.recipe.id


static func _resolve_recipe_costs(
	catalog: EquipmentProgressionCatalog,
	profile: ProfileData,
	blueprint: EquipmentBlueprintDefinition,
	material_grade: int
) -> Dictionary:
	if blueprint.recipe == null:
		return _cost_failure(CODE_MISSING_RECIPE, "Equipment recipe is unavailable.")
	var family_ids: Array[String] = []
	for raw_family in blueprint.recipe.normalized_costs():
		family_ids.append(String(raw_family))
	family_ids.sort()
	var costs: Dictionary = {}
	var owned_amounts: Dictionary = {}
	var shortages: Dictionary = {}
	for family_text in family_ids:
		var family_id := StringName(family_text)
		var material := catalog.get_material_for(family_id, material_grade)
		if material == null:
			return _cost_failure(
				CODE_MISSING_MATERIAL,
				"Recipe material is unavailable for family '%s' and grade %d."
				% [family_id, material_grade]
			)
		var amount := blueprint.recipe.get_cost(family_id)
		var owned := _material_amount(profile, material.id)
		costs[material.id] = amount
		owned_amounts[material.id] = owned
		shortages[material.id] = maxi(amount - owned, 0)
	return _cost_success(costs, owned_amounts, shortages)


static func _resolve_repair_cost(
	catalog: EquipmentProgressionCatalog,
	profile: ProfileData,
	blueprint: EquipmentBlueprintDefinition,
	material_grade: int
) -> Dictionary:
	var material := catalog.get_material_for(blueprint.primary_material_family, material_grade)
	if material == null:
		return _cost_failure(
			CODE_MISSING_MATERIAL,
			"Primary repair material is unavailable for the equipment grade."
		)
	var owned := _material_amount(profile, material.id)
	return _cost_success(
		{material.id: 1},
		{material.id: owned},
		{material.id: maxi(1 - owned, 0)}
	)


static func _cost_success(
	costs: Dictionary,
	owned_amounts: Dictionary,
	shortages: Dictionary
) -> Dictionary:
	return {
		"ok": true,
		"code": CODE_READY,
		"reason": "Material costs resolved.",
		"costs": costs,
		"owned_amounts": owned_amounts,
		"shortages": shortages,
	}


static func _cost_failure(code: StringName, reason: String) -> Dictionary:
	return {
		"ok": false,
		"code": code,
		"reason": reason,
		"costs": {},
		"owned_amounts": {},
		"shortages": {},
	}


static func _apply_cost_resolution(snapshot: Dictionary, resolution: Dictionary) -> void:
	snapshot["costs"] = resolution["costs"].duplicate(true)
	snapshot["owned_amounts"] = resolution["owned_amounts"].duplicate(true)
	snapshot["shortages"] = resolution["shortages"].duplicate(true)


static func _new_equipment_state(
	model: EquipmentModelDefinition,
	grade_id: StringName
) -> Dictionary:
	var maximum := maximum_condition(model, grade_id)
	return {
		"owned": true,
		"grade_id": grade_id,
		"material_grade": material_grade_for_grade_id(grade_id),
		"condition": maximum if model.has_condition else 0.0,
		"maximum_condition": maximum,
	}


static func _equipment_state(
	model: EquipmentModelDefinition,
	state: Dictionary
) -> Dictionary:
	var grade_id := StringName(state.get("grade_id", &""))
	var raw_condition: Variant = state.get("condition", 0.0)
	var condition := float(raw_condition) if raw_condition is int or raw_condition is float else 0.0
	return {
		"owned": true,
		"grade_id": grade_id,
		"material_grade": material_grade_for_grade_id(grade_id),
		"condition": condition,
		"maximum_condition": maximum_condition(model, grade_id),
	}


static func _empty_equipment_state() -> Dictionary:
	return {
		"owned": false,
		"grade_id": &"",
		"material_grade": 0,
		"condition": 0.0,
		"maximum_condition": 0.0,
	}


static func _profile_has_blueprint(profile: ProfileData, model_id: StringName) -> bool:
	for unlocked_model_id in profile.unlocked_blueprints:
		if StringName(unlocked_model_id) == model_id:
			return true
	return false


static func _has_crafted_equipment(profile: ProfileData, model_id: StringName) -> bool:
	return profile.crafted_equipment.has(model_id) or profile.crafted_equipment.has(String(model_id))


static func _crafted_state(profile: ProfileData, model_id: StringName) -> Dictionary:
	var value: Variant = _value_for_id(profile.crafted_equipment, model_id, null)
	return value.duplicate(true) if value is Dictionary else {}


static func _material_amount(profile: ProfileData, material_id: StringName) -> int:
	var value: Variant = _value_for_id(profile.materials, material_id, 0)
	return int(value) if value is int or value is float else 0


static func _value_for_id(values: Dictionary, id: StringName, fallback: Variant) -> Variant:
	if values.has(id):
		return values[id]
	return values.get(String(id), fallback)


static func _has_shortage(shortages: Dictionary) -> bool:
	for amount in shortages.values():
		if int(amount) > 0:
			return true
	return false


static func _outcome(
	snapshot: Dictionary,
	can_execute: bool,
	code: StringName,
	reason: String
) -> Dictionary:
	snapshot["can_execute"] = can_execute
	snapshot["code"] = code
	snapshot["reason"] = reason
	return snapshot
