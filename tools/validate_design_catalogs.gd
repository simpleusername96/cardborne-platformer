extends SceneTree

# Guards preimplementation catalog identities, cross-references, and gameplay invariants.
const CATALOG_PATHS := {
	"player": "res://data/design/first_slice/player_progression.json",
	"cards": "res://data/design/first_slice/card_catalog.json",
	"equipment": "res://data/design/first_slice/equipment_catalog.json",
	"economy": "res://data/design/first_slice/economy_tables.json",
	"encounters": "res://data/design/first_slice/enemy_trap_gimmick_catalog.json",
	"generation": "res://data/design/first_slice/procedural_region_rules.json",
}
const EXPECTED_SCHEMAS := {
	"player": "cardborne.first_run.player_progression.v1",
	"cards": "cardborne.first_run.card_catalog.v1",
	"equipment": "cardborne.first_run.equipment_catalog.v1",
	"economy": "cardborne.first_run.economy.v1",
	"encounters": "cardborne.first_run.encounter_catalog.v2",
	"generation": "cardborne.first_run.stage_generation.v1",
}
const FLOAT_EPSILON := 0.0001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalogs: Dictionary = {}
	for catalog_name in CATALOG_PATHS:
		var path: String = CATALOG_PATHS[catalog_name]
		var expected_schema: String = EXPECTED_SCHEMAS[catalog_name]
		var parsed: Variant = _load_json(path, expected_schema)
		if parsed != null:
			catalogs[catalog_name] = parsed

	if catalogs.size() == CATALOG_PATHS.size():
		_validate_catalogs(catalogs)
	_finish()


