class_name VehicleSettingsPanel
extends VBoxContainer

## Shared, scroll-safe settings surface used from deployment, pause, and garage.
## It owns presentation and input capture only; SettingsStore remains persistence
## truth and GameRoot applies the resulting InputMap.

signal close_requested
signal guide_requested

const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const BuildSummaryPanel = preload("res://scripts/ui/vehicle_build_summary_panel.gd")

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
var _reduced_motion_toggle: CheckButton
var _language_buttons: Dictionary = {}
var _status_label: Label
var _build_summary: VehicleBuildSummaryPanel
var _build_snapshot: Dictionary = {}
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
	_tabs.current_tab = 0
	_build_summary.set_snapshot(_build_snapshot)
	if is_instance_valid(_close_button):
		_close_button.grab_focus()


func set_compact_mode(compact: bool) -> void:
	custom_minimum_size = (
		Vector2(820.0, 456.0)
		if compact
		else Vector2(856.0, 500.0)
	)
	if is_instance_valid(_tabs):
		_tabs.custom_minimum_size.y = 376.0 if compact else 420.0


func set_build_snapshot(snapshot: Dictionary) -> void:
	_build_snapshot = snapshot.duplicate(true)
	if is_instance_valid(_build_summary):
		_build_summary.set_snapshot(_build_snapshot)


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
		"difficulty_controls": find_children("*", "OptionButton", true, false).size(),
		"difficulty_copy_visible":false,
		"ship_status":_build_summary.debug_contract() if is_instance_valid(_build_summary) else {},
	}


func debug_show_gameplay_page() -> void:
	_tabs.current_tab = 3


func _input(event: InputEvent) -> void:
	if not is_inside_tree() or not is_visible_in_tree():
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
	custom_minimum_size = Vector2(856.0, 500.0)
	add_theme_constant_override("separation", 12)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	var title := _label("SETTINGS_TITLE", 40, Art.IVORY_BRIGHT)
	title.theme_type_variation = &"TitleLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var guide := _button("?", &"SecondaryButton")
	guide.tooltip_text = tr("GUIDE_TITLE")
	guide.accessibility_name = tr("GUIDE_TITLE")
	guide.custom_minimum_size = Vector2(44.0, 44.0)
	guide.pressed.connect(func() -> void: guide_requested.emit())
	header.add_child(guide)
	_close_button = _button("SETTINGS_CLOSE", &"SecondaryButton")
	_close_button.custom_minimum_size.x = 112.0
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(_close_button)

	_status_label = _label("", 14, Art.MINT_SOFT)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.visible = false
	add_child(_status_label)

	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.custom_minimum_size.y = 420.0
	_tabs.focus_mode = Control.FOCUS_ALL
	add_child(_tabs)
	_style_tab_bar()
	_build_ship_status_page()
	_build_audio_page()
	_build_controls_page()
	_build_gameplay_page()
	_build_language_page()


func _build_ship_status_page() -> void:
	var box := _page("ShipStatus")
	_build_summary = BuildSummaryPanel.new()
	box.add_child(_build_summary)


func _build_audio_page() -> void:
	var box := _page("Audio")
	box.add_child(_section_title("SETTINGS_AUDIO_HEADING"))
	box.add_child(_label("PAUSE_MASTER_VOLUME", 15, Art.IVORY_BRIGHT))
	_master_slider = _slider()
	_master_slider.value_changed.connect(_on_master_volume_changed)
	box.add_child(_master_slider)
	box.add_child(_label("PAUSE_EFFECTS_VOLUME", 15, Art.IVORY_BRIGHT))
	_sfx_slider = _slider()
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	box.add_child(_sfx_slider)


func _build_controls_page() -> void:
	var box := _page("Controls")
	box.add_child(_section_title("SETTINGS_CONTROLS_HEADING"))
	var help := _label("SETTINGS_CONTROLS_HELP", 14, Art.MINT_SOFT)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help)
	for action in InputProfile.REMAPPABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var action_label := _label(String(ACTION_TITLE_KEYS[action]), 16, Art.IVORY_BRIGHT)
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
	reset.custom_minimum_size.x = 260.0
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(_reset_bindings)
	box.add_child(reset)


func _build_gameplay_page() -> void:
	var box := _page("Gameplay")
	box.add_child(_section_title("SETTINGS_GAMEPLAY_HEADING"))
	_reduced_motion_toggle = CheckButton.new()
	_reduced_motion_toggle.text = tr("SETTINGS_REDUCED_MOTION")
	_reduced_motion_toggle.custom_minimum_size.y = 44.0
	_reduced_motion_toggle.focus_mode = Control.FOCUS_ALL
	_reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	box.add_child(_reduced_motion_toggle)


