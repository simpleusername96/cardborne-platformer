extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const Tactics = preload("res://scripts/encounters/vehicle_collective_tactic_catalog.gd")
const Elites = preload("res://scripts/enemies/vehicle_elite_trait_catalog.gd")
const BossPhases = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")

var failures: Array[String] = []


func _init() -> void:
	var ids: Array[StringName] = []
	for number in range(1, 11):
		ids.append(StringName("stage_%d" % number))
	_expect(CombatStages.STAGE_IDS == ids, "the canonical registry contains stage_1 through stage_10")
	_expect(CombatStages.QUOTAS == [24, 24, 32, 32, 40, 40, 48, 48, 56, 56], "quota progression is exact")
	_expect(CombatStages.AUTHORED_COUNTS == [260, 260, 330, 330, 408, 408, 513, 513, 630, 630], "authored populations are exact")
	for index in ids.size():
		var stage_id := ids[index]
		var pair_start := index - 1 if index % 2 == 1 else index
		var profile := CombatStages.profile(stage_id)
		_expect(not profile.is_empty(), "%s has a profile" % stage_id)
		_expect(bool(profile["has_boss"]) == (index % 2 == 1), "%s has the expected boss gate" % stage_id)
		_expect(
			CombatStages.MOBILE_ROLES[index] == CombatStages.MOBILE_ROLES[pair_start],
			"%s retains its paired ordinary-enemy role arc" % stage_id
		)
		_expect(Elites.thresholds(index).size() == index / 2 + 1, "%s has an explicit elite schedule" % stage_id)
		_expect(not Tactics.assignment_for(index, 0, 3, 4).is_empty(), "%s has a tactic mapping" % stage_id)
	_expect(CombatStages.normalized_id(&"stage_11").is_empty(), "unknown stage IDs fail closed")
	_expect(StageCatalog.definition(&"stage_11").is_empty(), "catalog lookup fails closed")
	_expect(Difficulty.multipliers(10).is_empty(), "difficulty lookup fails closed")
	_expect(Difficulty.stage_index_from_id(&"stage_11") == -1, "unknown difficulty ID fails closed")
	_expect(Difficulty.HEALTH.size() == 10 and is_equal_approx(float(Difficulty.HEALTH[9]), 1.45), "Stage 10 preserves old final health")
	_expect(is_equal_approx(float(Difficulty.BOSS_BASE_HEALTH[9]), 1650.0), "Stage 10 preserves old final boss health")
	var expected_profiles: Array[StringName] = [&"stage_1", &"stage_2", &"stage_3", &"stage_4", &"stage_5"]
	for boss_index in expected_profiles.size():
		var stage_id := ids[boss_index * 2 + 1]
		_expect(CombatStages.boss_profile_id(stage_id) == expected_profiles[boss_index], "%s maps to its preserved boss arc" % stage_id)
		_expect(not BossPhases.definition(stage_id).is_empty(), "%s maps to a boss phase definition" % stage_id)
		_expect(not BossPatterns.sequence(stage_id).is_empty(), "%s maps to boss patterns" % stage_id)
	_expect(BossPhases.validate_contract().is_empty(), "all five preserved boss phase packets validate")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_TEN_STAGE_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
