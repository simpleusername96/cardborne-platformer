extends SceneTree

const SEED_COUNT := 1000
const CURATED_SEEDS: Array[int] = [1103, 29017, 73102]

var _failures: Array[String] = []


func _initialize() -> void:
	var rooms := load("res://data/generation/lower_ruins_room_catalog.tres") as RoomCatalog
	var stage_profile := load("res://data/generation/ruin_approach_profile.tres") as StageProfile
	var enemies := load("res://data/enemies/enemy_catalog.tres") as EnemyCatalog
	var hazards := load("res://data/hazards/hazard_catalog.tres") as HazardCatalog
	var rewards := load("res://data/rewards/reward_catalog.tres") as RewardCatalog
	var characters := load("res://data/characters/character_catalog.tres") as CharacterCatalog
	if null in [rooms, stage_profile, enemies, hazards, rewards, characters]:
		_failures.append("all property-gate catalogs should load")
		_finish(0, 0, 0)
		return
	var shared_limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	var topology_signatures: Dictionary = {}
	var encounter_signatures: Dictionary = {}
	var optional_templates: Dictionary = {}
	var hazard_decisions: Dictionary = {}
	var fallback_count := 0

	for seed in SEED_COUNT:
		var first := StageGenerationService.new().generate(
			rooms,
			stage_profile,
			enemies,
			hazards,
			rewards,
			seed,
			0,
			shared_limits
		)
		var second := StageGenerationService.new().generate(
			rooms,
			stage_profile,
			enemies,
			hazards,
			rewards,
			seed,
			0,
			shared_limits
		)
		if not first.success or first.plan == null:
			_failures.append("seed %d did not produce a valid plan" % seed)
			continue
		if not second.success or second.plan == null or first.plan.to_json() != second.plan.to_json():
			_failures.append("seed %d did not reproduce byte-equivalently" % seed)
			continue
		_expect(first.plan.run_seed == seed, "accepted plan should preserve seed %d" % seed)
		_expect(first.plan.get_rooms().size() == 7, "seed %d should retain the 6+1 graph" % seed)
		var report_data := first.report.to_dictionary()
		if bool(report_data["fallback_used"]):
			fallback_count += 1
			_expect(not String(report_data["fallback_id"]).is_empty(), "fallback seed should report its fixture")
		topology_signatures[_topology_signature(first.plan)] = true
		encounter_signatures[_encounter_signature(first.plan)] = true
		optional_templates[_optional_template(first.plan)] = true
		hazard_decisions[str(first.plan.get_hazards().size())] = true

	_expect(topology_signatures.size() >= 6, "1,000 seeds should vary authored room decisions")
	_expect(encounter_signatures.size() >= 8, "1,000 seeds should vary encounter decisions")
	_expect(optional_templates.size() == 2, "both optional room templates should appear")
	_expect(hazard_decisions.has("0") and hazard_decisions.has("1"), "spike and safe traversal variants should both appear")
	_validate_curated_all_character_routes(
		rooms,
		stage_profile,
		enemies,
		hazards,
		rewards,
		characters
	)
	_finish(fallback_count, topology_signatures.size(), encounter_signatures.size())


func _validate_curated_all_character_routes(
	rooms: RoomCatalog,
	stage_profile: StageProfile,
	enemies: EnemyCatalog,
	hazards: HazardCatalog,
	rewards: RewardCatalog,
	characters: CharacterCatalog
) -> void:
	var shared_limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	for seed in CURATED_SEEDS:
		var result := StageGenerationService.new().generate(
			rooms, stage_profile, enemies, hazards, rewards, seed, 0, shared_limits
		)
		_expect(result.success and result.plan != null, "curated seed %d should generate" % seed)
		if result.plan == null:
			continue
		for character in characters.profiles:
			var character_limits := MovementMetrics.route_limits_for_profiles([character])
			var errors := StagePlanValidator.validate_complete(
				result.plan,
				rooms,
				stage_profile,
				character_limits,
				enemies,
				hazards,
				rewards
			)
			_expect(
				errors.is_empty(),
				"curated seed %d should fit base %s movement: %s"
				% [seed, character.id, "; ".join(errors)]
			)


func _topology_signature(plan: StagePlan) -> String:
	var ids: Array[String] = []
	for room in plan.get_rooms():
		ids.append(String(room.template_id))
	return "|".join(ids)


func _encounter_signature(plan: StagePlan) -> String:
	var rows: Array[String] = []
	for encounter in plan.get_encounters():
		rows.append("%s:%s:%s" % [encounter.room_id, encounter.anchor_id, encounter.variant_id])
	return "|".join(rows)


func _optional_template(plan: StagePlan) -> String:
	for room in plan.get_rooms():
		if not room.required_route:
			return String(room.template_id)
	return "missing"


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 40:
		_failures.append(message)


func _finish(fallbacks: int, topology_count: int, encounter_count: int) -> void:
	if _failures.is_empty():
		print(
			"STAGE_GENERATION_PROPERTIES_OK seeds=%d fallbacks=%d topologies=%d encounters=%d"
			% [SEED_COUNT, fallbacks, topology_count, encounter_count]
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
