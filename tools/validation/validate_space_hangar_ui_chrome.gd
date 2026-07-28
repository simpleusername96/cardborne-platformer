extends SceneTree

## Gate C candidate validator. It verifies the declared asset inventory,
## dimensions, alpha/palette contract, invariant 9-slice corners, visible state
## deltas, proof sizes, text-fit measurements, and recorded output hashes.

const RECIPE_DEFAULT := "res://pixel-art-production/assets/recipes/candidates/space-hangar-v2-ui.json"
const EVIDENCE_DEFAULT := "res://pixel-art-production/evidence/space-hangar-v2/ui"
const EXPECTED_CLEAN := [
	"button-disabled.png",
	"button-focus.png",
	"button-hover.png",
	"button-normal.png",
	"button-pressed.png",
	"card-disabled.png",
	"card-focus.png",
	"card-hover.png",
	"card-normal.png",
	"card-pressed.png",
	"card-selected.png",
	"hud-frame-normal.png",
	"panel-normal.png",
	"tab-focus.png",
	"tab-hovered.png",
	"tab-normal.png",
	"tab-selected.png",
]
const EXPECTED_PROOFS := [
	"en-1280x720.png",
	"en-1920x1080.png",
	"en-960x540.png",
	"ko-1280x720.png",
	"ko-1920x1080.png",
	"ko-960x540.png",
]

var _recipe_path := ""
var _evidence_path := ""
var _recipe: Dictionary = {}
var _errors: Array[String] = []
var _checks: Array[Dictionary] = []


func _initialize() -> void:
	_parse_arguments()
	if not _load_recipe():
		_finish()
		return
	_validate_inventory()
	_validate_clean_assets()
	_validate_state_families()
	_validate_proofs()
	_validate_hashes()
	_finish()


func _parse_arguments() -> void:
	_recipe_path = ProjectSettings.globalize_path(RECIPE_DEFAULT)
	_evidence_path = ProjectSettings.globalize_path(EVIDENCE_DEFAULT)
	for argument_value in OS.get_cmdline_user_args():
		var argument := String(argument_value)
		if argument.begins_with("--recipe="):
			_recipe_path = argument.trim_prefix("--recipe=")
		elif argument.begins_with("--evidence="):
			_evidence_path = argument.trim_prefix("--evidence=")
	_recipe_path = _recipe_path.replace("\\", "/")
	_evidence_path = _evidence_path.replace("\\", "/").trim_suffix("/")


func _load_recipe() -> bool:
	if not FileAccess.file_exists(_recipe_path):
		return _error("Recipe is missing: %s" % _recipe_path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_recipe_path))
	if not parsed is Dictionary:
		return _error("Recipe root is invalid.")
	_recipe = Dictionary(parsed)
	return _check("recipe_loaded", true, {"path": _recipe_path})


func _validate_inventory() -> void:
	var clean_path := _evidence_path.path_join("clean")
	var actual_clean := Array(DirAccess.get_files_at(clean_path))
	actual_clean.sort()
	_check(
		"clean_inventory",
		actual_clean == EXPECTED_CLEAN,
		{"expected": EXPECTED_CLEAN, "actual": actual_clean}
	)
	var proof_path := _evidence_path.path_join("proofs")
	var actual_proofs := Array(DirAccess.get_files_at(proof_path))
	actual_proofs.sort()
	_check(
		"proof_inventory",
		actual_proofs == EXPECTED_PROOFS,
		{"expected": EXPECTED_PROOFS, "actual": actual_proofs}
	)
	for relative in [
		"review/ui-chrome-contact-sheet-native.png",
		"review/ui-chrome-contact-sheet-4x.png",
		"review/ui-chrome-state-deltas.png",
		"review/contact-sheet-layout.json",
		"text-fit.json",
		"sha256.json",
	]:
		_check(
			"required_%s" % relative.replace("/", "_"),
			FileAccess.file_exists(_evidence_path.path_join(relative)),
			{"path": relative}
		)


func _validate_clean_assets() -> void:
	var palette := {}
	for value in Array(Dictionary(_recipe["source_family"])["palette"]):
		palette[Color(String(value)).to_html(false).to_upper()] = true
	for family_value in Array(_recipe["families"]):
		var family := Dictionary(family_value)
		var size_values := Array(family["native_size"])
		var expected_size := Vector2i(int(size_values[0]), int(size_values[1]))
		for output_value in Array(family["outputs"]):
			var name := String(output_value)
			var path := _evidence_path.path_join("clean").path_join(name)
			var image := Image.load_from_file(path)
			var loaded := image != null and not image.is_empty()
			_check("load_%s" % name, loaded, {"path": path})
			if not loaded:
				continue
			var rgba_format := image.get_format() == Image.FORMAT_RGBA8
			_check(
				"size_%s" % name,
				image.get_size() == expected_size,
				{"expected": expected_size, "actual": image.get_size()}
			)
			image.convert(Image.FORMAT_RGBA8)
			var invalid_colors := 0
			for y in image.get_height():
				for x in image.get_width():
					var color := image.get_pixel(x, y)
					if color.a < 0.5:
						continue
					if not palette.has(color.to_html(false).to_upper()):
						invalid_colors += 1
			_check(
				"palette_%s" % name,
				invalid_colors == 0,
				{"invalid_pixels": invalid_colors}
			)
			_check(
				"alpha_%s" % name,
				rgba_format,
				{"format": image.get_format(), "expected": Image.FORMAT_RGBA8}
			)


