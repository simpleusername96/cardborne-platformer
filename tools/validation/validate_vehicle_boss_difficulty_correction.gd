extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const GuidebookStats = preload("res://scripts/progression/vehicle_guidebook_stat_adapter.gd")

const EXPECTED_BOSS_HEALTH := [16900.0, 21300.0, 28300.0, 36800.0, 46700.0, 57500.0, 69200.0, 81600.0, 94600.0, 108200.0, 122300.0, 136890.0]

var failures: Array[String] = []


func _initialize() -> void:
	_expect(BossProfiles.PROFILES.size() == 12, "boss catalog owns twelve independent profiles")
	for index in EXPECTED_BOSS_HEALTH.size():
		var profile := BossProfiles.profile(index)
		_expect(is_equal_approx(float(profile["health"]), EXPECTED_BOSS_HEALTH[index]), "stage %d boss health is exact" % (index + 1))
		if index > 0:
			_expect(float(profile["health"]) > float(BossProfiles.profile(index - 1)["health"]), "boss health increases at stage %d" % (index + 1))
		_expect(float(profile["move_speed"]) > 0.0 and float(profile["attack_move_speed"]) > 0.0, "stage %d owns absolute movement speeds" % (index + 1))
		_expect(Array(profile["read_gaps"]).size() == 3 and Array(profile["autonomous_intervals"]).size() == 3, "stage %d owns absolute cadence values" % (index + 1))
	_expect(is_equal_approx(BossPatterns.startup_seconds("heated_fan", 0), 0.85), "stage 1 attack startup is absolute")
	_expect(is_equal_approx(BossPatterns.active_seconds("focused_beam", 7), 0.688), "stage 8 attack duration is absolute")
	_expect(is_equal_approx(BossPatterns.recovery_seconds("resonance_break", 10), 0.36), "stage 11 recovery is absolute")
	_expect(is_equal_approx(BossProfiles.attack_move_speed(11), 455.1), "stage 12 active movement is absolute")

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
