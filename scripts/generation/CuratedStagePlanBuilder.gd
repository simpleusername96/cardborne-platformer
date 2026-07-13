class_name CuratedStagePlanBuilder
extends RefCounted

const CURATED_ATTEMPT := 3
# Random generation still reports this same curated attempt when it falls back.
const FALLBACK_ATTEMPT := CURATED_ATTEMPT

var _last_errors := PackedStringArray()

var last_errors: PackedStringArray:
	get:
		return _last_errors.duplicate()


func build(
	catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary
) -> StagePlan:
	if profile == null:
		_last_errors = PackedStringArray(["Curated planning needs a StageProfile."])
		return null
	match profile.id:
		&"ruin_approach":
			return build_ruin_approach(catalog, profile, run_seed, stage_index, movement_limits)
		&"flooded_works":
			return build_flooded_works(catalog, profile, run_seed, stage_index, movement_limits)
		&"broken_sanctum":
			return build_broken_sanctum(catalog, profile, run_seed, stage_index, movement_limits)
		_:
			_last_errors = PackedStringArray(["No curated plan exists for '%s'." % profile.id])
			return null


func build_ruin_approach(
	catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary
) -> StagePlan:
	_last_errors.clear()
	if catalog == null or profile == null:
		_last_errors.append("Curated planning needs a RoomCatalog and StageProfile.")
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
			_last_errors.append("Curated plan is missing room '%s'." % spec[0])
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
		CURATED_ATTEMPT
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
		CURATED_ATTEMPT
	)
	_last_errors = StagePlanValidator.validate_plan(
		plan,
		catalog,
		profile,
		movement_limits
	)
	return plan if _last_errors.is_empty() else null


func build_flooded_works(
	catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary
) -> StagePlan:
	_last_errors.clear()
	if catalog == null or profile == null:
		_last_errors.append("Flooded curated planning needs a RoomCatalog and StageProfile.")
		return null
	var specs := [
		[&"fw_flooded_entry", true, 0, 0, 0, 0],
		[&"fw_rope_shaft", true, 1, 0, 0, 0],
		[&"fw_poison_timing", true, 2, 0, 2, 0],
		[&"fw_leaper_basin", true, 3, 2, 0, 0],
		[&"fw_lower_upper_choice", true, 4, 0, 0, 1],
		[&"fw_pump_gallery", true, 5, 2, 0, 0],
		[&"fw_rest_forge", true, 6, 0, 0, 0],
		[&"fw_sunken_cache", false, 0, 0, 0, 1],
	]
	var rooms: Array[PlannedRoom] = []
	for spec in specs:
		var template := catalog.get_room_by_id(spec[0])
		if template == null:
			_last_errors.append("Flooded curated plan is missing room '%s'." % spec[0])
			continue
		rooms.append(PlannedRoom.new(
			template.id, template.id, template.content_version, template.role,
			bool(spec[1]), int(spec[2]), int(spec[3]), int(spec[4]), int(spec[5])
		))
	if not _last_errors.is_empty():
		return null
	var connections: Array[PlannedConnection] = [
		_connection(&"critical_0", &"fw_flooded_entry", &"flooded_entry_out", &"fw_rope_shaft", &"rope_shaft_in", &"critical"),
		_connection(&"critical_1", &"fw_rope_shaft", &"rope_shaft_out", &"fw_poison_timing", &"poison_timing_in", &"critical"),
		_connection(&"critical_2", &"fw_poison_timing", &"poison_timing_out", &"fw_leaper_basin", &"leaper_basin_in", &"critical"),
		_connection(&"critical_3", &"fw_leaper_basin", &"leaper_basin_out", &"fw_lower_upper_choice", &"flooded_choice_in", &"critical"),
		_connection(&"critical_4", &"fw_lower_upper_choice", &"flooded_choice_out", &"fw_pump_gallery", &"pump_gallery_in", &"critical"),
		_connection(&"critical_5", &"fw_pump_gallery", &"pump_gallery_out", &"fw_rest_forge", &"rest_forge_in", &"critical"),
		_connection(&"optional_branch_0", &"fw_lower_upper_choice", &"flooded_choice_branch", &"fw_sunken_cache", &"sunken_cache_branch", &"optional"),
		_connection(&"optional_return_0", &"fw_sunken_cache", &"sunken_cache_return", &"fw_lower_upper_choice", &"flooded_choice_return", &"return"),
	]
	var streams := NamedRngStreams.new(
		run_seed, stage_index, catalog.content_version, profile.content_version, CURATED_ATTEMPT
	)
	var plan := StagePlan.new(
		run_seed, stage_index, profile.id, profile.content_version, catalog.id,
		catalog.content_version, streams.get_stream_seeds(), rooms, connections, [],
		StagePlan.CURRENT_SCHEMA_VERSION, CURATED_ATTEMPT
	)
	_last_errors = StagePlanValidator.validate_plan(plan, catalog, profile, movement_limits)
	return plan if _last_errors.is_empty() else null


