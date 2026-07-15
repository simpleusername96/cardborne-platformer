extends Node

const BINDING_SAVE_PATH := "user://input_bindings.cfg"
const META_SECTION := "meta"
const KEYBOARD_SECTION := "keyboard"
const SAVE_VERSION := 2

const RETIRED_ACTIONS := [
	"climb_cancel",
	"heavy_attack",
	"skill_1",
	"skill_2",
	"skill_3",
]

# Version 1 persisted every default, so those exact values must become the new
# defaults while genuine player remaps continue to load.
const VERSION_1_DEFAULTS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"dash": [KEY_K, KEY_SHIFT],
	"attack": [KEY_F],
	"guard": [KEY_G],
	"heavy_attack": [KEY_G],
	"use_consumable": [KEY_H],
	"climb_up": [KEY_W, KEY_UP],
	"climb_down": [KEY_S, KEY_DOWN],
	"climb_cancel": [KEY_C],
	"crouch": [KEY_S, KEY_DOWN],
	"drop_through": [],
	"interact": [KEY_E, KEY_ENTER],
	"pause": [KEY_ESCAPE],
}
const VERSION_1_ACTION_ALIASES := {
	"guard": "heavy_attack",
}

const ACTION_DEFINITIONS := [
	{"name": "move_left", "label": "move left", "default_keys": [KEY_LEFT]},
	{"name": "move_right", "label": "move right", "default_keys": [KEY_RIGHT]},
	{"name": "jump", "label": "jump", "default_keys": [KEY_SPACE]},
	{"name": "dash", "label": "dash", "default_keys": [KEY_SHIFT]},
	{"name": "attack", "label": "attack", "default_keys": [KEY_X]},
	{"name": "guard", "label": "guard", "default_keys": [KEY_C]},
	{"name": "use_consumable", "label": "potion", "default_keys": [KEY_A]},
	{"name": "climb_up", "label": "climb up", "default_keys": [KEY_UP]},
	{"name": "climb_down", "label": "climb down", "default_keys": [KEY_DOWN]},
	{"name": "crouch", "label": "crouch/drop", "default_keys": [KEY_DOWN]},
	{"name": "drop_through", "label": "drop through", "default_keys": [], "hidden": true},
	{"name": "interact", "label": "interact", "default_keys": [KEY_E]},
	{"name": "pause", "label": "settings", "default_keys": [KEY_ESCAPE]},
]

var _definitions_by_name: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_input_map()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_gameplay_actions()


func ensure_input_map() -> void:
	_index_definitions()
	_remove_retired_actions()
	_restore_defaults_without_saving()
	if _load_saved_bindings():
		_save_bindings()
	SignalBus.input_bindings_changed.emit()


func get_input_guide_text() -> String:
	return "\n".join([
		"Controls",
		"Move %s | Crouch/drop %s" % [
			get_binding_text("move_left", "Left") + "/" + get_binding_text("move_right", "Right"),
			get_binding_text("crouch", "Down"),
		],
		"Jump %s | Dash %s | Attack %s | Guard %s" % [
			get_binding_text("jump", "Space"),
			get_binding_text("dash", "Shift"),
			get_binding_text("attack", "X"),
			get_binding_text("guard", "C"),
		],
		"Potion %s" % [
			get_binding_text("use_consumable", "A"),
		],
		"Climb %s/%s | Dismount %s or %s" % [
			get_binding_text("climb_up", "Up"),
			get_binding_text("climb_down", "Down"),
			get_binding_text("jump", "Space"),
			get_binding_text("dash", "Shift"),
		],
		"Interact %s | Settings %s" % [
			get_binding_text("interact", "E"),
			get_binding_text("pause", "Esc"),
		],
	])


func get_input_binding_lines() -> Array[String]:
	var lines: Array[String] = []
	for definition in ACTION_DEFINITIONS:
		if bool(definition.get("hidden", false)):
			continue
		var action_name := str(definition["name"])
		lines.append("%s: %s" % [str(definition["label"]), get_binding_text(action_name, "unbound")])
	return lines


func get_input_binding_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for definition in ACTION_DEFINITIONS:
		if bool(definition.get("hidden", false)):
			continue
		var action_name := str(definition["name"])
		rows.append({
			"action": action_name,
			"label": str(definition["label"]),
			"binding": get_binding_text(action_name, "unbound"),
		})
	return rows


