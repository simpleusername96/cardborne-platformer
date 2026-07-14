extends SceneTree

const Service := preload("res://scripts/progression/EquipmentProgressionService.gd")
const CATALOG_PATH := "res://data/equipment/equipment_progression_catalog.tres"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(CATALOG_PATH) as EquipmentProgressionCatalog
	_expect(catalog != null, "real equipment progression catalog should load")
	if catalog == null:
		_finish()
		return
	_validate_helpers(catalog)
	_validate_lookup_rejections(catalog)
	_validate_craft(catalog)
	_validate_recraft(catalog)
	_validate_repair(catalog)
	_validate_stage_entry_maintenance(catalog)
	_finish()


func _validate_helpers(catalog: EquipmentProgressionCatalog) -> void:
	var sword := catalog.get_model(&"traveler_sword")
	var bow := catalog.get_model(&"hunting_bow")
	_expect(sword != null and bow != null, "helper fixtures should resolve real equipment models")
	if sword == null or bow == null:
		return
	_expect(
		is_equal_approx(Service.maximum_condition(sword, Service.GRADE_ONE_ID), 100.0),
		"Grade 1 condition maximum should be 100"
	)
	_expect(
		is_equal_approx(Service.maximum_condition(sword, Service.GRADE_TWO_ID), 120.0),
		"Grade 2 condition maximum should be 120"
	)
	_expect(
		is_zero_approx(Service.maximum_condition(bow, Service.GRADE_TWO_ID)),
		"conditionless models should have zero maximum condition"
	)
	_expect(
		Service.material_grade_for_grade_id(Service.GRADE_ONE_ID) == MaterialDefinition.GRADE_ONE,
		"grade_1 should resolve material Grade 1"
	)
	_expect(
		Service.material_grade_for_grade_id(Service.GRADE_TWO_ID) == MaterialDefinition.GRADE_TWO,
		"grade_2 should resolve material Grade 2"
	)
	_expect(
		Service.material_grade_for_grade_id(&"grade_3") == 0,
		"unsupported equipment grades should not resolve a material grade"
	)


func _validate_lookup_rejections(catalog: EquipmentProgressionCatalog) -> void:
	var profile := ProfileData.new()
	_expect_outcome(
		Service.preview_craft(null, profile, &"hunting_spear"),
		Service.ACTION_CRAFT,
		Service.CODE_MISSING_CATALOG,
		false,
		"missing catalog"
	)
	_expect_outcome(
		Service.preview_craft(catalog, null, &"hunting_spear"),
		Service.ACTION_CRAFT,
		Service.CODE_MISSING_PROFILE,
		false,
		"missing profile"
	)
	_expect_outcome(
		Service.preview_craft(catalog, profile, &"missing_model"),
		Service.ACTION_CRAFT,
		Service.CODE_MISSING_MODEL,
		false,
		"missing model"
	)
	var catalog_without_spear_blueprint := _catalog_without_blueprint(catalog, &"hunting_spear")
	_expect_outcome(
		Service.preview_craft(catalog_without_spear_blueprint, profile, &"hunting_spear"),
		Service.ACTION_CRAFT,
		Service.CODE_MISSING_BLUEPRINT,
		false,
		"missing blueprint"
	)


