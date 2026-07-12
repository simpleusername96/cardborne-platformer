class_name MicroUpgradeDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var content_version: int = 1
@export_range(1, 99, 1) var max_stacks: int = 1
@export var effects: Array[EffectDefinition] = []
@export_range(0, 99, 1) var heal_on_apply: int = 0
@export var recovery_choice: bool = false


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Micro-upgrade ID", id)
	if display_name.strip_edges().is_empty() or description.strip_edges().is_empty():
		errors.append("Micro-upgrade '%s' needs a display name and description." % id)
	if content_version <= 0 or max_stacks <= 0:
		errors.append("Micro-upgrade '%s' has invalid version or stack cap." % id)
	if effects.is_empty() and heal_on_apply <= 0:
		errors.append("Micro-upgrade '%s' needs an effect or immediate heal." % id)
	return errors
