extends SceneTree

const ROOM_DATA_DIR := "res://data/rooms/broken_sanctum"
const CHARACTER_CATALOG_PATH := "res://data/characters/character_catalog.tres"
const MIN_CRITICAL_LANDING := 220.0
const MIN_OPTIONAL_LANDING := 180.0
const MIN_RETURN_SHAFT_WIDTH := 88.0
const EXPECTED_ROOM_IDS: Array[StringName] = [
	&"bs_breach_entry",
	&"bs_shield_choke",
	&"bs_sentry_crossfire",
	&"bs_fractured_gallery",
	&"bs_gate_switch_loop",
	&"bs_volatile_nave",
	&"bs_twin_reliquary_choice",
	&"bs_recovery_cloister",
	&"bs_reliquary_cache",
	&"bs_material_crypt",
	&"bs_exit_ascent",
]
const REQUIRED_ROLES: Array[StringName] = [
	&"start", &"combat", &"objective", &"hazard", &"choice", &"combat", &"safe", &"combat", &"exit",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var characters := load(CHARACTER_CATALOG_PATH) as CharacterCatalog
	_expect(characters != null, "Character catalog should load.")
	if characters == null:
		_finish()
		return
	var limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	_expect(not limits.is_empty(), "Shared base-character movement limits should resolve.")

	var catalog := _build_catalog()
	_validate_catalog(catalog)
	for data in catalog.rooms:
		if data != null:
			await _validate_room(data, limits)

	var profile := _build_profile()
	_append_errors(profile.validate_definition(), "Focused Stage 3 profile")
	if _include_random_planner():
		await _validate_planner_and_assembly(catalog, profile, limits)
	_finish()


func _include_random_planner() -> bool:
	return (
		OS.get_environment("CARDBORNE_INCLUDE_RANDOM_PLANNER") == "1"
		or OS.get_cmdline_user_args().has("--include-random-planner")
	)


func _build_catalog() -> RoomCatalog:
	var room_data: Array[RoomTemplateData] = []
	var files := DirAccess.get_files_at(ROOM_DATA_DIR)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
		var data := load("%s/%s" % [ROOM_DATA_DIR, file_name]) as RoomTemplateData
		_expect(data != null, "%s should load as RoomTemplateData." % file_name)
		if data != null:
			room_data.append(data)
	var catalog := RoomCatalog.new()
	catalog.id = &"broken_sanctum_rooms_focus"
	catalog.display_name = "Broken Sanctum Focused Rooms"
	catalog.content_version = 1
	catalog.rooms = room_data
	return catalog


func _build_profile() -> StageProfile:
	var profile := StageProfile.new()
	profile.id = &"broken_sanctum"
	profile.display_name = "Broken Sanctum"
	profile.content_version = 2
	profile.required_room_count = REQUIRED_ROLES.size()
	profile.required_roles = REQUIRED_ROLES.duplicate()
	profile.optional_branch_count = Vector2i(2, 2)
	profile.optional_room_role = &"optional"
	profile.terminal_room_role = &"exit"
	profile.eligible_enemy_archetypes = [
		&"walker", &"charger", &"shooter", &"shield_guard", &"leaper", &"sentry",
	]
	profile.eligible_hazards = [
		&"spike_row", &"fall_reset", &"timed_poison_vent", &"crumbling_platform",
	]
	profile.encounter_budget_per_combat_room = Vector2i(4, 8)
	profile.hazard_budget_per_room = Vector2i(0, 2)
	profile.reward_budget_per_room = Vector2i(0, 2)
	profile.fallback_id = &"fallback_broken_sanctum_focus"
	return profile


func _validate_catalog(catalog: RoomCatalog) -> void:
	_append_errors(catalog.validate_catalog(), "Room catalog")
	_expect(catalog.rooms.size() == EXPECTED_ROOM_IDS.size(), "Broken Sanctum should own 11 templates.")
	var ids: Array[StringName] = []
	var role_counts: Dictionary = {}
	for data in catalog.rooms:
		if data == null:
			continue
		ids.append(data.id)
		role_counts[data.role] = int(role_counts.get(data.role, 0)) + 1
	_expect(_same_ids(ids, EXPECTED_ROOM_IDS), "Broken Sanctum room membership is incorrect.")
	_expect(int(role_counts.get(&"combat", 0)) >= 3, "Broken Sanctum needs three combat alternatives.")
	_expect(int(role_counts.get(&"optional", 0)) == 2, "Broken Sanctum needs exactly two optional rooms.")
	for role in [&"start", &"objective", &"hazard", &"choice", &"safe", &"exit"]:
		_expect(int(role_counts.get(role, 0)) >= 1, "Broken Sanctum is missing role %s." % role)


func _validate_room(data: RoomTemplateData, limits: Dictionary) -> void:
	_expect(data.stage_tags == [&"broken_sanctum"], "%s should only target Broken Sanctum." % data.id)
	for error in data.validate_definition():
		_failures.append("%s: %s" % [data.id, error])
	if data.scene == null:
		return
	var host := data.scene.instantiate() as RoomTemplateHost
	_expect(host != null, "%s should instantiate as RoomTemplateHost." % data.id)
	if host == null:
		return
	root.add_child(host)
	for error in host.configure(data):
		_failures.append("%s: %s" % [data.id, error])
	var surfaces := _collect_surfaces(host)
	_validate_surfaces(data, host, surfaces, limits)
	_validate_sockets(data, surfaces, limits)
	_validate_anchors(data, host, surfaces)
	_validate_room_specific(data, host, limits)
	var decor_front := host.get_node_or_null("DecorFront")
	_expect(
		decor_front == null or decor_front.get_child_count() == 0,
		"%s should not use foreground geometry that can occlude play." % data.id
	)
	host.queue_free()
	await process_frame


func _validate_surfaces(
	data: RoomTemplateData,
	host: RoomTemplateHost,
	surfaces: Array[Dictionary],
	limits: Dictionary
) -> void:
	_expect(not surfaces.is_empty(), "%s should expose authored support surfaces." % data.id)
	var critical_count := 0
	for surface in surfaces:
		var width := float(surface["width"])
		if bool(surface["critical"]):
			critical_count += 1
			_expect(width >= MIN_CRITICAL_LANDING, "%s has a critical landing below 220px." % data.id)
		elif not data.required_route:
			_expect(width >= MIN_OPTIONAL_LANDING, "%s has an optional landing below 180px." % data.id)
	if data.required_route:
		_expect(critical_count > 0, "%s required route needs critical support." % data.id)

	var masses: Array[Dictionary] = []
	var terrain := host.get_node_or_null("Terrain")
	if terrain == null:
		return
	for child in terrain.get_children():
		if not child is StaticBody2D or not child.has_meta("surface_id"):
			continue
		var body := child as StaticBody2D
		if bool(body.get_meta("one_way", false)):
			continue
		var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		_expect(shape_node != null, "%s mass %s needs collision." % [data.id, body.name])
		if shape_node == null or not shape_node.shape is RectangleShape2D:
			continue
		var rectangle := shape_node.shape as RectangleShape2D
		var rect := Rect2(body.position + shape_node.position - rectangle.size * 0.5, rectangle.size)
		var support_top := float(body.get_meta("support_top"))
		_expect(absf(rect.position.y - support_top) <= 1.0, "%s mass %s top mismatches support." % [data.id, body.name])
		_expect(rect.end.y >= data.bounds.end.y - 1.0, "%s mass %s must extend to the lower bound." % [data.id, body.name])
		var visual := body.get_node_or_null("RockVisual") as Polygon2D
		_expect(visual != null, "%s mass %s needs a filled rock visual." % [data.id, body.name])
		if visual != null:
			var visual_bottom := -INF
			for point in visual.polygon:
				visual_bottom = maxf(visual_bottom, body.position.y + visual.position.y + point.y)
			_expect(visual_bottom >= data.bounds.end.y - 1.0, "%s mass %s visual must reach the lower bound." % [data.id, body.name])
		masses.append({"name": String(body.name), "rect": rect, "top": support_top})
	_validate_mass_overlaps(data.id, masses)
	if not data.required_route:
		_validate_optional_steps(data.id, masses, limits)


func _validate_mass_overlaps(room_id: StringName, masses: Array[Dictionary]) -> void:
	for first_index in masses.size():
		for second_index in range(first_index + 1, masses.size()):
			var first: Rect2 = masses[first_index]["rect"]
			var second: Rect2 = masses[second_index]["rect"]
			var overlap_width := minf(first.end.x, second.end.x) - maxf(first.position.x, second.position.x)
			var overlap_height := minf(first.end.y, second.end.y) - maxf(first.position.y, second.position.y)
			_expect(
				overlap_width <= 0.5 or overlap_height <= 0.5,
				"%s rock masses %s and %s overlap." % [room_id, masses[first_index]["name"], masses[second_index]["name"]]
			)


func _validate_optional_steps(room_id: StringName, masses: Array[Dictionary], limits: Dictionary) -> void:
	masses.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return (left["rect"] as Rect2).position.x < (right["rect"] as Rect2).position.x)
	var full_optional_rise := float((limits.get("least_metrics", {}) as Dictionary).get("double_jump_height", 0.0))
	for index in range(1, masses.size()):
		_expect(
			absf(float(masses[index]["top"]) - float(masses[index - 1]["top"])) <= full_optional_rise,
			"%s has an optional rise beyond the shared double-jump envelope." % room_id
		)


