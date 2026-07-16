extends SceneTree

const SHOOTER_SCENE_PATH := "res://scenes/enemies/ShooterRuin.tscn"
const SHOOTER_SCRIPT_PATH := "res://scripts/enemies/ShooterEnemy.gd"
const EXPECTED_WARNING := 0.42
const EXPECTED_RECOVERY := 0.5
const EXPECTED_INTERVAL := 2.0
const EXPECTED_PROJECTILE_SPEED := 260.0
const EXPECTED_PROJECTILE_RANGE := 700.0
const EXPECTED_AIM_CUE_LENGTH := 96.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_validate_ai_has_no_content_id_branches()
	var first := await _run_deterministic_fixture("first")
	var second := await _run_deterministic_fixture("second")
	_expect(not first.is_empty(), "first Shooter fixture should complete")
	_expect(not second.is_empty(), "second Shooter fixture should complete")
	if not first.is_empty() and not second.is_empty():
		_expect(
			var_to_bytes(first) == var_to_bytes(second),
			"identical Shooter fixtures should produce byte-equivalent behavior"
		)
	await _validate_aim_interruption()
	await _validate_solid_cover()
	_finish()


func _run_deterministic_fixture(label: String) -> Dictionary:
	var packed_scene := load(SHOOTER_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "%s fixture should load ShooterRuin" % label)
	if packed_scene == null:
		return {}

	var world := Node2D.new()
	world.name = "ShooterFixture_%s" % label
	root.add_child(world)
	_add_floor(world)
	var player_marker := Node2D.new()
	player_marker.name = "PlayerMarker"
	player_marker.add_to_group("player")
	player_marker.position = Vector2(120.0, 72.0)
	world.add_child(player_marker)

	var shooter: Variant = packed_scene.instantiate()
	var valid_shooter := _is_shooter_instance(shooter)
	_expect(valid_shooter, "%s fixture should instantiate ShooterEnemy behavior" % label)
	if not valid_shooter:
		world.queue_free()
		await process_frame
		return {}
	shooter.position = Vector2(480.0, 100.0)
	world.add_child(shooter)
	await physics_frame
	await process_frame
	_validate_resolved_contract(shooter, label)
	# Normalize the clock after first-load script/resource work so both runs start alike.
	shooter.reset_enemy()

	var frame := 0
	var warning_frame := -1
	var shot_frame := -1
	var shot: Variant
	for _step in 120:
		await physics_frame
		await process_frame
		frame += 1
		var current_aim_line := shooter.get_node_or_null("AimWarning") as Line2D
		if warning_frame < 0 and current_aim_line != null and current_aim_line.visible:
			warning_frame = frame
			_expect(current_aim_line.visible, "%s warning line should be visible" % label)
			if current_aim_line.points.size() == 2:
				_expect(
					is_equal_approx(
						current_aim_line.points[1].length(), EXPECTED_AIM_CUE_LENGTH
					),
					"%s warning should be a local facing cue, not a full-range overlay" % label
				)
			else:
				_expect(false, "%s warning line should have a complete aim segment" % label)
			_expect(_find_projectile(world) == null, "%s warning must precede the shot" % label)
			# The projectile must keep the warned direction even if the target crosses over.
			player_marker.position = Vector2(760.0, 72.0)
		shot = _find_projectile(world)
		if shot != null:
			shot_frame = frame
			break

	_expect(warning_frame >= 0, "%s fixture should observe an aim warning" % label)
	_expect(shot != null, "%s fixture should observe a projectile" % label)
	_expect(shot_frame > warning_frame, "%s projectile should follow, not coincide with, its warning" % label)
	if shot == null:
		world.queue_free()
		await process_frame
		return {}

	var combat_snapshot: Dictionary = shooter.get_combat_snapshot()
	_expect(
		bool(combat_snapshot.get("recovery", false)),
		"%s Shooter should expose a post-shot punish window" % label
	)
	var aim_line := shooter.get_node_or_null("AimWarning") as Line2D
	_expect(aim_line != null and not aim_line.visible, "%s warning should end before recovery" % label)
	_expect(shot.velocity.x < 0.0, "%s projectile direction should stay locked through warning" % label)
	_expect(
		is_equal_approx(shot.velocity.length(), EXPECTED_PROJECTILE_SPEED),
		"%s projectile should use the pinned Ruin speed" % label
	)
	var expected_lifetime := EXPECTED_PROJECTILE_RANGE / EXPECTED_PROJECTILE_SPEED
	_expect(
		is_equal_approx(shot.lifetime, expected_lifetime),
		"%s projectile lifetime should be derived from its exact range and speed" % label
	)
	_expect(
		(shooter.get("_active_projectiles") as Array).size() <= shooter.max_active_projectiles,
		"%s active projectiles should remain capped" % label
	)

	player_marker.position = Vector2(2000.0, 72.0)
	var observed_velocity: Vector2 = shot.velocity
	var observed_lifetime: float = shot.lifetime
	var shot_start: Vector2 = shot.global_position
	var maximum_distance := 0.0
	var lifetime_steps := ceili((shot.lifetime + 0.5) * Engine.physics_ticks_per_second)
	for _step in lifetime_steps:
		if not is_instance_valid(shot):
			break
		maximum_distance = maxf(maximum_distance, shot_start.distance_to(shot.global_position))
		await physics_frame
		await process_frame
	_expect(not is_instance_valid(shot), "%s projectile should expire within its lifetime bound" % label)
	_expect(
		maximum_distance <= EXPECTED_PROJECTILE_RANGE + EXPECTED_PROJECTILE_SPEED / 30.0,
		"%s projectile should not travel materially beyond its range bound" % label
	)
	var range_bound_respected := (
		maximum_distance <= EXPECTED_PROJECTILE_RANGE + EXPECTED_PROJECTILE_SPEED / 30.0
	)

	var result := {
		"warning_preceded_shot": warning_frame >= 0 and shot_frame > warning_frame,
		"shot_velocity": observed_velocity,
		"shot_lifetime": observed_lifetime,
		"recovery_observed": bool(combat_snapshot.get("recovery", false)),
		"range_bound_respected": range_bound_respected,
	}
	world.queue_free()
	await process_frame
	return result