func get_action_label(action_name: String) -> String:
	_index_definitions()
	var definition: Dictionary = _definitions_by_name.get(action_name, {})
	return str(definition.get("label", action_name))


func get_binding_text(action_name: String, fallback: String = "unbound") -> String:
	if not InputMap.has_action(action_name):
		return fallback

	var labels: Array[String] = []
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := _keycode_from_event(key_event)
			if keycode != KEY_NONE:
				labels.append(OS.get_keycode_string(keycode))

	labels = _dedupe_strings(labels)
	if labels.is_empty():
		return fallback
	return "/".join(labels)


func release_gameplay_actions() -> void:
	for definition in ACTION_DEFINITIONS:
		Input.action_release(StringName(definition["name"]))


func remap_action_to_event(action_name: String, event: InputEventKey) -> Dictionary:
	if not is_tracked_action(action_name):
		return {"ok": false, "message": "Unknown action: %s" % action_name}

	var keycode := _keycode_from_event(event)
	if keycode == KEY_NONE:
		return {"ok": false, "message": "Only keyboard keys are supported in this pass."}

	var conflict := get_conflict_for_key(action_name, keycode)
	if not conflict.is_empty():
		return {
			"ok": false,
			"message": "%s is already used by %s." % [OS.get_keycode_string(keycode), conflict],
		}

	_apply_keycodes(action_name, [keycode])
	_save_bindings()
	SignalBus.input_bindings_changed.emit()
	return {"ok": true, "message": "%s set to %s." % [get_action_label(action_name), OS.get_keycode_string(keycode)]}


func restore_action_default(action_name: String) -> Dictionary:
	if not is_tracked_action(action_name):
		return {"ok": false, "message": "Unknown action: %s" % action_name}

	var definition: Dictionary = _definitions_by_name[action_name]
	var default_keycodes := _to_int_array(definition.get("default_keys", []))
	var conflict := _conflict_for_keycodes(action_name, default_keycodes)
	if not conflict.is_empty():
		return {
			"ok": false,
			"message": "%s default conflicts with %s. Reset that action first."
			% [get_action_label(action_name), conflict],
		}
	_apply_keycodes(action_name, default_keycodes)
	_save_bindings()
	SignalBus.input_bindings_changed.emit()
	return {"ok": true, "message": "%s binding restored." % get_action_label(action_name)}


func restore_all_defaults() -> void:
	_restore_defaults_without_saving()
	_save_bindings()
	SignalBus.input_bindings_changed.emit()


func is_tracked_action(action_name: String) -> bool:
	_index_definitions()
	return _definitions_by_name.has(action_name)


func get_conflict_for_key(action_name: String, keycode: int) -> String:
	for definition in ACTION_DEFINITIONS:
		var other_action := str(definition["name"])
		if _is_allowed_overlap(action_name, other_action):
			continue
		if _keycodes_for_action(other_action).has(keycode):
			return str(definition["label"])
	return ""


func _conflict_for_keycodes(action_name: String, keycodes: Array[int]) -> String:
	for keycode in keycodes:
		var conflict := get_conflict_for_key(action_name, keycode)
		if not conflict.is_empty():
			return conflict
	return ""


func _index_definitions() -> void:
	if not _definitions_by_name.is_empty():
		return
	for definition in ACTION_DEFINITIONS:
		_definitions_by_name[str(definition["name"])] = definition


func _restore_defaults_without_saving() -> void:
	_index_definitions()
	for definition in ACTION_DEFINITIONS:
		var action_name := str(definition["name"])
		_apply_keycodes(action_name, _to_int_array(definition.get("default_keys", [])))


