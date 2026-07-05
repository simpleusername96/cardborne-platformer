extends SceneTree

var _failures: Array[String] = []
var _save_path: String = ""
var _saved_file_exists: bool = false
var _saved_file_bytes: PackedByteArray = PackedByteArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_save_path = ProjectSettings.globalize_path("user://input_bindings.cfg")
	if not _backup_saved_file():
		_finish(1)
		return

	var bindings := root.get_node_or_null("/root/InputBindings")
	if bindings == null:
		_failures.append("InputBindings autoload is unavailable.")
		_finish(1)
		return

	bindings.restore_all_defaults()
	_expect_binding(bindings, "attack", "F", "attack default should be F")

	var remap_event := _make_key_event(KEY_G)
	var remap_result: Dictionary = bindings.remap_action_to_event("attack", remap_event)
	if not bool(remap_result.get("ok", false)):
		_failures.append("Attack remap to G failed: %s" % str(remap_result.get("message", "")))
	_expect_binding(bindings, "attack", "G", "attack should remap to G")

	var conflict_result: Dictionary = bindings.remap_action_to_event("attack", _make_key_event(KEY_SPACE))
	if bool(conflict_result.get("ok", false)):
		_failures.append("Attack remap to Space should be blocked because jump uses Space.")
	_expect_binding(bindings, "attack", "G", "blocked duplicate should not change attack binding")

	bindings.ensure_input_map()
	_expect_binding(bindings, "attack", "G", "saved attack binding should reload")

	_write_saved_attack_key(KEY_SPACE)
	bindings.ensure_input_map()
	_expect_binding(bindings, "attack", "F", "conflicting saved attack binding should be ignored")

	bindings.restore_all_defaults()
	_expect_binding(bindings, "attack", "F", "restore defaults should return attack to F")

	_finish(1 if not _failures.is_empty() else 0)


func _backup_saved_file() -> bool:
	_saved_file_exists = FileAccess.file_exists(_save_path)
	if not _saved_file_exists:
		return true

	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		_failures.append("Unable to back up existing input binding file.")
		return false
	_saved_file_bytes = file.get_buffer(file.get_length())
	return true


func _write_saved_attack_key(keycode: int) -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("keyboard", "attack", [keycode])
	var error := config.save(_save_path)
	if error != OK:
		_failures.append("Unable to write temporary saved input binding: %s" % error_string(error))


func _restore_saved_file() -> void:
	if _saved_file_exists:
		var file := FileAccess.open(_save_path, FileAccess.WRITE)
		if file == null:
			push_error("Unable to restore existing input binding file.")
			return
		file.store_buffer(_saved_file_bytes)
	elif FileAccess.file_exists(_save_path):
		var error := DirAccess.remove_absolute(_save_path)
		if error != OK:
			push_error("Unable to remove temporary input binding file: %s" % error_string(error))


func _expect_binding(bindings: Node, action_name: String, expected: String, context: String) -> void:
	var actual := str(bindings.get_binding_text(action_name, "unbound"))
	if actual != expected:
		_failures.append("%s, got %s." % [context, actual])


func _make_key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _finish(exit_code: int) -> void:
	_restore_saved_file()
	if exit_code != 0:
		for failure in _failures:
			push_error(failure)
	quit(exit_code)
