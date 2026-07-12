class_name RoomTemplateHost
extends Node2D

const REQUIRED_ROOTS: Array[StringName] = [
	&"Terrain", &"OneWay", &"Hazards", &"DecorBack", &"DecorFront", &"Anchors",
	&"CameraBounds", &"Validation",
]
const REQUIRED_ANCHOR_GROUPS: Array[StringName] = [
	&"Sockets", &"Enemy", &"Hazard", &"Reward", &"Objective", &"Recovery",
]

@export var room_id: StringName

var template_data: RoomTemplateData


func configure(data: RoomTemplateData) -> PackedStringArray:
	var errors := PackedStringArray()
	if data == null:
		errors.append("Room host '%s' needs template data." % name)
		return errors
	for error in data.validate_definition():
		errors.append(error)
	if data.id != room_id:
		errors.append("Room host '%s' ID does not match data '%s'." % [room_id, data.id])
	_validate_scene_contract(data, errors)
	template_data = data
	return errors


func get_anchor(group_name: StringName, anchor_name: StringName) -> Marker2D:
	return get_node_or_null("Anchors/%s/%s" % [group_name, anchor_name]) as Marker2D


func get_anchor_by_id(group_name: StringName, anchor_id: StringName) -> RoomAnchor:
	for anchor in get_typed_anchors(group_name):
		if anchor.anchor_id == anchor_id:
			return anchor
	return null


func get_exit_portal() -> ExitPortal:
	return get_node_or_null("Anchors/Objective/ExitGate") as ExitPortal


func get_typed_anchors(group_name: StringName) -> Array[RoomAnchor]:
	var anchors: Array[RoomAnchor] = []
	var group := get_node_or_null("Anchors/%s" % group_name)
	if group == null:
		return anchors
	for child in group.get_children():
		if child is RoomAnchor:
			anchors.append(child)
	return anchors


func get_support_surfaces() -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	var terrain := get_node_or_null("Terrain")
	if terrain == null:
		return surfaces
	for child in terrain.get_children():
		if not child is StaticBody2D or not child.has_meta("surface_id"):
			continue
		surfaces.append({
			"id": StringName(child.get_meta("surface_id")),
			"x": child.position.x - float(child.get_meta("support_width")) * 0.5,
			"width": float(child.get_meta("support_width")),
			"top": float(child.get_meta("support_top")),
			"critical": bool(child.get_meta("critical", false)),
		})
	surfaces.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left["x"] < right["x"])
	return surfaces


func _validate_scene_contract(data: RoomTemplateData, errors: PackedStringArray) -> void:
	for root_name in REQUIRED_ROOTS:
		if get_node_or_null(String(root_name)) == null:
			errors.append("Room '%s' is missing required root '%s'." % [room_id, root_name])
	for group_name in REQUIRED_ANCHOR_GROUPS:
		if get_node_or_null("Anchors/%s" % group_name) == null:
			errors.append("Room '%s' is missing anchor group '%s'." % [room_id, group_name])
	_validate_socket_markers(data, errors)
	for group_name in [&"Enemy", &"Hazard", &"Reward", &"Recovery"]:
		var group := get_node_or_null("Anchors/%s" % group_name)
		if group == null:
			continue
		for child in group.get_children():
			if child is Marker2D and not child is RoomAnchor:
				errors.append(
					"Room '%s' anchor '%s/%s' must use RoomAnchor."
					% [room_id, group_name, child.name]
				)
			elif child is RoomAnchor:
				var anchor := child as RoomAnchor
				if String(anchor.anchor_type).capitalize() != String(group_name):
					errors.append(
						"Room '%s' anchor '%s' type does not match group '%s'."
						% [room_id, child.name, group_name]
					)
				for anchor_error in anchor.validate_definition():
					errors.append("Room '%s': %s" % [room_id, anchor_error])
	_validate_declared_anchor_ids(data, errors)
	_validate_enemy_anchor_contracts(data, errors)
	_validate_hazard_anchor_contracts(data, errors)
	_validate_reward_anchor_contracts(data, errors)


