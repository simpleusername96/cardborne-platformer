extends SceneTree

const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const FORGE_CATALOG := preload("res://data/forge/forge_catalog.tres")
const PROGRESSION_CATALOG := preload("res://data/progression/run_progression_catalog.tres")
const CHARACTER_CATALOG := preload("res://data/characters/character_catalog.tres")
const STARTING_ITEM_IDS: Array[StringName] = [
	&"iron_cleaver", &"field_bow", &"rust_knives", &"traveler_jacket",
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

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_equipment()
	_validate_mastery()
	_validate_forge_and_levels()
	_validate_rejection_cases()
	_validate_round_trips()
	_finish()


func _validate_equipment() -> void:
	_append_errors(EQUIPMENT_CATALOG.validate_catalog(), "Equipment catalog")
	_expect(EQUIPMENT_CATALOG.id == &"first_run_equipment", "equipment catalog ID must be stable")
	_expect(EQUIPMENT_CATALOG.items.size() == 12, "equipment catalog must contain twelve items")
	for item in EQUIPMENT_CATALOG.items:
		_expect(
			EQUIPMENT_UNLOCK_COSTS.has(item.id),
			"equipment %s needs an accepted unlock-cost contract" % item.id
		)
		if EQUIPMENT_UNLOCK_COSTS.has(item.id):
			_expect(
				_same_int_map(item.unlock_costs, EQUIPMENT_UNLOCK_COSTS[item.id]),
				"equipment %s unlock cost must remain exact" % item.id
			)
		_expect(
			item.starting_item == STARTING_ITEM_IDS.has(item.id),
			"equipment %s starting ownership must remain exact" % item.id
		)
		_expect(not item.salvage_materials.is_empty(), "%s needs duplicate salvage" % item.id)
		for effect in item.build_effects:
			_expect(effect.source_id == item.id, "%s build effect needs owner source" % item.id)
			_expect(
				effect.source_scope == EffectDefinition.SOURCE_SCOPE_EQUIPMENT,
				"%s build effect needs equipment scope" % item.id
			)
		for effect in item.behavior_effects:
			_expect(effect.source_id == item.id, "%s behavior needs owner source" % item.id)
			_expect(
				effect.source_scope == ProgressionBehaviorEffect.SOURCE_SCOPE_EQUIPMENT,
				"%s behavior needs equipment scope" % item.id
			)

	for profile in CHARACTER_CATALOG.profiles:
		var profile_id := StringName(profile.id)
		var compatible := EQUIPMENT_CATALOG.get_compatible(profile_id)
		_expect(compatible.size() == 8, "%s should have eight compatible items" % profile_id)
		for item in compatible:
			_expect(item.is_compatible(profile_id), "%s compatibility subset is invalid" % profile_id)
	_expect(
		EQUIPMENT_CATALOG.get_compatible(&"unknown_character").is_empty(),
		"unknown character equipment subset should be empty"
	)


func _validate_mastery() -> void:
	_append_errors(MASTERY_CATALOG.validate_catalog(), "Mastery catalog")
	_expect(MASTERY_CATALOG.id == &"first_run_mastery", "mastery catalog ID must be stable")
	_expect(MASTERY_CATALOG.nodes.size() == 18, "mastery catalog must contain eighteen nodes")
	for profile in CHARACTER_CATALOG.profiles:
		var profile_id := StringName(profile.id)
		var nodes := MASTERY_CATALOG.get_for_character(profile_id)
		_expect(nodes.size() == 6, "%s should have six mastery nodes" % profile_id)
		for node in nodes:
			_expect(
				_same_int_map(node.costs, _expected_mastery_cost(node)),
				"mastery %s cost must match depth and character" % node.id
			)
			for effect in node.behavior_effects:
				_expect(effect.source_id == node.id, "%s behavior needs owner source" % node.id)
				_expect(
					effect.source_scope == ProgressionBehaviorEffect.SOURCE_SCOPE_MASTERY,
					"%s behavior needs mastery scope" % node.id
				)
	_expect(
		MASTERY_CATALOG.get_for_character(&"unknown_character").is_empty(),
		"unknown character mastery subset should be empty"
	)


func _validate_forge_and_levels() -> void:
	_append_errors(FORGE_CATALOG.validate_catalog(), "Forge catalog")
	_append_errors(PROGRESSION_CATALOG.validate_catalog(), "Progression catalog")
	_expect(FORGE_CATALOG.coin_cost == 15, "forge should cost fifteen coins")
	_expect(FORGE_CATALOG.offer_size == 3, "forge should offer three affixes")
	_expect(FORGE_CATALOG.affixes.size() == 5, "forge should contain five affixes")
	_expect(
		PROGRESSION_CATALOG.level_xp_totals == PackedInt32Array([0, 20, 55, 100, 145, 185]),
		"level curve should match complete-run balance"
	)


func _validate_rejection_cases() -> void:
	var duplicate_equipment := EquipmentCatalog.new()
	duplicate_equipment.id = &"duplicate_equipment_fixture"
	duplicate_equipment.display_name = "Duplicate Equipment Fixture"
	duplicate_equipment.items = EQUIPMENT_CATALOG.items.duplicate()
	duplicate_equipment.items[-1] = EQUIPMENT_CATALOG.items[0]
	_expect(
		_contains(duplicate_equipment.validate_catalog(), "repeats"),
		"equipment catalog should reject duplicate IDs"
	)

	var duplicate_mastery := MasteryCatalog.new()
	duplicate_mastery.id = &"duplicate_mastery_fixture"
	duplicate_mastery.display_name = "Duplicate Mastery Fixture"
	duplicate_mastery.nodes = MASTERY_CATALOG.nodes.duplicate()
	duplicate_mastery.nodes[-1] = MASTERY_CATALOG.nodes[0]
	_expect(
		_contains(duplicate_mastery.validate_catalog(), "repeats"),
		"mastery catalog should reject duplicate IDs"
	)

	var cross_character := _clone_mastery_catalog()
	cross_character.get_node(&"archer_airborne_hunter").requires_all = [&"warrior_broad_guard"]
	_expect(
		_contains(cross_character.validate_catalog(), "another character"),
		"mastery should reject cross-character prerequisites"
	)

	var cyclic := _clone_mastery_catalog()
	cyclic.get_node(&"warrior_broad_guard").requires_all = [&"warrior_last_bastion"]
	_expect(_contains(cyclic.validate_catalog(), "cycle"), "mastery should reject cycles")


func _validate_round_trips() -> void:
	_round_trip(EQUIPMENT_CATALOG, "user://equipment_catalog_round_trip.tres", 12)
	_round_trip(MASTERY_CATALOG, "user://mastery_catalog_round_trip.tres", 18)


func _round_trip(resource: Resource, path: String, expected_count: int) -> void:
	var save_error := ResourceSaver.save(resource, path)
	_expect(save_error == OK, "%s should save" % path)
	if save_error != OK:
		return
	var reloaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	_expect(reloaded != null, "%s should reload" % path)
	if reloaded is EquipmentCatalog:
		_expect(reloaded.items.size() == expected_count, "equipment round trip should preserve count")
		_append_errors(reloaded.validate_catalog(), "Equipment round trip")
	elif reloaded is MasteryCatalog:
		_expect(reloaded.nodes.size() == expected_count, "mastery round trip should preserve count")
		_append_errors(reloaded.validate_catalog(), "Mastery round trip")
	else:
		_expect(false, "%s reloaded with the wrong resource type" % path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _clone_mastery_catalog() -> MasteryCatalog:
	var clone := MasteryCatalog.new()
	clone.id = MASTERY_CATALOG.id
	clone.display_name = MASTERY_CATALOG.display_name
	clone.content_version = MASTERY_CATALOG.content_version
	for node in MASTERY_CATALOG.nodes:
		clone.nodes.append(node.duplicate(true) as MasteryNodeDefinition)
	return clone


func _expected_mastery_cost(node: MasteryNodeDefinition) -> Dictionary:
	var amount := 4
	if node.depth == &"middle":
		amount = 8
	elif node.depth == &"capstone":
		amount = 10
	var cost := {MATCHING_MATERIAL[node.character_id]: amount}
	if node.depth == &"capstone":
		cost[&"boss_core"] = 1
	return cost


func _same_int_map(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for raw_key in expected:
		var key := StringName(raw_key)
		if int(actual.get(key, actual.get(String(key), -1))) != int(expected[raw_key]):
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
		print("EQUIPMENT_MASTERY_CATALOG_VALIDATION_OK equipment=12 mastery=18 forge=5")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