func _validate_sockets(data: RoomTemplateData, surfaces: Array[Dictionary], limits: Dictionary) -> void:
	var minimum_headroom := float(limits.get("minimum_headroom", 100.0))
	for socket in data.entry_sockets + data.exit_sockets:
		var minimum_landing := MIN_CRITICAL_LANDING if socket.route_role == &"critical" else MIN_OPTIONAL_LANDING
		_expect(socket.landing_width >= minimum_landing, "%s socket %s landing is too narrow." % [data.id, socket.id])
		_expect(socket.approach_width >= MIN_OPTIONAL_LANDING, "%s socket %s approach is too narrow." % [data.id, socket.id])
		_expect(socket.headroom >= minimum_headroom, "%s socket %s headroom is too low." % [data.id, socket.id])
		_expect(
			_surface_supports(socket.local_position.x, socket.support_top, surfaces),
			"%s socket %s has no authored support at its declared top." % [data.id, socket.id]
		)


func _validate_anchors(data: RoomTemplateData, host: RoomTemplateHost, surfaces: Array[Dictionary]) -> void:
	for group_name in [&"Enemy", &"Reward", &"Recovery"]:
		for anchor in host.get_typed_anchors(group_name):
			_expect(
				_surface_supports(anchor.position.x, anchor.position.y, surfaces),
				"%s anchor %s must sit on authored support." % [data.id, anchor.anchor_id]
			)
	for anchor in host.get_typed_anchors(&"Enemy"):
		_expect(anchor.position.x >= 240.0, "%s enemy %s violates safe entry." % [data.id, anchor.anchor_id])
	for anchor in host.get_typed_anchors(&"Hazard"):
		_expect(anchor.position.x >= 240.0, "%s hazard %s violates safe entry." % [data.id, anchor.anchor_id])
		_expect(_hazard_has_support(anchor, surfaces), "%s hazard %s lacks support." % [data.id, anchor.anchor_id])
	for contract in data.hazard_anchors:
		if contract == null:
			continue
		_expect(
			String(contract.safe_zone_id).is_empty() or host.get_anchor_by_id(&"Recovery", contract.safe_zone_id) != null,
			"%s hazard %s has no safe-zone recovery." % [data.id, contract.id]
		)
	if data.required_route:
		_expect(not data.recovery_anchor_ids.is_empty(), "%s required room needs recovery anchors." % data.id)


