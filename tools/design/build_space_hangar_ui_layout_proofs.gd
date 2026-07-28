extends SceneTree

## Builds screen-specific, candidate-only layout proofs from the existing UI
## chrome. The recipe owns current screen geometry; this script only performs
## 9-slice composition, live-text overlay, measurement, and review export.

const RECIPE_DEFAULT := "res://pixel-art-production/assets/recipes/candidates/space-hangar-v2-ui-layout-proofs.json"
const SCHEMA_PATH := "res://pixel-art-production/schemas/space-hangar-ui-layout-proofs.schema.json"
const EVIDENCE_ROOT := "res://pixel-art-production/evidence/space-hangar-v2/ui"
const PACKAGE_NAME := "layout-package"
const EXPECTED_SCREEN_IDS := [
	"deployment",
	"upgrade",
	"pause",
	"settings",
	"guidebook",
	"report",
	"garage",
]
const ASSET_MARGINS := {
	"panel": [16, 16, 16, 16],
	"button": [12, 12, 8, 8],
	"card": [16, 16, 16, 16],
	"tab": [12, 12, 8, 8],
	"hud-frame": [16, 16, 12, 12],
}

var _recipe_path := ""
var _evidence_path := ""
var _package_path := ""
var _staging_path := ""
var _backup_path := ""
var _check_only := false
var _recipe: Dictionary = {}
var _assets: Dictionary = {}
var _text_records: Array[Dictionary] = []
var _layout_records: Array[Dictionary] = []
var _hash_paths: Array[String] = []
var _last_error := ""


func _initialize() -> void:
	var arguments := _parse_arguments()
	if not bool(arguments["valid"]):
		_print_usage()
		quit(2)
		return
	_check_only = bool(arguments["check_only"])
	_recipe_path = String(arguments["recipe"])
	if _recipe_path.is_empty():
		_recipe_path = ProjectSettings.globalize_path(RECIPE_DEFAULT)
	_evidence_path = String(arguments["evidence"])
	if _evidence_path.is_empty():
		_evidence_path = ProjectSettings.globalize_path(EVIDENCE_ROOT)
	if not _validate_paths() or not _load_and_validate_recipe():
		push_error("SPACE_HANGAR_UI_LAYOUT_CONFIG_INVALID: %s" % _last_error)
		quit(1)
		return
	print("SPACE_HANGAR_UI_LAYOUT_CONFIG_OK")
	if _check_only:
		print("SPACE_HANGAR_UI_LAYOUT_CHECK_OK")
		quit(0)
		return
	if not _load_assets() or not _build_package():
		_discard_staging()
		push_error("SPACE_HANGAR_UI_LAYOUT_BUILD_FAILED: %s" % _last_error)
		quit(1)
		return
	print("SPACE_HANGAR_UI_LAYOUT_BUILD_OK output=%s" % _package_path)
	quit(0)


func _parse_arguments() -> Dictionary:
	var values := {
		"valid": true,
		"recipe": "",
		"evidence": "",
		"check_only": false,
	}
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var argument := String(args[index])
		if argument == "--check-only":
			values["check_only"] = true
		elif argument.begins_with("--recipe="):
			values["recipe"] = argument.trim_prefix("--recipe=")
		elif argument.begins_with("--evidence="):
			values["evidence"] = argument.trim_prefix("--evidence=")
		elif argument in ["--recipe", "--evidence"]:
			if index + 1 >= args.size():
				values["valid"] = false
				break
			index += 1
			values[argument.trim_prefix("--")] = String(args[index])
		else:
			values["valid"] = false
		index += 1
	return values


func _print_usage() -> void:
	print(
		"Usage: godot --headless --script "
		+ "res://tools/design/build_space_hangar_ui_layout_proofs.gd -- "
		+ "[--recipe <absolute.json>] [--evidence <absolute-ui-evidence-dir>] "
		+ "[--check-only]"
	)


