class_name EquipmentProgressionCatalog
extends Resource

const EXPECTED_MATERIAL_IDS: Array[StringName] = [
	&"rusted_scrap",
	&"steel_fragment",
	&"common_timber",
	&"hardwood",
	&"sky_thread",
	&"reinforced_fabric",
]
const EXPECTED_MODEL_IDS: Array[StringName] = [
	&"traveler_sword",
	&"hunting_spear",
	&"hunting_bow",
	&"matchlock",
	&"round_shield",
	&"tower_shield",
	&"traveler_coat",
	&"reinforced_coat",
]
const EXPECTED_BLUEPRINT_IDS: Array[StringName] = [
	&"traveler_sword_blueprint",
	&"hunting_spear_blueprint",
	&"hunting_bow_blueprint",
	&"matchlock_blueprint",
	&"round_shield_blueprint",
	&"tower_shield_blueprint",
	&"traveler_coat_blueprint",
	&"reinforced_coat_blueprint",
]
const EXPECTED_SPIRIT_STONE_IDS: Array[StringName] = [
	&"ember_spirit_stone",
	&"frost_spirit_stone",
]
const STARTING_MODEL_IDS: Array[StringName] = [
	&"traveler_sword",
	&"hunting_bow",
	&"round_shield",
	&"traveler_coat",
]
const EXPECTED_MATERIAL_SHAPES := {
	&"rusted_scrap": [MaterialDefinition.FAMILY_METAL, MaterialDefinition.GRADE_ONE],
	&"steel_fragment": [MaterialDefinition.FAMILY_METAL, MaterialDefinition.GRADE_TWO],
	&"common_timber": [MaterialDefinition.FAMILY_TIMBER, MaterialDefinition.GRADE_ONE],
	&"hardwood": [MaterialDefinition.FAMILY_TIMBER, MaterialDefinition.GRADE_TWO],
	&"sky_thread": [MaterialDefinition.FAMILY_TEXTILE, MaterialDefinition.GRADE_ONE],
	&"reinforced_fabric": [MaterialDefinition.FAMILY_TEXTILE, MaterialDefinition.GRADE_TWO],
}
const EXPECTED_MODEL_SLOTS := {
	&"traveler_sword": EquipmentModelDefinition.SLOT_MELEE,
	&"hunting_spear": EquipmentModelDefinition.SLOT_MELEE,
	&"hunting_bow": EquipmentModelDefinition.SLOT_RANGED,
	&"matchlock": EquipmentModelDefinition.SLOT_RANGED,
	&"round_shield": EquipmentModelDefinition.SLOT_SHIELD,
	&"tower_shield": EquipmentModelDefinition.SLOT_SHIELD,
	&"traveler_coat": EquipmentModelDefinition.SLOT_ARMOR,
	&"reinforced_coat": EquipmentModelDefinition.SLOT_ARMOR,
}
const EXPECTED_SLOT_COUNTS := {
	EquipmentModelDefinition.SLOT_MELEE: 2,
	EquipmentModelDefinition.SLOT_RANGED: 2,
	EquipmentModelDefinition.SLOT_SHIELD: 2,
	EquipmentModelDefinition.SLOT_ARMOR: 2,
}
const EXPECTED_RECIPE_COSTS := {
	&"traveler_sword": {&"metal": 5, &"timber": 2},
	&"hunting_spear": {&"metal": 3, &"timber": 4},
	&"hunting_bow": {&"metal": 1, &"timber": 5, &"textile": 3},
	&"matchlock": {&"metal": 6, &"timber": 3, &"textile": 1},
	&"round_shield": {&"metal": 3, &"timber": 4},
	&"tower_shield": {&"metal": 6, &"timber": 4},
	&"traveler_coat": {&"metal": 1, &"textile": 5},
	&"reinforced_coat": {&"metal": 4, &"textile": 5},
}

const GRADE_TWO_DAMAGE_BONUS := 1
const GRADE_TWO_STAGGER_MULTIPLIER := 1.15
const GRADE_TWO_STABILITY_MULTIPLIER := 1.15
const GRADE_TWO_CONDITION_MULTIPLIER := 1.20
const GRADE_TWO_ARMOR_HEALTH_BONUS := 1

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var materials: Array[MaterialDefinition] = []
@export var models: Array[EquipmentModelDefinition] = []
@export var blueprints: Array[EquipmentBlueprintDefinition] = []
@export var spirit_stones: Array[SpiritStoneDefinition] = []


