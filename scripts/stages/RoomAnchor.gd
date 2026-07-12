class_name RoomAnchor
extends Marker2D

const TYPES: Array[StringName] = [
	&"enemy", &"hazard", &"reward", &"objective", &"recovery", &"player_spawn",
]

@export var anchor_id: StringName
@export var anchor_type: StringName
@export var allowed_tags: Array[StringName] = []
@export_range(0.0, 2000.0, 1.0) var support_width: float = 0.0
@export_range(0.0, 2000.0, 1.0) var patrol_width: float = 0.0
@export_range(0.0, 2000.0, 1.0) var clearance: float = 0.0
@export var has_escape_route: bool = false
@export var has_line_of_sight: bool = false
@export var has_cover_or_elevation: bool = false
@export_range(0.0, 1000.0, 1.0) var safe_radius: float = 0.0
@export_range(0, 5, 1) var risk_tier: int = 0
@export var required: bool = false


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Room anchor ID", anchor_id)
	if not TYPES.has(anchor_type):
		errors.append("Room anchor '%s' has invalid type '%s'." % [anchor_id, anchor_type])
	if not is_finite(position.x) or not is_finite(position.y):
		errors.append("Room anchor '%s' needs a finite position." % anchor_id)
	for value in [support_width, patrol_width, clearance, safe_radius]:
		if not is_finite(value) or value < 0.0:
			errors.append("Room anchor '%s' has invalid geometry metadata." % anchor_id)
			break
	if anchor_type in [&"enemy", &"hazard"] and allowed_tags.is_empty():
		errors.append("Room anchor '%s' needs compatibility tags." % anchor_id)
	if anchor_type == &"enemy" and (support_width <= 0.0 or clearance <= 0.0):
		errors.append("Enemy anchor '%s' needs support width and clearance." % anchor_id)
	if anchor_type in [&"recovery", &"player_spawn"] and safe_radius <= 0.0:
		errors.append("Safe anchor '%s' needs a positive safe radius." % anchor_id)
	return errors
