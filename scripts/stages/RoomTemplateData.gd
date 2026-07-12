class_name RoomTemplateData
extends Resource

const ROLES: Array[StringName] = [
	&"start", &"traversal", &"combat", &"hazard", &"choice", &"objective",
	&"optional", &"safe", &"exit",
]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var scene: PackedScene
@export var role: StringName
@export var stage_tags: Array[StringName] = []
@export var required_route: bool = true
@export var bounds: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
@export var entry_sockets: Array[RoomSocketData] = []
@export var exit_sockets: Array[RoomSocketData] = []
@export var encounter_budget: Vector2i = Vector2i.ZERO
@export var hazard_budget: Vector2i = Vector2i.ZERO
@export var reward_budget: Vector2i = Vector2i.ZERO
@export var allowed_enemy_tags: Array[StringName] = []
@export var forbidden_pairs: Array[StringName] = []
@export var enemy_anchors: Array[RoomEnemyAnchorData] = []
@export var hazard_anchors: Array[RoomHazardAnchorData] = []
@export var reward_anchors: Array[RoomRewardAnchorData] = []
@export var recovery_anchor_ids: Array[StringName] = []
@export var estimated_seconds: Vector2i = Vector2i(20, 60)
@export var variant_group: StringName


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Room template ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Room template '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Room template '%s' needs a positive content version." % id)
	if scene == null:
		errors.append("Room template '%s' needs an authored scene." % id)
	if not ROLES.has(role):
		errors.append("Room template '%s' has invalid role '%s'." % [id, role])
	if stage_tags.is_empty():
		errors.append("Room template '%s' needs a stage tag." % id)
	else:
		ContentId.validate_list(errors, "Room template '%s' stage tag" % id, stage_tags, true)
	ContentId.validate_list(
		errors,
		"Room template '%s' enemy tag" % id,
		allowed_enemy_tags,
		false
	)
	ContentId.validate_list(
		errors,
		"Room template '%s' forbidden pair" % id,
		forbidden_pairs,
		false
	)
	_validate_enemy_anchors(errors)
	_validate_hazard_anchors(errors)
	_validate_reward_anchors(errors)
	for anchor_contract in [
		["recovery", recovery_anchor_ids],
	]:
		ContentId.validate_list(
			errors,
			"Room template '%s' %s anchor" % [id, anchor_contract[0]],
			anchor_contract[1],
			false
		)
	if encounter_budget.y > 0 and enemy_anchors.is_empty():
		errors.append("Room template '%s' needs enemy anchors for its encounter budget." % id)
	if hazard_budget.y > 0 and hazard_anchors.is_empty():
		errors.append("Room template '%s' needs hazard anchors for its hazard budget." % id)
	if reward_budget.y > 0 and reward_anchors.is_empty():
		errors.append("Room template '%s' needs reward anchors for its reward budget." % id)
	if required_route and recovery_anchor_ids.is_empty():
		errors.append("Required room template '%s' needs a recovery anchor." % id)
	if role == &"optional" and required_route:
		errors.append("Optional room template '%s' cannot be required-route content." % id)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		errors.append("Room template '%s' needs positive bounds." % id)
	if entry_sockets.is_empty() or exit_sockets.is_empty():
		errors.append("Milestone room '%s' needs entry and exit sockets." % id)
	_validate_sockets(errors, entry_sockets, "entry")
	_validate_sockets(errors, exit_sockets, "exit")
	var all_socket_ids: Dictionary = {}
	for socket in entry_sockets + exit_sockets:
		if socket == null:
			continue
		if all_socket_ids.has(String(socket.id)):
			errors.append("Room template '%s' repeats socket '%s' across routes." % [id, socket.id])
		all_socket_ids[String(socket.id)] = true
	_validate_budget(errors, encounter_budget, "encounter")
	_validate_budget(errors, hazard_budget, "hazard")
	_validate_budget(errors, reward_budget, "reward")
	if estimated_seconds.x <= 0 or estimated_seconds.y < estimated_seconds.x:
		errors.append("Room template '%s' estimated duration is invalid." % id)
	return errors


func get_enemy_anchor_by_id(anchor_id: StringName) -> RoomEnemyAnchorData:
	for anchor in enemy_anchors:
		if anchor != null and anchor.id == anchor_id:
			return anchor
	return null


