extends SceneTree

const SCENE_CATALOG_PATH := "res://data/enemies/enemy_scene_catalog.tres"
const ENEMY_CATALOG_PATH := "res://data/enemies/enemy_catalog.tres"
const LEAPER_VARIANT := &"leaper_flooded"
const MAX_FIXTURE_FRAMES := 180

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_validate_ai_has_no_content_branches()
	_validate_leaper_anchor_contract()
	await _validate_flooded_presentations()
	await _validate_mobile_terrain_response()
	await _validate_encounter_bounds()
	await _validate_leaper_interruption()
	await _validate_destination_selection()
	var first := await _run_leaper_sequence("first")
	var second := await _run_leaper_sequence("second")
	_expect(not first.is_empty() and not second.is_empty(), "deterministic Leaper fixtures should complete")
	if not first.is_empty() and not second.is_empty():
		_expect(
			var_to_bytes(first) == var_to_bytes(second),
			"identical Leaper fixtures should produce byte-equivalent timing"
		)
	_finish()


func _validate_leaper_anchor_contract() -> void:
	var catalog := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var archetype := catalog.get_archetype_by_id(&"leaper") if catalog != null else null
	_expect(archetype != null, "Leaper anchor fixture needs the typed archetype")
	if archetype == null:
		return
	var anchor := RoomEnemyAnchorData.new()
	anchor.allowed_pressure_roles = [&"vertical"]
	anchor.support_width = 600.0
	anchor.lane_width = 420.0
	anchor.clearance = 180.0
	anchor.has_escape_route = true
	_expect(anchor.supports(archetype, &"vertical"), "reviewed Leaper anchor should be eligible")
	anchor.clearance = 179.0
	_expect(
		not anchor.supports(archetype, &"vertical"),
		"Leaper allocation must reject insufficient jump-arc clearance"
	)


func _validate_flooded_presentations() -> void:
	var catalog := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var scenes := load(SCENE_CATALOG_PATH) as EnemySceneCatalog
	if catalog == null or scenes == null:
		_expect(false, "Flooded presentation fixture needs both enemy catalogs")
		return
	for variant_id in [&"walker_flooded", &"charger_flooded", &"shooter_flooded", LEAPER_VARIANT]:
		var packed := scenes.get_scene_for_variant(variant_id, catalog)
		_expect(packed != null, "%s should resolve a scene" % variant_id)
		if packed == null:
			continue
		var enemy: Variant = packed.instantiate()
		_expect(enemy is CharacterBody2D, "%s scene should instantiate an enemy body" % variant_id)
		if enemy == null:
			continue
		root.add_child(enemy)
		await process_frame
		_expect(enemy.resolved_spec != null, "%s should consume ResolvedEnemySpec" % variant_id)
		_expect(enemy.get_node_or_null("Visual/FloodedMark") != null, "%s needs a Flooded visual mark" % variant_id)
		if variant_id == &"charger_flooded":
			_expect(
				is_equal_approx(enemy.lane_warning_length, 128.0),
				"Flooded Charger should use a local direction cue."
			)
		if variant_id == &"shooter_flooded":
			_expect(is_equal_approx(enemy.weapon_length, 38.0), "Flooded Shooter needs a longer weapon")
		enemy.queue_free()
		await process_frame


func _validate_mobile_terrain_response() -> void:
	for variant_id in [&"walker_flooded", &"charger_flooded"]:
		await _run_mobile_terrain_fixture(variant_id)


