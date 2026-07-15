extends SceneTree

const Assets = preload("res://scripts/ui/production/ProductionUIAssets.gd")
const MANIFEST_PATH := "res://art/ui/production/asset-manifest.json"
const SECTIONS := [&"backgrounds", &"illustrations", &"shapes", &"icons"]
const ALLOWED_DISPOSITIONS := [&"runtime", &"fallback", &"contextual", &"deferred"]

var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	_expect(manifest_value is Dictionary, "production UI manifest must parse as a dictionary")
	if not manifest_value is Dictionary:
		_finish()
		return
	var manifest := manifest_value as Dictionary
	_expect(int(manifest.get("version", 0)) == 2, "production UI manifest must remain version 2")
	var dispositions: Dictionary = manifest.get("dispositions", {})
	var manifest_ids: Array[StringName] = []
	var seen := {}

	for section_name in SECTIONS:
		var entries_value: Variant = manifest.get(String(section_name), [])
		_expect(entries_value is Array, "%s must be an array" % section_name)
		if not entries_value is Array:
			continue
		for entry_value in entries_value as Array:
			_expect(entry_value is Dictionary, "%s entries must be dictionaries" % section_name)
			if not entry_value is Dictionary:
				continue
			var entry := entry_value as Dictionary
			var asset_id := StringName(String(entry.get("id", "")))
			_expect(asset_id != &"", "%s entry must have an id" % section_name)
			_expect(not seen.has(asset_id), "asset id must be unique: %s" % asset_id)
			seen[asset_id] = true
			manifest_ids.append(asset_id)
			_validate_entry(section_name, asset_id, entry, dispositions)

	manifest_ids.sort()
	var registry_ids := Assets.all_asset_ids()
	_expect(
		manifest_ids.size() == Assets.EXPECTED_ASSET_COUNT,
		"manifest must contain %d assets, found %d"
		% [Assets.EXPECTED_ASSET_COUNT, manifest_ids.size()]
	)
	_expect(registry_ids == manifest_ids, "runtime asset registry and manifest ids must match exactly")
	_expect(dispositions.size() == manifest_ids.size(), "every manifest asset must have one disposition")
	for disposition_id in dispositions:
		_expect(
			seen.has(StringName(disposition_id)),
			"disposition must not reference an unknown asset: %s" % disposition_id
		)
	_expect(Assets.texture(&"missing_asset") == null, "unknown asset lookup must return null")
	_finish()


func _validate_entry(
	section_name: StringName,
	asset_id: StringName,
	entry: Dictionary,
	dispositions: Dictionary
) -> void:
	var relative_path := String(entry.get("file", ""))
	var expected_path := "res://art/ui/production/%s" % relative_path
	_expect(not relative_path.is_empty(), "%s must declare a file" % asset_id)
	_expect(Assets.asset_path(asset_id) == expected_path, "%s runtime path must match manifest" % asset_id)
	_expect(FileAccess.file_exists(expected_path), "%s file must exist: %s" % [asset_id, expected_path])
	var texture := Assets.texture(asset_id, false)
	_expect(texture != null, "%s must import as Texture2D" % asset_id)

	var disposition_value: Variant = dispositions.get(String(asset_id), {})
	_expect(disposition_value is Dictionary, "%s must have a disposition record" % asset_id)
	if disposition_value is Dictionary:
		var record := disposition_value as Dictionary
		var state := StringName(String(record.get("state", "")))
		_expect(state in ALLOWED_DISPOSITIONS, "%s has invalid disposition %s" % [asset_id, state])
		_expect(Assets.disposition(asset_id) == state, "%s registry disposition must match manifest" % asset_id)
		_expect(not String(record.get("reason", "")).is_empty(), "%s disposition needs a reason" % asset_id)
		if state in [&"contextual", &"deferred"]:
			_expect(
				not Assets.disposition_reason(asset_id).is_empty(),
				"%s contextual/deferred registry entry needs a reason" % asset_id
			)

	match section_name:
		&"backgrounds", &"illustrations":
			_validate_raster_dimensions(asset_id, expected_path, entry)
		&"shapes":
			_validate_shape_dimensions(asset_id, texture, entry)
		&"icons":
			if texture != null:
				_expect(
					texture.get_size().is_equal_approx(Vector2(64.0, 64.0)),
					"%s icon must import at 64x64" % asset_id
				)

	if section_name == &"illustrations":
		var owner_id := StringName(String(entry.get("owner", "")))
		var fallback_id := StringName(String(entry.get("fallback", "")))
		_expect(owner_id != &"", "%s illustration needs an owner" % asset_id)
		_expect(Assets.asset_id_for_owner(owner_id) == asset_id, "%s owner lookup must resolve the illustration" % asset_id)
		_expect(Assets.fallback_asset_id(asset_id) == fallback_id, "%s fallback id must match manifest" % asset_id)
		_expect(Assets.texture(fallback_id, false) != null, "%s fallback must resolve" % asset_id)


func _validate_raster_dimensions(
	asset_id: StringName,
	path: String,
	entry: Dictionary
) -> void:
	var expected_value: Variant = entry.get("size", [])
	_expect(expected_value is Array and (expected_value as Array).size() == 2, "%s needs width and height" % asset_id)
	if not expected_value is Array or (expected_value as Array).size() != 2:
		return
	var expected := Vector2i(int(expected_value[0]), int(expected_value[1]))
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	_expect(image != null and not image.is_empty(), "%s raster must load from disk" % asset_id)
	if image != null and not image.is_empty():
		_expect(image.get_size() == expected, "%s raster must be %s" % [asset_id, expected])


func _validate_shape_dimensions(
	asset_id: StringName,
	texture: Texture2D,
	entry: Dictionary
) -> void:
	var view_box := String(entry.get("view_box", ""))
	var parts := view_box.split(" ", false)
	_expect(parts.size() == 4, "%s shape needs a four-value view box" % asset_id)
	if parts.size() != 4 or texture == null:
		return
	var expected := Vector2(parts[2].to_float(), parts[3].to_float())
	_expect(texture.get_size().is_equal_approx(expected), "%s shape import size must match view box" % asset_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"PRODUCTION_UI_ASSETS_OK assets=%d backgrounds=5 illustrations=19 shapes=6 icons=22"
			% Assets.EXPECTED_ASSET_COUNT
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
