extends SceneTree

const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const TEST_PATH := "user://cardborne_profile_validation.json"
const MIGRATION_PATH := "user://cardborne_profile_migration_validation.json"

var _failures: Array[String] = []


func _initialize() -> void:
	_cleanup(TEST_PATH)
	_cleanup(MIGRATION_PATH)
	_validate_round_trip_and_backup()
	_validate_legacy_migration()
	_cleanup(TEST_PATH)
	_cleanup(MIGRATION_PATH)
	_finish()


func _validate_round_trip_and_backup() -> void:
	var service := ProfileSaveService.new(EQUIPMENT_CATALOG, MASTERY_CATALOG, TEST_PATH)
	var data := ProfileData.new()
	var commands := ProfileCommandService.new(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	commands.grant_material(data, "rusted_scrap", 17)
	commands.purchase_equipment(data, &"patched_mail")
	commands.equip_item(data, &"warrior", &"armor", &"patched_mail")
	commands.purchase_mastery(data, &"warrior", &"warrior_broad_guard")
	var first_snapshot := data.to_dictionary()
	var first_save := service.save(data)
	_expect(
		bool(first_save.get("ok", false)),
		"first profile save should succeed: %s" % first_save.get("message", "no message")
	)
	var loaded := service.load_or_create()
	_expect(bool(loaded.get("ok", false)), "saved profile should load")
	_expect(loaded.get("source") == "primary", "valid primary profile should win")
	if loaded.get("data") is ProfileData:
		_expect(loaded["data"].to_dictionary() == first_snapshot, "profile round trip should preserve exact state")

	commands.grant_material(data, "rusted_scrap", 2)
	var second_save := service.save(data)
	_expect(
		bool(second_save.get("ok", false)),
		"second save should rotate a valid backup: %s" % second_save.get("message", "no message")
	)
	_write_text(TEST_PATH, "{ definitely not json")
	var recovered := service.load_or_create()
	_expect(bool(recovered.get("ok", false)), "corrupt primary should recover")
	_expect(recovered.get("source") == "backup", "corrupt primary should use last valid backup")
	_expect(bool(recovered.get("recovered", false)), "backup recovery should be explicit")
	if recovered.get("data") is ProfileData:
		_expect(
			recovered["data"].to_dictionary() == first_snapshot,
			"backup recovery should restore the previous valid profile"
		)
	var reread := service.load_or_create()
	_expect(reread.get("source") == "primary", "backup recovery should rewrite a valid primary")


func _validate_legacy_migration() -> void:
	var legacy := {
		"materials": {"rusted_scrap": 9},
		"owned_equipment": ["bell_hammer"],
		"loadout": {
			"weapon": "bell_hammer",
			"armor": "traveler_jacket",
			"charm": "",
			"relic": "",
			"consumable": "small_potion",
		},
		"mastery_unlocks": {"warrior": {"warrior_broad_guard": true}},
		"durable_unlocks": ["legacy_room_set"],
		"settings": {"screen_shake": false},
	}
	_write_text(MIGRATION_PATH, JSON.stringify(legacy, "\t", true))
	var service := ProfileSaveService.new(EQUIPMENT_CATALOG, MASTERY_CATALOG, MIGRATION_PATH)
	var migrated := service.load_or_create()
	_expect(bool(migrated.get("ok", false)), "legacy profile should migrate")
	_expect(bool(migrated.get("migrated", false)), "migration should be reported")
	if migrated.get("data") is ProfileData:
		var data: ProfileData = migrated["data"]
		_expect(data.schema_version == ProfileData.CURRENT_SCHEMA_VERSION, "migration should set current schema")
		_expect(data.owned_equipment.has("bell_hammer"), "migration should preserve known equipment")
		_expect(data.loadouts["warrior"]["weapon"] == "bell_hammer", "migration should map compatible legacy loadout")
		_expect(data.settings["screen_shake"] == false, "migration should preserve known settings")
	var rewritten: Variant = JSON.parse_string(FileAccess.get_file_as_string(MIGRATION_PATH))
	_expect(
		rewritten is Dictionary and int(rewritten.get("schema_version", 0)) == ProfileData.CURRENT_SCHEMA_VERSION,
		"migrated profile should be rewritten as schema v1"
	)


func _write_text(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("unable to write persistence fixture '%s'" % path)
		return
	file.store_string(contents)
	file.flush()


func _cleanup(path: String) -> void:
	for suffix in ["", ".backup", ".tmp", ".corrupt"]:
		var candidate := "%s%s" % [path, suffix]
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _finish() -> void:
	if _failures.is_empty():
		print("PROFILE_PERSISTENCE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
