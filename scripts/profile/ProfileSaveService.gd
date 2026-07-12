class_name ProfileSaveService
extends RefCounted

const DEFAULT_PRIMARY_PATH := "user://profile.json"

var primary_path: String
var backup_path: String
var _equipment_catalog: EquipmentCatalog
var _mastery_catalog: MasteryCatalog


func _init(
	equipment_catalog: EquipmentCatalog = null,
	mastery_catalog: MasteryCatalog = null,
	profile_path: String = DEFAULT_PRIMARY_PATH
) -> void:
	_equipment_catalog = equipment_catalog
	_mastery_catalog = mastery_catalog
	primary_path = profile_path
	backup_path = "%s.backup" % profile_path


func load_or_create() -> Dictionary:
	var primary := _load_candidate(primary_path)
	if bool(primary.get("ok", false)):
		var migrated := bool(primary.get("migrated", false))
		if migrated:
			primary["persisted"] = bool(save(primary["data"]).get("ok", false))
		primary["source"] = "primary"
		primary["recovered"] = false
		return primary

	var backup := _load_candidate(backup_path)
	if bool(backup.get("ok", false)):
		var recovered_data: ProfileData = backup["data"]
		var rewrite := save(recovered_data)
		return {
			"ok": true,
			"data": recovered_data,
			"source": "backup",
			"recovered": true,
			"persisted": bool(rewrite.get("ok", false)),
			"errors": primary.get("errors", PackedStringArray()),
		}

	var data := ProfileData.new()
	var created := save(data)
	return {
		"ok": true,
		"data": data,
		"source": "default",
		"recovered": false,
		"persisted": bool(created.get("ok", false)),
		"errors": _joined_errors(primary, backup),
	}


func save(data: ProfileData) -> Dictionary:
	if data == null:
		return {"ok": false, "message": "Profile data is unavailable."}
	var errors := data.validate_data(_equipment_catalog, _mastery_catalog)
	if not errors.is_empty():
		return {
			"ok": false,
			"message": "Profile data is invalid: %s" % "; ".join(errors),
			"errors": errors,
		}

	var temp_path := "%s.tmp" % primary_path
	var serialized := JSON.stringify(data.to_dictionary(), "\t", true)
	var write_error := _write_text(temp_path, serialized)
	if write_error != OK:
		return {"ok": false, "message": "Unable to write the profile staging file."}
	var staged := _load_candidate(temp_path)
	if not bool(staged.get("ok", false)):
		_remove_file(temp_path)
		var staged_errors: Variant = staged.get("errors", PackedStringArray())
		var detail := "; ".join(staged_errors) if staged_errors is PackedStringArray else "Unknown validation error."
		return {"ok": false, "message": "Profile staging verification failed: %s" % detail}

	var rotate_error := _rotate_primary_to_backup()
	if rotate_error != OK:
		_remove_file(temp_path)
		return {"ok": false, "message": "Unable to preserve the previous profile."}
	var replace_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(primary_path)
	)
	if replace_error != OK:
		_restore_backup_if_needed()
		_remove_file(temp_path)
		return {"ok": false, "message": "Unable to activate the saved profile."}
	return {"ok": true, "message": "Profile saved."}


func migrate_payload(payload: Dictionary) -> Dictionary:
	var version := int(payload.get("schema_version", 0))
	if version == ProfileData.CURRENT_SCHEMA_VERSION:
		return {"ok": true, "payload": payload.duplicate(true), "migrated": false}
	if version != 0:
		return {
			"ok": false,
			"message": "Profile schema version %d is newer than this build." % version,
		}
	return {
		"ok": true,
		"payload": _migrate_legacy_snapshot(payload),
		"migrated": true,
	}


func _load_candidate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": PackedStringArray(["Profile file is missing."])}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "errors": PackedStringArray(["Profile file cannot be opened."])}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK or not json.data is Dictionary:
		return {"ok": false, "errors": PackedStringArray(["Profile JSON is invalid."])}
	var migration := migrate_payload(json.data)
	if not bool(migration.get("ok", false)):
		return {
			"ok": false,
			"errors": PackedStringArray([String(migration.get("message", "Migration failed."))]),
		}
	var data := ProfileData.from_dictionary(migration["payload"])
	var errors := data.validate_data(_equipment_catalog, _mastery_catalog)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	return {
		"ok": true,
		"data": data,
		"migrated": bool(migration.get("migrated", false)),
		"errors": PackedStringArray(),
	}