func _validate_room_specific(
	data: RoomTemplateData,
	host: RoomTemplateHost,
	limits: Dictionary
) -> void:
	match data.id:
		&"bs_breach_entry":
			var player_spawn := host.get_node_or_null("Anchors/Objective/PlayerSpawn") as RoomAnchor
			_expect(player_spawn != null and player_spawn.safe_radius >= 240.0, "Breach entry needs one safe player spawn.")
		&"bs_shield_choke":
			_expect(data.encounter_budget == Vector2i(5, 8), "Shield Choke should admit its three authored elevations.")
			var guard := data.get_enemy_anchor_by_id(&"shield_guard_center")
			_expect(guard != null and guard.support_width >= 420.0, "Shield Guard needs at least 420px support.")
			_expect(guard != null and guard.has_escape_route and guard.has_cover_or_elevation, "Shield Guard needs a true flank route.")
			_expect(host.get_node_or_null("Anchors/Objective/FlankRoute") != null, "Shield Choke flank route is missing.")
			_expect(bool((host.get_node("Anchors/Enemy/ShieldGuardCenter") as RoomAnchor).get_meta("no_single_exit_block", false)), "Shield Guard cannot own the only path.")
		&"bs_sentry_crossfire":
			_validate_sentry_crossfire(data, host)
		&"bs_fractured_gallery":
			_expect(data.encounter_budget == Vector2i(5, 8), "Fractured Gallery should admit three authored placements.")
			var charger := data.get_enemy_anchor_by_id(&"fracture_charger")
			var leaper := data.get_enemy_anchor_by_id(&"fracture_leaper")
			_expect(charger != null and charger.lane_width >= 520.0 and charger.has_escape_route, "Fractured Gallery needs a legal charger lane.")
			_expect(leaper != null and leaper.lane_width >= 420.0 and leaper.clearance >= 180.0, "Fractured Gallery needs a legal leaper arc.")
		&"bs_gate_switch_loop":
			var gate := host.get_node_or_null("Anchors/Objective/GateController")
			var switch_anchor := host.get_node_or_null("Anchors/Objective/SwitchAnchor") as Marker2D
			var gate_anchor := host.get_node_or_null("Anchors/Objective/GateAnchor") as Marker2D
			_expect(
				gate != null
				and gate.get_script() != null
				and gate.get_script().resource_path == "res://scripts/stages/SwitchGate.gd",
				"Gate loop needs the shared SwitchGate component."
			)
			_expect(switch_anchor != null and gate_anchor != null and switch_anchor.position.x < gate_anchor.position.x, "Gate loop switch must precede its gate.")
			_validate_gate_moving_platform(data, host)
		&"bs_volatile_nave":
			_expect(data.hazard_budget == Vector2i(1, 2), "Volatile Nave should budget one or two hazards.")
			_expect(data.hazard_anchors.size() == 2, "Volatile Nave should expose vent and spike anchors.")
			_expect(host.get_node_or_null("OneWay/PermanentSafeGallery") != null, "Volatile Nave needs a permanent safe route.")
		&"bs_twin_reliquary_choice":
			_validate_choice_room(data, host)
		&"bs_recovery_cloister":
			_expect(data.encounter_budget == Vector2i.ZERO and data.hazard_budget == Vector2i.ZERO, "Recovery Cloister cannot budget pressure.")
			_expect(host.get_node_or_null("Anchors/Objective/SanctumCheckpoint") is StageCheckpoint, "Recovery Cloister needs a StageCheckpoint.")
		&"bs_reliquary_cache":
			_expect(_socket_by_transition(data.entry_sockets, &"optional", &"rope") != null, "Reliquary Cache needs its upper rope entry.")
			_expect(_socket_by_transition(data.exit_sockets, &"return", &"drop") != null, "Reliquary Cache needs its authored drop return.")
			_expect(data.reward_anchors.size() == 1 and data.reward_anchors[0].reward_role == &"cache_reward", "Reliquary Cache needs one chest reward.")
		&"bs_material_crypt":
			_validate_material_crypt(data, host, limits)
		&"bs_exit_ascent":
			_expect(host.get_exit_portal() != null, "Exit Ascent needs the shared exit portal.")
			_expect(
				host.get_anchor(&"Objective", &"Checkpoint") != null,
				"Exit Ascent needs the terminal checkpoint marker consumed by runtime spawning."
			)


