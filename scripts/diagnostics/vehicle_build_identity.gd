class_name VehicleBuildIdentity
extends RefCounted

## Reads the export-time identity. Editor play is deliberately never promoted to a
## guessed source revision when the generated identity is absent or invalid.

const SCHEMA_VERSION := 1
const GENERATED_PATH := "res://data/generated/vehicle_build_identity.json"


static func load_identity() -> Dictionary:
	if not FileAccess.file_exists(GENERATED_PATH):
		return dev_unknown()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GENERATED_PATH))
	if not parsed is Dictionary:
		return dev_unknown()
	var identity := Dictionary(parsed)
	if not is_complete(identity):
		return dev_unknown()
	return identity


static func dev_unknown() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"identity_status": "dev_unknown",
		"commit": "",
		"source_cleanliness": "unknown",
		"content_fingerprint": "",
	}


static func is_complete(identity: Dictionary) -> bool:
	return (
		int(identity.get("schema_version", 0)) == SCHEMA_VERSION
		and String(identity.get("identity_status", "")) == "resolved"
		and String(identity.get("commit", "")).is_valid_hex_number()
		and String(identity.get("commit", "")).length() == 40
		and not String(identity.get("ref", "")).is_empty()
		and String(identity.get("source_cleanliness", "")) in ["clean", "dirty"]
		and String(identity.get("content_fingerprint", "")).is_valid_hex_number()
		and String(identity.get("content_fingerprint", "")).length() == 64
	)


static func is_session_usable(identity: Dictionary) -> bool:
	if int(identity.get("schema_version", 0)) != SCHEMA_VERSION:
		return false
	if String(identity.get("identity_status", "")) == "dev_unknown":
		return true
	return is_complete(identity)


static func evidence_identity() -> Dictionary:
	return load_identity().duplicate(true)
