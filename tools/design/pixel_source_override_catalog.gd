extends RefCounted

## Loads reviewed pixel masters and resolves them onto the existing 64 px atlas
## frame contract. Gameplay geometry and runtime lookup keys remain elsewhere.

const ATLAS_FRAME_SIZE := 64
const ALLOWED_REPEAT_KEYS := {
	"hangar_floor":true,
	"hangar_wall":true,
	"hangar_water":true,
}
const ALLOWED_VISIBLE_COLORS := {
	"141B24":true,
	"202833":true,
	"2E3945":true,
	"44515E":true,
	"596774":true,
	"222B35":true,
	"E8EEF0":true,
	"D9A83D":true,
	"65A9B8":true,
	"C92F4E":true,
	"962754":true,
	"75C4B2":true,
	"E45F36":true,
	"769A32":true,
	"3E91B7":true,
	"9B59B6":true,
}

var _manifest_path := ""
var _manifest: Dictionary = {}
var _frame_rules: Dictionary = {}
var _repeat_rules: Dictionary = {}
var _source_cache: Dictionary = {}
var _used_frame_keys: Dictionary = {}
var _errors: PackedStringArray = []


func load_manifest(path: String) -> bool:
	_manifest_path = path
	_manifest.clear()
	_frame_rules.clear()
	_repeat_rules.clear()
	_source_cache.clear()
	_used_frame_keys.clear()
	_errors.clear()
	if not FileAccess.file_exists(path):
		_errors.append("Pixel source override manifest does not exist: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_errors.append("Pixel source override manifest is not valid JSON: %s" % path)
		return false
	_manifest = Dictionary(parsed)
	if int(_manifest.get("schema_version", 0)) != 1:
		_errors.append("Pixel source override schema_version must be 1.")
		return false
	for rule_variant in Array(_manifest.get("frame_rules", [])):
		if not rule_variant is Dictionary:
			_errors.append("Every frame override rule must be an object.")
			continue
		_index_frame_rule(Dictionary(rule_variant))
	for key_variant in Dictionary(_manifest.get("repeat_tiles", {})):
		var runtime_key := String(key_variant)
		var rule_variant: Variant = Dictionary(
			_manifest.get("repeat_tiles", {})
		).get(runtime_key, {})
		if not ALLOWED_REPEAT_KEYS.has(runtime_key):
			_errors.append("Unknown repeat tile override key: %s" % runtime_key)
			continue
		if not rule_variant is Dictionary:
			_errors.append("Repeat tile override must be an object: %s" % runtime_key)
			continue
		var rule := Dictionary(rule_variant)
		_validate_source_record(rule, "repeat tile %s" % runtime_key, true)
		_repeat_rules[runtime_key] = rule
	return _errors.is_empty()


func errors() -> PackedStringArray:
	return _errors.duplicate()


func resolve_frame(
	family: String,
	variant: String,
	direction_index: int,
	state: String,
	sequence_index: int
) -> Dictionary:
	var key := _frame_key(
		family, variant, direction_index, state, sequence_index
	)
	if not _frame_rules.has(key):
		return {}
	var rule := Dictionary(_frame_rules[key])
	var source := _load_source_image(rule)
	if source == null:
		return {}
	var pixel_scale := int(rule.get("pixel_scale", 1))
	var scaled := source.duplicate()
	if pixel_scale > 1:
		scaled.resize(
			source.get_width() * pixel_scale,
			source.get_height() * pixel_scale,
			Image.INTERPOLATE_NEAREST
		)
	if (
		scaled.get_width() > ATLAS_FRAME_SIZE
		or scaled.get_height() > ATLAS_FRAME_SIZE
	):
		_errors.append("Override source exceeds the atlas frame after scaling: %s" % key)
		return {}
	var frame := Image.create(
		ATLAS_FRAME_SIZE,
		ATLAS_FRAME_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	frame.fill(Color.TRANSPARENT)
	var offset := Vector2i(
		(ATLAS_FRAME_SIZE - scaled.get_width()) / 2,
		(ATLAS_FRAME_SIZE - scaled.get_height()) / 2
	)
	frame.blit_rect(
		scaled,
		Rect2i(Vector2i.ZERO, scaled.get_size()),
		offset
	)
	var source_direction := int(rule.get("source_direction_index", direction_index))
	var rotation_steps := posmod(direction_index - source_direction, 16)
	if rotation_steps != 0:
		frame = _rotated(frame, float(rotation_steps) * TAU / 16.0)
	_used_frame_keys[key] = true
	var metadata := _provenance(rule)
	metadata["source_transform"] = {
		"atlas_frame_size":[ATLAS_FRAME_SIZE, ATLAS_FRAME_SIZE],
		"native_pixel_scale":pixel_scale,
		"center_offset":[offset.x, offset.y],
		"source_direction_index":source_direction,
		"target_direction_index":direction_index,
		"rotation_steps_16":rotation_steps,
	}
	return {
		"image":frame,
		"metadata":metadata,
	}


func repeat_tile(runtime_key: String) -> Dictionary:
	if not _repeat_rules.has(runtime_key):
		return {}
	var rule := Dictionary(_repeat_rules[runtime_key])
	var image := _load_source_image(rule)
	if image == null:
		return {}
	return {
		"image":image.duplicate(),
		"metadata":_provenance(rule),
	}


func unused_frame_keys() -> PackedStringArray:
	var result := PackedStringArray()
	for key_variant in _frame_rules:
		var key := String(key_variant)
		if not _used_frame_keys.has(key):
			result.append(key)
	result.sort()
	return result


func catalog_summary() -> Dictionary:
	return {
		"manifest_path":_manifest_path.trim_prefix("res://"),
		"manifest_sha256":FileAccess.get_sha256(
			ProjectSettings.globalize_path(_manifest_path)
		),
		"generation_board_id":String(_manifest.get("generation_board_id", "")),
		"frame_override_count":_frame_rules.size(),
		"repeat_tile_override_count":_repeat_rules.size(),
	}


func _index_frame_rule(rule: Dictionary) -> void:
	for field in ["family", "variant", "states", "directions", "sequence_indices"]:
		if not rule.has(field):
			_errors.append("Frame override rule is missing '%s'." % field)
			return
	_validate_source_record(
		rule,
		"frame rule %s/%s" % [String(rule["family"]), String(rule["variant"])],
		false
	)
	for state_variant in Array(rule["states"]):
		for direction_variant in Array(rule["directions"]):
			for sequence_variant in Array(rule["sequence_indices"]):
				var key := _frame_key(
					String(rule["family"]),
					String(rule["variant"]),
					int(direction_variant),
					String(state_variant),
					int(sequence_variant)
				)
				if _frame_rules.has(key):
					_errors.append("Duplicate pixel frame override target: %s" % key)
				else:
					_frame_rules[key] = rule


func _validate_source_record(
	rule: Dictionary,
	label: String,
	require_repeat_safe: bool
) -> void:
	for field in [
		"source_path",
		"source_sha256",
		"raw_source_path",
		"raw_source_sha256",
		"prompt_path",
		"prompt_sha256",
		"logical_size",
		"production_method",
	]:
		if not rule.has(field):
			_errors.append("%s is missing '%s'." % [label, field])
	if String(rule.get("production_method", "")) != "imagegen_assisted":
		_errors.append("%s must use production_method imagegen_assisted." % label)
	if require_repeat_safe and not bool(rule.get("repeat_safe", false)):
		_errors.append("%s must declare repeat_safe=true." % label)
	var logical_size := Array(rule.get("logical_size", []))
	if logical_size.size() != 2:
		_errors.append("%s logical_size must contain width and height." % label)
		return
	var source_path := String(rule.get("source_path", ""))
	var raw_source_path := String(rule.get("raw_source_path", ""))
	var prompt_path := String(rule.get("prompt_path", ""))
	_validate_file_hash(
		source_path,
		String(rule.get("source_sha256", "")),
		"%s approved source" % label
	)
	_validate_file_hash(
		raw_source_path,
		String(rule.get("raw_source_sha256", "")),
		"%s raw ImageGen source" % label
	)
	_validate_file_hash(
		prompt_path,
		String(rule.get("prompt_sha256", "")),
		"%s prompt" % label
	)
	if FileAccess.file_exists("res://%s" % source_path):
		var image := Image.load_from_file("res://%s" % source_path)
		if (
			image == null
			or image.get_width() != int(logical_size[0])
			or image.get_height() != int(logical_size[1])
		):
			_errors.append(
				"%s approved source dimensions do not match logical_size." % label
			)
		else:
			_validate_pixels(image, label, require_repeat_safe)
			if require_repeat_safe and not _is_repeat_safe(image):
				_errors.append(
					"%s approved source is not mechanically seamless." % label
				)


func _validate_file_hash(path: String, expected: String, label: String) -> void:
	var resource_path := "res://%s" % path
	if not FileAccess.file_exists(resource_path):
		_errors.append("%s does not exist: %s" % [label, path])
		return
	var actual := FileAccess.get_sha256(ProjectSettings.globalize_path(resource_path))
	if actual.to_lower() != expected.to_lower():
		_errors.append("%s SHA-256 mismatch: %s" % [label, path])


func _load_source_image(rule: Dictionary) -> Image:
	var source_path := String(rule["source_path"])
	if _source_cache.has(source_path):
		return (_source_cache[source_path] as Image).duplicate()
	var image := Image.load_from_file("res://%s" % source_path)
	if image == null:
		_errors.append("Could not load approved pixel source: %s" % source_path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	_source_cache[source_path] = image.duplicate()
	return image


func _provenance(rule: Dictionary) -> Dictionary:
	return {
		"production_method":"imagegen_assisted",
		"approved_source_path":String(rule["source_path"]),
		"approved_source_sha256":String(rule["source_sha256"]).to_lower(),
		"raw_source_path":String(rule["raw_source_path"]),
		"raw_source_sha256":String(rule["raw_source_sha256"]).to_lower(),
		"prompt_path":String(rule["prompt_path"]),
		"prompt_sha256":String(rule["prompt_sha256"]).to_lower(),
		"derivation":String(rule.get(
			"derivation",
			"imagegen_grid_snap_palette_and_cell_cleanup"
		)),
	}


func _frame_key(
	family: String,
	variant: String,
	direction_index: int,
	state: String,
	sequence_index: int
) -> String:
	return "%s/%s/%d/%s/%d" % [
		family,
		variant,
		direction_index,
		state,
		sequence_index,
	]


func _is_repeat_safe(image: Image) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	for x in width:
		if image.get_pixel(x, 0) != image.get_pixel(x, height - 1):
			return false
	for y in height:
		if image.get_pixel(0, y) != image.get_pixel(width - 1, y):
			return false
	return true


func _validate_pixels(image: Image, label: String, require_opaque: bool) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var alpha_byte := roundi(color.a * 255.0)
			if alpha_byte != 0 and alpha_byte != 255:
				_errors.append("%s contains partial alpha." % label)
				return
			if require_opaque and alpha_byte != 255:
				_errors.append("%s repeat source contains transparency." % label)
				return
			if (
				alpha_byte == 255
				and not ALLOWED_VISIBLE_COLORS.has(
					color.to_html(false).to_upper()
				)
			):
				_errors.append("%s contains a color outside the approved palette." % label)
				return


func _rotated(source: Image, angle: float) -> Image:
	var result := Image.create(
		ATLAS_FRAME_SIZE,
		ATLAS_FRAME_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	result.fill(Color.TRANSPARENT)
	var center := Vector2(31.5, 31.5)
	var sine := sin(-angle)
	var cosine := cos(-angle)
	for y in ATLAS_FRAME_SIZE:
		for x in ATLAS_FRAME_SIZE:
			var delta := Vector2(float(x), float(y)) - center
			var source_position := Vector2(
				delta.x * cosine - delta.y * sine,
				delta.x * sine + delta.y * cosine
			) + center
			var source_x := roundi(source_position.x)
			var source_y := roundi(source_position.y)
			if (
				source_x >= 0
				and source_x < ATLAS_FRAME_SIZE
				and source_y >= 0
				and source_y < ATLAS_FRAME_SIZE
			):
				result.set_pixel(x, y, source.get_pixel(source_x, source_y))
	return result