func _validate_material_crypt(
	data: RoomTemplateData,
	host: RoomTemplateHost,
	_limits: Dictionary
) -> void:
	_expect(
		_socket_by_transition(data.entry_sockets, &"optional", &"drop") != null,
		"Material Crypt needs its lower drop entry."
	)
	var return_socket := _socket_by_transition(data.exit_sockets, &"return", &"rope")
	_expect(return_socket != null, "Material Crypt needs its rope return.")
	var basin_rope := host.get_node_or_null("Anchors/Objective/BasinReturnRope") as Climbable
	var return_rope := host.get_node_or_null("Anchors/Objective/ReturnRope") as Climbable
	_expect(basin_rope != null, "Material Crypt needs a basin-to-shelf climbable.")
	_expect(return_rope != null, "Material Crypt needs an authored return rope.")
	if basin_rope == null or return_rope == null or return_socket == null:
		return
	var surfaces := _collect_surfaces(host)
	var basin := _surface_by_id(surfaces, &"material_crypt_basin")
	var return_shelf := _surface_by_id(surfaces, &"material_crypt_return_shelf")
	_expect(not basin.is_empty() and not return_shelf.is_empty(), "Material Crypt needs basin and return-shelf support.")
	if basin.is_empty() or return_shelf.is_empty():
		return
	_expect(
		host.get_node_or_null("OneWay/BasinReturnStep") == null,
		"Material Crypt should not rely on the former basin step workaround."
	)
	var basin_rope_half := basin_rope.climbable_size * 0.5
	var basin_rope_top := basin_rope.position.y - basin_rope_half.y
	var basin_rope_bottom := basin_rope.position.y + basin_rope_half.y
	var basin_rope_left := basin_rope.position.x - basin_rope_half.x
	var basin_rope_right := basin_rope.position.x + basin_rope_half.x
	_expect(
		basin_rope_top <= float(return_shelf["top"]) + 1.0
		and basin_rope_bottom >= float(basin["top"]) - 1.0,
		"Material Crypt basin rope must span both authored support tops."
	)
	_expect(
		basin_rope_right <= float(return_shelf["x"]) + 1.0,
		"Material Crypt basin rope must stay outside the solid return shelf."
	)
	_expect(
		float(return_shelf["x"]) - basin_rope_right
		<= float(basin_rope.get_meta("endpoint_clearance", 0.0)) + 1.0,
		"Material Crypt basin rope is too far from its shelf dismount."
	)
	_expect(
		basin_rope_left <= float(basin["end_x"]) and basin_rope_right >= float(basin["x"]),
		"Material Crypt basin rope must overlap the basin approach."
	)
	_expect(
		StringName(basin_rope.get_meta("entry_support", &"")) == &"material_crypt_basin"
		and StringName(basin_rope.get_meta("exit_support", &"")) == &"material_crypt_return_shelf"
		and StringName(basin_rope.get_meta("route_scope", &"")) == &"room_local",
		"Material Crypt basin rope must own only the local return route."
	)
	var rope_top := return_rope.position.y - return_rope.climbable_size.y * 0.5
	var rope_bottom := return_rope.position.y + return_rope.climbable_size.y * 0.5
	_expect(rope_top <= -100.0, "Material Crypt return rope must reach through the choice-room cover.")
	_expect(absf(rope_bottom - float(return_shelf["top"])) <= 1.0, "Material Crypt return rope must mount on the return shelf.")
	_expect(
		return_rope.position.x >= float(return_shelf["x"])
		and return_rope.position.x <= float(return_shelf["end_x"]),
		"Material Crypt return rope must overlap its lower mount."
	)
	_expect(
		return_socket.local_position.x == return_rope.position.x,
		"Material Crypt return socket must identify the real rope shaft."
	)
	_expect(
		StringName(return_rope.get_meta("entry_support", &"")) == &"material_crypt_return_shelf"
		and StringName(return_rope.get_meta("exit_support", &"")) == &"twin_choice_return_hatch"
		and StringName(return_rope.get_meta("route_scope", &"")) == &"cross_room",
		"Material Crypt return rope support metadata is stale."
	)


