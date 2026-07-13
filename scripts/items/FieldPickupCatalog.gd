class_name FieldPickupCatalog
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var definitions: Array[FieldPickupDefinition] = []


func get_definition(definition_id: StringName) -> FieldPickupDefinition:
	for definition in definitions:
		if definition != null and definition.id == definition_id:
			return definition
	return null


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Field pickup catalog ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Field pickup catalog '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Field pickup catalog '%s' needs a positive content version." % id)
	if definitions.is_empty():
		errors.append("Field pickup catalog '%s' needs at least one definition." % id)
	var seen_ids: Dictionary = {}
	for definition_index in definitions.size():
		var definition := definitions[definition_index]
		if definition == null:
			errors.append("Field pickup definition at index %d is null." % definition_index)
			continue
		var definition_id := String(definition.id)
		if seen_ids.has(definition_id):
			errors.append("Duplicate field pickup definition ID '%s'." % definition_id)
		seen_ids[definition_id] = true
		for definition_error in definition.validate_definition():
			errors.append(definition_error)
	return errors
