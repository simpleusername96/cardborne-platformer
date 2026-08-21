extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const PLAYER_BASE_SPEED := 280.0

var failures: Array[String] = []


func _initialize() -> void:
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		if not Catalog.has_boss(stage_id):
			_expect(
				Patterns.sequence(stage_id, false).is_empty()
					and Patterns.autonomous_sequence(stage_id).is_empty(),
				"%s fails closed without boss patterns" % stage_id
			)
			continue
		var phase_one := Patterns.sequence(stage_id, false)
		var phase_two := Patterns.sequence(stage_id, true)
		var phase_three := Patterns.sequence(stage_id, 3)
		_expect(
			phase_one.size() == 5
				and phase_one.duplicate().all(func(pattern): return phase_one.count(pattern) == 1)
				and (
					("common_charge" in phase_one and "common_broad_barrage" in phase_one)
					if stage_index < 8
					else ("common_charge" not in phase_one and "common_broad_barrage" not in phase_one)
				),
			"%s has five distinct attacks with the correct common-pattern policy" % stage_id
		)
		_expect(phase_two.size() == 5 and phase_two != phase_one, "%s changes order in phase two" % stage_id)
		_expect(phase_three.size() == 5 and phase_three != phase_two, "%s has an authored phase-three order" % stage_id)
		for pattern in phase_one:
			_expect(
				not Patterns.behavior_family(pattern).is_empty(),
				"%s resolves a canonical behavior family" % pattern
			)
			_expect(Patterns.startup_seconds(pattern, stage_index) >= 0.65, "%s startup is visible" % pattern)
			_expect(Patterns.active_seconds(pattern, stage_index) >= 0.4, "%s active window is explicit" % pattern)
			_expect(
				Patterns.recovery_seconds(pattern, stage_index) > 0.0
					or Patterns.commit_mode(pattern) == &"autonomous",
				"%s recovery or autonomous ownership is explicit" % pattern
			)
			_expect(
				Patterns.affinity(pattern) in AttackContract.AFFINITIES,
				"%s declares a supported attack affinity" % pattern
			)
			_expect(Patterns.commit_mode(pattern) in [&"committed", &"autonomous"], "%s declares execution ownership" % pattern)
			if Patterns.damage(pattern, stage_index) > 0.0:
				_expect(
					Patterns.affinity(pattern) != AttackContract.SUPPORT,
					"%s does not present damage as support" % pattern
				)
			if Patterns.kind(pattern) in [&"lanes", &"fan", &"cross"]:
				_expect(Patterns.volley_interval(pattern) > 0.0 and Patterns.volley_limit(pattern, false) >= 3, "%s repeats aimed projectile volleys" % pattern)
				_expect(Patterns.volley_limit(pattern, true) > Patterns.volley_limit(pattern, false), "%s adds one phase-two volley" % pattern)
			if (
				stage_index < 8
				and
				Patterns.damage(pattern, stage_index) > 0.0
				and Patterns.kind(pattern) in [&"area", &"pylons", &"summon"]
			):
				_expect(
					Patterns.startup_seconds(pattern, stage_index) * PLAYER_BASE_SPEED
						>= Patterns.radius(pattern, stage_index)
							+ Patterns.MIN_BASE_WALK_ESCAPE_MARGIN,
					"%s can be escaped from its center with ordinary movement" % pattern
				)
		var autonomous := Patterns.autonomous_sequence(stage_id)
		_expect(autonomous.size() == 2, "%s owns two bounded autonomous systems" % stage_id)
		for pattern in autonomous:
			_expect(
				not Patterns.behavior_family(pattern).is_empty(),
				"%s autonomous selection resolves a canonical behavior family" % pattern
			)
			if stage_index >= 8:
				continue
			_expect(
				Patterns.commit_mode(pattern) == &"autonomous",
				"%s remains independent of boss-body state" % pattern
			)
			_expect(
				Patterns.kind(pattern) in [&"area", &"lanes", &"beam", &"summon", &"long_banks", &"crossing_weave", &"radial_volley"],
				"%s has an explicitly dispatched autonomous shape" % pattern
			)
			if Patterns.kind(pattern) == &"area" and Patterns.damage(pattern, stage_index) > 0.0:
				_expect(
					Patterns.startup_seconds(pattern, stage_index) * PLAYER_BASE_SPEED
						>= Patterns.radius(pattern, stage_index)
							+ Patterns.MIN_BASE_WALK_ESCAPE_MARGIN,
					"%s scaled autonomous area keeps its walk-escape margin" % pattern
				)
		_expect(
			is_equal_approx(Difficulty.boss_health(stage_index), BossProfiles.health(stage_index)),
			"%s reads its independently authored health" % stage_id
		)
	_expect(
		Patterns.sequence(&"stage_7").count("crossing_weave_a") == 1
			and Patterns.sequence(&"stage_7").count("crossing_weave_b") == 1
			and "cross_beam" not in Patterns.sequence(&"stage_7"),
		"Stage 7 Boss owns two crossing-weave identity selections without Cross Beam"
	)
	_expect(
		Patterns.sequence(&"stage_8").count("radial_volley_a") == 1
			and Patterns.sequence(&"stage_8").count("radial_volley_b") == 1
			and "mirror_cross" not in Patterns.sequence(&"stage_8"),
		"Stage 8 Boss owns two projectile-only radial-volley selections without Mirror Cross"
	)
	_expect(
		Patterns.behavior_family("reflect_fan") == &"fan_volley"
			and Patterns.behavior_family("resonance_fan") == &"fan_volley"
			and Patterns.behavior_family("ricochet_volley") == &"fan_volley"
			and Patterns.is_shared_behavior("reflect_fan"),
		"differently named fan aliases resolve to one shared behavior"
	)
	_expect(
		Patterns.behavior_family("reflect_lance") == &"emitted_beam"
			and Patterns.behavior_family("focused_beam") == &"emitted_beam"
			and Patterns.is_shared_behavior("reflect_lance"),
		"differently named emitted beams resolve to one shared behavior"
	)
	_expect(
		Patterns.behavior_family("switch_sweep") == &"sequential_beam_sweep"
			and not Patterns.is_shared_behavior("switch_sweep"),
		"Stage 4 sequential sweep is a real signature behavior, not a beam alias"
	)
	_expect(
		not Patterns.is_shared_behavior("crossing_weave_a")
			and Patterns.stages_using_behavior(&"crossing_weave") == [&"stage_7"]
			and not Patterns.is_shared_behavior("radial_volley_a")
			and Patterns.stages_using_behavior(&"radial_volley") == [&"stage_8"],
		"single-stage execution families remain signature behaviors"
	)
	_expect(BossProfiles.PROFILES.size() == 12, "boss catalog exposes twelve independent profiles")
	_expect(
		is_equal_approx(Patterns.damage("thermal_gates", 0), 22.0)
			and is_equal_approx(Patterns.damage("reflect_lance", 9), 55.08)
			and is_equal_approx(Patterns.damage("overload_rush_return", 11), 74.76),
		"boss attacks expose independently authored damage"
	)
	_expect(
		is_equal_approx(Patterns.radius("thermal_ring", 0), 287.5)
			and is_equal_approx(Patterns.radius("depth_area", 1), 240.5)
			and is_equal_approx(Patterns.radius("gate_shockwave", 5), 360.0)
			and is_equal_approx(Patterns.width("switch_sweep", 3), 87.36)
			and is_equal_approx(Patterns.width("focused_beam", 7), 104.96)
			and is_equal_approx(Patterns.radius("resonance_pulse", 10), 385.25),
		"representative boss attacks expose exact authored coverage"
	)
	for stage_index in 11:
		_expect(
			BossProfiles.health(stage_index + 1) > BossProfiles.health(stage_index)
				and BossProfiles.move_speed(stage_index + 1) > BossProfiles.move_speed(stage_index),
			"Stage %d to %d uses stronger independently authored core stats"
				% [stage_index + 1, stage_index + 2]
		)
	_expect(
		is_equal_approx(EncounterDirector.effective_hostile_projectile_speed(500.0), 410.0),
		"boss prediction and projectile motion share the reduced hostile speed contract"
	)
	_expect(
		Patterns.AREA_TARGET_MAX_LEAD == 96.0,
		"boss circular attacks keep their committed center close to the player"
	)
	_expect(
		Patterns.affinity("thermal_gates") == AttackContract.THERMAL
			and Patterns.affinity("direct_charge") == AttackContract.KINETIC
			and Patterns.affinity("thermal_ring") == AttackContract.THERMAL
			and Patterns.affinity("forge_vent") == AttackContract.ARC,
		"stage-one boss patterns expose distinct thermal, kinetic, and arc families"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_PATTERNS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