func _validate_resolved_contract(shooter: Variant, label: String) -> void:
	var spec: Variant = shooter.resolved_spec
	_expect(spec != null, "%s Shooter should consume a ResolvedEnemySpec" % label)
	if spec == null:
		return
	_expect(spec.archetype_id == &"shooter", "%s archetype should resolve" % label)
	_expect(spec.variant_id == &"shooter_ruin", "%s variant should resolve" % label)
	_expect(spec.health == 4 and spec.damage == 1, "%s health/damage should be exact" % label)
	_expect(spec.stagger_capacity == 40, "%s stagger capacity should be exact" % label)
	_expect(is_equal_approx(spec.warning_time, EXPECTED_WARNING), "%s warning should be exact" % label)
	_expect(is_equal_approx(spec.recovery_time, EXPECTED_RECOVERY), "%s recovery should be exact" % label)
	_expect(is_equal_approx(spec.cadence_time, EXPECTED_INTERVAL), "%s cadence should be exact" % label)
	_expect(
		is_equal_approx(spec.projectile_speed, EXPECTED_PROJECTILE_SPEED)
		and is_equal_approx(spec.attack_range, EXPECTED_PROJECTILE_RANGE)
		and spec.active_projectile_cap == 2,
		"%s ranged values should resolve from the immutable spec" % label
	)
	_expect(spec.drop_source_id == &"drop_shooter", "%s drop source should resolve" % label)
	_expect(is_equal_approx(shooter.warning_time, spec.warning_time), "%s AI should read spec warning" % label)
	_expect(is_equal_approx(shooter.recovery_time, spec.recovery_time), "%s AI should read spec recovery" % label)
	_expect(is_equal_approx(shooter.shoot_interval, spec.cadence_time), "%s AI should read spec cadence" % label)
	_expect(
		is_equal_approx(shooter.projectile_speed, spec.projectile_speed)
		and is_equal_approx(shooter.projectile_range, spec.attack_range)
		and shooter.max_active_projectiles == spec.active_projectile_cap,
		"%s AI should read spec projectile tuning" % label
	)

	var copied_stats: Dictionary = spec.get_exact_stats()
	copied_stats["health"] = 999
	var copied_tags: PackedStringArray = spec.tags
	copied_tags.append("fixture_mutation")
	_expect(spec.health == 4, "%s exact stat copies must not mutate the spec" % label)
	_expect(not spec.tags.has("fixture_mutation"), "%s tag copies must not mutate the spec" % label)
	var variant: Variant = shooter.enemy_catalog.get_variant_by_id(&"shooter_ruin")
	if variant != null:
		var original_warning: float = variant.warning_time
		variant.warning_time = 9.0
		_expect(
			is_equal_approx(spec.warning_time, EXPECTED_WARNING),
			"%s resolved values must not follow mutable source Resources" % label
		)
		variant.warning_time = original_warning


