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
	for number in range(1, 13):
		ids.append(StringName("stage_%d" % number))
	_expect(CombatStages.STAGE_IDS == ids, "the canonical registry contains twelve internal cycle IDs")
	_expect(CombatStages.QUOTAS == [90, 99, 108, 117, 126, 135, 144, 153, 162, 171, 180, 189], "quota progression is exactly 1.5x the previous sequence")
	_expect(CombatStages.AUTHORED_COUNTS == [260, 300, 340, 390, 440, 500, 560, 630, 700, 770, 840, 910], "authored populations are exact")
	for index in ids.size():
		var stage_id := ids[index]
		var profile := CombatStages.profile(stage_id)
		_expect(not profile.is_empty(), "%s has a profile" % stage_id)
		_expect(bool(profile["has_boss"]), "%s has its quota-gated boss" % stage_id)
		_expect(not CombatStages.MOBILE_ROLES[index].is_empty(), "%s has an ordinary-enemy role arc" % stage_id)
		_expect(not Elites.thresholds(index).is_empty(), "%s has an explicit elite schedule" % stage_id)
		_expect(not Tactics.assignment_for(index, 0, 3, 4).is_empty(), "%s has a tactic mapping" % stage_id)
	_expect(CombatStages.normalized_id(&"stage_13").is_empty(), "unknown stage IDs fail closed")
	_expect(StageCatalog.definition(&"stage_13").is_empty(), "catalog lookup fails closed")
	_expect(Difficulty.multipliers(12).is_empty(), "difficulty lookup fails closed")
	_expect(Difficulty.stage_index_from_id(&"stage_13") == -1, "unknown difficulty ID fails closed")
	_expect(Difficulty.HEALTH.size() == 12 and is_equal_approx(float(Difficulty.HEALTH[11]), 2.00), "cycle 12 has the final ordinary base health scale")
	_expect(is_equal_approx(Difficulty.boss_health(11), 91260.0), "cycle 12 has the final boss health")
	var expected_profiles: Array[StringName] = ids.duplicate()
	for boss_index in expected_profiles.size():
		var stage_id := ids[boss_index]
		_expect(CombatStages.boss_profile_id(stage_id) == expected_profiles[boss_index], "%s maps to its preserved boss arc" % stage_id)
		_expect(not BossPhases.definition(stage_id).is_empty(), "%s maps to a boss phase definition" % stage_id)
		_expect(not BossPatterns.sequence(stage_id).is_empty(), "%s maps to boss patterns" % stage_id)
	_expect(BossPhases.validate_contract().is_empty(), "all twelve boss phase packets validate")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_TWELVE_CYCLE_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
