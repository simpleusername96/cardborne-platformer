class_name VehicleUpgradeCatalog
extends RefCounted

const CARD_PATH := "res://data/cards/vehicle"
const EXPECTED_COUNT := 28
const EXPECTED_LEVEL_STATES := 92
const OPTIONAL_SECONDARY_SLOTS := 2
const CATEGORIES: Array[StringName] = [
	&"primary", &"secondary", &"element", &"activated", &"chassis", &"combat",
]
## Category capacities constrain only the read-only build rail. Records pack in
## acquisition order; gameplay compatibility remains owned by this catalog.
const CATEGORY_DESCRIPTORS: Array[Dictionary] = [
	{"id":&"primary", "heading_key":"UPGRADE_CATEGORY_PRIMARY", "description_key":"UPGRADE_CATEGORY_PRIMARY_DESCRIPTION", "slot_keys":[&"split_muzzle", &"piercing_rounds"]},
	{"id":&"secondary", "heading_key":"UPGRADE_CATEGORY_SECONDARY", "description_key":"UPGRADE_CATEGORY_SECONDARY_DESCRIPTION", "slot_keys":[&"homing_missiles", &"optional_0", &"optional_1", &"secondary_coolant", &"secondary_amplifier"]},
	{"id":&"element", "heading_key":"UPGRADE_CATEGORY_ELEMENT", "description_key":"UPGRADE_CATEGORY_ELEMENT_DESCRIPTION", "slot_keys":[&"damage", &"utility"]},
	{"id":&"activated", "heading_key":"UPGRADE_CATEGORY_ACTIVATED", "description_key":"UPGRADE_CATEGORY_ACTIVATED_DESCRIPTION", "slot_keys":[&"kind", &"active_coolant", &"active_amplifier"]},
	{"id":&"chassis", "heading_key":"UPGRADE_CATEGORY_CHASSIS", "description_key":"UPGRADE_CATEGORY_CHASSIS_DESCRIPTION", "slot_keys":[&"chassis_speed", &"pickup_radius", &"hull_integrity", &"lifesteal", &"overflow_barrier"]},
	{"id":&"combat", "heading_key":"UPGRADE_CATEGORY_COMBAT", "description_key":"UPGRADE_CATEGORY_COMBAT_DESCRIPTION", "slot_keys":[&"critical_targeting", &"dash_overdrive", &"dash_afterburn_field", &"last_stand_amplifier"]},
]
const SECONDARY_SLOT_KINDS: Array[StringName] = [&"", &"built_in", &"optional"]
const ATTRIBUTE_SLOT_KINDS: Array[StringName] = [&"", &"damage", &"utility"]
const ACTIVE_SLOT_KINDS: Array[StringName] = [&"", &"kind", &"enhancement"]
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
	&"shock_lock_duration",
	&"secondary_cooldown_multiplier",
	&"secondary_damage_multiplier",
	&"active_cooldown_multiplier",
	&"active_damage_multiplier",
]
const EXPECTED_IDS: Array[StringName] = [
	&"active_amplifier", &"active_coolant", &"bio_toxin", &"chassis_speed",
	&"critical_targeting", &"cryo_slow",
	&"dash_afterburn_field", &"dash_overdrive", &"drop_mines",
	&"electric_field", &"gravity_collapse", &"homing_missiles", &"hull_integrity",
	&"kinetic_shockwave",
	&"last_stand_amplifier", &"lifesteal", &"orbiting_blades",
	&"overflow_barrier", &"pickup_radius", &"piercing_rounds",
	&"piercing_lance", &"secondary_amplifier", &"secondary_coolant",
	&"shock_disruption", &"split_muzzle", &"storm_barrage", &"thermal_burst",
	&"auto_laser",
]
const ATTACK_UPGRADE_IDS := {
	&"split_muzzle":true,
	&"piercing_rounds":true,
	&"homing_missiles":true,
	&"electric_field":true,
	&"orbiting_blades":true,
	&"drop_mines":true,
	&"auto_laser":true,
	&"thermal_burst":true,
	&"bio_toxin":true,
	&"critical_targeting":true,
	&"dash_overdrive":true,
	&"dash_afterburn_field":true,
	&"last_stand_amplifier":true,
	&"storm_barrage":true,
	&"secondary_amplifier":true,
	&"gravity_collapse":true,
	&"kinetic_shockwave":true,
	&"piercing_lance":true,
	&"active_amplifier":true,
}

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
		if definition.secondary_slot_kind != &"" and definition.category != &"secondary":
			errors.append("%s secondary slot kind is outside the secondary category" % definition.id)
		if definition.attribute_slot_kind not in ATTRIBUTE_SLOT_KINDS:
			errors.append("%s has invalid attribute slot kind" % definition.id)
		if definition.attribute_slot_kind != &"" and definition.category != &"element":
			errors.append("%s attribute slot kind is outside the element category" % definition.id)
		if definition.active_slot_kind not in ACTIVE_SLOT_KINDS:
			errors.append("%s has invalid active slot kind" % definition.id)
		if (definition.active_slot_kind != &"") != (definition.category == &"activated"):
			errors.append("%s category and active slot kind disagree" % definition.id)
		for modifier in definition.modifiers:
			if modifier.operation not in MODIFIER_OPERATIONS:
				errors.append("%s has invalid modifier operation %s" % [definition.id, modifier.operation])
			if modifier.display_unit not in MODIFIER_DISPLAY_UNITS:
				errors.append("%s has invalid modifier display unit %s" % [definition.id, modifier.display_unit])
			if modifier.stat_id not in STAT_IDS:
				errors.append("%s has unknown stat id %s" % [definition.id, modifier.stat_id])
	if level_states != EXPECTED_LEVEL_STATES:
		errors.append("vehicle upgrade catalog expected %d level states, found %d" % [EXPECTED_LEVEL_STATES, level_states])
	errors.append_array(_validate_category_descriptors())
	return errors


