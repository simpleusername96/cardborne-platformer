extends SceneTree

## Candidate-only compiler for Space Hangar V2 UI chrome. It crops the
## generated master, removes chroma, palette-maps pixels, derives state
## modulation, and renders review proofs. It never writes runtime UI paths.

const RECIPE_DEFAULT := "res://pixel-art-production/assets/recipes/candidates/space-hangar-v2-ui.json"
const SCHEMA_PATH := "res://pixel-art-production/schemas/space-hangar-ui-chrome.schema.json"
const OUTPUT_CANONICAL := "res://pixel-art-production/evidence/space-hangar-v2/ui"
const OUTPUT_STAGING_SUFFIX := ".space-hangar-ui-staging"
const OUTPUT_BACKUP_SUFFIX := ".space-hangar-ui-previous"
const EXPECTED_FAMILIES := ["panel", "button", "card", "tab", "hud-frame"]
const EXPECTED_SIZES := {
	"panel": Vector2i(96, 96),
	"button": Vector2i(96, 32),
	"card": Vector2i(96, 128),
	"tab": Vector2i(72, 32),
	"hud-frame": Vector2i(128, 48),
}
const EXPECTED_STATES := {
	"panel": ["normal"],
	"button": ["normal", "hover", "pressed", "focus", "disabled"],
	"card": ["normal", "hover", "pressed", "focus", "selected", "disabled"],
	"tab": ["normal", "hovered", "selected", "focus"],
	"hud-frame": ["normal"],
}

var _recipe_path := ""
var _output_path := ""
var _staging_path := ""
var _backup_path := ""
var _check_only := false
var _recipe: Dictionary = {}
var _palette: Array[Color] = []
var _families: Array[Dictionary] = []
var _clean_images: Dictionary = {}
var _hash_paths: Array[String] = []
var _text_fit_records: Array[Dictionary] = []
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
	_output_path = String(arguments["output"])
	if _output_path.is_empty():
		_output_path = ProjectSettings.globalize_path(OUTPUT_CANONICAL)
	if not _validate_paths() or not _load_and_validate_recipe():
		push_error("SPACE_HANGAR_UI_CONFIG_INVALID: %s" % _last_error)
		quit(1)
		return
	print("SPACE_HANGAR_UI_CONFIG_OK")
	if _check_only:
		print("SPACE_HANGAR_UI_CHECK_OK")
		quit(0)
		return
	if not _compile():
		_discard_staging()
		push_error("SPACE_HANGAR_UI_BUILD_FAILED: %s" % _last_error)
		quit(1)
		return
	print("SPACE_HANGAR_UI_BUILD_OK output=%s" % _output_path)
	quit(0)


func _parse_arguments() -> Dictionary:
	var values := {"valid": true, "recipe": "", "output": "", "check_only": false}
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg := String(args[index])
		if arg == "--check-only":
			values["check_only"] = true
		elif arg.begins_with("--recipe="):
			values["recipe"] = arg.trim_prefix("--recipe=")
		elif arg.begins_with("--output="):
			values["output"] = arg.trim_prefix("--output=")
		elif arg in ["--recipe", "--output"]:
			if index + 1 >= args.size():
				values["valid"] = false
				break
			index += 1
			values[arg.trim_prefix("--")] = String(args[index])
		else:
			values["valid"] = false
		index += 1
	return values


func _print_usage() -> void:
	print(
		"Usage: godot --headless --script res://tools/design/build_space_hangar_ui_chrome.gd -- "
		+ "[--recipe <absolute.json>] [--output <absolute-evidence-ui-dir>] [--check-only]"
	)


func _validate_paths() -> bool:
	_recipe_path = _recipe_path.replace("\\", "/")
	_output_path = _output_path.replace("\\", "/").trim_suffix("/")
	if not _recipe_path.is_absolute_path() or not FileAccess.file_exists(_recipe_path):
		return _fail("Recipe must be an existing absolute JSON path.")
	var canonical := ProjectSettings.globalize_path(OUTPUT_CANONICAL).replace("\\", "/").trim_suffix("/")
	if _output_path.to_lower() != canonical.to_lower():
		return _fail("Output is candidate-only and must be %s." % canonical)
	if not FileAccess.file_exists(ProjectSettings.globalize_path(SCHEMA_PATH)):
		return _fail("UI chrome schema is missing.")
	_staging_path = _output_path + OUTPUT_STAGING_SUFFIX
	_backup_path = _output_path + OUTPUT_BACKUP_SUFFIX
	for reserved in [_staging_path, _backup_path]:
		if DirAccess.dir_exists_absolute(reserved) or FileAccess.file_exists(reserved):
			return _fail("Reserved publish path exists: %s" % reserved)
	return true


