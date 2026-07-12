extends SceneTree

const CATALOG := preload("res://data/forge/forge_catalog.tres")

var _failures: Array[String] = []


func _initialize() -> void:
	for error in CATALOG.validate_catalog():
		_failures.append(error)
	_validate_offers()
	_validate_build_effects()
	_finish()


func _validate_offers() -> void:
	for slot_id in EquipmentDefinition.PERSISTENT_SLOTS:
		var first := ForgeOfferService.build_offer(CATALOG, slot_id, 701, 1, &"fixture_item", 0)
		var replay := ForgeOfferService.build_offer(CATALOG, slot_id, 701, 1, &"fixture_item", 0)
		_expect(first.size() == 3, "slot '%s' should produce three forge choices" % slot_id)
		_expect(first == replay, "slot '%s' forge offer should reproduce exactly" % slot_id)
		_expect(_unique(first).size() == 3, "slot '%s' forge offer should not repeat" % slot_id)
		if not first.is_empty():
			var replacement := ForgeOfferService.build_offer(
				CATALOG, slot_id, 701, 1, &"fixture_item", 1, first[0]
			)
			_expect(replacement.size() == 3, "replacement offer for '%s' should remain complete" % slot_id)
			_expect(not replacement.has(first[0]), "replacement offer should exclude the current affix")


func _validate_build_effects() -> void:
	var base := {
		"direct_damage_multiplier": 1.0,
		"skill_cooldown_multiplier": 1.0,
		"move_speed": 200.0,
		"air_acceleration": 1200.0,
	}
	var effects: Array = []
	for affix_id in [&"forge_force", &"forge_tempo", &"forge_stride"]:
		var affix := CATALOG.get_affix(affix_id)
		for effect in affix.build_effects:
			effects.append(effect)
	var build := PlayerBuild.resolve(base, effects)
	_expect(build.is_valid(), "forge build effects should resolve through PlayerBuild")
	_expect(is_equal_approx(build.get_stat(&"direct_damage_multiplier"), 1.1), "Force should multiply damage")
	_expect(is_equal_approx(build.get_stat(&"skill_cooldown_multiplier"), 0.92), "Tempo should multiply skill cooldown")
	_expect(is_equal_approx(build.get_stat(&"move_speed"), 210.0), "Stride should add move speed")


func _unique(values: Array[StringName]) -> Dictionary:
	var unique: Dictionary = {}
	for value in values:
		unique[value] = true
	return unique


func _finish() -> void:
	if _failures.is_empty():
		print("FORGE_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
