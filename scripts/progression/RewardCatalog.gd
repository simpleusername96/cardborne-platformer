class_name RewardCatalog
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tables: Array[RewardTable] = []


func get_table(table_id: StringName) -> RewardTable:
	for table in tables:
		if table != null and table.id == table_id:
			return table
	return null


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Reward catalog ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Reward catalog '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Reward catalog '%s' needs a positive content version." % id)
	var seen: Dictionary = {}
	for table_index in tables.size():
		var table := tables[table_index]
		if table == null:
			errors.append("Reward table at index %d is null." % table_index)
			continue
		var table_id := String(table.id)
		if seen.has(table_id):
			errors.append("Reward catalog repeats table '%s'." % table_id)
		seen[table_id] = true
		for table_error in table.validate_definition():
			errors.append(table_error)
	return errors
