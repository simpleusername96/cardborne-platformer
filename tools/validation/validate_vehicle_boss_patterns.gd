extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const PLAYER_BASE_SPEED := 280.0

var failures: Array[String] = []


func _initialize() -> void:
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		var phase_one := Patterns.sequence(stage_id, false)
		var phase_two := Patterns.sequence(stage_id, true)
		var phase_three := Patterns.sequence(stage_id, 3)
		_expect(phase_one.size() == 4 and phase_one.duplicate().all(func(pattern): return phase_one.count(pattern) == 1), "%s has four distinct attacks" % stage_id)
		_expect(phase_two.size() == 4 and phase_two != phase_one, "%s changes order in phase two" % stage_id)
		_expect(phase_three.size() == 4 and phase_three != phase_two, "%s has an authored phase-three order" % stage_id)
		for pattern in phase_one:
			_expect(Patterns.startup_seconds(pattern) >= 0.8, "%s startup is visible" % pattern)
			_expect(Patterns.active_seconds(pattern) >= 0.4, "%s active window is explicit" % pattern)
			_expect(Patterns.recovery_seconds(pattern) >= 0.9, "%s recovery is explicit" % pattern)
			_expect(
				Patterns.affinity(pattern) in AttackContract.AFFINITIES,
				"%s declares a supported attack affinity" % pattern
			)
			_expect(
				Patterns.commit_mode(pattern) == &"committed",
				"%s is a committed direct attack" % pattern
			)
			if Patterns.damage(pattern, stage_index) > 0.0:
				_expect(
					Patterns.affinity(pattern) != AttackContract.SUPPORT,
					"%s does not present damage as support" % pattern
				)
			if Patterns.kind(pattern) in [&"lanes", &"fan", &"cross"]:
				_expect(Patterns.volley_interval(pattern) > 0.0 and Patterns.volley_limit(pattern, false) >= 3, "%s repeats aimed projectile volleys" % pattern)
				_expect(Patterns.volley_limit(pattern, true) > Patterns.volley_limit(pattern, false), "%s adds one phase-two volley" % pattern)
			if (
				Patterns.damage(pattern, stage_index) > 0.0
				and Patterns.kind(pattern) in [&"area", &"pylons", &"summon"]
			):
				_expect(
					Patterns.startup_seconds(pattern) * PLAYER_BASE_SPEED
						>= Patterns.radius(pattern, stage_index)
							+ Patterns.MIN_BASE_WALK_ESCAPE_MARGIN,
					"%s can be escaped from its center with ordinary movement" % pattern
				)
		var autonomous := Patterns.autonomous_sequence(stage_id)
		_expect(autonomous.size() == 2, "%s owns two bounded autonomous systems" % stage_id)
		for pattern in autonomous:
			_expect(
				Patterns.commit_mode(pattern) == &"autonomous",
				"%s remains independent of boss-body state" % pattern
			)
			_expect(
				Patterns.kind(pattern) in [&"area", &"lanes", &"beam", &"summon"],
				"%s has an explicitly dispatched autonomous shape" % pattern
			)
			if Patterns.kind(pattern) == &"area" and Patterns.damage(pattern, stage_index) > 0.0:
				_expect(
					Patterns.startup_seconds(pattern) * PLAYER_BASE_SPEED
						>= Patterns.radius(pattern, stage_index)
							+ Patterns.MIN_BASE_WALK_ESCAPE_MARGIN,
					"%s scaled autonomous area keeps its walk-escape margin" % pattern
				)
		var base_health: float = Difficulty.BOSS_BASE_HEALTH[stage_index]
		_expect(
			is_equal_approx(
				Difficulty.boss_health(stage_index),
				base_health * Difficulty.BOSS_HEALTH_MULTIPLIERS[stage_index]
			),
			"%s applies its exact boss-health profile" % stage_id
		)
	_expect(
		Difficulty.BOSS_HEALTH_MULTIPLIERS == [4.20, 4.30, 4.40, 4.50, 4.60]
			and Difficulty.BOSS_DAMAGE_MULTIPLIERS == [1.50, 1.60, 1.70, 1.80, 1.90]
			and Difficulty.BOSS_SHIELDED_DAMAGE_MULTIPLIERS == [0.110, 0.105, 0.100, 0.095, 0.090]
			and Difficulty.BOSS_CADENCE_SCALES == [0.95, 0.90, 0.85, 0.80, 0.75]
			and Difficulty.BOSS_COVERAGE_SCALES == [1.05, 1.10, 1.15, 1.20, 1.25],
		"boss profile exposes the accepted aligned five-stage curves"
	)
	_expect(
		is_equal_approx(
				float(Patterns.definition("furnace_gates")["damage"]), 22.0
			)
			and is_equal_approx(Patterns.damage("furnace_gates", 0), 33.0)
			and is_equal_approx(Patterns.damage("furnace_gates", 4), 41.8)
			and is_equal_approx(Patterns.damage("breaker_charge", 4), 68.4),
		"boss patterns preserve authored base damage and apply the stage-owned multiplier"
	)
	_expect(
		is_equal_approx(Patterns.radius("furnace_ring", 0), 241.5)
			and is_equal_approx(Patterns.radius("archive_depth", 1), 203.5)
			and is_equal_approx(Patterns.radius("titan_pulse", 2), 270.25)
			and is_equal_approx(Patterns.radius("gate_shockwave", 3), 288.0)
			and is_equal_approx(Patterns.width("switch_sweep", 3), 93.6)
			and is_equal_approx(Patterns.width("crown_beam", 4), 102.5)
			and is_equal_approx(Patterns.radius("relay_pulse_rings", 4), 281.25),
		"representative boss attacks apply exact stage coverage"
	)
	for stage_index in 4:
		_expect(
			Difficulty.boss_health(stage_index + 1) > Difficulty.boss_health(stage_index)
				and Difficulty.boss_damage_multiplier(stage_index + 1)
					>= Difficulty.boss_damage_multiplier(stage_index)
				and Difficulty.boss_shielded_damage_multiplier(stage_index + 1)
					<= Difficulty.boss_shielded_damage_multiplier(stage_index)
				and Difficulty.boss_cadence_scale(stage_index + 1)
					<= Difficulty.boss_cadence_scale(stage_index)
				and Difficulty.boss_coverage_scale(stage_index + 1)
					>= Difficulty.boss_coverage_scale(stage_index),
			"Stage %d to %d strengthens every declared boss-profile axis"
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
		Patterns.affinity("furnace_gates") == AttackContract.THERMAL
			and Patterns.affinity("foundry_ram") == AttackContract.KINETIC
			and Patterns.affinity("furnace_ring") == AttackContract.THERMAL
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
