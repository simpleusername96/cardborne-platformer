extends SceneTree

const SEED_COUNT := 300
const CURATED_SEEDS: Array[int] = [2207, 48119, 90533]

var _failures: Array[String] = []


func _initialize() -> void:
	var rooms := load("res://data/generation/flooded_works_room_catalog.tres") as RoomCatalog
	var profile := load("res://data/generation/flooded_works_profile.tres") as StageProfile
	var enemies := load("res://data/enemies/enemy_catalog.tres") as EnemyCatalog
	var hazards := load("res://data/hazards/hazard_catalog.tres") as HazardCatalog
	var rewards := load("res://data/rewards/reward_catalog.tres") as RewardCatalog
	var characters := load("res://data/characters/character_catalog.tres") as CharacterCatalog
	if null in [rooms, profile, enemies, hazards, rewards, characters]:
		_failures.append("Flooded generation catalogs should load")
		_finish(0, 0)
		return
	var limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	var topology_signatures: Dictionary = {}
	var encounter_signatures: Dictionary = {}
	var hazard_templates: Dictionary = {}
	for seed in SEED_COUNT:
		var first := StageGenerationService.new().generate(
			rooms, profile, enemies, hazards, rewards, seed, 1, limits
		)
		var replay := StageGenerationService.new().generate(
			rooms, profile, enemies, hazards, rewards, seed, 1, limits
		)
		if not first.success or first.plan == null:
			_expect(false, "Flooded seed %d should generate" % seed)
			continue
		_expect(
			replay.success and replay.plan != null and first.plan.to_json() == replay.plan.to_json(),
			"Flooded seed %d should reproduce byte-equivalently" % seed
		)
		_expect(first.plan.get_rooms().size() == 8, "Flooded seed %d should retain the 7+1 graph" % seed)
		var topology_signature := _topology_signature(first.plan)
		if not topology_signatures.has(topology_signature):
			_validate_geometry(first.plan, rooms, limits, "seed %d" % seed)
		topology_signatures[topology_signature] = true
		encounter_signatures[_encounter_signature(first.plan)] = true
		for room in first.plan.get_rooms():
			if room.role == &"hazard":
				hazard_templates[String(room.template_id)] = true
	_expect(topology_signatures.size() >= 4, "Flooded seeds should vary hazard and combat room decisions")
	_expect(encounter_signatures.size() >= 8, "Flooded seeds should vary exact encounter decisions")
	_expect(hazard_templates.has("fw_poison_timing"), "Poison timing room should appear")
	_expect(hazard_templates.has("fw_crumble_crossing"), "Crumble crossing room should appear")
	_validate_curated_all_characters(rooms, profile, enemies, hazards, rewards, characters)
	_validate_fallback(rooms, profile, enemies, hazards, rewards, limits)
	_finish(topology_signatures.size(), encounter_signatures.size())


func _validate_curated_all_characters(
	rooms: RoomCatalog,
	profile: StageProfile,
	enemies: EnemyCatalog,
	hazards: HazardCatalog,
	rewards: RewardCatalog,
	characters: CharacterCatalog
) -> void:
	var shared_limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	for seed in CURATED_SEEDS:
		var result := StageGenerationService.new().generate(
			rooms, profile, enemies, hazards, rewards, seed, 1, shared_limits
		)
		_expect(result.success and result.plan != null, "curated Flooded seed %d should generate" % seed)
		if result.plan == null:
			continue
		for character in characters.profiles:
			var errors := StagePlanValidator.validate_complete(
				result.plan,
				rooms,
				profile,
				MovementMetrics.route_limits_for_profiles([character]),
				enemies,
				hazards,
				rewards
			)
			_expect(
				errors.is_empty(),
				"Flooded seed %d should fit base %s: %s" % [seed, character.id, "; ".join(errors)]
			)


func _validate_fallback(
	rooms: RoomCatalog,
	profile: StageProfile,
	enemies: EnemyCatalog,
	hazards: HazardCatalog,
	rewards: RewardCatalog,
	limits: Dictionary
) -> void:
	var fallback := StageGenerationService.new().generate(
		rooms, profile, enemies, hazards, rewards, 7331, 1, limits, 0
	)
	_expect(fallback.success and fallback.plan != null, "Flooded curated fallback should generate")
	_expect(
		fallback.report != null and bool(fallback.report.to_dictionary().get("fallback_used", false)),
		"Flooded zero-attempt generation should report fallback use"
	)
	if fallback.plan != null:
		_validate_geometry(fallback.plan, rooms, limits, "curated fallback")


func _validate_geometry(
	plan: StagePlan,
	rooms: RoomCatalog,
	limits: Dictionary,
	context: String
) -> void:
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(plan, rooms, rooms_root)
	_expect(
		assembly.success,
		"Flooded %s should assemble: %s" % [context, "; ".join(assembly.get_errors())]
	)
	if assembly.success:
		var errors := StageGeometryValidator.validate_assembly(plan, rooms, assembly, limits)
		_expect(
			errors.is_empty(),
			"Flooded %s geometry should be traversable: %s" % [context, "; ".join(errors)]
		)
	rooms_root.queue_free()


func _topology_signature(plan: StagePlan) -> String:
	var ids: Array[String] = []
	for room in plan.get_rooms():
		ids.append(String(room.template_id))
	return "|".join(ids)


func _encounter_signature(plan: StagePlan) -> String:
	var rows: Array[String] = []
	for encounter in plan.get_encounters():
		rows.append("%s:%s" % [encounter.room_id, encounter.variant_id])
	return "|".join(rows)


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 40:
		_failures.append(message)


func _finish(topologies: int, encounters: int) -> void:
	if _failures.is_empty():
		print(
			"FLOODED_GENERATION_VALIDATION_OK seeds=%d topologies=%d encounters=%d"
			% [SEED_COUNT, topologies, encounters]
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
