extends SceneTree

# Guards preimplementation catalog IDs and counts until typed Resources replace JSON.
const CATALOG_PATHS := {
	"player": "res://data/design/first_slice/player_progression.json",
	"cards": "res://data/design/first_slice/card_catalog.json",
	"equipment": "res://data/design/first_slice/equipment_catalog.json",
	"economy": "res://data/design/first_slice/economy_tables.json",
	"encounters": "res://data/design/first_slice/enemy_trap_gimmick_catalog.json",
	"generation": "res://data/design/first_slice/procedural_region_rules.json",
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalogs: Dictionary = {}
	for catalog_name in CATALOG_PATHS:
		var path: String = CATALOG_PATHS[catalog_name]
		var parsed: Variant = _load_json(path)
		if parsed != null:
			catalogs[catalog_name] = parsed

	if catalogs.size() == CATALOG_PATHS.size():
		_validate_catalogs(catalogs)
	_finish()


func _load_json(path: String) -> Variant:
	_expect(FileAccess.file_exists(path), "missing catalog: %s" % path)
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(parsed is Dictionary, "catalog must contain a JSON object: %s" % path)
	if not parsed is Dictionary:
		return null
	_expect(str(parsed.get("schema", "")).ends_with(".v1"), "catalog schema must be accepted v1: %s" % path)
	return parsed


func _validate_catalogs(catalogs: Dictionary) -> void:
	var player: Dictionary = catalogs["player"]
	var cards: Dictionary = catalogs["cards"]
	var equipment: Dictionary = catalogs["equipment"]
	var economy: Dictionary = catalogs["economy"]
	var encounters: Dictionary = catalogs["encounters"]
	var generation: Dictionary = catalogs["generation"]

	var characters := _index_entries(player.get("characters", []), "character")
	var mastery := _index_entries(player.get("mastery_nodes", []), "mastery")
	var card_entries := _index_entries(cards.get("cards", []), "card")
	var items := _index_entries(equipment.get("items", []), "equipment")
	var consumables := _index_entries(equipment.get("consumables", []), "consumable")
	var currencies := _index_entries(economy.get("currencies", []), "currency")
	var drop_tables := _index_entries(economy.get("drop_tables", []), "drop table")
	var enemies := _index_entries(encounters.get("enemies", []), "enemy")
	var special_actors := _index_entries(encounters.get("special_actors", []), "special actor")
	var hazards := _index_entries(encounters.get("hazards", []), "hazard")
	var stage_profiles := _index_entries(generation.get("stage_profiles", []), "stage profile")
	var rooms := _index_entries(generation.get("room_templates", []), "room template")

	_expect(characters.size() == 3, "first run requires exactly 3 characters")
	_expect(mastery.size() == 18, "first run requires exactly 18 mastery nodes")
	_expect(card_entries.size() == 15, "first run requires exactly 15 cards")
	_expect(items.size() == 12, "first run requires exactly 12 persistent equipment items")
	_expect(consumables.size() == 3, "first run requires exactly 3 consumables")
	_expect(enemies.size() == 6, "first run requires exactly 6 normal enemies")
	_expect(special_actors.size() == 2, "first run requires exactly 2 special actors")
	_expect(hazards.size() == 4, "first run requires exactly 4 core hazards")
	_expect(stage_profiles.size() == 3, "first run requires exactly 3 generated stage profiles")
	_expect(rooms.size() == 18, "first run requires exactly 18 room templates")

	for character_id in characters:
		var character: Dictionary = characters[character_id]
		for mastery_id in character.get("mastery_nodes", []):
			_expect(
				mastery.has(mastery_id),
				"character %s references unknown mastery %s" % [character_id, mastery_id]
			)
		var starting: Dictionary = character.get("starting_equipment", {})
		for slot in ["weapon", "armor", "charm", "relic"]:
			var item_id: Variant = starting.get(slot)
			if item_id != null:
				_expect(
					items.has(item_id),
					"character %s references unknown %s item %s" % [character_id, slot, item_id]
				)
		var consumable_id: Variant = starting.get("consumable")
		if consumable_id != null:
			_expect(
				consumables.has(consumable_id),
				"character %s references unknown consumable %s" % [character_id, consumable_id]
			)

	for mastery_id in mastery:
		var node: Dictionary = mastery[mastery_id]
		_expect(characters.has(node.get("character", "")), "mastery %s references unknown character" % mastery_id)
		for required_id in node.get("requires", []):
			_expect(mastery.has(required_id), "mastery %s requires unknown node %s" % [mastery_id, required_id])
		for required_id in node.get("requires_any", []):
			_expect(mastery.has(required_id), "mastery %s requires unknown alternative %s" % [mastery_id, required_id])

	for card_id in card_entries:
		var card: Dictionary = card_entries[card_id]
		var compatibility: Array = card.get("compatibility", [])
		_expect(not compatibility.is_empty(), "card %s needs compatibility" % card_id)
		for compatible_id in compatibility:
			_expect(
				compatible_id == "shared" or characters.has(compatible_id),
				"card %s has unknown compatibility %s" % [card_id, compatible_id]
			)

	for enemy_id in enemies:
		_expect(
			drop_tables.has(enemies[enemy_id].get("drop_table", "")),
			"enemy %s references unknown drop table" % enemy_id
		)
	for actor_id in special_actors:
		_expect(
			drop_tables.has(special_actors[actor_id].get("drop_table", "")),
			"special actor %s references unknown drop table" % actor_id
		)
	var boss: Dictionary = encounters.get("boss", {})
	_expect(drop_tables.has(boss.get("drop_table", "")), "boss references unknown drop table")
	_validate_economy_refs(economy, currencies, drop_tables, consumables, stage_profiles, boss)

	for room_id in rooms:
		var room: Dictionary = rooms[room_id]
		for stage_id in room.get("stages", []):
			_expect(
				stage_profiles.has(stage_id),
				"room %s references unknown stage profile %s" % [room_id, stage_id]
			)
		for hazard_id in room.get("hazard_tags", []):
			_expect(hazards.has(hazard_id), "room %s references unknown hazard %s" % [room_id, hazard_id])
	for stage_id in stage_profiles:
		var profile: Dictionary = stage_profiles[stage_id]
		var required_roles: Array = profile.get("required_roles", [])
		_expect(
			required_roles.size() == int(profile.get("required_room_count", -1)),
			"stage %s required role count must match required room count" % stage_id
		)
		var terminal_role := str(profile.get("terminal_room_role", ""))
		_expect(
			not required_roles.is_empty() and terminal_role == str(required_roles[-1]),
			"stage %s terminal role must match its final required room role" % stage_id
		)
		for role_value in required_roles:
			_expect(
				_stage_has_room_role(stage_id, str(role_value), rooms),
				"stage %s has no room template for required role %s" % [stage_id, role_value]
			)
		for enemy_id in profile.get("eligible_enemies", []):
			_expect(
				enemies.has(enemy_id) or special_actors.has(enemy_id),
				"stage %s references unknown enemy %s" % [stage_id, enemy_id]
			)
		for hazard_id in profile.get("eligible_hazards", []):
			_expect(hazards.has(hazard_id), "stage %s references unknown hazard %s" % [stage_id, hazard_id])


func _validate_economy_refs(
		economy: Dictionary,
		currencies: Dictionary,
		drop_tables: Dictionary,
		consumables: Dictionary,
		stage_profiles: Dictionary,
		boss: Dictionary
) -> void:
	for drop_id in drop_tables:
		var drop_table: Dictionary = drop_tables[drop_id]
		for entry_value in drop_table.get("guaranteed", []) + drop_table.get("rolls", []):
			if not entry_value is Dictionary:
				_expect(false, "drop table %s contains a non-object entry" % drop_id)
				continue
			var entry: Dictionary = entry_value
			if entry.get("type", "") == "currency":
				_expect(
					currencies.has(entry.get("id", "")),
					"drop table %s references unknown currency %s"
					% [drop_id, entry.get("id", "")]
				)

	var boss_stage_id := str(boss.get("stage_id", ""))
	_expect(not boss_stage_id.is_empty(), "boss needs a stage_id")
	for stage_reward_value in economy.get("stage_clear_rewards", []):
		if not stage_reward_value is Dictionary:
			_expect(false, "stage clear reward entry must be an object")
			continue
		var stage_reward: Dictionary = stage_reward_value
		var stage_id := str(stage_reward.get("stage_profile", ""))
		_expect(
			stage_profiles.has(stage_id) or stage_id == boss_stage_id,
			"stage clear rewards reference unknown stage %s" % stage_id
		)
		for reward_value in stage_reward.get("rewards", []):
			if not reward_value is Dictionary:
				_expect(false, "stage %s contains a non-object reward" % stage_id)
				continue
			var reward: Dictionary = reward_value
			match str(reward.get("type", "")):
				"currency":
					_expect(
						currencies.has(reward.get("id", "")),
						"stage %s references unknown currency %s"
						% [stage_id, reward.get("id", "")]
					)
				"apply_drop_table":
					_expect(
						drop_tables.has(reward.get("id", "")),
						"stage %s references unknown drop table %s"
						% [stage_id, reward.get("id", "")]
					)

	for shop_entry_value in economy.get("shop", []):
		if not shop_entry_value is Dictionary:
			_expect(false, "shop entry must be an object")
			continue
		var shop_entry: Dictionary = shop_entry_value
		var effect: Dictionary = shop_entry.get("effect", {})
		if effect.get("type", "") == "grant_consumable":
			_expect(
				consumables.has(effect.get("id", "")),
				"shop entry %s references unknown consumable %s"
				% [shop_entry.get("id", ""), effect.get("id", "")]
			)


func _stage_has_room_role(stage_id: String, role: String, rooms: Dictionary) -> bool:
	for room_id in rooms:
		var room: Dictionary = rooms[room_id]
		if room.get("role", "") == role and stage_id in room.get("stages", []):
			return true
	return false


func _index_entries(entries: Array, label: String) -> Dictionary:
	var indexed: Dictionary = {}
	for entry_value in entries:
		_expect(entry_value is Dictionary, "%s entry must be an object" % label)
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var id := str(entry.get("id", ""))
		_expect(not id.is_empty(), "%s entry needs an id" % label)
		_expect(not indexed.has(id), "duplicate %s id: %s" % [label, id])
		if not id.is_empty() and not indexed.has(id):
			indexed[id] = entry
	return indexed


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("DESIGN_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
