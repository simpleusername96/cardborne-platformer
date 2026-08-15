class_name VehicleSessionDiagnosticStore
extends RefCounted

## Completed bundles only. Retention is evaluated at lifecycle flush time, never in
## the frame path, and corrupt records are isolated instead of blocking a new session.

const DIRECTORY := "user://diagnostics"
const MAX_SESSIONS := 10
const MAX_BYTES := 25 * 1024 * 1024
const MAX_AGE_SECONDS := 14 * 24 * 60 * 60


static func persist_completed(
	bundle: Dictionary,
	directory_uri: String = DIRECTORY
) -> Error:
	if not _valid_bundle(bundle):
		return ERR_INVALID_DATA
	var directory := ProjectSettings.globalize_path(directory_uri)
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


static func load_completed(
	directory_uri: String = DIRECTORY
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directory := ProjectSettings.globalize_path(directory_uri)
	if not DirAccess.dir_exists_absolute(directory):
		return result
	_evict(directory)
	for name in DirAccess.get_files_at(directory):
		if not String(name).ends_with(".json"):
			continue
		var parsed: Variant = _parse_json_file(directory.path_join(name))
		if parsed is Dictionary and _valid_bundle(Dictionary(parsed)):
			result.append(Dictionary(parsed))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_saved := int(a.get("saved_unix", 0))
		var b_saved := int(b.get("saved_unix", 0))
		return (
			a_saved > b_saved
			or (
				a_saved == b_saved
				and String(a.get("session_id", ""))
				> String(b.get("session_id", ""))
			)
		)
	)
	return result


static func _evict(
	directory: String,
	max_sessions: int = MAX_SESSIONS,
	max_bytes: int = MAX_BYTES,
	max_age_seconds: int = MAX_AGE_SECONDS
) -> void:
	var records: Array[Dictionary] = []
	var now := Time.get_unix_time_from_system()
	for name in DirAccess.get_files_at(directory):
		if not String(name).ends_with(".json"):
			continue
		var path := directory.path_join(name)
		var parsed: Variant = _parse_json_file(path)
		if not parsed is Dictionary or not _valid_bundle(Dictionary(parsed)):
			DirAccess.rename_absolute(path, path + ".quarantine")
			continue
		var bundle := Dictionary(parsed)
		if not _is_meaningful_session(bundle):
			DirAccess.remove_absolute(path)
			continue
		var saved_unix := int(bundle.get("saved_unix", 0))
		if now - saved_unix > max_age_seconds:
			DirAccess.remove_absolute(path)
			continue
		records.append({
			"path": path,
			"saved_unix": saved_unix,
			"session_id": String(bundle.get("session_id", "")),
			"bytes": FileAccess.get_file_as_bytes(path).size(),
		})
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (
			int(a["saved_unix"]) < int(b["saved_unix"])
			or (
				int(a["saved_unix"]) == int(b["saved_unix"])
				and String(a["session_id"]) < String(b["session_id"])
			)
		)
	)
	var total := 0
	for record in records:
		total += int(record["bytes"])
	while records.size() > max_sessions or total > max_bytes:
		var oldest: Dictionary = records.pop_front()
		DirAccess.remove_absolute(String(oldest["path"]))
		total -= int(oldest["bytes"])


static func _valid_bundle(bundle: Dictionary) -> bool:
	return int(bundle.get("schema_version", 0)) == 1 and String(bundle.get("kind", "")) == "session_diagnostic" and not String(bundle.get("session_id", "")).is_empty()


static func _parse_json_file(path: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data


static func _is_meaningful_session(bundle: Dictionary) -> bool:
	if String(bundle.get("completed_reason", "")) != "normal_exit":
		return true
	var samples: Array = bundle.get("one_hz", [])
	if samples.size() != 1:
		return true
	return float(Dictionary(samples[0]).get("end_monotonic_seconds", 0.0)) >= 1.0
