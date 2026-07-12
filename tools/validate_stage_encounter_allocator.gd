extends SceneTree

const ROOM_CATALOG_PATH := "res://data/generation/lower_ruins_room_catalog.tres"
const STAGE_PROFILE_PATH := "res://data/generation/ruin_approach_profile.tres"
const ENEMY_CATALOG_PATH := "res://data/enemies/enemy_catalog.tres"
const TEST_SEED := 713031

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var room_catalog := load(ROOM_CATALOG_PATH) as RoomCatalog
	var profile := load(STAGE_PROFILE_PATH) as StageProfile
	var enemy_catalog := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	_expect(room_catalog != null, "real Lower Ruins room catalog should load")
	_expect(profile != null, "real Ruin Approach profile should load")
	_expect(enemy_catalog != null, "real enemy catalog should load")
	if room_catalog == null or profile == null or enemy_catalog == null:
		_finish()
		return

	_expect(room_catalog.validate_catalog().is_empty(), "real room catalog should validate")
	_expect(profile.validate_definition().is_empty(), "real Stage 1 profile should validate")
	_expect(enemy_catalog.validate_catalog().is_empty(), "real enemy catalog should validate")

	var plan := _build_real_plan(room_catalog, profile)
	_expect(plan != null, "real-resource fixture plan should build")
	if plan == null:
		_finish()
		return

	_validate_exact_deterministic_allocation(plan, room_catalog, profile, enemy_catalog)
	_validate_explicit_failures(plan, room_catalog, profile, enemy_catalog)
	_validate_variant_stream_isolation(plan, room_catalog, profile, enemy_catalog)
	_finish()


func _validate_exact_deterministic_allocation(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog
) -> void:
	var first_allocator := StageEncounterAllocator.new()
	var second_allocator := StageEncounterAllocator.new()
	var first := first_allocator.allocate(plan, room_catalog, profile, enemy_catalog)
	var second := second_allocator.allocate(plan, room_catalog, profile, enemy_catalog)
	_expect(
		first != null,
		"real-resource allocation should succeed: %s" % "; ".join(first_allocator.last_errors)
	)
	_expect(
		second != null,
		"repeated real-resource allocation should succeed: %s" % "; ".join(second_allocator.last_errors)
	)
	if first == null or second == null:
		return

	_expect(first.to_json() == second.to_json(), "same StagePlan must produce byte-identical encounters")
	_expect(plan.get_encounters().is_empty(), "allocator must not mutate its source StagePlan")
	_expect(first.run_seed == plan.run_seed, "allocator should preserve run seed")
	_expect(first.get_rng_stream_seeds() == plan.get_rng_stream_seeds(), "allocator should preserve stream seeds")
	_expect(
		_serialize_connections(first) == _serialize_connections(plan),
		"allocator should preserve planned connections"
	)
	_validate_encounter_contracts(first, room_catalog, profile, enemy_catalog)


