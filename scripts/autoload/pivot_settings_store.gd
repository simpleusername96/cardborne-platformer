class_name PivotSettingsStore
extends Node

const SETTINGS_PATH := "user://pivot-settings.cfg"
const SECTION := "audio"

var master_volume := 1.0
var sfx_volume := 1.0


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	master_volume = 1.0
	sfx_volume = 1.0
	var config := ConfigFile.new()
	var result := config.load(SETTINGS_PATH)
	if result == OK:
		master_volume = _safe_volume(config.get_value(SECTION, "master", 1.0))
		sfx_volume = _safe_volume(config.get_value(SECTION, "sfx", 1.0))
	elif result != ERR_FILE_NOT_FOUND:
		push_warning("Audio settings were malformed; restored defaults")
	apply_audio()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	_save()


func apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("SFX", sfx_volume)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(index, linear <= 0.0001)


func _safe_volume(value: Variant) -> float:
	if value is float or value is int:
		return clampf(float(value), 0.0, 1.0)
	push_warning("Invalid audio volume; restored default")
	return 1.0


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "master", master_volume)
	config.set_value(SECTION, "sfx", sfx_volume)
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		push_warning("Could not save audio settings: %s" % error_string(result))
