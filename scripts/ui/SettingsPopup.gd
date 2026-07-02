extends Control

var panel: PanelContainer
var close_button: Button
var binding_list_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	SignalBus.settings_visibility_changed.connect(_on_settings_visibility_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_panel()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
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

	var bindings_title := Label.new()
	bindings_title.text = "Input bindings (remap deferred)"
	bindings_title.add_theme_font_size_override("font_size", 15)
	root_box.add_child(bindings_title)

	binding_list_label = Label.new()
	binding_list_label.text = _binding_list_text()
	binding_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binding_list_label.add_theme_font_size_override("font_size", 12)
	root_box.add_child(binding_list_label)

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


func _layout_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var panel_size := Vector2(minf(620.0, viewport_size.x - 32.0), minf(560.0, viewport_size.y - 32.0))
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
	if visible and binding_list_label != null:
		binding_list_label.text = _binding_list_text()
	if visible and close_button != null:
		close_button.grab_focus()


func _binding_list_text() -> String:
	return "\n".join(Game.get_input_binding_lines())
