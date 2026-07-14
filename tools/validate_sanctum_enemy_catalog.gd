extends SceneTree

const STAGE_ID := &"broken_sanctum"
const ARCHETYPE_PATHS := [
	"res://data/enemies/walker_archetype.tres",
	"res://data/enemies/charger_archetype.tres",
	"res://data/enemies/shooter_archetype.tres",
	"res://data/enemies/shield_guard_archetype.tres",
	"res://data/enemies/leaper_archetype.tres",
	"res://data/enemies/sentry_archetype.tres",
]
const VARIANT_PATHS := [
	"res://data/enemies/walker_sanctum.tres",
	"res://data/enemies/charger_sanctum.tres",
	"res://data/enemies/shooter_sanctum.tres",
	"res://data/enemies/shield_guard_sanctum.tres",
	"res://data/enemies/leaper_sanctum.tres",
	"res://data/enemies/sentry_sanctum.tres",
]
const SCENE_PATHS := {
	&"walker_sanctum": "res://scenes/enemies/WalkerSanctum.tscn",
	&"charger_sanctum": "res://scenes/enemies/ChargerSanctum.tscn",
	&"shooter_sanctum": "res://scenes/enemies/ShooterSanctum.tscn",
	&"shield_guard_sanctum": "res://scenes/enemies/ShieldGuardSanctum.tscn",
	&"leaper_sanctum": "res://scenes/enemies/LeaperSanctum.tscn",
	&"sentry_sanctum": "res://scenes/enemies/SentrySanctum.tscn",
}
const EXPECTED := {
	&"walker_sanctum": [&"walker", 5, 1, 82.0, 0.0, 0.0, 0.0, 46, 2],
	&"charger_sanctum": [&"charger", 6, 1, 0.0, 0.42, 0.58, 0.38, 72, 3],
	&"shooter_sanctum": [&"shooter", 6, 1, 0.0, 0.34, 0.0, 0.42, 48, 3],
	&"shield_guard_sanctum": [&"shield_guard", 7, 1, 0.0, 0.35, 1.2, 0.55, 100, 3],
	&"leaper_sanctum": [&"leaper", 5, 1, 0.0, 0.33, 0.55, 0.46, 60, 3],
	&"sentry_sanctum": [&"sentry", 6, 1, 0.0, 0.45, 0.0, 0.45, 80, 3],
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var catalog := _build_catalog()
	_expect(catalog != null, "Sanctum fixture should assemble a typed enemy catalog")
	if catalog != null:
		var errors := catalog.validate_catalog()
		_expect(errors.is_empty(), "Sanctum enemy resources should validate: %s" % errors)
		_validate_exact_resolution(catalog)
		await _validate_scenes(catalog)
	_validate_special_actor_scenes()
	_validate_drop_tables()
	_finish()


func _build_catalog() -> EnemyCatalog:
	var catalog := EnemyCatalog.new()
	catalog.id = &"sanctum_enemy_fixture"
	catalog.display_name = "Sanctum Enemy Fixture"
	catalog.content_version = 1
	catalog.tags = [&"enemy_catalog", &"fixture"]
	var archetypes: Array[EnemyArchetypeDefinition] = []
	for path in ARCHETYPE_PATHS:
		var archetype := load(path) as EnemyArchetypeDefinition
		_expect(archetype != null, "%s should load" % path)
		if archetype != null:
			archetypes.append(archetype)
	var tuning_profiles: Array[EnemyTuningProfile] = []
	var tuning := load("res://data/enemies/tuning_broken_sanctum.tres") as EnemyTuningProfile
	_expect(tuning != null, "Broken Sanctum tuning should load")
	if tuning != null:
		tuning_profiles.append(tuning)
	var variants: Array[EnemyVariantDefinition] = []
	for path in VARIANT_PATHS:
		var variant := load(path) as EnemyVariantDefinition
		_expect(variant != null, "%s should load" % path)
		if variant != null:
			variants.append(variant)
	catalog.archetypes = archetypes
	catalog.tuning_profiles = tuning_profiles
	catalog.variants = variants
	return catalog


func _validate_exact_resolution(catalog: EnemyCatalog) -> void:
	for variant_id: StringName in EXPECTED:
		var row: Array = EXPECTED[variant_id]
		var spec := catalog.resolve(row[0], variant_id, STAGE_ID)
		_expect(spec != null, "%s should resolve" % variant_id)
		if spec == null:
			continue
		_expect(spec.health == row[1] and spec.damage == row[2], "%s health/damage should be exact" % variant_id)
		_expect(is_equal_approx(spec.move_speed, row[3]), "%s move speed should be exact" % variant_id)
		_expect(is_equal_approx(spec.warning_time, row[4]), "%s warning should be exact" % variant_id)
		_expect(is_equal_approx(spec.active_time, row[5]), "%s active/guard time should be exact" % variant_id)
		_expect(is_equal_approx(spec.recovery_time, row[6]), "%s recovery should be exact" % variant_id)
		_expect(spec.stagger_capacity == row[7], "%s stagger capacity should be exact" % variant_id)
		_expect(spec.budget_cost == row[8], "%s budget should be exact" % variant_id)
	var charger := catalog.resolve(&"charger", &"charger_sanctum", STAGE_ID)
	var shooter := catalog.resolve(&"shooter", &"shooter_sanctum", STAGE_ID)
	var sentry := catalog.resolve(&"sentry", &"sentry_sanctum", STAGE_ID)
	if charger != null:
		_expect(is_equal_approx(charger.charge_speed, 395.0), "Sanctum Charger speed should be exact")
	if shooter != null:
		_expect(is_equal_approx(shooter.cadence_time, 1.55), "Sanctum Shooter cadence should be exact")
		_expect(is_equal_approx(shooter.projectile_speed, 315.0), "Sanctum Shooter projectile speed should be exact")
		_expect(is_equal_approx(shooter.attack_range, 920.0), "Sanctum Shooter range should be exact")
	if sentry != null:
		_expect(is_equal_approx(sentry.cadence_time, 1.4), "Sentry cadence should be exact")
		_expect(is_equal_approx(sentry.projectile_speed, 300.0), "Sentry projectile speed should be exact")
		_expect(is_equal_approx(sentry.attack_range, 900.0), "Sentry range should be exact")
		_expect(sentry.active_projectile_cap == 2, "Sentry projectile cap should be exact")


func _validate_scenes(catalog: EnemyCatalog) -> void:
	for variant_id: StringName in SCENE_PATHS:
		var scene_path: String = SCENE_PATHS[variant_id]
		var packed := load(scene_path) as PackedScene
		_expect(packed != null, "%s should load" % scene_path)
		if packed == null:
			continue
		var enemy: Variant = packed.instantiate()
		_expect(
			enemy is CharacterBody2D and enemy.has_method("get_combat_snapshot"),
			"%s should instantiate a production enemy" % scene_path
		)
		if not enemy is CharacterBody2D:
			continue
		enemy.enemy_catalog = catalog
		root.add_child(enemy)
		await process_frame
		var row: Array = EXPECTED[variant_id]
		_expect(enemy.resolved_spec != null, "%s should consume ResolvedEnemySpec" % variant_id)
		_expect(enemy.archetype_id == row[0] and enemy.variant_id == variant_id, "%s scene IDs should be exact" % variant_id)
		_expect(enemy.max_health == row[1], "%s scene health should come from the spec" % variant_id)
		_expect(enemy.stagger_capacity == row[7], "%s scene stagger should come from the spec" % variant_id)
		_expect(not enemy.auto_reset_on_defeat, "%s production scene must not self-reset" % variant_id)
		_expect(enemy.get_node_or_null("Visual/SanctumMark") != null or variant_id == &"shield_guard_sanctum", "%s needs a Sanctum presentation mark" % variant_id)
		_validate_runtime_values(enemy, variant_id)
		enemy.queue_free()
		await process_frame


func _validate_runtime_values(enemy: Variant, variant_id: StringName) -> void:
	var spec: Variant = enemy.resolved_spec
	if spec == null:
		return
	match variant_id:
		&"walker_sanctum":
			_expect(is_equal_approx(enemy.move_speed, spec.move_speed), "Walker runtime must not multiply speed")
		&"charger_sanctum":
			_expect(is_equal_approx(enemy.warning_time, spec.warning_time), "Charger runtime warning should be resolved")
			_expect(is_equal_approx(enemy.charge_time, spec.active_time), "Charger runtime active time should be resolved")
			_expect(is_equal_approx(enemy.recovery_time, spec.recovery_time), "Charger runtime recovery should be resolved")
			_expect(is_equal_approx(enemy.charge_speed, spec.charge_speed), "Charger runtime speed should be resolved")
		&"shooter_sanctum":
			_expect(is_equal_approx(enemy.warning_time, spec.warning_time), "Shooter runtime warning should be resolved")
			_expect(is_equal_approx(enemy.recovery_time, spec.recovery_time), "Shooter runtime recovery should be resolved")
			_expect(is_equal_approx(enemy.shoot_interval, spec.cadence_time), "Shooter runtime cadence should be resolved")
			_expect(is_equal_approx(enemy.projectile_speed, spec.projectile_speed), "Shooter runtime speed should be resolved")
			_expect(is_equal_approx(enemy.projectile_range, spec.attack_range), "Shooter runtime range should be resolved")
		&"shield_guard_sanctum":
			_expect(is_equal_approx(enemy.guard_time, spec.active_time), "Shield runtime guard duration should be resolved")
			_expect(is_equal_approx(enemy.attack_warning_time, spec.warning_time), "Shield runtime warning should be resolved")
			_expect(is_equal_approx(enemy.attack_recovery_time, spec.recovery_time), "Shield runtime recovery should be resolved")
		&"leaper_sanctum":
			_expect(is_equal_approx(enemy.warning_time, spec.warning_time), "Leaper runtime warning should be resolved")
			_expect(is_equal_approx(enemy.leap_time, spec.active_time), "Leaper runtime active time should be resolved")
			_expect(is_equal_approx(enemy.recovery_time, spec.recovery_time), "Leaper runtime recovery should be resolved")
		&"sentry_sanctum":
			_expect(is_equal_approx(enemy.warning_time, spec.warning_time), "Sentry runtime warning should be resolved")
			_expect(is_equal_approx(enemy.recovery_time, spec.recovery_time), "Sentry runtime recovery should be resolved")
			_expect(is_equal_approx(enemy.fire_interval, spec.cadence_time), "Sentry runtime cadence should be resolved")
			_expect(is_equal_approx(enemy.projectile_speed, spec.projectile_speed), "Sentry runtime speed should be resolved")
			_expect(is_equal_approx(enemy.activation_range, spec.attack_range), "Sentry runtime range should be resolved")
			_expect(enemy.max_active_projectiles == spec.active_projectile_cap, "Sentry runtime cap should be resolved")


func _validate_special_actor_scenes() -> void:
	var summon_scene := load("res://scenes/enemies/SummonNode.tscn") as PackedScene
	var slime_scene := load("res://scenes/enemies/SmallSlime.tscn") as PackedScene
	_expect(summon_scene != null, "Summon Node production scene should load")
	_expect(slime_scene != null, "Small Slime production scene should load")
	if summon_scene != null:
		var summon: Variant = summon_scene.instantiate()
		_expect(summon != null, "Summon Node production scene should instantiate")
		if summon == null:
			return
		root.add_child(summon)
		_expect(summon.max_health == 8, "Summon Node should have exact HP 8")
		_expect(summon.get_node_or_null("ContactHitbox") == null, "Summon Node should not have contact damage")
		_expect(summon.get_node_or_null("SpawnMarkers/Left") != null and summon.get_node_or_null("SpawnMarkers/Right") != null, "Summon Node needs two authored spawn markers")
		summon.queue_free()
	if slime_scene != null:
		var slime: Variant = slime_scene.instantiate()
		_expect(slime != null, "Small Slime production scene should instantiate")
		if slime == null:
			return
		root.add_child(slime)
		_expect(slime.max_health == 2 and slime.contact_damage == 1, "Small Slime should have exact health/damage")
		_expect(slime.get_combat_snapshot()["spawn_warning"], "Small Slime should begin in warning")
		slime.queue_free()


func _validate_drop_tables() -> void:
	_validate_drop("res://data/rewards/drop_shield_guard.tres", &"drop_shield_guard", {
		&"xp": [18, 18, 1.0],
		&"coin": [4, 4, 1.0],
		&"tower_shield": [1, 1, 1.0, RewardEntry.TYPE_BLUEPRINT_UNLOCK],
		&"steel_fragment": [6, 6, 1.0],
		&"hardwood": [5, 5, 1.0],
		&"reinforced_fabric": [5, 5, 1.0],
	})
	_validate_drop("res://data/rewards/drop_sentry.tres", &"drop_sentry", {
		&"xp": [20, 20, 1.0], &"coin": [5, 5, 1.0], &"rusted_scrap": [1, 1, 1.0],
	})
	_validate_drop("res://data/rewards/drop_summon_node.tres", &"drop_summon_node", {
		&"xp": [20, 20, 1.0], &"coin": [4, 4, 1.0], &"slime_residue": [1, 2, 0.5],
	})
	_validate_drop("res://data/rewards/drop_small_slime.tres", &"drop_small_slime", {
		&"xp": [4, 4, 1.0], &"coin": [1, 2, 0.6], &"slime_residue": [1, 1, 0.25],
	})


func _validate_drop(path: String, expected_id: StringName, expected: Dictionary) -> RewardTable:
	var table := load(path) as RewardTable
	_expect(table != null, "%s should load" % path)
	if table == null:
		return null
	_expect(table.id == expected_id, "%s ID should be exact" % path)
	_expect(table.validate_definition().is_empty(), "%s should validate" % path)
	var entries := {}
	for entry in table.entries:
		entries[entry.content_id] = entry
	_expect(entries.size() == expected.size(), "%s entry count should be exact" % path)
	for content_id: StringName in expected:
		var row: Array = expected[content_id]
		var entry := entries.get(content_id) as RewardEntry
		_expect(entry != null, "%s should contain %s" % [path, content_id])
		if entry != null:
			_expect(entry.minimum_amount == row[0] and entry.maximum_amount == row[1], "%s %s amount should be exact" % [path, content_id])
			_expect(is_equal_approx(entry.chance, row[2]), "%s %s chance should be exact" % [path, content_id])
			if row.size() >= 4:
				_expect(
					entry.reward_type == row[3],
					"%s %s reward type should be exact" % [path, content_id]
				)
	return table


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SANCTUM_ENEMY_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
