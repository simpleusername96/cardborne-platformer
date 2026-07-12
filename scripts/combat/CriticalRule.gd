class_name CriticalRule
extends Resource

@export var id: StringName
@export var content_version: int = 1
@export var required_target_flags: Array[StringName] = []
@export var required_context_flags: Array[StringName] = []
@export_range(1.0, 2.0, 0.05) var multiplier: float = 1.5
@export var consumed_target_flags: Array[StringName] = []


func is_satisfied(target_state: Dictionary, hit_context: Dictionary) -> bool:
	for flag in required_target_flags:
		if not bool(target_state.get(String(flag), false)):
			return false
	for flag in required_context_flags:
		if not bool(hit_context.get(String(flag), false)):
			return false
	return not required_target_flags.is_empty() or not required_context_flags.is_empty()


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty():
		errors.append("Critical rule ID cannot be blank.")
	if content_version <= 0:
		errors.append("Critical rule '%s' needs a positive content version." % id)
	if required_target_flags.is_empty() and required_context_flags.is_empty():
		errors.append("Critical rule '%s' needs an earned condition." % id)
	if multiplier <= 1.0 or multiplier > 2.0:
		errors.append("Critical rule '%s' multiplier must be above 1 and at most 2." % id)
	for consumed_flag in consumed_target_flags:
		if not required_target_flags.has(consumed_flag):
			errors.append(
				"Critical rule '%s' consumes undeclared target flag '%s'." % [id, consumed_flag]
			)
	return errors