func _validate_craft(catalog: EquipmentProgressionCatalog) -> void:
	var locked_profile := ProfileData.new()
	locked_profile.materials = {"rusted_scrap": 3, "common_timber": 4}
	var locked := Service.preview_craft(catalog, locked_profile, &"hunting_spear")
	_expect_outcome(
		locked,
		Service.ACTION_CRAFT,
		Service.CODE_BLUEPRINT_LOCKED,
		false,
		"locked blueprint"
	)
	_expect_material_maps(
		locked,
		{&"rusted_scrap": 3, &"common_timber": 4},
		{&"rusted_scrap": 3, &"common_timber": 4},
		{&"rusted_scrap": 0, &"common_timber": 0},
		"locked craft"
	)

	var already_crafted := Service.preview_craft(catalog, ProfileData.new(), &"traveler_sword")
	_expect_outcome(
		already_crafted,
		Service.ACTION_CRAFT,
		Service.CODE_ALREADY_CRAFTED,
		false,
		"already crafted"
	)
	_expect(bool(already_crafted["current_state"]["owned"]), "already-crafted preview should expose current state")

	var success_profile := ProfileData.new()
	success_profile.unlocked_blueprints.append("hunting_spear")
	success_profile.materials = {"rusted_scrap": 3, "common_timber": 4}
	var before := success_profile.to_dictionary()
	var success := Service.preview_craft(catalog, success_profile, &"hunting_spear")
	_expect_outcome(success, Service.ACTION_CRAFT, Service.CODE_READY, true, "craft success")
	_expect_common_snapshot(success, "craft success")
	_expect(success["grade_id"] == Service.GRADE_ONE_ID, "craft should target Grade 1")
	_expect(not bool(success["current_state"]["owned"]), "craft should require an unowned model")
	_expect(bool(success["result_state"]["owned"]), "craft result should own the model")
	_expect(
		is_equal_approx(float(success["result_state"]["condition"]), 100.0),
		"crafting a condition model should produce full Grade 1 condition"
	)
	_expect_material_maps(
		success,
		{&"rusted_scrap": 3, &"common_timber": 4},
		{&"rusted_scrap": 3, &"common_timber": 4},
		{&"rusted_scrap": 0, &"common_timber": 0},
		"craft success"
	)
	_expect(success_profile.to_dictionary() == before, "craft preview must not mutate ProfileData")
	_expect(
		success == Service.preview_craft(catalog, success_profile, &"hunting_spear"),
		"craft preview should be deterministic"
	)

	var shortage_profile := success_profile.duplicate_data()
	shortage_profile.materials = {"rusted_scrap": 2, "common_timber": 4}
	var shortage := Service.preview_craft(catalog, shortage_profile, &"hunting_spear")
	_expect_outcome(
		shortage,
		Service.ACTION_CRAFT,
		Service.CODE_INSUFFICIENT_MATERIALS,
		false,
		"craft shortage"
	)
	_expect_material_maps(
		shortage,
		{&"rusted_scrap": 3, &"common_timber": 4},
		{&"rusted_scrap": 2, &"common_timber": 4},
		{&"rusted_scrap": 1, &"common_timber": 0},
		"craft shortage"
	)


func _validate_recraft(catalog: EquipmentProgressionCatalog) -> void:
	var uncrafted_profile := ProfileData.new()
	uncrafted_profile.unlocked_blueprints.append("hunting_spear")
	uncrafted_profile.materials = {"steel_fragment": 3, "hardwood": 4}
	_expect_outcome(
		Service.preview_recraft(catalog, uncrafted_profile, &"hunting_spear"),
		Service.ACTION_RECRAFT,
		Service.CODE_NOT_CRAFTED,
		false,
		"uncrafted recraft"
	)

	var grade_two_profile := ProfileData.new()
	grade_two_profile.crafted_equipment["traveler_sword"] = {
		"grade_id": "grade_2",
		"condition": 120.0,
	}
	grade_two_profile.materials = {"steel_fragment": 5, "hardwood": 2}
	_expect_outcome(
		Service.preview_recraft(catalog, grade_two_profile, &"traveler_sword"),
		Service.ACTION_RECRAFT,
		Service.CODE_ALREADY_GRADE_TWO,
		false,
		"already Grade 2"
	)

	var success_profile := ProfileData.new()
	success_profile.crafted_equipment["traveler_sword"]["condition"] = 61.0
	success_profile.materials = {"steel_fragment": 5, "hardwood": 2}
	var before := success_profile.to_dictionary()
	var success := Service.preview_recraft(catalog, success_profile, &"traveler_sword")
	_expect_outcome(success, Service.ACTION_RECRAFT, Service.CODE_READY, true, "recraft success")
	_expect_common_snapshot(success, "recraft success")
	_expect(success["grade_id"] == Service.GRADE_TWO_ID, "recraft should target Grade 2")
	_expect(
		success["current_state"]["grade_id"] == Service.GRADE_ONE_ID,
		"recraft should expose the owned Grade 1 state"
	)
	_expect(
		success["result_state"]["grade_id"] == Service.GRADE_TWO_ID,
		"recraft should produce Grade 2 state"
	)
	_expect(
		is_equal_approx(float(success["result_state"]["condition"]), 120.0),
		"recraft should fabricate a full-condition Grade 2 replacement"
	)
	_expect(
		is_equal_approx(float(success["result_state"]["maximum_condition"]), 120.0),
		"recraft should expose the Grade 2 maximum condition"
	)
	_expect_material_maps(
		success,
		{&"steel_fragment": 5, &"hardwood": 2},
		{&"steel_fragment": 5, &"hardwood": 2},
		{&"steel_fragment": 0, &"hardwood": 0},
		"recraft success"
	)
	_expect(success_profile.to_dictionary() == before, "recraft preview must not mutate ProfileData")

	var shortage_profile := success_profile.duplicate_data()
	shortage_profile.materials = {"steel_fragment": 4, "hardwood": 1}
	var shortage := Service.preview_recraft(catalog, shortage_profile, &"traveler_sword")
	_expect_outcome(
		shortage,
		Service.ACTION_RECRAFT,
		Service.CODE_INSUFFICIENT_MATERIALS,
		false,
		"recraft shortage"
	)
	_expect_material_maps(
		shortage,
		{&"steel_fragment": 5, &"hardwood": 2},
		{&"steel_fragment": 4, &"hardwood": 1},
		{&"steel_fragment": 1, &"hardwood": 1},
		"recraft shortage"
	)


