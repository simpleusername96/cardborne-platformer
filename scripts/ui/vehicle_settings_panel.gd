class_name VehicleSettingsPanel
extends VBoxContainer

## Shared, scroll-safe settings surface used from deployment, pause, and garage.
## It owns presentation and input capture only; SettingsStore remains persistence
## truth and GameRoot applies the resulting InputMap.

signal close_requested

const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const ACTION_TITLE_KEYS := {
	&"primary_fire": "ACTION_PRIMARY",
	&"dash": "ACTION_DASH",
	&"active_skill": "ACTION_EMP",
	&"move_left": "SETTINGS_MOVEMENT_RESERVED",
	&"move_right": "SETTINGS_MOVEMENT_RESERVED",
	&"move_up": "SETTINGS_MOVEMENT_RESERVED",
	&"move_down": "SETTINGS_MOVEMENT_RESERVED",
	&"pause": "SETTINGS_PAUSE_RESERVED",
}

var _tabs: TabContainer
var _close_button: Button
var _binding_buttons: Dictionary = {}
var _master_slider: HSlider
var _sfx_slider: HSlider
var _preset_selector: OptionButton
var _reduced_motion_toggle: CheckButton
var _language_buttons: Dictionary = {}
var _status_label: Label
var _capturing_action: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build()
	_refresh_localized_content()
	_connect_store()
	refresh_from_store()


func open() -> void:
	visible = true
	_cancel_capture(false)
	refresh_from_store()
	if is_instance_valid(_close_button):
		_close_button.grab_focus()


func first_focus() -> Control:
	return _close_button


func is_capturing_binding() -> bool:
	return not _capturing_action.is_empty()


func refresh_from_store() -> void:
	var settings := _settings_store()
	if settings == null or not is_instance_valid(_tabs):
		return
	_master_slider.set_value_no_signal(settings.master_volume)
	_sfx_slider.set_value_no_signal(settings.sfx_volume)
	for action in InputProfile.REMAPPABLE_ACTIONS:
		var button: Button = _binding_buttons.get(action)
		if is_instance_valid(button):
			button.text = InputProfile.action_display_name(action, settings.control_bindings)
	if _preset_selector.item_count > 0:
		var preset_index := 1 if settings.combat_preset == &"onslaught" else 0
		_preset_selector.select(preset_index)
	_reduced_motion_toggle.set_pressed_no_signal(settings.reduced_motion)
	_refresh_localized_content()


func debug_contract() -> Dictionary:
	return {
		"tabs": _tabs.get_tab_count() if is_instance_valid(_tabs) else 0,
		"binding_controls": _binding_buttons.size(),
		"minimum_size": custom_minimum_size,
		"focusables": find_children("*", "Control", true, false).filter(
			func(control: Control) -> bool: return control.focus_mode != Control.FOCUS_NONE
		).size(),
		"capturing": is_capturing_binding(),
		"reduced_motion_control": is_instance_valid(_reduced_motion_toggle) and _reduced_motion_toggle.custom_minimum_size.y >= 44.0,
	}


func _input(event: InputEvent) -> void:
	if not visible or not is_inside_tree():
		return
	if not _capturing_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_cancel_capture(true)
			get_viewport().set_input_as_handled()
			return
		var descriptor := InputProfile.descriptor_from_event(event)
		if not descriptor.is_empty():
			_commit_captured_binding(descriptor)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _build() -> void:
	custom_minimum_size = Vector2(760.0, 410.0)
	add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	var title := _label("SETTINGS_TITLE", 28, Art.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_close_button = _button("SETTINGS_CLOSE", &"SecondaryButton")
	_close_button.custom_minimum_size.x = 112.0
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(_close_button)

	_status_label = _label("SETTINGS_STATUS_READY", 14, Art.INK_MUTED)
	_status_label.custom_minimum_size.y = 24.0
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)

	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.custom_minimum_size.y = 312.0
	_tabs.focus_mode = Control.FOCUS_ALL
	add_child(_tabs)
	_style_tab_bar()
	_build_audio_page()
	_build_controls_page()
	_build_gameplay_page()
	_build_language_page()


func _build_audio_page() -> void:
	var box := _page("Audio")
	box.add_child(_section_title("SETTINGS_AUDIO_HEADING"))
	box.add_child(_label("PAUSE_MASTER_VOLUME", 15, Art.INK))
	_master_slider = _slider()
	_master_slider.value_changed.connect(_on_master_volume_changed)
	box.add_child(_master_slider)
	box.add_child(_label("PAUSE_EFFECTS_VOLUME", 15, Art.INK))
	_sfx_slider = _slider()
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	box.add_child(_sfx_slider)


