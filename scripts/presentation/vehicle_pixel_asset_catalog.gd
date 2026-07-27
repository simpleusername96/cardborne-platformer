class_name VehiclePixelAssetCatalog
extends RefCounted

## Immutable lookup boundary for approved pixel-atlas frames. Presentation
## owners ask for an exact family/variant/direction/state tuple; missing
## published frames fail visibly instead of substituting unrelated artwork.

const CATALOG_PATH := "res://pixel-art-production/runtime/catalog.json"

var _ready := false
var _assets_by_family: Dictionary = {}
var _textures_by_family: Dictionary = {}


func _init() -> void:
	_load_catalog()


func is_ready() -> bool:
	return _ready


func published_families() -> Array[StringName]:
	var families: Array[StringName] = []
	for family_variant in _assets_by_family.keys():
		families.append(StringName(family_variant))
	families.sort()
	return families


func has_family(family: StringName) -> bool:
	return _assets_by_family.has(family)


func texture(family: StringName) -> Texture2D:
	if _textures_by_family.has(family):
		return _textures_by_family[family]
	var asset: Dictionary = _assets_by_family.get(family, {})
	if asset.is_empty():
		push_error("Pixel family is not published: %s" % String(family))
		return null
	var atlas_path := "res://%s" % String(asset["atlas_path"])
	var loaded := load(atlas_path) as Texture2D
	if loaded == null:
		push_error("Published pixel atlas could not load: %s" % atlas_path)
		return null
	_textures_by_family[family] = loaded
	return loaded


func frame(
	family: StringName,
	variant: StringName,
	direction_index: int,
	state: StringName,
	sequence_index: int = 0
) -> Dictionary:
	var asset: Dictionary = _assets_by_family.get(family, {})
	if asset.is_empty():
		push_error("Pixel family is not published: %s" % String(family))
		return {}
	var key := _frame_key(variant, direction_index, state, sequence_index)
	var frames: Dictionary = asset["frames_by_key"]
	if not frames.has(key):
		push_error(
			"Published pixel frame is missing: %s/%s"
			% [String(family), key]
		)
		return {}
	return Dictionary(frames[key]).duplicate(true)


func first_frame(
	family: StringName,
	variant: StringName,
	preferred_state: StringName = &""
) -> Dictionary:
	var asset: Dictionary = _assets_by_family.get(family, {})
	if asset.is_empty():
		return {}
	var fallback: Dictionary = {}
	for frame_variant in Array(asset.get("frames", [])):
		var candidate := Dictionary(frame_variant)
		if StringName(candidate["variant"]) != variant:
			continue
		if fallback.is_empty():
			fallback = candidate
		if (
			preferred_state == &""
			or StringName(candidate["state"]) == preferred_state
		):
			var result := candidate.duplicate(true)
			result["family"] = family
			return result
	if not fallback.is_empty():
		var result := fallback.duplicate(true)
		result["family"] = family
		return result
	return {}


func frame_uv(frame_record: Dictionary) -> Color:
	var asset: Dictionary = _assets_by_family.get(
		StringName(frame_record.get("family", &"")),
		{}
	)
	if asset.is_empty():
		return Color(0.0, 0.0, 1.0, 1.0)
	var atlas_size_values := Array(asset["atlas_size"])
	var atlas_size := Vector2(
		float(atlas_size_values[0]),
		float(atlas_size_values[1])
	)
	var region := Array(frame_record["region"])
	return Color(
		float(region[0]) / atlas_size.x,
		float(region[1]) / atlas_size.y,
		float(region[2]) / atlas_size.x,
		float(region[3]) / atlas_size.y
	)


func direction_index(direction: Vector2, direction_count: int) -> int:
	if direction_count <= 1 or direction.is_zero_approx():
		return 0
	var normalized_angle := fposmod(direction.angle() + PI * 0.5, TAU)
	var step := TAU / float(direction_count)
	var slot: int = posmod(roundi(normalized_angle / step), direction_count)
	return roundi(float(slot) * 16.0 / float(direction_count)) % 16


func _load_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		push_warning("Pixel runtime catalog is not published yet: %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Dictionary:
		push_error("Pixel runtime catalog is not valid JSON.")
		return
	var catalog := Dictionary(parsed)
	for asset_variant in Array(catalog.get("assets", [])):
		var asset := Dictionary(asset_variant).duplicate(true)
		var family := StringName(asset["family"])
		if _assets_by_family.has(family):
			push_error("Duplicate published pixel family: %s" % String(family))
			_assets_by_family.clear()
			return
		var frames_by_key := {}
		for frame_variant in Array(asset.get("frames", [])):
			var frame := Dictionary(frame_variant).duplicate(true)
			frame["family"] = family
			var local_key := _frame_key(
				StringName(frame["variant"]),
				int(frame["direction_index"]),
				StringName(frame["state"]),
				int(frame["sequence_index"])
			)
			if frames_by_key.has(local_key):
				push_error("Duplicate pixel frame tuple: %s/%s" % [String(family), local_key])
				_assets_by_family.clear()
				return
			frames_by_key[local_key] = frame
		asset["frames_by_key"] = frames_by_key
		_assets_by_family[family] = asset
	_ready = not _assets_by_family.is_empty()


func _frame_key(
	variant: StringName,
	direction_index: int,
	state: StringName,
	sequence_index: int
) -> String:
	return "%s/%d/%s/%d" % [
		String(variant),
		direction_index,
		String(state),
		sequence_index,
	]
