class_name VehicleSettingsPanel
extends VBoxContainer

## Shared, scroll-safe settings surface. It owns presentation/input capture;
## SettingsStore remains persistence truth and GameRoot applies InputMap state.

signal close_requested
signal guide_requested
signal diagnostic_export_requested

const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const BuildSummaryPanel = preload("res://scripts/ui/vehicle_build_summary_panel.gd")

const CATEGORY_IDS: Array[StringName] = [
	&"ship", &"audio", &"controls", &"gameplay", &"language",
]
const CATEGORY_KEYS := {
	&"ship":"SHIP_STATUS_TAB",
	&"audio":"SETTINGS_AUDIO_TAB",
	&"controls":"SETTINGS_CONTROLS_TAB",
	&"gameplay":"SETTINGS_GAMEPLAY_TAB",
	&"language":"SETTINGS_LANGUAGE_TAB",
}
const ACTION_TITLE_KEYS := {
	&"primary_fire":"ACTION_PRIMARY",
	&"dash":"ACTION_DASH",
	&"active_skill":"ACTION_ACTIVE_WEAPON",
	&"move_left":"SETTINGS_MOVEMENT_RESERVED",
	&"move_right":"SETTINGS_MOVEMENT_RESERVED",
	&"move_up":"SETTINGS_MOVEMENT_RESERVED",
	&"move_down":"SETTINGS_MOVEMENT_RESERVED",
	&"pause":"SETTINGS_PAUSE_RESERVED",
}

var _title_label: Label
var _guide_button: Button
var _close_button: Button
var _category_rail: VBoxContainer
var _category_buttons: Dictionary = {}
var _pages: Dictionary = {}
var _content_scroll: ScrollContainer
var _active_category := &"ship"
var _binding_buttons: Dictionary = {}
var _master_slider: HSlider
var _sfx_slider: HSlider
var _reduced_motion_toggle: CheckButton
var _diagnostic_export_button: Button
var _language_buttons: Dictionary = {}
var _status_label: Label
var _build_summary: VehicleBuildSummaryPanel
var _build_snapshot: Dictionary = {}
var _capturing_action: StringName = &""
var _text_rows: Array[HBoxContainer] = []


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
	_select_category(&"ship")
	_build_summary.set_snapshot(_build_snapshot)
	_close_button.grab_focus()


func set_compact_mode(compact: bool) -> void:
	custom_minimum_size = Vector2(820.0, 456.0) if compact else Vector2(856.0, 500.0)
	_category_rail.custom_minimum_size.x = 150.0 if compact else 176.0
	add_theme_constant_override("separation", 8 if compact else 12)
	for row in _text_rows:
		(row.get_child(0) as Label).custom_minimum_size.x = 136.0 if compact else 168.0


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
	if settings == null or not is_instance_valid(_content_scroll):
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
		"tabs":CATEGORY_IDS.size(),
		"category_order":CATEGORY_IDS.duplicate(),
		"active_category":_active_category,
		"category_selectables":_category_buttons.size(),
		"single_scroll_region":find_children("*", "ScrollContainer", true, false).size() == 1,
		"text_rows":_text_rows.size(),
		"row_panel_count":0,
		"binding_controls":_binding_buttons.size(),
		"minimum_size":custom_minimum_size,
		"focusables":find_children("*", "Control", true, false).filter(
			func(control: Control) -> bool: return control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree()
		).size(),
		"capturing":is_capturing_binding(),
		"reduced_motion_control":is_instance_valid(_reduced_motion_toggle) and _reduced_motion_toggle.custom_minimum_size.y >= 44.0,
		"diagnostic_export_visible":is_instance_valid(_diagnostic_export_button) and _diagnostic_export_button.visible,
		"difficulty_controls":0,
		"difficulty_copy_visible":false,
		"ship_status":_build_summary.debug_contract() if is_instance_valid(_build_summary) else {},
	}