func _validate_paths() -> bool:
	_recipe_path = _recipe_path.replace("\\", "/")
	_evidence_path = _evidence_path.replace("\\", "/").trim_suffix("/")
	if not _recipe_path.is_absolute_path() or not FileAccess.file_exists(_recipe_path):
		return _fail("Layout recipe must be an existing absolute path.")
	var canonical := ProjectSettings.globalize_path(EVIDENCE_ROOT).replace("\\", "/").trim_suffix("/")
	if _evidence_path.to_lower() != canonical.to_lower():
		return _fail("Evidence path must be the canonical candidate UI directory.")
	if not DirAccess.dir_exists_absolute(_evidence_path.path_join("clean")):
		return _fail("Clean UI chrome must exist before layout proof generation.")
	if not FileAccess.file_exists(ProjectSettings.globalize_path(SCHEMA_PATH)):
		return _fail("Layout proof schema is missing.")
	_package_path = _evidence_path.path_join(PACKAGE_NAME)
	_staging_path = _package_path + ".staging"
	_backup_path = _package_path + ".previous"
	for reserved in [_staging_path, _backup_path]:
		if DirAccess.dir_exists_absolute(reserved) or FileAccess.file_exists(reserved):
			return _fail("Reserved publish path exists: %s" % reserved)
	return true


func _load_and_validate_recipe() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_recipe_path))
	if not parsed is Dictionary:
		return _fail("Layout recipe root must be an object.")
	_recipe = Dictionary(parsed)
	var required := [
		"schema_version",
		"base_viewport",
		"viewports",
		"languages",
		"font",
		"screens",
	]
	if not _has_exact_keys(_recipe, required):
		return _fail("Layout recipe top-level keys do not match the contract.")
	if int(_recipe["schema_version"]) != 1:
		return _fail("Layout recipe schema_version must be 1.")
	if not _numeric_array_equals(Array(_recipe["base_viewport"]), [1280, 720]):
		return _fail("base_viewport must be [1280, 720].")
	if not _nested_numeric_array_equals(
		Array(_recipe["viewports"]),
		[[960, 540], [1280, 720], [1920, 1080]]
	):
		return _fail("viewports do not match the fixed proof set.")
	if Array(_recipe["languages"]) != ["ko", "en"]:
		return _fail("languages must be ko and en.")
	var screens := Array(_recipe["screens"])
	if screens.size() != EXPECTED_SCREEN_IDS.size():
		return _fail("Layout recipe must contain seven screens.")
	for index in screens.size():
		if not screens[index] is Dictionary:
			return _fail("Screen %d must be an object." % index)
		var screen := Dictionary(screens[index])
		if String(screen.get("id", "")) != EXPECTED_SCREEN_IDS[index]:
			return _fail("Screen order or id is invalid at index %d." % index)
		var panel_values := Array(screen.get("panel_rect", []))
		if panel_values.size() != 4:
			return _fail("Screen %s panel_rect is invalid." % screen["id"])
		var panel_rect := _scaled_rect(panel_values, 1.0)
		if panel_rect.position.x * 2 + panel_rect.size.x != 1280:
			return _fail("Screen %s panel is not horizontally centered." % screen["id"])
		for reference_key in ["reference_ko", "reference_en"]:
			var reference_path := ProjectSettings.globalize_path(
				"res://%s" % String(screen.get(reference_key, ""))
			)
			if not FileAccess.file_exists(reference_path):
				return _fail(
					"Screen %s reference is missing: %s"
					% [screen["id"], reference_path]
				)
		if Array(screen.get("elements", [])).is_empty():
			return _fail("Screen %s has no chrome elements." % screen["id"])
		if Array(screen.get("texts", [])).is_empty():
			return _fail("Screen %s has no text overlays." % screen["id"])
	return true