func _validate_aim_interruption() -> void:
	var packed_scene := load(SHOOTER_SCENE_PATH) as PackedScene
	if packed_scene == null:
		return
	var world := Node2D.new()
	root.add_child(world)
	_add_floor(world)
	var player_marker := Node2D.new()
	player_marker.add_to_group("player")
	player_marker.position = Vector2(120.0, 72.0)
	world.add_child(player_marker)
	var shooter: Variant = packed_scene.instantiate()
	var valid_shooter := _is_shooter_instance(shooter)
	_expect(valid_shooter, "interruption fixture should instantiate ShooterEnemy behavior")
	if not valid_shooter:
		world.queue_free()
		await process_frame
		return
	shooter.position = Vector2(480.0, 100.0)
	world.add_child(shooter)

	var observed_warning := false
	for _step in 60:
		await physics_frame
		await process_frame
		var aim_line := shooter.get_node_or_null("AimWarning") as Line2D
		if aim_line != null and aim_line.visible:
			observed_warning = true
			break
	_expect(observed_warning, "interruption fixture should reach the aiming state")
	if observed_warning:
		shooter.receive_damage(DamageInfo.new(1))
		await physics_frame
		await process_frame
		var snapshot: Dictionary = shooter.get_combat_snapshot()
		_expect(bool(snapshot.get("recovery", false)), "damage should interrupt aim into recovery")
		_expect(_find_projectile(world) == null, "interrupted aim should not emit a projectile")
	world.queue_free()
	await process_frame


func _validate_solid_cover() -> void:
	var packed_scene := load(SHOOTER_SCENE_PATH) as PackedScene
	if packed_scene == null:
		return
	var world := Node2D.new()
	world.name = "ShooterCoverFixture"
	root.add_child(world)
	_add_floor(world)
	var cover := StaticBody2D.new()
	cover.name = "SolidCover"
	cover.position = Vector2(300.0, 62.0)
	cover.collision_layer = 1
	cover.collision_mask = 0
	world.add_child(cover)
	var cover_shape := CollisionShape2D.new()
	var cover_rect := RectangleShape2D.new()
	cover_rect.size = Vector2(28.0, 124.0)
	cover_shape.shape = cover_rect
	cover.add_child(cover_shape)
	var player_marker := Node2D.new()
	player_marker.add_to_group("player")
	player_marker.position = Vector2(120.0, 72.0)
	world.add_child(player_marker)
	var shooter: Variant = packed_scene.instantiate()
	if not _is_shooter_instance(shooter):
		_expect(false, "solid-cover fixture should instantiate ShooterEnemy behavior")
		world.queue_free()
		await process_frame
		return
	shooter.position = Vector2(480.0, 100.0)
	world.add_child(shooter)
	var shot: EnemyProjectile
	for _frame in 100:
		await physics_frame
		await process_frame
		shot = _find_projectile(world) as EnemyProjectile
		if shot != null:
			break
	_expect(shot != null, "solid-cover fixture should observe a projectile")
	var terrain_contacts := [0]
	if shot != null:
		shot.terrain_hit.connect(
			func(_body: PhysicsBody2D) -> void:
				terrain_contacts[0] += 1
		)
		for _frame in 90:
			if not is_instance_valid(shot):
				break
			await physics_frame
			await process_frame
		_expect(not is_instance_valid(shot), "solid cover should terminate the projectile")
		_expect(terrain_contacts[0] == 1, "solid cover should report one terrain contact")
	world.queue_free()
	await process_frame


func _validate_ai_has_no_content_id_branches() -> void:
	var source := FileAccess.get_file_as_string(SHOOTER_SCRIPT_PATH)
	_expect(not source.is_empty(), "Shooter AI source should be readable")
	for forbidden_text in ["shooter_ruin", "ruin_approach", "variant_id", "stage_id"]:
		_expect(
			not source.contains(forbidden_text),
			"Shooter AI should not branch on content identifier '%s'" % forbidden_text
		)


func _is_shooter_instance(value: Variant) -> bool:
	if not value is CharacterBody2D:
		return false
	var script := value.get_script() as Script
	return script != null and script.get_global_name() == "ShooterEnemy"


func _find_projectile(world: Node2D) -> Variant:
	for child in world.get_children():
		var script := child.get_script() as Script
		if (
			script != null
			and script.get_global_name() == "EnemyProjectile"
			and not child.is_queued_for_deletion()
		):
			return child
	return null


func _add_floor(world: Node2D) -> void:
	var floor := StaticBody2D.new()
	floor.position = Vector2(300.0, 112.0)
	floor.collision_layer = 1
	floor.collision_mask = 0
	world.add_child(floor)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1000.0, 24.0)
	collision.shape = rectangle
	floor.add_child(collision)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SHOOTER_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
