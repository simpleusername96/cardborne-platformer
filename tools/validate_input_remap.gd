extends SceneTree

const EXPECTED_DEFAULTS := {
	"move_left": "Left",
	"move_right": "Right",
	"jump": "Space",
	"dash": "Shift",
	"attack": "X",
	"guard": "C",
	"use_consumable": "A",
	"climb_up": "Up",
	"climb_down": "Down",
	"crouch": "Down",
	"interact": "E",
	"pause": "Escape",
}
const RETIRED_ACTIONS := [
	"climb_cancel",
	"heavy_attack",
	"skill_1",
	"skill_2",
	"skill_3",
]
const CHORDS := [
	["move_left", "jump", "attack"],
	["move_right", "dash", "attack"],
	["move_left", "guard"],
	["jump", "guard"],
]

var _failures: Array[String] = []
var _save_path: String = ""
var _saved_file_exists := false
var _saved_file_bytes := PackedByteArray()


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

	_remove_test_save()
	bindings.ensure_input_map()
	bindings.restore_all_defaults()
	_expect_current_defaults(bindings, "fresh defaults")
	_expect_keyboard_only_actions()
	_expect_retired_actions_absent()
	_expect_binding_rows(bindings)
	_expect_guide(bindings)
	_expect_chords()

	var remap_result: Dictionary = bindings.remap_action_to_event(
		"attack", _make_key_event(KEY_J)
	)
	_expect(bool(remap_result.get("ok", false)), "Attack remap to J should succeed.")
	_expect_binding(bindings, "attack", "J", "attack remap")

	var conflict_result: Dictionary = bindings.remap_action_to_event(
		"attack", _make_key_event(KEY_SPACE)
	)
	_expect(not bool(conflict_result.get("ok", false)), "Attack remap to Space should conflict with jump.")
	_expect_binding(bindings, "attack", "J", "blocked remap must preserve attack")

	bindings.ensure_input_map()
	_expect_binding(bindings, "attack", "J", "version 2 saved remap reload")

	_write_version_1_defaults()
	bindings.ensure_input_map()
	_expect_current_defaults(bindings, "version 1 defaults migration")
	_expect_saved_version(2, "version 1 defaults migration")

	_write_version_1_guard_alias(KEY_B)
	bindings.ensure_input_map()
	_expect_binding(bindings, "guard", "B", "heavy_attack action-name migration")
	_expect_binding(bindings, "attack", "X", "migration must retain new attack default")

	_write_version_1_custom_remap("move_left", KEY_X)
	bindings.ensure_input_map()
	_expect_binding(bindings, "move_left", "X", "version 1 custom remap takes priority")
	_expect_binding(bindings, "attack", "unbound", "conflicting new default is left unbound")
	bindings.ensure_input_map()
	_expect_binding(bindings, "move_left", "X", "migrated custom remap survives reload")
	_expect_binding(bindings, "attack", "unbound", "migrated empty binding survives reload")
	var blocked_default: Dictionary = bindings.restore_action_default("attack")
	_expect(
		not bool(blocked_default.get("ok", false)),
		"Per-action default restore should reject a migrated remap conflict."
	)
	_expect_binding(bindings, "move_left", "X", "blocked default preserves custom remap")
	_expect_binding(bindings, "attack", "unbound", "blocked default preserves empty action")
	_expect(
		bool(bindings.restore_action_default("move_left").get("ok", false)),
		"Move Left should restore after releasing X."
	)
	_expect(
		bool(bindings.restore_action_default("attack").get("ok", false)),
		"Attack should restore after its default key is free."
	)
	_expect_binding(bindings, "move_left", "Left", "resolved default restore move")
	_expect_binding(bindings, "attack", "X", "resolved default restore attack")

	_write_saved_binding(99, "attack", KEY_J)
	bindings.ensure_input_map()
	_expect_binding(bindings, "attack", "X", "unsupported save version reset")
	_expect_saved_version(2, "unsupported save version reset")

	bindings.restore_all_defaults()
	_expect_current_defaults(bindings, "restore all defaults")
	_expect_focus_loss_release(bindings)

	_finish(1 if not _failures.is_empty() else 0)


func _expect_current_defaults(bindings: Node, context: String) -> void:
	for action_name in EXPECTED_DEFAULTS:
		_expect_binding(
			bindings,
			action_name,
			String(EXPECTED_DEFAULTS[action_name]),
			"%s: %s" % [context, action_name]
		)


func _expect_keyboard_only_actions() -> void:
	for action_name in EXPECTED_DEFAULTS:
		if not InputMap.has_action(action_name):
			_failures.append("Tracked action is missing: %s." % action_name)
			continue
		for event in InputMap.action_get_events(action_name):
			if not (event is InputEventKey):
				_failures.append(
					"Tracked action must contain keyboard events only: %s (%s)." % [
						action_name,
						event.get_class(),
					]
				)


