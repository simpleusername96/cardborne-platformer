extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var store := get_root().get_node("SettingsStore") as PivotSettingsStore
	_expect(AudioServer.get_bus_index("Master") == 0, "Master audio bus is missing")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "SFX audio bus is missing")
	var previous_master := store.master_volume
	var previous_sfx := store.sfx_volume
	store.set_master_volume(0.37)
	store.set_sfx_volume(0.61)
	store.master_volume = 1.0
	store.sfx_volume = 1.0
	store.load_settings()
	_expect(is_equal_approx(store.master_volume, 0.37), "Master volume did not survive reload")
	_expect(is_equal_approx(store.sfx_volume, 0.61), "SFX volume did not survive reload")
	var malformed := ConfigFile.new()
	malformed.set_value("audio", "master", "invalid")
	malformed.set_value("audio", "sfx", Vector2.ONE)
	malformed.save(PivotSettingsStore.SETTINGS_PATH)
	store.load_settings()
	_expect(store.master_volume == 1.0 and store.sfx_volume == 1.0, "malformed audio settings did not restore defaults")
	store.set_master_volume(previous_master)
	store.set_sfx_volume(previous_sfx)
	if failures.is_empty():
		print("PASS: Master/SFX defaults, live application, persistence, and malformed fallback")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
