class_name RoomRewardAnchorData
extends Resource

@export var id: StringName
@export var reward_role: StringName
@export var eligible_table_ids: Array[StringName] = []
@export_range(0, 5, 1) var risk_tier: int = 0
@export var interaction_space: Vector2 = Vector2(120.0, 96.0)
@export_range(1, 5, 1) var budget_cost: int = 1


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Room reward anchor ID", id)
	ContentId.validate(errors, "Room reward anchor '%s' role" % id, reward_role)
	ContentId.validate_list(
		errors,
		"Room reward anchor '%s' eligible table" % id,
		eligible_table_ids,
		true
	)
	if risk_tier < 0:
		errors.append("Room reward anchor '%s' risk tier cannot be negative." % id)
	if (
		not is_finite(interaction_space.x)
		or not is_finite(interaction_space.y)
		or interaction_space.x <= 0.0
		or interaction_space.y <= 0.0
	):
		errors.append("Room reward anchor '%s' needs positive interaction space." % id)
	if budget_cost <= 0:
		errors.append("Room reward anchor '%s' needs positive budget cost." % id)
	return errors