func _validate_sentry_crossfire(data: RoomTemplateData, host: RoomTemplateHost) -> void:
	_expect(data.encounter_budget == Vector2i(6, 6), "Sentry Crossfire should exactly budget two Sentries.")
	var anchors := host.get_typed_anchors(&"Enemy")
	_expect(anchors.size() == 2, "Sentry Crossfire needs two sentry anchors.")
	if anchors.size() != 2:
		return
	for anchor in anchors:
		_expect(anchor.allowed_tags == [&"zone"], "Crossfire anchors should resolve only the Sentry zone role.")
		_expect(anchor.has_cover_or_elevation and anchor.has_line_of_sight, "Every Sentry needs cover and a sight lane.")
	var west_lane: Rect2 = anchors[0].get_meta("fire_lane", Rect2())
	var east_lane: Rect2 = anchors[1].get_meta("fire_lane", Rect2())
	_expect(not west_lane.intersects(east_lane), "Sentry fire lanes must not form unavoidable overlap.")
	_expect(host.get_node_or_null("Terrain/WestCover") != null and host.get_node_or_null("Terrain/EastCover") != null, "Sentry Crossfire needs two independent covers.")
	_expect(
		float(anchors[0].get_meta("fire_phase", 0.0)) != float(anchors[1].get_meta("fire_phase", 0.0)),
		"Sentry warnings need staggered authored phases."
	)