func debug_show_gameplay_page() -> void:
	_select_category(&"gameplay")


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
	_title_label = Factory.label("SETTINGS_TITLE", 40, Art.TEXT_PRIMARY)
	_title_label.theme_type_variation = &"TitleLabel"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_guide_button = Factory.command_button("?", Factory.COMMAND_SECONDARY)
	_guide_button.tooltip_text = tr("GUIDE_TITLE")
	_guide_button.accessibility_name = tr("GUIDE_TITLE")
	_guide_button.custom_minimum_size = Vector2(44.0, 44.0)
	_guide_button.pressed.connect(func() -> void: guide_requested.emit())
	header.add_child(_guide_button)
	_close_button = Factory.command_button("SETTINGS_CLOSE", Factory.COMMAND_SECONDARY)
	_close_button.custom_minimum_size.x = 112.0
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(_close_button)

	_status_label = Factory.label("", 14, Art.MINT_SOFT)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.visible = false
	add_child(_status_label)

	var workspace := HBoxContainer.new()
	workspace.add_theme_constant_override("separation", 16)
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(workspace)
	_category_rail = VBoxContainer.new()
	_category_rail.custom_minimum_size.x = 176.0
	_category_rail.add_theme_constant_override("separation", 4)
	workspace.add_child(_category_rail)
	for category_id in CATEGORY_IDS:
		var button := _selectable(String(CATEGORY_KEYS[category_id]))
		button.toggle_mode = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 48.0
		button.pressed.connect(_select_category.bind(category_id))
		_category_rail.add_child(button)
		_category_buttons[category_id] = button
	workspace.add_child(VSeparator.new())
	_content_scroll = ScrollContainer.new()
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(_content_scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(margin)
	var page_root := VBoxContainer.new()
	page_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(page_root)
	for category_id in CATEGORY_IDS:
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 12)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.visible = category_id == &"ship"
		page_root.add_child(page)
		_pages[category_id] = page
	_build_ship_status_page()
	_build_audio_page()
	_build_controls_page()
	_build_gameplay_page()
	_build_language_page()
	_select_category(&"ship")


func _build_ship_status_page() -> void:
	var page := _page(&"ship")
	page.add_child(Factory.section_heading("SHIP_STATUS_HEADING"))
	_build_summary = BuildSummaryPanel.new()
	page.add_child(_build_summary)


func _build_audio_page() -> void:
	var page := _page(&"audio")
	page.add_child(Factory.section_heading("SETTINGS_AUDIO_HEADING"))
	_master_slider = _slider()
	_master_slider.value_changed.connect(_on_master_volume_changed)
	page.add_child(_control_row("PAUSE_MASTER_VOLUME", _master_slider))
	_sfx_slider = _slider()
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	page.add_child(_control_row("PAUSE_EFFECTS_VOLUME", _sfx_slider))


func _build_controls_page() -> void:
	var page := _page(&"controls")
	page.add_child(Factory.section_heading("SETTINGS_CONTROLS_HEADING"))
	var help := Factory.label("SETTINGS_CONTROLS_HELP", 14, Art.MINT_SOFT)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(help)
	for action in InputProfile.REMAPPABLE_ACTIONS:
		var button := Factory.command_button("INPUT_UNBOUND", Factory.COMMAND_SECONDARY)
		button.custom_minimum_size.x = 220.0
		button.pressed.connect(_begin_capture.bind(action))
		_binding_buttons[action] = button
		page.add_child(_control_row(String(ACTION_TITLE_KEYS[action]), button))
	var reset := Factory.command_button("SETTINGS_RESET_BINDINGS", Factory.COMMAND_SECONDARY)
	reset.custom_minimum_size.x = 260.0
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(_reset_bindings)
	page.add_child(reset)