func _load_and_validate_recipe() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_recipe_path))
	if not parsed is Dictionary:
		return _fail("Recipe root must be an object.")
	_recipe = Dictionary(parsed)
	var required := ["schema_version", "source_family", "families", "theme_targets", "proofs"]
	if not _has_exact_keys(_recipe, required):
		return _fail("Recipe top-level keys do not match the fixed contract.")
	if int(_recipe["schema_version"]) != 1:
		return _fail("schema_version must be 1.")
	var source := Dictionary(_recipe["source_family"])
	if (
		String(source.get("id", "")) != "space-hangar-v2-ui"
		or not _array_equals(Array(source.get("raw_size", [])), [1024, 1024])
		or String(source.get("chroma_key", "")).to_upper() != "#FF00FF"
	):
		return _fail(
			"Source family does not match the fixed contract: id=%s size=%s chroma=%s."
			% [
				source.get("id", ""),
				source.get("raw_size", []),
				source.get("chroma_key", ""),
			]
		)
	var raw_path := ProjectSettings.globalize_path("res://%s" % String(source.get("raw", "")))
	if not FileAccess.file_exists(raw_path):
		return _fail("Normalized raw source is missing: %s" % raw_path)
	for color_value in Array(source.get("palette", [])):
		_palette.append(Color(String(color_value)))
	if _palette.size() != 8:
		return _fail("Source palette must contain exactly eight colors.")
	var family_values := Array(_recipe["families"])
	if family_values.size() != EXPECTED_FAMILIES.size():
		return _fail("Recipe must contain five UI families.")
	for index in family_values.size():
		if not family_values[index] is Dictionary:
			return _fail("Family %d must be an object." % index)
		var family := Dictionary(family_values[index])
		var family_id := String(family.get("id", ""))
		if family_id != EXPECTED_FAMILIES[index]:
			return _fail("Family order or id is invalid at index %d." % index)
		if not _array_equals(Array(family.get("native_size", [])), [
			EXPECTED_SIZES[family_id].x, EXPECTED_SIZES[family_id].y
		]):
			return _fail("Family %s has an invalid native size." % family_id)
		if not _array_equals(
			Array(family.get("states", [])),
			Array(EXPECTED_STATES[family_id])
		):
			return _fail("Family %s has an invalid state list." % family_id)
		var outputs := Array(family.get("outputs", []))
		if outputs.size() != Array(EXPECTED_STATES[family_id]).size():
			return _fail("Family %s output/state counts differ." % family_id)
		if Array(family.get("source_region", [])).size() != 4:
			return _fail("Family %s source region is invalid." % family_id)
		if Array(family.get("patch_margins", [])).size() != 4:
			return _fail("Family %s patch margins are invalid." % family_id)
		if Array(family.get("content_insets", [])).size() != 4:
			return _fail("Family %s content insets are invalid." % family_id)
		_families.append(family)
	return true


func _compile() -> bool:
	if DirAccess.make_dir_recursive_absolute(_staging_path) != OK:
		return _fail("Cannot create staging directory.")
	for child in ["clean", "review", "proofs"]:
		if DirAccess.make_dir_recursive_absolute(_staging_path.path_join(child)) != OK:
			return _fail("Cannot create staging child directory: %s" % child)
	var source := Dictionary(_recipe["source_family"])
	var raw := Image.load_from_file(
		ProjectSettings.globalize_path("res://%s" % String(source["raw"]))
	)
	if raw == null or raw.get_size() != Vector2i(1024, 1024):
		return _fail("Normalized raw source is unreadable or has the wrong size.")
	for family in _families:
		if not _build_family(raw, family):
			return false
	if not _build_contact_sheets():
		return false
	if not _build_proofs():
		return false
	if not _write_metadata():
		return false
	return _publish_staging()