func _validate_gate_moving_platform(data: RoomTemplateData, host: RoomTemplateHost) -> void:
	_expect(data.moving_platform_anchors.size() == 1, "Gate loop needs one typed moving-platform path.")
	if data.moving_platform_anchors.size() != 1:
		return
	var contract := data.moving_platform_anchors[0]
	_expect(contract.path_id == &"gate_overhead_route", "Gate overhead path ID is incorrect.")
	_expect(contract.start_position == Vector2(300, 200) and contract.end_position == Vector2(980, 200), "Gate overhead endpoints should span x300..980 at y200.")
	_expect(contract.fall_recovery_id == &"gate_entry_recovery", "Gate overhead route should fall back to entry recovery.")
	var platform := host.get_node_or_null("OneWay/OverheadPlatform") as MovingPlatform
	_expect(platform != null, "Gate loop needs the shared MovingPlatform component.")
	for wait_id in contract.wait_pad_ids:
		var wait_pad := host.get_node_or_null(
			"Anchors/Objective/OverheadWaitWest" if wait_id == &"gate_overhead_wait_west" else "Anchors/Objective/OverheadWaitEast"
		) as RoomAnchor
		_expect(wait_pad != null and wait_pad.anchor_type == &"objective" and wait_pad.safe_radius >= 120.0, "Moving-platform wait pads must be safe Objective RoomAnchors.")
	var recovery := host.get_anchor_by_id(&"Recovery", contract.fall_recovery_id)
	_expect(recovery != null and recovery.safe_radius >= contract.checkpoint_safe_radius, "Moving-platform fall recovery must satisfy its safe-radius contract.")
	if platform != null and recovery != null:
		var distance := _distance_to_segment(recovery.position, contract.start_position, contract.end_position)
		_expect(
			distance >= contract.checkpoint_safe_radius + platform.platform_size.length() * 0.5,
			"Moving platform must never enter the entry recovery safe radius."
		)


func _validate_choice_room(data: RoomTemplateData, host: RoomTemplateHost) -> void:
	var branches := _sockets_for_role(data.exit_sockets, &"optional")
	var returns := _sockets_for_role(data.entry_sockets, &"return")
	_expect(branches.size() == 2, "Twin Reliquary Choice needs two branch exits.")
	_expect(returns.size() == 2, "Twin Reliquary Choice needs two return entries.")
	_expect(_socket_by_transition(branches, &"optional", &"drop") != null, "Choice needs a lower drop branch.")
	_expect(_socket_by_transition(branches, &"optional", &"rope") != null, "Choice needs an upper rope branch.")
	var lower_return := _socket_by_transition(returns, &"return", &"rope")
	_expect(lower_return != null, "Choice needs a lower rope return.")
	_expect(_socket_by_transition(returns, &"return", &"drop") != null, "Choice needs an upper drop return.")
	var endpoints: Dictionary = {}
	for socket in branches + returns:
		var key := "%s:%s" % [socket.local_position, socket.route_role]
		_expect(not endpoints.has(key), "Choice branch socket endpoints must be unique.")
		endpoints[key] = true
	var branch_rope := host.get_node_or_null("Anchors/Objective/UpperBranchRope") as Climbable
	_expect(branch_rope != null and branch_rope.climbable_size.y >= 760.0, "Upper optional branch needs an authored rope.")
	_validate_lower_return_hatch(lower_return, host)


func _validate_lower_return_hatch(return_socket: RoomSocketData, host: RoomTemplateHost) -> void:
	# The one-way top stays continuous; the split fill masses define the clear rope shaft.
	var west := host.get_node_or_null("Terrain/RightChoiceFillWest") as StaticBody2D
	var east := host.get_node_or_null("Terrain/RightChoiceFillEast") as StaticBody2D
	var hatch := host.get_node_or_null("Terrain/LowerReturnHatch") as StaticBody2D
	_expect(
		west != null and east != null and hatch != null,
		"Lower return needs two fill masses and a centered hatch."
	)
	if west == null or east == null or hatch == null or return_socket == null:
		return
	var west_rect := _collision_rect(west)
	var east_rect := _collision_rect(east)
	var hatch_rect := _collision_rect(hatch)
	_expect(
		west_rect.has_area() and east_rect.has_area() and hatch_rect.has_area(),
		"Lower return hatch geometry needs rectangular collision."
	)
	if not west_rect.has_area() or not east_rect.has_area() or not hatch_rect.has_area():
		return
	var hatch_shape := hatch.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_expect(
		hatch_shape != null and hatch_shape.one_way_collision,
		"Lower return hatch must be one-way collision."
	)
	_expect(
		StringName(hatch.get_meta("surface_id", &"")) == &"twin_choice_return_hatch",
		"Lower return hatch needs its stable support ID."
	)
	var shaft_width := east_rect.position.x - west_rect.end.x
	_expect(
		shaft_width >= MIN_RETURN_SHAFT_WIDTH,
		"Lower return shaft needs player-width clearance around the rope."
	)
	_expect(
		absf(shaft_width - float(hatch.get_meta("shaft_width", 0.0))) <= 1.0,
		"Lower return shaft metadata must match its collision gap."
	)
	_expect(
		hatch_rect.position.x <= west_rect.position.x + 1.0,
		"Lower return one-way surface must cover the west fill."
	)
	_expect(
		hatch_rect.end.x >= east_rect.end.x - 1.0,
		"Lower return one-way surface must cover the east fill."
	)
	_expect(
		west_rect.end.y >= 719.0 and east_rect.end.y >= 719.0,
		"Lower return fill masses must reach the room floor."
	)
	_expect(
		return_socket.local_position.x >= west_rect.end.x
		and return_socket.local_position.x <= east_rect.position.x,
		"Lower return socket must align with the open hatch shaft."
	)
	_expect(
		absf(return_socket.support_top - float(hatch.get_meta("support_top", 0.0))) <= 1.0,
		"Lower return socket must use the hatch support top."
	)


