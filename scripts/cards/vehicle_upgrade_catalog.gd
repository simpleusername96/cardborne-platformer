class_name VehicleUpgradeCatalog
extends RefCounted

const CARD_PATH := "res://data/cards/vehicle"
const EXPECTED_COUNT := 41
const OPTIONAL_SECONDARY_SLOTS := 2
const ELEMENT_BRANCHES: Array = [
	[&"incendiary_core", &"thermal_compound"],
	[&"toxin_core", &"concentrated_toxin", &"contagion"],
	[&"cryo_core", &"deep_freeze"],
]

var definitions: Dictionary = {}


func _init() -> void:
	_load_definitions()


func _load_definitions() -> void:
	definitions.clear()
	var files := DirAccess.get_files_at(CARD_PATH)
	files.sort()
	for file_name in files:
		var resource_name := _source_resource_name(file_name)
		if resource_name.is_empty():
			continue
		var definition := load(CARD_PATH.path_join(resource_name)) as VehicleUpgradeDefinition
		if definition != null:
			definitions[definition.id] = definition


static func _source_resource_name(file_name: String) -> String:
	# Exported packs expose dynamically enumerated resources through .remap
	# entries; loading the original resource path lets ResourceLoader resolve it.
	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".remap")
	return file_name if file_name.ends_with(".tres") else ""


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
	if (
		definition.family == &"secondary"
		and definition.secondary_slot_kind == &"optional"
		and build.level_of(definition.id) == 0
		and build.active_optional_secondaries() >= OPTIONAL_SECONDARY_SLOTS
	):
		return false
	return true


## Stable within one reward transaction; callers advance offer_serial exactly
## once when a new transaction opens.
func offer(
	build: VehicleRunBuild,
	run_seed: int,
	stage_index: int,
	source_id: StringName,
	offer_serial: int
) -> Array[VehicleUpgradeDefinition]:
	var available: Array[VehicleUpgradeDefinition] = []
	for definition in all_definitions():
		var source_matches := source_id == &"level_up" or definition.source_tags.is_empty() or source_id in definition.source_tags
		if compatible(definition, build) and source_matches:
			available.append(definition)
	var seed_value := hash(
		"upgrade-offer:v2:%d:%d:%s:%d"
		% [run_seed, stage_index, source_id, offer_serial]
	)
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
			_append_unique(result, tuned)
	if source_id == &"level_up" and stage_index == 0 and build.levels.is_empty():
		_append_first_family(result, available, [&"primary"])
		_append_first_family(result, available, [&"element"])
		_append_first_family(result, available, [&"secondary", &"mobility"])
	else:
		if source_id == &"level_up":
			var branch_child := _eligible_branch_child(build, available)
			if branch_child != null:
				_append_unique(result, branch_child)
		_append_first_behavior(result, available)
		for definition in available:
			if result.size() >= 3:
				break
			if (
				(result.is_empty() or definition.family != result[0].family or available.size() <= 3)
				and not _contains_upgrade_id(result, definition.id)
			):
				_append_unique(result, definition)
		for definition in available:
			if result.size() >= 3:
				break
			_append_unique(result, definition)
	return result


func _append_first_family(result: Array[VehicleUpgradeDefinition], available: Array[VehicleUpgradeDefinition], families: Array[StringName]) -> void:
	for definition in available:
		if definition.family in families and not _contains_upgrade_id(result, definition.id):
			_append_unique(result, definition)
			return


func _append_first_behavior(result: Array[VehicleUpgradeDefinition], available: Array[VehicleUpgradeDefinition]) -> void:
	for definition in available:
		if not definition.behavior_ids.is_empty() and not _contains_upgrade_id(result, definition.id):
			_append_unique(result, definition)
			return


func _append_unique(
	result: Array[VehicleUpgradeDefinition],
	definition: VehicleUpgradeDefinition
) -> void:
	if (
		definition != null
		and not _contains_upgrade_id(result, definition.id)
		and result.size() < 3
	):
		result.append(definition)


func _contains_upgrade_id(
	result: Array[VehicleUpgradeDefinition],
	upgrade_id: StringName
) -> bool:
	return result.any(
		func(candidate: VehicleUpgradeDefinition) -> bool:
			return candidate.id == upgrade_id
	)


func _eligible_branch_child(
	build: VehicleRunBuild,
	available: Array[VehicleUpgradeDefinition]
) -> VehicleUpgradeDefinition:
	var candidates: Array[Dictionary] = []
	for branch in ELEMENT_BRANCHES:
		if not build.has(branch[0]):
			continue
		var child: VehicleUpgradeDefinition
		for child_id in branch.slice(1):
			if build.level_of(StringName(child_id)) <= 0:
				child = get_definition(StringName(child_id))
				break
		if child == null:
			for child_id in branch.slice(1):
				var definition := get_definition(StringName(child_id))
				if definition != null and build.level_of(definition.id) < definition.max_level:
					child = definition
					break
		if child != null and child in available:
			var progress := 0
			for branch_id in branch:
				progress += build.level_of(StringName(branch_id))
			candidates.append({
				"definition":child,
				"progress":progress,
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
