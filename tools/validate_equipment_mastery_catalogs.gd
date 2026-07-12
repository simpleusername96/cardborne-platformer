extends SceneTree

const EQUIPMENT_CATALOG_PATH := "res://data/equipment/equipment_catalog.tres"
const MASTERY_CATALOG_PATH := "res://data/mastery/mastery_catalog.tres"
const EQUIPMENT_SOURCE_PATH := "res://data/design/first_slice/equipment_catalog.json"
const PROGRESSION_SOURCE_PATH := "res://data/design/first_slice/player_progression.json"

const STARTING_ITEM_IDS: Array[StringName] = [
	&"iron_cleaver",
	&"field_bow",
	&"rust_knives",
	&"traveler_jacket",
]
const EQUIPMENT_UNLOCK_COSTS := {
	&"iron_cleaver": {},
	&"bell_hammer": {&"rusted_scrap": 6},
	&"field_bow": {},
	&"twinstring_bow": {&"sky_thread": 6},
	&"rust_knives": {},
	&"hooked_blades": {&"slime_residue": 8},
	&"traveler_jacket": {},
	&"patched_mail": {&"rusted_scrap": 5},
	&"runner_cloak": {&"sky_thread": 5},
	&"copper_charm": {&"rusted_scrap": 6},
	&"spring_charm": {&"sky_thread": 6},
	&"slime_relic": {&"slime_residue": 8, &"boss_core": 1},
}
const MATCHING_MATERIAL := {
	&"warrior": &"rusted_scrap",
	&"archer": &"sky_thread",
	&"assassin": &"slime_residue",
}

var _failures := PackedStringArray()


func _initialize() -> void:
	var equipment := load(EQUIPMENT_CATALOG_PATH) as EquipmentCatalog
	var mastery := load(MASTERY_CATALOG_PATH) as MasteryCatalog
	_expect(equipment != null, "canonical equipment catalog must load")
	_expect(mastery != null, "canonical mastery catalog must load")
	if equipment != null and mastery != null:
		_validate_equipment(equipment)
		_validate_mastery(mastery)
		_validate_rejection_cases(equipment, mastery)
		_validate_round_trips(equipment, mastery)
	_finish()


func _validate_equipment(catalog: EquipmentCatalog) -> void:
	_expect(catalog.id == &"first_run_equipment", "equipment catalog ID must be stable")
	_expect(catalog.items.size() == 12, "equipment catalog must contain exactly 12 items")
	_expect(catalog.validate_catalog().is_empty(), "equipment catalog must pass catalog validation")
	var source := _load_json(EQUIPMENT_SOURCE_PATH)
	var source_items: Array = source.get("items", [])
	_expect(source_items.size() == 12, "equipment source must contain exactly 12 persistent items")
	_expect(
		_sorted_equipment_ids(catalog.items) == _sorted_dictionary_ids(source_items),
		"equipment resource IDs must exactly match the design source"
	)

	for raw_value in source_items:
		var raw_item: Dictionary = raw_value
		var item_id := StringName(raw_item.get("id", ""))
		var item := catalog.get_item(item_id)
		_expect(item != null, "equipment '%s' must be retrievable" % item_id)
		if item == null:
			continue
		_expect(catalog.has_item(item_id), "equipment '%s' must be reported present" % item_id)
		_expect(item.display_name == String(raw_item.get("display_name", "")), "%s display name must match source" % item_id)
		_expect(item.slot == StringName(raw_item.get("slot", "")), "%s slot must match source" % item_id)
		_expect(item.source == StringName(raw_item.get("source", "")), "%s source must match source catalog" % item_id)
		_expect(_same_id_array(item.compatibility, raw_item.get("compatibility", [])), "%s compatibility must match source" % item_id)
		_expect(_same_int_map(item.salvage_materials, raw_item.get("salvage", {})), "%s salvage must match source" % item_id)
		_expect(_same_int_map(item.unlock_costs, EQUIPMENT_UNLOCK_COSTS[item_id]), "%s unlock cost must match first-run decision" % item_id)
		_expect(item.starting_item == STARTING_ITEM_IDS.has(item_id), "%s starting-item flag must be exact" % item_id)
		_validate_equipment_effect_migration(item, raw_item.get("effects", []))

	for character_id in [&"warrior", &"archer", &"assassin"]:
		var compatible := catalog.get_compatible(character_id)
		_expect(compatible.size() == 8, "%s must have two weapons plus six shared items" % character_id)
		for item in compatible:
			_expect(item.is_compatible(character_id), "%s compatibility subset contains an invalid item" % character_id)
	_expect(catalog.get_compatible(&"unknown_character").is_empty(), "unknown character compatibility must be empty")


