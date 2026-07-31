class_name VehicleSemanticAssetProvider
extends RefCounted

## Runtime adapter for the approved semantic-v2 raster pack. This provider
## resolves image presentation only; collision, radii, timing, and behavior
## remain in their gameplay owners.

const MANIFEST_PATH := "res://art/gameplay/semantic-v2/asset-manifest.json"
const PACK_ROOT := "res://art/gameplay/semantic-v2"

const MAP_SURFACE_PREFIXES: Array[String] = [
	"world_shared_floor_",
	"world_wall_",
]

static var _manifest: Dictionary = {}
static var _assets: Dictionary = {}
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
	var pivot := Vector2(entry.get("pivot", canvas * 0.5))
	var unit_radius := maxf(canvas.x, canvas.y) * 0.5
	var mesh := QuadMesh.new()
	mesh.size = canvas / unit_radius
	mesh.center_offset = Vector3(
		(canvas.x * 0.5 - pivot.x) / unit_radius,
		(canvas.y * 0.5 - pivot.y) / unit_radius,
		0.0
	)
	_meshes[asset_id] = mesh
	return mesh


static func animation_frame_asset(
	animation_id: StringName,
	normalized_progress: float
) -> StringName:
	_ensure_loaded()
	var source := Dictionary(
		Dictionary(_manifest.get("animations", {})).get(
			String(animation_id),
			{}
		)
	)
	var frame_count := int(source.get("frame_count", 0))
	if frame_count <= 0:
		return &""
	var index := clampi(
		floori(clampf(normalized_progress, 0.0, 0.9999) * frame_count),
		0,
		frame_count - 1
	)
	return StringName("effect/%s/%02d" % [animation_id, index])


static func validate_pack() -> PackedStringArray:
	_ensure_loaded()
	var errors := _load_errors.duplicate()
	var seen_paths := {}
	for asset_id_variant in _assets:
		var asset_id := StringName(asset_id_variant)
		var entry := Dictionary(_assets[asset_id])
		var path := String(entry.get("path", ""))
		if path.is_empty() or not FileAccess.file_exists(path):
			errors.append("semantic asset file missing: %s -> %s" % [asset_id, path])
			continue
		if seen_paths.has(path):
			errors.append(
				"semantic asset path reused: %s and %s"
				% [seen_paths[path], asset_id]
			)
		seen_paths[path] = asset_id
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
	_manifest = Dictionary(parser.data)
	_index_attachments()
	_index_asset_sets()
	_index_animations()


static func _index_attachments() -> void:
	for id_variant in Dictionary(_manifest.get("attachments", {})):
		var attachment_id := StringName(id_variant)
		var source := Dictionary(
			Dictionary(_manifest["attachments"])[id_variant]
		)
		_add_asset(
			StringName("attachment/%s" % attachment_id),
			String(source["path"]),
			source,
			&"attachment"
		)


