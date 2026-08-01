class_name VehicleRunCaptureDriver
extends RefCounted

## Owns capture CLI configuration and screenshot I/O for VehicleRun.

var directory := ""
var locale := ""
var viewport_size := Vector2i.ZERO
var text_scale := 1.0
var layout_seed_override: Variant = null
var field_id_override := &""
var failed := false


static func from_command_line() -> VehicleRunCaptureDriver:
	var driver := VehicleRunCaptureDriver.new()
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	for argument in arguments:
		if argument.begins_with("--capture-all="):
			driver.directory = argument.trim_prefix("--capture-all=")
		elif argument.begins_with("--capture-locale="):
			driver.locale = argument.trim_prefix("--capture-locale=")
		elif argument.begins_with("--capture-size="):
			var parts := argument.trim_prefix("--capture-size=").split("x")
			if parts.size() == 2:
				driver.viewport_size = Vector2i(
					maxi(640, int(parts[0])), maxi(360, int(parts[1]))
				)
		elif argument.begins_with("--capture-text-scale="):
			driver.text_scale = clampf(
				float(argument.trim_prefix("--capture-text-scale=")), 1.0, 2.0
			)
		elif argument.begins_with("--layout-seed="):
			driver.layout_seed_override = int(argument.trim_prefix("--layout-seed="))
		elif argument.begins_with("--field-id="):
			driver.field_id_override = StringName(argument.trim_prefix("--field-id="))
	return driver


func is_requested() -> bool:
	return not directory.is_empty()


func apply_locale() -> void:
	if locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)


func prepare_output() -> bool:
	if not is_requested():
		return false
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		failed = true
		push_error("Capture directory creation failed: %s (%d)" % [directory, error])
		return false
	return true


func is_full_evidence(viewport: Viewport) -> bool:
	var width := viewport_size.x
	if width <= 0:
		width = roundi(viewport.get_visible_rect().size.x)
	return locale == "ko" and width == 1280


func save_viewport(viewport: Viewport, file_name: String) -> bool:
	var path := directory.path_join(file_name)
	RenderingServer.force_draw(true)
	var image := viewport.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		failed = true
		push_error("Could not save capture %s: %s" % [path, error_string(error)])
		return false
	print("CAPTURE_SAVED %s" % path)
	return true