# Planner compatibility keeps required combat slots distinct and reserves the
# matching transition pair for each optional room.
func _validate_planner_and_assembly(
	catalog: RoomCatalog,
	profile: StageProfile,
	limits: Dictionary
) -> void:
	var expected_combat_ids: Array[StringName] = [
		&"bs_shield_choke", &"bs_sentry_crossfire", &"bs_fractured_gallery",
	]
	var expected_combat_slot_count := profile.required_roles.count(&"combat")
	_expect(
		expected_combat_slot_count <= expected_combat_ids.size(),
		"Required combat slots must not exceed the focused combat catalog."
	)
	var combat_coverage: Dictionary = {}
	var assembled_signatures: Dictionary = {}
	for seed in range(1, 65):
		var planner := StagePlanner.new()
		var plan := planner.build_plan(catalog, profile, seed * 104729, 2, limits)
		_expect(plan != null, "Seed %d should produce a Broken Sanctum plan." % seed)
		if plan == null:
			continue
		var optional_rooms: Array[PlannedRoom] = []
		var combat_ids: Array[StringName] = []
		var unique_combat_ids: Dictionary = {}
		for room in plan.get_rooms():
			if not room.required_route:
				optional_rooms.append(room)
			elif room.role == &"combat":
				combat_ids.append(room.template_id)
				unique_combat_ids[room.template_id] = true
				combat_coverage[room.template_id] = true
		_expect(
			combat_ids.size() == expected_combat_slot_count
			and unique_combat_ids.size() == combat_ids.size(),
			"Required combat slots must be filled with unique templates."
		)
		_expect(optional_rooms.size() == 2, "Every plan needs exactly two optional rooms.")
		_validate_plan_branch_ends(plan, optional_rooms)

		var signature_parts := PackedStringArray()
		for combat_id in combat_ids:
			signature_parts.append(String(combat_id))
		signature_parts.sort()
		var signature := ",".join(signature_parts)
		if assembled_signatures.has(signature):
			continue
		assembled_signatures[signature] = true
		await _validate_assembled_plan(plan, catalog, limits)

	for combat_id in expected_combat_ids:
		_expect(combat_coverage.has(combat_id), "Planner seeds should exercise combat alternative %s." % combat_id)
	var expected_signature_count := _combination_count(
		expected_combat_ids.size(),
		expected_combat_slot_count
	)
	_expect(
		assembled_signatures.size() >= expected_signature_count,
		"Seed sweep should assemble every distinct required-combat combination."
	)


func _validate_plan_branch_ends(plan: StagePlan, optional_rooms: Array[PlannedRoom]) -> void:
	var branch_count := 0
	var return_count := 0
	var socket_ends: Dictionary = {}
	for connection in plan.get_connections():
		if connection.route_role == &"optional":
			branch_count += 1
			_expect(connection.from_room_id == &"bs_twin_reliquary_choice", "Optional branches must leave Twin Reliquary Choice.")
		elif connection.route_role == &"return":
			return_count += 1
			_expect(connection.to_room_id == &"bs_twin_reliquary_choice", "Optional branches must rejoin Twin Reliquary Choice.")
		var from_end := "%s:exit:%s" % [connection.from_room_id, connection.from_socket_id]
		var to_end := "%s:entry:%s" % [connection.to_room_id, connection.to_socket_id]
		_expect(not socket_ends.has(from_end), "Connection source socket endpoints must be unique.")
		_expect(not socket_ends.has(to_end), "Connection target socket endpoints must be unique.")
		socket_ends[from_end] = true
		socket_ends[to_end] = true
	_expect(branch_count == 2 and return_count == 2, "Each optional room needs one branch and one return edge.")
	var optional_ids: Array[StringName] = []
	for room in optional_rooms:
		optional_ids.append(room.template_id)
	_expect(
		_same_ids(optional_ids, [&"bs_reliquary_cache", &"bs_material_crypt"]),
		"Plans must select both unique optional rooms."
	)