func _validate_equipment_effect_migration(item: EquipmentDefinition, raw_effects: Array) -> void:
	var expected_build_count := 0
	var expected_behavior_count := 0
	for raw_value in raw_effects:
		var raw_effect: Dictionary = raw_value
		var effect_type := StringName(raw_effect.get("type", ""))
		match effect_type:
			&"add_max_health":
				expected_build_count += 1
				_expect_build(item, &"max_health", "add", float(raw_effect.get("value", 0.0)))
				if raw_effect.has("minimum"):
					expected_behavior_count += 1
					var minimum_effect := _find_behavior(item, &"minimum_stat_value")
					_expect(minimum_effect != null, "%s must preserve minimum health as typed behavior" % item.id)
					if minimum_effect != null:
						_expect(minimum_effect.target_id == &"max_health", "%s minimum must target max_health" % item.id)
						_expect_close(minimum_effect.value, float(raw_effect.get("minimum", 0.0)), "%s minimum health" % item.id)
			&"add_move_speed":
				expected_build_count += 1
				_expect_build(item, &"move_speed", "add", float(raw_effect.get("value", 0.0)))
			&"multiply_damage_knockback":
				expected_build_count += 2
				_expect_build(item, &"damage_knockback_x", "multiply", float(raw_effect.get("value", 0.0)))
				_expect_build(item, &"damage_knockback_y", "multiply", float(raw_effect.get("value", 0.0)))
			&"reduce_dash_cooldown":
				expected_build_count += 1
				_expect_build(item, &"dash_cooldown", "add", -float(raw_effect.get("value", 0.0)))
			_:
				expected_behavior_count += 1
				var behavior := _find_behavior(item, effect_type)
				_expect(behavior != null, "%s must migrate behavior '%s'" % [item.id, effect_type])
				if behavior != null:
					_validate_equipment_behavior(behavior, raw_effect)
	_expect(item.build_effects.size() == expected_build_count, "%s must not add or drop build effects" % item.id)
	_expect(item.behavior_effects.size() == expected_behavior_count, "%s must not add or drop behavior effects" % item.id)
	for effect in item.build_effects:
		_expect(effect.source_id == item.id, "%s build effect source ID must match owner" % item.id)
		_expect(effect.source_scope == EffectDefinition.SOURCE_SCOPE_EQUIPMENT, "%s build effect scope must be equipment" % item.id)
	for effect in item.behavior_effects:
		_expect(effect.source_id == item.id, "%s behavior effect source ID must match owner" % item.id)
		_expect(effect.source_scope == ProgressionBehaviorEffect.SOURCE_SCOPE_EQUIPMENT, "%s behavior scope must be equipment" % item.id)


func _validate_equipment_behavior(effect: ProgressionBehaviorEffect, raw: Dictionary) -> void:
	match effect.effect_type:
		&"modify_attack":
			_expect(effect.target_id == StringName(raw.get("attack", "")), "attack modifier target must match source")
			_expect(effect.damage == int(raw.get("add_damage", 0)), "attack modifier damage must match source")
			_expect(effect.stagger == int(raw.get("add_stagger", 0)), "attack modifier stagger must match source")
			_expect_close(effect.recovery, float(raw.get("add_recovery", 0.0)), "attack modifier recovery")
		&"quick_shot_repeat":
			_expect_close(effect.delay, float(raw.get("delay", 0.0)), "Quick Shot repeat delay")
			_expect_close(effect.damage_scale, float(raw.get("damage_scale", 0.0)), "Quick Shot repeat damage")
		&"power_shot_max_damage":
			_expect(effect.damage_delta == int(raw.get("add", 0)), "Power Shot damage delta must match source")
		&"twin_cut_second_bleed":
			_expect(effect.damage == int(raw.get("damage", 0)), "Twin Cut bleed must match source")
		&"shadow_lunge_distance":
			_expect_close(effect.distance_delta, float(raw.get("add", 0.0)), "Shadow Lunge distance delta")
		&"reduce_first_card_reroll_cost":
			_expect_close(effect.value, float(raw.get("value", 0.0)), "reroll discount")
		&"first_post_double_jump_attack_stagger":
			_expect(effect.stagger == int(raw.get("value", 0)), "aerial stagger must match source")
		&"full_health_encounter_clear_guard":
			_expect_close(effect.duration, float(raw.get("duration", 0.0)), "Slime Relic duration")
			_expect(effect.limit == StringName(raw.get("limit", "")), "Slime Relic limit must match source")


