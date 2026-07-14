extends SceneTree

const CATALOG_PATH := "res://data/equipment/equipment_progression_catalog.tres"
const ROUND_TRIP_PATH := "user://equipment_progression_catalog_round_trip.tres"
const FORBIDDEN_EQUIPMENT_PROPERTIES: Array[StringName] = [
	&"compatibility",
	&"compatibility_ids",
	&"class_id",
	&"class_ids",
	&"rarity",
	&"random_stats",
	&"random_stat_range",
	&"active_skill_id",
	&"active_action_id",
]
const FORBIDDEN_SPIRIT_PROPERTIES: Array[StringName] = [
	&"input_action",
	&"cooldown",
	&"cooldown_seconds",
	&"resonance",
	&"resonance_max",
	&"resource_gauge",
	&"charge_meter",
	&"active_skill_id",
	&"active_action_id",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(CATALOG_PATH) as EquipmentProgressionCatalog
	_expect(catalog != null, "typed equipment progression catalog should load")
	if catalog == null:
		_finish()
		return

	_append_errors(catalog.validate_catalog(), "Equipment progression catalog")
	_expect(catalog.id == &"minimum_equipment_progression", "catalog ID must remain exact")
	_expect(catalog.materials.size() == 6, "catalog must contain exactly six materials")
	_expect(catalog.models.size() == 8, "catalog must contain exactly eight equipment models")
	_expect(catalog.blueprints.size() == 8, "catalog must contain exactly eight blueprints")
	_expect(catalog.spirit_stones.size() == 2, "catalog must contain exactly two Spirit Stones")
	_validate_materials(catalog)
	_validate_models(catalog)
	_validate_blueprints(catalog)
	_validate_spirit_stones(catalog)
	_validate_grade_policy()
	_validate_forbidden_schema(catalog)
	_validate_rejection_cases(catalog)
	_validate_round_trip(catalog)
	_finish()


func _validate_materials(catalog: EquipmentProgressionCatalog) -> void:
	var expected := {
		&"rusted_scrap": [MaterialDefinition.FAMILY_METAL, MaterialDefinition.GRADE_ONE],
		&"steel_fragment": [MaterialDefinition.FAMILY_METAL, MaterialDefinition.GRADE_TWO],
		&"common_timber": [MaterialDefinition.FAMILY_TIMBER, MaterialDefinition.GRADE_ONE],
		&"hardwood": [MaterialDefinition.FAMILY_TIMBER, MaterialDefinition.GRADE_TWO],
		&"sky_thread": [MaterialDefinition.FAMILY_TEXTILE, MaterialDefinition.GRADE_ONE],
		&"reinforced_fabric": [MaterialDefinition.FAMILY_TEXTILE, MaterialDefinition.GRADE_TWO],
	}
	for material_id in expected:
		var material := catalog.get_material(material_id)
		_expect(material != null, "material %s should resolve" % material_id)
		if material == null:
			continue
		var shape: Array = expected[material_id]
		_expect(material.family == shape[0], "material %s family must remain exact" % material_id)
		_expect(material.grade == int(shape[1]), "material %s grade must remain exact" % material_id)
		_expect(material.presentation_key == material.id, "material %s presentation key must be stable" % material_id)
	for family in MaterialDefinition.FAMILIES:
		_expect(
			catalog.get_material_for(family, MaterialDefinition.GRADE_ONE) != null,
			"material family %s should expose Grade 1" % family
		)
		_expect(
			catalog.get_material_for(family, MaterialDefinition.GRADE_TWO) != null,
			"material family %s should expose Grade 2" % family
		)
	_expect(catalog.get_material(&"missing_material") == null, "unknown material lookup should fail closed")


func _validate_models(catalog: EquipmentProgressionCatalog) -> void:
	_validate_attack_model(
		catalog,
		&"traveler_sword",
		EquipmentModelDefinition.SLOT_MELEE,
		2,
		18,
		76.0,
		0.10,
		0.22
	)
	var sword := catalog.get_model(&"traveler_sword")
	if sword != null:
		_expect(sword.combo_finisher_hit == 3, "Traveler Sword third hit must remain the finisher")
		_expect(
			is_equal_approx(sword.combo_finisher_width_multiplier, 1.20),
			"Traveler Sword finisher width must remain +20%"
		)
		_expect(sword.has_condition and sword.grade_one_max_condition == 100, "Traveler Sword condition must remain 100")

	_validate_attack_model(
		catalog,
		&"hunting_spear",
		EquipmentModelDefinition.SLOT_MELEE,
		3,
		24,
		118.0,
		0.16,
		0.30
	)
	var spear := catalog.get_model(&"hunting_spear")
	if spear != null:
		_expect(is_equal_approx(spear.close_range_penalty_distance, 36.0), "Hunting Spear close penalty must remain 36px")
		_expect(is_equal_approx(spear.tip_reward_length, 32.0), "Hunting Spear tip reward must remain 32px")
		_expect(spear.has_condition and spear.grade_one_max_condition == 100, "Hunting Spear condition must remain 100")

	_validate_attack_model(
		catalog,
		&"hunting_bow",
		EquipmentModelDefinition.SLOT_RANGED,
		2,
		10,
		520.0,
		0.12,
		0.44
	)
	var bow := catalog.get_model(&"hunting_bow")
	if bow != null:
		_expect(bow.ranged_resource_id == &"arrows", "Hunting Bow must consume arrows")
		_expect(bow.starting_ranged_resource == 12, "Hunting Bow must start with 12 arrows")
		_expect(bow.maximum_ranged_resource == 20, "Hunting Bow must cap at 20 arrows")
		_expect(is_zero_approx(bow.reload_seconds), "Hunting Bow must not gain reload timing")

	_validate_attack_model(
		catalog,
		&"matchlock",
		EquipmentModelDefinition.SLOT_RANGED,
		5,
		42,
		680.0,
		0.08,
		0.0
	)
	var matchlock := catalog.get_model(&"matchlock")
	if matchlock != null:
		_expect(matchlock.ranged_resource_id == &"cartridges", "Matchlock must consume cartridges")
		_expect(matchlock.starting_ranged_resource == 5, "Matchlock must start with 5 cartridges")
		_expect(matchlock.maximum_ranged_resource == 8, "Matchlock must cap at 8 cartridges")
		_expect(is_equal_approx(matchlock.reload_seconds, 1.35), "Matchlock reload must remain 1.35 seconds")
		_expect(matchlock.dash_cancels_reload, "Matchlock dash must cancel reload")

	_validate_shield_model(catalog, &"round_shield", 100, 120.0, 0.08, 0.14, 0.70, false)
	var round_shield := catalog.get_model(&"round_shield")
	if round_shield != null:
		_expect(
			is_equal_approx(round_shield.precise_guard_window_seconds, 0.14),
			"Round Shield precise window must remain 0.14 seconds"
		)

	_validate_shield_model(catalog, &"tower_shield", 150, 160.0, 0.30, 0.28, 0.35, true)
	var tower_shield := catalog.get_model(&"tower_shield")
	if tower_shield != null:
		_expect(
			is_zero_approx(tower_shield.precise_guard_window_seconds),
			"Tower Shield must not invent an unspecified precise-window duration"
		)

	var traveler_coat := catalog.get_model(&"traveler_coat")
	_expect(traveler_coat != null, "Traveler Coat should resolve")
	if traveler_coat != null:
		_expect(traveler_coat.slot == EquipmentModelDefinition.SLOT_ARMOR, "Traveler Coat must use armor slot")
		_expect(traveler_coat.max_health_bonus == 0, "Traveler Coat must remain baseline health")
		_expect(is_zero_approx(traveler_coat.knockback_reduction_fraction), "Traveler Coat must remain baseline knockback")
		_expect(is_zero_approx(traveler_coat.dash_cooldown_addition_seconds), "Traveler Coat must remain baseline dash")

	var reinforced_coat := catalog.get_model(&"reinforced_coat")
	_expect(reinforced_coat != null, "Reinforced Coat should resolve")
	if reinforced_coat != null:
		_expect(reinforced_coat.slot == EquipmentModelDefinition.SLOT_ARMOR, "Reinforced Coat must use armor slot")
		_expect(reinforced_coat.max_health_bonus == 2, "Reinforced Coat must add 2 max health")
		_expect(
			is_equal_approx(reinforced_coat.knockback_reduction_fraction, 0.15),
			"Reinforced Coat must reduce knockback by 15%"
		)
		_expect(
			is_equal_approx(reinforced_coat.dash_cooldown_addition_seconds, 0.06),
			"Reinforced Coat dash penalty must remain 0.06 seconds"
		)
	_expect(catalog.get_model(&"missing_model") == null, "unknown model lookup should fail closed")


func _validate_attack_model(
	catalog: EquipmentProgressionCatalog,
	model_id: StringName,
	expected_slot: StringName,
	expected_damage: int,
	expected_stagger: int,
	expected_reach: float,
	expected_startup: float,
	expected_recovery: float
) -> void:
	var model := catalog.get_model(model_id)
	_expect(model != null, "equipment model %s should resolve" % model_id)
	if model == null:
		return
	_expect(model.slot == expected_slot, "%s slot must remain exact" % model_id)
	_expect(model.damage == expected_damage, "%s damage must remain exact" % model_id)
	_expect(model.stagger_damage == expected_stagger, "%s stagger must remain exact" % model_id)
	_expect(is_equal_approx(model.reach, expected_reach), "%s reach must remain exact" % model_id)
	_expect(is_equal_approx(model.startup_seconds, expected_startup), "%s startup must remain exact" % model_id)
	_expect(is_equal_approx(model.recovery_seconds, expected_recovery), "%s recovery must remain exact" % model_id)


func _validate_shield_model(
	catalog: EquipmentProgressionCatalog,
	model_id: StringName,
	expected_stability: int,
	expected_angle: float,
	expected_startup: float,
	expected_recovery: float,
	expected_move_multiplier: float,
	expected_jump_block: bool
) -> void:
	var model := catalog.get_model(model_id)
	_expect(model != null, "shield model %s should resolve" % model_id)
	if model == null:
		return
	_expect(model.slot == EquipmentModelDefinition.SLOT_SHIELD, "%s must use shield slot" % model_id)
	_expect(model.guard_stability == expected_stability, "%s stability must remain exact" % model_id)
	_expect(is_equal_approx(model.guard_angle_degrees, expected_angle), "%s angle must remain exact" % model_id)
	_expect(is_equal_approx(model.startup_seconds, expected_startup), "%s startup must remain exact" % model_id)
	_expect(is_equal_approx(model.recovery_seconds, expected_recovery), "%s lower recovery must remain exact" % model_id)
	_expect(
		is_equal_approx(model.guard_move_speed_multiplier, expected_move_multiplier),
		"%s guard movement must remain exact" % model_id
	)
	_expect(model.blocks_jump_while_guarding == expected_jump_block, "%s jump rule must remain exact" % model_id)
	_expect(model.has_condition and model.grade_one_max_condition == 100, "%s condition must remain 100" % model_id)


func _validate_blueprints(catalog: EquipmentProgressionCatalog) -> void:
	for model_id in EquipmentProgressionCatalog.EXPECTED_MODEL_IDS:
		var blueprint := catalog.get_blueprint_for_model(model_id)
		_expect(blueprint != null, "model %s should resolve one blueprint" % model_id)
		if blueprint == null:
			continue
		var expected_blueprint_id := StringName("%s_blueprint" % model_id)
		var expected_recipe_id := StringName("%s_recipe" % model_id)
		_expect(blueprint.id == expected_blueprint_id, "%s blueprint ID must remain exact" % model_id)
		_expect(
			blueprint.starting_blueprint == EquipmentProgressionCatalog.STARTING_MODEL_IDS.has(model_id),
			"%s starting-blueprint state must remain exact" % model_id
		)
		_expect(blueprint.minimum_material_grade == 1, "%s minimum grade must remain 1" % model_id)
		_expect(blueprint.maximum_material_grade == 2, "%s maximum grade must remain 2" % model_id)
		_expect(blueprint.recipe != null, "%s should have a typed recipe" % model_id)
		if blueprint.recipe == null:
			continue
		_expect(blueprint.recipe.id == expected_recipe_id, "%s recipe ID must remain exact" % model_id)
		_expect(blueprint.recipe.same_grade_only, "%s recipe must remain same-grade" % model_id)
		_expect(
			_same_int_map(
				blueprint.recipe.family_costs,
				EquipmentProgressionCatalog.EXPECTED_RECIPE_COSTS[model_id]
			),
			"%s recipe costs must remain exact" % model_id
		)
	_expect(catalog.get_blueprint(&"missing_blueprint") == null, "unknown blueprint lookup should fail closed")


func _validate_spirit_stones(catalog: EquipmentProgressionCatalog) -> void:
	var ember := catalog.get_spirit_stone(&"ember_spirit_stone")
	_expect(ember != null, "Ember Spirit Stone should resolve")
	if ember != null:
		_expect(ember.trigger == SpiritStoneDefinition.TRIGGER_DIRECT_ATTACK_SEQUENCE, "Ember trigger must remain direct attacks")
		_expect(ember.effect == SpiritStoneDefinition.EFFECT_BURN, "Ember effect must remain burn")
		_expect(ember.required_direct_attack_count == 4, "Ember must trigger on the fourth direct attack")
		_expect(is_equal_approx(ember.direct_attack_window_seconds, 3.0), "Ember attack window must remain 3 seconds")
		_expect(ember.burn_damage_per_tick == 1, "Ember burn must remain 1 damage per tick")
		_expect(ember.burn_tick_count == 2, "Ember burn must remain 2 ticks")
		_expect(ember.deduplicate_by_event_id, "Ember must deduplicate event IDs")

	var frost := catalog.get_spirit_stone(&"frost_spirit_stone")
	_expect(frost != null, "Frost Spirit Stone should resolve")
	if frost != null:
		_expect(frost.trigger == SpiritStoneDefinition.TRIGGER_PRECISE_GUARD, "Frost trigger must remain precise guard")
		_expect(frost.effect == SpiritStoneDefinition.EFFECT_SLOW, "Frost effect must remain slow")
		_expect(is_equal_approx(frost.slow_fraction, 0.25), "Frost slow must remain 25%")
		_expect(is_equal_approx(frost.slow_duration_seconds, 1.5), "Frost duration must remain 1.5 seconds")
		_expect(frost.deduplicate_by_event_id, "Frost must deduplicate event IDs")
	_expect(catalog.get_spirit_stone(&"missing_stone") == null, "unknown Spirit Stone lookup should fail closed")


func _validate_grade_policy() -> void:
	_expect(EquipmentProgressionCatalog.GRADE_TWO_DAMAGE_BONUS == 1, "Grade 2 damage bonus must remain +1")
	_expect(
		is_equal_approx(EquipmentProgressionCatalog.GRADE_TWO_STAGGER_MULTIPLIER, 1.15),
		"Grade 2 stagger multiplier must remain +15%"
	)
	_expect(
		is_equal_approx(EquipmentProgressionCatalog.GRADE_TWO_STABILITY_MULTIPLIER, 1.15),
		"Grade 2 stability multiplier must remain +15%"
	)
	_expect(
		is_equal_approx(EquipmentProgressionCatalog.GRADE_TWO_CONDITION_MULTIPLIER, 1.20),
		"Grade 2 condition multiplier must remain +20%"
	)
	_expect(EquipmentProgressionCatalog.GRADE_TWO_ARMOR_HEALTH_BONUS == 1, "Grade 2 armor health must remain +1")


func _validate_forbidden_schema(catalog: EquipmentProgressionCatalog) -> void:
	for model in catalog.models:
		_expect_absent_properties(model, "Equipment model '%s'" % model.id, FORBIDDEN_EQUIPMENT_PROPERTIES)
	for blueprint in catalog.blueprints:
		_expect_absent_properties(blueprint, "Equipment blueprint '%s'" % blueprint.id, FORBIDDEN_EQUIPMENT_PROPERTIES)
		if blueprint.recipe != null:
			_expect_absent_properties(blueprint.recipe, "Crafting recipe '%s'" % blueprint.recipe.id, FORBIDDEN_EQUIPMENT_PROPERTIES)
	for stone in catalog.spirit_stones:
		_expect_absent_properties(stone, "Spirit Stone '%s'" % stone.id, FORBIDDEN_SPIRIT_PROPERTIES)


func _expect_absent_properties(resource: Resource, label: String, forbidden: Array[StringName]) -> void:
	var property_names: Dictionary = {}
	for property in resource.get_property_list():
		property_names[StringName(property["name"])] = true
	for forbidden_property in forbidden:
		_expect(
			not property_names.has(forbidden_property),
			"%s must not expose unsupported property '%s'" % [label, forbidden_property]
		)


func _validate_rejection_cases(catalog: EquipmentProgressionCatalog) -> void:
	var duplicate_model_catalog := _clone_catalog(catalog)
	duplicate_model_catalog.models[-1] = duplicate_model_catalog.models[0]
	_expect(
		_contains(duplicate_model_catalog.validate_catalog(), "Duplicate equipment model ID"),
		"catalog validation should reject duplicate model IDs"
	)

	var invalid_slot_catalog := _clone_catalog(catalog)
	var invalid_slot := catalog.get_model(&"traveler_sword").duplicate(true) as EquipmentModelDefinition
	invalid_slot.slot = &"weapon"
	invalid_slot_catalog.models[0] = invalid_slot
	_expect(
		_contains(invalid_slot_catalog.validate_catalog(), "unsupported slot"),
		"catalog validation should reject legacy or unknown equipment slots"
	)

	var invalid_grade_catalog := _clone_catalog(catalog)
	var invalid_grade := catalog.get_material(&"steel_fragment").duplicate(true) as MaterialDefinition
	invalid_grade.grade = 3
	invalid_grade_catalog.materials[1] = invalid_grade
	_expect(
		_contains(invalid_grade_catalog.validate_catalog(), "grade must be 1 or 2"),
		"catalog validation should reject unsupported material grades"
	)

	var invalid_recipe_catalog := _clone_catalog(catalog)
	var invalid_blueprint := catalog.get_blueprint(&"hunting_spear_blueprint").duplicate(true) as EquipmentBlueprintDefinition
	invalid_blueprint.recipe.family_costs = {&"metal": 3, &"ore": 4}
	invalid_recipe_catalog.blueprints[1] = invalid_blueprint
	_expect(
		_contains(invalid_recipe_catalog.validate_catalog(), "unsupported material family"),
		"catalog validation should reject recipe families outside metal/timber/textile"
	)

	var duplicate_target_catalog := _clone_catalog(catalog)
	var duplicate_target := catalog.get_blueprint(&"hunting_spear_blueprint").duplicate(true) as EquipmentBlueprintDefinition
	duplicate_target.model_id = &"traveler_sword"
	duplicate_target_catalog.blueprints[1] = duplicate_target
	_expect(
		_contains(duplicate_target_catalog.validate_catalog(), "Duplicate blueprint target model"),
		"catalog validation should reject multiple blueprints for one model"
	)

	var duplicate_stone_catalog := _clone_catalog(catalog)
	duplicate_stone_catalog.spirit_stones[1] = duplicate_stone_catalog.spirit_stones[0]
	_expect(
		_contains(duplicate_stone_catalog.validate_catalog(), "Duplicate Spirit Stone ID"),
		"catalog validation should reject duplicate Spirit Stone IDs"
	)


func _clone_catalog(catalog: EquipmentProgressionCatalog) -> EquipmentProgressionCatalog:
	var clone := EquipmentProgressionCatalog.new()
	clone.id = catalog.id
	clone.display_name = catalog.display_name
	clone.content_version = catalog.content_version
	clone.tags = catalog.tags.duplicate()
	clone.materials = catalog.materials.duplicate()
	clone.models = catalog.models.duplicate()
	clone.blueprints = catalog.blueprints.duplicate()
	clone.spirit_stones = catalog.spirit_stones.duplicate()
	return clone


func _validate_round_trip(catalog: EquipmentProgressionCatalog) -> void:
	var save_error := ResourceSaver.save(catalog, ROUND_TRIP_PATH)
	_expect(save_error == OK, "equipment progression catalog should save for a round trip")
	if save_error != OK:
		return
	var reloaded := ResourceLoader.load(
		ROUND_TRIP_PATH,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	) as EquipmentProgressionCatalog
	_expect(reloaded != null, "equipment progression catalog should reload with its typed class")
	if reloaded != null:
		_append_errors(reloaded.validate_catalog(), "Equipment progression round trip")
		_expect(reloaded.materials.size() == 6, "round trip should preserve six materials")
		_expect(reloaded.models.size() == 8, "round trip should preserve eight models")
		_expect(reloaded.blueprints.size() == 8, "round trip should preserve eight blueprints")
		_expect(reloaded.spirit_stones.size() == 2, "round trip should preserve two Spirit Stones")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROUND_TRIP_PATH))


func _same_int_map(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for raw_key in expected:
		var key := StringName(raw_key)
		var amount: Variant = actual.get(key, actual.get(String(key), -1))
		if not amount is int or int(amount) != int(expected[raw_key]):
			return false
	return true


func _contains(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	return false


func _append_errors(errors: PackedStringArray, label: String) -> void:
	for error in errors:
		_failures.append("%s: %s" % [label, error])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"EQUIPMENT_PROGRESSION_CATALOG_VALIDATION_OK "
			+ "models=8 blueprints=8 materials=6 spirit_stones=2"
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