func _validate_assembled_plan(plan: StagePlan, catalog: RoomCatalog, limits: Dictionary) -> void:
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(plan, catalog, rooms_root)
	_expect(assembly.success, "Authored Broken Sanctum plan should assemble.")
	for error in assembly.get_errors():
		_failures.append("Stage assembly: %s" % error)
	if assembly.success:
		for error in StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits):
			_failures.append("Stage geometry: %s" % error)
		var positions := assembly.get_room_positions()
		var choice_position: Vector2 = positions.get("bs_twin_reliquary_choice", Vector2.ZERO)
		var cache_position: Vector2 = positions.get("bs_reliquary_cache", choice_position)
		var crypt_position: Vector2 = positions.get("bs_material_crypt", choice_position)
		_expect(cache_position.y < choice_position.y, "Reliquary Cache should assemble above the choice room.")
		_expect(crypt_position.y > choice_position.y, "Material Crypt should assemble below the choice room.")
	rooms_root.queue_free()
	await process_frame


func _collect_surfaces(host: RoomTemplateHost) -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	for root_name in ["Terrain", "OneWay"]:
		var surface_root := host.get_node_or_null(root_name)
		if surface_root == null:
			continue
		for child in surface_root.get_children():
			if not child is StaticBody2D or not child.has_meta("surface_id"):
				continue
			var body := child as StaticBody2D
			var width := float(body.get_meta("support_width", 0.0))
			surfaces.append({
				"id": StringName(body.get_meta("surface_id")),
				"x": body.position.x - width * 0.5,
				"end_x": body.position.x + width * 0.5,
				"top": float(body.get_meta("support_top", body.position.y)),
				"width": width,
				"critical": bool(body.get_meta("critical", false)),
				"body": body,
			})
	return surfaces


func _surface_by_id(
	surfaces: Array[Dictionary],
	surface_id: StringName
) -> Dictionary:
	for surface in surfaces:
		if StringName(surface["id"]) == surface_id:
			return surface
	return {}


func _collision_rect(body: StaticBody2D) -> Rect2:
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var rectangle := shape_node.shape as RectangleShape2D if shape_node != null else null
	if rectangle == null:
		return Rect2()
	return Rect2(body.position + shape_node.position - rectangle.size * 0.5, rectangle.size)


func _surface_supports(x: float, top: float, surfaces: Array[Dictionary]) -> bool:
	for surface in surfaces:
		if x < float(surface["x"]) - 1.0 or x > float(surface["end_x"]) + 1.0:
			continue
		if absf(top - float(surface["top"])) <= 1.0:
			return true
	return false


func _hazard_has_support(anchor: RoomAnchor, surfaces: Array[Dictionary]) -> bool:
	for surface in surfaces:
		if anchor.position.x < float(surface["x"]) - 1.0 or anchor.position.x > float(surface["end_x"]) + 1.0:
			continue
		var offset := float(surface["top"]) - anchor.position.y
		if offset >= 0.0 and offset <= anchor.clearance:
			return true
	return false


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	if segment.length_squared() <= 0.000001:
		return point.distance_to(start)
	var weight := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * weight)


func _sockets_for_role(sockets: Array[RoomSocketData], role: StringName) -> Array[RoomSocketData]:
	var matches: Array[RoomSocketData] = []
	for socket in sockets:
		if socket != null and socket.route_role == role:
			matches.append(socket)
	return matches


func _socket_by_transition(
	sockets: Array[RoomSocketData],
	role: StringName,
	transition: StringName
) -> RoomSocketData:
	for socket in sockets:
		if socket != null and socket.route_role == role and socket.transition_type == transition:
			return socket
	return null


func _same_ids(left: Array[StringName], right: Array[StringName]) -> bool:
	var left_copy := left.duplicate()
	var right_copy := right.duplicate()
	left_copy.sort()
	right_copy.sort()
	return left_copy == right_copy


func _combination_count(total: int, chosen: int) -> int:
	if chosen < 0 or chosen > total:
		return 0
	var smaller_side := mini(chosen, total - chosen)
	var result := 1
	for index in range(1, smaller_side + 1):
		result = int(result * (total - smaller_side + index) / index)
	return result


func _append_errors(errors: PackedStringArray, label: String) -> void:
	for error in errors:
		_failures.append("%s: %s" % [label, error])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		var planner_mode := "full" if _include_random_planner() else "dormant"
		print(
			"BROKEN_SANCTUM_ROOM_VALIDATION_OK rooms=11 planner=%s"
			% planner_mode
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
