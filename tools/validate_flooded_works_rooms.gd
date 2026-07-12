extends SceneTree

const PROFILE_PATH := "res://data/generation/flooded_works_profile.tres"
const CATALOG_PATH := "res://data/generation/flooded_works_room_catalog.tres"
const CHARACTER_CATALOG_PATH := "res://data/characters/character_catalog.tres"
const RULES_PATH := "res://data/design/first_slice/procedural_region_rules.json"
const ROOM_DATA_DIR := "res://data/rooms/flooded_works"
const MIN_CRITICAL_LANDING := 220.0
const MIN_OPTIONAL_LANDING := 180.0
const MIN_ROPE_SUPPORT_OVERLAP := 24.0
const EXPECTED_ROOM_IDS: Array[StringName] = [
	&"fw_flooded_entry",
	&"fw_rope_shaft",
	&"fw_poison_timing",
	&"fw_crumble_crossing",
	&"fw_leaper_basin",
	&"fw_pump_gallery",
	&"fw_lower_upper_choice",
	&"fw_sunken_cache",
	&"fw_rest_forge",
]
const EXPECTED_ROLES: Array[StringName] = [
	&"start", &"traversal", &"hazard", &"combat", &"choice", &"combat", &"safe",
]
const POISON_ROUTE: Array[StringName] = [
	&"fw_flooded_entry",
	&"fw_rope_shaft",
	&"fw_poison_timing",
	&"fw_leaper_basin",
	&"fw_lower_upper_choice",
	&"fw_pump_gallery",
	&"fw_rest_forge",
]
const CRUMBLE_ROUTE: Array[StringName] = [
	&"fw_flooded_entry",
	&"fw_rope_shaft",
	&"fw_crumble_crossing",
	&"fw_leaper_basin",
	&"fw_lower_upper_choice",
	&"fw_pump_gallery",
	&"fw_rest_forge",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := load(PROFILE_PATH) as StageProfile
	var catalog := load(CATALOG_PATH) as RoomCatalog
	var characters := load(CHARACTER_CATALOG_PATH) as CharacterCatalog
	_expect(profile != null, "Flooded Works profile should load.")
	_expect(catalog != null, "Flooded Works room catalog should load.")
	_expect(characters != null, "Character catalog should load.")
	if profile == null or catalog == null or characters == null:
		_finish()
		return

	_validate_profile(profile)
	_validate_catalog(catalog)
	_validate_rules(profile)
	var shared_limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	_expect(not shared_limits.is_empty(), "Shared base-character movement limits should resolve.")
	for room_data in catalog.rooms:
		if room_data != null:
			await _validate_room(room_data, shared_limits)
	_validate_role_candidates(catalog, characters, profile)
	await _validate_assembled_candidate(catalog, profile, POISON_ROUTE, shared_limits)
	await _validate_assembled_candidate(catalog, profile, CRUMBLE_ROUTE, shared_limits)
	_finish()


func _validate_profile(profile: StageProfile) -> void:
	_append_errors(profile.validate_definition(), "Stage profile")
	_expect(profile.id == &"flooded_works", "Profile ID should be flooded_works.")
	_expect(profile.required_room_count == 7, "Profile should require seven rooms.")
	_expect(profile.required_roles == EXPECTED_ROLES, "Profile required role order is incorrect.")
	_expect(profile.optional_branch_count == Vector2i(1, 1), "Profile should choose one optional branch.")
	_expect(profile.terminal_room_role == &"safe", "Profile terminal role should be safe.")
	_expect(
		profile.encounter_budget_per_combat_room == Vector2i(2, 5),
		"Profile combat budget should be 2-5."
	)
	_expect(
		profile.hazard_budget_per_room == Vector2i(0, 2),
		"Profile hazard budget should be 0-2."
	)
	_expect(
		profile.fallback_id == &"fallback_flooded_works_v1",
		"Profile fallback ID is incorrect."
	)


func _validate_catalog(catalog: RoomCatalog) -> void:
	_append_errors(catalog.validate_catalog(), "Room catalog")
	_expect(catalog.id == &"flooded_works_rooms", "Room catalog ID is incorrect.")
	_expect(catalog.rooms.size() == EXPECTED_ROOM_IDS.size(), "Room catalog should contain nine rooms.")
	var catalog_ids: Array[StringName] = []
	for room_data in catalog.rooms:
		if room_data != null:
			catalog_ids.append(room_data.id)
	_expect(_same_ids(catalog_ids, EXPECTED_ROOM_IDS), "Room catalog membership is incorrect.")

	var file_count := 0
	for file_name in DirAccess.get_files_at(ROOM_DATA_DIR):
		if file_name.ends_with(".tres"):
			file_count += 1
	_expect(file_count == EXPECTED_ROOM_IDS.size(), "Every Flooded Works room should have one data file.")


func _validate_rules(profile: StageProfile) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	_expect(parsed is Dictionary, "Procedural region rules should parse as a dictionary.")
	if not parsed is Dictionary:
		return
	var rules := parsed as Dictionary
	var generation_model: Variant = rules.get("generation_model", {})
	_expect(generation_model is Dictionary, "Generation model rules should exist.")
	if generation_model is Dictionary:
		_expect(
			int(generation_model.get("max_retries", -1)) == 3,
			"Shared generation rules should retain three retries."
		)

	var rule_profile: Dictionary = {}
	var raw_profiles: Variant = rules.get("stage_profiles", [])
	if raw_profiles is Array:
		for raw_profile in raw_profiles:
			if raw_profile is Dictionary and str(raw_profile.get("id", "")) == "flooded_works":
				rule_profile = raw_profile
				break
	_expect(not rule_profile.is_empty(), "Procedural rules should define Flooded Works.")
	if rule_profile.is_empty():
		return
	_expect(int(rule_profile.get("required_room_count", 0)) == 7, "Rules should require seven rooms.")
	_expect(
		_to_string_names(rule_profile.get("required_roles", [])) == EXPECTED_ROLES,
		"Profile roles should match procedural rules."
	)
	var optional_range := _to_vector2i(rule_profile.get("optional_branch_count", []))
	_expect(
		profile.optional_branch_count.x >= optional_range.x
		and profile.optional_branch_count.y <= optional_range.y,
		"One optional branch should stay inside the shared 1-2 allowance."
	)
	_expect(
		_to_vector2i(rule_profile.get("encounter_budget_per_room", []))
		== profile.encounter_budget_per_combat_room,
		"Combat budget should match procedural rules."
	)
	_expect(
		_to_vector2i(rule_profile.get("hazard_budget_per_room", []))
		== profile.hazard_budget_per_room,
		"Hazard budget should match procedural rules."
	)
	_expect(
		_same_ids(
			profile.eligible_enemy_archetypes,
			_to_string_names(rule_profile.get("eligible_enemy_archetypes", []))
		),
		"Enemy eligibility should match procedural rules."
	)
	_expect(
		_same_ids(
			profile.eligible_hazards,
			_to_string_names(rule_profile.get("eligible_hazards", []))
		),
		"Hazard eligibility should match procedural rules."
	)


func _validate_room(data: RoomTemplateData, shared_limits: Dictionary) -> void:
	_expect(data.stage_tags == [&"flooded_works"], "%s should only target Flooded Works." % data.id)
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
	_validate_surfaces(data, host, surfaces)
	_validate_sockets(data, surfaces, shared_limits)
	_validate_anchors(data, host, surfaces)
	_validate_room_specific(data, host, surfaces)
	host.queue_free()
	await process_frame


func _validate_surfaces(data: RoomTemplateData, host: RoomTemplateHost, surfaces: Array[Dictionary]) -> void:
	_expect(not surfaces.is_empty(), "%s should expose authored support surfaces." % data.id)
	for surface in surfaces:
		var width := float(surface["width"])
		_expect(width > 0.0, "%s surface %s needs positive width." % [data.id, surface["id"]])
		if bool(surface["critical"]):
			_expect(
				width >= MIN_CRITICAL_LANDING,
				"%s critical surface %s is narrower than 220px."
				% [data.id, surface["id"]]
			)
		elif not data.required_route:
			_expect(
				width >= MIN_OPTIONAL_LANDING,
				"%s optional surface %s is narrower than 180px."
				% [data.id, surface["id"]]
			)

	var mass_rects: Array[Dictionary] = []
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
		_expect(shape_node != null, "%s mass %s needs a collision shape." % [data.id, body.name])
		if shape_node == null or not shape_node.shape is RectangleShape2D:
			continue
		var rectangle := shape_node.shape as RectangleShape2D
		var rect := Rect2(
			body.position + shape_node.position - rectangle.size * 0.5,
			rectangle.size
		)
		var support_top := float(body.get_meta("support_top"))
		_expect(
			absf(rect.position.y - support_top) <= 1.0,
			"%s mass %s collision top should match support top." % [data.id, body.name]
		)
		_expect(
			rect.end.y >= data.bounds.end.y - 1.0,
			"%s mass %s should extend to the room lower bound." % [data.id, body.name]
		)
		var rock_visual := body.get_node_or_null("RockVisual") as Polygon2D
		_expect(rock_visual != null, "%s mass %s needs a rock visual." % [data.id, body.name])
		if rock_visual != null:
			var visual_bottom := -INF
			for point in rock_visual.polygon:
				visual_bottom = maxf(visual_bottom, body.position.y + rock_visual.position.y + point.y)
			_expect(
				visual_bottom >= data.bounds.end.y - 1.0,
				"%s mass %s visual should reach the lower bound." % [data.id, body.name]
			)
		mass_rects.append({"name": String(body.name), "rect": rect})
	_validate_mass_overlaps(data.id, mass_rects)


func _validate_mass_overlaps(room_id: StringName, masses: Array[Dictionary]) -> void:
	for first_index in masses.size():
		for second_index in range(first_index + 1, masses.size()):
			var first_rect: Rect2 = masses[first_index]["rect"]
			var second_rect: Rect2 = masses[second_index]["rect"]
			var overlap_width := minf(first_rect.end.x, second_rect.end.x) - maxf(
				first_rect.position.x,
				second_rect.position.x
			)
			var overlap_height := minf(first_rect.end.y, second_rect.end.y) - maxf(
				first_rect.position.y,
				second_rect.position.y
			)
			_expect(
				overlap_width <= 0.5 or overlap_height <= 0.5,
				"%s rock masses %s and %s overlap."
				% [room_id, masses[first_index]["name"], masses[second_index]["name"]]
			)


func _validate_sockets(
	data: RoomTemplateData,
	surfaces: Array[Dictionary],
	shared_limits: Dictionary
) -> void:
	var minimum_headroom := float(shared_limits.get("minimum_headroom", 100.0))
	for socket in data.entry_sockets + data.exit_sockets:
		var minimum_landing := (
			MIN_CRITICAL_LANDING if socket.route_role == &"critical" else MIN_OPTIONAL_LANDING
		)
		_expect(
			socket.landing_width >= minimum_landing,
			"%s socket %s landing width is too small." % [data.id, socket.id]
		)
		_expect(
			socket.approach_width >= MIN_OPTIONAL_LANDING,
			"%s socket %s approach width is too small." % [data.id, socket.id]
		)
		_expect(
			socket.headroom >= minimum_headroom,
			"%s socket %s headroom is below the shared limit." % [data.id, socket.id]
		)
		_expect(
			_surface_supports(socket.local_position.x, socket.support_top, surfaces),
			"%s socket %s has no authored support at its declared top."
			% [data.id, socket.id]
		)


func _validate_anchors(
	data: RoomTemplateData,
	host: RoomTemplateHost,
	surfaces: Array[Dictionary]
) -> void:
	for group_name in [&"Enemy", &"Reward", &"Recovery"]:
		for anchor in host.get_typed_anchors(group_name):
			_expect(
				_surface_supports(anchor.position.x, anchor.position.y, surfaces),
				"%s anchor %s should sit on authored support." % [data.id, anchor.anchor_id]
			)
	for anchor in host.get_typed_anchors(&"Enemy"):
		_expect(
			anchor.position.x >= 240.0,
			"%s enemy anchor %s violates the 240px safe entry." % [data.id, anchor.anchor_id]
		)
	for anchor in host.get_typed_anchors(&"Hazard"):
		_expect(
			anchor.position.x >= 240.0,
			"%s hazard anchor %s violates the 240px safe entry." % [data.id, anchor.anchor_id]
		)
		_expect(
			_hazard_has_support(anchor, surfaces),
			"%s hazard anchor %s should resolve authored or runtime-owned support."
			% [data.id, anchor.anchor_id]
		)
	for hazard_contract in data.hazard_anchors:
		if hazard_contract == null:
			continue
		var has_safe_owner := (
			String(hazard_contract.safe_zone_id).is_empty()
			or host.get_anchor_by_id(&"Recovery", hazard_contract.safe_zone_id) != null
		)
		var has_reset_owner := (
			String(hazard_contract.reset_id).is_empty()
			or host.get_anchor_by_id(&"Recovery", hazard_contract.reset_id) != null
		)
		_expect(has_safe_owner, "%s hazard safe-zone owner is missing." % data.id)
		_expect(has_reset_owner, "%s hazard reset owner is missing." % data.id)


func _validate_room_specific(
	data: RoomTemplateData,
	host: RoomTemplateHost,
	surfaces: Array[Dictionary]
) -> void:
	match data.id:
		&"fw_flooded_entry":
			_validate_start_room(host, surfaces)
		&"fw_rope_shaft":
			_validate_rope_shaft(host, surfaces)
		&"fw_poison_timing":
			_validate_poison_room(data, host, surfaces)
		&"fw_crumble_crossing":
			_validate_crumble_room(data, host, surfaces)
		&"fw_leaper_basin":
			_validate_leaper_room(data)
		&"fw_pump_gallery":
			_validate_pump_gallery(data)
		&"fw_lower_upper_choice":
			_validate_choice_room(data, host)
		&"fw_sunken_cache":
			_validate_optional_room(data, host)
		&"fw_rest_forge":
			_validate_safe_room(data, host)


func _validate_start_room(host: RoomTemplateHost, surfaces: Array[Dictionary]) -> void:
	var spawn_count := 0
	var objective := host.get_node_or_null("Anchors/Objective")
	if objective != null:
		for child in objective.get_children():
			if child is RoomAnchor and child.anchor_type == &"player_spawn":
				spawn_count += 1
				_expect(
					_surface_supports(child.position.x, child.position.y, surfaces),
					"Flooded entry player spawn should sit on support."
				)
	_expect(spawn_count == 1, "Flooded entry should have exactly one player spawn.")


func _validate_rope_shaft(host: RoomTemplateHost, surfaces: Array[Dictionary]) -> void:
	var rope := host.get_node_or_null("Anchors/Objective/RopeClimb") as Climbable
	_expect(rope != null, "Rope shaft should own a climbable route.")
	if rope == null:
		return
	var half_height := rope.climbable_size.y * 0.5
	_expect(
		_surface_supports(rope.position.x, rope.position.y - half_height, surfaces),
		"Rope shaft top should touch stable support."
	)
	_expect(
		_surface_supports(rope.position.x, rope.position.y + half_height, surfaces),
		"Rope shaft bottom should touch lower recovery support."
	)
	_expect(
		float(rope.get_meta("support_overlap", 0.0)) >= MIN_ROPE_SUPPORT_OVERLAP,
		"Rope shaft support overlap should be at least 24px."
	)


func _validate_poison_room(
	data: RoomTemplateData,
	host: RoomTemplateHost,
	surfaces: Array[Dictionary]
) -> void:
	_expect(data.hazard_budget == Vector2i(2, 2), "Poison room should spend hazard budget 2.")
	_expect(
		data.hazard_anchors[0].allowed_hazard_ids == [&"timed_poison_vent"],
		"Poison room should only host the timed poison vent."
	)
	var safe_lane := _surface_by_id(surfaces, &"poison_safe_lane")
	_expect(not safe_lane.is_empty(), "Poison room should expose a permanent safe lane.")
	if not safe_lane.is_empty():
		_expect(float(safe_lane["width"]) >= 720.0, "Poison safe lane should span both vent bands.")
		var safe_body := host.get_node_or_null("OneWay/PermanentSafeLane")
		_expect(
			safe_body != null and bool(safe_body.get_meta("permanent_safe_lane", false)),
			"Poison safe lane should be explicitly permanent."
		)


func _validate_crumble_room(
	data: RoomTemplateData,
	host: RoomTemplateHost,
	surfaces: Array[Dictionary]
) -> void:
	_expect(data.hazard_budget == Vector2i(2, 2), "Crumble room should spend hazard budget 2.")
	_expect(
		data.hazard_anchors[0].allowed_hazard_ids == [&"crumbling_platform"],
		"Crumble room should only host crumbling platforms."
	)
	var wait_pad_count := 0
	var stable_bridge_count := 0
	for surface in surfaces:
		var body := surface["body"] as StaticBody2D
		if bool(body.get_meta("wait_pad", false)):
			wait_pad_count += 1
		if bool(body.get_meta("stable_bridge", false)):
			stable_bridge_count += 1
	_expect(wait_pad_count == 2, "Crumble crossing should have two permanent wait pads.")
	_expect(stable_bridge_count == 2, "Crumble crossing should retain two stable bridge supports.")
	var hazard_anchor := host.get_anchor_by_id(&"Hazard", &"crumble_path")
	_expect(
		hazard_anchor != null and hazard_anchor.support_width >= MIN_CRITICAL_LANDING,
		"Runtime crumble support should preserve a 220px landing."
	)
	_expect(
		host.get_node_or_null("Hazards/CrumblePreview") != null,
		"Crumble crossing should preview its runtime-owned center support."
	)
	_expect(
		host.get_anchor_by_id(&"Recovery", &"crumble_lower_recovery") != null,
		"Crumble crossing should retain lower recovery."
	)


func _validate_leaper_room(data: RoomTemplateData) -> void:
	var anchor := data.get_enemy_anchor_by_id(&"leaper_arc")
	_expect(anchor != null, "Leaper basin should declare its vertical anchor.")
	if anchor != null:
		_expect(anchor.lane_width >= 420.0, "Leaper lane should be at least 420px.")
		_expect(anchor.clearance >= 180.0, "Leaper arc clearance should be at least 180px.")
		_expect(anchor.has_escape_route, "Leaper basin should expose side recovery.")


func _validate_pump_gallery(data: RoomTemplateData) -> void:
	_expect(
		_same_ids(data.allowed_enemy_tags, [&"occupier", &"burst", &"ranged"]),
		"Pump gallery should support walker, charger, and shooter pressure roles."
	)
	var charger := data.get_enemy_anchor_by_id(&"gallery_center_charger")
	var shooter := data.get_enemy_anchor_by_id(&"gallery_shooter_perch")
	_expect(charger != null and charger.lane_width >= 560.0, "Pump gallery needs a charger lane.")
	_expect(charger != null and charger.has_escape_route, "Charger lane needs escape pads.")
	_expect(shooter != null and shooter.has_line_of_sight, "Shooter perch needs line of sight.")
	_expect(
		shooter != null and shooter.has_cover_or_elevation,
		"Shooter perch needs cover or elevation."
	)


func _validate_choice_room(data: RoomTemplateData, host: RoomTemplateHost) -> void:
	_expect(data.reward_budget == Vector2i(1, 1), "Choice room should guarantee one route reward.")
	_expect(_socket_for_role(data.exit_sockets, &"optional") != null, "Choice needs a branch socket.")
	_expect(_socket_for_role(data.entry_sockets, &"return") != null, "Choice needs a return socket.")
	_expect(
		host.get_anchor_by_id(&"Reward", &"flooded_upper_reward") != null,
		"Choice upper route should own its reward anchor."
	)


func _validate_optional_room(data: RoomTemplateData, host: RoomTemplateHost) -> void:
	_expect(data.reward_anchors.size() == 2, "Sunken cache should offer cache and material anchors.")
	_expect(_socket_for_role(data.entry_sockets, &"optional") != null, "Sunken cache needs branch entry.")
	_expect(_socket_for_role(data.exit_sockets, &"return") != null, "Sunken cache needs return exit.")
	var return_rope := host.get_node_or_null("Anchors/Objective/ReturnRope") as Climbable
	_expect(return_rope != null, "Sunken cache should own a return rope.")
	if return_rope != null:
		_expect(return_rope.climbable_size.y >= 620.0, "Sunken cache return rope should reach choice.")


func _validate_safe_room(data: RoomTemplateData, host: RoomTemplateHost) -> void:
	_expect(data.encounter_budget == Vector2i.ZERO, "Rest/forge cannot budget enemies.")
	_expect(data.hazard_budget == Vector2i.ZERO, "Rest/forge cannot budget hazards.")
	_expect(data.enemy_anchors.is_empty(), "Rest/forge cannot declare enemy anchors.")
	_expect(data.hazard_anchors.is_empty(), "Rest/forge cannot declare hazard anchors.")
	_expect(host.get_node_or_null("Anchors/Objective/RestSpawn") != null, "Rest spawn is missing.")
	_expect(host.get_node_or_null("Anchors/Objective/Checkpoint") != null, "Checkpoint is missing.")
	_expect(host.get_node_or_null("Anchors/Objective/ForgeStation") != null, "Forge anchor is missing.")
	_expect(host.get_node_or_null("Anchors/Objective/ShopStation") != null, "Shop anchor is missing.")
	_expect(host.get_exit_portal() != null, "Rest/forge terminal exit is missing.")


func _validate_role_candidates(
	catalog: RoomCatalog,
	characters: CharacterCatalog,
	profile: StageProfile
) -> void:
	for route in [POISON_ROUTE, CRUMBLE_ROUTE]:
		_validate_role_sequence(catalog, route)
		for character in characters.profiles:
			var limits := MovementMetrics.route_limits_for_profiles([character])
			_validate_route_connections(catalog, route, limits, String(character.id))
		_validate_optional_connections(
			catalog,
			MovementMetrics.route_limits_for_profiles(characters.profiles)
		)
	_expect(profile.supports_one_optional_branch(), "Flooded Works should support one optional branch.")
	var poison := catalog.get_room_by_id(&"fw_poison_timing")
	var crumble := catalog.get_room_by_id(&"fw_crumble_crossing")
	_expect(
		poison != null
		and crumble != null
		and poison.role == &"hazard"
		and crumble.role == &"hazard"
		and poison.variant_group == crumble.variant_group,
		"Poison and crumble rooms should be seed-selectable variants of one hazard slot."
	)


func _validate_role_sequence(catalog: RoomCatalog, route: Array[StringName]) -> void:
	_expect(route.size() == EXPECTED_ROLES.size(), "Candidate route should contain exactly seven rooms.")
	var used: Dictionary = {}
	for index in route.size():
		var room_data := catalog.get_room_by_id(route[index])
		_expect(room_data != null, "Candidate route references missing room %s." % route[index])
		if room_data == null:
			continue
		_expect(room_data.role == EXPECTED_ROLES[index], "Candidate route role %d is incorrect." % index)
		_expect(room_data.required_route, "%s should be required-route content." % room_data.id)
		_expect(not used.has(room_data.id), "Candidate route repeats %s." % room_data.id)
		used[room_data.id] = true


func _validate_route_connections(
	catalog: RoomCatalog,
	route: Array[StringName],
	limits: Dictionary,
	profile_label: String
) -> void:
	for index in range(route.size() - 1):
		var source := catalog.get_room_by_id(route[index])
		var target := catalog.get_room_by_id(route[index + 1])
		if source == null or target == null:
			continue
		_expect(
			not RoomSocketCompatibility.find_pair(
				source.exit_sockets,
				target.entry_sockets,
				&"critical",
				limits
			).is_empty(),
			"%s cannot connect %s to %s." % [profile_label, source.id, target.id]
		)


func _validate_optional_connections(catalog: RoomCatalog, limits: Dictionary) -> void:
	var choice := catalog.get_room_by_id(&"fw_lower_upper_choice")
	var optional := catalog.get_room_by_id(&"fw_sunken_cache")
	if choice == null or optional == null:
		return
	_expect(
		not RoomSocketCompatibility.find_pair(
			choice.exit_sockets,
			optional.entry_sockets,
			&"optional",
			limits
		).is_empty(),
		"Choice should connect to the sunken cache drop."
	)
	_expect(
		not RoomSocketCompatibility.find_pair(
			optional.exit_sockets,
			choice.entry_sockets,
			&"return",
			limits
		).is_empty(),
		"Sunken cache return rope should reconnect to choice."
	)


# Assemble the exact candidate plus its branch without relying on random selection.
func _validate_assembled_candidate(
	catalog: RoomCatalog,
	profile: StageProfile,
	route: Array[StringName],
	limits: Dictionary
) -> void:
	var planned_rooms: Array[PlannedRoom] = []
	var connections: Array[PlannedConnection] = []
	for index in route.size():
		var data := catalog.get_room_by_id(route[index])
		if data == null:
			return
		planned_rooms.append(
			PlannedRoom.new(data.id, data.id, data.content_version, data.role, true, index)
		)
		if index == 0:
			continue
		var previous := catalog.get_room_by_id(route[index - 1])
		var pair := RoomSocketCompatibility.find_pair(
			previous.exit_sockets,
			data.entry_sockets,
			&"critical",
			limits
		)
		if pair.is_empty():
			return
		connections.append(
			PlannedConnection.new(
				StringName("critical_%d" % (index - 1)),
				previous.id,
				(pair["from"] as RoomSocketData).id,
				data.id,
				(pair["to"] as RoomSocketData).id,
				&"critical"
			)
		)

	var optional := catalog.get_room_by_id(&"fw_sunken_cache")
	var choice := catalog.get_room_by_id(&"fw_lower_upper_choice")
	if optional == null or choice == null:
		return
	planned_rooms.append(
		PlannedRoom.new(optional.id, optional.id, optional.content_version, optional.role, false, 0)
	)
	var branch_pair := RoomSocketCompatibility.find_pair(
		choice.exit_sockets,
		optional.entry_sockets,
		&"optional",
		limits
	)
	var return_pair := RoomSocketCompatibility.find_pair(
		optional.exit_sockets,
		choice.entry_sockets,
		&"return",
		limits
	)
	if branch_pair.is_empty() or return_pair.is_empty():
		return
	connections.append(
		PlannedConnection.new(
			&"optional_branch_0",
			choice.id,
			(branch_pair["from"] as RoomSocketData).id,
			optional.id,
			(branch_pair["to"] as RoomSocketData).id,
			&"optional"
		)
	)
	connections.append(
		PlannedConnection.new(
			&"optional_return_0",
			optional.id,
			(return_pair["from"] as RoomSocketData).id,
			choice.id,
			(return_pair["to"] as RoomSocketData).id,
			&"return"
		)
	)
	var empty_encounters: Array[PlannedEncounter] = []
	var plan := StagePlan.new(
		73021,
		2,
		profile.id,
		profile.content_version,
		catalog.id,
		catalog.content_version,
		{},
		planned_rooms,
		connections,
		empty_encounters
	)
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var result := StageAssembler.assemble(plan, catalog, rooms_root)
	_expect(result.success, "Authored Flooded Works candidate should assemble.")
	for error in result.get_errors():
		_failures.append("Stage assembly: %s" % error)
	if result.success:
		_validate_assembled_bounds(plan, catalog, result.get_room_positions())
	rooms_root.queue_free()
	await process_frame


func _validate_assembled_bounds(plan: StagePlan, catalog: RoomCatalog, positions: Dictionary) -> void:
	var bounds_by_room: Array[Dictionary] = []
	for room in plan.get_rooms():
		var data := catalog.get_room_by_id(room.template_id)
		if data == null or not positions.has(String(room.id)):
			continue
		var position: Vector2 = positions[String(room.id)]
		bounds_by_room.append({
			"id": String(room.id),
			"bounds": Rect2(position + data.bounds.position, data.bounds.size),
		})
	for first_index in bounds_by_room.size():
		for second_index in range(first_index + 1, bounds_by_room.size()):
			var first: Rect2 = bounds_by_room[first_index]["bounds"]
			var second: Rect2 = bounds_by_room[second_index]["bounds"]
			var overlap_width := minf(first.end.x, second.end.x) - maxf(first.position.x, second.position.x)
			var overlap_height := minf(first.end.y, second.end.y) - maxf(first.position.y, second.position.y)
			_expect(
				overlap_width <= 0.5 or overlap_height <= 0.5,
				"Assembled rooms %s and %s overlap."
				% [bounds_by_room[first_index]["id"], bounds_by_room[second_index]["id"]]
			)


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


func _surface_supports(x: float, top: float, surfaces: Array[Dictionary]) -> bool:
	for surface in surfaces:
		if x < float(surface["x"]) - 1.0 or x > float(surface["end_x"]) + 1.0:
			continue
		if absf(top - float(surface["top"])) <= 1.0:
			return true
	return false


func _hazard_has_support(anchor: RoomAnchor, surfaces: Array[Dictionary]) -> bool:
	if anchor.allowed_tags.has(&"crumbling_platform"):
		return (
			anchor.has_meta("support_top")
			and anchor.support_width >= MIN_CRITICAL_LANDING
			and float(anchor.get_meta("support_top")) < anchor.position.y
		)
	for surface in surfaces:
		if anchor.position.x < float(surface["x"]) - 1.0:
			continue
		if anchor.position.x > float(surface["end_x"]) + 1.0:
			continue
		var vertical_offset := float(surface["top"]) - anchor.position.y
		if vertical_offset >= 0.0 and vertical_offset <= anchor.clearance:
			return true
	return false


func _surface_by_id(surfaces: Array[Dictionary], surface_id: StringName) -> Dictionary:
	for surface in surfaces:
		if surface["id"] == surface_id:
			return surface
	return {}


func _socket_for_role(sockets: Array[RoomSocketData], role: StringName) -> RoomSocketData:
	for socket in sockets:
		if socket != null and socket.route_role == role:
			return socket
	return null


func _same_ids(left: Array[StringName], right: Array[StringName]) -> bool:
	var left_copy := left.duplicate()
	var right_copy := right.duplicate()
	left_copy.sort()
	right_copy.sort()
	return left_copy == right_copy


func _to_string_names(value: Variant) -> Array[StringName]:
	var names: Array[StringName] = []
	if value is Array:
		for item in value:
			names.append(StringName(str(item)))
	return names


func _to_vector2i(value: Variant) -> Vector2i:
	if value is Array and value.size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


func _append_errors(errors: PackedStringArray, label: String) -> void:
	for error in errors:
		_failures.append("%s: %s" % [label, error])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_WORKS_ROOM_VALIDATION_OK rooms=9 routes=2 optional_branches=1")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