func get_material(material_id: StringName) -> MaterialDefinition:
	for material in materials:
		if material != null and material.id == material_id:
			return material
	return null


func get_material_for(family: StringName, grade: int) -> MaterialDefinition:
	for material in materials:
		if material != null and material.family == family and material.grade == grade:
			return material
	return null


func get_model(model_id: StringName) -> EquipmentModelDefinition:
	for model in models:
		if model != null and model.id == model_id:
			return model
	return null


func get_blueprint(blueprint_id: StringName) -> EquipmentBlueprintDefinition:
	for blueprint in blueprints:
		if blueprint != null and blueprint.id == blueprint_id:
			return blueprint
	return null


func get_blueprint_for_model(model_id: StringName) -> EquipmentBlueprintDefinition:
	for blueprint in blueprints:
		if blueprint != null and blueprint.model_id == model_id:
			return blueprint
	return null


func get_spirit_stone(stone_id: StringName) -> SpiritStoneDefinition:
	for stone in spirit_stones:
		if stone != null and stone.id == stone_id:
			return stone
	return null


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Equipment progression catalog ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Equipment progression catalog '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Equipment progression catalog '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Equipment progression catalog '%s' tag" % id, tags, true)
	_validate_materials(errors)
	_validate_models(errors)
	_validate_blueprints(errors)
	_validate_spirit_stones(errors)
	return errors


func _validate_materials(errors: PackedStringArray) -> void:
	if materials.size() != EXPECTED_MATERIAL_IDS.size():
		errors.append("Equipment progression catalog needs exactly 6 materials.")
	var seen_ids: Dictionary = {}
	var seen_family_grades: Dictionary = {}
	for material_index in materials.size():
		var material := materials[material_index]
		if material == null:
			errors.append("Material at index %d is null." % material_index)
			continue
		var material_text := String(material.id)
		if seen_ids.has(material_text):
			errors.append("Duplicate material ID '%s'." % material.id)
		seen_ids[material_text] = true
		for definition_error in material.validate_definition():
			errors.append("Material '%s': %s" % [material.id, definition_error])
		var shape_key := "%s:%d" % [material.family, material.grade]
		if seen_family_grades.has(shape_key):
			errors.append("Duplicate material family/grade '%s'." % shape_key)
		seen_family_grades[shape_key] = true
		var expected_shape: Array = EXPECTED_MATERIAL_SHAPES.get(material.id, [])
		if not expected_shape.is_empty() and (
			material.family != expected_shape[0] or material.grade != int(expected_shape[1])
		):
			errors.append("Material '%s' has the wrong family or grade." % material.id)
	_validate_expected_ids(errors, "material", seen_ids, EXPECTED_MATERIAL_IDS)
	for family in MaterialDefinition.FAMILIES:
		for grade in MaterialDefinition.GRADES:
			if get_material_for(family, grade) == null:
				errors.append("Material family '%s' is missing grade %d." % [family, grade])


func _validate_models(errors: PackedStringArray) -> void:
	if models.size() != EXPECTED_MODEL_IDS.size():
		errors.append("Equipment progression catalog needs exactly 8 equipment models.")
	var seen_ids: Dictionary = {}
	var slot_counts: Dictionary = {}
	for slot_id in EquipmentModelDefinition.SLOTS:
		slot_counts[slot_id] = 0
	for model_index in models.size():
		var model := models[model_index]
		if model == null:
			errors.append("Equipment model at index %d is null." % model_index)
			continue
		var model_text := String(model.id)
		if seen_ids.has(model_text):
			errors.append("Duplicate equipment model ID '%s'." % model.id)
		seen_ids[model_text] = true
		for definition_error in model.validate_definition():
			errors.append("Equipment model '%s': %s" % [model.id, definition_error])
		if slot_counts.has(model.slot):
			slot_counts[model.slot] = int(slot_counts[model.slot]) + 1
		var expected_slot := StringName(EXPECTED_MODEL_SLOTS.get(model.id, &""))
		if expected_slot != &"" and model.slot != expected_slot:
			errors.append("Equipment model '%s' must use slot '%s'." % [model.id, expected_slot])
	_validate_expected_ids(errors, "equipment model", seen_ids, EXPECTED_MODEL_IDS)
	for slot_id in EXPECTED_SLOT_COUNTS:
		if int(slot_counts.get(slot_id, 0)) != int(EXPECTED_SLOT_COUNTS[slot_id]):
			errors.append(
				"Equipment slot '%s' needs exactly %d models."
				% [slot_id, int(EXPECTED_SLOT_COUNTS[slot_id])]
			)


