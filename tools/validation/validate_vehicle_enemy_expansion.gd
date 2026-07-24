extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const EliteTraits = preload("res://scripts/enemies/vehicle_elite_trait_catalog.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const Stages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

var _failures: Array[String] = []


func _init() -> void:
	_expect(Archetypes.DEFINITIONS.has(&"bulkhead_guard"), "Bulkhead Guard is registered")
	_expect(Archetypes.DEFINITIONS.has(&"splitter_barge"), "Splitter Barge is registered")
	_expect(&"spark_minelet" in Stages.MOBILE_ROLES[1], "Spark Minelet starts in Stage 2")
	_expect(&"bulkhead_guard" in Stages.MOBILE_ROLES[2], "Bulkhead Guard starts in Stage 3")
	_expect(&"splitter_barge" in Stages.MOBILE_ROLES[4], "Splitter Barge starts in Stage 5")
	for stage_index in 5:
		_expect(
			EliteTraits.thresholds(stage_index).size() == stage_index + 1,
			"Stage %d has an exact elite reservation schedule" % (stage_index + 1)
		)
		var roles: Array = Stages.MOBILE_ROLES[stage_index]
		var projectile_roles := 0
		for archetype in roles:
			if Archetypes.fires_projectiles(StringName(archetype)):
				projectile_roles += 1
		_expect(
			float(projectile_roles) / float(roles.size()) <= 0.5,
			"Stage %d keeps ordinary projectile roles at or below half" % (stage_index + 1)
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
			and is_equal_approx(heavy.speed, 90.0),
		"Heavy applies its fixed health, footprint, and speed multipliers"
	)
	_finish()


func _enemy() -> EnemyState:
	var enemy := EnemyState.new()
	enemy.health = 100.0
	enemy.max_health = 100.0
	enemy.speed = 100.0
	enemy.radius = 20.0
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
