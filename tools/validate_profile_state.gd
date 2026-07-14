extends SceneTree

const ProfileStateScript = preload("res://scripts/autoload/ProfileState.gd")
const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const CHARACTER_CATALOG := preload("res://data/characters/character_catalog.tres")
const PROGRESSION_CATALOG := preload(
	"res://data/equipment/equipment_progression_catalog.tres"
)
const ROLLBACK_PATH := "user://profile_state_rollback_validation.json"

var _failures: Array[String] = []


func _initialize() -> void:
	var profile := ProfileStateScript.new()
	profile.initialize_for_tests(
		EQUIPMENT_CATALOG, MASTERY_CATALOG, "", false, PROGRESSION_CATALOG
	)
	_validate_defaults(profile)
	_validate_material_and_equipment_commands(profile)
	_validate_mastery_commands(profile)
	_validate_discovery_idempotency(profile)
	_validate_settings_and_snapshot(profile)
	_validate_base_loadouts(profile)
	profile.free()
	_validate_v2_progression_commands()
	_validate_failed_save_rolls_back_memory()
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


func _validate_v2_progression_commands() -> void:
	var profile := ProfileStateScript.new()
	profile.initialize_for_tests(
		EQUIPMENT_CATALOG, MASTERY_CATALOG, "", false, PROGRESSION_CATALOG
	)
	var unlock: Dictionary = profile.unlock_blueprint(&"hunting_spear", &"fixture:profile:spear")
	_expect(bool(unlock.get("ok", false)), "profile boundary should unlock a blueprint")
	profile.grant_material("rusted_scrap", 3)
	profile.grant_material("common_timber", 4)
	var craft: Dictionary = profile.craft_equipment(&"hunting_spear")
	_expect(bool(craft.get("ok", false)), "profile boundary should craft unlocked equipment")
	_expect(
		bool(profile.equip_hero_item(&"melee", &"hunting_spear").get("ok", false)),
		"profile boundary should equip crafted equipment"
	)
	var preparation: Dictionary = profile.get_preparation_snapshot()
	_expect(preparation["loadout"]["melee"] == "hunting_spear", "preparation snapshot should expose equipped melee")
	_expect(preparation["slots"].size() == 4, "preparation snapshot should expose four equipment slots")
	profile.free()


func _validate_failed_save_rolls_back_memory() -> void:
	_cleanup_rollback_fixture()
	var blocked_temp_path := ProjectSettings.globalize_path("%s.tmp" % ROLLBACK_PATH)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(blocked_temp_path)
	_expect(mkdir_error == OK, "rollback fixture should block the staging file path")
	var profile := ProfileStateScript.new()
	profile.initialize_for_tests(
		EQUIPMENT_CATALOG,
		MASTERY_CATALOG,
		ROLLBACK_PATH,
		false,
		PROGRESSION_CATALOG
	)
	var before := profile.get_profile_snapshot()
	var result: Dictionary = profile.unlock_blueprint(
		&"hunting_spear",
		&"fixture:rollback:spear"
	)
	_expect(not bool(result.get("ok", true)), "failed persistence should reject the command")
	_expect(result.get("code") == "persistence_failed", "failed persistence should expose its reason")
	_expect(
		profile.get_profile_snapshot() == before,
		"failed persistence must leave the live in-memory profile unchanged"
	)
	profile.free()
	_cleanup_rollback_fixture()


func _cleanup_rollback_fixture() -> void:
	for suffix in ["", ".backup", ".tmp", ".corrupt"]:
		var path := ProjectSettings.globalize_path("%s%s" % [ROLLBACK_PATH, suffix])
		if DirAccess.dir_exists_absolute(path):
			DirAccess.remove_absolute(path)
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


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
