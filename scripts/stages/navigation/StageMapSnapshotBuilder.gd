class_name StageMapSnapshotBuilder
extends RefCounted

## Projects the accepted StagePlan and assembly into one copy-safe navigation
## snapshot. The minimap never scans collision or owns a second topology.


static func build(
	plan: StagePlan,
	assembly: StageAssemblyResult,
	stage_id: StringName,
	content_signature: String,
	terminal_room_id: StringName,
	exit_portal: ExitPortal,
	runtime_content: StageRuntimeContentResult
) -> Dictionary:
	if plan == null or assembly == null or not assembly.success:
		return {}
	var hosts := assembly.get_room_hosts()
	var rooms: Array[Dictionary] = []
	for planned_room in plan.get_rooms():
		var host := hosts.get(String(planned_room.id)) as RoomTemplateHost
		if host == null or host.template_data == null:
			continue
		rooms.append({
			"id": String(planned_room.id),
			"role": String(planned_room.role),
			"required_route": planned_room.required_route,
			"route_index": planned_room.route_index,
			"bounds": Rect2(
				host.global_position + host.template_data.bounds.position,
				host.template_data.bounds.size
			),
			"start": planned_room.role == &"start",
			"exit": planned_room.id == terminal_room_id,
		})
	rooms.sort_custom(_sort_rooms)

	var connections: Array[Dictionary] = []
	for connection in plan.get_connections():
		connections.append({
			"id": String(connection.id),
			"from_room_id": String(connection.from_room_id),
			"to_room_id": String(connection.to_room_id),
			"route_role": String(connection.route_role),
		})
	connections.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return String(left["id"]) < String(right["id"])
	)

	var markers: Array[Dictionary] = []
	_append_endpoint_markers(
		markers,
		plan,
		hosts,
		terminal_room_id,
		exit_portal
	)
	if runtime_content != null:
		_append_checkpoint_markers(
			markers,
			hosts,
			runtime_content.checkpoint,
			terminal_room_id
		)
		_append_reward_markers(markers, runtime_content.rewards)
	_append_gate_markers(markers, hosts)
	markers.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return String(left["id"]) < String(right["id"])
	)

	return {
		"stage_id": String(stage_id),
		"stage_index": plan.stage_index,
		"content_signature": content_signature,
		"world_bounds": assembly.world_bounds,
		"rooms": rooms,
		"connections": connections,
		"markers": markers,
	}


static func _append_endpoint_markers(
	markers: Array[Dictionary],
	plan: StagePlan,
	hosts: Dictionary,
	terminal_room_id: StringName,
	exit_portal: ExitPortal
) -> void:
	for room in plan.get_rooms():
		var host := hosts.get(String(room.id)) as RoomTemplateHost
		if host == null:
			continue
		if room.role == &"start":
			var spawn := host.get_anchor(&"Objective", &"PlayerSpawn")
			markers.append({
				"id": "start:%s" % room.id,
				"type": "start",
				"room_id": String(room.id),
				"position": (
					spawn.global_position
					if spawn != null
					else _room_center(host)
				),
				"state": "known",
				"always_visible": true,
			})
		if room.id == terminal_room_id:
			markers.append({
				"id": "exit:%s" % room.id,
				"type": "exit",
				"room_id": String(room.id),
				"position": (
					exit_portal.global_position
					if exit_portal != null
					else _room_center(host)
				),
				"state": (
					"ready"
					if exit_portal != null and exit_portal.interaction_enabled
					else "locked"
				),
				"always_visible": true,
			})


static func _append_checkpoint_markers(
	markers: Array[Dictionary],
	hosts: Dictionary,
	runtime_checkpoint: StageCheckpoint,
	terminal_room_id: StringName
) -> void:
	var seen_ids: Dictionary = {}
	var room_ids := hosts.keys()
	room_ids.sort()
	for room_value in room_ids:
		var room_id := String(room_value)
		var host := hosts[room_value] as RoomTemplateHost
		if host == null:
			continue
		for node in host.find_children("*", "StageCheckpoint", true, false):
			var checkpoint := node as StageCheckpoint
			if checkpoint == null or seen_ids.has(checkpoint.checkpoint_id):
				continue
			_append_checkpoint_marker(markers, checkpoint, StringName(room_id))
			seen_ids[checkpoint.checkpoint_id] = true
	if (
		runtime_checkpoint != null
		and not seen_ids.has(runtime_checkpoint.checkpoint_id)
	):
		_append_checkpoint_marker(markers, runtime_checkpoint, terminal_room_id)


static func _append_checkpoint_marker(
	markers: Array[Dictionary],
	checkpoint: StageCheckpoint,
	room_id: StringName
) -> void:
	if checkpoint == null:
		return
	markers.append({
		"id": "checkpoint:%s" % checkpoint.checkpoint_id,
		"type": "checkpoint",
		"room_id": String(room_id),
		"position": checkpoint.global_position,
		"state": "inactive",
		"always_visible": false,
	})


static func _append_reward_markers(
	markers: Array[Dictionary],
	rewards: Array[StageRewardInteractable]
) -> void:
	for reward in rewards:
		if reward == null:
			continue
		var context := reward.get_claim_context()
		var source_id := String(context.get("source_id", reward.transaction_id))
		var room_id := String(context.get("room_id", ""))
		markers.append({
			"id": "reward:%s" % source_id,
			"type": "reward",
			"room_id": room_id,
			"position": reward.global_position,
			"state": "claimed" if reward.is_claimed() else "available",
			"always_visible": false,
		})


static func _append_gate_markers(
	markers: Array[Dictionary],
	hosts: Dictionary
) -> void:
	var room_ids := hosts.keys()
	room_ids.sort()
	for room_value in room_ids:
		var room_id := String(room_value)
		var host := hosts[room_value] as RoomTemplateHost
		if host == null:
			continue
		for node in host.find_children("*", "SwitchGate", true, false):
			var gate := node as SwitchGate
			var objective_id := String(gate.get_meta("objective_id", gate.name))
			markers.append({
				"id": "gate:%s" % objective_id,
				"type": "gate",
				"room_id": room_id,
				"position": gate.global_position,
				"state": "open" if gate.is_open else "closed",
				"always_visible": false,
			})


static func _room_center(host: RoomTemplateHost) -> Vector2:
	return (
		host.global_position
		+ host.template_data.bounds.position
		+ host.template_data.bounds.size * 0.5
	)


static func _sort_rooms(left: Dictionary, right: Dictionary) -> bool:
	var left_required := bool(left["required_route"])
	var right_required := bool(right["required_route"])
	if left_required != right_required:
		return left_required
	if int(left["route_index"]) != int(right["route_index"]):
		return int(left["route_index"]) < int(right["route_index"])
	return String(left["id"]) < String(right["id"])
