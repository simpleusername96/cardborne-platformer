class_name ContentId
extends RefCounted


static func validate(
	errors: PackedStringArray,
	label: String,
	value: StringName
) -> void:
	var text_value := String(value)
	if not is_valid(text_value):
		errors.append("%s '%s' must be a non-blank snake_case identifier." % [label, text_value])


static func validate_list(
	errors: PackedStringArray,
	label: String,
	values: Array[StringName],
	require_value: bool
) -> void:
	if require_value and values.is_empty():
		errors.append("%s list cannot be empty." % label)
		return
	var seen: Dictionary = {}
	for value in values:
		var text_value := String(value)
		if not is_valid(text_value):
			errors.append("%s '%s' must be a non-blank snake_case identifier." % [label, text_value])
		elif seen.has(text_value):
			errors.append("%s '%s' is duplicated." % [label, text_value])
		seen[text_value] = true


static func is_valid(value: String) -> bool:
	if (
		value.is_empty()
		or value != value.strip_edges()
		or value.begins_with("_")
		or value.ends_with("_")
		or value.contains("__")
	):
		return false
	var bytes := value.to_utf8_buffer()
	if bytes[0] < 97 or bytes[0] > 122:
		return false
	for byte in bytes:
		if not ((byte >= 97 and byte <= 122) or (byte >= 48 and byte <= 57) or byte == 95):
			return false
	return true