func category_descriptors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for descriptor in CATEGORY_DESCRIPTORS:
		var copy := descriptor.duplicate(true)
		copy["capacity"] = Array(copy["slot_keys"]).size()
		result.append(copy)
	return result


func category_descriptor(category_id: StringName) -> Dictionary:
	for descriptor in category_descriptors():
		if StringName(descriptor["id"]) == category_id:
			return descriptor
	return {}


func category_slot_key(definition: VehicleUpgradeDefinition, build: VehicleRunBuild) -> StringName:
	if definition == null:
		return &""
	match definition.category:
		&"primary", &"chassis", &"combat": return definition.id
		&"secondary":
			if definition.secondary_slot_kind == &"optional":
				return build.optional_secondary_slot_key(definition.id)
			return definition.id
		&"element": return definition.attribute_slot_kind
		&"activated": return definition.id if definition.active_slot_kind == &"enhancement" else definition.active_slot_kind
	return &""


func _validate_category_descriptors() -> PackedStringArray:
	var errors := PackedStringArray()
	var descriptor_categories: Array[StringName] = []
	var fixed_card_ids := {}
	for descriptor in category_descriptors():
		var category_id := StringName(descriptor["id"])
		descriptor_categories.append(category_id)
		var slots: Array = descriptor["slot_keys"]
		if slots.is_empty():
			errors.append("%s has no category build positions" % category_id)
		for slot_variant in slots:
			var slot_key := StringName(slot_variant)
			if slot_key not in [&"optional_0", &"optional_1", &"damage", &"utility", &"kind"]:
				if fixed_card_ids.has(slot_key):
					errors.append("duplicate category build position %s" % slot_key)
				fixed_card_ids[slot_key] = true
	if descriptor_categories != CATEGORIES:
		errors.append("category descriptors must retain catalog category order")
	for definition in all_definitions():
		if definition.category == &"secondary" and definition.secondary_slot_kind == &"optional":
			continue
		if definition.category == &"element" and definition.attribute_slot_kind != &"":
			continue
		if definition.category == &"activated" and definition.active_slot_kind == &"kind":
			continue
		if not fixed_card_ids.has(definition.id):
			errors.append("%s has no fixed category build position" % definition.id)
	return errors


func compatible(definition: VehicleUpgradeDefinition, build: VehicleRunBuild) -> bool:
	if definition == null or build.level_of(definition.id) >= definition.max_level:
		return false
	if definition.attribute_slot_kind != &"":
		var active_attribute := build.active_attribute_id(definition.attribute_slot_kind)
		if not active_attribute.is_empty() and definition.id != active_attribute:
			return false
	if definition.active_slot_kind == &"kind":
		var active_kind := build.active_weapon_card_id()
		if not active_kind.is_empty() and definition.id != active_kind:
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
	offer_serial: int,
	opening_emp_enhancement_required := false
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
	var opening_emp_enhancement := _opening_emp_enhancement(
		available, build, stage_index, source_id,
		opening_emp_enhancement_required
	)
	if opening_emp_enhancement != null:
		result.append(opening_emp_enhancement)
	var used_categories := {}
	if opening_emp_enhancement != null:
		used_categories[opening_emp_enhancement.category] = true
	if stage_index >= 2:
		for definition in available:
			if ATTACK_UPGRADE_IDS.has(definition.id):
				_append_unique(result, definition)
				used_categories[definition.category] = true
				break
	for definition in available:
		if result.size() >= 3:
			break
		if opening_emp_enhancement != null and definition.category == &"activated":
			continue
		if used_categories.has(definition.category):
			continue
		_append_unique(result, definition)
		used_categories[definition.category] = true
	for definition in available:
		if result.size() >= 3:
			break
		if opening_emp_enhancement != null and definition.category == &"activated":
			continue
		_append_unique(result, definition)
	return result


func _opening_emp_enhancement(
	available: Array[VehicleUpgradeDefinition],
	build: VehicleRunBuild,
	stage_index: int,
	source_id: StringName,
	opening_emp_enhancement_required: bool
) -> VehicleUpgradeDefinition:
	if (
		not opening_emp_enhancement_required
		or
		stage_index != 0
		or source_id != &"level_up"
		or build.active_weapon_id() != &"emp"
	):
		return null
	for upgrade_id in [&"active_amplifier", &"active_coolant"]:
		for definition in available:
			if definition.id == upgrade_id:
				return definition
	return null


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
