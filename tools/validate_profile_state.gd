extends SceneTree

const ProfileStateScript = preload("res://scripts/autoload/ProfileState.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var profile := ProfileStateScript.new()
	_validate_materials(profile)
	_validate_equipment(profile)
	_validate_mastery_and_unlocks(profile)
	_validate_settings_and_snapshot(profile)
	profile.free()

	if _failures.is_empty():
		print("PROFILE_STATE_VALIDATION_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_materials(profile: Node) -> void:
	_expect(profile.grant_material("stone", 5), "positive material grant should succeed")
	_expect(profile.get_material_count("stone") == 5, "material grant should update count")
	_expect(not profile.spend_material("stone", 6), "overspend should fail")
	_expect(profile.spend_material("stone", 2), "affordable spend should succeed")
	_expect(profile.get_material_count("stone") == 3, "material spend should update count")
	_expect(not profile.grant_material("", 1), "blank material id should fail")


func _validate_equipment(profile: Node) -> void:
	_expect(profile.grant_equipment("iron_blade"), "new equipment should be granted")
	_expect(not profile.grant_equipment("iron_blade"), "duplicate equipment should be rejected")
	_expect(profile.set_loadout_item("weapon", "iron_blade"), "owned equipment should equip")
	_expect(not profile.set_loadout_item("armor", "missing_armor"), "unowned equipment should not equip")
	_expect(not profile.set_loadout_item("unknown", ""), "unknown slot should fail")
	var loadout: Dictionary = profile.get_loadout()
	loadout["weapon"] = "mutated_copy"
	_expect(profile.get_loadout()["weapon"] == "iron_blade", "loadout getter must return a copy")


func _validate_mastery_and_unlocks(profile: Node) -> void:
	_expect(profile.unlock_mastery("warrior", "guard_counter"), "new mastery should unlock")
	_expect(not profile.unlock_mastery("warrior", "guard_counter"), "duplicate mastery should fail")
	_expect(profile.has_mastery("warrior", "guard_counter"), "mastery lookup should be character-scoped")
	_expect(not profile.has_mastery("archer", "guard_counter"), "mastery must not leak between characters")
	_expect(profile.unlock_content("elite_rooms"), "new content should unlock")
	_expect(not profile.unlock_content("elite_rooms"), "duplicate content unlock should fail")


func _validate_settings_and_snapshot(profile: Node) -> void:
	_expect(profile.set_setting("screen_shake", false), "known setting should update")
	_expect(not profile.set_setting("unknown_setting", true), "unknown setting should fail")
	_expect(not profile.set_setting("music_volume", 1.5), "out-of-range volume should fail")
	_expect(not profile.set_setting("damage_flash", "yes"), "setting type mismatch should fail")
	var snapshot: Dictionary = profile.get_profile_snapshot()
	snapshot["materials"]["stone"] = 999
	snapshot["settings"]["screen_shake"] = true
	_expect(profile.get_material_count("stone") == 3, "snapshot materials must be isolated")
	_expect(profile.get_setting("screen_shake", true) == false, "snapshot settings must be isolated")
	profile.reset_to_defaults()
	_expect(profile.get_material_count("stone") == 0, "profile reset should clear materials")
	_expect(profile.get_setting("screen_shake", false) == true, "profile reset should restore settings")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
