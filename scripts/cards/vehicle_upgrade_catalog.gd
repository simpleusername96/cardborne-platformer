class_name VehicleUpgradeCatalog
extends RefCounted

const CARD_PATH := "res://data/cards/vehicle"
const EXPECTED_COUNT := 43

var definitions: Dictionary = {}


func _init() -> void:
	_load_definitions()


func _load_definitions() -> void:
	definitions.clear()
	var files := DirAccess.get_files_at(CARD_PATH)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
		var definition := load(CARD_PATH.path_join(file_name)) as VehicleUpgradeDefinition
		if definition != null:
			definitions[definition.id] = definition


func get_definition(upgrade_id: StringName) -> VehicleUpgradeDefinition:
	return definitions.get(upgrade_id) as VehicleUpgradeDefinition


func all_definitions() -> Array[VehicleUpgradeDefinition]:
	var result: Array[VehicleUpgradeDefinition] = []
	for value in definitions.values():
		result.append(value as VehicleUpgradeDefinition)
	result.sort_custom(func(a: VehicleUpgradeDefinition, b: VehicleUpgradeDefinition) -> bool: return String(a.id) < String(b.id))
	return result


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if definitions.size() != EXPECTED_COUNT:
		errors.append("vehicle upgrade catalog expected %d definitions, found %d" % [EXPECTED_COUNT, definitions.size()])
	var seen_titles := {}
	for definition in all_definitions():
		errors.append_array(definition.validate())
		if seen_titles.has(definition.title_key):
			errors.append("duplicate upgrade title key: %s" % definition.title_key)
		seen_titles[definition.title_key] = true
		if definition.requirement != &"" and not definitions.has(definition.requirement):
			errors.append("%s requires missing %s" % [definition.id, definition.requirement])
	return errors


func compatible(definition: VehicleUpgradeDefinition, build: VehicleRunBuild) -> bool:
	if definition == null or build.level_of(definition.id) >= definition.max_level:
		return false
	if definition.requirement != &"" and build.level_of(definition.requirement) <= 0:
		return false
	if definition.exclusion_group == &"element_core" and build.element_core != &"" and build.element_core != definition.id:
		return false
	if definition.requirement != &"" and build.element_core != &"" and _core_for(definition.id) != &"" and _core_for(definition.id) != build.element_core:
		return false
	return true


func offer(build: VehicleRunBuild, run_index: int, stage_index: int, source_id: StringName) -> Array[VehicleUpgradeDefinition]:
	var available: Array[VehicleUpgradeDefinition] = []
	for definition in all_definitions():
		var source_matches := source_id == &"level_up" or definition.source_tags.is_empty() or source_id in definition.source_tags
		if compatible(definition, build) and source_matches:
			available.append(definition)
	var seed_value := hash("%d:%d:%s" % [run_index, stage_index, source_id])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index in range(available.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := available[index]
		available[index] = available[swap_index]
		available[swap_index] = temporary
	var result: Array[VehicleUpgradeDefinition] = []
	if source_id == &"level_up" and stage_index == 0 and build.levels.is_empty():
		_append_first_family(result, available, [&"primary"])
		_append_first_family(result, available, [&"element"])
		_append_first_family(result, available, [&"passive", &"mobility"])
	else:
		_append_first_behavior(result, available)
		for definition in available:
			if result.size() >= 3: break
			if result.is_empty() or definition.family != result[0].family or available.size() <= 3:
				result.append(definition)
		for definition in available:
			if result.size() >= 3: break
			if definition not in result: result.append(definition)
	return result


func _append_first_family(result: Array[VehicleUpgradeDefinition], available: Array[VehicleUpgradeDefinition], families: Array[StringName]) -> void:
	for definition in available:
		if definition.family in families and definition not in result:
			result.append(definition)
			return


func _append_first_behavior(result: Array[VehicleUpgradeDefinition], available: Array[VehicleUpgradeDefinition]) -> void:
	for definition in available:
		if not definition.behavior_ids.is_empty() and definition not in result:
			result.append(definition)
			return


func _core_for(upgrade_id: StringName) -> StringName:
	if upgrade_id in [&"thermal_compound", &"flashover"]: return &"incendiary_core"
	if upgrade_id in [&"concentrated_toxin", &"contagion"]: return &"toxin_core"
	if upgrade_id in [&"deep_freeze", &"shatter"]: return &"cryo_core"
	return &""
