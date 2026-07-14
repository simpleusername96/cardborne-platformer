extends SceneTree

const CATALOG_PATH := "res://data/enemies/enemy_catalog.tres"
const SCENE_CATALOG_PATH := "res://data/enemies/enemy_scene_catalog.tres"
const REWARD_CATALOG_PATH := "res://data/rewards/reward_catalog.tres"
const WALKER_SCENE := "res://scenes/enemies/WalkerRuin.tscn"
const CHARGER_SCENE := "res://scenes/enemies/ChargerRuin.tscn"
const FLOODED_SCENES := {
	&"walker_flooded": "res://scenes/enemies/WalkerFlooded.tscn",
	&"charger_flooded": "res://scenes/enemies/ChargerFlooded.tscn",
	&"shooter_flooded": "res://scenes/enemies/ShooterFlooded.tscn",
	&"leaper_flooded": "res://scenes/enemies/LeaperFlooded.tscn",
}
const SANCTUM_SCENES := {
	&"walker_sanctum": "res://scenes/enemies/WalkerSanctum.tscn",
	&"charger_sanctum": "res://scenes/enemies/ChargerSanctum.tscn",
	&"shooter_sanctum": "res://scenes/enemies/ShooterSanctum.tscn",
	&"shield_guard_sanctum": "res://scenes/enemies/ShieldGuardSanctum.tscn",
	&"leaper_sanctum": "res://scenes/enemies/LeaperSanctum.tscn",
	&"sentry_sanctum": "res://scenes/enemies/SentrySanctum.tscn",
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(CATALOG_PATH) as EnemyCatalog
	_expect(catalog != null, "typed enemy catalog should load")
	if catalog != null:
		_expect(catalog.validate_catalog().is_empty(), "typed enemy catalog should validate")
		_expect(catalog.archetypes.size() == 6, "catalog should contain all six normal archetypes")
		_expect(catalog.tuning_profiles.size() == 3, "catalog should contain all three stage tuning profiles")
		_expect(catalog.variants.size() == 14, "catalog should contain all first-run variants")
		_validate_resolution(catalog)
		_validate_flooded_resolution(catalog)
		_validate_sanctum_resolution(catalog)
		_validate_scene_catalog(catalog)
		_validate_leaper_drop()
		_validate_content_ids()
	await _validate_scene(WALKER_SCENE, &"walker", &"walker_ruin", 3, 40)
	await _validate_scene(CHARGER_SCENE, &"charger", &"charger_ruin", 5, 60)
	await _validate_scene(FLOODED_SCENES[&"walker_flooded"], &"walker", &"walker_flooded", 4, 42)
	await _validate_scene(FLOODED_SCENES[&"charger_flooded"], &"charger", &"charger_flooded", 6, 66)
	await _validate_scene(FLOODED_SCENES[&"shooter_flooded"], &"shooter", &"shooter_flooded", 5, 44)
	await _validate_scene(FLOODED_SCENES[&"leaper_flooded"], &"leaper", &"leaper_flooded", 4, 55)
	for variant_id: StringName in SANCTUM_SCENES:
		var variant := catalog.get_variant_by_id(variant_id) if catalog != null else null
		if variant != null:
			await _validate_scene(
				SANCTUM_SCENES[variant_id],
				variant.archetype_id,
				variant.id,
				variant.health,
				variant.stagger_capacity
			)
	_finish()


func _validate_resolution(catalog: EnemyCatalog) -> void:
	var walker := catalog.resolve(&"walker", &"walker_ruin", &"ruin_approach")
	var charger := catalog.resolve(&"charger", &"charger_ruin", &"ruin_approach")
	var shield_guard := catalog.resolve(&"shield_guard", &"shield_guard_ruin", &"ruin_approach")
	_expect(walker != null, "walker ruin should resolve")
	_expect(charger != null, "charger ruin should resolve")
	_expect(shield_guard != null, "shield guard ruin should resolve")
	if walker != null:
		_expect(walker.health == 3 and walker.damage == 1, "walker ruin should keep exact health/damage")
		_expect(is_equal_approx(walker.move_speed, 70.0), "walker ruin should keep exact speed")
		_expect(walker.stagger_capacity == 40, "walker ruin should keep exact stagger capacity")
		var mutated := walker.get_exact_stats()
		mutated["health"] = 999
		_expect(walker.health == 3, "resolved spec collections should be copy-safe")
	if charger != null:
		_expect(charger.health == 5 and charger.damage == 1, "charger ruin should keep exact health/damage")
		_expect(is_equal_approx(charger.warning_time, 0.48), "charger warning should be exact")
		_expect(is_equal_approx(charger.active_time, 0.52), "charger active time should be exact")
		_expect(is_equal_approx(charger.recovery_time, 0.42), "charger recovery should be exact")
		_expect(is_equal_approx(charger.charge_speed, 360.0), "charger speed should be exact")
	if shield_guard != null:
		_expect(shield_guard.health == 7 and shield_guard.damage == 1, "ruin elite should keep exact health/damage")
		_expect(shield_guard.budget_cost == 3, "ruin elite should own the three-point encounter budget")
		_expect(shield_guard.drop_source_id == &"drop_shield_guard", "ruin elite should own the shield blueprint source")
	_expect(
		catalog.resolve(&"walker", &"walker_ruin", &"broken_sanctum") == null,
		"stage-mismatched resolution should fail"
	)


func _validate_flooded_resolution(catalog: EnemyCatalog) -> void:
	var expected := {
		&"walker_flooded": [&"walker", 4, 1, 76.0, 0.0, 0.0, 0.0, 42, 1],
		&"charger_flooded": [&"charger", 6, 1, 0.0, 0.46, 0.55, 0.42, 66, 2],
		&"shooter_flooded": [&"shooter", 5, 1, 0.0, 0.38, 0.0, 0.45, 44, 2],
		&"leaper_flooded": [&"leaper", 4, 1, 0.0, 0.38, 0.52, 0.52, 55, 2],
	}
	for variant_id: StringName in expected:
		var row: Array = expected[variant_id]
		var spec := catalog.resolve(row[0], variant_id, &"flooded_works")
		_expect(spec != null, "%s should resolve" % variant_id)
		if spec == null:
			continue
		_expect(spec.health == row[1] and spec.damage == row[2], "%s health/damage should be exact" % variant_id)
		_expect(is_equal_approx(spec.move_speed, row[3]), "%s move speed should be exact" % variant_id)
		_expect(is_equal_approx(spec.warning_time, row[4]), "%s warning should be exact" % variant_id)
		_expect(is_equal_approx(spec.active_time, row[5]), "%s active time should be exact" % variant_id)
		_expect(is_equal_approx(spec.recovery_time, row[6]), "%s recovery should be exact" % variant_id)
		_expect(spec.stagger_capacity == row[7], "%s stagger should be exact" % variant_id)
		_expect(spec.budget_cost == row[8], "%s budget should be exact" % variant_id)

	var charger := catalog.resolve(&"charger", &"charger_flooded", &"flooded_works")
	var shooter := catalog.resolve(&"shooter", &"shooter_flooded", &"flooded_works")
	var leaper := catalog.resolve(&"leaper", &"leaper_flooded", &"flooded_works")
	if charger != null:
		_expect(is_equal_approx(charger.charge_speed, 375.0), "Flooded Charger speed should be exact")
	if shooter != null:
		_expect(is_equal_approx(shooter.cadence_time, 1.75), "Flooded Shooter cadence should be exact")
		_expect(is_equal_approx(shooter.projectile_speed, 290.0), "Flooded Shooter projectile speed should be exact")
		_expect(is_equal_approx(shooter.attack_range, 820.0), "Flooded Shooter range should be exact")
	if leaper != null:
		var room := leaper.room_requirements
		_expect(is_equal_approx(room["minimum_lane_width"], 420.0), "Leaper needs a 420px lane")
		_expect(is_equal_approx(room["minimum_arc_clearance"], 180.0), "Leaper needs 180px arc clearance")
		_expect(is_equal_approx(leaper.safety_bounds["minimum_warning_time"], 0.32), "Leaper warning floor should resolve")
		_expect(is_equal_approx(leaper.safety_bounds["minimum_recovery_time"], 0.45), "Leaper recovery floor should resolve")
		var copied := leaper.get_exact_stats()
		copied["health"] = 999
		_expect(leaper.health == 4, "Flooded resolved specs must remain immutable")
		var source := catalog.get_variant_by_id(&"leaper_flooded")
		var original_warning := source.warning_time
		source.warning_time = 9.0
		_expect(is_equal_approx(leaper.warning_time, 0.38), "Resolved values must not follow source mutation")
		source.warning_time = original_warning


func _validate_sanctum_resolution(catalog: EnemyCatalog) -> void:
	for variant_id: StringName in SANCTUM_SCENES:
		var variant := catalog.get_variant_by_id(variant_id)
		_expect(variant != null, "%s should be registered" % variant_id)
		if variant == null:
			continue
		var resolved := catalog.resolve(variant.archetype_id, variant.id, &"broken_sanctum")
		_expect(resolved != null, "%s should resolve for Broken Sanctum" % variant_id)
		if resolved != null:
			_expect(resolved.damage == 1, "%s should preserve one-damage safety" % variant_id)
			_expect(resolved.budget_cost in [2, 3], "%s should keep its reviewed budget" % variant_id)


func _validate_scene_catalog(catalog: EnemyCatalog) -> void:
	var scenes := load(SCENE_CATALOG_PATH) as EnemySceneCatalog
	_expect(scenes != null, "enemy scene catalog should load")
	if scenes == null:
		return
	_expect(scenes.validate_catalog(catalog).is_empty(), "enemy scene catalog should validate")
	for variant_id: StringName in FLOODED_SCENES:
		var scene := scenes.get_scene_for_variant(variant_id, catalog)
		_expect(scene != null, "%s should have a registered scene" % variant_id)
		if scene != null:
			_expect(scene.resource_path == FLOODED_SCENES[variant_id], "%s should resolve its exact scene" % variant_id)
	for variant_id: StringName in SANCTUM_SCENES:
		var scene := scenes.get_scene_for_variant(variant_id, catalog)
		_expect(scene != null, "%s should have a registered scene" % variant_id)
		if scene != null:
			_expect(scene.resource_path == SANCTUM_SCENES[variant_id], "%s should resolve its exact scene" % variant_id)


func _validate_leaper_drop() -> void:
	var rewards := load(REWARD_CATALOG_PATH) as RewardCatalog
	_expect(rewards != null and rewards.validate_catalog().is_empty(), "reward catalog should validate")
	if rewards == null:
		return
	var table := rewards.get_table(&"drop_leaper")
	_expect(table != null, "drop_leaper should be registered")
	if table == null:
		return
	var entries := {}
	for entry in table.entries:
		entries[entry.content_id] = entry
	_expect(entries.size() == 4, "drop_leaper should contain four economy entries")
	_expect(_entry_matches(entries.get(&"xp"), 12, 12, 1.0), "Leaper XP should be exact")
	_expect(_entry_matches(entries.get(&"coin"), 2, 2, 1.0), "Leaper coins should be exact")
	_expect(_entry_matches(entries.get(&"sky_thread"), 1, 1, 0.25), "Leaper thread roll should be exact")
	_expect(_entry_matches(entries.get(&"slime_residue"), 1, 1, 0.2), "Leaper residue roll should be exact")


func _entry_matches(value: Variant, minimum: int, maximum: int, chance: float) -> bool:
	if not value is RewardEntry:
		return false
	var entry := value as RewardEntry
	return (
		entry.minimum_amount == minimum
		and entry.maximum_amount == maximum
		and is_equal_approx(entry.chance, chance)
	)


func _validate_content_ids() -> void:
	_expect(ContentId.is_valid("walker_ruin"), "snake_case content ID should validate")
	_expect(not ContentId.is_valid("Walker Ruin"), "spaced title must not validate as content ID")
	var errors := PackedStringArray()
	ContentId.validate_list(errors, "Fixture tag", [&"occupier", &"occupier"], true)
	_expect(errors.size() == 1, "content ID list validation should reject duplicates")


func _validate_scene(
	scene_path: String,
	expected_archetype: StringName,
	expected_variant: StringName,
	expected_health: int,
	expected_stagger: int
) -> void:
	var packed_scene := load(scene_path) as PackedScene
	_expect(packed_scene != null, "%s should load" % scene_path)
	if packed_scene == null:
		return
	var enemy: Variant = packed_scene.instantiate()
	_expect(
		enemy is CharacterBody2D and enemy.has_signal("defeated"),
		"%s should instantiate as a production enemy" % scene_path
	)
	if enemy == null:
		return
	root.add_child(enemy)
	await process_frame
	_expect(enemy.resolved_spec != null, "%s should resolve before play" % scene_path)
	_expect(enemy.archetype_id == expected_archetype, "%s archetype should match" % scene_path)
	_expect(enemy.variant_id == expected_variant, "%s variant should match" % scene_path)
	_expect(enemy.max_health == expected_health, "%s health should come from spec" % scene_path)
	_expect(enemy.stagger_capacity == expected_stagger, "%s stagger should come from spec" % scene_path)
	_expect(not enemy.auto_reset_on_defeat, "%s cannot auto-reset in production" % scene_path)
	enemy.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ENEMY_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
