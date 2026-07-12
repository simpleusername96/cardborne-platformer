class_name RoomMovingPlatformAnchorData
extends Resource

@export var path_id: StringName
@export var start_position: Vector2
@export var end_position: Vector2
@export var travel_time: float = 1.8
@export var start_wait_time: float = 0.45
@export var end_wait_time: float = 0.45
@export var wait_pad_ids: Array[StringName] = []
@export var fall_recovery_id: StringName
@export var checkpoint_safe_radius: float = 96.0


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Moving platform path ID", path_id)
	if (
		not is_finite(start_position.x)
		or not is_finite(start_position.y)
		or not is_finite(end_position.x)
		or not is_finite(end_position.y)
		or start_position.distance_squared_to(end_position) <= 0.000001
	):
		errors.append("Moving platform path '%s' needs distinct finite endpoints." % path_id)
	for duration in [travel_time, start_wait_time, end_wait_time]:
		if not is_finite(duration) or duration <= 0.0:
			errors.append("Moving platform path '%s' needs positive travel and wait times." % path_id)
			break
	if wait_pad_ids.size() != 2:
		errors.append("Moving platform path '%s' needs exactly two safe wait pads." % path_id)
	else:
		ContentId.validate_list(
			errors,
			"Moving platform path '%s' wait pad" % path_id,
			wait_pad_ids,
			true
		)
	ContentId.validate(
		errors,
		"Moving platform path '%s' fall recovery" % path_id,
		fall_recovery_id
	)
	if not is_finite(checkpoint_safe_radius) or checkpoint_safe_radius <= 0.0:
		errors.append("Moving platform path '%s' needs a positive checkpoint-safe radius." % path_id)
	return errors
