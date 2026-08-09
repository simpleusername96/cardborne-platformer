class_name VehicleUpgradeCatalog
extends RefCounted

const CARD_PATH := "res://data/cards/vehicle"
const EXPECTED_COUNT := 13
const EXPECTED_LEVEL_STATES := 36
const OPTIONAL_SECONDARY_SLOTS := 2
const CATEGORIES: Array[StringName] = [
	&"primary", &"secondary", &"element", &"chassis",
]
const SECONDARY_SLOT_KINDS: Array[StringName] = [&"", &"built_in", &"optional"]
const MODIFIER_OPERATIONS: Array[String] = ["add", "multiply"]
const MODIFIER_DISPLAY_UNITS: Array[String] = ["none", "percent", "seconds"]
const STAT_IDS: Array[StringName] = [
	&"move_speed_multiplier",
	&"pickup_radius_bonus",
	&"max_health_bonus",
	&"lifesteal_percent",
	&"thermal_burst_radius",
	&"thermal_burst_damage",
	&"toxin_dps_per_stack",
	&"toxin_duration",
	&"cryo_slow_per_stack",
	&"cryo_duration",
]
const EXPECTED_IDS: Array[StringName] = [
	&"bio_toxin", &"chassis_speed", &"cryo_slow", &"drop_mines",
	&"electric_field", &"homing_missiles", &"hull_integrity", &"lifesteal",
	&"orbiting_blades", &"pickup_radius", &"piercing_rounds",
	&"split_muzzle", &"thermal_burst",
]

var definitions: Dictionary = {}
var load_errors := PackedStringArray()


func _init() -> void:
	_load_definitions()


func _load_definitions() -> void:
	definitions.clear()
	load_errors.clear()
	var files := DirAccess.get_files_at(CARD_PATH)
	files.sort()
	for file_name in files:
		var resource_name := _source_resource_name(file_name)
		if resource_name.is_empty():
			continue
		var definition := load(CARD_PATH.path_join(resource_name)) as VehicleUpgradeDefinition
		if definition != null:
			if definitions.has(definition.id):
				load_errors.append("duplicate vehicle upgrade id: %s" % definition.id)
				continue
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
	var errors := load_errors.duplicate()
	if definitions.size() != EXPECTED_COUNT:
		errors.append("vehicle upgrade catalog expected %d definitions, found %d" % [EXPECTED_COUNT, definitions.size()])
	var actual_ids: Array = definitions.keys()
	actual_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	var expected_ids: Array = EXPECTED_IDS.duplicate()
	expected_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	if actual_ids != expected_ids:
		errors.append("vehicle upgrade catalog id set differs from the minimal contract")
	var seen_titles := {}
	var level_states := 0
	for definition in all_definitions():
		errors.append_array(definition.validate())
		level_states += definition.max_level
		if seen_titles.has(definition.title_key):
			errors.append("duplicate upgrade title key: %s" % definition.title_key)
		seen_titles[definition.title_key] = true
		if definition.category not in CATEGORIES:
			errors.append("%s has invalid category %s" % [definition.id, definition.category])
		if definition.secondary_slot_kind not in SECONDARY_SLOT_KINDS:
			errors.append("%s has invalid secondary slot kind" % definition.id)
		var is_secondary := definition.category == &"secondary"
		if is_secondary != (definition.secondary_slot_kind != &""):
			errors.append("%s category and secondary slot kind disagree" % definition.id)
		for modifier in definition.modifiers:
			if modifier.operation not in MODIFIER_OPERATIONS:
				errors.append("%s has invalid modifier operation %s" % [definition.id, modifier.operation])
			if modifier.display_unit not in MODIFIER_DISPLAY_UNITS:
				errors.append("%s has invalid modifier display unit %s" % [definition.id, modifier.display_unit])
			if modifier.stat_id not in STAT_IDS:
				errors.append("%s has unknown stat id %s" % [definition.id, modifier.stat_id])
	if level_states != EXPECTED_LEVEL_STATES:
		errors.append("vehicle upgrade catalog expected %d level states, found %d" % [EXPECTED_LEVEL_STATES, level_states])
	return errors


func compatible(definition: VehicleUpgradeDefinition, build: VehicleRunBuild) -> bool:
	if definition == null or build.level_of(definition.id) >= definition.max_level:
		return false
	if definition.category == &"element":
		var active_element := build.active_element_id()
		if not active_element.is_empty() and definition.id != active_element:
			return false
	if (
		definition.category == &"secondary"
		and definition.secondary_slot_kind == &"optional"
		and build.level_of(definition.id) == 0
		and build.active_optional_secondaries() >= OPTIONAL_SECONDARY_SLOTS
	):
		return false
	return true


func compatible_definitions(build: VehicleRunBuild) -> Array[VehicleUpgradeDefinition]:
	var result: Array[VehicleUpgradeDefinition] = []
	for definition in all_definitions():
		if compatible(definition, build):
			result.append(definition)
	return result


## Stable within one reward transaction; callers advance offer_serial exactly
## once when a new transaction opens.
func offer(
	build: VehicleRunBuild,
	run_seed: int,
	stage_index: int,
	source_id: StringName,
	offer_serial: int
) -> Array[VehicleUpgradeDefinition]:
	var available := compatible_definitions(build)
	var seed_value := hash(
		"upgrade-offer:v3:%d:%d:%s:%d"
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
	var used_categories := {}
	for definition in available:
		if result.size() >= 3:
			break
		if used_categories.has(definition.category):
			continue
		_append_unique(result, definition)
		used_categories[definition.category] = true
	for definition in available:
		if result.size() >= 3:
			break
		_append_unique(result, definition)
	return result


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
