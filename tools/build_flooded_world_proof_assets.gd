extends SceneTree

const ROOT := "res://art/world/flooded_works"
const REPORT_PATH := "res://.codex-runtime/reports/flooded_world_asset_build.json"
const TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)
const ROCK := Color("2c4144")
const ROCK_LIGHT := Color("395457")
const ROCK_SHADOW := Color("1b2d30")
const CAP := Color("638e87")
const RUST := Color("76523f")
const WARNING := Color("d5a84d")
const ACTIVE := Color("8cc79b")
const COOLDOWN := Color("4f8888")

var _written := PackedStringArray()
var _failures: Array[String] = []


func _initialize() -> void:
	_build_terrain_family()
	_build_poison_vent_family()
	_build_crumbling_platform_family()
	var report := {
		"schema_version": 1,
		"stage_id": "flooded_works",
		"representative_room_id": "fw_poison_timing",
		"terrain_signature_count": 5,
		"canonical_component_base_count": 2,
		"state_overlay_count": 6,
		"paths": Array(_written),
		"style": "flat raster; broad planes; no outline; no generated microtexture",
	}
	_write_json(REPORT_PATH, report)
	print("FLOODED_WORLD_ASSET_BUILD %s" % JSON.stringify(report))
	_finish()


func _build_terrain_family() -> void:
	for size in [Vector2i(320, 100), Vector2i(240, 100), Vector2i(240, 140), Vector2i(240, 180)]:
		var image := _new_image(size)
		image.fill_rect(Rect2i(Vector2i.ZERO, size), ROCK)
		image.fill_rect(Rect2i(0, 0, size.x, 10), CAP)
		image.fill_rect(Rect2i(0, size.y - 20, size.x, 20), ROCK_SHADOW)
		image.fill_rect(Rect2i(0, 10, 18, size.y - 30), ROCK_LIGHT)
		image.fill_rect(Rect2i(size.x - 12, 10, 12, size.y - 30), RUST.darkened(0.20))
		_save(image, "%s/terrain/solid_%dx%d.png" % [ROOT, size.x, size.y])

	var catwalk := _new_image(Vector2i(720, 32))
	catwalk.fill_rect(Rect2i(0, 10, 720, 12), ROCK_LIGHT)
	catwalk.fill_rect(Rect2i(0, 10, 720, 5), CAP)
	for support_x in [24, 342, 672]:
		catwalk.fill_rect(Rect2i(support_x, 22, 24, 10), ROCK_SHADOW)
	catwalk.fill_rect(Rect2i(338, 15, 32, 17), RUST)
	_save(catwalk, "%s/terrain/oneway_720x12.png" % ROOT)


func _build_poison_vent_family() -> void:
	var base := _new_image(Vector2i(180, 96))
	base.fill_rect(Rect2i(0, 72, 180, 24), ROCK_SHADOW)
	base.fill_rect(Rect2i(12, 52, 156, 28), ROCK)
	base.fill_rect(Rect2i(28, 28, 124, 44), ROCK_LIGHT)
	base.fill_rect(Rect2i(44, 20, 92, 12), CAP)
	base.fill_rect(Rect2i(64, 40, 52, 32), ROCK_SHADOW)
	for grille_y in [44, 54, 64]:
		base.fill_rect(Rect2i(72, grille_y, 36, 5), CAP.darkened(0.18))
	base.fill_rect(Rect2i(18, 58, 20, 16), RUST)
	base.fill_rect(Rect2i(142, 58, 20, 16), RUST)
	_save(base, "%s/components/poison_vent/base.png" % ROOT)

	var warning := _new_image(Vector2i(180, 96))
	for stripe_x in [32, 72, 112]:
		warning.fill_rect(Rect2i(stripe_x, 8, 24, 8), WARNING)
		warning.fill_rect(Rect2i(stripe_x + 8, 16, 8, 12), WARNING.darkened(0.12))
	_save(warning, "%s/components/poison_vent/warning_overlay.png" % ROOT)

	var active := _new_image(Vector2i(180, 96))
	active.fill_rect(Rect2i(42, 2, 20, 54), ACTIVE.darkened(0.18))
	active.fill_rect(Rect2i(68, 0, 36, 64), ACTIVE)
	active.fill_rect(Rect2i(110, 8, 24, 48), ACTIVE.darkened(0.10))
	active.fill_rect(Rect2i(30, 52, 120, 16), ACTIVE.darkened(0.24))
	_save(active, "%s/components/poison_vent/active_overlay.png" % ROOT)

	var cooldown := _new_image(Vector2i(180, 96))
	for bar_y in [42, 52, 62]:
		cooldown.fill_rect(Rect2i(68, bar_y, 44, 5), COOLDOWN)
	_save(cooldown, "%s/components/poison_vent/cooldown_overlay.png" % ROOT)


func _build_crumbling_platform_family() -> void:
	var base := _new_image(Vector2i(220, 28))
	base.fill_rect(Rect2i(0, 4, 220, 16), ROCK_LIGHT)
	base.fill_rect(Rect2i(0, 4, 220, 5), CAP)
	base.fill_rect(Rect2i(18, 20, 42, 8), ROCK_SHADOW)
	base.fill_rect(Rect2i(160, 20, 42, 8), ROCK_SHADOW)
	base.fill_rect(Rect2i(98, 12, 24, 16), RUST)
	_save(base, "%s/components/crumbling_platform/base.png" % ROOT)

	var warning := _new_image(Vector2i(220, 28))
	for crack_x in [42, 104, 166]:
		warning.fill_rect(Rect2i(crack_x, 6, 4, 8), WARNING)
		warning.fill_rect(Rect2i(crack_x + 4, 12, 8, 4), WARNING)
		warning.fill_rect(Rect2i(crack_x + 10, 16, 4, 8), WARNING)
	_save(warning, "%s/components/crumbling_platform/warning_overlay.png" % ROOT)

	var disabled := _new_image(Vector2i(220, 28))
	for block in [Rect2i(22, 8, 24, 10), Rect2i(76, 16, 18, 8), Rect2i(128, 6, 28, 9), Rect2i(178, 18, 16, 8)]:
		disabled.fill_rect(block, ROCK_LIGHT)
	_save(disabled, "%s/components/crumbling_platform/disabled_overlay.png" % ROOT)

	var respawning := _new_image(Vector2i(220, 28))
	respawning.fill_rect(Rect2i(0, 4, 220, 4), COOLDOWN)
	for block_x in [20, 70, 120, 170]:
		respawning.fill_rect(Rect2i(block_x, 12, 30, 8), COOLDOWN.darkened(0.18))
	_save(respawning, "%s/components/crumbling_platform/respawning_overlay.png" % ROOT)


func _new_image(size: Vector2i) -> Image:
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	return image


func _save(image: Image, path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := image.save_png(absolute)
	if error != OK:
		_failures.append("Could not save %s (error %d)." % [path, error])
		return
	_written.append(path)


func _write_json(path: String, value: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("Could not write %s." % path)
		return
	file.store_string(JSON.stringify(value, "\t") + "\n")


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_WORLD_ASSET_BUILD_OK terrain=5 bases=2 overlays=6")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
