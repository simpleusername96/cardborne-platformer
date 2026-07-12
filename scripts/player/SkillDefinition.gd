class_name SkillDefinition
extends AttackDefinition

@export_range(1, 3, 1) var skill_slot: int = 1
@export_range(0.0, 2000.0, 1.0) var movement_distance: float = 0.0
@export var frontal_guard_during_active: bool = false
@export_range(1, 16, 1) var max_targets: int = 1


func validate_definition() -> PackedStringArray:
	var errors := super.validate_definition()
	if skill_slot < 1 or skill_slot > 3:
		errors.append("Skill '%s' slot must be between 1 and 3." % id)
	if movement_distance < 0.0:
		errors.append("Skill '%s' movement distance cannot be negative." % id)
	if max_targets <= 0:
		errors.append("Skill '%s' needs a positive target cap." % id)
	return errors
