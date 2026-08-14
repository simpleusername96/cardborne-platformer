class_name VehicleSecondaryCatalog
extends RefCounted

## Sole resource-loading and lookup boundary for secondary-weapon definitions.

const DEFINITION_PATH := "res://data/weapons/vehicle/secondary"
const EXPECTED_IDS: Array[StringName] = [
	&"auto_laser", &"drop_mines", &"electric_field", &"orbiting_blades",
	&"seeker", &"storm_barrage",
]

var definitions: Dictionary = {}
var load_errors := PackedStringArray()


func _init() -> void:
	_load_definitions()


func _load_definitions() -> void:
	definitions.clear()
	load_errors.clear()
	var files := DirAccess.get_files_at(DEFINITION_PATH)
	files.sort()
	for file_name in files:
		var resource_name := _source_resource_name(file_name)
		if resource_name.is_empty():
			continue
		var definition := load(
			DEFINITION_PATH.path_join(resource_name)
		) as VehicleSecondaryDefinition
		if definition == null:
			continue
		if definitions.has(definition.id):
			load_errors.append("duplicate vehicle secondary id: %s" % definition.id)
			continue
		definitions[definition.id] = definition


static func _source_resource_name(file_name: String) -> String:
	# Dynamic discovery must resolve the same resource in source and export trees.
	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".remap")
	return file_name if file_name.ends_with(".tres") else ""


func get_definition(secondary_id: StringName) -> VehicleSecondaryDefinition:
	return definitions.get(secondary_id) as VehicleSecondaryDefinition


func get_by_upgrade_id(upgrade_id: StringName) -> VehicleSecondaryDefinition:
	for definition_variant in definitions.values():
		var definition := definition_variant as VehicleSecondaryDefinition
		if definition != null and definition.upgrade_id == upgrade_id:
			return definition
	return null


func validate_contract() -> PackedStringArray:
	var errors := load_errors.duplicate()
	var actual_ids: Array = definitions.keys()
	actual_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	var expected_ids: Array = EXPECTED_IDS.duplicate()
	expected_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	if actual_ids != expected_ids:
		errors.append("vehicle secondary catalog id set differs from the live contract")
	for definition_variant in definitions.values():
		var definition := definition_variant as VehicleSecondaryDefinition
		if definition == null or definition.upgrade_id == &"":
			errors.append("vehicle secondary definition has no upgrade owner")
			continue
		var expected_states := 4 if definition.id in [
			&"seeker", &"drop_mines", &"electric_field", &"orbiting_blades"
		] else 3
		if (
			definition.values_by_level.size() != expected_states
			or definition.auxiliary_by_level.size() != expected_states
			or definition.cadence_by_level.size() != expected_states
			or definition.cap_by_level.size() != expected_states
		):
			errors.append("%s must own exactly %d bounded states" % [definition.id, expected_states])
		if definition.id == &"seeker" and definition.structure_damage_by_level.size() != expected_states:
			errors.append("seeker must own structure damage for every level")
	return errors
