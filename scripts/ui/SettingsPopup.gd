extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const BINDING_HINT := "Keyboard keys can be remapped. Gamepad layout is fixed."

@onready var panel: PanelContainer = %SettingsPanel
@onready var title_label: Label = %SettingsTitle
@onready var accent_rule: ColorRect = %SettingsRule
@onready var close_button: Button = %CloseButton
@onready var restore_all_button: Button = %RestoreAllButton
@onready var bindings_box: VBoxContainer = %BindingsBox
@onready var warning_label: Label = %BindingStatus
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SfxValue
@onready var screen_shake_toggle: CheckBox = %ScreenShakeToggle
@onready var damage_flash_toggle: CheckBox = %DamageFlashToggle

var binding_row_controls: Dictionary = {}
var capture_action_name: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style_ui()
	_configure_settings_controls()
	_rebuild_binding_rows()
	close_button.pressed.connect(func() -> void: Game.set_settings_open(false))
	restore_all_button.pressed.connect(_restore_all_defaults)
	SignalBus.settings_visibility_changed.connect(_on_settings_visibility_changed)
	SignalBus.input_bindings_changed.connect(_on_input_bindings_changed)
	_layout_panel()
	call_deferred("_layout_panel")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_panel()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if not capture_action_name.is_empty():
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo:
				get_viewport().set_input_as_handled()
				var keycode := (
					key_event.physical_keycode
					if key_event.physical_keycode != KEY_NONE
					else key_event.keycode
				)
				if keycode == KEY_ESCAPE and capture_action_name != "pause":
					_clear_capture(true)
					return
				_apply_captured_key(key_event)
		elif event is InputEventJoypadButton:
			var button_event := event as InputEventJoypadButton
			if button_event.pressed:
				get_viewport().set_input_as_handled()
				if button_event.button_index == JOY_BUTTON_B:
					_clear_capture(true)
		return

	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.set_settings_open(false)


func _style_ui() -> void:
	panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.99), Styles.OUTLINE)
	)
	Styles.configure_label(title_label, 28, Styles.TEXT)
	accent_rule.color = Styles.MOSS
	Styles.apply_button(close_button, Styles.CYAN, true)
	Styles.apply_button(restore_all_button, Styles.MOSS, true)
	close_button.add_theme_font_size_override("font_size", 15)
	restore_all_button.add_theme_font_size_override("font_size", 14)
	for label in [%AudioHeading, %FeedbackHeading, %ControlsHeading]:
		Styles.configure_label(label as Label, 15, Styles.AMBER)
	for label in [%ActionColumn, %KeyboardColumn, %GamepadColumn]:
		Styles.configure_label(label as Label, 11, Styles.TEXT_MUTED)
	for label in [%MasterLabel, %MusicLabel, %SfxLabel]:
		Styles.configure_label(label as Label, 14, Styles.TEXT)
	for label in [master_value, music_value, sfx_value]:
		Styles.configure_label(label, 13, Styles.TEXT_MUTED)
	Styles.configure_label(warning_label, 12, Styles.TEXT_MUTED)
	screen_shake_toggle.add_theme_font_size_override("font_size", 14)
	damage_flash_toggle.add_theme_font_size_override("font_size", 14)
	screen_shake_toggle.add_theme_color_override("font_color", Styles.TEXT)
	damage_flash_toggle.add_theme_color_override("font_color", Styles.TEXT)


func _configure_settings_controls() -> void:
	_configure_slider(master_slider, master_value, "master_volume")
	_configure_slider(music_slider, music_value, "music_volume")
	_configure_slider(sfx_slider, sfx_value, "sfx_volume")
	screen_shake_toggle.set_pressed_no_signal(
		bool(RunState.get_setting("screen_shake", true))
	)
	damage_flash_toggle.set_pressed_no_signal(
		bool(RunState.get_setting("damage_flash", true))
	)
	screen_shake_toggle.toggled.connect(func(enabled: bool) -> void:
		RunState.set_setting("screen_shake", enabled)
	)
	damage_flash_toggle.toggled.connect(func(enabled: bool) -> void:
		RunState.set_setting("damage_flash", enabled)
	)


func _configure_slider(slider: HSlider, value_label: Label, setting_name: String) -> void:
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.set_value_no_signal(float(RunState.get_setting(setting_name, 0.8)) * 100.0)
	_update_slider_value(value_label, slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		RunState.set_setting(setting_name, value / 100.0)
		_update_slider_value(value_label, value)
	)


func _update_slider_value(label: Label, value: float) -> void:
	label.text = "%d%%" % int(round(value))


