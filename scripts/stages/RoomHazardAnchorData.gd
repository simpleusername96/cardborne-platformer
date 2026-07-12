class_name RoomHazardAnchorData
extends Resource

@export var id: StringName
@export var allowed_hazard_ids: Array[StringName] = []
@export var warning_space: Vector2 = Vector2(180.0, 120.0)
@export var safe_zone_id: StringName
@export var reset_id: StringName


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Room hazard anchor ID", id)
	ContentId.validate_list(
		errors,
		"Room hazard anchor '%s' allowed hazard" % id,
		allowed_hazard_ids,
		true
	)
	if (
		not is_finite(warning_space.x)
		or not is_finite(warning_space.y)
		or warning_space.x <= 0.0
		or warning_space.y <= 0.0
	):
		errors.append("Room hazard anchor '%s' needs positive warning space." % id)
	if String(safe_zone_id).is_empty() and String(reset_id).is_empty():
		errors.append("Room hazard anchor '%s' needs a safe zone or reset owner." % id)
	return errors