func _validate_blueprints(errors: PackedStringArray) -> void:
	if blueprints.size() != EXPECTED_BLUEPRINT_IDS.size():
		errors.append("Equipment progression catalog needs exactly 8 blueprints.")
	var seen_ids: Dictionary = {}
	var seen_model_ids: Dictionary = {}
	for blueprint_index in blueprints.size():
		var blueprint := blueprints[blueprint_index]
		if blueprint == null:
			errors.append("Equipment blueprint at index %d is null." % blueprint_index)
			continue
		var blueprint_text := String(blueprint.id)
		if seen_ids.has(blueprint_text):
			errors.append("Duplicate equipment blueprint ID '%s'." % blueprint.id)
		seen_ids[blueprint_text] = true
		var model_text := String(blueprint.model_id)
		if seen_model_ids.has(model_text):
			errors.append("Duplicate blueprint target model '%s'." % blueprint.model_id)
		seen_model_ids[model_text] = true
		for definition_error in blueprint.validate_definition():
			errors.append("Equipment blueprint '%s': %s" % [blueprint.id, definition_error])
		if get_model(blueprint.model_id) == null:
			errors.append(
				"Equipment blueprint '%s' references missing model '%s'."
				% [blueprint.id, blueprint.model_id]
			)
		var should_start := STARTING_MODEL_IDS.has(blueprint.model_id)
		if blueprint.starting_blueprint != should_start:
			errors.append("Equipment blueprint '%s' has the wrong starting-unlock state." % blueprint.id)
		if blueprint.recipe != null:
			var expected_costs: Dictionary = EXPECTED_RECIPE_COSTS.get(blueprint.model_id, {})
			if not _same_cost_map(blueprint.recipe.family_costs, expected_costs):
				errors.append("Equipment blueprint '%s' has the wrong recipe costs." % blueprint.id)
			for family in blueprint.recipe.normalized_costs():
				if (
					get_material_for(family, MaterialDefinition.GRADE_ONE) == null
					or get_material_for(family, MaterialDefinition.GRADE_TWO) == null
				):
					errors.append(
						"Equipment blueprint '%s' recipe family '%s' lacks both material grades."
						% [blueprint.id, family]
					)
	_validate_expected_ids(errors, "equipment blueprint", seen_ids, EXPECTED_BLUEPRINT_IDS)
	for model_id in EXPECTED_MODEL_IDS:
		if not seen_model_ids.has(String(model_id)):
			errors.append("Equipment model '%s' is missing its blueprint." % model_id)


func _validate_spirit_stones(errors: PackedStringArray) -> void:
	if spirit_stones.size() != EXPECTED_SPIRIT_STONE_IDS.size():
		errors.append("Equipment progression catalog needs exactly 2 Spirit Stones.")
	var seen_ids: Dictionary = {}
	for stone_index in spirit_stones.size():
		var stone := spirit_stones[stone_index]
		if stone == null:
			errors.append("Spirit Stone at index %d is null." % stone_index)
			continue
		var stone_text := String(stone.id)
		if seen_ids.has(stone_text):
			errors.append("Duplicate Spirit Stone ID '%s'." % stone.id)
		seen_ids[stone_text] = true
		for definition_error in stone.validate_definition():
			errors.append("Spirit Stone '%s': %s" % [stone.id, definition_error])
	_validate_expected_ids(errors, "Spirit Stone", seen_ids, EXPECTED_SPIRIT_STONE_IDS)


func _validate_expected_ids(
	errors: PackedStringArray,
	label: String,
	seen_ids: Dictionary,
	expected_ids: Array[StringName]
) -> void:
	for expected_id in expected_ids:
		if not seen_ids.has(String(expected_id)):
			errors.append("Equipment progression catalog is missing %s '%s'." % [label, expected_id])
	for actual_id in seen_ids:
		if not expected_ids.has(StringName(actual_id)):
			errors.append("Equipment progression catalog contains unexpected %s '%s'." % [label, actual_id])


func _same_cost_map(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for raw_family in expected:
		var family := StringName(raw_family)
		var actual_amount: Variant = actual.get(family, actual.get(String(family), -1))
		if not actual_amount is int or int(actual_amount) != int(expected[raw_family]):
			return false
	return true