func _load_saved_bindings() -> bool:
	var config := ConfigFile.new()
	var error := config.load(BINDING_SAVE_PATH)
	if error != OK:
		return false

	var saved_version := int(config.get_value(META_SECTION, "version", 1))
	if saved_version < 1 or saved_version > SAVE_VERSION:
		push_warning(
			"Resetting input bindings from unsupported save version %d." % saved_version
		)
		return true

	var saved_bindings: Array[Dictionary] = []
	for definition in ACTION_DEFINITIONS:
		var action_name := str(definition["name"])
		var source_action := _saved_source_action(config, action_name, saved_version)
		if source_action.is_empty():
			continue
		var saved_value: Variant = config.get_value(KEYBOARD_SECTION, source_action)
		if not (saved_value is Array):
			continue
		var keycodes := _to_int_array(saved_value)
		if saved_version == 1 and _matches_version_1_default(source_action, keycodes):
			continue
		saved_bindings.append({"action": action_name, "keycodes": keycodes})

	# Version 1 did not know the accepted defaults. Genuine remaps own their keys;
	# a newly assigned default is left unbound when it would steal that remap.
	if saved_version == 1:
		_clear_default_conflicts_for_migration(saved_bindings)
	else:
		# Version 2 persists intentional empty bindings created by that migration.
		for saved in saved_bindings:
			if (saved["keycodes"] as Array).is_empty():
				_apply_keycodes(String(saved["action"]), [])

	for saved in saved_bindings:
		var action_name := String(saved["action"])
		var keycodes := saved["keycodes"] as Array[int]
		if keycodes.is_empty():
			_apply_keycodes(action_name, [])
			continue
		var conflict := _conflict_for_keycodes(action_name, keycodes)
		if not conflict.is_empty():
			push_warning("Ignoring saved binding for %s because it conflicts with %s." % [action_name, conflict])
			continue
		_apply_keycodes(action_name, keycodes)
	return saved_version != SAVE_VERSION


func _clear_default_conflicts_for_migration(saved_bindings: Array[Dictionary]) -> void:
	for saved in saved_bindings:
		var owner := String(saved["action"])
		var keycodes := saved["keycodes"] as Array[int]
		for keycode in keycodes:
			for definition in ACTION_DEFINITIONS:
				var other_action := String(definition["name"])
				if _is_allowed_overlap(owner, other_action):
					continue
				if _keycodes_for_action(other_action).has(keycode):
					_apply_keycodes(other_action, [])


func _saved_source_action(config: ConfigFile, action_name: String, saved_version: int) -> String:
	if config.has_section_key(KEYBOARD_SECTION, action_name):
		return action_name
	if saved_version == 1:
		var alias := str(VERSION_1_ACTION_ALIASES.get(action_name, ""))
		if not alias.is_empty() and config.has_section_key(KEYBOARD_SECTION, alias):
			return alias
	return ""


func _matches_version_1_default(action_name: String, keycodes: Array[int]) -> bool:
	if not VERSION_1_DEFAULTS.has(action_name):
		return false
	var expected := _to_int_array(VERSION_1_DEFAULTS[action_name])
	keycodes.sort()
	expected.sort()
	return keycodes == expected


func _save_bindings() -> void:
	var config := ConfigFile.new()
	config.set_value(META_SECTION, "version", SAVE_VERSION)
	for definition in ACTION_DEFINITIONS:
		var action_name := str(definition["name"])
		config.set_value(KEYBOARD_SECTION, action_name, _keycodes_for_action(action_name))
	var error := config.save(BINDING_SAVE_PATH)
	if error != OK:
		push_warning("Unable to save input bindings: %s" % error_string(error))


func _apply_keycodes(action_name: String, keycodes: Array[int]) -> void:
	_ensure_action(action_name)
	InputMap.action_erase_events(action_name)
	for keycode in _dedupe_ints(keycodes):
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)


func _ensure_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)


func _keycodes_for_action(action_name: String) -> Array[int]:
	var keycodes: Array[int] = []
	if not InputMap.has_action(action_name):
		return keycodes

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var keycode := _keycode_from_event(event as InputEventKey)
			if keycode != KEY_NONE:
				keycodes.append(keycode)
	return _dedupe_ints(keycodes)


func _keycode_from_event(event: InputEventKey) -> int:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode


func _to_int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if not (value is Array):
		return result
	for item in value:
		if item is int:
			result.append(int(item))
	return _dedupe_ints(result)


func _dedupe_ints(values: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		if not result.has(value):
			result.append(value)
	return result


func _dedupe_strings(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		if not result.has(value):
			result.append(value)
	return result


func _remove_retired_actions() -> void:
	for action_name in RETIRED_ACTIONS:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)


func _is_allowed_overlap(action_a: String, action_b: String) -> bool:
	if action_a == action_b:
		return true

	var crouch_climb_down := ["crouch", "climb_down"]
	if crouch_climb_down.has(action_a) and crouch_climb_down.has(action_b):
		return true
	return false