func _build_language_page() -> void:
	var box := _page("Language")
	box.add_child(_section_title("SETTINGS_LANGUAGE_HEADING"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for locale in ["ko", "en"]:
		var button := _button("LANGUAGE_KO" if locale == "ko" else "LANGUAGE_EN", &"SecondaryButton")
		button.custom_minimum_size.x = 220.0
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
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	return box


func _section_title(key: String) -> Label:
	var label := _label(key, 22, Art.MUSTARD)
	label.theme_type_variation = &"SectionLabel"
	return label


func _style_tab_bar() -> void:
	_tabs.add_theme_font_override("font", get_theme_default_font())
	_tabs.add_theme_font_size_override("font_size", 18)
	_tabs.add_theme_color_override("font_unselected_color", Art.IVORY_BRIGHT)
	_tabs.add_theme_color_override("font_hovered_color", Art.IVORY_BRIGHT)
	_tabs.add_theme_color_override("font_selected_color", Art.IVORY_BRIGHT)
	var tab_bar := _tabs.get_tab_bar()
	tab_bar.add_theme_font_override("font", get_theme_default_font())
	tab_bar.add_theme_font_size_override("font_size", 18)
	tab_bar.add_theme_color_override("font_unselected_color", Art.IVORY_BRIGHT)
	tab_bar.add_theme_color_override("font_hovered_color", Art.IVORY_BRIGHT)
	tab_bar.add_theme_color_override("font_selected_color", Art.IVORY_BRIGHT)


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
	slider.custom_minimum_size = Vector2(480.0, 44.0)
	slider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
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
	if settings.has_signal("locale_changed"):
		settings.locale_changed.connect(_on_locale_changed)


func _begin_capture(action: StringName) -> void:
	_capturing_action = action
	_status_label.text = tr("SETTINGS_CAPTURE_PROMPT") % tr(String(ACTION_TITLE_KEYS[action]))
	_status_label.visible = true
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
		_status_label.visible = true
		_cancel_capture(false, false)
		return
	var action := _capturing_action
	if settings.set_control_binding(action, descriptor):
		_status_label.text = tr("SETTINGS_BINDING_SAVED") % [
			tr(String(ACTION_TITLE_KEYS[action])),
			InputProfile.display_name(descriptor),
		]
		_status_label.visible = true
	_cancel_capture(false, false)
	refresh_from_store()


func _cancel_capture(show_message: bool, restore_ready: bool = true) -> void:
	_capturing_action = &""
	for button_variant in _binding_buttons.values():
		(button_variant as Button).disabled = false
	if show_message:
		_status_label.text = tr("SETTINGS_CAPTURE_CANCELLED")
		_status_label.visible = true
	elif restore_ready:
		_status_label.text = ""
		_status_label.visible = false
	refresh_from_store()


func _reset_bindings() -> void:
	var settings := _settings_store()
	if settings != null:
		settings.reset_control_bindings()
	_status_label.text = tr("SETTINGS_BINDINGS_RESET")
	_status_label.visible = true
	refresh_from_store()


func _on_master_volume_changed(value: float) -> void:
	var settings := _settings_store()
	if settings != null:
		settings.set_master_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	var settings := _settings_store()
	if settings != null:
		settings.set_sfx_volume(value)


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


func _on_locale_changed(_locale: String) -> void:
	_refresh_localized_content()
	refresh_from_store()
	if is_instance_valid(_build_summary):
		_build_summary.set_snapshot(_build_snapshot)


func _refresh_localized_content() -> void:
	if not is_instance_valid(_tabs):
		return
	var tab_keys := [
		"SHIP_STATUS_TAB",
		"SETTINGS_AUDIO_TAB",
		"SETTINGS_CONTROLS_TAB",
		"SETTINGS_GAMEPLAY_TAB",
		"SETTINGS_LANGUAGE_TAB",
	]
	for index in mini(_tabs.get_tab_count(), tab_keys.size()):
		_tabs.set_tab_title(index, tr(tab_keys[index]))
	_reduced_motion_toggle.text = tr("SETTINGS_REDUCED_MOTION")
	var settings := _settings_store()
	if settings != null:
		for locale in _language_buttons:
			var button := _language_buttons[locale] as Button
			button.theme_type_variation = &"SelectedChoiceButton" if locale == settings.ui_locale else &"SecondaryButton"
