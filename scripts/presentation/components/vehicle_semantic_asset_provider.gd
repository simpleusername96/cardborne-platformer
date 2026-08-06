class_name VehicleSemanticAssetProvider
extends RefCounted

## Runtime adapter for the final authored-raster pack. This provider resolves
## presentation metadata only; collision, radii, timing, value, and behavior
## remain in their gameplay owners.

const MANIFEST_PATH := "res://art/visuals/production/gameplay/asset-manifest.json"
const PACK_ROOT := "res://art/visuals/production/gameplay"

static var _manifest: Dictionary = {}
static var _assets: Dictionary = {}
static var _asset_paths: Dictionary = {}
static var _textures: Dictionary = {}
static var _meshes: Dictionary = {}
static var _load_errors := PackedStringArray()


static func manifest() -> Dictionary:
	_ensure_loaded()
	return _manifest.duplicate(true)


static func asset_ids() -> Array[StringName]:
	_ensure_loaded()
	var ids: Array[StringName] = []
	for asset_id in _assets:
		ids.append(StringName(asset_id))
	ids.sort()
	return ids


static func descriptor(asset_id: StringName) -> Dictionary:
	_ensure_loaded()
	return Dictionary(_assets.get(asset_id, {})).duplicate(true)


static func has_asset(asset_id: StringName) -> bool:
	_ensure_loaded()
	return _assets.has(asset_id)


static func texture(asset_id: StringName) -> Texture2D:
	_ensure_loaded()
	if _textures.has(asset_id):
		return _textures[asset_id] as Texture2D
	var entry := Dictionary(_assets.get(asset_id, {}))
	if entry.is_empty():
		return null
	var loaded := load(String(entry["path"])) as Texture2D
	if loaded != null:
		_textures[asset_id] = loaded
	return loaded


static func normalized_mesh(asset_id: StringName) -> QuadMesh:
	_ensure_loaded()
	if _meshes.has(asset_id):
		return _meshes[asset_id] as QuadMesh
	var entry := Dictionary(_assets.get(asset_id, {}))
	if entry.is_empty():
		return null
	var image := texture(asset_id)
	if image == null:
		return null
	var canvas := Vector2(entry.get("canvas", image.get_size()))
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		canvas = Vector2(image.get_size())
	var content_rect := Rect2(entry.get("content_rect", Rect2(Vector2.ZERO, canvas)))
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		content_rect = Rect2(Vector2.ZERO, canvas)
	var pivot := Vector2(entry.get("pivot", canvas * 0.5))
	var unit_radius := maxf(content_rect.size.x, content_rect.size.y) * 0.5
	var mesh := QuadMesh.new()
	# Keep the full texture canvas on the quad so its UVs stay correct. Only the
	# normalization radius comes from the visible alpha bounds; callers can then
	# fit authored content to gameplay geometry without trimming approved bytes.
	mesh.size = canvas / unit_radius
	mesh.center_offset = Vector3(
		(canvas.x * 0.5 - pivot.x) / unit_radius,
		(canvas.y * 0.5 - pivot.y) / unit_radius,
		0.0
	)
	_meshes[asset_id] = mesh
	return mesh


static func validate_pack() -> PackedStringArray:
	_ensure_loaded()
	var errors := _load_errors.duplicate()
	var expected_count := int(_manifest.get("final_asset_count", -1))
	if expected_count != _assets.size():
		errors.append(
			"semantic asset count mismatch: expected %d got %d"
			% [expected_count, _assets.size()]
		)
	for asset_id_variant in _assets:
		var asset_id := StringName(asset_id_variant)
		var entry := Dictionary(_assets[asset_id])
		var path := String(entry.get("path", ""))
		if path.is_empty() or not FileAccess.file_exists(path):
			errors.append("semantic asset file missing: %s -> %s" % [asset_id, path])
			continue
		var image := texture(asset_id)
		if image == null:
			errors.append("semantic texture failed to load: %s" % asset_id)
			continue
		var expected := Vector2i(entry.get("canvas", Vector2i.ZERO))
		var actual := Vector2i(image.get_size())
		if expected != Vector2i.ZERO and actual != expected:
			errors.append(
				"semantic texture size mismatch: %s expected %s got %s"
				% [asset_id, expected, actual]
			)
	return errors