func _validate_encounter_contracts(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog
) -> void:
	var rooms: Dictionary = {}
	var spent: Dictionary = {}
	var used_anchors: Dictionary = {}
	var encounter_ids: Dictionary = {}
	for room in plan.get_rooms():
		rooms[String(room.id)] = room
		spent[String(room.id)] = 0

	for encounter in plan.get_encounters():
		var room_key := String(encounter.room_id)
		_expect(not encounter_ids.has(encounter.id), "encounter IDs should be unique")
		encounter_ids[encounter.id] = true
		_expect(rooms.has(room_key), "encounter should reference a planned room")
		if not rooms.has(room_key):
			continue
		var room: PlannedRoom = rooms[room_key]
		var template := room_catalog.get_room_by_id(room.template_id)
		_expect(template.get_enemy_anchor_ids().has(encounter.anchor_id), "encounter anchor should be authored")
		var anchor_key := "%s:%s" % [encounter.room_id, encounter.anchor_id]
		_expect(not used_anchors.has(anchor_key), "room enemy anchors cannot be reused")
		used_anchors[anchor_key] = true
		_expect(
			template.allowed_enemy_tags.has(encounter.pressure_role),
			"encounter pressure role should be allowed by its room"
		)
		_expect(
			profile.eligible_enemy_archetypes.has(encounter.archetype_id),
			"encounter archetype should be eligible for Stage 1"
		)
		var archetype := enemy_catalog.get_archetype_by_id(encounter.archetype_id)
		_expect(archetype != null, "encounter archetype should resolve")
		if archetype != null:
			_expect(
				archetype.pressure_roles.has(encounter.pressure_role),
				"encounter pressure role should belong to its archetype"
			)
		var resolved := enemy_catalog.resolve(
			encounter.archetype_id,
			encounter.variant_id,
			profile.id
		)
		_expect(resolved != null, "encounter should resolve an exact Stage 1 variant")
		if resolved != null:
			_expect(
				resolved.variant_content_version == encounter.content_version,
				"encounter should preserve exact variant content version"
			)
			_expect(
				resolved.budget_cost == encounter.budget_cost,
				"encounter should preserve exact variant budget cost"
			)
		spent[room_key] = int(spent[room_key]) + encounter.budget_cost

	for room in plan.get_rooms():
		_expect(
			int(spent[String(room.id)]) == room.encounter_budget,
			"room '%s' should spend its exact encounter budget" % room.id
		)


func _validate_explicit_failures(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog
) -> void:
	var missing_seed_data := plan.to_dictionary()
	var missing_seeds: Dictionary = missing_seed_data["rng_stream_seeds"]
	missing_seeds.erase("enemy_variant")
	var missing_seed_plan := StagePlan.from_dictionary(missing_seed_data)
	var missing_seed_allocator := StageEncounterAllocator.new()
	_expect(
		missing_seed_allocator.allocate(
			missing_seed_plan, room_catalog, profile, enemy_catalog
		) == null,
		"missing variant stream should reject allocation"
	)
	_expect(
		_has_error(missing_seed_allocator.last_errors, "missing RNG stream seed 'enemy_variant'"),
		"missing stream rejection should explain the exact contract"
	)

	var impossible_catalog := _clone_room_catalog(room_catalog)
	var impossible_choice := impossible_catalog.get_room_by_id(&"lr_lower_upper_choice")
	impossible_choice.allowed_enemy_tags = [&"burst"]
	impossible_choice.enemy_anchors[0].allowed_pressure_roles = [&"burst"]
	_expect(impossible_catalog.validate_catalog().is_empty(), "impossible fixture catalog should remain valid")
	var impossible_allocator := StageEncounterAllocator.new()
	var impossible_result := impossible_allocator.allocate(
		plan,
		impossible_catalog,
		profile,
		enemy_catalog
	)
	_expect(impossible_result == null, "unfillable exact budget should return no partial StagePlan")
	_expect(
		_has_error(impossible_allocator.last_errors, "cannot exactly fill encounter budget 1"),
		"unfillable budget should identify the room budget failure"
	)
	_expect(plan.get_encounters().is_empty(), "failed allocation must leave the source plan untouched")


