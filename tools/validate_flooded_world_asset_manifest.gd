extends SceneTree

const MANIFEST_PATH := "res://art/world/flooded_works/asset-manifest.json"
const GENERATION_RECORD_PATH := "res://art/world/flooded_works/generation-record.json"
const WORLD_ROOT := "res://art/world/flooded_works"

var _failures: Array[String] = []


func _initialize() -> void:
	var manifest := _read_json(MANIFEST_PATH)
	var generation := _read_json(GENERATION_RECORD_PATH)
	_expect(not manifest.is_empty(), "Flooded world manifest should parse.")
	_expect(not generation.is_empty(), "Flooded generation record should parse.")
	if not manifest.is_empty():
		_validate_manifest(manifest)
	if not generation.is_empty():
		_validate_generation_record(generation)
	_finish()


func _validate_manifest(manifest: Dictionary) -> void:
	_expect(manifest.get("status") == "representative_room_runtime_proof", "Manifest status should be explicit.")
	var listed := {}
	var background: Dictionary = manifest.get("background", {})
	var panel_size: Array = background.get("panel_size", [])
	_expect(
		panel_size.size() == 2 and Vector2i(int(panel_size[0]), int(panel_size[1])) == Vector2i(2048, 1536),
		"Panel size should remain 2048x1536."
	)
	_expect(background.get("overlap") == 192, "Panel overlap should remain 192 px.")
	for path in background.get("panels", []):
		_validate_image_path(String(path), Vector2i(2048, 1536), listed)

	var room: Dictionary = manifest.get("representative_room", {})
	_expect(room.get("id") == "fw_poison_timing", "Representative room should remain explicit.")
	_expect((room.get("terrain_types", []) as Array).size() == 5, "Manifest should own five terrain types.")
	for terrain in room.get("terrain_types", []):
		var signature := String(terrain.get("signature", ""))
		var parts := signature.split("_")
		var dimensions := String(parts[2]).split("x") if parts.size() == 3 else PackedStringArray()
		var expected := Vector2i(int(dimensions[0]), int(dimensions[1])) if dimensions.size() == 2 else Vector2i.ZERO
		if signature == "layer_2_720x12":
			expected = Vector2i(720, 32)
		_validate_image_path(String(terrain.get("path", "")), expected, listed)

	var components: Array = manifest.get("stateful_components", [])
	_expect(components.size() == 2, "Manifest should own two stateful component families.")
	for component in components:
		var expected := Vector2i(180, 96) if component.get("id") == "timed_poison_vent" else Vector2i(220, 28)
		_validate_image_path(String(component.get("base", "")), expected, listed)
		for path in (component.get("overlays", {}) as Dictionary).values():
			_validate_image_path(String(path), expected, listed)

	var runtime_pngs := _collect_png_paths(WORLD_ROOT)
	_expect(runtime_pngs.size() == 15, "World proof should contain exactly 15 runtime PNGs.")
	for path in runtime_pngs:
		_expect(listed.has(path), "Runtime PNG lacks a manifest disposition: %s" % path)
	for source in manifest.get("source_boards", []):
		var path := String(source.get("path", ""))
		_expect(FileAccess.file_exists(path), "Source board should exist: %s" % path)
		_expect(source.get("disposition") == "direction_only_not_runtime_atlas", "Source board disposition should be explicit.")
		var image := _load_image(path)
		_expect(image != null and image.detect_alpha(), "Source board should retain transparency: %s" % path)
	var retired: Dictionary = manifest.get("retired_reference", {})
	_expect(retired.get("disposition") == "historical_unaccepted_reference_not_runtime", "Old preview disposition should be explicit.")


func _validate_generation_record(record: Dictionary) -> void:
	var outputs: Array = record.get("outputs", [])
	_expect(outputs.size() == 4, "Generation record should cover four independent calls.")
	for output in outputs:
		_expect(not String(output.get("prompt", "")).is_empty(), "Every generated output needs its prompt contract.")
		_expect(FileAccess.file_exists(String(output.get("output", ""))), "Generated output should exist: %s" % output.get("output", ""))


func _validate_image_path(path: String, expected_size: Vector2i, listed: Dictionary) -> void:
	_expect(path.ends_with(".png"), "Runtime world art must be PNG: %s" % path)
	_expect(FileAccess.file_exists(path), "Runtime world art should exist: %s" % path)
	var image := _load_image(path)
	_expect(image != null, "Runtime image should decode: %s" % path)
	if image != null:
		_expect(image.get_size() == expected_size, "%s should be %s, got %s." % [path, expected_size, image.get_size()])
	listed[path] = true


func _collect_png_paths(root_path: String) -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		return paths
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := "%s/%s" % [root_path, name]
		if directory.current_is_dir():
			paths.append_array(_collect_png_paths(child))
		elif name.ends_with(".png"):
			paths.append(child)
		name = directory.get_next()
	directory.list_dir_end()
	paths.sort()
	return paths


func _load_image(path: String) -> Image:
	var image := Image.new()
	return image if image.load(ProjectSettings.globalize_path(path)) == OK else null


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_WORLD_ASSET_MANIFEST_OK runtime_png=15 terrain=5 components=2")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
