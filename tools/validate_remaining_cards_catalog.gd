extends SceneTree

const CATALOG := preload("res://data/cards/card_catalog.tres")
const EXPECTED: Dictionary = {
	"dash_wake": {
		"path": "res://data/cards/dash_wake.tres",
		"rarity": &"common",
		"trigger": &"dash_completed",
		"effect_types": [&"spawn_damage_trail"],
		"internal_cooldown": 0.0,
		"max_stacks": 2,
	},
	"aerial_opener": {
		"path": "res://data/cards/aerial_opener.tres",
		"rarity": &"common",
		"trigger": &"first_attack_after_extra_jump",
		"effect_types": [&"add_damage", &"add_stagger"],
		"internal_cooldown": 0.0,
		"max_stacks": 1,
	},
	"perfect_punish": {
		"path": "res://data/cards/perfect_punish.tres",
		"rarity": &"rare",
		"trigger": &"hit_target_in_recovery",
		"effect_types": [&"add_damage"],
		"internal_cooldown": 2.0,
		"max_stacks": 1,
	},
	"second_wind": {
		"path": "res://data/cards/second_wind.tres",
		"rarity": &"common",
		"trigger": &"required_room_encounter_cleared_without_damage",
		"effect_types": [&"heal_player"],
		"internal_cooldown": 0.0,
		"max_stacks": 1,
	},
	"last_stand": {
		"path": "res://data/cards/last_stand.tres",
		"rarity": &"legendary",
		"trigger": &"damage_left_one_health",
		"effect_types": [&"grant_invulnerability"],
		"internal_cooldown": 0.0,
		"max_stacks": 1,
	},
}

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_cards()
	_finish()


func _validate_cards() -> void:
	_expect(CATALOG.validate_catalog().is_empty(), "production card catalog should validate")
	_expect(CATALOG.cards.size() == EXPECTED.size(), "catalog should expose only five live cards")
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
		_expect(
			card.max_stacks == int(expected["max_stacks"]),
			"card '%s' should use its authored stack cap" % card_id
		)
		_expect(
			is_equal_approx(card.internal_cooldown, float(expected["internal_cooldown"])),
			"card '%s' should use its authored internal cooldown" % card_id
		)
		_expect(card.validate_definition().is_empty(), "card '%s' should validate" % card_id)
		var effect_types: Array[StringName] = []
		for effect in card.effects:
			effect_types.append(effect.effect_type)
		_expect(effect_types == expected["effect_types"], "card '%s' should expose exact effects" % card_id)
		_expect(CATALOG.get_card(card.id) == card, "catalog should own card '%s'" % card_id)

	var dash := load(String(EXPECTED["dash_wake"]["path"])) as CardDefinition
	_expect(dash.effects[0].damage_by_stack == PackedInt32Array([1, 2]), "Dash Wake should scale by stack")
	var aerial := load(String(EXPECTED["aerial_opener"]["path"])) as CardDefinition
	_expect(aerial.effects[0].damage == 1 and aerial.effects[1].stagger == 20, "Aerial Opener should expose exact bonuses")
	var second_wind := load(String(EXPECTED["second_wind"]["path"])) as CardDefinition
	_expect(second_wind.effects[0].health == 1, "Second Wind should heal one")
	var last_stand := load(String(EXPECTED["last_stand"]["path"])) as CardDefinition
	_expect(is_equal_approx(last_stand.effects[0].seconds, 1.2), "Last Stand should grant 1.2 seconds")


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
