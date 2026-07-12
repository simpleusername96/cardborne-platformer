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
	_validate_moving_platform_contracts(data, errors)


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


func _validate_moving_platform_contracts(
	data: RoomTemplateData,
	errors: PackedStringArray
) -> void:
	var platforms: Array[MovingPlatform] = []
	_collect_moving_platforms(self, platforms)
	for platform in platforms:
		for platform_error in platform.validate_configuration():
			errors.append("Room '%s': %s" % [room_id, platform_error])
		if data.get_moving_platform_anchor_by_path_id(platform.path_id) == null:
			errors.append(
				"Room '%s' has undeclared moving platform path '%s'."
				% [room_id, platform.path_id]
			)

	for contract in data.moving_platform_anchors:
		if contract == null:
			continue
		var platform := _find_moving_platform(platforms, contract.path_id)
		if platform == null:
			errors.append(
				"Room '%s' declares missing moving platform path '%s'."
				% [room_id, contract.path_id]
			)
			continue
		_validate_moving_platform_geometry(contract, platform, errors)


func _validate_moving_platform_geometry(
	contract: RoomMovingPlatformAnchorData,
	platform: MovingPlatform,
	errors: PackedStringArray
) -> void:
	var parent := platform.get_parent() as Node2D
	if parent == null:
		errors.append("Room '%s' moving platform '%s' needs a Node2D parent." % [room_id, contract.path_id])
		return
	var start := to_local(parent.to_global(platform.get_authored_start_position()))
	var end := to_local(parent.to_global(platform.get_authored_end_position()))
	if not start.is_equal_approx(contract.start_position) or not end.is_equal_approx(contract.end_position):
		errors.append(
			"Room '%s' moving platform '%s' endpoints do not match its data contract."
			% [room_id, contract.path_id]
		)
	if (
		not is_equal_approx(platform.travel_time, contract.travel_time)
		or not is_equal_approx(platform.start_wait_time, contract.start_wait_time)
		or not is_equal_approx(platform.end_wait_time, contract.end_wait_time)
	):
		errors.append(
			"Room '%s' moving platform '%s' timing does not match its data contract."
			% [room_id, contract.path_id]
		)

	var endpoints := [start, end]
	for index in contract.wait_pad_ids.size():
		var wait_pad := _get_objective_anchor_by_id(contract.wait_pad_ids[index])
		if wait_pad == null or wait_pad.safe_radius <= 0.0:
			errors.append(
				"Room '%s' moving platform '%s' wait pad '%s' is missing or unsafe."
				% [room_id, contract.path_id, contract.wait_pad_ids[index]]
			)
			continue
		var pad_position := to_local(wait_pad.global_position)
		var boarding_distance := wait_pad.safe_radius + platform.platform_size.x * 0.5
		if pad_position.distance_to(endpoints[index]) > boarding_distance:
			errors.append(
				"Room '%s' moving platform '%s' wait pad '%s' cannot reach its endpoint."
				% [room_id, contract.path_id, contract.wait_pad_ids[index]]
			)

	var recovery := get_anchor_by_id(&"Recovery", contract.fall_recovery_id)
	if recovery == null or recovery.safe_radius < contract.checkpoint_safe_radius:
		errors.append(
			"Room '%s' moving platform '%s' has no matching checkpoint-safe recovery."
			% [room_id, contract.path_id]
		)
		return
	var recovery_position := to_local(recovery.global_position)
	var platform_radius := platform.platform_size.length() * 0.5
	if _distance_to_segment(recovery_position, start, end) < contract.checkpoint_safe_radius + platform_radius:
		errors.append(
			"Room '%s' moving platform '%s' enters its recovery safe radius."
			% [room_id, contract.path_id]
		)


func _collect_moving_platforms(node: Node, result: Array[MovingPlatform]) -> void:
	for child in node.get_children():
		if child is MovingPlatform:
			result.append(child)
		_collect_moving_platforms(child, result)


func _find_moving_platform(
	platforms: Array[MovingPlatform],
	path_id: StringName
) -> MovingPlatform:
	for platform in platforms:
		if platform.path_id == path_id:
			return platform
	return null


func _get_objective_anchor_by_id(anchor_id: StringName) -> RoomAnchor:
	var objective := get_node_or_null("Anchors/Objective")
	if objective == null:
		return null
	return _find_room_anchor(objective, anchor_id)


func _find_room_anchor(node: Node, anchor_id: StringName) -> RoomAnchor:
	for child in node.get_children():
		if child is RoomAnchor and child.anchor_id == anchor_id:
			return child
		var nested := _find_room_anchor(child, anchor_id)
		if nested != null:
			return nested
	return null


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	if segment.length_squared() <= 0.000001:
		return point.distance_to(start)
	var weight := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * weight)
