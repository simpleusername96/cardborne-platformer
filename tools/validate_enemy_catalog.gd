extends SceneTree

const CATALOG_PATH := "res://data/enemies/enemy_catalog.tres"
const WALKER_SCENE := "res://scenes/enemies/WalkerRuin.tscn"
const CHARGER_SCENE := "res://scenes/enemies/ChargerRuin.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(CATALOG_PATH) as EnemyCatalog
	_expect(catalog != null, "typed enemy catalog should load")
	if catalog != null:
		_expect(catalog.validate_catalog().is_empty(), "typed enemy catalog should validate")
		_validate_resolution(catalog)
		_validate_content_ids()
	await _validate_scene(WALKER_SCENE, &"walker", &"walker_ruin", 3, 40)
	await _validate_scene(CHARGER_SCENE, &"charger", &"charger_ruin", 5, 60)
	_finish()


func _validate_resolution(catalog: EnemyCatalog) -> void:
	var walker := catalog.resolve(&"walker", &"walker_ruin", &"ruin_approach")
	var charger := catalog.resolve(&"charger", &"charger_ruin", &"ruin_approach")
	_expect(walker != null, "walker ruin should resolve")
	_expect(charger != null, "charger ruin should resolve")
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
	_expect(
		catalog.resolve(&"walker", &"walker_ruin", &"broken_sanctum") == null,
		"stage-mismatched resolution should fail"
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
