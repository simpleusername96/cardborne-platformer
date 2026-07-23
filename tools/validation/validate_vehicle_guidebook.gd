extends SceneTree

const Catalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const Store = preload("res://scripts/autoload/vehicle_guidebook_store.gd")
const GuidePanel = preload("res://scripts/ui/vehicle_guidebook_panel.gd")

var failures: Array[String] = []
const TEST_PATH := "user://vehicle-guidebook-validation.cfg"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var store := Store.new()
	store.save_path = TEST_PATH
	store.known.clear()
	_expect(store.discover(&"mobile_chaser"), "first encounter unlocks one entry")
	_expect(not store.discover(&"mobile_chaser"), "discovery is idempotent")
	_expect(not store.discover(&"unknown_entry"), "unknown IDs are discarded")
	_expect(Catalog.entry_id_for_enemy(&"spark_minelet", &"mine") == &"mobile_spark_minelet", "moving minelets stay in the mobile guide category")
	_expect(Catalog.entry_id_for_enemy(&"mine", &"mine") == &"stationary_mine", "authored mines stay in the stationary guide category")
	var locked := store.snapshot({"health":120.0})
	var mobile: Array = locked["categories"][&"mobile"]
	var hidden := mobile.filter(func(entry: Dictionary) -> bool: return bool(entry["locked"]))
	_expect(hidden.all(func(entry: Dictionary) -> bool: return entry.keys().all(func(key): return key in ["id", "locked", "name", "description"]) and entry["name"] == "???" and entry["description"] == ""), "locked entries contain no hidden copy")
	var loaded := Store.new()
	loaded.save_path = TEST_PATH
	loaded.load_discovery()
	_expect(loaded.known.has(&"mobile_chaser") and loaded.known.size() == 1, "discovery save round-trips sanitized IDs")
	var panel := GuidePanel.new()
	get_root().add_child(panel)
	var contract := panel.debug_contract()
	_expect(int(contract["categories"]) == 5 and int(contract["command_height"]) >= 44, "guide modal has five accessible categories")
	panel.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_GUIDEBOOK_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
