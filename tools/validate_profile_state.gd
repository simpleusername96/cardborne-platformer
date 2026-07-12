extends SceneTree

const ProfileStateScript = preload("res://scripts/autoload/ProfileState.gd")
const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const CHARACTER_CATALOG := preload("res://data/characters/character_catalog.tres")

var _failures: Array[String] = []


func _initialize() -> void:
	var profile := ProfileStateScript.new()
	profile.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_validate_defaults(profile)
	_validate_material_and_equipment_commands(profile)
	_validate_mastery_commands(profile)
	_validate_discovery_idempotency(profile)
	_validate_settings_and_snapshot(profile)
	_validate_base_loadouts(profile)
	profile.free()
	_finish()


func _validate_defaults(profile: Node) -> void:
	for item_id in ["iron_cleaver", "field_bow", "rust_knives", "traveler_jacket"]:
		_expect(profile.owns_equipment(item_id), "starting equipment '%s' should be owned" % item_id)
	_expect(profile.get_loadout("warrior")["weapon"] == "iron_cleaver", "Warrior should start with Iron Cleaver")
	_expect(profile.get_loadout("archer")["weapon"] == "field_bow", "Archer should start with Field Bow")
	_expect(profile.get_loadout("assassin")["weapon"] == "rust_knives", "Assassin should start with Rust Knives")


func _validate_material_and_equipment_commands(profile: Node) -> void:
	_expect(profile.grant_material("rusted_scrap", 5), "material grant should succeed")
	var purchase: Dictionary = profile.purchase_equipment(&"patched_mail")
	_expect(bool(purchase.get("ok", false)), "affordable equipment purchase should succeed")
	_expect(profile.get_material_count("rusted_scrap") == 0, "equipment purchase should charge exactly once")
	_expect(not bool(profile.purchase_equipment(&"patched_mail").get("ok", true)), "owned equipment purchase should fail")
	var equip: Dictionary = profile.equip_item(&"warrior", &"armor", &"patched_mail")
	_expect(bool(equip.get("ok", false)), "owned compatible armor should equip")
	_expect(
		not bool(profile.equip_item(&"archer", &"weapon", &"iron_cleaver").get("ok", true)),
		"incompatible character weapon should be rejected"
	)
	var warrior: CharacterProfile = CHARACTER_CATALOG.get_profile_by_id("warrior")
	var preview: PlayerBuildSnapshot = profile.preview_build(warrior)
	_expect(preview.is_valid(), "equipment preview should produce a valid build")
	_expect_close(preview.get_stat(&"max_health"), warrior.max_health + 1.0, "Patched Mail should add one health")
	_expect_close(preview.get_stat(&"move_speed"), warrior.move_speed - 8.0, "Patched Mail should reduce move speed")
	_expect(preview.get_source_breakdown().has("patched_mail"), "equipment source should remain visible in build breakdown")


func _validate_mastery_commands(profile: Node) -> void:
	_expect(profile.grant_material("rusted_scrap", 12), "mastery material grant should succeed")
	var locked: Dictionary = profile.purchase_mastery(&"warrior", &"warrior_steady_feet")
	_expect(not bool(locked.get("ok", true)), "middle mastery should reject missing prerequisite")
	_expect(profile.get_material_count("rusted_scrap") == 12, "rejected mastery should not charge")
	_expect(
		bool(profile.purchase_mastery(&"warrior", &"warrior_broad_guard").get("ok", false)),
		"root mastery should purchase"
	)
	_expect(
		bool(profile.purchase_mastery(&"warrior", &"warrior_steady_feet").get("ok", false)),
		"unlocked middle mastery should purchase"
	)
	_expect(profile.get_material_count("rusted_scrap") == 0, "mastery purchases should use documented costs")
	_expect(profile.has_mastery("warrior", "warrior_steady_feet"), "mastery should be character-scoped")
	_expect(not profile.has_mastery("archer", "warrior_steady_feet"), "mastery should not leak to another character")
	var respec: Dictionary = profile.respec_character(&"warrior")
	_expect(bool(respec.get("ok", false)), "development respec should succeed")
	_expect(profile.get_material_count("rusted_scrap") == 12, "respec should refund exact purchase costs")
	_expect(profile.get_mastery_unlocks("warrior").is_empty(), "respec should clear only the selected character")


func _validate_discovery_idempotency(profile: Node) -> void:
	var first: Dictionary = profile.discover_equipment(&"bell_hammer", &"fixture:cache:1")
	_expect(bool(first.get("ok", false)) and profile.owns_equipment("bell_hammer"), "first discovery should unlock equipment")
	var before_duplicate: int = profile.get_material_count("rusted_scrap")
	var duplicate: Dictionary = profile.discover_equipment(&"bell_hammer", &"fixture:cache:1")
	_expect(bool(duplicate.get("duplicate", false)), "replayed discovery transaction should be duplicate")
	_expect(profile.get_material_count("rusted_scrap") == before_duplicate, "replayed discovery should grant no salvage")
	var second_source: Dictionary = profile.discover_equipment(&"bell_hammer", &"fixture:cache:2")
	_expect(bool(second_source.get("ok", false)), "a distinct duplicate discovery should settle")
	_expect(profile.get_material_count("rusted_scrap") == before_duplicate + 4, "owned Bell Hammer should salvage to four scrap")


func _validate_settings_and_snapshot(profile: Node) -> void:
	_expect(profile.set_setting("screen_shake", false), "known setting should update")
	_expect(not profile.set_setting("unknown_setting", true), "unknown setting should fail")
	_expect(not profile.set_setting("music_volume", 1.5), "out-of-range volume should fail")
	var snapshot: Dictionary = profile.get_profile_snapshot()
	snapshot["materials"]["rusted_scrap"] = 999
	snapshot["settings"]["screen_shake"] = true
	_expect(profile.get_material_count("rusted_scrap") != 999, "profile snapshot materials must be isolated")
	_expect(profile.get_setting("screen_shake", true) == false, "profile snapshot settings must be isolated")


func _validate_base_loadouts(profile: Node) -> void:
	for character in CHARACTER_CATALOG.profiles:
		var snapshot: Dictionary = profile.get_character_loadout_snapshot(character)
		_expect(bool(snapshot.get("ok", false)), "base loadout for '%s' should resolve" % character.id)
		_expect(snapshot["validation_errors"].is_empty(), "base loadout for '%s' should have no build errors" % character.id)


func _finish() -> void:
	if _failures.is_empty():
		print("PROFILE_STATE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _expect_close(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		_failures.append("%s; expected %s, got %s." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
