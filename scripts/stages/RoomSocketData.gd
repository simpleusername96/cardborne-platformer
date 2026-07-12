class_name RoomSocketData
extends Resource

const DIRECTIONS: Array[StringName] = [&"left", &"right", &"up", &"down", &"branch", &"rejoin"]
const ROUTE_ROLES: Array[StringName] = [&"critical", &"optional", &"return"]
const TRANSITION_TYPES: Array[StringName] = [
	&"seam", &"safe_gap", &"dash_gap", &"drop", &"rope", &"one_way"
]
const REQUIRED_ABILITIES: Array[StringName] = [
	&"baseline", &"double_jump", &"dash", &"crouch", &"climb"
]

@export var id: StringName
@export var direction: StringName
@export var route_role: StringName = &"critical"
@export var local_position: Vector2
@export var opening_size: Vector2 = Vector2(120.0, 120.0)
@export var support_top: float
@export var transition_type: StringName = &"seam"
@export var required_ability: StringName = &"baseline"
@export var approach_width: float = 220.0
@export var landing_width: float = 220.0
@export var headroom: float = 96.0
@export var recovery_id: StringName


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty():
		errors.append("Room socket ID cannot be blank.")
	if not DIRECTIONS.has(direction):
		errors.append("Room socket '%s' has invalid direction '%s'." % [id, direction])
	if not ROUTE_ROLES.has(route_role):
		errors.append("Room socket '%s' has invalid route role '%s'." % [id, route_role])
	if not TRANSITION_TYPES.has(transition_type):
		errors.append("Room socket '%s' has invalid transition '%s'." % [id, transition_type])
	if not REQUIRED_ABILITIES.has(required_ability):
		errors.append("Room socket '%s' has invalid required ability '%s'." % [id, required_ability])
	if opening_size.x <= 0.0 or opening_size.y <= 0.0:
		errors.append("Room socket '%s' needs positive opening size." % id)
	if (
		not is_finite(local_position.x)
		or not is_finite(local_position.y)
		or not is_finite(support_top)
	):
		errors.append("Room socket '%s' needs finite position and support top." % id)
	if approach_width <= 0.0 or landing_width <= 0.0 or headroom <= 0.0:
		errors.append("Room socket '%s' needs positive approach, landing, and headroom." % id)
	return errors
