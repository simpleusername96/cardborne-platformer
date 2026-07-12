class_name RoomSocketCompatibility
extends RefCounted

const MIN_OPENING_WIDTH := 96.0
const MIN_CRITICAL_APPROACH_WIDTH := 180.0
const MIN_CRITICAL_LANDING_WIDTH := 220.0
const MIN_OPTIONAL_LANDING_WIDTH := 180.0
const MIN_DASH_APPROACH_WIDTH := 260.0


static func validate_movement_limits(movement_limits: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var max_gap := float(movement_limits.get("max_required_gap", 0.0))
	var max_ledge := float(movement_limits.get("max_required_ledge", 0.0))
	if not is_finite(max_gap) or max_gap <= 0.0:
		errors.append("Movement limits need a positive finite max_required_gap.")
	if not is_finite(max_ledge) or max_ledge <= 0.0:
		errors.append("Movement limits need a positive finite max_required_ledge.")
	return errors


static func are_compatible(
	from_socket: RoomSocketData,
	to_socket: RoomSocketData,
	route_role: StringName,
	movement_limits: Dictionary
) -> bool:
	return get_errors(from_socket, to_socket, route_role, movement_limits).is_empty()


static func get_errors(
	from_socket: RoomSocketData,
	to_socket: RoomSocketData,
	route_role: StringName,
	movement_limits: Dictionary
) -> PackedStringArray:
	var errors := validate_movement_limits(movement_limits)
	if from_socket == null or to_socket == null:
		errors.append("Connection sockets cannot be null.")
		return errors
	if from_socket.route_role != route_role or to_socket.route_role != route_role:
		errors.append("Connection route role does not match both sockets.")
	if not _directions_match(from_socket.direction, to_socket.direction):
		errors.append(
			"Socket directions '%s' and '%s' are incompatible."
			% [from_socket.direction, to_socket.direction]
		)
	if from_socket.transition_type != to_socket.transition_type:
		errors.append("Connection socket transition types do not match.")
	if from_socket.required_ability != to_socket.required_ability:
		errors.append("Connection socket required abilities do not match.")
	var minimum_headroom := float(movement_limits.get("minimum_headroom", 0.0))
	if minf(from_socket.opening_size.x, to_socket.opening_size.x) < MIN_OPENING_WIDTH:
		errors.append("Connection opening width is below its movement minimum.")
	if minf(from_socket.opening_size.y, to_socket.opening_size.y) < minimum_headroom:
		errors.append("Connection opening height is below its movement minimum.")

	var from_support_offset := from_socket.support_top - from_socket.local_position.y
	var to_support_offset := to_socket.support_top - to_socket.local_position.y
	var max_ledge := float(movement_limits.get("max_required_ledge", 0.0))
	if (
		from_socket.transition_type not in [&"drop", &"rope"]
		and absf(from_support_offset - to_support_offset) > max_ledge
	):
		errors.append("Connection support delta exceeds max_required_ledge.")
	if from_socket.transition_type == &"drop":
		if to_support_offset <= from_support_offset:
			errors.append("Drop connection must land below its source support.")
		if String(to_socket.recovery_id).is_empty():
			errors.append("Drop connection needs a target recovery owner.")
	if (
		from_socket.transition_type == &"rope"
		and from_socket.required_ability != &"climb"
	):
		errors.append("Rope connection must require climb.")
	var max_gap := float(movement_limits.get("max_required_gap", 0.0))
	if (
		from_socket.transition_type in [&"safe_gap", &"dash_gap"]
		and maxf(from_socket.opening_size.x, to_socket.opening_size.x) > max_gap
	):
		errors.append("Connection gap exceeds max_required_gap.")

	var minimum_approach := (
		MIN_DASH_APPROACH_WIDTH
		if from_socket.transition_type == &"dash_gap"
		else MIN_CRITICAL_APPROACH_WIDTH
	)
	if from_socket.approach_width < minimum_approach:
		errors.append("Connection approach width is below its movement minimum.")
	var minimum_landing := (
		MIN_CRITICAL_LANDING_WIDTH
		if route_role == &"critical"
		else MIN_OPTIONAL_LANDING_WIDTH
	)
	if to_socket.landing_width < minimum_landing:
		errors.append("Connection landing width is below its movement minimum.")
	if minf(from_socket.headroom, to_socket.headroom) < minimum_headroom:
		errors.append("Connection headroom is below its movement minimum.")

	var allowed_abilities: Variant = movement_limits.get("allowed_required_abilities", [])
	if not _ability_is_allowed(allowed_abilities, from_socket.required_ability):
		errors.append(
			"Connection requires unsupported ability '%s'." % from_socket.required_ability
		)
	return errors


static func find_pair(
	from_sockets: Array[RoomSocketData],
	to_sockets: Array[RoomSocketData],
	route_role: StringName,
	movement_limits: Dictionary
) -> Dictionary:
	for from_socket in from_sockets:
		for to_socket in to_sockets:
			if are_compatible(from_socket, to_socket, route_role, movement_limits):
				return {"from": from_socket, "to": to_socket}
	return {}


static func _directions_match(from_direction: StringName, to_direction: StringName) -> bool:
	if (
		(from_direction == &"left" and to_direction == &"right")
		or (from_direction == &"right" and to_direction == &"left")
		or (from_direction == &"up" and to_direction == &"down")
		or (from_direction == &"down" and to_direction == &"up")
	):
		return true
	return (
		from_direction in [&"branch", &"rejoin"]
		and to_direction in [&"branch", &"rejoin"]
	)


static func _ability_is_allowed(values: Variant, ability: StringName) -> bool:
	if values is Array and values.is_empty():
		return true
	if values is PackedStringArray and values.is_empty():
		return true
	if values is Array or values is PackedStringArray:
		for value in values:
			if StringName(str(value)) == ability:
				return true
		return false
	return true
