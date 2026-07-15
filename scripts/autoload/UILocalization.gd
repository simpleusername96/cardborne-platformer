extends Node

## Owns the active UI language independently of profile or run progression data.
## Every lookup resolves through the active Godot translation and then the English catalog.

signal locale_changed(locale: String)

const PREFERENCES_PATH := "user://ui_preferences.cfg"
const PREFERENCES_SECTION := "localization"
const LOCALE_KEY := "locale"
const DEFAULT_LOCALE := "en"
const SUPPORTED_LOCALES := ["en", "ko"]

const ENGLISH_TRANSLATION: Translation = preload("res://localization/ui.en.po")

var _locale := DEFAULT_LOCALE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved_locale := _load_saved_locale()
	_locale = saved_locale if not saved_locale.is_empty() else _infer_locale()
	TranslationServer.set_locale(_locale)
	if saved_locale.is_empty():
		_save_locale()


func text(key: StringName, values: Array = []) -> String:
	var source := String(key)
	if source.is_empty():
		return ""

	var translated := String(TranslationServer.translate(key))
	if translated.is_empty() or translated == source:
		var english_fallback := String(ENGLISH_TRANSLATION.get_message(key))
		if not english_fallback.is_empty():
			translated = english_fallback
	if translated.is_empty():
		translated = source
	if values.is_empty():
		return translated
	if translated.contains("%"):
		return translated % values
	return translated.format(values)


func get_locale() -> String:
	return _locale


func set_locale(locale: String) -> bool:
	var normalized := _normalize_locale(locale)
	if normalized.is_empty():
		return false
	if normalized == _locale:
		TranslationServer.set_locale(_locale)
		return true

	_locale = normalized
	TranslationServer.set_locale(_locale)
	_save_locale()
	locale_changed.emit(_locale)
	return true


func supported_locales() -> PackedStringArray:
	return PackedStringArray(SUPPORTED_LOCALES)


func _load_saved_locale() -> String:
	var config := ConfigFile.new()
	if config.load(PREFERENCES_PATH) != OK:
		return ""
	return _normalize_locale(String(config.get_value(PREFERENCES_SECTION, LOCALE_KEY, "")))


func _infer_locale() -> String:
	var inferred := _normalize_locale(OS.get_locale())
	return inferred if not inferred.is_empty() else DEFAULT_LOCALE


func _normalize_locale(locale: String) -> String:
	var candidate := locale.strip_edges().replace("-", "_").to_lower()
	if candidate.is_empty():
		return ""
	var language := candidate.get_slice("_", 0)
	return language if SUPPORTED_LOCALES.has(language) else ""


func _save_locale() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(PREFERENCES_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Unable to read UI preferences: %s" % error_string(load_error))
	config.set_value(PREFERENCES_SECTION, LOCALE_KEY, _locale)
	var save_error := config.save(PREFERENCES_PATH)
	if save_error != OK:
		push_warning("Unable to save UI language: %s" % error_string(save_error))
