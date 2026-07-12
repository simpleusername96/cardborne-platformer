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
@export var estimated_seconds: Vector2i = Vector2i(20, 60)
@export var variant_group: StringName


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty():
		errors.append("Room template ID cannot be blank.")
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
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		errors.append("Room template '%s' needs positive bounds." % id)
	if entry_sockets.is_empty() or exit_sockets.is_empty():
		errors.append("Milestone room '%s' needs entry and exit sockets." % id)
	_validate_sockets(errors, entry_sockets, "entry")
	_validate_sockets(errors, exit_sockets, "exit")
	_validate_budget(errors, encounter_budget, "encounter")
	_validate_budget(errors, hazard_budget, "hazard")
	_validate_budget(errors, reward_budget, "reward")
	if estimated_seconds.x <= 0 or estimated_seconds.y < estimated_seconds.x:
		errors.append("Room template '%s' estimated duration is invalid." % id)
	return errors


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
