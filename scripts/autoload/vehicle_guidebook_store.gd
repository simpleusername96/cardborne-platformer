extends Node

signal discovery_changed(entry_id: StringName)

const Catalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const SAVE_PATH := "user://vehicle-guidebook.cfg"
const SCHEMA_VERSION := 2
const LEGACY_SCHEMA_VERSION := 1

var known: Dictionary = {}
var save_path := SAVE_PATH
var _valid_ids: Dictionary = Catalog.valid_ids()


func _ready() -> void:
	load_discovery()


func discover(entry_id: StringName) -> bool:
	if (
		entry_id.is_empty()
		or known.has(entry_id)
		or not _valid_ids.has(entry_id)
	):
		return false
	known[entry_id] = true
	save_discovery()
	discovery_changed.emit(entry_id)
	return true


func snapshot(
	ship: Dictionary = {},
	context: Dictionary = {}
) -> Dictionary:
	return Catalog.snapshot(known, ship, context)


func save_discovery() -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SCHEMA_VERSION)
	var ids: Array[String] = []
	for entry_id in known.keys():
		ids.append(String(entry_id))
	ids.sort()
	config.set_value("discovery", "known", PackedStringArray(ids))
	return config.save(save_path)


func load_discovery() -> void:
	known.clear()
	var config := ConfigFile.new()
	var error := config.load(save_path)
	if error == ERR_FILE_NOT_FOUND:
		return
	var stored_version := int(config.get_value("meta", "version", 0))
	if error != OK or stored_version not in [LEGACY_SCHEMA_VERSION, SCHEMA_VERSION]:
		push_warning("Guidebook discovery could not be loaded; using an empty catalog.")
		return
	var migrated := false
	for value in config.get_value("discovery", "known", PackedStringArray()):
		var entry_id := _migrated_entry_id(String(value), stored_version)
		migrated = migrated or String(entry_id) != String(value)
		if _valid_ids.has(entry_id):
			known[entry_id] = true
	if stored_version != SCHEMA_VERSION or migrated:
		save_discovery()


func _migrated_entry_id(raw_id: String, stored_version: int) -> StringName:
	if stored_version != LEGACY_SCHEMA_VERSION:
		return StringName(raw_id)
	var retired_family_token := "gun" + "ner"
	for tier in range(1, 4):
		var retired_id := "enemy_ordinary_%s_t%d" % [retired_family_token, tier]
		if raw_id == retired_id:
			return StringName("enemy_ordinary_emitter_t%d" % tier)
	return StringName(raw_id)
