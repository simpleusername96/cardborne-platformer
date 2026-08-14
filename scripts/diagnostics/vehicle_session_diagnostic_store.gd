class_name VehicleSessionDiagnosticStore
extends RefCounted

## Completed bundles only. Retention is evaluated at lifecycle flush time, never in
## the frame path, and corrupt records are isolated instead of blocking a new session.

const DIRECTORY := "user://diagnostics"
const MAX_SESSIONS := 20
const MAX_BYTES := 25 * 1024 * 1024
const MAX_AGE_SECONDS := 14 * 24 * 60 * 60


static func persist_completed(bundle: Dictionary) -> Error:
	if not _valid_bundle(bundle):
		return ERR_INVALID_DATA
	var directory := ProjectSettings.globalize_path(DIRECTORY)
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return error
	_evict(directory)
	var file_name := "%s.json" % String(bundle["session_id"]).validate_filename()
	var file := FileAccess.open(directory.path_join(file_name), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(bundle) + "\n")
	file.close()
	_evict(directory)
	return OK


static func load_completed() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directory := ProjectSettings.globalize_path(DIRECTORY)
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for name in DirAccess.get_files_at(directory):
		if not String(name).ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(name)))
		if parsed is Dictionary and _valid_bundle(Dictionary(parsed)):
			result.append(Dictionary(parsed))
	return result


static func _evict(directory: String) -> void:
	var records: Array[Dictionary] = []
	var now := Time.get_unix_time_from_system()
	for name in DirAccess.get_files_at(directory):
		if not String(name).ends_with(".json"):
			continue
		var path := directory.path_join(name)
		var modified := FileAccess.get_modified_time(path)
		if now - modified > MAX_AGE_SECONDS:
			DirAccess.remove_absolute(path)
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary or not _valid_bundle(Dictionary(parsed)):
			DirAccess.rename_absolute(path, path + ".quarantine")
			continue
		records.append({"path": path, "modified": modified, "bytes": FileAccess.get_file_as_bytes(path).size()})
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["modified"]) < int(b["modified"]))
	var total := 0
	for record in records:
		total += int(record["bytes"])
	while records.size() > MAX_SESSIONS or total > MAX_BYTES:
		var oldest: Dictionary = records.pop_front()
		DirAccess.remove_absolute(String(oldest["path"]))
		total -= int(oldest["bytes"])


static func _valid_bundle(bundle: Dictionary) -> bool:
	return int(bundle.get("schema_version", 0)) == 1 and String(bundle.get("kind", "")) == "session_diagnostic" and not String(bundle.get("session_id", "")).is_empty()