func _validate_repair(catalog: EquipmentProgressionCatalog) -> void:
	var conditionless := Service.preview_repair(catalog, ProfileData.new(), &"hunting_bow")
	_expect_outcome(
		conditionless,
		Service.ACTION_REPAIR,
		Service.CODE_CONDITIONLESS_MODEL,
		false,
		"conditionless repair"
	)
	_expect(
		bool(conditionless["current_state"]["owned"])
		and conditionless["current_state"]["grade_id"] == Service.GRADE_ONE_ID,
		"conditionless rejection should still expose the owned Grade 1 state"
	)

	var full_profile := ProfileData.new()
	full_profile.materials = {"rusted_scrap": 1}
	var full := Service.preview_repair(catalog, full_profile, &"traveler_sword")
	_expect_outcome(
		full,
		Service.ACTION_REPAIR,
		Service.CODE_FULL_CONDITION,
		false,
		"full repair"
	)
	_expect_material_maps(
		full,
		{&"rusted_scrap": 1},
		{&"rusted_scrap": 1},
		{&"rusted_scrap": 0},
		"full repair"
	)

	var shortage_profile := ProfileData.new()
	shortage_profile.crafted_equipment["traveler_sword"]["condition"] = 40.0
	var shortage := Service.preview_repair(catalog, shortage_profile, &"traveler_sword")
	_expect_outcome(
		shortage,
		Service.ACTION_REPAIR,
		Service.CODE_INSUFFICIENT_MATERIALS,
		false,
		"repair shortage"
	)
	_expect_material_maps(
		shortage,
		{&"rusted_scrap": 1},
		{&"rusted_scrap": 0},
		{&"rusted_scrap": 1},
		"repair shortage"
	)

	var exact_profile := ProfileData.new()
	exact_profile.crafted_equipment["traveler_sword"]["condition"] = 40.0
	exact_profile.materials = {"rusted_scrap": 1}
	var before := exact_profile.to_dictionary()
	var exact := Service.preview_repair(catalog, exact_profile, &"traveler_sword")
	_expect_outcome(exact, Service.ACTION_REPAIR, Service.CODE_READY, true, "exact repair")
	_expect_common_snapshot(exact, "exact repair")
	_expect(is_equal_approx(float(exact["repair_amount"]), 35.0), "Grade 1 repair should restore 35 condition")
	_expect(
		is_equal_approx(float(exact["result_state"]["condition"]), 75.0),
		"Grade 1 repair should add exactly 35% of maximum condition"
	)
	_expect(exact_profile.to_dictionary() == before, "repair preview must not mutate ProfileData")

	var grade_two_profile := ProfileData.new()
	grade_two_profile.crafted_equipment["traveler_sword"] = {
		"grade_id": "grade_2",
		"condition": 50.0,
	}
	grade_two_profile.materials = {"steel_fragment": 1}
	var grade_two := Service.preview_repair(catalog, grade_two_profile, &"traveler_sword")
	_expect_outcome(grade_two, Service.ACTION_REPAIR, Service.CODE_READY, true, "Grade 2 repair")
	_expect(is_equal_approx(float(grade_two["repair_amount"]), 42.0), "Grade 2 repair should restore 42 condition")
	_expect(
		is_equal_approx(float(grade_two["result_state"]["condition"]), 92.0),
		"Grade 2 repair should add exactly 35% of 120"
	)
	_expect_material_maps(
		grade_two,
		{&"steel_fragment": 1},
		{&"steel_fragment": 1},
		{&"steel_fragment": 0},
		"Grade 2 repair"
	)

	var clamped_profile := grade_two_profile.duplicate_data()
	clamped_profile.crafted_equipment["traveler_sword"]["condition"] = 110.0
	var clamped := Service.preview_repair(catalog, clamped_profile, &"traveler_sword")
	_expect_outcome(clamped, Service.ACTION_REPAIR, Service.CODE_READY, true, "clamped repair")
	_expect(
		is_equal_approx(float(clamped["result_state"]["condition"]), 120.0),
		"repair should clamp to maximum condition"
	)
	_expect(is_equal_approx(float(clamped["condition_delta"]), 10.0), "clamped repair delta should remain exact")


