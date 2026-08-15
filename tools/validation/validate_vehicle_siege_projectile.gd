extends SceneTree

const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var projectile := ProjectileState.new()
	projectile.configure(_spec(ProjectileState.SIEGE_GROWTH_KIND), &"enemy", 1, true)
	_expect(
		is_equal_approx(projectile.velocity.length(), 750.0)
			and is_equal_approx(projectile.radius, 10.0)
			and is_equal_approx(projectile.damage, 20.0),
		"Siege ammunition starts slow and keeps base size and damage before arming"
	)
	projectile.advance_distance_growth(ProjectileState.SIEGE_ARM_DISTANCE)
	_expect(is_zero_approx(projectile.distance_growth_ratio), "Siege ammunition arms at exactly 360 traveled units")
	projectile.advance_distance_growth(
		(ProjectileState.SIEGE_CAP_DISTANCE - ProjectileState.SIEGE_ARM_DISTANCE) * 0.5
	)
	_expect(
		is_equal_approx(projectile.distance_growth_ratio, 0.5)
			and is_equal_approx(projectile.velocity.length(), 1050.0)
			and is_equal_approx(projectile.radius, 12.5)
			and is_equal_approx(projectile.damage, 26.0),
		"Siege ammunition interpolates speed, size, and damage monotonically"
	)
	projectile.advance_distance_growth(9999.0)
	_expect(
		is_equal_approx(projectile.distance_growth_ratio, 1.0)
			and is_equal_approx(projectile.velocity.length(), 1350.0)
			and is_equal_approx(projectile.radius, 15.0)
			and is_equal_approx(projectile.damage, 32.0),
		"Siege ammunition hard-caps all growth at 880 traveled units"
	)
	projectile.configure(_spec(&""), &"enemy", 2, false)
	_expect(
		projectile.distance_growth_kind.is_empty()
			and is_zero_approx(projectile.distance_traveled)
			and is_zero_approx(projectile.distance_growth_ratio)
			and is_equal_approx(projectile.velocity.length(), 1000.0)
			and is_equal_approx(projectile.radius, 10.0)
			and is_equal_approx(projectile.damage, 20.0),
		"pooled state resets every Siege-only field before ordinary reuse"
	)
	var store := ProjectileStore.new()
	_expect(store.add_hostile(_spec(ProjectileState.SIEGE_GROWTH_KIND), true), "store admits one boss-reserved Siege projectile")
	store.remove_hostile_at_swap(0)
	_expect(store.add_hostile(_spec(&""), false), "retired Siege state can be reused by an ordinary projectile")
	_expect(store.hostile_live[0].distance_growth_kind.is_empty(), "store reuse cannot leak Siege behavior")
	var run_source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	_expect(
		run_source.contains("ProjectileState.SIEGE_GROWTH_KIND")
			and run_source.contains("_spawn_boss_long_banks")
			and run_source.contains("advance_distance_growth"),
		"only the authored Siege Battery path opts into distance growth"
	)
	_finish()


func _spec(kind: StringName) -> Dictionary:
	return {
		"pos":Vector2.ZERO,
		"velocity":Vector2.RIGHT * 1000.0,
		"radius":10.0,
		"damage":20.0,
		"life":4.0,
		"distance_growth_kind":kind,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SIEGE_PROJECTILE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
