class_name CuratedStagePlanBuilder
extends RefCounted

const FALLBACK_ATTEMPT := 3

var _last_errors := PackedStringArray()

var last_errors: PackedStringArray:
	get:
		return _last_errors.duplicate()


func build_ruin_approach(
	catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary
) -> StagePlan:
	_last_errors.clear()
	if catalog == null or profile == null:
		_last_errors.append("Curated fallback needs a RoomCatalog and StageProfile.")
		return null

	var specs := [
		[&"lr_start_shelf", true, 0, 0, 0, 0],
		[&"lr_rise_steps", true, 1, 0, 0, 0],
		[&"lr_patrol_gallery", true, 2, 1, 0, 0],
		[&"lr_lower_upper_choice", true, 3, 0, 0, 1],
		[&"lr_charge_lane", true, 4, 2, 0, 0],
		[&"lr_exit_ascent", true, 5, 2, 0, 0],
		[&"lr_destructible_cache", false, 0, 0, 0, 1],
	]
	var rooms: Array[PlannedRoom] = []
	for spec in specs:
		var template := catalog.get_room_by_id(spec[0])
		if template == null:
			_last_errors.append("Curated fallback is missing room '%s'." % spec[0])
			continue
		rooms.append(
			PlannedRoom.new(
				template.id,
				template.id,
				template.content_version,
				template.role,
				bool(spec[1]),
				int(spec[2]),
				int(spec[3]),
				int(spec[4]),
				int(spec[5])
			)
		)
	if not _last_errors.is_empty():
		return null

	var connections: Array[PlannedConnection] = [
		_connection(&"critical_0", &"lr_start_shelf", &"start_exit", &"lr_rise_steps", &"rise_entry", &"critical"),
		_connection(&"critical_1", &"lr_rise_steps", &"rise_exit", &"lr_patrol_gallery", &"patrol_entry", &"critical"),
		_connection(&"critical_2", &"lr_patrol_gallery", &"patrol_exit", &"lr_lower_upper_choice", &"choice_entry", &"critical"),
		_connection(&"critical_3", &"lr_lower_upper_choice", &"choice_exit", &"lr_charge_lane", &"charge_entry", &"critical"),
		_connection(&"critical_4", &"lr_charge_lane", &"charge_exit", &"lr_exit_ascent", &"exit_ascent_entry", &"critical"),
		_connection(&"optional_branch_0", &"lr_lower_upper_choice", &"choice_optional_branch", &"lr_destructible_cache", &"cache_branch", &"optional"),
		_connection(&"optional_return_0", &"lr_destructible_cache", &"cache_rejoin", &"lr_lower_upper_choice", &"choice_optional_rejoin", &"return"),
	]
	var streams := NamedRngStreams.new(
		run_seed,
		stage_index,
		catalog.content_version,
		profile.content_version,
		FALLBACK_ATTEMPT
	)
	var plan := StagePlan.new(
		run_seed,
		stage_index,
		profile.id,
		profile.content_version,
		catalog.id,
		catalog.content_version,
		streams.get_stream_seeds(),
		rooms,
		connections,
		[],
		StagePlan.CURRENT_SCHEMA_VERSION,
		FALLBACK_ATTEMPT
	)
	_last_errors = StagePlanValidator.validate_plan(
		plan,
		catalog,
		profile,
		movement_limits
	)
	return plan if _last_errors.is_empty() else null


func _connection(
	id: StringName,
	from_room: StringName,
	from_socket: StringName,
	to_room: StringName,
	to_socket: StringName,
	role: StringName
) -> PlannedConnection:
	return PlannedConnection.new(id, from_room, from_socket, to_room, to_socket, role)
