extends Control

const BINDING_HINT := "Keyboard only; mouse/gamepad remap deferred."

var panel: PanelContainer
var close_button: Button
var bindings_box: VBoxContainer
var warning_label: Label
var binding_row_labels: Dictionary = {}
var capture_action_name: String = ""
var capture_action_label: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	SignalBus.settings_visibility_changed.connect(_on_settings_visibility_changed)
	SignalBus.input_bindings_changed.connect(_on_input_bindings_changed)


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
				var keycode := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
				if keycode == KEY_ESCAPE and capture_action_name != "pause":
					_clear_capture(true)
					return
				_apply_captured_key(key_event)
		return

	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		Game.set_settings_open(false)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	margin.add_child(root_box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_box.add_child(header)

	var title := Label.new()
	title.text = "Settings"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(88, 40)
	close_button.pressed.connect(func() -> void: Game.set_settings_open(false))
	header.add_child(close_button)

	root_box.add_child(_make_slider_row("Master", "master_volume"))
	root_box.add_child(_make_slider_row("Music", "music_volume"))
	root_box.add_child(_make_slider_row("SFX", "sfx_volume"))

	var toggle_row := HBoxContainer.new()
	toggle_row.add_theme_constant_override("separation", 20)
	root_box.add_child(toggle_row)
	toggle_row.add_child(_make_check_box("Screen shake", "screen_shake"))
	toggle_row.add_child(_make_check_box("Damage flash", "damage_flash"))

	var bindings_header := HBoxContainer.new()
	bindings_header.add_theme_constant_override("separation", 12)
	root_box.add_child(bindings_header)

	var bindings_title := Label.new()
	bindings_title.text = "Input bindings"
	bindings_title.add_theme_font_size_override("font_size", 15)
	bindings_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bindings_header.add_child(bindings_title)

	var restore_all_button := Button.new()
	restore_all_button.text = "Restore all"
	restore_all_button.custom_minimum_size = Vector2(108, 34)
	restore_all_button.pressed.connect(_restore_all_defaults)
	bindings_header.add_child(restore_all_button)

	warning_label = Label.new()
	warning_label.text = BINDING_HINT
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.add_theme_font_size_override("font_size", 12)
	root_box.add_child(warning_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 248.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)

	bindings_box = VBoxContainer.new()
	bindings_box.add_theme_constant_override("separation", 6)
	bindings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bindings_box)

	_rebuild_binding_rows()
	_layout_panel()


func _make_slider_row(label_text: String, setting_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(84, 32)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = float(RunState.get_setting(setting_name, 0.8)) * 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(220, 36)
	slider.value_changed.connect(func(value: float) -> void:
		RunState.set_setting(setting_name, value / 100.0)
	)
	row.add_child(slider)
	return row


func _make_check_box(label_text: String, setting_name: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = label_text
	checkbox.button_pressed = bool(RunState.get_setting(setting_name, true))
	checkbox.custom_minimum_size = Vector2(150, 40)
	checkbox.toggled.connect(func(is_pressed: bool) -> void:
		RunState.set_setting(setting_name, is_pressed)
	)
	return checkbox


func _make_binding_row(row_info: Dictionary) -> VBoxContainer:
	var action_name := str(row_info["action"])
	var action_label := str(row_info["label"])

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.custom_minimum_size = Vector2(0.0, 68.0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var binding_label := Label.new()
	binding_label.text = _binding_row_text(row_info)
	binding_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binding_label.custom_minimum_size = Vector2(0.0, 24.0)
	binding_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(binding_label)
	binding_row_labels[action_name] = binding_label

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(button_row)

	var change_button := Button.new()
	change_button.text = "Change"
	change_button.custom_minimum_size = Vector2(82.0, 34.0)
	change_button.pressed.connect(func() -> void:
		_begin_capture(action_name, action_label)
	)
	button_row.add_child(change_button)

	var default_button := Button.new()
	default_button.text = "Default"
	default_button.custom_minimum_size = Vector2(82.0, 34.0)
	default_button.pressed.connect(func() -> void:
		_restore_action_default(action_name)
	)
	button_row.add_child(default_button)

	return row


func _rebuild_binding_rows() -> void:
	if bindings_box == null:
		return

	for child in bindings_box.get_children():
		bindings_box.remove_child(child)
		child.queue_free()
	binding_row_labels.clear()

	for row_info in Game.get_input_binding_rows():
		bindings_box.add_child(_make_binding_row(row_info))


func _refresh_binding_rows() -> void:
	for row_info in Game.get_input_binding_rows():
		var action_name := str(row_info["action"])
		if not binding_row_labels.has(action_name):
			_rebuild_binding_rows()
			return
		var binding_label := binding_row_labels[action_name] as Label
		binding_label.text = _binding_row_text(row_info)


func _binding_row_text(row_info: Dictionary) -> String:
	return "%s: %s" % [str(row_info["label"]), str(row_info["binding"])]


func _begin_capture(action_name: String, action_label: String) -> void:
	capture_action_name = action_name
	capture_action_label = action_label
	warning_label.text = "Press a key for %s. Esc cancels." % action_label


func _apply_captured_key(key_event: InputEventKey) -> void:
	var result := Game.remap_action_to_event(capture_action_name, key_event)
	if bool(result.get("ok", false)):
		warning_label.text = str(result.get("message", "Binding updated."))
		capture_action_name = ""
		capture_action_label = ""
		_refresh_binding_rows()
	else:
		warning_label.text = str(result.get("message", "Unable to use that key."))


func _clear_capture(show_message: bool) -> void:
	capture_action_name = ""
	capture_action_label = ""
	if show_message:
		warning_label.text = "Remap canceled."


func _restore_action_default(action_name: String) -> void:
	var result := Game.restore_action_default(action_name)
	warning_label.text = str(result.get("message", "Default restored."))
	_clear_capture(false)
	_refresh_binding_rows()


func _restore_all_defaults() -> void:
	Game.restore_all_input_defaults()
	warning_label.text = "Default bindings restored."
	_clear_capture(false)
	_refresh_binding_rows()


func _layout_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var panel_size := Vector2(minf(660.0, viewport_size.x - 32.0), minf(640.0, viewport_size.y - 32.0))
	var panel_position := (viewport_size - panel_size) * 0.5
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.97)
	style.border_color = Color(0.52, 0.58, 0.66, 0.85)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _on_settings_visibility_changed(is_visible: bool) -> void:
	visible = is_visible
	if visible:
		warning_label.text = BINDING_HINT
		_refresh_binding_rows()
		if close_button != null:
			close_button.grab_focus()
	else:
		_clear_capture(false)


func _on_input_bindings_changed() -> void:
	if visible:
		_refresh_binding_rows()