func _build_gameplay_page() -> void:
	var page := _page(&"gameplay")
	page.add_child(Factory.section_heading("SETTINGS_GAMEPLAY_HEADING"))
	_reduced_motion_toggle = CheckButton.new()
	_reduced_motion_toggle.text = ""
	_reduced_motion_toggle.accessibility_name = tr("SETTINGS_REDUCED_MOTION")
	_reduced_motion_toggle.custom_minimum_size = Vector2(220.0, 44.0)
	_reduced_motion_toggle.focus_mode = Control.FOCUS_ALL
	_reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	page.add_child(_control_row("SETTINGS_REDUCED_MOTION", _reduced_motion_toggle))
	_diagnostic_export_button = Factory.command_button("DIAGNOSTICS_EXPORT", Factory.COMMAND_SECONDARY)
	_diagnostic_export_button.custom_minimum_size = Vector2(260.0, 44.0)
	_diagnostic_export_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_diagnostic_export_button.pressed.connect(func() -> void: diagnostic_export_requested.emit())
	page.add_child(_diagnostic_export_button)


func _build_language_page() -> void:
	var page := _page(&"language")
	page.add_child(Factory.section_heading("SETTINGS_LANGUAGE_HEADING"))
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	for locale in ["ko", "en"]:
		var button := _selectable("LANGUAGE_KO" if locale == "ko" else "LANGUAGE_EN")
		button.custom_minimum_size = Vector2(120.0, 44.0)
		button.pressed.connect(_on_locale_selected.bind(locale))
		choices.add_child(button)
		_language_buttons[locale] = button
	page.add_child(_control_row("LANGUAGE_LABEL", choices))


func _page(category: StringName) -> VBoxContainer:
	return _pages[category] as VBoxContainer


func _control_row(label_key: String, control: Control) -> HBoxContainer:
	var row := Factory.text_row(label_key, "", {
		"label_min_width":168.0,
		"label_size":16,
		"value_size":16,
	})
	var placeholder := row.get_child(1)
	row.remove_child(placeholder)
	placeholder.queue_free()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	_text_rows.append(row)
	return row


func _slider() -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(360.0, 44.0)
	slider.focus_mode = Control.FOCUS_ALL
	return slider


func _selectable(text: String) -> Button:
	return Factory.selectable_button(text)


func _select_category(category: StringName) -> void:
	if category not in CATEGORY_IDS:
		return
	_active_category = category
	for category_id in CATEGORY_IDS:
		(_pages[category_id] as Control).visible = category_id == category
		var button := _category_buttons[category_id] as Button
		button.button_pressed = category_id == category
		button.theme_type_variation = (
			&"SelectedSelectableButton" if category_id == category else &"SelectableButton"
		)
	_content_scroll.scroll_vertical = 0


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
	if not is_instance_valid(_title_label):
		return
	_title_label.text = tr("SETTINGS_TITLE")
	_guide_button.tooltip_text = tr("GUIDE_TITLE")
	_guide_button.accessibility_name = tr("GUIDE_TITLE")
	_close_button.text = tr("SETTINGS_CLOSE")
	for category_id in CATEGORY_IDS:
		(_category_buttons[category_id] as Button).text = tr(String(CATEGORY_KEYS[category_id]))
	_reduced_motion_toggle.accessibility_name = tr("SETTINGS_REDUCED_MOTION")
	_diagnostic_export_button.text = tr("DIAGNOSTICS_EXPORT")
	_diagnostic_export_button.accessibility_name = tr("DIAGNOSTICS_EXPORT")
	var settings := _settings_store()
	if settings != null:
		for locale in _language_buttons:
			var button := _language_buttons[locale] as Button
			var selected: bool = String(locale) == String(settings.ui_locale)
			button.button_pressed = selected
			button.theme_type_variation = &"SelectedSelectableButton" if selected else &"SelectableButton"


func set_diagnostic_status(message_key: String) -> void:
	_status_label.text = tr(message_key)
	_status_label.visible = not message_key.is_empty()
