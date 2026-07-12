class_name RoomEnemyAnchorData
extends Resource

@export var id: StringName
@export var allowed_pressure_roles: Array[StringName] = []
@export_range(0.0, 2000.0, 1.0) var support_width: float = 0.0
@export_range(0.0, 2000.0, 1.0) var lane_width: float = 0.0
@export_range(0.0, 2000.0, 1.0) var clearance: float = 0.0
@export var has_escape_route: bool = false
@export var has_line_of_sight: bool = false
@export var has_cover_or_elevation: bool = false


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Room enemy anchor ID", id)
	ContentId.validate_list(
		errors,
		"Room enemy anchor '%s' pressure role" % id,
		allowed_pressure_roles,
		true
	)
	for value in [support_width, lane_width, clearance]:
		if not is_finite(value) or value < 0.0:
			errors.append("Room enemy anchor '%s' has invalid geometry." % id)
			break
	if support_width <= 0.0 or clearance <= 0.0:
		errors.append("Room enemy anchor '%s' needs support width and clearance." % id)
	return errors


func supports(archetype: EnemyArchetypeDefinition, pressure_role: StringName) -> bool:
	if archetype == null or not allowed_pressure_roles.has(pressure_role):
		return false
	if not archetype.pressure_roles.has(pressure_role):
		return false
	if support_width < archetype.minimum_support_width:
		return false
	if lane_width < archetype.minimum_lane_width:
		return false
	if clearance < archetype.minimum_arc_clearance:
		return false
	if archetype.requires_patrol_turn_points and lane_width <= 0.0:
		return false
	if archetype.requires_escape_route and not has_escape_route:
		return false
	if archetype.room_requirement_tags.has(&"line_of_sight_lane") and not has_line_of_sight:
		return false
	if (
		archetype.room_requirement_tags.has(&"cover_or_elevation")
		and not has_cover_or_elevation
	):
		return false
	return true
