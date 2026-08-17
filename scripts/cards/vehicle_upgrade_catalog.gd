class_name VehicleUpgradeCatalog
extends RefCounted

const CARD_PATH := "res://data/cards/vehicle"
const EXPECTED_COUNT := 27
const EXPECTED_LEVEL_STATES := 91
const AUTOMATIC_WEAPON_SLOTS := 3
const CATEGORIES: Array[StringName] = [
	&"primary", &"secondary", &"element", &"activated", &"chassis", &"combat",
]
## Category capacities constrain only the read-only build rail. Records pack in
## acquisition order; gameplay compatibility remains owned by this catalog.
const CATEGORY_DESCRIPTORS: Array[Dictionary] = [
	{"id":&"primary", "heading_key":"UPGRADE_CATEGORY_PRIMARY", "description_key":"UPGRADE_CATEGORY_PRIMARY_DESCRIPTION", "slot_keys":[&"split_muzzle", &"piercing_rounds"]},
	{"id":&"secondary", "heading_key":"UPGRADE_CATEGORY_SECONDARY", "description_key":"UPGRADE_CATEGORY_SECONDARY_DESCRIPTION", "slot_keys":[&"weapon_0", &"weapon_1", &"weapon_2"]},
	{"id":&"element", "heading_key":"UPGRADE_CATEGORY_ELEMENT", "description_key":"UPGRADE_CATEGORY_ELEMENT_DESCRIPTION", "slot_keys":[&"slot_0", &"slot_1"]},
	{"id":&"activated", "heading_key":"UPGRADE_CATEGORY_ACTIVATED", "description_key":"UPGRADE_CATEGORY_ACTIVATED_DESCRIPTION", "slot_keys":[&"weapon"]},
	{"id":&"chassis", "heading_key":"UPGRADE_CATEGORY_CHASSIS", "description_key":"UPGRADE_CATEGORY_CHASSIS_DESCRIPTION", "slot_keys":[&"chassis_speed", &"pickup_radius", &"hull_integrity", &"lifesteal", &"overflow_barrier"]},
	{"id":&"combat", "heading_key":"UPGRADE_CATEGORY_COMBAT", "description_key":"UPGRADE_CATEGORY_COMBAT_DESCRIPTION", "slot_keys":[&"critical_targeting", &"dash_overdrive", &"dash_afterburn_field", &"last_stand_amplifier", &"miss_compensation", &"hit_chain", &"braced_fire"]},
]
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
	&"cryo_shatter_damage",
]
const EXPECTED_IDS: Array[StringName] = [
	&"auto_laser", &"bio_toxin", &"chassis_speed",
	&"critical_targeting", &"cryo_slow",
	&"dash_afterburn_field", &"dash_overdrive", &"drop_mines",
	&"electric_field", &"emp", &"gravity_collapse", &"homing_missiles", &"hull_integrity",
	&"kinetic_shockwave",
	&"last_stand_amplifier", &"lifesteal", &"orbiting_blades",
	&"miss_compensation", &"hit_chain", &"braced_fire",
	&"overflow_barrier", &"pickup_radius", &"piercing_rounds",
	&"piercing_lance",
	&"split_muzzle", &"storm_barrage", &"thermal_burst",
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
	&"emp":true,
	&"gravity_collapse":true,
	&"kinetic_shockwave":true,
	&"piercing_lance":true,
	&"miss_compensation":true,
	&"hit_chain":true,
	&"braced_fire":true,
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
		if (
			definition.category == &"element"
			and definition.id not in VehicleRunBuild.ATTRIBUTE_IDS
		):
			errors.append("%s is not a supported primary attribute" % definition.id)
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
		&"secondary": return build.automatic_weapon_slot_key(definition.id)
		&"element": return build.attribute_slot_key(definition.id)
		&"activated": return &"weapon"
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
			if slot_key not in [&"weapon_0", &"weapon_1", &"weapon_2", &"weapon", &"damage", &"utility"]:
				if fixed_card_ids.has(slot_key):
					errors.append("duplicate category build position %s" % slot_key)
				fixed_card_ids[slot_key] = true
	if descriptor_categories != CATEGORIES:
		errors.append("category descriptors must retain catalog category order")
	for definition in all_definitions():
		if definition.category == &"secondary":
			continue
		if definition.category == &"element":
			continue
		if definition.category == &"activated":
			continue
		if not fixed_card_ids.has(definition.id):
			errors.append("%s has no fixed category build position" % definition.id)
	return errors


func compatible(definition: VehicleUpgradeDefinition, build: VehicleRunBuild) -> bool:
	if definition == null or build.level_of(definition.id) >= definition.max_level:
		return false
	if (
		definition.category == &"element"
		and build.level_of(definition.id) == 0
		and build.active_attribute_ids().size() >= VehicleRunBuild.ATTRIBUTE_SLOTS
	):
		return false
	if definition.category == &"activated":
		var active_kind := build.active_weapon_card_id()
		if not active_kind.is_empty() and definition.id != active_kind:
			return false
	if (
		definition.category == &"secondary"
		and build.level_of(definition.id) == 0
		and build.active_automatic_weapons() >= AUTOMATIC_WEAPON_SLOTS
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
	opening_weapon_mix_required := false
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
	# A missing active weapon and missing automatic weapon each reserve one
	# independent offer position before ordinary category diversity is applied.
	if build.active_weapon_card_id().is_empty():
		_append_first_category(result, available, &"activated")
	if build.active_automatic_weapons() == 0:
		_append_first_category(result, available, &"secondary")
	if result.is_empty() and opening_weapon_mix_required and stage_index == 0 and source_id == &"level_up":
		_append_first_category(result, available, &"activated")
		_append_first_category(result, available, &"secondary")
		for definition in available:
			if definition.category not in [&"activated", &"secondary"]:
				_append_unique(result, definition)
				break
		return result
	if stage_index >= 2:
		for definition in available:
			if ATTACK_UPGRADE_IDS.has(definition.id):
				_append_unique(result, definition)
				used_categories[definition.category] = true
				break
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


func _append_first_category(
	result: Array[VehicleUpgradeDefinition],
	available: Array[VehicleUpgradeDefinition],
	category: StringName
) -> void:
	for definition in available:
		if definition.category == category:
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