func _load_assets() -> bool:
	var names := {}
	for screen_value in Array(_recipe["screens"]):
		for element_value in Array(Dictionary(screen_value)["elements"]):
			names[String(Dictionary(element_value)["asset"])] = true
	for name_value in names.keys():
		var name := String(name_value)
		var path := _evidence_path.path_join("clean").path_join(name)
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			return _fail("Layout asset is missing or unreadable: %s" % path)
		_assets[name] = image
	return true


func _build_package() -> bool:
	if DirAccess.make_dir_recursive_absolute(_staging_path.path_join("proofs")) != OK:
		return _fail("Cannot create layout proof staging directory.")
	if DirAccess.make_dir_recursive_absolute(_staging_path.path_join("review")) != OK:
		return _fail("Cannot create layout review staging directory.")
	var font_path := ProjectSettings.globalize_path(
		"res://%s" % String(_recipe["font"])
	).replace("\\", "/")
	if not FileAccess.file_exists(font_path):
		return _fail("Layout proof font is missing: %s" % font_path)
	for screen_value in Array(_recipe["screens"]):
		var screen := Dictionary(screen_value)
		for viewport_value in Array(_recipe["viewports"]):
			var viewport_array := Array(viewport_value)
			var viewport := Vector2i(
				int(viewport_array[0]),
				int(viewport_array[1])
			)
			for language_value in Array(_recipe["languages"]):
				var language := String(language_value)
				if not _build_screen_proof(screen, viewport, language, font_path):
					return false
		if not _build_reference_review(screen):
			return false
	if not _write_metadata():
		return false
	return _publish()


func _build_screen_proof(
	screen: Dictionary,
	viewport: Vector2i,
	language: String,
	font_path: String
) -> bool:
	var scale := float(viewport.x) / 1280.0
	var canvas := Image.create_empty(
		viewport.x,
		viewport.y,
		false,
		Image.FORMAT_RGBA8
	)
	canvas.fill(Color("#0B1118"))
	for element_value in Array(screen["elements"]):
		var element := Dictionary(element_value)
		var asset_name := String(element["asset"])
		var rect := _scaled_rect(Array(element["rect"]), scale)
		_blit_nine_slice(
			canvas,
			_assets[asset_name],
			rect,
			_margins_for_asset(asset_name)
		)
	var screen_id := String(screen["id"])
	var base_path := _staging_path.path_join(
		"_base-%s-%s-%dx%d.png"
		% [screen_id, language, viewport.x, viewport.y]
	)
	if canvas.save_png(base_path) != OK:
		return _fail("Cannot save layout proof base: %s" % base_path)
	var relative := "proofs/%s-%s-%dx%d.png" % [
		screen_id,
		language,
		viewport.x,
		viewport.y,
	]
	var final_path := _staging_path.path_join(relative)
	var args: Array[String] = [base_path, "-font", font_path]
	for text_value in Array(screen["texts"]):
		var text_spec := Dictionary(text_value)
		var value := String(text_spec[language])
		var box := _scaled_rect(Array(text_spec["rect"]), scale)
		var point_size := maxi(10, int(round(float(text_spec["point_size"]) * scale)))
		var measurement := _measure_text(value, point_size, font_path)
		var vertical_tolerance := maxi(4, point_size / 4)
		if (
			measurement.x > box.size.x
			or measurement.y > box.size.y + vertical_tolerance
		):
			DirAccess.remove_absolute(base_path)
			return _fail(
				"Text does not fit %s/%s/%s at %s: measured=%s box=%s."
				% [
					screen_id,
					language,
					text_spec["role"],
					viewport,
					measurement,
					box.size,
				]
			)
		var position := _aligned_text_position(
			box,
			measurement,
			String(text_spec["align"])
		)
		_text_records.append({
			"screen": screen_id,
			"language": language,
			"viewport": [viewport.x, viewport.y],
			"role": text_spec["role"],
			"text": value,
			"point_size": point_size,
			"measured": [measurement.x, measurement.y],
			"box": [box.size.x, box.size.y],
			"passed": true,
		})
		args.append_array([
			"-pointsize",
			str(point_size),
			"-fill",
			String(text_spec["color"]),
			"-gravity",
			"NorthWest",
			"-annotate",
			"+%d+%d" % [position.x, position.y],
			value,
		])
	args.append("-strip")
	args.append(final_path)
	var output: Array = []
	var exit_code := OS.execute("magick", args, output, true)
	DirAccess.remove_absolute(base_path)
	if exit_code != 0 or not FileAccess.file_exists(final_path):
		return _fail(
			"ImageMagick could not render %s: %s"
			% [relative, "\n".join(output)]
		)
	_hash_paths.append(relative)
	var panel_rect := _scaled_rect(Array(screen["panel_rect"]), scale)
	var left_margin := panel_rect.position.x
	var right_margin := viewport.x - panel_rect.end.x
	_layout_records.append({
		"screen": screen_id,
		"language": language,
		"viewport": [viewport.x, viewport.y],
		"panel_rect": [
			panel_rect.position.x,
			panel_rect.position.y,
			panel_rect.size.x,
			panel_rect.size.y,
		],
		"left_margin": left_margin,
		"right_margin": right_margin,
		"center_offset_px": left_margin - right_margin,
		"horizontally_centered": abs(left_margin - right_margin) <= 1,
	})
	return true