func _validate_state_families() -> void:
	for family_value in Array(_recipe["families"]):
		var family := Dictionary(family_value)
		var outputs := Array(family["outputs"])
		if outputs.size() <= 1:
			continue
		var normal := Image.load_from_file(
			_evidence_path.path_join("clean").path_join(String(outputs[0]))
		)
		var margins := Array(family["patch_margins"])
		for index in range(1, outputs.size()):
			var name := String(outputs[index])
			var current := Image.load_from_file(
				_evidence_path.path_join("clean").path_join(name)
			)
			if normal == null or current == null:
				continue
			var corner_equal := _patch_border_equal(normal, current, margins)
			var delta := _count_different_pixels(normal, current)
			_check(
				"patch_invariant_%s" % name,
				corner_equal,
				{"family": family["id"], "file": name}
			)
			_check(
				"state_delta_%s" % name,
				delta > 0,
				{"different_pixels": delta}
			)


func _patch_border_equal(left: Image, right: Image, margins: Array) -> bool:
	var l := int(margins[0])
	var r := int(margins[1])
	var t := int(margins[2])
	var b := int(margins[3])
	for y in left.get_height():
		for x in left.get_width():
			var in_corner := (
				(x < l or x >= left.get_width() - r)
				and (y < t or y >= left.get_height() - b)
			)
			if not in_corner:
				continue
			if not left.get_pixel(x, y).is_equal_approx(right.get_pixel(x, y)):
				return false
	return true


func _count_different_pixels(left: Image, right: Image) -> int:
	var count := 0
	for y in left.get_height():
		for x in left.get_width():
			if not left.get_pixel(x, y).is_equal_approx(right.get_pixel(x, y)):
				count += 1
	return count


func _validate_proofs() -> void:
	for proof_name in EXPECTED_PROOFS:
		var image := Image.load_from_file(
			_evidence_path.path_join("proofs").path_join(proof_name)
		)
		if image == null:
			continue
		var size_text: String = proof_name.get_basename().split("-")[-1]
		var dimensions: PackedStringArray = size_text.split("x")
		var expected := Vector2i(int(dimensions[0]), int(dimensions[1]))
		_check(
			"proof_size_%s" % proof_name,
			image.get_size() == expected,
			{"expected": expected, "actual": image.get_size()}
		)
	var text_fit_path := _evidence_path.path_join("text-fit.json")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(text_fit_path))
	var text_fit_valid := (
		parsed is Dictionary
		and bool(Dictionary(parsed).get("all_passed", false))
		and Array(Dictionary(parsed).get("records", [])).size() == 42
	)
	_check(
		"text_fit",
		text_fit_valid,
		{"expected_records": 42}
	)


func _validate_hashes() -> void:
	var path := _evidence_path.path_join("sha256.json")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_error("sha256.json is invalid.")
		return
	var files := Dictionary(Dictionary(parsed).get("files", {}))
	var mismatches: Array[String] = []
	for relative_value in files.keys():
		var relative := String(relative_value)
		var absolute := _evidence_path.path_join(relative)
		if (
			not FileAccess.file_exists(absolute)
			or FileAccess.get_sha256(absolute) != String(files[relative])
		):
			mismatches.append(relative)
	_check(
		"output_hashes",
		mismatches.is_empty(),
		{"count": files.size(), "mismatches": mismatches}
	)


func _finish() -> void:
	var result := {
		"schema_version": 1,
		"gate": "Gate C candidate",
		"status": "passed" if _errors.is_empty() else "failed",
		"checks": _checks,
		"errors": _errors,
		"runtime_publication_performed": false,
	}
	if DirAccess.dir_exists_absolute(_evidence_path):
		var file := FileAccess.open(
			_evidence_path.path_join("candidate-validation.json"),
			FileAccess.WRITE
		)
		if file != null:
			file.store_string(JSON.stringify(result, "\t", false) + "\n")
			file.close()
	if _errors.is_empty():
		print("SPACE_HANGAR_UI_VALIDATION_OK checks=%d" % _checks.size())
		quit(0)
	else:
		for message in _errors:
			push_error(message)
		quit(1)


func _check(name: String, passed: bool, details: Dictionary) -> bool:
	_checks.append({"name": name, "passed": passed, "details": details})
	if not passed:
		_errors.append("%s failed." % name)
	return passed


func _error(message: String) -> bool:
	_errors.append(message)
	return false