func _validate_mastery(catalog: MasteryCatalog) -> void:
	_expect(catalog.id == &"first_run_mastery", "mastery catalog ID must be stable")
	_expect(catalog.nodes.size() == 18, "mastery catalog must contain exactly 18 nodes")
	_expect(catalog.validate_catalog().is_empty(), "mastery catalog must pass catalog validation")
	var source := _load_json(PROGRESSION_SOURCE_PATH)
	var source_nodes: Array = source.get("mastery_nodes", [])
	_expect(source_nodes.size() == 18, "mastery source must contain exactly 18 nodes")
	_expect(
		_sorted_mastery_ids(catalog.nodes) == _sorted_dictionary_ids(source_nodes),
		"mastery resource IDs must exactly match the design source"
	)

	for raw_value in source_nodes:
		var raw_node: Dictionary = raw_value
		var node_id := StringName(raw_node.get("id", ""))
		var node := catalog.get_node(node_id)
		_expect(node != null, "mastery '%s' must be retrievable" % node_id)
		if node == null:
			continue
		_expect(catalog.has_node(node_id), "mastery '%s' must be reported present" % node_id)
		_expect(node.character_id == StringName(raw_node.get("character", "")), "%s character must match source" % node_id)
		_expect(node.depth == StringName(raw_node.get("depth", "")), "%s depth must match source" % node_id)
		_expect(_same_id_array(node.requires_all, raw_node.get("requires", [])), "%s all-of prerequisites must match source" % node_id)
		_expect(_same_id_array(node.requires_any, raw_node.get("requires_any", [])), "%s any-of prerequisites must match source" % node_id)
		_expect(_same_int_map(node.costs, _expected_mastery_cost(node)), "%s costs must match depth and character" % node_id)
		var raw_effects: Array = raw_node.get("effects", [])
		_expect(node.behavior_effects.size() == raw_effects.size(), "%s effect count must match source" % node_id)
		for raw_effect_value in raw_effects:
			var raw_effect: Dictionary = raw_effect_value
			var effect_type := StringName(raw_effect.get("type", ""))
			var effect := _find_behavior_on_node(node, effect_type)
			_expect(effect != null, "%s must migrate behavior '%s'" % [node_id, effect_type])
			if effect != null:
				_expect(effect.source_id == node.id, "%s behavior source ID must match owner" % node_id)
				_expect(effect.source_scope == ProgressionBehaviorEffect.SOURCE_SCOPE_MASTERY, "%s behavior scope must be mastery" % node_id)
				_validate_mastery_behavior(effect, raw_effect)

	for character_id in [&"warrior", &"archer", &"assassin"]:
		_expect(catalog.get_for_character(character_id).size() == 6, "%s must expose exactly six mastery nodes" % character_id)
	_expect(catalog.get_for_character(&"unknown_character").is_empty(), "unknown character mastery subset must be empty")