func _expect_retired_actions_absent() -> void:
	for action_name in RETIRED_ACTIONS:
		_expect(not InputMap.has_action(action_name), "Retired action should be absent: %s." % action_name)
	_expect(not InputMap.has_action("active_skill"), "No active-skill action should exist before adoption.")


func _expect_binding_rows(bindings: Node) -> void:
	var rows: Array = bindings.get_input_binding_rows()
	_expect(rows.size() == EXPECTED_DEFAULTS.size(), "Settings rows should expose every visible action exactly once.")
	for row_value in rows:
		var row := row_value as Dictionary
		_expect(row.has("action") and row.has("label") and row.has("binding"), "Binding row is missing a keyboard field.")
		_expect(not row.has("gamepad_binding"), "Binding row must not expose a gamepad column.")
		_expect(not row.has("input_device"), "Binding row must not expose device-switch state.")


func _expect_guide(bindings: Node) -> void:
	var guide := String(bindings.get_input_guide_text())
	for required in ["Move Left/Right", "Attack X", "Guard C", "Potion A", "Interact E", "Dismount Space or Shift"]:
		_expect(guide.contains(required), "Input guide should contain '%s'." % required)
	for stale in ["W/Up", "S/Down", "K/Shift", "Attack F", "Guard G", "Consumable H", "D-pad", "R3"]:
		_expect(not guide.contains(stale), "Input guide contains stale text: %s." % stale)


func _expect_chords() -> void:
	for chord_value in CHORDS:
		var chord := chord_value as Array
		for action_name in chord:
			Input.action_press(StringName(action_name))
		for action_name in chord:
			_expect(Input.is_action_pressed(StringName(action_name)), "Simulated chord lost action %s." % action_name)
		for action_name in chord:
			Input.action_release(StringName(action_name))


func _expect_focus_loss_release(bindings: Node) -> void:
	for action_name in ["move_right", "dash", "guard"]:
		Input.action_press(action_name)
	bindings.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	for action_name in ["move_right", "dash", "guard"]:
		_expect(not Input.is_action_pressed(action_name), "Focus loss should release %s." % action_name)


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


func _remove_test_save() -> void:
	if FileAccess.file_exists(_save_path):
		var error := DirAccess.remove_absolute(_save_path)
		if error != OK:
			_failures.append("Unable to remove temporary input binding file: %s." % error_string(error))


func _write_version_1_defaults() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	var defaults := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"dash": [KEY_K, KEY_SHIFT],
		"attack": [KEY_F],
		"guard": [KEY_G],
		"use_consumable": [KEY_H],
		"climb_up": [KEY_W, KEY_UP],
		"climb_down": [KEY_S, KEY_DOWN],
		"climb_cancel": [KEY_C],
		"crouch": [KEY_S, KEY_DOWN],
		"drop_through": [],
		"interact": [KEY_E, KEY_ENTER],
		"pause": [KEY_ESCAPE],
	}
	for action_name in defaults:
		config.set_value("keyboard", action_name, defaults[action_name])
	_save_test_config(config)


func _write_version_1_guard_alias(keycode: int) -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("keyboard", "attack", [KEY_F])
	config.set_value("keyboard", "heavy_attack", [keycode])
	_save_test_config(config)


func _write_version_1_custom_remap(action_name: String, keycode: int) -> void:
	_write_version_1_defaults()
	var config := ConfigFile.new()
	var error := config.load(_save_path)
	if error != OK:
		_failures.append("Unable to load version 1 remap fixture.")
		return
	config.set_value("keyboard", action_name, [keycode])
	_save_test_config(config)


func _write_saved_binding(version: int, action_name: String, keycode: int) -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", version)
	config.set_value("keyboard", action_name, [keycode])
	_save_test_config(config)


func _save_test_config(config: ConfigFile) -> void:
	var error := config.save(_save_path)
	if error != OK:
		_failures.append("Unable to write temporary input binding file: %s." % error_string(error))


func _expect_saved_version(expected: int, context: String) -> void:
	var config := ConfigFile.new()
	var error := config.load(_save_path)
	if error != OK:
		_failures.append("%s: migrated save is unavailable." % context)
		return
	var actual := int(config.get_value("meta", "version", -1))
	_expect(actual == expected, "%s: expected saved version %d, got %d." % [context, expected, actual])
	for retired_action in RETIRED_ACTIONS:
		_expect(
			not config.has_section_key("keyboard", retired_action),
			"%s: retired action remained in save: %s." % [context, retired_action]
		)


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
	_expect(actual == expected, "%s expected %s, got %s." % [context, expected, actual])


func _make_key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(exit_code: int) -> void:
	_restore_saved_file()
	if exit_code != 0:
		for failure in _failures:
			push_error(failure)
	else:
		print(
			"INPUT_REMAP_VALIDATION_OK defaults=%d chords=%d migration=1>2 keyboard_only=true" % [
				EXPECTED_DEFAULTS.size(),
				CHORDS.size(),
			]
		)
	quit(exit_code)
