class_name RewardTable
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var entries: Array[RewardEntry] = []


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Reward table ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Reward table '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Reward table '%s' needs a positive content version." % id)
	if entries.is_empty():
		errors.append("Reward table '%s' needs at least one entry." % id)
	for entry_index in entries.size():
		var entry := entries[entry_index]
		if entry == null:
			errors.append("Reward table '%s' entry %d is null." % [id, entry_index])
			continue
		for entry_error in entry.validate_definition():
			errors.append("Reward table '%s': %s" % [id, entry_error])
	return errors