func _validate_variant_stream_isolation(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog
) -> void:
	var expanded_catalog := enemy_catalog.duplicate(true) as EnemyCatalog
	var source_variant := expanded_catalog.get_variant_by_id(&"walker_ruin")
	var alternate := source_variant.duplicate(true) as EnemyVariantDefinition
	alternate.id = &"walker_ruin_alt"
	alternate.display_name = "Walker Ruin Alternate"
	alternate.content_version = 2
	alternate.presentation_key = &"enemy.walker.ruin_alt"
	alternate.presentation_description = "Stage 1 validation variant with the same exact encounter cost."
	expanded_catalog.variants.append(alternate)
	_expect(expanded_catalog.validate_catalog().is_empty(), "expanded real enemy catalog should validate")

	var structure_signatures: Dictionary = {}
	var variant_signatures: Dictionary = {}
	for variant_seed in range(1, 25):
		var seeded_data := plan.to_dictionary()
		var seeds: Dictionary = seeded_data["rng_stream_seeds"]
		seeds["enemy_variant"] = variant_seed
		var seeded_plan := StagePlan.from_dictionary(seeded_data)
		var allocator := StageEncounterAllocator.new()
		var allocated := allocator.allocate(
			seeded_plan,
			room_catalog,
			profile,
			expanded_catalog
		)
		_expect(
			allocated != null,
			"variant-seed fixture should allocate: %s" % "; ".join(allocator.last_errors)
		)
		if allocated == null:
			continue
		structure_signatures[_encounter_signature(allocated, false)] = true
		variant_signatures[_encounter_signature(allocated, true)] = true
	_expect(
		structure_signatures.size() == 1,
		"enemy_variant stream changes must not perturb roles, archetypes, anchors, or budgets"
	)
	_expect(
		variant_signatures.size() >= 2,
		"enemy_variant stream should independently select between eligible exact variants"
	)


func _build_real_plan(room_catalog: RoomCatalog, profile: StageProfile) -> StagePlan:
	var room_specs := [
		[&"lr_start_shelf", true, 0, 0],
		[&"lr_rise_steps", true, 1, 0],
		[&"lr_patrol_gallery", true, 2, 2],
		[&"lr_lower_upper_choice", true, 3, 1],
		[&"lr_shooter_overlook", true, 4, 3],
		[&"lr_exit_ascent", true, 5, 2],
		[&"lr_material_cavern", false, 0, 1],
	]
	var rooms: Array[PlannedRoom] = []
	for spec in room_specs:
		var template := room_catalog.get_room_by_id(spec[0])
		_expect(template != null, "fixture room '%s' should exist" % spec[0])
		if template == null:
			return null
		rooms.append(
			PlannedRoom.new(
				template.id,
				template.id,
				template.content_version,
				template.role,
				bool(spec[1]),
				int(spec[2]),
				int(spec[3]),
				0,
				0
			)
		)
	var connections: Array[PlannedConnection] = [
		PlannedConnection.new(
			&"preserved_connection",
			&"lr_start_shelf",
			&"start_exit",
			&"lr_rise_steps",
			&"rise_entry",
			&"critical"
		),
	]
	var encounters: Array[PlannedEncounter] = []
	var streams := NamedRngStreams.new(
		TEST_SEED,
		0,
		room_catalog.content_version,
		profile.content_version
	)
	return StagePlan.new(
		TEST_SEED,
		0,
		profile.id,
		profile.content_version,
		room_catalog.id,
		room_catalog.content_version,
		streams.get_stream_seeds(),
		rooms,
		connections,
		encounters
	)


func _clone_room_catalog(source: RoomCatalog) -> RoomCatalog:
	var clone := RoomCatalog.new()
	clone.id = source.id
	clone.display_name = source.display_name
	clone.content_version = source.content_version
	var cloned_rooms: Array[RoomTemplateData] = []
	for room in source.rooms:
		cloned_rooms.append(room.duplicate(true) as RoomTemplateData)
	clone.rooms = cloned_rooms
	return clone


func _serialize_connections(plan: StagePlan) -> String:
	var serialized: Array[Dictionary] = []
	for connection in plan.get_connections():
		serialized.append(connection.to_dictionary())
	return JSON.stringify(serialized)


func _encounter_signature(plan: StagePlan, include_variant: bool) -> String:
	var rows: Array[String] = []
	for encounter in plan.get_encounters():
		var row := "%s|%s|%s|%s|%d" % [
			encounter.room_id,
			encounter.anchor_id,
			encounter.pressure_role,
			encounter.archetype_id,
			encounter.budget_cost,
		]
		if include_variant:
			row += "|%s|%d" % [encounter.variant_id, encounter.content_version]
		rows.append(row)
	return ";".join(rows)


func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.to_lower().contains(fragment.to_lower()):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_ENCOUNTER_ALLOCATOR_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