func _validate_mastery_behavior(effect: ProgressionBehaviorEffect, raw: Dictionary) -> void:
	match effect.effect_type:
		&"wall_impact_stagger":
			_expect(effect.stagger == int(raw.get("value", 0)), "wall impact stagger must match source")
		&"breaker_applies_fractured":
			_expect_close(effect.duration, float(raw.get("duration", 0.0)), "Fractured duration")
			_expect(effect.damage == int(raw.get("next_skill_damage", 0)), "Fractured damage must match source")
		&"ground_splitter_aftershock", &"rain_final_arrow_bonus", &"twin_cut_second_bleed":
			_expect(effect.damage == int(raw.get("damage", 0)), "%s damage must match source" % effect.effect_type)
			if raw.has("duration"):
				_expect_close(effect.duration, float(raw.get("duration", 0.0)), "%s duration" % effect.effect_type)
			if raw.has("stagger"):
				_expect(effect.stagger == int(raw.get("stagger", 0)), "%s stagger must match source" % effect.effect_type)
		&"guard_knockback_scale", &"post_dash_quick_shot_startup_scale", \
		&"full_charge_extra_pierce", &"vault_air_control_restore", &"smoke_duration", \
		&"kunai_return_count", &"back_hit_flow_stack":
			_expect_close(effect.value, float(raw.get("value", 0.0)), "%s value" % effect.effect_type)
		&"once_per_stage_one_health_guard_and_skill_reset":
			_expect(effect.target_id == StringName(raw.get("skill", "")), "Last Bastion target must match source")
			_expect(effect.limit == ProgressionBehaviorEffect.LIMIT_ONCE_PER_STAGE, "Last Bastion limit must be explicit")
		&"transfer_consumed_mark":
			_expect_close(effect.duration, float(raw.get("duration", 0.0)), "Shared Mark duration")
			_expect_close(effect.radius, float(raw.get("radius", 0.0)), "Shared Mark radius")
		&"mark_consume_reduce_longest_skill":
			_expect_close(effect.seconds, float(raw.get("seconds", 0.0)), "Clean Release reduction")
			_expect_close(effect.internal_cooldown, float(raw.get("internal_cooldown", 0.0)), "Clean Release cooldown")
		&"lunge_kill_refund_dash":
			_expect_close(effect.internal_cooldown, float(raw.get("internal_cooldown", 0.0)), "Slipstream cooldown")


func _validate_rejection_cases(equipment: EquipmentCatalog, mastery: MasteryCatalog) -> void:
	var duplicate_equipment := EquipmentCatalog.new()
	duplicate_equipment.id = &"duplicate_equipment_fixture"
	duplicate_equipment.display_name = "Duplicate Equipment Fixture"
	for item in equipment.items:
		duplicate_equipment.items.append(item)
	duplicate_equipment.items[duplicate_equipment.items.size() - 1] = equipment.items[0]
	_expect(_contains(duplicate_equipment.validate_catalog(), "repeats"), "equipment catalog must reject duplicate IDs")

	var duplicate_mastery := MasteryCatalog.new()
	duplicate_mastery.id = &"duplicate_mastery_fixture"
	duplicate_mastery.display_name = "Duplicate Mastery Fixture"
	for node in mastery.nodes:
		duplicate_mastery.nodes.append(node)
	duplicate_mastery.nodes[duplicate_mastery.nodes.size() - 1] = mastery.nodes[0]
	_expect(_contains(duplicate_mastery.validate_catalog(), "repeats"), "mastery catalog must reject duplicate IDs")

	var cross_character := _clone_mastery_catalog(mastery)
	var airborne := cross_character.get_node(&"archer_airborne_hunter")
	airborne.requires_all = [&"warrior_broad_guard"]
	_expect(_contains(cross_character.validate_catalog(), "another character"), "mastery catalog must reject cross-character prerequisites")

	var cyclic := _clone_mastery_catalog(mastery)
	var broad_guard := cyclic.get_node(&"warrior_broad_guard")
	broad_guard.requires_all = [&"warrior_last_bastion"]
	_expect(_contains(cyclic.validate_catalog(), "cycle"), "mastery catalog must reject prerequisite cycles")

	var invalid_scope := ProgressionBehaviorEffect.new()
	invalid_scope.effect_type = &"quick_shot_repeat"
	invalid_scope.source_id = &"invalid_scope_fixture"
	invalid_scope.source_scope = ProgressionBehaviorEffect.SOURCE_SCOPE_MASTERY
	invalid_scope.target_id = &"archer_quick_shot"
	invalid_scope.delay = 0.1
	invalid_scope.damage_scale = 0.5
	_expect(_contains(invalid_scope.validate_definition(), "equipment-only"), "behavior effects must reject invalid source scopes")


func _validate_round_trips(equipment: EquipmentCatalog, mastery: MasteryCatalog) -> void:
	_round_trip_catalog(equipment, "user://equipment_catalog_round_trip.tres", 12)
	_round_trip_catalog(mastery, "user://mastery_catalog_round_trip.tres", 18)