static func _ensure_loaded() -> void:
	if not _manifest.is_empty() or not _load_errors.is_empty():
		return
	if not FileAccess.file_exists(MANIFEST_PATH):
		_load_errors.append("semantic asset manifest missing: %s" % MANIFEST_PATH)
		return
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(MANIFEST_PATH))
	if error != OK:
		_load_errors.append(
			"semantic asset manifest parse failed at line %d: %s"
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return
	if not parser.data is Dictionary:
		_load_errors.append("semantic asset manifest root must be a dictionary")
		return
	_manifest = Dictionary(parser.data)
	_index_attachments()
	_index_assets()


static func _index_attachments() -> void:
	for id_variant in Dictionary(_manifest.get("attachments", {})):
		var source := Dictionary(
			Dictionary(_manifest["attachments"])[id_variant]
		)
		var asset_id := StringName(
			source.get("semantic_id", "attachment/%s" % id_variant)
		)
		_add_asset(
			asset_id,
			String(source.get("path", "")),
			source,
			StringName(source.get("category", &"attachment"))
		)


static func _index_assets() -> void:
	for asset_variant in Array(_manifest.get("assets", [])):
		var source := Dictionary(asset_variant)
		_add_asset(
			StringName(source.get("id", &"")),
			String(source.get("path", "")),
			source,
			StringName(source.get("category", &""))
		)


static func _add_asset(
	asset_id: StringName,
	relative_path: String,
	source: Dictionary,
	category: StringName
) -> void:
	if asset_id == &"":
		_load_errors.append("semantic asset id is empty")
		return
	if _assets.has(asset_id):
		_load_errors.append("semantic asset id duplicated: %s" % asset_id)
		return
	if relative_path.is_empty():
		_load_errors.append("semantic asset path is empty: %s" % asset_id)
		return
	if category == &"":
		_load_errors.append("semantic asset category is empty: %s" % asset_id)
		return
	var path := (
		relative_path
		if relative_path.begins_with("res://")
		else "%s/%s" % [PACK_ROOT, relative_path]
	)
	if _asset_paths.has(path):
		_load_errors.append(
			"semantic asset path duplicated: %s and %s -> %s"
			% [_asset_paths[path], asset_id, path]
		)
		return
	var canvas := _vector2i(source.get("canvas", Vector2i.ZERO))
	if canvas.x <= 0 or canvas.y <= 0:
		_load_errors.append("semantic asset canvas is invalid: %s" % asset_id)
		return
	var pivot_variant: Variant = source.get("pivot", &"center")
	var pivot := (
		Vector2(canvas) * 0.5
		if pivot_variant is String or pivot_variant is StringName
		else _vector2(pivot_variant)
	)
	if pivot.x < 0.0 or pivot.y < 0.0 or pivot.x > canvas.x or pivot.y > canvas.y:
		_load_errors.append("semantic asset pivot is outside its canvas: %s" % asset_id)
		return
	var content_rect := _rect2(source.get("content_rect", [0, 0, canvas.x, canvas.y]))
	if (
		content_rect.size.x <= 0.0
		or content_rect.size.y <= 0.0
		or content_rect.position.x < 0.0
		or content_rect.position.y < 0.0
		or content_rect.end.x > canvas.x
		or content_rect.end.y > canvas.y
	):
		_load_errors.append("semantic asset content rect is outside its canvas: %s" % asset_id)
		return
	var descriptor_source := source.duplicate(true)
	descriptor_source.erase("id")
	descriptor_source.erase("semantic_id")
	descriptor_source["path"] = path
	descriptor_source["canvas"] = canvas
	descriptor_source["content_rect"] = content_rect
	descriptor_source["pivot"] = pivot
	descriptor_source["category"] = category
	_assets[asset_id] = descriptor_source
	_asset_paths[path] = asset_id


static func _vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	return Vector2i.ZERO


static func _vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2(float(Array(value)[0]), float(Array(value)[1]))
	return Vector2.ZERO


static func _rect2(value: Variant) -> Rect2:
	if value is Rect2:
		return value
	if value is Rect2i:
		return Rect2(value)
	if value is Array and Array(value).size() >= 4:
		var values := Array(value)
		return Rect2(
			float(values[0]),
			float(values[1]),
			float(values[2]),
			float(values[3])
		)
	return Rect2()