static func _index_asset_sets() -> void:
	for set_variant in Array(_manifest.get("asset_sets", [])):
		var asset_set := Dictionary(set_variant)
		var set_id := StringName(asset_set.get("id", &""))
		var root := String(asset_set.get("root", ""))
		match set_id:
			&"ordinary_enemies":
				var canvas_by_role := Dictionary(
					asset_set.get("canvas_by_role", {})
				)
				for role_variant in Array(asset_set.get("roles", [])):
					var role := StringName(role_variant)
					var canvas: Variant = canvas_by_role.get(
						String(role),
						canvas_by_role.get("default", [112, 112])
					)
					_add_asset(
						StringName("actor/%s" % role),
						"%s/actor_enemy_%s_base.png" % [root, role],
						{"canvas":canvas, "pivot":&"center"},
						&"actor"
					)
			&"bosses":
				for boss_variant in Array(asset_set.get("roles", [])):
					var boss := StringName(boss_variant)
					_add_asset(
						StringName("boss/%s" % boss),
						"%s/actor_boss_%s_base.png" % [root, boss],
						asset_set,
						&"boss"
					)
			&"boss_modules":
				for file_variant in Array(asset_set.get("files", [])):
					var file := String(file_variant)
					var module_id := file.get_basename().trim_prefix(
						"actor_boss_module_"
					)
					_add_asset(
						StringName("boss_module/%s" % module_id),
						"%s/%s" % [root, file],
						asset_set,
						&"boss_module"
					)
			&"secondaries", &"projectiles", &"states", &"pickups":
				var namespace_prefix: String = String({
					&"secondaries": "secondary",
					&"projectiles": "projectile",
					&"states": "state",
					&"pickups": "pickup",
				}.get(set_id, ""))
				for id_variant in Dictionary(asset_set.get("files", {})):
					var asset_name := StringName(id_variant)
					var source := Dictionary(
						Dictionary(asset_set["files"])[id_variant]
					)
					_add_asset(
						StringName("%s/%s" % [namespace_prefix, asset_name]),
						"%s/%s" % [root, String(source["path"])],
						source,
						set_id
					)
			&"world":
				for file_variant in Array(asset_set.get("files", [])):
					var file := String(file_variant)
					if _is_map_surface_file(file):
						continue
					_add_asset(
						StringName("world/%s" % file.get_basename()),
						"%s/%s" % [root, file],
						{},
						&"world_feature"
					)
			&"hud":
				for file_variant in Array(asset_set.get("files", [])):
					var file := String(file_variant)
					_add_asset(
						StringName("hud/%s" % file.get_basename()),
						"%s/%s" % [root, file],
						{},
						&"hud"
					)
			&"combat_cues":
				for id_variant in Dictionary(asset_set.get("files", {})):
					var cue_id := StringName(id_variant)
					var source := Dictionary(
						Dictionary(asset_set["files"])[id_variant]
					)
					_add_asset(
						StringName("cue/%s" % cue_id),
						"%s/%s" % [root, String(source["path"])],
						source,
						&"combat_cue"
					)


static func _index_animations() -> void:
	for animation_variant in Dictionary(_manifest.get("animations", {})):
		var animation_id := StringName(animation_variant)
		var source := Dictionary(
			Dictionary(_manifest["animations"])[animation_variant]
		)
		_add_asset(
			StringName("effect_atlas/%s" % animation_id),
			String(source["atlas"]),
			{},
			&"effect_atlas"
		)
		var frame_pattern := String(source["frames"])
		var frame_count := int(source["frame_count"])
		for index in frame_count:
			var relative_path := frame_pattern.replace(
				"{index:02}",
				"%02d" % index
			)
			_add_asset(
				StringName("effect/%s/%02d" % [animation_id, index]),
				relative_path,
				{"canvas":source["frame_size"], "pivot":source["pivot"]},
				&"effect_frame"
			)


static func _add_asset(
	asset_id: StringName,
	relative_path: String,
	source: Dictionary,
	category: StringName
) -> void:
	if _assets.has(asset_id):
		_load_errors.append("semantic asset id duplicated: %s" % asset_id)
		return
	var path := (
		relative_path
		if relative_path.begins_with("res://")
		else "%s/%s" % [PACK_ROOT, relative_path]
	)
	var canvas := _vector2i(source.get("canvas", Vector2i.ZERO))
	var pivot_variant: Variant = source.get("pivot", &"center")
	var pivot := (
		Vector2(canvas) * 0.5
		if pivot_variant is String or pivot_variant is StringName
		else Vector2(_vector2i(pivot_variant))
	)
	_assets[asset_id] = {
		"path":path,
		"canvas":canvas,
		"pivot":pivot,
		"category":category,
	}


static func _vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	return Vector2i.ZERO


static func _is_map_surface_file(file: String) -> bool:
	for prefix in MAP_SURFACE_PREFIXES:
		if file.begins_with(prefix):
			return true
	return false
