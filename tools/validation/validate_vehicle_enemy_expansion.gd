extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const EliteTraits = preload("res://scripts/enemies/vehicle_elite_trait_catalog.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const Stages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

var _failures: Array[String] = []


func _init() -> void:
	_expect(Archetypes.DEFINITIONS.has(&"ordinary_shield_01"), "Shield Ordinary Enemy Lv.1 is registered")
	_expect(Archetypes.DEFINITIONS.has(&"ordinary_pulse_01"), "Pulse Ordinary Enemy Lv.1 is registered")
	for specialist in [&"ordinary_beam_01", &"ordinary_range_01", &"ordinary_sweep_01", &"ordinary_melee_02"]:
		_expect(Archetypes.DEFINITIONS.has(specialist), "%s is registered" % specialist)
	_expect(
		Archetypes.fires_projectiles(&"ordinary_beam_01")
			and Archetypes.fires_projectiles(&"ordinary_range_01")
			and not Archetypes.fires_projectiles(&"ordinary_sweep_01"),
		"ordinary firing roles distinguish direct bolts from delayed ground blasts"
	)
	_expect(&"ordinary_area_01" in Stages.MOBILE_ROLES[0], "Stage 1 includes its boss-intro ordinary role")
	_expect(&"ordinary_shield_01" in Stages.MOBILE_ROLES[2], "Stage 3 introduces its shield tutor")
	_expect(&"ordinary_pulse_01" in Stages.MOBILE_ROLES[7], "Stage 8 introduces its pulse tutor")
	for stage_index in Stages.MOBILE_ROLES.size():
		_expect(
			EliteTraits.thresholds(stage_index).size() == mini(stage_index / 2 + 1, 6),
			"Stage %d has an exact elite reservation schedule" % (stage_index + 1)
		)
		var roles: Array = Stages.MOBILE_ROLES[stage_index]
		_expect(
			roles.size() == 3 and roles[2] == Stages.BOSS_TUTOR_ROLES[stage_index],
			"Stage %d keeps a three-role roster ending in its boss tutor" % (stage_index + 1)
		)
		if stage_index > 0:
			_expect(
				roles[0] == Stages.MOBILE_ROLES[stage_index - 1][1]
					and roles[1] == Stages.MOBILE_ROLES[stage_index - 1][2],
				"Stage %d retires only the oldest role" % (stage_index + 1)
			)
	var armored := _enemy()
	EliteTraits.apply(armored, &"armored")
	_expect(armored.armor_structure == 72.0, "Armored shell remains fixed at 72 structure")
	var overclocked := _enemy()
	EliteTraits.apply(overclocked, &"overclocked")
	_expect(
		is_equal_approx(overclocked.speed, 115.0),
		"Overclocked changes speed without adding a projectile"
	)
	var heavy := _enemy()
	EliteTraits.apply(heavy, &"heavy")
	_expect(
		is_equal_approx(heavy.health, 135.0)
			and is_equal_approx(heavy.radius, 23.0)
			and is_equal_approx(heavy.projectile_hit_radius, 34.5)
			and is_equal_approx(heavy.speed, 90.0),
		"Heavy applies its fixed health, movement, projectile-hit, and speed multipliers"
	)
	_finish()


func _enemy() -> EnemyState:
	var enemy := EnemyState.new()
	enemy.health = 100.0
	enemy.max_health = 100.0
	enemy.speed = 100.0
	enemy.radius = 20.0
	enemy.projectile_hit_radius = 30.0
	enemy.visual_radius = 30.0
	return enemy


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_ENEMY_EXPANSION_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