func _build_reference_review(screen: Dictionary) -> bool:
	var screen_id := String(screen["id"])
	var reference := ProjectSettings.globalize_path(
		"res://%s" % String(screen["reference_ko"])
	).replace("\\", "/")
	var proof := _staging_path.path_join(
		"proofs/%s-ko-1280x720.png" % screen_id
	)
	var relative := "review/%s-ko-reference-vs-candidate.png" % screen_id
	var output_path := _staging_path.path_join(relative)
	var output: Array = []
	var exit_code := OS.execute(
		"magick",
		[
			reference,
			proof,
			"+append",
			"-strip",
			output_path,
		],
		output,
		true
	)
	if exit_code != 0 or not FileAccess.file_exists(output_path):
		return _fail(
			"Cannot build reference review for %s: %s"
			% [screen_id, "\n".join(output)]
		)
	_hash_paths.append(relative)
	return true


func _measure_text(value: String, point_size: int, font_path: String) -> Vector2i:
	var width := 0
	var height := 0
	for line in value.split("\n"):
		var output: Array = []
		var exit_code := OS.execute(
			"magick",
			[
				"-font",
				font_path,
				"-pointsize",
				str(point_size),
				"label:%s" % line,
				"-format",
				"%w %h",
				"info:",
			],
			output,
			true
		)
		if exit_code != 0 or output.is_empty():
			return Vector2i(2147483647, 2147483647)
		var parts := String(output[0]).strip_edges().split(" ", false)
		if parts.size() < 2:
			return Vector2i(2147483647, 2147483647)
		width = maxi(width, int(parts[0]))
		height += int(parts[1])
	return Vector2i(width, height)


func _aligned_text_position(
	box: Rect2i,
	measurement: Vector2i,
	align: String
) -> Vector2i:
	var x := box.position.x
	if align == "center":
		x += (box.size.x - measurement.x) / 2
	elif align == "right":
		x += box.size.x - measurement.x
	var y := box.position.y + maxi(0, (box.size.y - measurement.y) / 2)
	return Vector2i(x, y)


func _margins_for_asset(asset_name: String) -> Array:
	for prefix in ASSET_MARGINS.keys():
		if asset_name.begins_with("%s-" % String(prefix)):
			return Array(ASSET_MARGINS[prefix])
	return [16, 16, 16, 16]