func _make_binding_row(row_info: Dictionary) -> HBoxContainer:
	var action_name := String(row_info["action"])
	var action_label := String(row_info["label"]).capitalize()

	var row := HBoxContainer.new()
	row.name = "Binding_%s" % action_name
	row.custom_minimum_size = Vector2(0.0, 44.0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var action := Label.new()
	action.text = action_label
	action.custom_minimum_size = Vector2(105.0, 0.0)
	action.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(action, 13, Styles.TEXT)
	row.add_child(action)

	var keyboard_button := Button.new()
	keyboard_button.text = String(row_info.get("keyboard_binding", "Unbound"))
	keyboard_button.custom_minimum_size = Vector2(155.0, 40.0)
	keyboard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keyboard_button.clip_text = true
	Styles.apply_button(keyboard_button, Styles.CYAN, true)
	keyboard_button.add_theme_font_size_override("font_size", 13)
	keyboard_button.pressed.connect(func() -> void:
		_begin_capture(action_name, action_label)
	)
	row.add_child(keyboard_button)

	var gamepad_label := Label.new()
	gamepad_label.text = String(row_info.get("gamepad_binding", "Unbound"))
	gamepad_label.custom_minimum_size = Vector2(145.0, 0.0)
	gamepad_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gamepad_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(gamepad_label, 12, Styles.TEXT_MUTED)
	row.add_child(gamepad_label)

	var default_button := Button.new()
	default_button.text = "Default"
	default_button.custom_minimum_size = Vector2(78.0, 40.0)
	Styles.apply_button(default_button, Styles.MOSS, true)
	default_button.add_theme_font_size_override("font_size", 12)
	default_button.pressed.connect(func() -> void:
		_restore_action_default(action_name)
	)
	row.add_child(default_button)

	binding_row_controls[action_name] = {
		"keyboard": keyboard_button,
		"gamepad": gamepad_label,
	}
	return row


func _rebuild_binding_rows() -> void:
	if bindings_box == null:
		return
	for child in bindings_box.get_children():
		bindings_box.remove_child(child)
		child.queue_free()
	binding_row_controls.clear()
	for row_info in Game.get_input_binding_rows():
		bindings_box.add_child(_make_binding_row(row_info))
	call_deferred("_layout_panel")


func _refresh_binding_rows() -> void:
	for row_info in Game.get_input_binding_rows():
		var action_name := String(row_info["action"])
		if not binding_row_controls.has(action_name):
			_rebuild_binding_rows()
			return
		var controls: Dictionary = binding_row_controls[action_name]
		var keyboard_button := controls["keyboard"] as Button
		var gamepad_label := controls["gamepad"] as Label
		keyboard_button.text = (
			"Press a key"
			if action_name == capture_action_name
			else String(row_info.get("keyboard_binding", "Unbound"))
		)
		gamepad_label.text = String(row_info.get("gamepad_binding", "Unbound"))


func _begin_capture(action_name: String, action_label: String) -> void:
	capture_action_name = action_name
	warning_label.text = "Press a keyboard key for %s. Esc or gamepad B cancels." % action_label
	_refresh_binding_rows()


func _apply_captured_key(key_event: InputEventKey) -> void:
	var result := Game.remap_action_to_event(capture_action_name, key_event)
	if bool(result.get("ok", false)):
		capture_action_name = ""
		warning_label.text = String(result.get("message", "Binding updated."))
		_refresh_binding_rows()
	else:
		warning_label.text = String(result.get("message", "Unable to use that key."))


func _clear_capture(show_message: bool) -> void:
	capture_action_name = ""
	if show_message:
		warning_label.text = "Remap canceled."
	_refresh_binding_rows()


func _restore_action_default(action_name: String) -> void:
	var result := Game.restore_action_default(action_name)
	capture_action_name = ""
	warning_label.text = String(result.get("message", "Keyboard default restored."))
	_refresh_binding_rows()


func _restore_all_defaults() -> void:
	Game.restore_all_input_defaults()
	capture_action_name = ""
	warning_label.text = "Default keyboard bindings restored."
	_refresh_binding_rows()


func _layout_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var panel_size := Vector2(
		minf(900.0, viewport_size.x - 24.0),
		minf(650.0, viewport_size.y - 24.0)
	)
	var panel_position := (viewport_size - panel_size) * 0.5
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y


func _on_settings_visibility_changed(is_visible: bool) -> void:
	visible = is_visible
	if visible:
		close_button.text = "Back" if Game.pause_menu_open else "Close"
		warning_label.text = BINDING_HINT
		_refresh_binding_rows()
		close_button.grab_focus()
	else:
		_clear_capture(false)


func _on_input_bindings_changed() -> void:
	if visible:
		_refresh_binding_rows()
