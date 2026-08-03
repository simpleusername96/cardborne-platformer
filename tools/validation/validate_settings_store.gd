extends SceneTree

const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var store := get_root().get_node("SettingsStore") as SettingsStoreService
	_expect(AudioServer.get_bus_index("Master") == 0, "Master audio bus is missing")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "SFX audio bus is missing")
	var previous_master := store.master_volume
	var previous_sfx := store.sfx_volume
	var previous_locale := store.ui_locale
	var previous_bindings := store.control_bindings.duplicate(true)
	var previous_reduced_motion := store.reduced_motion
	store.set_master_volume(0.37)
	store.set_sfx_volume(0.61)
	store.master_volume = 1.0
	store.sfx_volume = 1.0
	store.load_settings()
	_expect(is_equal_approx(store.master_volume, 0.37), "Master volume did not survive reload")
	_expect(is_equal_approx(store.sfx_volume, 0.61), "SFX volume did not survive reload")
	store.set_ui_locale("en")
	store.load_settings()
	_expect(store.ui_locale == "en" and TranslationServer.get_locale().left(2) == "en", "English locale did not survive reload")
	_expect(tr("PAUSE_TITLE") == "Paused", "English translation catalog is available")
	_expect(store.set_control_binding(&"dash", "key:%d" % KEY_Q), "valid dash rebind was rejected")
	store.set_reduced_motion(true)
	store.load_settings()
	_expect(store.control_bindings[&"dash"] == "key:%d" % KEY_Q, "dash binding did not survive reload")
	_expect(store.reduced_motion, "reduced-motion preference did not survive reload")
	_expect(not store.set_control_binding(&"active_skill", store.control_bindings[&"dash"]), "conflicting binding was accepted")
	var legacy := ConfigFile.new()
	_expect(legacy.load(SettingsStoreService.SETTINGS_PATH) == OK, "settings file could not be prepared for legacy migration")
	legacy.set_value("gameplay", "run_difficulty", "normal")
	legacy.set_value("gameplay", "future_setting", "preserve-me")
	legacy.save(SettingsStoreService.SETTINGS_PATH)
	store.load_settings()
	var before_normal_save := ConfigFile.new()
	_expect(before_normal_save.load(SettingsStoreService.SETTINGS_PATH) == OK, "legacy settings file could not be read")
	_expect(before_normal_save.has_section_key("gameplay", "run_difficulty"), "loading alone erased the legacy difficulty before a normal save")
	store.set_reduced_motion(false)
	var migrated := ConfigFile.new()
	_expect(migrated.load(SettingsStoreService.SETTINGS_PATH) == OK, "migrated settings file could not be read")
	_expect(not migrated.has_section_key("gameplay", "run_difficulty"), "normal save retained the legacy run difficulty")
	_expect(migrated.get_value("gameplay", "future_setting", "") == "preserve-me", "normal save erased an unrelated setting")
	var malformed := ConfigFile.new()
	malformed.set_value("audio", "master", "invalid")
	malformed.set_value("audio", "sfx", Vector2.ONE)
	malformed.set_value("controls", "primary_fire", "invalid")
	malformed.set_value("controls", "dash", "key:%d" % KEY_Q)
	malformed.set_value("controls", "active_skill", "key:%d" % KEY_SHIFT)
	malformed.set_value("gameplay", "run_difficulty", "unknown")
	malformed.set_value("gameplay", "future_setting", "preserve-me")
	malformed.save(SettingsStoreService.SETTINGS_PATH)
	store.load_settings()
	_expect(store.master_volume == 1.0 and store.sfx_volume == 1.0, "malformed audio settings did not restore defaults")
	_expect(store.ui_locale == "ko" and tr("PAUSE_TITLE") == "일시정지", "missing locale restores Korean default")
	_expect(store.control_bindings[&"primary_fire"] == InputProfile.default_descriptors()[&"primary_fire"], "malformed primary binding did not restore only its default")
	_expect(store.control_bindings[&"dash"] == "key:%d" % KEY_Q, "valid sibling binding was discarded during repair")
	_expect(not store.reduced_motion, "missing reduced-motion setting restores its default")
	var repaired := ConfigFile.new()
	_expect(repaired.load(SettingsStoreService.SETTINGS_PATH) == OK, "repaired settings file could not be read")
	_expect(not repaired.has_section_key("gameplay", "run_difficulty"), "repair save retained the legacy run difficulty")
	_expect(repaired.get_value("gameplay", "future_setting", "") == "preserve-me", "repair save erased an unrelated setting")
	store.master_volume = previous_master
	store.sfx_volume = previous_sfx
	store.ui_locale = previous_locale
	store.control_bindings = previous_bindings
	store.reduced_motion = previous_reduced_motion
	store.apply_audio()
	store.apply_locale()
	store.call("_save")
	var cleaned := ConfigFile.new()
	if (
		cleaned.load(SettingsStoreService.SETTINGS_PATH) == OK
		and cleaned.has_section_key("gameplay", "future_setting")
	):
		cleaned.erase_section_key("gameplay", "future_setting")
		cleaned.save(SettingsStoreService.SETTINGS_PATH)
	if failures.is_empty():
		print("PASS: audio, locale, bindings, fixed-Hard migration, conflict, persistence, and per-key malformed fallback")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