func _migrate_legacy_snapshot(payload: Dictionary) -> Dictionary:
	var migrated := ProfileData.new().to_dictionary()
	var legacy_materials: Variant = payload.get("materials", {})
	if legacy_materials is Dictionary:
		for material_id in legacy_materials:
			if ProfileData.MATERIAL_IDS.has(String(material_id)):
				migrated["materials"][String(material_id)] = maxi(int(legacy_materials[material_id]), 0)

	var owned: Array[String] = ProfileData.DEFAULT_OWNED_EQUIPMENT.duplicate()
	var legacy_owned: Variant = payload.get("owned_equipment", [])
	if legacy_owned is Array:
		for raw_item_id in legacy_owned:
			var item_id := String(raw_item_id)
			if _equipment_catalog != null and _equipment_catalog.get_item(StringName(item_id)) != null:
				if not owned.has(item_id):
					owned.append(item_id)
	migrated["owned_equipment"] = owned

	var legacy_mastery: Variant = payload.get("mastery_unlocks", {})
	if legacy_mastery is Dictionary:
		for character_id in ProfileData.CHARACTER_IDS:
			var raw_nodes: Variant = legacy_mastery.get(character_id, [])
			var node_ids: Array[String] = []
			if raw_nodes is Dictionary:
				for node_id in raw_nodes:
					if bool(raw_nodes[node_id]):
						node_ids.append(String(node_id))
			elif raw_nodes is Array:
				for node_id in raw_nodes:
					node_ids.append(String(node_id))
			migrated["mastery_unlocks"][character_id] = node_ids

	var legacy_settings: Variant = payload.get("settings", {})
	if legacy_settings is Dictionary:
		for setting_id in ProfileData.DEFAULT_SETTINGS:
			if legacy_settings.has(setting_id):
				migrated["settings"][setting_id] = legacy_settings[setting_id]

	var legacy_unlocks: Variant = payload.get("durable_unlocks", [])
	if legacy_unlocks is Array:
		var unlocks: Array[String] = []
		for unlock_id in legacy_unlocks:
			if not String(unlock_id).is_empty() and not unlocks.has(String(unlock_id)):
				unlocks.append(String(unlock_id))
		migrated["durable_unlocks"] = unlocks

	var legacy_loadout: Variant = payload.get("loadout", {})
	if legacy_loadout is Dictionary:
		_apply_legacy_loadout(legacy_loadout, migrated["loadouts"], owned)
	return migrated


func _apply_legacy_loadout(
	legacy_loadout: Dictionary,
	loadouts: Dictionary,
	owned: Array[String]
) -> void:
	for slot_id in ProfileData.ALL_SLOTS:
		var item_id := String(legacy_loadout.get(slot_id, ""))
		if item_id.is_empty():
			continue
		if slot_id == "consumable":
			if ProfileData.CONSUMABLE_IDS.has(item_id):
				for character_id in ProfileData.CHARACTER_IDS:
					loadouts[character_id][slot_id] = item_id
			continue
		var item := _equipment_catalog.get_item(StringName(item_id)) if _equipment_catalog != null else null
		if item == null or not owned.has(item_id):
			continue
		for character_id in ProfileData.CHARACTER_IDS:
			if String(item.slot) == slot_id and item.is_compatible(StringName(character_id)):
				loadouts[character_id][slot_id] = item_id


func _rotate_primary_to_backup() -> Error:
	if not FileAccess.file_exists(primary_path):
		return OK
	var current := _load_candidate(primary_path)
	if not bool(current.get("ok", false)):
		var corrupt_path := "%s.corrupt" % primary_path
		_remove_file(corrupt_path)
		return DirAccess.rename_absolute(
			ProjectSettings.globalize_path(primary_path),
			ProjectSettings.globalize_path(corrupt_path)
		)
	_remove_file(backup_path)
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(primary_path),
		ProjectSettings.globalize_path(backup_path)
	)


func _restore_backup_if_needed() -> void:
	if FileAccess.file_exists(primary_path) or not FileAccess.file_exists(backup_path):
		return
	var backup_file := FileAccess.open(backup_path, FileAccess.READ)
	if backup_file != null:
		_write_text(primary_path, backup_file.get_as_text())


func _write_text(path: String, contents: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	file.flush()
	return OK


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _joined_errors(first: Dictionary, second: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for result in [first, second]:
		var candidate_errors: Variant = result.get("errors", PackedStringArray())
		if candidate_errors is PackedStringArray:
			errors.append_array(candidate_errors)
	return errors