func _build_family(raw: Image, family: Dictionary) -> bool:
	var family_id := String(family["id"])
	var source_rect := _rect_from_array(Array(family["source_region"]))
	var base := raw.get_region(source_rect)
	_remove_chroma_and_quantize(base)
	var native_size: Vector2i = EXPECTED_SIZES[family_id]
	base.resize(native_size.x, native_size.y, Image.INTERPOLATE_NEAREST)
	_remove_chroma_and_quantize(base)
	var states := Array(family["states"])
	var outputs := Array(family["outputs"])
	for index in states.size():
		var state := String(states[index])
		var output_name := String(outputs[index])
		var state_image := base.duplicate()
		_apply_state_modulation(
			state_image,
			state,
			Array(family["patch_margins"])
		)
		var relative := "clean/%s" % output_name
		if not _save_image(state_image, relative):
			return false
		_clean_images[output_name] = state_image
	return true


func _remove_chroma_and_quantize(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if _is_chroma(color):
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var mapped := _closest_palette_color(color)
				mapped.a = 1.0
				image.set_pixel(x, y, mapped)


func _is_chroma(color: Color) -> bool:
	return (
		color.r >= 0.62
		and color.b >= 0.62
		and color.g <= 0.42
		and color.r - color.g >= 0.30
		and color.b - color.g >= 0.30
	)


func _closest_palette_color(color: Color) -> Color:
	var best := _palette[0]
	var best_distance := INF
	for candidate in _palette:
		var distance := (
			pow(color.r - candidate.r, 2.0)
			+ pow(color.g - candidate.g, 2.0)
			+ pow(color.b - candidate.b, 2.0)
		)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _apply_state_modulation(
	image: Image,
	state: String,
	margins: Array
) -> void:
	if state == "normal":
		return
	var left := int(margins[0])
	var right := int(margins[1])
	var top := int(margins[2])
	var bottom := int(margins[3])
	if state in ["focus", "selected"]:
		for y in image.get_height():
			for x in image.get_width():
				var in_corner := (
					(x < left or x >= image.get_width() - right)
					and (y < top or y >= image.get_height() - bottom)
				)
				if in_corner:
					continue
				var rail_color := image.get_pixel(x, y)
				if rail_color.a < 0.5:
					continue
				var rail_index := _palette_index(rail_color)
				if rail_index in [5, 6]:
					image.set_pixel(
						x,
						y,
						_palette[6] if state == "focus" else _palette[7]
					)
		return
	for y in range(top, image.get_height() - bottom):
		for x in range(left, image.get_width() - right):
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			image.set_pixel(x, y, _state_color(color, state))


func _state_color(color: Color, state: String) -> Color:
	var index := _palette_index(color)
	if state in ["hover", "hovered"]:
		var hover_map := [0, 2, 3, 4, 4, 6, 6, 7]
		return _palette[hover_map[index]]
	if state == "pressed":
		var pressed_map := [0, 0, 1, 2, 3, 1, 3, 5]
		return _palette[pressed_map[index]]
	if state == "disabled":
		var disabled_map := [0, 1, 1, 2, 2, 2, 3, 2]
		return _palette[disabled_map[index]]
	return color


func _palette_index(color: Color) -> int:
	for index in _palette.size():
		if color.is_equal_approx(_palette[index]):
			return index
	return 0


func _build_contact_sheets() -> bool:
	var native := Image.create_empty(640, 480, false, Image.FORMAT_RGBA8)
	native.fill(Color("#0B1118"))
	var x := 16
	var y := 16
	var row_height := 0
	for family in _families:
		var outputs := Array(family["outputs"])
		for output_value in outputs:
			var output_name := String(output_value)
			var image: Image = _clean_images[output_name]
			if x + image.get_width() > native.get_width() - 16:
				x = 16
				y += row_height + 16
				row_height = 0
			native.blit_rect(
				image,
				Rect2i(Vector2i.ZERO, image.get_size()),
				Vector2i(x, y)
			)
			x += image.get_width() + 16
			row_height = maxi(row_height, image.get_height())
	if not _save_image(native, "review/ui-chrome-contact-sheet-native.png"):
		return false
	var enlarged := native.duplicate()
	enlarged.resize(
		native.get_width() * 4,
		native.get_height() * 4,
		Image.INTERPOLATE_NEAREST
	)
	if not _save_image(enlarged, "review/ui-chrome-contact-sheet-4x.png"):
		return false
	var delta := Image.create_empty(640, 480, false, Image.FORMAT_RGBA8)
	delta.fill(Color("#0B1118"))
	x = 16
	y = 16
	row_height = 0
	for family in _families:
		var outputs := Array(family["outputs"])
		var normal: Image = _clean_images[String(outputs[0])]
		for output_index in outputs.size():
			var output_name := String(outputs[output_index])
			var current: Image = _clean_images[output_name]
			if x + current.get_width() > delta.get_width() - 16:
				x = 16
				y += row_height + 16
				row_height = 0
			var diff := _state_delta(normal, current)
			delta.blit_rect(diff, Rect2i(Vector2i.ZERO, diff.get_size()), Vector2i(x, y))
			x += diff.get_width() + 16
			row_height = maxi(row_height, diff.get_height())
	if not _save_image(delta, "review/ui-chrome-state-deltas.png"):
		return false
	return _write_json(
		"review/contact-sheet-layout.json",
		{"family_order": EXPECTED_FAMILIES, "families": _families}
	)


func _state_delta(normal: Image, current: Image) -> Image:
	var result := Image.create_empty(
		current.get_width(), current.get_height(), false, Image.FORMAT_RGBA8
	)
	for y in current.get_height():
		for x in current.get_width():
			var a := normal.get_pixel(x, y)
			var b := current.get_pixel(x, y)
			if a.is_equal_approx(b):
				result.set_pixel(x, y, Color("#202833"))
			else:
				result.set_pixel(x, y, Color("#D9A83D"))
	return result


func _build_proofs() -> bool:
	var proof_spec := Dictionary(_recipe["proofs"])
	var font_path := ProjectSettings.globalize_path(
		"res://%s" % String(proof_spec["font"])
	).replace("\\", "/")
	if not FileAccess.file_exists(font_path):
		return _fail("Proof font is missing: %s" % font_path)
	for viewport_value in Array(proof_spec["viewports"]):
		var viewport_array := Array(viewport_value)
		var viewport := Vector2i(int(viewport_array[0]), int(viewport_array[1]))
		for language_value in Array(proof_spec["languages"]):
			var language := String(language_value)
			if not _build_one_proof(viewport, language, font_path):
				return false
	return true


func _build_one_proof(
	viewport: Vector2i,
	language: String,
	font_path: String
) -> bool:
	var scale := float(viewport.x) / 1280.0
	var canvas := Image.create_empty(
		viewport.x, viewport.y, false, Image.FORMAT_RGBA8
	)
	canvas.fill(Color("#0B1118"))
	var modal_size := Vector2i(
		mini(int(round(720.0 * scale)), viewport.x - 64),
		mini(int(round(520.0 * scale)), viewport.y - 32)
	)
	var modal_pos := (viewport - modal_size) / 2
	_blit_nine_slice(canvas, _clean_images["panel-normal.png"], Rect2i(modal_pos, modal_size), [16, 16, 16, 16])
	var padding := maxi(24, int(round(40.0 * scale)))
	var tab_rect := Rect2i(
		modal_pos + Vector2i(padding, padding),
		Vector2i(int(round(180.0 * scale)), maxi(40, int(round(48.0 * scale))))
	)
	_blit_nine_slice(canvas, _clean_images["tab-selected.png"], tab_rect, [12, 12, 8, 8])
	var hud_rect := Rect2i(
		Vector2i(maxi(16, int(round(24.0 * scale))), maxi(16, int(round(24.0 * scale)))),
		Vector2i(int(round(250.0 * scale)), maxi(52, int(round(60.0 * scale))))
	)
	_blit_nine_slice(canvas, _clean_images["hud-frame-normal.png"], hud_rect, [16, 16, 12, 12])
	var font_size := maxi(12, int(round(18.0 * scale)))
	var title_size := maxi(14, int(round(24.0 * scale)))
	var card_gap := maxi(8, int(round(12.0 * scale)))
	var title_y := modal_pos.y + padding + tab_rect.size.y + 12
	var cards_top := title_y + title_size * 2 + 8
	var cards_width := modal_size.x - padding * 2
	var card_width := (cards_width - card_gap * 2) / 3
	var card_height := int(round(230.0 * scale))
	var card_rects: Array[Rect2i] = []
	for index in 3:
		var card_rect := Rect2i(
			Vector2i(modal_pos.x + padding + index * (card_width + card_gap), cards_top),
			Vector2i(card_width, card_height)
		)
		var asset_name := "card-selected.png" if index == 0 else "card-normal.png"
		_blit_nine_slice(canvas, _clean_images[asset_name], card_rect, [16, 16, 16, 16])
		card_rects.append(card_rect)
	var button_size := Vector2i(
		int(round(300.0 * scale)),
		maxi(44, int(round(48.0 * scale)))
	)
	var button_rect := Rect2i(
		Vector2i(
			modal_pos.x + (modal_size.x - button_size.x) / 2,
			modal_pos.y + modal_size.y - padding - button_size.y
		),
		button_size
	)
	_blit_nine_slice(canvas, _clean_images["button-focus.png"], button_rect, [12, 12, 8, 8])
	var base_name := "_proof-base-%s-%dx%d.png" % [language, viewport.x, viewport.y]
	var base_path := _staging_path.path_join(base_name)
	if canvas.save_png(base_path) != OK:
		return _fail("Cannot save proof base: %s" % base_path)
	var final_relative := "proofs/%s-%dx%d.png" % [language, viewport.x, viewport.y]
	var final_path := _staging_path.path_join(final_relative)
	var text_items := _proof_text_items(
		language,
		modal_pos,
		padding,
		tab_rect,
		hud_rect,
		card_rects,
		button_rect,
		font_size,
		title_size
	)
	var args: Array[String] = [base_path, "-font", font_path]
	for item in text_items:
		var fit := _measure_and_record_text(
			String(item["text"]),
			int(item["point_size"]),
			Vector2i(item["box_size"]),
			font_path,
			language,
			viewport,
			String(item["role"])
		)
		if not fit:
			return _fail(
				"Text-fit proof failed for %s %s %s."
				% [language, viewport, item["role"]]
			)
		args.append_array([
			"-pointsize", str(item["point_size"]),
			"-fill", String(item["color"]),
			"-gravity", "NorthWest",
			"-annotate",
			"+%d+%d" % [item["position"].x, item["position"].y],
			String(item["text"]),
		])
	args.append("-strip")
	args.append(final_path)
	var output: Array = []
	var exit_code := OS.execute("magick", args, output, true)
	DirAccess.remove_absolute(base_path)
	if exit_code != 0 or not FileAccess.file_exists(final_path):
		return _fail("ImageMagick could not render proof: %s" % "\n".join(output))
	_hash_paths.append(final_relative)
	return true


func _proof_text_items(
	language: String,
	modal_pos: Vector2i,
	padding: int,
	tab_rect: Rect2i,
	hud_rect: Rect2i,
	card_rects: Array[Rect2i],
	button_rect: Rect2i,
	font_size: int,
	title_size: int
) -> Array[Dictionary]:
	var ko := language == "ko"
	var items: Array[Dictionary] = []
	items.append(_text_item(
		"hud", "선체 120 / 120" if ko else "HULL 120 / 120",
		hud_rect.position + Vector2i(20, 16),
		hud_rect.size - Vector2i(40, 24), font_size, "#F1E6BE"
	))
	items.append(_text_item(
		"tab", "현재 함선" if ko else "Current Ship",
		tab_rect.position + Vector2i(18, 11),
		tab_rect.size - Vector2i(36, 16), font_size, "#F1E6BE"
	))
	items.append(_text_item(
		"title", "회로 하나를 선택하세요" if ko else "Choose one circuit",
		modal_pos + Vector2i(padding, padding + tab_rect.size.y + 12),
		Vector2i(
			card_rects[2].end.x - card_rects[0].position.x,
			maxi(40, title_size * 2)
		),
		title_size, "#F1E6BE"
	))
	var card_texts := [
		"분기 포구\n측면 탄환 +1\n레벨 0 → 1" if ko else "Branch Port\nSide round +1\nLevel 0 → 1",
		"빙결 코어\n동결 확률 +20%\n레벨 0 → 1" if ko else "Cryo Core\nFreeze chance\n+20%\nLevel 0 → 1",
		"추적탄\n피해 ×1.20\n레벨 0 → 1" if ko else "Seeker Round\nDamage ×1.20\nLevel 0 → 1",
	]
	for index in 3:
		items.append(_text_item(
			"card-%d" % index,
			card_texts[index],
			card_rects[index].position + Vector2i(22, 24),
			card_rects[index].size - Vector2i(44, 44),
			font_size,
			"#F1E6BE"
		))
	items.append(_text_item(
		"button", "장착" if ko else "Equip",
		button_rect.position + Vector2i(button_rect.size.x / 2 - 36, 10),
		Vector2i(button_rect.size.x - 40, button_rect.size.y - 12),
		font_size, "#F1E6BE"
	))
	return items


func _text_item(
	role: String,
	text: String,
	position: Vector2i,
	box_size: Vector2i,
	point_size: int,
	color: String
) -> Dictionary:
	return {
		"role": role,
		"text": text,
		"position": position,
		"box_size": box_size,
		"point_size": point_size,
		"color": color,
	}


func _measure_and_record_text(
	value: String,
	point_size: int,
	box_size: Vector2i,
	font_path: String,
	language: String,
	viewport: Vector2i,
	role: String
) -> bool:
	var max_width := 0
	var total_height := 0
	for line in value.split("\n"):
		var output: Array = []
		var exit_code := OS.execute(
			"magick",
			[
				"-font", font_path,
				"-pointsize", str(point_size),
				"label:%s" % line,
				"-format", "%w %h",
				"info:",
			],
			output,
			true
		)
		if exit_code != 0 or output.is_empty():
			return false
		var parts := String(output[0]).strip_edges().split(" ", false)
		if parts.size() < 2:
			return false
		max_width = maxi(max_width, int(parts[0]))
		total_height += int(parts[1])
	var passed := max_width <= box_size.x and total_height <= box_size.y
	_text_fit_records.append({
		"language": language,
		"viewport": [viewport.x, viewport.y],
		"role": role,
		"text": value,
		"point_size": point_size,
		"measured": [max_width, total_height],
		"box": [box_size.x, box_size.y],
		"passed": passed,
	})
	return passed


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
	var all_passed := true
	for record in _text_fit_records:
		if not bool(record["passed"]):
			all_passed = false
	if not _write_json("text-fit.json", {
		"schema_version": 1,
		"all_passed": all_passed,
		"records": _text_fit_records,
	}):
		return false
	var hashes := {}
	for path in _hash_paths:
		hashes[path] = FileAccess.get_sha256(_staging_path.path_join(path))
	return _write_json("sha256.json", {
		"schema_version": 1,
		"recipe_sha256": FileAccess.get_sha256(_recipe_path),
		"schema_sha256": FileAccess.get_sha256(ProjectSettings.globalize_path(SCHEMA_PATH)),
		"files": hashes,
	})


func _save_image(image: Image, relative_path: String) -> bool:
	var absolute := _staging_path.path_join(relative_path)
	if image.save_png(absolute) != OK:
		return _fail("Cannot save image: %s" % absolute)
	_hash_paths.append(relative_path)
	return true


func _write_json(relative_path: String, value: Variant) -> bool:
	var absolute := _staging_path.path_join(relative_path)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot write JSON: %s" % absolute)
	file.store_string(JSON.stringify(value, "\t", false) + "\n")
	file.close()
	_hash_paths.append(relative_path)
	return true


func _publish_staging() -> bool:
	if DirAccess.dir_exists_absolute(_output_path):
		if DirAccess.rename_absolute(_output_path, _backup_path) != OK:
			return _fail("Cannot move previous evidence to backup.")
	if DirAccess.rename_absolute(_staging_path, _output_path) != OK:
		if DirAccess.dir_exists_absolute(_backup_path):
			DirAccess.rename_absolute(_backup_path, _output_path)
		return _fail("Cannot publish staged UI evidence.")
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


func _rect_from_array(values: Array) -> Rect2i:
	return Rect2i(
		int(values[0]), int(values[1]), int(values[2]), int(values[3])
	)


func _array_equals(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if (
			typeof(left[index]) in [TYPE_INT, TYPE_FLOAT]
			and typeof(right[index]) in [TYPE_INT, TYPE_FLOAT]
		):
			if not is_equal_approx(float(left[index]), float(right[index])):
				return false
		elif left[index] != right[index]:
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
