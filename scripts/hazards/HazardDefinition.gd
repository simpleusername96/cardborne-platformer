class_name HazardDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var scene: PackedScene
@export var budget_cost: int = 0
@export var placement_tags: Array[StringName] = []

@export_group("Runtime Semantics")
@export var is_damaging: bool = false
@export var is_static: bool = true
@export var is_reset: bool = false
@export var active_cap: int = 1


func supports_placement(required_tags: Array[StringName]) -> bool:
	for required_tag in required_tags:
		if required_tag not in placement_tags:
			return false
	return true


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Hazard definition ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Hazard definition '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Hazard definition '%s' needs a positive content version." % id)
	if scene == null or not scene.can_instantiate():
		errors.append("Hazard definition '%s' needs an instantiable scene." % id)
	if budget_cost < 0:
		errors.append("Hazard definition '%s' budget cost cannot be negative." % id)
	ContentId.validate_list(
		errors,
		"Hazard definition '%s' placement tag" % id,
		placement_tags,
		true
	)
	if is_damaging and is_reset:
		errors.append("Hazard definition '%s' cannot both damage and reset." % id)
	if active_cap <= 0:
		errors.append("Hazard definition '%s' needs a positive active cap." % id)
	return errors
