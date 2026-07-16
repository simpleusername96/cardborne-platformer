extends SceneTree

const SOURCE_PATHS: Array[String] = [
	"res://.codex-runtime/imagegen/flooded-panel-01-source.png",
	"res://.codex-runtime/imagegen/flooded-panel-02-source.png",
]
const OUTPUT_PATHS: Array[String] = [
	"res://art/world/flooded_works/backgrounds/panel_01.png",
	"res://art/world/flooded_works/backgrounds/panel_02.png",
]
const REPORT_PATH := "res://.codex-runtime/reports/flooded_panorama_normalization.json"
const TARGET_SIZE := Vector2i(2048, 1536)
const OVERLAP := 192

var _failures: Array[String] = []


func _initialize() -> void:
	var panels: Array[Image] = []
	var source_sizes: Array[Dictionary] = []
	for path in SOURCE_PATHS:
		var image := _load_image(path)
		if image == null:
			continue
		source_sizes.append(_vector2i_data(image.get_size()))
		panels.append(_normalize(image))
	if panels.size() == 2:
		_blend_overlap(panels[0], panels[1])
		for index in panels.size():
			_save_image(panels[index], OUTPUT_PATHS[index])
		var report := {
			"schema_version": 1,
			"source_sizes": source_sizes,
			"target_size": _vector2i_data(TARGET_SIZE),
			"panel_ratio": snappedf(float(TARGET_SIZE.x) / float(TARGET_SIZE.y), 0.0001),
			"overlap": OVERLAP,
			"composite_size": _vector2i_data(
				Vector2i(TARGET_SIZE.x * 2 - OVERLAP, TARGET_SIZE.y)
			),
			"entry_seam_mean_delta": _column_mean_delta(
				panels[0], TARGET_SIZE.x - OVERLAP, panels[1], 0
			),
			"overlap_exit_mean_delta": _column_mean_delta(
				panels[1], OVERLAP - 1, panels[1], OVERLAP
			),
			"method": "center crop, Lanczos resize, 192 px smooth overlap reference blend",
		}
		_write_json(REPORT_PATH, report)
		print("FLOODED_PANORAMA_NORMALIZED %s" % JSON.stringify(report))
	_finish()


func _load_image(path: String) -> Image:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		_failures.append("Could not load %s (error %d)." % [path, error])
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func _normalize(source: Image) -> Image:
	var source_size := source.get_size()
	var target_ratio := float(TARGET_SIZE.x) / float(TARGET_SIZE.y)
	var source_ratio := float(source_size.x) / float(source_size.y)
	var crop_size := source_size
	if source_ratio > target_ratio:
		crop_size.x = roundi(float(source_size.y) * target_ratio)
	else:
		crop_size.y = roundi(float(source_size.x) / target_ratio)
	var crop_position := Vector2i(
		(source_size.x - crop_size.x) / 2,
		(source_size.y - crop_size.y) / 2
	)
	var normalized := source.get_region(Rect2i(crop_position, crop_size))
	normalized.resize(TARGET_SIZE.x, TARGET_SIZE.y, Image.INTERPOLATE_LANCZOS)
	return normalized


func _blend_overlap(previous: Image, next: Image) -> void:
	var previous_start := TARGET_SIZE.x - OVERLAP
	for x in OVERLAP:
		var ratio := float(x) / float(OVERLAP - 1)
		var smooth := ratio * ratio * (3.0 - 2.0 * ratio)
		for y in TARGET_SIZE.y:
			var reference := previous.get_pixel(previous_start + x, y)
			var generated := next.get_pixel(x, y)
			next.set_pixel(x, y, reference.lerp(generated, smooth))


func _column_mean_delta(left: Image, left_x: int, right: Image, right_x: int) -> float:
	var total := 0.0
	for y in TARGET_SIZE.y:
		var a := left.get_pixel(left_x, y)
		var b := right.get_pixel(right_x, y)
		total += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
	return snappedf(total / float(TARGET_SIZE.y * 3), 0.000001)


func _save_image(image: Image, path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := image.save_png(absolute)
	if error != OK:
		_failures.append("Could not save %s (error %d)." % [path, error])


func _write_json(path: String, value: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("Could not write %s." % path)
		return
	file.store_string(JSON.stringify(value, "\t") + "\n")


func _vector2i_data(value: Vector2i) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_PANORAMA_NORMALIZATION_OK panels=2 overlap=192")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
