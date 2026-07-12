class_name StageProfile
extends Resource

@export var id: StringName = &"ruin_approach"
@export var display_name: String = "Ruin Approach"
@export var content_version: int = 1
@export var required_room_count: int = 6
@export var required_roles: Array[StringName] = [
	&"start", &"traversal", &"combat", &"choice", &"combat", &"exit",
]
@export var optional_branch_count: Vector2i = Vector2i(1, 1)
@export var optional_room_role: StringName = &"optional"
@export var terminal_room_role: StringName = &"exit"
@export var eligible_enemy_archetypes: Array[StringName] = [
	&"walker", &"charger", &"shooter",
]
@export var eligible_hazards: Array[StringName] = [&"spike_row", &"fall_reset"]
@export var encounter_budget_per_combat_room: Vector2i = Vector2i(1, 3)
@export var hazard_budget_per_room: Vector2i = Vector2i(0, 1)
@export var reward_budget_per_room: Vector2i = Vector2i(0, 3)
@export var fallback_id: StringName = &"fallback_ruin_approach_v1"


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Stage profile ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Stage profile '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Stage profile '%s' needs a positive content version." % id)
	if required_room_count <= 0 or required_room_count != required_roles.size():
		errors.append(
			"Stage profile '%s' required room count must match its role sequence."
			% id
		)
	if required_roles.is_empty() or required_roles[0] != &"start":
		errors.append("Stage profile '%s' required route must begin with start." % id)
	if required_roles.is_empty() or required_roles[-1] != terminal_room_role:
		errors.append("Stage profile '%s' required route must end with its terminal role." % id)
	for role in required_roles:
		if not RoomTemplateData.ROLES.has(role):
			errors.append("Stage profile '%s' has invalid required role '%s'." % [id, role])
	if not RoomTemplateData.ROLES.has(optional_room_role):
		errors.append("Stage profile '%s' has invalid optional room role '%s'." % [id, optional_room_role])
	if not RoomTemplateData.ROLES.has(terminal_room_role):
		errors.append("Stage profile '%s' has invalid terminal role '%s'." % [id, terminal_room_role])
	if optional_branch_count.x < 0 or optional_branch_count.y < optional_branch_count.x:
		errors.append("Stage profile '%s' optional branch count is invalid." % id)
	if optional_branch_count.y > 0 and not required_roles.has(&"choice"):
		errors.append("Stage profile '%s' needs a choice room for optional branches." % id)
	_validate_budget(errors, encounter_budget_per_combat_room, "combat encounter")
	_validate_budget(errors, hazard_budget_per_room, "hazard")
	_validate_budget(errors, reward_budget_per_room, "reward")
	ContentId.validate_list(
		errors,
		"Stage profile '%s' eligible enemy archetype" % id,
		eligible_enemy_archetypes,
		false
	)
	ContentId.validate_list(
		errors,
		"Stage profile '%s' eligible hazard" % id,
		eligible_hazards,
		false
	)
	ContentId.validate(errors, "Stage profile fallback ID", fallback_id)
	return errors


func supports_optional_branch_count(branch_count: int) -> bool:
	return branch_count >= optional_branch_count.x and branch_count <= optional_branch_count.y


# Kept for focused Stage 1-2 validators that assert their exact one-branch contract.
func supports_one_optional_branch() -> bool:
	return supports_optional_branch_count(1)


func _validate_budget(errors: PackedStringArray, budget: Vector2i, label: String) -> void:
	if budget.x < 0 or budget.y < budget.x:
		errors.append("Stage profile '%s' %s budget is invalid." % [id, label])