func build_broken_sanctum(
	catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary
) -> StagePlan:
	_last_errors.clear()
	if catalog == null or profile == null:
		_last_errors.append("Broken Sanctum curated planning needs a RoomCatalog and StageProfile.")
		return null
	var specs := [
		[&"bs_breach_entry", true, 0, 0, 0, 0],
		[&"bs_shield_choke", true, 1, 5, 0, 0],
		[&"bs_gate_switch_loop", true, 2, 0, 0, 0],
		[&"bs_volatile_nave", true, 3, 0, 1, 0],
		[&"bs_twin_reliquary_choice", true, 4, 0, 0, 0],
		[&"bs_recovery_cloister", true, 5, 0, 0, 0],
		[&"bs_sentry_crossfire", true, 6, 6, 0, 0],
		[&"bs_exit_ascent", true, 7, 0, 0, 0],
		[&"bs_material_crypt", false, 0, 0, 0, 1],
		[&"bs_reliquary_cache", false, 1, 0, 0, 1],
	]
	var rooms: Array[PlannedRoom] = []
	for spec in specs:
		var template := catalog.get_room_by_id(spec[0])
		if template == null:
			_last_errors.append("Broken Sanctum curated plan is missing room '%s'." % spec[0])
			continue
		rooms.append(PlannedRoom.new(
			template.id, template.id, template.content_version, template.role,
			bool(spec[1]), int(spec[2]), int(spec[3]), int(spec[4]), int(spec[5])
		))
	if not _last_errors.is_empty():
		return null
	var connections: Array[PlannedConnection] = [
		_connection(&"critical_0", &"bs_breach_entry", &"breach_entry_out", &"bs_shield_choke", &"shield_choke_in", &"critical"),
		_connection(&"critical_1", &"bs_shield_choke", &"shield_choke_out", &"bs_gate_switch_loop", &"gate_switch_loop_in", &"critical"),
		_connection(&"critical_2", &"bs_gate_switch_loop", &"gate_switch_loop_out", &"bs_volatile_nave", &"volatile_nave_in", &"critical"),
		_connection(&"critical_3", &"bs_volatile_nave", &"volatile_nave_out", &"bs_twin_reliquary_choice", &"twin_choice_in", &"critical"),
		_connection(&"critical_4", &"bs_twin_reliquary_choice", &"twin_choice_out", &"bs_recovery_cloister", &"recovery_cloister_in", &"critical"),
		_connection(&"critical_5", &"bs_recovery_cloister", &"recovery_cloister_out", &"bs_sentry_crossfire", &"sentry_crossfire_in", &"critical"),
		_connection(&"critical_6", &"bs_sentry_crossfire", &"sentry_crossfire_out", &"bs_exit_ascent", &"sanctum_exit_in", &"critical"),
		_connection(&"optional_branch_0", &"bs_twin_reliquary_choice", &"twin_choice_lower_branch", &"bs_material_crypt", &"material_crypt_branch", &"optional"),
		_connection(&"optional_return_0", &"bs_material_crypt", &"material_crypt_return", &"bs_twin_reliquary_choice", &"twin_choice_lower_return", &"return"),
		_connection(&"optional_branch_1", &"bs_twin_reliquary_choice", &"twin_choice_upper_branch", &"bs_reliquary_cache", &"reliquary_cache_branch", &"optional"),
		_connection(&"optional_return_1", &"bs_reliquary_cache", &"reliquary_cache_return", &"bs_twin_reliquary_choice", &"twin_choice_upper_return", &"return"),
	]
	var streams := NamedRngStreams.new(
		run_seed, stage_index, catalog.content_version, profile.content_version, CURATED_ATTEMPT
	)
	var plan := StagePlan.new(
		run_seed, stage_index, profile.id, profile.content_version, catalog.id,
		catalog.content_version, streams.get_stream_seeds(), rooms, connections, [],
		StagePlan.CURRENT_SCHEMA_VERSION, CURATED_ATTEMPT
	)
	_last_errors = StagePlanValidator.validate_plan(plan, catalog, profile, movement_limits)
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
