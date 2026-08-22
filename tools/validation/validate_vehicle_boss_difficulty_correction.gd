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
	_expect(
		is_equal_approx(BossPatterns.startup_seconds("heated_fan", 0), 0.18)
			and is_equal_approx(
				BossPatterns.startup_seconds("common_broad_barrage", 0),
				0.22
			),
		"rapid boss projectiles and the broad barrage use their absolute commitment caps"
	)
	_expect(is_equal_approx(BossPatterns.active_seconds("focused_beam", 7), 0.688), "stage 8 attack duration is absolute")
	_expect(is_equal_approx(BossPatterns.recovery_seconds("resonance_break", 10), 0.36), "stage 11 recovery is absolute")
	_expect(
		Array(BossProfiles.profile(0)["read_gaps"]) == [0.2412, 0.1809, 0.14472]
			and Array(BossProfiles.profile(1)["read_gaps"]) == [0.234, 0.1755, 0.1404]
			and Array(BossProfiles.profile(2)["read_gaps"]) == [0.2268, 0.1701, 0.13608],
		"bosses 1-3 use only the exact ten-percent read-gap reduction"
	)
	var stage_11 := BossProfiles.profile(10)
	_expect(
		is_equal_approx(float(stage_11["health"]), 122300.0)
			and is_equal_approx(float(stage_11["move_speed"]), 540.0)
			and is_equal_approx(float(stage_11["attack_move_speed"]), 432.0)
			and is_equal_approx(float(stage_11["initial_autonomous_delay"]), 2.0)
			and Array(stage_11["autonomous_intervals"]) == [2.75, 2.30, 1.95]
			and is_equal_approx(float(BossPatterns.COMMON_DAMAGE_SCALES[10]), 1.66),
		"stage 11 keeps health while using the calmer exact pressure profile"
	)
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
