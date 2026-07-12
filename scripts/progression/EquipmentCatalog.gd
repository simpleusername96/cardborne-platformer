class_name EquipmentCatalog
extends Resource

const EXPECTED_ITEM_IDS: Array[StringName] = [
	&"iron_cleaver",
	&"bell_hammer",
	&"field_bow",
	&"twinstring_bow",
	&"rust_knives",
	&"hooked_blades",
	&"traveler_jacket",
	&"patched_mail",
	&"runner_cloak",
	&"copper_charm",
	&"spring_charm",
	&"slime_relic",
]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var items: Array[EquipmentDefinition] = []


func get_item(item_id: StringName) -> EquipmentDefinition:
	for item in items:
		if item != null and item.id == item_id:
			return item
	return null


func has_item(item_id: StringName) -> bool:
	return get_item(item_id) != null


func get_compatible(character_id: StringName) -> Array[EquipmentDefinition]:
	var compatible: Array[EquipmentDefinition] = []
	if character_id not in [&"warrior", &"archer", &"assassin"]:
		return compatible
	for item in items:
		if item != null and item.is_compatible(character_id):
			compatible.append(item)
	return compatible


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Equipment catalog ID", id)
	if display_name.strip_edges().is_empty() or content_version <= 0:
		errors.append("Equipment catalog needs a display name and positive version.")
	if items.size() != EXPECTED_ITEM_IDS.size():
		errors.append("First-run equipment catalog needs exactly %d items." % EXPECTED_ITEM_IDS.size())

	var seen: Dictionary = {}
	for item_index in items.size():
		var item := items[item_index]
		if item == null:
			errors.append("Equipment item at index %d is null." % item_index)
			continue
		if seen.has(item.id):
			errors.append("Equipment catalog repeats '%s'." % item.id)
		seen[item.id] = true
		for item_error in item.validate_definition():
			errors.append(item_error)
	for expected_id in EXPECTED_ITEM_IDS:
		if not seen.has(expected_id):
			errors.append("Equipment catalog is missing required item '%s'." % expected_id)
	for actual_id in seen:
		if not EXPECTED_ITEM_IDS.has(StringName(actual_id)):
			errors.append("Equipment catalog contains unexpected item '%s'." % actual_id)
	return errors