func _run_mobile_terrain_fixture(variant_id: StringName) -> void:
	var catalog := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var scenes := load(SCENE_CATALOG_PATH) as EnemySceneCatalog
	var packed := scenes.get_scene_for_variant(variant_id, catalog) if scenes != null else null
	_expect(packed != null, "%s terrain fixture should resolve" % variant_id)
	if packed == null:
		return
	var world := Node2D.new()
	world.name = "%sTerrainFixture" % variant_id
	root.add_child(world)
	_add_platform(world, Vector2(300.0, 112.0), Vector2(260.0, 24.0))
	var enemy: Variant = packed.instantiate()
	if not enemy is CharacterBody2D:
		_expect(false, "%s terrain fixture should instantiate" % variant_id)
		world.queue_free()
		await process_frame
		return
	enemy.position = Vector2(390.0, 100.0)
	enemy.set("patrol_half_width", 500.0)
	enemy.encounter_bounds = Rect2(160.0, 0.0, 280.0, 220.0)
	world.add_child(enemy)
	await physics_frame
	var reversed := false
	var maximum_x: float = enemy.global_position.x
	for _frame in 150:
		await physics_frame
		maximum_x = maxf(maximum_x, enemy.global_position.x)
		if int(enemy.get("direction")) < 0:
			reversed = true
	_expect(reversed, "%s should reverse before leaving authored support" % variant_id)
	_expect(maximum_x <= 432.0, "%s should not patrol beyond the platform edge" % variant_id)
	_expect(enemy.global_position.y < 150.0, "%s should not walk into the void" % variant_id)
	world.queue_free()
	await process_frame


func _validate_encounter_bounds() -> void:
	var fixture := await _create_leaper_fixture("bounds", Vector2(120.0, 72.0))
	var world := fixture.get("world") as Node2D
	var leaper: Variant = fixture.get("leaper")
	var player := fixture.get("player") as Node2D
	if world == null or leaper == null or player == null:
		_expect(false, "encounter-bounds fixture should instantiate")
		return
	leaper.encounter_bounds = Rect2(300.0, 0.0, 400.0, 220.0)
	for _frame in 30:
		await physics_frame
	var snapshot: Dictionary = leaper.get_combat_snapshot()
	_expect(not snapshot["warning"] and not snapshot["active"], "Leaper must ignore targets outside encounter bounds")
	player.position = Vector2(360.0, 72.0)
	var warning_seen := false
	for _frame in 30:
		await physics_frame
		snapshot = leaper.get_combat_snapshot()
		if snapshot["warning"]:
			warning_seen = true
			break
	_expect(warning_seen, "Leaper should acquire a target after it enters encounter bounds")
	world.queue_free()
	await process_frame


func _validate_leaper_interruption() -> void:
	var fixture := await _create_leaper_fixture("interruption", Vector2(180.0, 72.0))
	var world := fixture.get("world") as Node2D
	var leaper: Variant = fixture.get("leaper")
	if world == null or leaper == null:
		_expect(false, "Leaper interruption fixture should instantiate")
		return
	leaper.encounter_bounds = Rect2(0.0, 0.0, 800.0, 220.0)
	var warning_seen := false
	for _frame in 40:
		await physics_frame
		if leaper.get_combat_snapshot()["warning"]:
			warning_seen = true
			break
	_expect(warning_seen, "Leaper interruption fixture should reach warning")
	if warning_seen:
		leaper.receive_damage(DamageInfo.new(1))
		await physics_frame
		var snapshot: Dictionary = leaper.get_combat_snapshot()
		var contact: Variant = leaper.get_node_or_null("ContactHitbox")
		_expect(snapshot["recovery"], "damage should interrupt Leaper warning into recovery")
		_expect(contact != null and not contact.active, "interrupted Leaper must remain non-damaging")
	world.queue_free()
	await process_frame


