class_name PivotSettingsStore
extends Node

signal locale_changed(locale: String)

const SETTINGS_PATH := "user://pivot-settings.cfg"
const AUDIO_SECTION := "audio"
const UI_SECTION := "ui"
const DEFAULT_LOCALE := "ko"
const SUPPORTED_LOCALES := ["ko", "en"]

var master_volume := 1.0
var sfx_volume := 1.0
var ui_locale := DEFAULT_LOCALE


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	master_volume = 1.0
	sfx_volume = 1.0
	ui_locale = DEFAULT_LOCALE
	var config := ConfigFile.new()
	var result := config.load(SETTINGS_PATH)
	if result == OK:
		master_volume = _safe_volume(config.get_value(AUDIO_SECTION, "master", 1.0))
		sfx_volume = _safe_volume(config.get_value(AUDIO_SECTION, "sfx", 1.0))
		ui_locale = _safe_locale(config.get_value(UI_SECTION, "locale", DEFAULT_LOCALE))
	elif result != ERR_FILE_NOT_FOUND:
		push_warning("Settings file was malformed; restored defaults")
	apply_audio()
	apply_locale()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	_save()


func set_ui_locale(value: String) -> void:
	var next_locale := _safe_locale(value)
	if ui_locale == next_locale:
		return
	ui_locale = next_locale
	apply_locale()
	_save()
	locale_changed.emit(ui_locale)


func apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("SFX", sfx_volume)


func apply_locale() -> void:
	TranslationServer.set_locale(ui_locale)


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


func _safe_locale(value: Variant) -> String:
	var locale := String(value)
	if SUPPORTED_LOCALES.has(locale):
		return locale
	if not locale.is_empty():
		push_warning("Unsupported UI locale; restored Korean default")
	return DEFAULT_LOCALE


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value(AUDIO_SECTION, "master", master_volume)
	config.set_value(AUDIO_SECTION, "sfx", sfx_volume)
	config.set_value(UI_SECTION, "locale", ui_locale)
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		push_warning("Could not save settings: %s" % error_string(result))
