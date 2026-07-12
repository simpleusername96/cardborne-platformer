extends SceneTree

const CATALOG_PATH := "res://data/hazards/hazard_catalog.tres"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(CATALOG_PATH) as HazardCatalog
	_expect(catalog != null, "typed hazard catalog should load")
	if catalog == null:
		_finish()
		return

	_expect(catalog.validate_catalog().is_empty(), "typed hazard catalog should validate")
	_expect(catalog.definitions.size() == 2, "catalog should ship exactly two M3 hazards")
	_validate_lookup_and_eligibility(catalog)
	_validate_rejected_contracts(catalog)
	await _validate_spike_row(catalog.get_hazard(&"spike_row"))
	await _validate_fall_reset(catalog.get_hazard(&"fall_reset"))
	_finish()


func _validate_lookup_and_eligibility(catalog: HazardCatalog) -> void:
	var spike := catalog.get_hazard(&"spike_row")
	var reset := catalog.get_hazard(&"fall_reset")
	_expect(spike != null, "spike_row should resolve by ID")
	_expect(reset != null, "fall_reset should resolve by ID")
	_expect(catalog.get_hazard(&"missing") == null, "unknown hazard ID should fail closed")
	_expect(
		catalog.get_definition(&"spike_row") == spike,
		"legacy definition lookup should alias the allocator-facing hazard lookup"
	)
	if spike != null:
		_expect(spike.display_name == "Spike Row", "spike_row should keep its display name")
		_expect(spike.content_version == 1, "spike_row should keep content version 1")
		_expect(spike.budget_cost == 1, "spike_row should cost one hazard budget")
		_expect(spike.is_damaging and spike.is_static, "spike_row should be static and damaging")
		_expect(not spike.is_reset and spike.active_cap == 1, "spike_row should not reset and should cap at one")
	if reset != null:
		_expect(reset.display_name == "Fall Reset", "fall_reset should keep its display name")
		_expect(reset.content_version == 1, "fall_reset should keep content version 1")
		_expect(reset.budget_cost == 0, "fall_reset should not spend room hazard budget")
		_expect(not reset.is_damaging and reset.is_static, "fall_reset should be static and non-damaging")
		_expect(reset.is_reset and reset.active_cap == 1, "fall_reset should reset and should cap at one")

	var grounded_tags: Array[StringName] = [&"grounded"]
	var stage_wide_tags: Array[StringName] = [&"stage_wide"]
	var grounded := catalog.get_eligible(grounded_tags, 1)
	var stage_wide := catalog.get_eligible(stage_wide_tags, 0)
	_expect(grounded.size() == 1 and grounded[0] == spike, "grounded budget-one query should return spike_row")
	_expect(stage_wide.size() == 1 and stage_wide[0] == reset, "stage-wide budget-zero query should return fall_reset")
	_expect(catalog.get_eligible(grounded_tags, 0).is_empty(), "budget-zero grounded query should reject spike_row")


func _validate_rejected_contracts(catalog: HazardCatalog) -> void:
	var invalid := HazardDefinition.new()
	invalid.id = &"invalid_hazard"
	invalid.display_name = "Invalid Hazard"
	invalid.scene = catalog.get_hazard(&"spike_row").scene
	invalid.placement_tags = [&"grounded"]
	invalid.is_damaging = true
	invalid.is_reset = true
	invalid.active_cap = 0
	var invalid_errors := invalid.validate_definition()
	_expect(invalid_errors.size() == 2, "definition validation should reject mixed semantics and zero cap")

	var duplicate_catalog := HazardCatalog.new()
	duplicate_catalog.id = &"duplicate_fixture"
	duplicate_catalog.display_name = "Duplicate Fixture"
	duplicate_catalog.definitions = [
		catalog.get_hazard(&"spike_row"),
		catalog.get_hazard(&"spike_row"),
	]
	_expect(
		not duplicate_catalog.validate_catalog().is_empty(),
		"catalog validation should reject duplicate definition IDs"
	)


func _validate_spike_row(definition: HazardDefinition) -> void:
	if definition == null or definition.scene == null:
		return
	var instance := definition.scene.instantiate()
	_expect(instance is Hazard, "spike_row scene should instantiate the existing Hazard runtime")
	if not instance is Hazard:
		if instance != null:
			instance.free()
		return
	root.add_child(instance)
	await process_frame
	await physics_frame
	var collision := instance.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var visual := instance.get_node_or_null("Visual") as Polygon2D
	_expect(collision != null and collision.shape != null, "spike_row should have collision after ready")
	_expect(collision != null and not collision.disabled, "spike_row collision should be active after ready")
	_expect(visual != null and not visual.polygon.is_empty(), "spike_row should have visible spike geometry")
	_expect(instance.damage_amount == 1, "spike_row should deal exactly one damage")
	_expect(instance.active and instance.repeat_hits, "spike_row should start as a repeating active hitbox")
	_expect(instance.collision_layer == 64 and instance.collision_mask == 4, "spike_row should use hazard/player layers")
	instance.queue_free()
	await process_frame


func _validate_fall_reset(definition: HazardDefinition) -> void:
	if definition == null or definition.scene == null:
		return
	var instance := definition.scene.instantiate()
	_expect(instance is FallResetZone, "fall_reset scene should instantiate the existing reset runtime")
	_expect(not instance is Hitbox, "fall_reset scene should not be a damaging hitbox")
	if not instance is FallResetZone:
		if instance != null:
			instance.free()
		return
	root.add_child(instance)
	await process_frame
	await physics_frame
	var collision := instance.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_expect(collision != null and collision.shape != null, "fall_reset should have collision after ready")
	_expect(collision != null and not collision.disabled, "fall_reset collision should remain active after ready")
	_expect(instance.zone_size == Vector2(2000.0, 160.0), "fall_reset should cover the authored stage-wide catch size")
	_expect(instance.reason == "fall", "fall_reset should publish the fall reset reason")
	_expect(instance.collision_layer == 0 and instance.collision_mask == 4, "fall_reset should detect only the player body")
	instance.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("HAZARD_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
