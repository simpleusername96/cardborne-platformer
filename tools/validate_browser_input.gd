extends SceneTree

const ACTIVE_INPUT_FILES := [
	"res://scripts/autoload/InputBindings.gd",
	"res://scripts/autoload/Game.gd",
	"res://scripts/ui/SettingsPopup.gd",
	"res://scenes/ui/SettingsPopup.tscn",
	"res://tools/validate_release_candidate.ps1",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_runtime_surface()
	_validate_web_preset()
	_validate_export_helper()
	_validate_project_renderer()

	if _failures.is_empty():
		print("BROWSER_INPUT_VALIDATION_OK preset=Web scroll_guard=true focus_release=true gamepad_paths=0")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_runtime_surface() -> void:
	for path in ACTIVE_INPUT_FILES:
		var text := _read(path)
		if text.is_empty():
			continue
		for stale_term in ["gamepad", "joypad", "GAMEPAD_LAYOUT", "active_input_device"]:
			_expect(
				not text.to_lower().contains(stale_term.to_lower()),
				"Active input surface still contains '%s': %s." % [stale_term, path]
			)
	_expect(
		not FileAccess.file_exists("res://tools/validate_gamepad_input.gd"),
		"Obsolete gamepad validator should be removed."
	)
	var bindings := _read("res://scripts/autoload/InputBindings.gd")
	_expect(bindings.contains("NOTIFICATION_APPLICATION_FOCUS_OUT"), "Focus loss must release held gameplay input.")
	_expect(bindings.contains("Input.action_release"), "Focus-loss handling must release Input actions.")
	_expect(not bindings.contains("\"climb_cancel\"") or bindings.contains("RETIRED_ACTIONS"), "climb_cancel may only remain as a retired migration identifier.")


func _validate_web_preset() -> void:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	if error != OK:
		_failures.append("Web export preset cannot be loaded: %s." % error_string(error))
		return
	_expect(String(config.get_value("preset.0", "name", "")) == "Web", "Export preset must be named Web.")
	_expect(String(config.get_value("preset.0", "platform", "")) == "Web", "Export preset platform must be Web.")
	_expect(bool(config.get_value("preset.0", "runnable", false)), "Web preset must be runnable.")
	_expect(not bool(config.get_value("preset.0.options", "variant/thread_support", true)), "Web preset must use the compatible single-threaded baseline.")
	_expect(not bool(config.get_value("preset.0.options", "variant/extensions_support", true)), "Web preset must not enable unused extensions.")
	_expect(bool(config.get_value("preset.0.options", "html/focus_canvas_on_start", false)), "Web canvas must own keyboard focus on start.")
	var head_include := String(config.get_value("preset.0.options", "html/head_include", ""))
	for required in ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Space", "preventDefault", "activeElement", "canvas"]:
		_expect(head_include.contains(required), "Web scroll guard is missing '%s'." % required)


func _validate_export_helper() -> void:
	var helper := _read("res://tools/export_web.ps1")
	for required in ["--export-release", "Web", "build\\web", "index.html", "index.js", "index.pck", "index.wasm"]:
		_expect(helper.contains(required), "Deterministic web export helper is missing '%s'." % required)
	_expect(helper.contains("Refusing to clean an unexpected web export path"), "Web export cleanup needs an absolute-path guard.")


func _validate_project_renderer() -> void:
	var project := _read("res://project.godot")
	_expect(project.contains("GL Compatibility"), "Project feature tags must match the Web-compatible renderer.")
	_expect(project.contains('renderer/rendering_method="gl_compatibility"'), "Project rendering method must be Web compatible.")


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		_failures.append("Required browser-input file is missing: %s." % path)
		return ""
	return FileAccess.get_file_as_string(path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
