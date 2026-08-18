extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const GuidebookStats = preload("res://scripts/progression/vehicle_guidebook_stat_adapter.gd")

const EXPECTED_BOSS_HEALTH := [16900.0, 21300.0, 28300.0, 36800.0, 46700.0, 57500.0, 69200.0, 81600.0, 94600.0, 108200.0, 122300.0, 136890.0]
const EXPECTED_TIME_SCALES := [1.00, 0.98, 0.96, 0.94, 0.92, 0.90, 0.88, 0.86, 0.85, 0.84, 0.83, 0.82]
const EXPECTED_MOVE_SCALES := [0.62, 0.64, 0.66, 0.68, 0.70, 0.72, 0.74, 0.76, 0.78, 0.80, 0.81, 0.82]

var failures: Array[String] = []


func _initialize() -> void:
	_expect(Difficulty.BOSS_MAX_HEALTH == EXPECTED_BOSS_HEALTH, "boss maximum health uses the direct authored curve")
	_expect(Difficulty.BOSS_ATTACK_TIME_SCALES == EXPECTED_TIME_SCALES, "boss startup and active time use the authored curve")
	_expect(Difficulty.BOSS_ATTACK_MOVE_SCALES == EXPECTED_MOVE_SCALES, "boss attack movement uses the authored curve")
	for index in EXPECTED_BOSS_HEALTH.size():
		_expect(is_equal_approx(Difficulty.boss_health(index), EXPECTED_BOSS_HEALTH[index]), "stage %d boss health is exact" % (index + 1))
		if index > 0:
			_expect(Difficulty.boss_health(index) > Difficulty.boss_health(index - 1), "boss health increases at stage %d" % (index + 1))
		_expect(BossPatterns.scaled_startup_seconds("heated_fan", index) >= Difficulty.MIN_BOSS_STARTUP_SECONDS, "stage %d startup keeps its fairness floor" % (index + 1))
		_expect(BossPatterns.scaled_active_seconds("thermal_ring", index) >= Difficulty.MIN_BOSS_ACTIVE_SECONDS, "stage %d active window keeps its fairness floor" % (index + 1))
	_expect(is_equal_approx(BossPatterns.scaled_startup_seconds("heated_fan", 11), 0.697), "stage 12 scales authored startup")
	_expect(is_equal_approx(BossPatterns.scaled_active_seconds("focused_beam", 11), 0.656), "stage 12 scales authored active time")

	var role: StringName = &"ordinary_melee_01"
	var definition := Archetypes.definition(role)
	var base_health := float(definition["health"])
	for stage_index in [0, 11]:
		var rows := GuidebookStats.enemy_rows(role, {"active_stage_index":stage_index})
		var expected := roundi(
			base_health
			* EncounterDirector.ENEMY_HEALTH_MULTIPLIER
			* Difficulty.ordinary_health_multiplier(stage_index)
			* Difficulty.ORDINARY_HEALTH_MULTIPLIER
			* Difficulty.ORDINARY_DURABILITY_MULTIPLIER
		)
		_expect(not rows.is_empty() and int(rows[0]["value_args"][0]) == expected, "Guidebook publishes final effective ordinary HP for stage %d" % (stage_index + 1))
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_DIFFICULTY_CORRECTION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
