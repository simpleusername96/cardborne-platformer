extends Node

signal discovery_changed(entry_id: StringName)

const Catalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const SAVE_PATH := "user://vehicle-guidebook.cfg"
const SCHEMA_VERSION := 1

var known: Dictionary = {}
var save_path := SAVE_PATH


func _ready() -> void:
	load_discovery()


func discover(entry_id: StringName) -> bool:
	if known.has(entry_id) or not Catalog.valid_ids().has(entry_id):
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
	if error != OK or int(config.get_value("meta", "version", 0)) != SCHEMA_VERSION:
		push_warning("Guidebook discovery could not be loaded; using an empty catalog.")
		return
	var valid := Catalog.valid_ids()
	for value in config.get_value("discovery", "known", PackedStringArray()):
		var entry_id := StringName(value)
		if valid.has(entry_id):
			known[entry_id] = true