func _load_json(path: String, expected_schema: String) -> Variant:
	_expect(FileAccess.file_exists(path), "missing catalog: %s" % path)
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(parsed is Dictionary, "catalog must contain a JSON object: %s" % path)
	if not parsed is Dictionary:
		return null
	_expect(
		str(parsed.get("schema", "")) == expected_schema,
		"catalog schema must be %s: %s" % [expected_schema, path]
	)
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
	var archetypes := _index_entries(encounters.get("enemy_archetypes", []), "enemy archetype")
	var variants := _index_entries(encounters.get("enemy_variants", []), "enemy variant")
	var tuning_profiles := _index_entries(
		encounters.get("enemy_tuning_profiles", []), "enemy tuning profile"
	)
	var special_actors := _index_entries(encounters.get("special_actors", []), "special actor")
	var hazards := _index_entries(encounters.get("hazards", []), "hazard")
	var stage_profiles := _index_entries(generation.get("stage_profiles", []), "stage profile")
	var rooms := _index_entries(generation.get("room_templates", []), "room template")

	_expect(characters.size() == 3, "first run requires exactly 3 characters")
	_expect(mastery.size() == 18, "first run requires exactly 18 mastery nodes")
	_expect(card_entries.size() == 15, "first run requires exactly 15 cards")
	_expect(items.size() == 12, "first run requires exactly 12 persistent equipment items")
	_expect(consumables.size() == 3, "first run requires exactly 3 consumables")
	_expect(archetypes.size() == 6, "first run requires exactly 6 enemy archetypes")
	_expect(variants.size() == 13, "first run requires exactly 13 normal enemy variants")
	_expect(tuning_profiles.size() == 3, "first run requires exactly 3 enemy tuning profiles")
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
	_validate_combat_resolution(player, characters)

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

	_validate_enemy_catalog(
		encounters,
		archetypes,
		variants,
		tuning_profiles,
		drop_tables,
		stage_profiles
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
		for pressure_role in room.get("enemy_tags", []):
			_expect(
				_archetype_has_role(str(pressure_role), archetypes),
				"room %s references unknown enemy pressure role %s" % [room_id, pressure_role]
			)
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
		for archetype_id in profile.get("eligible_enemy_archetypes", []):
			_expect(
				archetypes.has(archetype_id),
				"stage %s references unknown enemy archetype %s" % [stage_id, archetype_id]
			)
			_expect(
				_stage_has_enemy_variant(stage_id, str(archetype_id), variants),
				"stage %s has no variant for enemy archetype %s" % [stage_id, archetype_id]
			)
		for actor_id in profile.get("eligible_special_actors", []):
			_expect(
				special_actors.has(actor_id),
				"stage %s references unknown special actor %s" % [stage_id, actor_id]
			)
		for hazard_id in profile.get("eligible_hazards", []):
			_expect(hazards.has(hazard_id), "stage %s references unknown hazard %s" % [stage_id, hazard_id])


func _validate_combat_resolution(player: Dictionary, characters: Dictionary) -> void:
	var combat: Dictionary = player.get("combat_resolution", {})
	_expect(not combat.is_empty(), "player catalog needs combat_resolution")
	_expect(
		is_zero_approx(float(combat.get("direct_damage_variance", -1.0))),
		"first-run direct damage variance must be zero"
	)
	_expect(
		is_zero_approx(float(combat.get("baseline_random_critical_chance", -1.0))),
		"first-run baseline random critical chance must be zero"
	)
	_expect(not bool(combat.get("enemy_critical_hits", true)), "enemies cannot critical")
	_expect(
		not bool(combat.get("secondary_hits_can_critical_by_default", true)),
		"secondary hits cannot critical by default"
	)
	_expect(
		combat.get("rounding", "") == "floor_non_negative_plus_half",
		"combat rounding rule must be explicit"
	)
	var critical_multiplier := float(combat.get("default_critical_multiplier", 0.0))
	var maximum_multiplier := float(combat.get("maximum_critical_multiplier", 0.0))
	_expect(critical_multiplier > 1.0, "default critical multiplier must exceed one")
	_expect(
		critical_multiplier <= maximum_multiplier and maximum_multiplier <= 2.0,
		"critical multiplier must respect the first-run cap"
	)

	var combat_verb_owners: Dictionary = {}
	for character_id in characters:
		var character: Dictionary = characters[character_id]
		for field in ["basic_attack", "heavy_attack"]:
			var verb_id := str(character.get(field, ""))
			_expect(not verb_id.is_empty(), "character %s needs %s" % [character_id, field])
			if not verb_id.is_empty():
				_expect(not combat_verb_owners.has(verb_id), "duplicate combat verb %s" % verb_id)
				combat_verb_owners[verb_id] = character_id
		for skill_id in character.get("skills", []):
			var verb_id := str(skill_id)
			_expect(not verb_id.is_empty(), "character %s has an empty skill ID" % character_id)
			if not verb_id.is_empty():
				_expect(not combat_verb_owners.has(verb_id), "duplicate combat verb %s" % verb_id)
				combat_verb_owners[verb_id] = character_id

	var critical_rules := _index_entries(combat.get("critical_rules", []), "critical rule")
	_expect(critical_rules.size() == 3, "first run requires exactly 3 earned critical rules")
	var critical_rule_counts: Dictionary = {}
	for rule_id in critical_rules:
		var rule: Dictionary = critical_rules[rule_id]
		var attack_id := str(rule.get("attack_id", ""))
		_expect(
			combat_verb_owners.has(attack_id),
			"critical rule %s references unknown combat verb" % rule_id
		)
		if combat_verb_owners.has(attack_id):
			var owner_id: String = combat_verb_owners[attack_id]
			critical_rule_counts[owner_id] = int(critical_rule_counts.get(owner_id, 0)) + 1
		_expect(
			rule.get("trigger", "") == "earned_condition",
			"critical rule %s must be earned, not random" % rule_id
		)
		var requirements: Array = rule.get("requires", [])
		_expect(
			not requirements.is_empty(),
			"critical rule %s needs at least one condition" % rule_id
		)
		for requirement in requirements:
			_expect(not str(requirement).is_empty(), "critical rule %s has an empty condition" % rule_id)
		for consumed_condition in rule.get("consumes", []):
			_expect(
				consumed_condition in requirements,
				"critical rule %s consumes an undeclared condition" % rule_id
			)
	for character_id in characters:
		_expect(
			int(critical_rule_counts.get(character_id, 0)) == 1,
			"character %s needs exactly one first-run critical rule" % character_id
		)


func _validate_enemy_catalog(
		encounters: Dictionary,
		archetypes: Dictionary,
		variants: Dictionary,
		tuning_profiles: Dictionary,
		drop_tables: Dictionary,
		stage_profiles: Dictionary
) -> void:
	var damage_policy: Dictionary = encounters.get("damage_policy", {})
	_expect(
		is_zero_approx(float(damage_policy.get("per_hit_variance", -1.0))),
		"enemy per-hit damage variance must be zero"
	)
	_expect(
		not bool(damage_policy.get("enemy_critical_hits", true)),
		"enemy catalog must disable critical hits"
	)
	_expect(
		_is_exact_int(damage_policy.get("normal_damage", 0), 1),
		"normal enemy damage must be integer one"
	)

	var tuning_by_stage: Dictionary = {}
	for tuning_id in tuning_profiles:
		var tuning: Dictionary = tuning_profiles[tuning_id]
		_validate_enemy_tuning_profile(tuning_id, tuning, stage_profiles)
		var stage_id := str(tuning.get("stage_id", ""))
		_expect(
			not tuning_by_stage.has(stage_id),
			"stage %s has duplicate enemy tuning profiles" % stage_id
		)
		tuning_by_stage[stage_id] = tuning_id

	for archetype_id in archetypes:
		var archetype: Dictionary = archetypes[archetype_id]
		var reference_stats: Dictionary = archetype.get("reference_stats", {})
		_expect(
			not str(archetype.get("behavior_owner", "")).is_empty(),
			"enemy archetype %s needs a behavior owner" % archetype_id
		)
		_expect(
			not Array(archetype.get("roles", [])).is_empty(),
			"enemy archetype %s needs pressure roles" % archetype_id
		)
		var room_requirements: Variant = archetype.get("room_requirements", {})
		_expect(
			room_requirements is Dictionary and not room_requirements.is_empty(),
			"enemy archetype %s needs room requirements" % archetype_id
		)
		_expect(float(reference_stats.get("health", 0.0)) > 0.0, "%s needs base health" % archetype_id)
		_expect(
			_is_exact_int(reference_stats.get("damage", 0), 1),
			"%s base damage must be integer one" % archetype_id
		)

	for variant_id in variants:
		_validate_enemy_variant(
			variant_id,
			variants[variant_id],
			archetypes,
			tuning_profiles,
			drop_tables,
			stage_profiles
		)

	for stage_id in stage_profiles:
		_expect(
			tuning_by_stage.has(stage_id),
			"stage %s needs exactly one enemy tuning profile" % stage_id
		)


func _validate_enemy_tuning_profile(
		tuning_id: String,
		tuning: Dictionary,
		stage_profiles: Dictionary
) -> void:
	var stage_id := str(tuning.get("stage_id", ""))
	_expect(stage_profiles.has(stage_id), "enemy tuning %s has unknown stage" % tuning_id)
	for range_id in [
		"health_ratio",
		"warning_ratio",
		"active_ratio",
		"recovery_ratio",
		"cadence_ratio",
		"speed_or_range_ratio",
	]:
		_validate_numeric_range(tuning.get(range_id, []), "enemy tuning %s %s" % [tuning_id, range_id])
	var allowed_damage: Array = tuning.get("allowed_damage", [])
	_expect(
		allowed_damage.size() == 1 and _is_exact_int(allowed_damage[0], 1),
		"enemy tuning %s must allow only integer one damage" % tuning_id
	)
	_expect(
		float(tuning.get("max_stagger_capacity_ratio", 0.0)) >= 1.0,
		"enemy tuning %s needs a valid stagger cap" % tuning_id
	)


func _validate_enemy_variant(
		variant_id: String,
		variant: Dictionary,
		archetypes: Dictionary,
		tuning_profiles: Dictionary,
		drop_tables: Dictionary,
		stage_profiles: Dictionary
) -> void:
	var archetype_id := str(variant.get("archetype_id", ""))
	var stage_id := str(variant.get("stage_id", ""))
	var tuning_id := str(variant.get("tuning_profile_id", ""))
	_expect(archetypes.has(archetype_id), "variant %s has unknown archetype" % variant_id)
	_expect(stage_profiles.has(stage_id), "variant %s has unknown stage" % variant_id)
	_expect(tuning_profiles.has(tuning_id), "variant %s has unknown tuning profile" % variant_id)
	_expect(
		drop_tables.has(variant.get("drop_table", "")),
		"variant %s references unknown drop table" % variant_id
	)
	_expect(not str(variant.get("visual_key", "")).is_empty(), "variant %s needs visual_key" % variant_id)
	_expect(
		not str(variant.get("tuning_trait", "")).is_empty(),
		"variant %s needs a tuning trait" % variant_id
	)
	_expect(int(variant.get("budget", 0)) > 0, "variant %s needs positive budget" % variant_id)
	if not archetypes.has(archetype_id) or not tuning_profiles.has(tuning_id):
		return

	var archetype: Dictionary = archetypes[archetype_id]
	var tuning: Dictionary = tuning_profiles[tuning_id]
	var reference_stats: Dictionary = archetype.get("reference_stats", {})
	var stats: Dictionary = variant.get("stats", {})
	_expect(tuning.get("stage_id", "") == stage_id, "variant %s tuning/stage mismatch" % variant_id)
	if stage_profiles.has(stage_id):
		var stage_profile: Dictionary = stage_profiles[stage_id]
		_expect(
			archetype_id in stage_profile.get("eligible_enemy_archetypes", []),
			"variant %s archetype is not eligible for its stage" % variant_id
		)
	for stat_id in reference_stats:
		_expect(stats.has(stat_id), "variant %s is missing stat %s" % [variant_id, stat_id])
	_expect(float(stats.get("health", 0.0)) > 0.0, "variant %s needs positive health" % variant_id)
	var damage_value: Variant = stats.get("damage", 0)
	_expect(_is_integer_value(damage_value), "variant %s damage must be an integer" % variant_id)
	var damage := int(damage_value) if _is_integer_value(damage_value) else 0
	_expect(
		_array_has_int(tuning.get("allowed_damage", []), damage),
		"variant %s damage is not allowed" % variant_id
	)

	for floor_id in Dictionary(archetype.get("safety_floors", {})):
		_expect(stats.has(floor_id), "variant %s is missing safety stat %s" % [variant_id, floor_id])
		if stats.has(floor_id):
			_expect(
				float(stats[floor_id]) + FLOAT_EPSILON >= float(archetype["safety_floors"][floor_id]),
				"variant %s violates %s safety floor" % [variant_id, floor_id]
			)
	for ceiling_id in Dictionary(archetype.get("safety_ceilings", {})):
		_expect(stats.has(ceiling_id), "variant %s is missing safety stat %s" % [variant_id, ceiling_id])
		if stats.has(ceiling_id):
			_expect(
				float(stats[ceiling_id]) - FLOAT_EPSILON
				<= float(archetype["safety_ceilings"][ceiling_id]),
				"variant %s violates %s safety ceiling" % [variant_id, ceiling_id]
			)

	_validate_stat_ratio(variant_id, "health", stats, reference_stats, tuning.get("health_ratio", []))
	_validate_stat_ratio(variant_id, "warning", stats, reference_stats, tuning.get("warning_ratio", []))
	_validate_stat_ratio(variant_id, "active", stats, reference_stats, tuning.get("active_ratio", []))
	for recovery_id in ["recovery", "post_shot_recovery"]:
		_validate_stat_ratio(
			variant_id, recovery_id, stats, reference_stats, tuning.get("recovery_ratio", [])
		)
	_validate_stat_ratio(
		variant_id, "fire_interval", stats, reference_stats, tuning.get("cadence_ratio", [])
	)
	for movement_id in ["move_speed", "charge_speed", "projectile_speed", "range"]:
		_validate_stat_ratio(
			variant_id,
			movement_id,
			stats,
			reference_stats,
			tuning.get("speed_or_range_ratio", [])
		)
	_expect(
		float(stats.get("stagger_capacity_ratio", 1.0))
		<= float(tuning.get("max_stagger_capacity_ratio", 0.0)) + FLOAT_EPSILON,
		"variant %s exceeds stagger capacity cap" % variant_id
	)


func _validate_numeric_range(value: Variant, label: String) -> void:
	_expect(value is Array and value.size() == 2, "%s must be a two-value range" % label)
	if not value is Array or value.size() != 2:
		return
	_expect(float(value[0]) > 0.0 and float(value[0]) <= float(value[1]), "%s is invalid" % label)


func _validate_stat_ratio(
		variant_id: String,
		stat_id: String,
		stats: Dictionary,
		reference_stats: Dictionary,
		bounds_value: Variant
) -> void:
	if not stats.has(stat_id) or not reference_stats.has(stat_id):
		return
	if not bounds_value is Array or bounds_value.size() != 2:
		return
	var reference := float(reference_stats[stat_id])
	_expect(reference > 0.0, "archetype reference %s must be positive" % stat_id)
	if reference <= 0.0:
		return
	var ratio := float(stats[stat_id]) / reference
	_expect(
		ratio + FLOAT_EPSILON >= float(bounds_value[0])
		and ratio - FLOAT_EPSILON <= float(bounds_value[1]),
		"variant %s %s ratio %.3f is outside tuning bounds" % [variant_id, stat_id, ratio]
	)


func _archetype_has_role(role: String, archetypes: Dictionary) -> bool:
	for archetype_id in archetypes:
		if role in archetypes[archetype_id].get("roles", []):
			return true
	return false


func _stage_has_enemy_variant(stage_id: String, archetype_id: String, variants: Dictionary) -> bool:
	for variant_id in variants:
		var variant: Dictionary = variants[variant_id]
		if variant.get("stage_id", "") == stage_id and variant.get("archetype_id", "") == archetype_id:
			return true
	return false


func _array_has_int(values: Array, expected: int) -> bool:
	for value in values:
		if _is_exact_int(value, expected):
			return true
	return false


func _is_exact_int(value: Variant, expected: int) -> bool:
	return _is_integer_value(value) and int(value) == expected


func _is_integer_value(value: Variant) -> bool:
	return (
		(value is int or value is float)
		and is_equal_approx(float(value), round(float(value)))
	)


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
