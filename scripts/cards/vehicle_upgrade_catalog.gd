class_name VehicleUpgradeCatalog
extends RefCounted

const CARD_PATH := "res://data/cards/vehicle"
const EXPECTED_COUNT := 46
const SECONDARY_FAMILY_IDS: Array[StringName] = [&"ion_field", &"orbit_blades", &"wake_mines", &"escort_drone"]
const OPTIONAL_SECONDARY_SLOTS := 2

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
	if definition.id in SECONDARY_FAMILY_IDS and build.level_of(definition.id) == 0 and build.active_optional_secondaries() >= OPTIONAL_SECONDARY_SLOTS:
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
	if source_id == &"level_up" and build.total_levels() == 1 and not build.has(&"tuned_thrusters"):
		var tuned := get_definition(&"tuned_thrusters")
		if tuned != null and tuned in available:
			result.append(tuned)
	if source_id == &"level_up" and stage_index == 0 and build.levels.is_empty():
		_append_first_family(result, available, [&"primary"])
		_append_first_family(result, available, [&"element"])
		_append_first_family(result, available, [&"passive", &"mobility"])
	else:
		if source_id == &"level_up":
			var branch_child := _eligible_branch_child(build, available)
			if branch_child != null:
				result.append(branch_child)
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


func _eligible_branch_child(
	build: VehicleRunBuild,
	available: Array[VehicleUpgradeDefinition]
) -> VehicleUpgradeDefinition:
	var branches := [
		[&"incendiary_core", &"thermal_compound", &"flashover"],
		[&"toxin_core", &"concentrated_toxin", &"contagion"],
		[&"cryo_core", &"deep_freeze", &"shatter"],
	]
	var candidates: Array[Dictionary] = []
	for branch in branches:
		if not build.has(branch[0]):
			continue
		var child: VehicleUpgradeDefinition
		if build.level_of(branch[1]) <= 0:
			child = get_definition(branch[1])
		elif not build.has(branch[2]):
			child = get_definition(branch[2])
		elif build.level_of(branch[1]) < get_definition(branch[1]).max_level:
			child = get_definition(branch[1])
		if child != null and child in available:
			candidates.append({
				"definition":child,
				"progress":build.level_of(branch[0]) + build.level_of(branch[1]) + build.level_of(branch[2]),
				"seeded_order":available.find(child),
			})
	if candidates.is_empty():
		return null
	candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["progress"]) != int(b["progress"]):
				return int(a["progress"]) < int(b["progress"])
			return int(a["seeded_order"]) < int(b["seeded_order"])
	)
	return candidates[0]["definition"] as VehicleUpgradeDefinition
