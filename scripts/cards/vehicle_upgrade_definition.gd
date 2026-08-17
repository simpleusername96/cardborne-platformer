class_name VehicleUpgradeDefinition
extends Resource

@export var id: StringName
@export var title_key := ""
@export var description_key := ""
## Optional summary used after the first acquired level.
@export var enhance_description_key := ""
## Player-facing build lane. Trigger ownership and slot ownership remain
## separate so category names stay stable when a behavior changes internally.
@export var category: StringName
## Canonical semantic artwork id resolved by the shared asset provider.
@export var artwork_asset_id: StringName = &""
@export var max_level := 1
@export var modifiers: Array[VehicleStatModifier] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("upgrade id is empty")
	if title_key.is_empty() or description_key.is_empty(): errors.append("%s localization keys are incomplete" % id)
	if category == &"": errors.append("%s category is empty" % id)
	if artwork_asset_id == &"": errors.append("%s artwork asset id is empty" % id)
	if max_level < 1: errors.append("%s max level is invalid" % id)
	for modifier in modifiers:
		if modifier == null or modifier.stat_id == &"" or modifier.values_by_level.size() != max_level:
			errors.append("%s has an invalid stat modifier" % id)
	return errors