func _round_trip_catalog(resource: Resource, path: String, expected_count: int) -> void:
	var save_error := ResourceSaver.save(resource, path)
	_expect(save_error == OK, "%s must save for a resource round trip" % path)
	if save_error != OK:
		return
	var reloaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	_expect(reloaded != null, "%s must reload after save" % path)
	if reloaded is EquipmentCatalog:
		_expect(reloaded.items.size() == expected_count, "equipment round trip must preserve item count")
		_expect(reloaded.validate_catalog().is_empty(), "equipment round trip must remain valid")
	elif reloaded is MasteryCatalog:
		_expect(reloaded.nodes.size() == expected_count, "mastery round trip must preserve node count")
		_expect(reloaded.validate_catalog().is_empty(), "mastery round trip must remain valid")
	else:
		_expect(false, "%s reloaded with the wrong resource type" % path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _clone_mastery_catalog(source: MasteryCatalog) -> MasteryCatalog:
	var clone := MasteryCatalog.new()
	clone.id = source.id
	clone.display_name = source.display_name
	clone.content_version = source.content_version
	for node in source.nodes:
		clone.nodes.append(node.duplicate(true) as MasteryNodeDefinition)
	return clone


func _expected_mastery_cost(node: MasteryNodeDefinition) -> Dictionary:
	var material_id: StringName = MATCHING_MATERIAL[node.character_id]
	var amount := 4
	if node.depth == &"middle":
		amount = 8
	elif node.depth == &"capstone":
		amount = 10
	var cost := {material_id: amount}
	if node.depth == &"capstone":
		cost[&"boss_core"] = 1
	return cost


func _expect_build(item: EquipmentDefinition, stat_id: StringName, operation: String, value: float) -> void:
	var found: EffectDefinition = null
	for effect in item.build_effects:
		if effect.stat_id == stat_id and effect.operation == operation:
			found = effect
			break
	_expect(found != null, "%s must contain %s %s build effect" % [item.id, operation, stat_id])
	if found != null:
		_expect_close(found.value, value, "%s %s build value" % [item.id, stat_id])


func _find_behavior(item: EquipmentDefinition, effect_type: StringName) -> ProgressionBehaviorEffect:
	for effect in item.behavior_effects:
		if effect.effect_type == effect_type:
			return effect
	return null


func _find_behavior_on_node(node: MasteryNodeDefinition, effect_type: StringName) -> ProgressionBehaviorEffect:
	for effect in node.behavior_effects:
		if effect.effect_type == effect_type:
			return effect
	return null


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "%s must open" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_expect(parsed is Dictionary, "%s must parse as a JSON object" % path)
	return parsed if parsed is Dictionary else {}


func _same_id_array(actual: Array[StringName], expected_value: Variant) -> bool:
	var expected: Array = expected_value if expected_value is Array else []
	var actual_ids: Array[String] = []
	var expected_ids: Array[String] = []
	for value in actual:
		actual_ids.append(String(value))
	for value in expected:
		expected_ids.append(String(value))
	actual_ids.sort()
	expected_ids.sort()
	return actual_ids == expected_ids


func _same_int_map(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for raw_key in expected:
		var key := StringName(raw_key)
		if int(actual.get(key, actual.get(String(key), -1))) != int(expected[raw_key]):
			return false
	return true


func _sorted_equipment_ids(items: Array[EquipmentDefinition]) -> Array[String]:
	var ids: Array[String] = []
	for item in items:
		ids.append(String(item.id))
	ids.sort()
	return ids


func _sorted_mastery_ids(nodes: Array[MasteryNodeDefinition]) -> Array[String]:
	var ids: Array[String] = []
	for node in nodes:
		ids.append(String(node.id))
	ids.sort()
	return ids


func _sorted_dictionary_ids(entries: Array) -> Array[String]:
	var ids: Array[String] = []
	for raw_value in entries:
		var entry: Dictionary = raw_value
		ids.append(String(entry.get("id", "")))
	ids.sort()
	return ids


func _contains(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	return false


func _expect_close(actual: float, expected: float, label: String) -> void:
	_expect(is_equal_approx(actual, expected), "%s expected %.3f, got %.3f" % [label, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("EQUIPMENT_MASTERY_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