func _validate_stage_entry_maintenance(catalog: EquipmentProgressionCatalog) -> void:
	var profile := ProfileData.new()
	profile.crafted_equipment["traveler_sword"]["condition"] = 24.0
	profile.crafted_equipment["round_shield"]["condition"] = 25.0
	profile.ranged_supplies["arrows"] = 2
	profile.unlocked_blueprints.append("hunting_spear")
	profile.crafted_equipment["hunting_spear"] = {
		"grade_id": "grade_1",
		"condition": 1.0,
	}
	var before := profile.to_dictionary()
	var preview := Service.preview_stage_entry_maintenance(catalog, profile)
	_expect_outcome(
		preview,
		Service.ACTION_STAGE_ENTRY_MAINTENANCE,
		Service.CODE_READY,
		true,
		"free maintenance"
	)
	_expect(preview["entries"].size() == 2, "maintenance should inspect exactly equipped melee and shield")
	_expect(
		preview["model_ids"] == [&"traveler_sword", &"round_shield"],
		"maintenance should use stable melee-then-shield order"
	)
	var sword_entry := _entry_for(preview, &"traveler_sword")
	var shield_entry := _entry_for(preview, &"round_shield")
	var supply_entry: Dictionary = preview.get("ranged_supply", {})
	_expect_outcome(
		sword_entry,
		Service.ACTION_STAGE_ENTRY_MAINTENANCE,
		Service.CODE_READY,
		true,
		"below-threshold maintenance"
	)
	_expect(
		is_equal_approx(float(sword_entry["result_state"]["condition"]), 25.0),
		"condition below 25% should become exactly 25%"
	)
	_expect_outcome(
		shield_entry,
		Service.ACTION_STAGE_ENTRY_MAINTENANCE,
		Service.CODE_MAINTENANCE_NOT_REQUIRED,
		false,
		"at-threshold maintenance"
	)
	_expect(
		is_equal_approx(float(shield_entry["result_state"]["condition"]), 25.0),
		"condition exactly at 25% should remain unchanged"
	)
	_expect(
		not preview["model_ids"].has(&"hunting_spear"),
		"maintenance should ignore unequipped condition models"
	)
	_expect(
		bool(supply_entry.get("can_execute", false))
		and supply_entry.get("supply_id") == "arrows"
		and int(supply_entry.get("current", -1)) == 2
		and int(supply_entry.get("result", -1)) == 8,
		"stage entry should preview the equipped bow's minimum arrow supply"
	)
	_expect(
		int(preview["result_state"]["ranged_supplies"].get("arrows", -1)) == 8,
		"maintenance result state should include ranged supply"
	)
	_expect(profile.to_dictionary() == before, "maintenance preview must not mutate ProfileData")
	_expect(
		preview == Service.preview_stage_entry_maintenance(catalog, profile),
		"maintenance preview should be deterministic"
	)

	var grade_two_profile := ProfileData.new()
	grade_two_profile.crafted_equipment["traveler_sword"] = {
		"grade_id": "grade_2",
		"condition": 29.0,
	}
	grade_two_profile.crafted_equipment["round_shield"]["condition"] = 26.0
	var grade_two_preview := Service.preview_stage_entry_maintenance(catalog, grade_two_profile)
	var grade_two_entry := _entry_for(grade_two_preview, &"traveler_sword")
	_expect(
		is_equal_approx(float(grade_two_entry["maintenance_threshold"]), 30.0),
		"Grade 2 free-maintenance threshold should be 30"
	)
	_expect(
		is_equal_approx(float(grade_two_entry["result_state"]["condition"]), 30.0),
		"Grade 2 condition below 25% should become exactly 30"
	)

	var no_change_profile := ProfileData.new()
	no_change_profile.crafted_equipment["traveler_sword"]["condition"] = 25.0
	no_change_profile.crafted_equipment["round_shield"]["condition"] = 26.0
	_expect_outcome(
		Service.preview_stage_entry_maintenance(catalog, no_change_profile),
		Service.ACTION_STAGE_ENTRY_MAINTENANCE,
		Service.CODE_MAINTENANCE_NOT_REQUIRED,
		false,
		"maintenance threshold aggregate"
	)