func _run_leaper_sequence(label: String) -> Dictionary:
	var fixture := await _create_leaper_fixture(label, Vector2(180.0, 72.0))
	var world := fixture.get("world") as Node2D
	var leaper: Variant = fixture.get("leaper")
	if world == null or leaper == null:
		return {}
	leaper.encounter_bounds = Rect2(0.0, 0.0, 800.0, 220.0)
	leaper.reset_enemy()
	await physics_frame

	var warning_frame := -1
	var active_frame := -1
	var recovery_frame := -1
	var idle_after_recovery_frame := -1
	var active_velocity := Vector2.ZERO
	for frame in MAX_FIXTURE_FRAMES:
		await physics_frame
		var snapshot: Dictionary = leaper.get_combat_snapshot()
		var contact: Variant = leaper.get_node_or_null("ContactHitbox")
		if warning_frame < 0 and snapshot["warning"]:
			warning_frame = frame
			var marker := leaper.get_node_or_null("LandingWarning") as Line2D
			_expect(marker != null and marker.visible, "%s warning should show the landing destination" % label)
			_expect(
				marker != null
				and marker.points.size() == 2
				and marker.points[0].distance_to(marker.points[1]) <= 50.0,
				"%s warning should be a local destination cue, not a full trajectory" % label
			)
			_expect(contact != null and not contact.active, "%s warning must not deal contact damage" % label)
		if active_frame < 0 and snapshot["active"]:
			active_frame = frame
			active_velocity = leaper.velocity
			_expect(contact != null and contact.active, "%s leap should activate contact damage" % label)
		if active_frame >= 0 and snapshot["recovery"]:
			recovery_frame = frame
			_expect(contact != null and not contact.active, "%s recovery must disable contact damage" % label)
			break
	if recovery_frame >= 0:
		for frame in range(recovery_frame + 1, MAX_FIXTURE_FRAMES):
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if not snapshot["warning"] and not snapshot["active"] and not snapshot["recovery"]:
				idle_after_recovery_frame = frame
				break

	_expect(warning_frame >= 0, "%s fixture should observe a warning" % label)
	_expect(active_frame > warning_frame, "%s active leap should follow its warning" % label)
	_expect(recovery_frame > active_frame, "%s recovery should follow the active leap" % label)
	_expect(idle_after_recovery_frame > recovery_frame, "%s recovery should return to idle" % label)
	_expect(active_frame - warning_frame >= 22, "%s warning must preserve its 0.38s floor" % label)
	_expect(recovery_frame - active_frame >= 30, "%s active window must preserve its 0.52s duration" % label)
	_expect(idle_after_recovery_frame - recovery_frame >= 30, "%s recovery must preserve its 0.52s floor" % label)
	_expect(
		leaper.resolved_spec != null and leaper.resolved_spec.drop_source_id == &"drop_leaper",
		"%s exact drop source should resolve" % label
	)
	var result := {
		"warning_frame": warning_frame,
		"active_frame": active_frame,
		"recovery_frame": recovery_frame,
		"idle_after_recovery_frame": idle_after_recovery_frame,
		"active_velocity": Vector2(snappedf(active_velocity.x, 0.01), snappedf(active_velocity.y, 0.01)),
	}
	world.queue_free()
	await process_frame
	return result


func _validate_destination_selection() -> void:
	var fixture := await _create_split_leaper_fixture()
	var world := fixture.get("world") as Node2D
	var leaper: Variant = fixture.get("leaper")
	var player := fixture.get("player") as Node2D
	if world == null or leaper == null or player == null:
		_expect(false, "multi-surface Leaper fixture should instantiate")
		return
	var destinations: Array[Vector2] = []
	for cycle in 3:
		var warning_seen := false
		var target := Vector2.ZERO
		for _frame in 150:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if snapshot["warning"]:
				warning_seen = true
				target = snapshot["landing_target"]
				break
		_expect(warning_seen, "Leaper cycle %d should select a destination" % cycle)
		if not warning_seen:
			break
		destinations.append(target)
		var landed := false
		for _frame in 150:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if snapshot["recovery"] and leaper.is_on_floor():
				landed = true
				break
		_expect(landed, "Leaper cycle %d should land on authored support" % cycle)
		_expect(
			absf(leaper.global_position.x - target.x) <= 72.0,
			"Leaper cycle %d should approach its warned destination" % cycle
		)
		for _frame in 90:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if not snapshot["warning"] and not snapshot["active"] and not snapshot["recovery"]:
				break
		player.position.x = 600.0 if cycle == 0 else (260.0 if cycle == 1 else 600.0)
	var distinct := 0
	var unique: Array[float] = []
	for destination in destinations:
		var repeated := false
		for existing_x in unique:
			if absf(destination.x - existing_x) < 48.0:
				repeated = true
				break
		if not repeated:
			unique.append(destination.x)
			distinct += 1
	_expect(distinct >= 2, "Leaper should use at least two reachable landing destinations")
	_expect(leaper.is_physics_processing(), "repeated Leaper cycles should not idle-lock")
	world.queue_free()
	await process_frame


