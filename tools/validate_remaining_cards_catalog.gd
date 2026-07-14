extends SceneTree

const EXPECTED: Dictionary = {
	"kinetic_refund": {
		"path": "res://data/cards/kinetic_refund.tres",
		"rarity": &"common",
		"trigger": &"heavy_or_skill_multi_target_completed",
		"effect_types": [&"reduce_all_skill_cooldowns"],
		"internal_cooldown": 3.0,
	},
	"second_wind": {
		"path": "res://data/cards/second_wind.tres",
		"rarity": &"common",
		"trigger": &"required_room_encounter_cleared_without_damage",
		"effect_types": [&"heal_player"],
		"internal_cooldown": 0.0,
	},
	"last_stand": {
		"path": "res://data/cards/last_stand.tres",
		"rarity": &"legendary",
		"trigger": &"damage_left_one_health",
		"effect_types": [&"grant_invulnerability"],
		"internal_cooldown": 0.0,
	},
	"treasure_instinct": {
		"path": "res://data/cards/treasure_instinct.tres",
		"rarity": &"common",
		"trigger": &"optional_route_chest_claimed",
		"effect_types": [&"request_reward_preview_replacement"],
		"internal_cooldown": 0.0,
	},
}

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_cards()
	_validate_malformed_effects()
	_finish()


func _validate_cards() -> void:
	for card_id in EXPECTED:
		var expected: Dictionary = EXPECTED[card_id]
		var card := load(String(expected["path"])) as CardDefinition
		_expect(card != null, "card '%s' should load" % card_id)
		if card == null:
			continue
		_expect(String(card.id) == card_id, "card '%s' should preserve its canonical ID" % card_id)
		_expect(card.rarity == expected["rarity"], "card '%s' should use its authored rarity" % card_id)
		_expect(card.trigger == expected["trigger"], "card '%s' should use its domain trigger" % card_id)
		_expect(card.compatibility == [&"shared"], "card '%s' should be shared" % card_id)
		_expect(card.max_stacks == 1, "card '%s' should have one stack" % card_id)
		_expect(
			is_equal_approx(card.internal_cooldown, float(expected["internal_cooldown"])),
			"card '%s' should use its authored internal cooldown" % card_id
		)
		_expect(card.validate_definition().is_empty(), "card '%s' should validate" % card_id)
		var effect_types: Array[StringName] = []
		for effect in card.effects:
			effect_types.append(effect.effect_type)
		_expect(effect_types == expected["effect_types"], "card '%s' should expose exact effects" % card_id)

	var kinetic := load(String(EXPECTED["kinetic_refund"]["path"])) as CardDefinition
	_expect(is_equal_approx(kinetic.effects[0].seconds, 1.0), "Kinetic Refund should trim one second")
	var second_wind := load(String(EXPECTED["second_wind"]["path"])) as CardDefinition
	_expect(second_wind.effects[0].health == 1, "Second Wind should heal one")
	var last_stand := load(String(EXPECTED["last_stand"]["path"])) as CardDefinition
	_expect(is_equal_approx(last_stand.effects[0].seconds, 1.2), "Last Stand should grant 1.2 seconds")
	var treasure := load(String(EXPECTED["treasure_instinct"]["path"])) as CardDefinition
	_expect(treasure.effects[0].choice_count == 1, "Treasure Instinct should request one choice")
	_expect(
		treasure.effects[0].reward_pool == &"compatible_equipment_or_forge",
		"Treasure Instinct should use the compatible equipment/forge pool"
	)


func _validate_malformed_effects() -> void:
	var cooldown := CardEffectDefinition.new()
	cooldown.effect_type = &"reduce_all_skill_cooldowns"
	_expect(not cooldown.validate_definition().is_empty(), "cooldown reduction should reject zero seconds")
	var heal := CardEffectDefinition.new()
	heal.effect_type = &"heal_player"
	_expect(not heal.validate_definition().is_empty(), "heal should reject zero health")
	var replacement := CardEffectDefinition.new()
	replacement.effect_type = &"request_reward_preview_replacement"
	_expect(not replacement.validate_definition().is_empty(), "replacement should require a reward pool")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("REMAINING_CARDS_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