func _blit_nine_slice(
	target: Image,
	source: Image,
	target_rect: Rect2i,
	margins: Array
) -> void:
	var left := int(margins[0])
	var right := int(margins[1])
	var top := int(margins[2])
	var bottom := int(margins[3])
	var source_x := [0, left, source.get_width() - right, source.get_width()]
	var source_y := [0, top, source.get_height() - bottom, source.get_height()]
	var target_x := [
		target_rect.position.x,
		target_rect.position.x + left,
		target_rect.end.x - right,
		target_rect.end.x,
	]
	var target_y := [
		target_rect.position.y,
		target_rect.position.y + top,
		target_rect.end.y - bottom,
		target_rect.end.y,
	]
	for row in 3:
		for column in 3:
			var source_rect := Rect2i(
				source_x[column],
				source_y[row],
				source_x[column + 1] - source_x[column],
				source_y[row + 1] - source_y[row]
			)
			var patch := source.get_region(source_rect)
			var target_size := Vector2i(
				target_x[column + 1] - target_x[column],
				target_y[row + 1] - target_y[row]
			)
			if patch.get_size() != target_size:
				patch.resize(
					target_size.x,
					target_size.y,
					Image.INTERPOLATE_NEAREST
				)
			target.blit_rect(
				patch,
				Rect2i(Vector2i.ZERO, patch.get_size()),
				Vector2i(target_x[column], target_y[row])
			)


func _write_metadata() -> bool:
	if not _write_json("text-fit.json", {
		"schema_version": 1,
		"all_passed": true,
		"records": _text_records,
	}):
		return false
	if not _write_json("layout-metrics.json", {
		"schema_version": 1,
		"base_viewport": _recipe["base_viewport"],
		"records": _layout_records,
	}):
		return false
	var hashes := {}
	for relative in _hash_paths:
		hashes[relative] = FileAccess.get_sha256(
			_staging_path.path_join(relative)
		)
	return _write_json("sha256.json", {
		"schema_version": 1,
		"recipe_sha256": FileAccess.get_sha256(_recipe_path),
		"schema_sha256": FileAccess.get_sha256(
			ProjectSettings.globalize_path(SCHEMA_PATH)
		),
		"files": hashes,
	})


func _write_json(relative: String, value: Variant) -> bool:
	var path := _staging_path.path_join(relative)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot write layout metadata: %s" % path)
	file.store_string(JSON.stringify(value, "\t", false) + "\n")
	file.close()
	_hash_paths.append(relative)
	return true


func _publish() -> bool:
	if DirAccess.dir_exists_absolute(_package_path):
		if DirAccess.rename_absolute(_package_path, _backup_path) != OK:
			return _fail("Cannot move the previous layout package to backup.")
	if DirAccess.rename_absolute(_staging_path, _package_path) != OK:
		if DirAccess.dir_exists_absolute(_backup_path):
			DirAccess.rename_absolute(_backup_path, _package_path)
		return _fail("Cannot publish the layout proof package.")
	if DirAccess.dir_exists_absolute(_backup_path):
		_remove_tree(_backup_path)
	return true


func _discard_staging() -> void:
	if DirAccess.dir_exists_absolute(_staging_path):
		_remove_tree(_staging_path)


func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _scaled_rect(values: Array, scale: float) -> Rect2i:
	return Rect2i(
		int(round(float(values[0]) * scale)),
		int(round(float(values[1]) * scale)),
		int(round(float(values[2]) * scale)),
		int(round(float(values[3]) * scale))
	)


func _numeric_array_equals(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if not is_equal_approx(float(left[index]), float(right[index])):
			return false
	return true


func _nested_numeric_array_equals(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if not _numeric_array_equals(Array(left[index]), Array(right[index])):
			return false
	return true


func _has_exact_keys(value: Dictionary, keys: Array) -> bool:
	if value.size() != keys.size():
		return false
	for key in keys:
		if not value.has(key):
			return false
	return true


func _fail(message: String) -> bool:
	_last_error = message
	return false
