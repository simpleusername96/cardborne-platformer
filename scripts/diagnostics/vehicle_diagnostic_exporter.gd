class_name VehicleDiagnosticExporter
extends RefCounted

## Explicit user-requested exporter core. UI/platform owners select a destination;
## this owner redacts local data and never initiates a request or upload.

const EXPORT_SCHEMA_VERSION := 1
const FORBIDDEN_KEYS := ["session_id", "device_id", "player_id", "path", "raw_path", "route", "user_agent", "ip", "secret", "token"]


static func make_redacted_bundle(bundle: Dictionary) -> Dictionary:
	return {"schema_version": EXPORT_SCHEMA_VERSION, "kind": "cardborne_diagnostics_export",
		"registry_version": int(bundle.get("registry_version", 0)),
		"build_identity": _redact_value(bundle.get("build_identity", {})),
		"session_context":_redact_value(bundle.get("session_context", {})),
		"summary": {"completed_reason": String(bundle.get("completed_reason", "")),
			"started_unix": int(bundle.get("started_unix", 0)),
			"saved_unix": int(bundle.get("saved_unix", 0)),
			"event_count": Array(bundle.get("events", [])).size(), "one_hz_count": Array(bundle.get("one_hz", [])).size()},
		"events": _redact_value(bundle.get("events", [])),
		"one_hz": _redact_value(bundle.get("one_hz", [])),
		"slow_tick_receipts":_redact_value(bundle.get("slow_tick_receipts", []))}


static func write_native(bundle: Dictionary, absolute_path: String) -> Error:
	if absolute_path.is_empty() or not absolute_path.is_absolute_path():
		return ERR_INVALID_PARAMETER
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(make_redacted_bundle(bundle)) + "\n")
	file.close()
	return OK


static func _redact_value(value: Variant) -> Variant:
	if value is Dictionary:
		var output := {}
		for key in Dictionary(value):
			if not _key_is_forbidden(String(key)):
				output[key] = _redact_value(Dictionary(value)[key])
		return output
	if value is Array:
		var output: Array = []
		for entry in Array(value): output.append(_redact_value(entry))
		return output
	return value


static func _key_is_forbidden(key: String) -> bool:
	var normalized := key.to_lower().replace("_", "").replace("-", "")
	for forbidden in FORBIDDEN_KEYS:
		var forbidden_normalized := String(forbidden).replace("_", "")
		if normalized == forbidden_normalized:
			return true
		if (
			forbidden_normalized != "ip"
			and normalized.ends_with(forbidden_normalized)
		):
			return true
	if normalized in ["ipaddress", "clientip", "remoteip"]:
		return true
	return false