func _build_controls_page() -> void:
	var box := _page("Controls")
	box.add_child(_section_title("SETTINGS_CONTROLS_HEADING"))
	var help := _label("SETTINGS_CONTROLS_HELP", 14, Art.INK_MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help)
	for action in InputProfile.REMAPPABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var action_label := _label(String(ACTION_TITLE_KEYS[action]), 16, Art.INK)
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(action_label)
		var binding_button := _button("INPUT_UNBOUND", &"SecondaryButton")
		binding_button.custom_minimum_size.x = 220.0
		binding_button.pressed.connect(_begin_capture.bind(action))
		row.add_child(binding_button)
		_binding_buttons[action] = binding_button
		box.add_child(row)
	var reset := _button("SETTINGS_RESET_BINDINGS", &"SecondaryButton")
	reset.pressed.connect(_reset_bindings)
	box.add_child(reset)


func _build_gameplay_page() -> void:
	var box := _page("Gameplay")
	box.add_child(_section_title("SETTINGS_GAMEPLAY_HEADING"))
	box.add_child(_label("SETTINGS_COMBAT_PRESET", 16, Art.INK))
	_preset_selector = OptionButton.new()
	_preset_selector.custom_minimum_size.y = 44.0
	_preset_selector.focus_mode = Control.FOCUS_ALL
	_preset_selector.item_selected.connect(_on_preset_selected)
	box.add_child(_preset_selector)
	_reduced_motion_toggle = CheckButton.new()
	_reduced_motion_toggle.text = tr("SETTINGS_REDUCED_MOTION")
	_reduced_motion_toggle.custom_minimum_size.y = 44.0
	_reduced_motion_toggle.focus_mode = Control.FOCUS_ALL
	_reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	box.add_child(_reduced_motion_toggle)
	var detail := _label("SETTINGS_PRESET_DETAIL", 14, Art.INK_MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 72.0
	box.add_child(detail)


func _build_language_page() -> void:
	var box := _page("Language")
	box.add_child(_section_title("SETTINGS_LANGUAGE_HEADING"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for locale in ["ko", "en"]:
		var button := _button("LANGUAGE_KO" if locale == "ko" else "LANGUAGE_EN", &"SecondaryButton")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_locale_selected.bind(locale))
		row.add_child(button)
		_language_buttons[locale] = button


func _page(page_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = page_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	return box


func _section_title(key: String) -> Label:
	return _label(key, 19, Art.MUSTARD)


func _style_tab_bar() -> void:
	_tabs.add_theme_font_override("font", get_theme_default_font())
	_tabs.add_theme_font_size_override("font_size", 17)
	_tabs.add_theme_color_override("font_unselected_color", Art.IVORY_BRIGHT)
	_tabs.add_theme_color_override("font_hovered_color", Art.IVORY_BRIGHT)
	_tabs.add_theme_color_override("font_selected_color", Art.INK)
	_tabs.add_theme_stylebox_override("tab_unselected", _tab_style(Art.BLOCKER_FILL))
	_tabs.add_theme_stylebox_override("tab_hovered", _tab_style(Art.CERAMIC_GREEN_MID))
	_tabs.add_theme_stylebox_override("tab_selected", _tab_style(Art.MUSTARD))
	_tabs.add_theme_stylebox_override("tab_focus", _tab_style(Art.MUSTARD))
	var tab_bar := _tabs.get_tab_bar()
	tab_bar.add_theme_font_override("font", get_theme_default_font())
	tab_bar.add_theme_font_size_override("font_size", 17)
	tab_bar.add_theme_color_override("font_unselected_color", Art.IVORY_BRIGHT)
	tab_bar.add_theme_color_override("font_hovered_color", Art.IVORY_BRIGHT)
	tab_bar.add_theme_color_override("font_selected_color", Art.INK)
	tab_bar.add_theme_stylebox_override("tab_unselected", _tab_style(Art.BLOCKER_FILL))
	tab_bar.add_theme_stylebox_override("tab_hovered", _tab_style(Art.CERAMIC_GREEN_MID))
	tab_bar.add_theme_stylebox_override("tab_selected", _tab_style(Art.MUSTARD))
	tab_bar.add_theme_stylebox_override("tab_focus", _tab_style(Art.MUSTARD))


func _tab_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.custom_minimum_size.y = 44.0
	button.focus_mode = Control.FOCUS_ALL
	return button


func _slider() -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size.y = 44.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	return slider


func _settings_store() -> Node:
	return get_node_or_null("/root/SettingsStore")


func _connect_store() -> void:
	var settings := _settings_store()
	if settings == null:
		return
	if settings.has_signal("controls_changed"):
		settings.controls_changed.connect(_on_controls_changed)
	if settings.has_signal("combat_preset_changed"):
		settings.combat_preset_changed.connect(_on_combat_preset_changed)
	if settings.has_signal("locale_changed"):
		settings.locale_changed.connect(_on_locale_changed)


func _begin_capture(action: StringName) -> void:
	_capturing_action = action
	_status_label.text = tr("SETTINGS_CAPTURE_PROMPT") % tr(String(ACTION_TITLE_KEYS[action]))
	for button_variant in _binding_buttons.values():
		var button := button_variant as Button
		button.disabled = button != _binding_buttons[action]
	var active_button := _binding_buttons[action] as Button
	active_button.text = tr("SETTINGS_CAPTURE_WAITING")


func _commit_captured_binding(descriptor: String) -> void:
	var settings := _settings_store()
	if settings == null:
		_cancel_capture(false)
		return
	var conflict := InputProfile.conflict_action(descriptor, settings.control_bindings, _capturing_action)
	if not conflict.is_empty():
		var title_key := String(ACTION_TITLE_KEYS.get(conflict, "SETTINGS_RESERVED_CONTROL"))
		_status_label.text = tr("SETTINGS_BINDING_CONFLICT") % tr(title_key)
		_cancel_capture(false, false)
		return
	var action := _capturing_action
	if settings.set_control_binding(action, descriptor):
		_status_label.text = tr("SETTINGS_BINDING_SAVED") % [
			tr(String(ACTION_TITLE_KEYS[action])),
			InputProfile.display_name(descriptor),
		]
	_cancel_capture(false, false)
	refresh_from_store()


func _cancel_capture(show_message: bool, restore_ready: bool = true) -> void:
	_capturing_action = &""
	for button_variant in _binding_buttons.values():
		(button_variant as Button).disabled = false
	if show_message:
		_status_label.text = tr("SETTINGS_CAPTURE_CANCELLED")
	elif restore_ready:
		_status_label.text = tr("SETTINGS_STATUS_READY")
	refresh_from_store()


func _reset_bindings() -> void:
	var settings := _settings_store()
	if settings != null:
		settings.reset_control_bindings()
	_status_label.text = tr("SETTINGS_BINDINGS_RESET")
	refresh_from_store()


func _on_master_volume_changed(value: float) -> void:
	var settings := _settings_store()
	if settings != null:
		settings.set_master_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	var settings := _settings_store()
	if settings != null:
		settings.set_sfx_volume(value)


func _on_preset_selected(index: int) -> void:
	var settings := _settings_store()
	if settings != null:
		settings.set_combat_preset(&"onslaught" if index == 1 else &"standard")


func _on_reduced_motion_toggled(enabled: bool) -> void:
	var settings := _settings_store()
	if settings != null:
		settings.set_reduced_motion(enabled)


func _on_locale_selected(locale: String) -> void:
	var settings := _settings_store()
	if settings != null:
		settings.set_ui_locale(locale)


func _on_controls_changed(_action: StringName) -> void:
	refresh_from_store()


func _on_combat_preset_changed(_preset: StringName) -> void:
	refresh_from_store()


func _on_locale_changed(_locale: String) -> void:
	_refresh_localized_content()
	refresh_from_store()


func _refresh_localized_content() -> void:
	if not is_instance_valid(_tabs):
		return
	var tab_keys := ["SETTINGS_AUDIO_TAB", "SETTINGS_CONTROLS_TAB", "SETTINGS_GAMEPLAY_TAB", "SETTINGS_LANGUAGE_TAB"]
	for index in mini(_tabs.get_tab_count(), tab_keys.size()):
		_tabs.set_tab_title(index, tr(tab_keys[index]))
	_preset_selector.clear()
	_preset_selector.add_item(tr("SETTINGS_PRESET_STANDARD"), 0)
	_preset_selector.add_item(tr("SETTINGS_PRESET_ONSLAUGHT"), 1)
	_reduced_motion_toggle.text = tr("SETTINGS_REDUCED_MOTION")
	var settings := _settings_store()
	if settings != null:
		_preset_selector.select(1 if settings.combat_preset == &"onslaught" else 0)
		for locale in _language_buttons:
			var button := _language_buttons[locale] as Button
			button.theme_type_variation = &"SelectedChoiceButton" if locale == settings.ui_locale else &"SecondaryButton"
