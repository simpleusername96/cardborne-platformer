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
	for number in range(1, 9):
		ids.append(StringName("stage_%d" % number))
	_expect(CombatStages.STAGE_IDS == ids, "the canonical registry contains eight internal cycle IDs")
	_expect(CombatStages.QUOTAS == [40, 44, 48, 52, 56, 60, 64, 68], "quota progression is exact")
	_expect(CombatStages.AUTHORED_COUNTS == [260, 300, 340, 390, 440, 500, 560, 630], "authored populations are exact")
	for index in ids.size():
		var stage_id := ids[index]
		var profile := CombatStages.profile(stage_id)
		_expect(not profile.is_empty(), "%s has a profile" % stage_id)
		_expect(bool(profile["has_boss"]), "%s has its quota-gated boss" % stage_id)
		_expect(not CombatStages.MOBILE_ROLES[index].is_empty(), "%s has an ordinary-enemy role arc" % stage_id)
		_expect(not Elites.thresholds(index).is_empty(), "%s has an explicit elite schedule" % stage_id)
		_expect(not Tactics.assignment_for(index, 0, 3, 4).is_empty(), "%s has a tactic mapping" % stage_id)
	_expect(CombatStages.normalized_id(&"stage_11").is_empty(), "unknown stage IDs fail closed")
	_expect(StageCatalog.definition(&"stage_11").is_empty(), "catalog lookup fails closed")
	_expect(Difficulty.multipliers(8).is_empty(), "difficulty lookup fails closed")
	_expect(Difficulty.stage_index_from_id(&"stage_11") == -1, "unknown difficulty ID fails closed")
	_expect(Difficulty.HEALTH.size() == 8 and is_equal_approx(float(Difficulty.HEALTH[7]), 3.10), "cycle 8 has the final ordinary health scale")
	_expect(is_equal_approx(Difficulty.boss_health(7), 10660.0), "cycle 8 has the final boss health")
	var expected_profiles: Array[StringName] = ids.duplicate()
	for boss_index in expected_profiles.size():
		var stage_id := ids[boss_index]
		_expect(CombatStages.boss_profile_id(stage_id) == expected_profiles[boss_index], "%s maps to its preserved boss arc" % stage_id)
		_expect(not BossPhases.definition(stage_id).is_empty(), "%s maps to a boss phase definition" % stage_id)
		_expect(not BossPatterns.sequence(stage_id).is_empty(), "%s maps to boss patterns" % stage_id)
	_expect(BossPhases.validate_contract().is_empty(), "all eight boss phase packets validate")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_EIGHT_CYCLE_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
