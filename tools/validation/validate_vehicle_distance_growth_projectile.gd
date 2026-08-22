extends SceneTree

const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var projectile := ProjectileState.new()
	projectile.configure(_spec(ProjectileState.DISTANCE_GROWTH_GROWTH_KIND), &"enemy", 1, true)
	_expect(
		is_equal_approx(projectile.velocity.length(), 1000.0)
			and is_equal_approx(projectile.radius, 10.0)
			and is_equal_approx(projectile.damage, 20.0)
			and not projectile.distance_growth_proximity_armed,
		"Stage 6 ammunition starts with ordinary projectile speed, size, and damage"
	)
	projectile.advance_distance_growth(ProjectileState.DISTANCE_GROWTH_ARM_DISTANCE)
	_expect(
		is_zero_approx(projectile.distance_growth_ratio)
			and is_equal_approx(projectile.velocity.length(), 1000.0)
			and not projectile.distance_growth_proximity_armed,
		"distance growth begins at 360 units without a launch-speed penalty"
	)
	projectile.advance_distance_growth(
		(ProjectileState.DISTANCE_GROWTH_CAP_DISTANCE - ProjectileState.DISTANCE_GROWTH_ARM_DISTANCE) * 0.5
	)
	_expect(
		is_equal_approx(projectile.distance_growth_ratio, 0.5)
			and is_equal_approx(projectile.velocity.length(), 1175.0)
			and is_equal_approx(projectile.radius, 12.5)
			and is_equal_approx(projectile.damage, 26.0),
		"Stage 6 ammunition grows speed, size, and damage monotonically"
	)
	_expect(
		not projectile.can_proximity_detonate(Vector2(80.0, 0.0)),
		"proximity detonation remains disabled before 720 traveled units"
	)
	projectile.advance_distance_growth(
		ProjectileState.DISTANCE_GROWTH_PROXIMITY_ARM_DISTANCE
			- projectile.distance_traveled
	)
	_expect(
		projectile.distance_growth_proximity_armed
			and projectile.can_proximity_detonate(Vector2(80.0, 0.0))
			and projectile.can_proximity_detonate_on_segment(
				Vector2(-200.0, 0.0), Vector2(200.0, 0.0), Vector2.ZERO
			),
		"armed Stage 6 ammunition detects the player without direct body contact"
	)
	_expect(
		projectile.consume_distance_growth_detonation()
			and not projectile.consume_distance_growth_detonation()
			and not projectile.can_proximity_detonate(Vector2.ZERO),
		"one Stage 6 projectile exposes exactly one detonation damage path"
	)
	projectile.advance_distance_growth(9999.0)
	_expect(
		is_equal_approx(projectile.distance_growth_ratio, 1.0)
			and is_equal_approx(projectile.velocity.length(), 1350.0)
			and is_equal_approx(projectile.radius, 15.0)
			and is_equal_approx(projectile.damage, 32.0),
		"Stage 6 ammunition hard-caps all growth at 880 traveled units"
	)
	projectile.configure(_spec(&""), &"enemy", 2, false)
	_expect(
		projectile.distance_growth_kind.is_empty()
			and is_zero_approx(projectile.distance_traveled)
			and is_zero_approx(projectile.distance_growth_ratio)
			and not projectile.distance_growth_proximity_armed
			and not projectile.distance_growth_detonated
			and is_equal_approx(projectile.velocity.length(), 1000.0)
			and is_equal_approx(projectile.radius, 10.0)
			and is_equal_approx(projectile.damage, 20.0),
		"pooled state resets every Stage 6-only field before ordinary reuse"
	)
	var store := ProjectileStore.new()
	_expect(store.add_hostile(_spec(ProjectileState.DISTANCE_GROWTH_GROWTH_KIND), true), "store admits one boss-reserved distance-growth projectile")
	store.remove_hostile_at_swap(0)
	_expect(store.add_hostile(_spec(&""), false), "retired Stage 6 state can be reused by an ordinary projectile")
	_expect(
		store.hostile_live[0].distance_growth_kind.is_empty()
			and not store.hostile_live[0].distance_growth_proximity_armed,
		"store reuse cannot leak Stage 6 proximity behavior"
	)
	var run_source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	var renderer_source := FileAccess.get_file_as_string("res://scripts/presentation/vehicle_combat_renderer.gd")
	_expect(
		run_source.contains("_detonate_distance_growth_projectile")
			and run_source.contains("AttackContract.relative_sweep_first_t")
			and run_source.contains("DISTANCE_GROWTH_PROXIMITY_TRIGGER_RADIUS")
			and run_source.contains("_spawn_boss_long_banks"),
		"the authored Stage 6 path owns growth, relative proximity collision, and retirement"
	)
	_expect(
		not renderer_source.contains("trail_length")
			and renderer_source.contains("distance_growth_proximity_armed"),
		"Stage 6 projectiles use an armed-state ring without the false beam-like trail"
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
		print("VEHICLE_DISTANCE_GROWTH_PROJECTILE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
