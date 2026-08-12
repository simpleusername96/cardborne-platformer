class_name VehicleActiveWeaponCatalog
extends RefCounted

## Sole resource-loading and lookup boundary for equipped active weapons.

const DEFINITION_PATH := "res://data/weapons/vehicle/active"
const EXPECTED_IDS: Array[StringName] = [&"black_hole", &"cross_beam", &"emp", &"shockwave"]

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
		var definition := load(DEFINITION_PATH.path_join(resource_name)) as VehicleActiveWeaponDefinition
		if definition == null:
			continue
		if definitions.has(definition.id):
			load_errors.append("duplicate vehicle active weapon id: %s" % definition.id)
			continue
		definitions[definition.id] = definition


static func _source_resource_name(file_name: String) -> String:
	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".remap")
	return file_name if file_name.ends_with(".tres") else ""


func get_definition(active_weapon_id: StringName) -> VehicleActiveWeaponDefinition:
	return definitions.get(active_weapon_id) as VehicleActiveWeaponDefinition


func validate_contract() -> PackedStringArray:
	var errors := load_errors.duplicate()
	var actual_ids: Array = definitions.keys()
	actual_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	var expected_ids: Array = EXPECTED_IDS.duplicate()
	expected_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	if actual_ids != expected_ids:
		errors.append("vehicle active weapon catalog id set differs from the live contract")
	for definition_variant in definitions.values():
		var definition := definition_variant as VehicleActiveWeaponDefinition
		if definition == null:
			continue
		var expected_states := 1 if definition.id == &"emp" else 4
		if definition.damage_by_level.size() != expected_states or definition.size_by_level.size() != expected_states:
			errors.append("%s must own exactly %d bounded states" % [definition.id, expected_states])
		if definition.id != &"emp" and definition.upgrade_id == &"":
			errors.append("%s has no upgrade owner" % definition.id)
	return errors
