class_name SettingsStoreService
extends Node

signal locale_changed(locale: String)
signal controls_changed(action: StringName)
signal reduced_motion_changed(enabled: bool)

const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")

const SETTINGS_PATH := "user://cardborne-settings.cfg"
const AUDIO_SECTION := "audio"
const UI_SECTION := "ui"
const CONTROLS_SECTION := "controls"
const GAMEPLAY_SECTION := "gameplay"
const DEFAULT_LOCALE := "ko"
const SUPPORTED_LOCALES := ["ko", "en"]

var master_volume := 1.0
var sfx_volume := 1.0
var ui_locale := DEFAULT_LOCALE
var control_bindings: Dictionary = InputProfile.default_descriptors()
var reduced_motion := false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	master_volume = 1.0
	sfx_volume = 1.0
	ui_locale = DEFAULT_LOCALE
	control_bindings = InputProfile.default_descriptors()
	reduced_motion = false
	var config := ConfigFile.new()
	var result := config.load(SETTINGS_PATH)
	var repaired := false
	if result == OK:
		master_volume = _safe_volume(config.get_value(AUDIO_SECTION, "master", 1.0))
		sfx_volume = _safe_volume(config.get_value(AUDIO_SECTION, "sfx", 1.0))
		ui_locale = _safe_locale(config.get_value(UI_SECTION, "locale", DEFAULT_LOCALE))
		reduced_motion = bool(config.get_value(UI_SECTION, "reduced_motion", false))
		for action in InputProfile.REMAPPABLE_ACTIONS:
			var raw_value: Variant = config.get_value(CONTROLS_SECTION, String(action), control_bindings[action])
			var descriptor := InputProfile.normalize_descriptor(raw_value)
			if descriptor.is_empty() or not InputProfile.conflict_action(descriptor, control_bindings, action).is_empty():
				if config.has_section_key(CONTROLS_SECTION, String(action)):
					push_warning("Invalid %s binding; restored its default" % action)
					repaired = true
				descriptor = InputProfile.default_descriptors()[action]
			control_bindings[action] = descriptor
	elif result != ERR_FILE_NOT_FOUND:
		push_warning("Settings file was malformed; restored defaults")
	apply_audio()
	apply_locale()
	if repaired:
		_save()
	controls_changed.emit(&"")


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


func set_control_binding(action: StringName, descriptor_value: Variant) -> bool:
	if not InputProfile.is_remappable(action):
		return false
	var descriptor := InputProfile.normalize_descriptor(descriptor_value)
	if descriptor.is_empty() or not InputProfile.conflict_action(descriptor, control_bindings, action).is_empty():
		return false
	if control_bindings.get(action, "") == descriptor:
		return true
	control_bindings[action] = descriptor
	_save()
	controls_changed.emit(action)
	return true


func reset_control_bindings() -> void:
	control_bindings = InputProfile.default_descriptors()
	_save()
	controls_changed.emit(&"")


func set_reduced_motion(value: bool) -> void:
	if reduced_motion == value:
		return
	reduced_motion = value
	_save()
	reduced_motion_changed.emit(reduced_motion)


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
	var load_result := config.load(SETTINGS_PATH)
	if load_result != OK:
		config = ConfigFile.new()
	config.set_value(AUDIO_SECTION, "master", master_volume)
	config.set_value(AUDIO_SECTION, "sfx", sfx_volume)
	config.set_value(UI_SECTION, "locale", ui_locale)
	config.set_value(UI_SECTION, "reduced_motion", reduced_motion)
	for action in InputProfile.REMAPPABLE_ACTIONS:
		config.set_value(CONTROLS_SECTION, String(action), control_bindings[action])
	if config.has_section_key(GAMEPLAY_SECTION, "run_difficulty"):
		config.erase_section_key(GAMEPLAY_SECTION, "run_difficulty")
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		push_warning("Could not save settings: %s" % error_string(result))
