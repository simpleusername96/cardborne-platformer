extends SceneTree

const PROFILE_PATH := "res://data/generation/broken_sanctum_profile.tres"
const ROOM_CATALOG_PATH := "res://data/generation/broken_sanctum_room_catalog.tres"
const ENEMY_CATALOG_PATH := "res://data/enemies/enemy_catalog.tres"
const HAZARD_CATALOG_PATH := "res://data/hazards/hazard_catalog.tres"
const REWARD_CATALOG_PATH := "res://data/rewards/reward_catalog.tres"
const CHARACTER_CATALOG_PATH := "res://data/characters/character_catalog.tres"
const SEED_COUNT := 120

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := load(PROFILE_PATH) as StageProfile
	var rooms := load(ROOM_CATALOG_PATH) as RoomCatalog
	var enemies := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var hazards := load(HAZARD_CATALOG_PATH) as HazardCatalog
	var rewards := load(REWARD_CATALOG_PATH) as RewardCatalog
	var characters := load(CHARACTER_CATALOG_PATH) as CharacterCatalog
	_expect(null not in [profile, rooms, enemies, hazards, rewards, characters], "all Stage 3 catalogs should load")
	if null in [profile, rooms, enemies, hazards, rewards, characters]:
		_finish()
		return
	_expect(profile.validate_definition().is_empty(), "Broken Sanctum profile should validate")
	_expect(rooms.validate_catalog().is_empty(), "Broken Sanctum room catalog should validate")
	_expect(enemies.validate_catalog().is_empty(), "complete enemy catalog should validate")
	_expect(rewards.get_table(&"stage_clear_broken_sanctum") != null, "Stage 3 clear reward should be registered")

	var limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	limits["minimum_headroom"] = 100.0
	limits["allowed_required_abilities"] = [
		"baseline", "double_jump", "dash", "crouch", "climb",
	]
	var topologies: Dictionary = {}
	var seen_archetypes: Dictionary = {}
	for seed_offset in SEED_COUNT:
		var seed := 41_000 + seed_offset * 977
		var first := StageGenerationService.new().generate(
			rooms, profile, enemies, hazards, rewards, seed, 2, limits
		)
		var repeated := StageGenerationService.new().generate(
			rooms, profile, enemies, hazards, rewards, seed, 2, limits
		)
		_expect(first.success and first.plan != null, "seed %d should generate" % seed)
		_expect(repeated.success and repeated.plan != null, "seed %d should regenerate" % seed)
		if first.plan == null or repeated.plan == null:
			continue
		_expect(first.plan.to_json() == repeated.plan.to_json(), "seed %d should be deterministic" % seed)
		_validate_plan(first.plan, rooms, profile, enemies, hazards, rewards, limits, seed)
		topologies[_required_route_signature(first.plan)] = true
		for encounter in first.plan.get_encounters():
			seen_archetypes[String(encounter.archetype_id)] = true
		if seed_offset < 12:
			_validate_assembly(first.plan, rooms, limits, seed)

	_expect(topologies.size() >= 2, "seed sweep should produce more than one required combat route")
	for archetype_id in profile.eligible_enemy_archetypes:
		_expect(seen_archetypes.has(String(archetype_id)), "%s should appear across Stage 3 seeds" % archetype_id)

	var fallback := StageGenerationService.new().generate(
		rooms, profile, enemies, hazards, rewards, 91_703, 2, limits, 0
	)
	_expect(fallback.success and fallback.plan != null, "curated Stage 3 fallback should generate")
	if fallback.plan != null:
		_expect(fallback.plan.generation_attempt == CuratedStagePlanBuilder.FALLBACK_ATTEMPT, "fallback attempt should be explicit")
		_validate_plan(fallback.plan, rooms, profile, enemies, hazards, rewards, limits, 91_703)
		_validate_assembly(fallback.plan, rooms, limits, 91_703)
	_finish(topologies.size(), seen_archetypes.size())


func _validate_plan(
	plan: StagePlan,
	rooms: RoomCatalog,
	profile: StageProfile,
	enemies: EnemyCatalog,
	hazards: HazardCatalog,
	rewards: RewardCatalog,
	limits: Dictionary,
	seed: int
) -> void:
	var required_count := 0
	var optional_count := 0
	for room in plan.get_rooms():
		if room.required_route:
			required_count += 1
		else:
			optional_count += 1
	_expect(required_count == 8 and optional_count == 2, "seed %d should preserve the 8+2 contract" % seed)
	var errors := StagePlanValidator.validate_complete(
		plan, rooms, profile, limits, enemies, hazards, rewards
	)
	_expect(errors.is_empty(), "seed %d complete plan should validate: %s" % [seed, "; ".join(errors)])


func _validate_assembly(
	plan: StagePlan,
	rooms: RoomCatalog,
	limits: Dictionary,
	seed: int
) -> void:
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(plan, rooms, rooms_root)
	_expect(assembly.success, "seed %d should assemble: %s" % [seed, "; ".join(assembly.get_errors())])
	if assembly.success:
		var geometry_errors := StageGeometryValidator.validate_assembly(plan, rooms, assembly, limits)
		_expect(geometry_errors.is_empty(), "seed %d geometry should validate: %s" % [seed, "; ".join(geometry_errors)])
	rooms_root.queue_free()


func _required_route_signature(plan: StagePlan) -> String:
	var required: Array[PlannedRoom] = []
	for room in plan.get_rooms():
		if room.required_route:
			required.append(room)
	required.sort_custom(func(left: PlannedRoom, right: PlannedRoom) -> bool:
		return left.route_index < right.route_index
	)
	var ids: Array[String] = []
	for room in required:
		ids.append(String(room.template_id))
	return ">".join(ids)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(topology_count: int = 0, archetype_count: int = 0) -> void:
	if _failures.is_empty():
		print(
			"BROKEN_SANCTUM_GENERATION_VALIDATION_OK seeds=%d topologies=%d archetypes=%d"
			% [SEED_COUNT, topology_count, archetype_count]
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
