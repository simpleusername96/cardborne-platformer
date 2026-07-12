extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	var rooms := load("res://data/generation/lower_ruins_room_catalog.tres") as RoomCatalog
	var profile := load("res://data/generation/ruin_approach_profile.tres") as StageProfile
	var enemies := load("res://data/enemies/enemy_catalog.tres") as EnemyCatalog
	var hazards := load("res://data/hazards/hazard_catalog.tres") as HazardCatalog
	var rewards := load("res://data/rewards/reward_catalog.tres") as RewardCatalog
	var characters := load("res://data/characters/character_catalog.tres") as CharacterCatalog
	if null in [rooms, profile, enemies, hazards, rewards, characters]:
		_failures.append("all shipped generation resources should load")
		_finish()
		return
	var limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	limits["minimum_headroom"] = 100.0
	limits["allowed_required_abilities"] = [
		"baseline", "double_jump", "dash", "crouch", "climb",
	]

	for seed in [1103, 29017, 73102]:
		var first := StageGenerationService.new().generate(
			rooms, profile, enemies, hazards, rewards, seed, 0, limits
		)
		var second := StageGenerationService.new().generate(
			rooms, profile, enemies, hazards, rewards, seed, 0, limits
		)
		_expect(first.success and first.plan != null, "seed %d should generate" % seed)
		_expect(second.success and second.plan != null, "seed %d should regenerate" % seed)
		if first.plan == null or second.plan == null:
			continue
		_expect(first.plan.to_json() == second.plan.to_json(), "seed %d should be byte-identical" % seed)
		_expect(first.report.is_successful(), "seed %d report should be successful" % seed)
		_expect(not bool(first.report.to_dictionary()["fallback_used"]), "seed %d should use a random plan" % seed)
		_validate_assembly(first.plan, rooms, seed)

	var fallback := StageGenerationService.new().generate(
		rooms,
		profile,
		enemies,
		hazards,
		rewards,
		1103,
		0,
		limits,
		0
	)
	_expect(fallback.success and fallback.plan != null, "curated fallback should generate")
	if fallback.plan != null:
		_expect(
			fallback.plan.generation_attempt == CuratedStagePlanBuilder.FALLBACK_ATTEMPT,
			"fallback should preserve its deterministic attempt"
		)
		_expect(bool(fallback.report.to_dictionary()["fallback_used"]), "fallback report should identify fallback use")
		_validate_assembly(fallback.plan, rooms, 1103)

	var invalid := StageGenerationService.new().generate(
		rooms,
		profile,
		enemies,
		null,
		rewards,
		1,
		0,
		limits
	)
	_expect(not invalid.success and invalid.plan == null, "missing hazard catalog should fail closed")
	_expect(not invalid.report.get_failures().is_empty(), "preflight failure should be reported")
	_finish()


func _validate_assembly(plan: StagePlan, rooms: RoomCatalog, seed: int) -> void:
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(plan, rooms, rooms_root)
	_expect(
		assembly.success,
		"seed %d complete plan should assemble: %s" % [seed, "; ".join(assembly.get_errors())]
	)
	rooms_root.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_GENERATION_SERVICE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
