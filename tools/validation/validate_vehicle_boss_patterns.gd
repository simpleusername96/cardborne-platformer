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
			if Patterns.damage(pattern) > 0.0:
				_expect(
					Patterns.affinity(pattern) != AttackContract.SUPPORT,
					"%s does not present damage as support" % pattern
				)
			if Patterns.kind(pattern) in [&"lanes", &"fan", &"cross"]:
				_expect(Patterns.volley_interval(pattern) > 0.0 and Patterns.volley_limit(pattern, false) >= 3, "%s repeats aimed projectile volleys" % pattern)
				_expect(Patterns.volley_limit(pattern, true) > Patterns.volley_limit(pattern, false), "%s adds one phase-two volley" % pattern)
			if (
				Patterns.damage(pattern) > 0.0
				and Patterns.kind(pattern) in [&"area", &"pylons", &"summon"]
			):
				_expect(
					Patterns.startup_seconds(pattern) * PLAYER_BASE_SPEED
						>= Patterns.radius(pattern)
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
		var base_health: float = [1250.0, 1350.0, 1450.0, 1550.0, 1650.0][stage_index]
		_expect(
			is_equal_approx(
				Difficulty.boss_health(stage_index),
				base_health * Difficulty.BOSS_HEALTH_MULTIPLIER
			),
			"%s applies the dedicated 30 percent boss-health increase" % stage_id
		)
	_expect(
		is_equal_approx(Difficulty.BOSS_HEALTH_MULTIPLIER, 1.30),
		"boss health multiplier remains 1.30"
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