func _create_leaper_fixture(label: String, player_position: Vector2) -> Dictionary:
	var catalog := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var scenes := load(SCENE_CATALOG_PATH) as EnemySceneCatalog
	var packed := scenes.get_scene_for_variant(LEAPER_VARIANT, catalog) if scenes != null else null
	if packed == null:
		return {}
	var world := Node2D.new()
	world.name = "LeaperFixture_%s" % label
	root.add_child(world)
	_add_floor(world)
	var player := Node2D.new()
	player.name = "PlayerMarker"
	player.add_to_group("player")
	player.position = player_position
	world.add_child(player)
	var leaper: Variant = packed.instantiate()
	if not leaper is CharacterBody2D:
		world.queue_free()
		await process_frame
		return {}
	leaper.position = Vector2(480.0, 100.0)
	world.add_child(leaper)
	await physics_frame
	await process_frame
	return {"world": world, "player": player, "leaper": leaper}


func _create_split_leaper_fixture() -> Dictionary:
	var catalog := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var scenes := load(SCENE_CATALOG_PATH) as EnemySceneCatalog
	var packed := scenes.get_scene_for_variant(LEAPER_VARIANT, catalog) if scenes != null else null
	if packed == null:
		return {}
	var world := Node2D.new()
	world.name = "LeaperMultiSurfaceFixture"
	root.add_child(world)
	_add_platform(world, Vector2(220.0, 112.0), Vector2(240.0, 24.0))
	_add_platform(world, Vector2(480.0, 112.0), Vector2(180.0, 24.0))
	_add_platform(world, Vector2(740.0, 112.0), Vector2(240.0, 24.0))
	var player := Node2D.new()
	player.name = "PlayerMarker"
	player.add_to_group("player")
	player.position = Vector2(220.0, 72.0)
	world.add_child(player)
	var leaper: Variant = packed.instantiate()
	if not leaper is CharacterBody2D:
		world.queue_free()
		await process_frame
		return {}
	leaper.position = Vector2(480.0, 100.0)
	leaper.encounter_bounds = Rect2(40.0, 0.0, 880.0, 220.0)
	world.add_child(leaper)
	await physics_frame
	await process_frame
	return {"world": world, "player": player, "leaper": leaper}


func _add_floor(world: Node2D) -> void:
	var floor := StaticBody2D.new()
	floor.position = Vector2(400.0, 112.0)
	floor.collision_layer = 1
	floor.collision_mask = 0
	world.add_child(floor)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1000.0, 24.0)
	collision.shape = rectangle
	floor.add_child(collision)


func _add_platform(world: Node2D, center: Vector2, size: Vector2) -> void:
	var floor := StaticBody2D.new()
	floor.position = center
	floor.collision_layer = 1
	floor.collision_mask = 0
	world.add_child(floor)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	floor.add_child(collision)


func _validate_ai_has_no_content_branches() -> void:
	for script_path in [
		"res://scripts/enemies/WalkerEnemy.gd",
		"res://scripts/enemies/ChargerEnemy.gd",
		"res://scripts/enemies/ShooterEnemy.gd",
		"res://scripts/enemies/LeaperEnemy.gd",
	]:
		var source := FileAccess.get_file_as_string(script_path)
		_expect(not source.is_empty(), "%s should be readable" % script_path)
		for forbidden in ["ruin_approach", "flooded_works", "broken_sanctum", "_flooded"]:
			_expect(not source.contains(forbidden), "%s must not branch on '%s'" % [script_path, forbidden])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_ENEMY_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