func _catalog_without_blueprint(
	catalog: EquipmentProgressionCatalog,
	model_id: StringName
) -> EquipmentProgressionCatalog:
	var clone := EquipmentProgressionCatalog.new()
	clone.id = catalog.id
	clone.display_name = catalog.display_name
	clone.content_version = catalog.content_version
	clone.tags = catalog.tags.duplicate()
	clone.materials = catalog.materials.duplicate()
	clone.models = catalog.models.duplicate()
	clone.spirit_stones = catalog.spirit_stones.duplicate()
	var blueprints: Array[EquipmentBlueprintDefinition] = []
	for blueprint in catalog.blueprints:
		if blueprint.model_id != model_id:
			blueprints.append(blueprint)
	clone.blueprints = blueprints
	return clone


func _entry_for(snapshot: Dictionary, model_id: StringName) -> Dictionary:
	for raw_entry in snapshot.get("entries", []):
		if raw_entry is Dictionary and StringName(raw_entry.get("model_id", &"")) == model_id:
			return raw_entry
	_failures.append("maintenance entry %s should exist" % model_id)
	return {}


func _expect_common_snapshot(snapshot: Dictionary, label: String) -> void:
	for key in [
		"action",
		"model_id",
		"model",
		"grade_id",
		"material_grade",
		"current_state",
		"result_state",
		"costs",
		"owned_amounts",
		"shortages",
		"can_execute",
		"code",
		"reason",
	]:
		_expect(snapshot.has(key), "%s should include '%s'" % [label, key])
	_expect(snapshot.get("model", {}).has("id"), "%s should include model metadata" % label)
	_expect(not String(snapshot.get("reason", "")).is_empty(), "%s should include a stable reason" % label)


func _expect_outcome(
	snapshot: Dictionary,
	action: StringName,
	code: StringName,
	can_execute: bool,
	label: String
) -> void:
	_expect(not snapshot.is_empty(), "%s should return a snapshot" % label)
	if snapshot.is_empty():
		return
	_expect(snapshot.get("action", &"") == action, "%s should preserve action '%s'" % [label, action])
	_expect(snapshot.get("code", &"") == code, "%s should use code '%s'" % [label, code])
	_expect(bool(snapshot.get("can_execute", not can_execute)) == can_execute, "%s can_execute should be %s" % [label, can_execute])
	_expect(not String(snapshot.get("reason", "")).is_empty(), "%s should include a reason" % label)


func _expect_material_maps(
	snapshot: Dictionary,
	expected_costs: Dictionary,
	expected_owned: Dictionary,
	expected_shortages: Dictionary,
	label: String
) -> void:
	_expect(
		_same_int_map(snapshot.get("costs", {}), expected_costs),
		"%s costs should be exact: %s" % [label, snapshot.get("costs", {})]
	)
	_expect(
		_same_int_map(snapshot.get("owned_amounts", {}), expected_owned),
		"%s owned amounts should be exact: %s" % [label, snapshot.get("owned_amounts", {})]
	)
	_expect(
		_same_int_map(snapshot.get("shortages", {}), expected_shortages),
		"%s shortages should be exact: %s" % [label, snapshot.get("shortages", {})]
	)


func _same_int_map(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for raw_key in expected:
		var key := StringName(raw_key)
		var actual_value: Variant = actual.get(key, actual.get(String(key), null))
		if not actual_value is int or int(actual_value) != int(expected[raw_key]):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"EQUIPMENT_PROGRESSION_SERVICE_VALIDATION_OK "
			+ "craft=covered recraft=covered repair=covered maintenance=covered"
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
