class_name HazardCatalog
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var definitions: Array[HazardDefinition] = []


func get_hazard(hazard_id: StringName) -> HazardDefinition:
	for definition in definitions:
		if definition != null and definition.id == hazard_id:
			return definition
	return null


func get_definition(hazard_id: StringName) -> HazardDefinition:
	return get_hazard(hazard_id)


func get_eligible(
	required_placement_tags: Array[StringName],
	maximum_budget_cost: int
) -> Array[HazardDefinition]:
	var eligible: Array[HazardDefinition] = []
	if maximum_budget_cost < 0:
		return eligible
	for definition in definitions:
		if definition == null or definition.budget_cost > maximum_budget_cost:
			continue
		if definition.supports_placement(required_placement_tags):
			eligible.append(definition)
	return eligible


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Hazard catalog ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Hazard catalog '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Hazard catalog '%s' needs a positive content version." % id)
	if definitions.is_empty():
		errors.append("Hazard catalog '%s' needs at least one definition." % id)

	var seen_ids: Dictionary = {}
	for definition_index in definitions.size():
		var definition := definitions[definition_index]
		if definition == null:
			errors.append("Hazard definition at index %d is null." % definition_index)
			continue
		var definition_id := String(definition.id)
		if seen_ids.has(definition_id):
			errors.append("Duplicate hazard definition ID '%s'." % definition_id)
		seen_ids[definition_id] = true
		for definition_error in definition.validate_definition():
			errors.append("Hazard definition '%s': %s" % [definition.id, definition_error])
	return errors