func _validate_socket_markers(data: RoomTemplateData, errors: PackedStringArray) -> void:
	var sockets_root := get_node_or_null("Anchors/Sockets")
	if sockets_root == null:
		return
	var markers: Array[Marker2D] = []
	for child in sockets_root.get_children():
		if child is Marker2D:
			markers.append(child)
	for socket in data.entry_sockets + data.exit_sockets:
		var matched := false
		for marker in markers:
			if marker.position.is_equal_approx(socket.local_position):
				matched = true
				break
		if not matched:
			errors.append(
				"Room '%s' socket '%s' has no authored marker at %s."
				% [room_id, socket.id, socket.local_position]
			)


func _validate_declared_anchor_ids(data: RoomTemplateData, errors: PackedStringArray) -> void:
	for contract in [
		[&"Enemy", data.get_enemy_anchor_ids()],
		[&"Hazard", data.get_hazard_anchor_ids()],
		[&"Reward", data.get_reward_anchor_ids()],
		[&"Recovery", data.recovery_anchor_ids],
	]:
		var group_name: StringName = contract[0]
		for anchor_id in contract[1]:
			if get_anchor_by_id(group_name, anchor_id) == null:
				errors.append(
					"Room '%s' declares missing %s anchor '%s'."
					% [room_id, group_name, anchor_id]
				)


func _validate_enemy_anchor_contracts(
	data: RoomTemplateData,
	errors: PackedStringArray
) -> void:
	for contract in data.enemy_anchors:
		if contract == null:
			continue
		var scene_anchor := get_anchor_by_id(&"Enemy", contract.id)
		if scene_anchor == null:
			continue
		if not _same_ids(scene_anchor.allowed_tags, contract.allowed_pressure_roles):
			errors.append(
				"Room '%s' enemy anchor '%s' pressure roles do not match its data contract."
				% [room_id, contract.id]
			)
		if (
			not is_equal_approx(scene_anchor.support_width, contract.support_width)
			or not is_equal_approx(scene_anchor.patrol_width, contract.lane_width)
			or not is_equal_approx(scene_anchor.clearance, contract.clearance)
		):
			errors.append(
				"Room '%s' enemy anchor '%s' geometry does not match its data contract."
				% [room_id, contract.id]
			)
		if (
			scene_anchor.has_escape_route != contract.has_escape_route
			or scene_anchor.has_line_of_sight != contract.has_line_of_sight
			or scene_anchor.has_cover_or_elevation != contract.has_cover_or_elevation
		):
			errors.append(
				"Room '%s' enemy anchor '%s' response-space flags do not match its data contract."
				% [room_id, contract.id]
			)


func _same_ids(left: Array[StringName], right: Array[StringName]) -> bool:
	var left_copy := left.duplicate()
	var right_copy := right.duplicate()
	left_copy.sort()
	right_copy.sort()
	return left_copy == right_copy


func _validate_hazard_anchor_contracts(
	data: RoomTemplateData,
	errors: PackedStringArray
) -> void:
	for contract in data.hazard_anchors:
		if contract == null:
			continue
		var scene_anchor := get_anchor_by_id(&"Hazard", contract.id)
		if scene_anchor == null:
			continue
		if not _same_ids(scene_anchor.allowed_tags, contract.allowed_hazard_ids):
			errors.append(
				"Room '%s' hazard anchor '%s' IDs do not match its data contract."
				% [room_id, contract.id]
			)


func _validate_reward_anchor_contracts(
	data: RoomTemplateData,
	errors: PackedStringArray
) -> void:
	for contract in data.reward_anchors:
		if contract == null:
			continue
		var scene_anchor := get_anchor_by_id(&"Reward", contract.id)
		if scene_anchor == null:
			continue
		if scene_anchor.risk_tier != contract.risk_tier:
			errors.append(
				"Room '%s' reward anchor '%s' risk tier does not match its data contract."
				% [room_id, contract.id]
			)
		if scene_anchor.has_meta("reward_role"):
			if StringName(scene_anchor.get_meta("reward_role")) != contract.reward_role:
				errors.append(
					"Room '%s' reward anchor '%s' role does not match its data contract."
					% [room_id, contract.id]
				)
