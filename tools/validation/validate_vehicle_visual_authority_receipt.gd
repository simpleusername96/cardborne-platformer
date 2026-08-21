extends SceneTree

const SPEC_PATH := "res://docs/design/VISUAL_SYSTEM.md"
const SHEET_PATH := "res://docs/design/cardborne-universal-art-style-reference.png"
const EXPECTED_SHEET_SHA256 := "96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889"
const EXPECTED_SHEET_SIZE := Vector2i(1448, 1086)
const EVIDENCE_DIRECTORY := "res://build/vehicle-run/visual-authority"

var failures: Array[String] = []


func _initialize() -> void:
	var spec_absolute := ProjectSettings.globalize_path(SPEC_PATH)
	var sheet_absolute := ProjectSettings.globalize_path(SHEET_PATH)
	_expect(FileAccess.file_exists(spec_absolute), "missing canonical visual specification")
	_expect(FileAccess.file_exists(sheet_absolute), "missing canonical visual reference")
	if not failures.is_empty():
		_finish()
		return

	var spec_bytes := FileAccess.get_file_as_bytes(spec_absolute)
	var sheet_bytes := FileAccess.get_file_as_bytes(sheet_absolute)
	var spec_sha256 := _sha256(spec_bytes)
	var sheet_sha256 := _sha256(sheet_bytes)
	_expect(not spec_bytes.is_empty(), "canonical visual specification is empty")
	_expect(not sheet_bytes.is_empty(), "canonical visual reference is empty")
	_expect(
		sheet_sha256 == EXPECTED_SHEET_SHA256,
		"canonical visual reference hash mismatch: %s" % sheet_sha256
	)

	var image := Image.new()
	var image_error := image.load_png_from_buffer(sheet_bytes)
	_expect(image_error == OK, "canonical visual reference does not decode as PNG")
	if image_error == OK:
		_expect(
			Vector2i(image.get_width(), image.get_height()) == EXPECTED_SHEET_SIZE,
			"canonical visual reference dimensions are not 1448x1086"
		)

	if failures.is_empty():
		var output_absolute := ProjectSettings.globalize_path(EVIDENCE_DIRECTORY)
		var directory_error := DirAccess.make_dir_recursive_absolute(output_absolute)
		_expect(directory_error == OK, "could not create visual-authority evidence directory")
		if directory_error == OK:
			_write_bytes(output_absolute.path_join("cardborne-universal-art-style-reference.png"), sheet_bytes)
			var receipt := {
				"schema_version": 1,
				"spec_path": SPEC_PATH.trim_prefix("res://"),
				"spec_sha256": spec_sha256,
				"sheet_path": SHEET_PATH.trim_prefix("res://"),
				"sheet_sha256": sheet_sha256,
				"sheet_width": image.get_width(),
				"sheet_height": image.get_height(),
				"expected_sheet_sha256": EXPECTED_SHEET_SHA256,
				"artifact_kind": "visual_authority_preflight",
				"source_bytes_copied_without_edit": true,
			}
			_write_text(
				output_absolute.path_join("visual-authority-receipt.json"),
				JSON.stringify(receipt, "\t") + "\n"
			)
			print(
				"VEHICLE_VISUAL_AUTHORITY_RECEIPT_OK spec_sha256=%s sheet_sha256=%s dimensions=%dx%d"
				% [spec_sha256, sheet_sha256, image.get_width(), image.get_height()]
			)
	_finish()


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	var start_error := context.start(HashingContext.HASH_SHA256)
	if start_error != OK:
		failures.append("could not start SHA-256 hashing")
		return ""
	var update_error := context.update(bytes)
	if update_error != OK:
		failures.append("could not update SHA-256 hashing")
		return ""
	return context.finish().hex_encode()


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "could not write evidence file: %s" % path)
	if file != null:
		file.store_buffer(bytes)
		file.close()


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "could not write evidence receipt: %s" % path)
	if file != null:
		file.store_string(text)
		file.close()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
