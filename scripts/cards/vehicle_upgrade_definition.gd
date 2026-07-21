class_name VehicleUpgradeDefinition
extends Resource

@export var id: StringName
@export var title_key := ""
@export var description_key := ""
@export var family: StringName
@export var max_level := 1
@export var requirement: StringName
@export var exclusion_group: StringName
@export var source_tags: Array[StringName] = []
@export var behavior_ids: Array[StringName] = []
@export var modifiers: Array[VehicleStatModifier] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("upgrade id is empty")
	if title_key.is_empty() or description_key.is_empty(): errors.append("%s localization keys are incomplete" % id)
	if family == &"": errors.append("%s family is empty" % id)
	if max_level < 1: errors.append("%s max level is invalid" % id)
	for modifier in modifiers:
		if modifier == null or modifier.stat_id == &"" or modifier.values_by_level.size() != max_level:
			errors.append("%s has an invalid stat modifier" % id)
	return errors
