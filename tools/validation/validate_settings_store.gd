extends SceneTree

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
	var malformed := ConfigFile.new()
	malformed.set_value("audio", "master", "invalid")
	malformed.set_value("audio", "sfx", Vector2.ONE)
	malformed.save(SettingsStoreService.SETTINGS_PATH)
	store.load_settings()
	_expect(store.master_volume == 1.0 and store.sfx_volume == 1.0, "malformed audio settings did not restore defaults")
	_expect(store.ui_locale == "ko" and tr("PAUSE_TITLE") == "일시정지", "missing locale restores Korean default")
	store.set_master_volume(previous_master)
	store.set_sfx_volume(previous_sfx)
	store.set_ui_locale(previous_locale)
	if failures.is_empty():
		print("PASS: audio and Korean/English locale defaults, persistence, and malformed fallback")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