func get_enemy_anchor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for anchor in enemy_anchors:
		if anchor != null:
			ids.append(anchor.id)
	return ids


func get_hazard_anchor_by_id(anchor_id: StringName) -> RoomHazardAnchorData:
	for anchor in hazard_anchors:
		if anchor != null and anchor.id == anchor_id:
			return anchor
	return null


func get_hazard_anchor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for anchor in hazard_anchors:
		if anchor != null:
			ids.append(anchor.id)
	return ids


func get_reward_anchor_by_id(anchor_id: StringName) -> RoomRewardAnchorData:
	for anchor in reward_anchors:
		if anchor != null and anchor.id == anchor_id:
			return anchor
	return null


func get_reward_anchor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for anchor in reward_anchors:
		if anchor != null:
			ids.append(anchor.id)
	return ids


func _validate_enemy_anchors(errors: PackedStringArray) -> void:
	var seen_ids: Dictionary = {}
	var covered_roles: Dictionary = {}
	for anchor_index in enemy_anchors.size():
		var anchor := enemy_anchors[anchor_index]
		if anchor == null:
			errors.append("Room template '%s' enemy anchor %d is null." % [id, anchor_index])
			continue
		if seen_ids.has(anchor.id):
			errors.append("Room template '%s' repeats enemy anchor '%s'." % [id, anchor.id])
		seen_ids[anchor.id] = true
		for anchor_error in anchor.validate_definition():
			errors.append("Room template '%s': %s" % [id, anchor_error])
		for pressure_role in anchor.allowed_pressure_roles:
			covered_roles[pressure_role] = true
			if not allowed_enemy_tags.has(pressure_role):
				errors.append(
					"Room template '%s' enemy anchor '%s' allows undeclared role '%s'."
					% [id, anchor.id, pressure_role]
				)
	for pressure_role in allowed_enemy_tags:
		if not covered_roles.has(pressure_role):
			errors.append(
				"Room template '%s' allows pressure role '%s' without a compatible anchor."
				% [id, pressure_role]
			)


func _validate_hazard_anchors(errors: PackedStringArray) -> void:
	var seen_ids: Dictionary = {}
	for anchor_index in hazard_anchors.size():
		var anchor := hazard_anchors[anchor_index]
		if anchor == null:
			errors.append("Room template '%s' hazard anchor %d is null." % [id, anchor_index])
			continue
		if seen_ids.has(anchor.id):
			errors.append("Room template '%s' repeats hazard anchor '%s'." % [id, anchor.id])
		seen_ids[anchor.id] = true
		for anchor_error in anchor.validate_definition():
			errors.append("Room template '%s': %s" % [id, anchor_error])


func _validate_reward_anchors(errors: PackedStringArray) -> void:
	var seen_ids: Dictionary = {}
	for anchor_index in reward_anchors.size():
		var anchor := reward_anchors[anchor_index]
		if anchor == null:
			errors.append("Room template '%s' reward anchor %d is null." % [id, anchor_index])
			continue
		if seen_ids.has(anchor.id):
			errors.append("Room template '%s' repeats reward anchor '%s'." % [id, anchor.id])
		seen_ids[anchor.id] = true
		for anchor_error in anchor.validate_definition():
			errors.append("Room template '%s': %s" % [id, anchor_error])


func _validate_sockets(
	errors: PackedStringArray,
	sockets: Array[RoomSocketData],
	label: String
) -> void:
	var seen_ids: Dictionary = {}
	for socket_index in sockets.size():
		var socket := sockets[socket_index]
		if socket == null:
			errors.append("Room template '%s' %s socket %d is null." % [id, label, socket_index])
			continue
		if seen_ids.has(socket.id):
			errors.append("Room template '%s' repeats socket '%s'." % [id, socket.id])
		seen_ids[socket.id] = true
		for socket_error in socket.validate_definition():
			errors.append("Room template '%s': %s" % [id, socket_error])


func _validate_budget(errors: PackedStringArray, budget: Vector2i, label: String) -> void:
	if budget.x < 0 or budget.y < budget.x:
		errors.append("Room template '%s' %s budget is invalid." % [id, label])
