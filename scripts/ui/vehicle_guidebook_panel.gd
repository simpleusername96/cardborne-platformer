class_name VehicleGuidebookPanel
extends VBoxContainer

## Read-only guide navigation. Discovery truth and locked-entry redaction stay
## in the store/catalog; this surface owns layout, selection, and presentation.

signal close_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const BuildSummaryPanel = preload("res://scripts/ui/vehicle_build_summary_panel.gd")
const GuidebookPreview = preload("res://scripts/ui/vehicle_guidebook_preview.gd")

const CATEGORY_KEYS := {
	&"ship":"GUIDE_CATEGORY_SHIP",
	&"mobile":"GUIDE_CATEGORY_MOBILE",
	&"stationary":"GUIDE_CATEGORY_STATIONARY",
	&"bosses":"GUIDE_CATEGORY_BOSSES",
	&"objects":"GUIDE_CATEGORY_OBJECTS",
}

var _snapshot: Dictionary = {}
var _compact := false
var _content: HBoxContainer
var _category_rail: VBoxContainer
var _category_separator: VSeparator
var _category_selector: OptionButton
var _entry_list: VBoxContainer
var _entry_scroll: ScrollContainer
var _entry_separator: VSeparator
var _detail_scroll: ScrollContainer
var _title_label: Label
var _detail_title: Label
var _detail_body: Label
var _build_summary: VehicleBuildSummaryPanel
var _preview_well: PanelContainer
var _preview: VehicleGuidebookPreview
var _counterplay_rows: VBoxContainer
var _close_button: Button
var _active_category: StringName = &"ship"
var _active_entry_id: StringName = &""
var _category_buttons: Dictionary = {}
var _entry_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func open(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_active_category = &"ship"
	_active_entry_id = &""
	refresh_localized_content()
	visible = true
	_rebuild_categories()
	_select_category(&"ship")
	_focus_first_category()


func set_compact_mode(compact: bool) -> void:
	_compact = compact
	custom_minimum_size = Vector2(840.0, 456.0) if compact else Vector2(1104.0, 580.0)
	add_theme_constant_override("separation", 8 if compact else 14)
	if not is_instance_valid(_content):
		return
	_category_rail.visible = not compact
	_category_separator.visible = not compact
	_category_selector.visible = compact
	_category_rail.custom_minimum_size.x = 198.0
	_entry_scroll.custom_minimum_size.x = 0.0 if compact else 230.0
	_entry_scroll.size_flags_stretch_ratio = 0.34 if compact else 0.0
	_detail_scroll.size_flags_stretch_ratio = 0.66 if compact else 1.0
	_preview_well.custom_minimum_size.y = 150.0 if compact else 210.0
	_title_label.add_theme_font_size_override("font_size", 32 if compact else 40)
	_apply_category_layout()


func _input(event: InputEvent) -> void:
	if (
		is_inside_tree()
		and is_visible_in_tree()
		and event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_ESCAPE
	):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _build() -> void:
	custom_minimum_size = Vector2(1104.0, 580.0)
	add_theme_constant_override("separation", 14)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	_title_label = Factory.label("GUIDE_TITLE", 40, Art.TEXT_PRIMARY)
	_title_label.theme_type_variation = &"DisplayLabel"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_close_button = Factory.command_button("SETTINGS_CLOSE", Factory.COMMAND_SECONDARY)
	_close_button.custom_minimum_size = Vector2(136.0, 48.0)
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(_close_button)

	_category_selector = OptionButton.new()
	_category_selector.name = "GuideCategorySelector"
	_category_selector.custom_minimum_size.y = 44.0
	_category_selector.fit_to_longest_item = false
	_category_selector.focus_mode = Control.FOCUS_ALL
	_category_selector.visible = false
	_category_selector.item_selected.connect(_on_compact_category_selected)
	add_child(_category_selector)

	_content = HBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content)
	_category_rail = VBoxContainer.new()
	_category_rail.custom_minimum_size.x = 198.0
	_category_rail.add_theme_constant_override("separation", 4)
	_content.add_child(_category_rail)
	_category_separator = VSeparator.new()
	_content.add_child(_category_separator)

	_entry_scroll = ScrollContainer.new()
	_entry_scroll.custom_minimum_size.x = 230.0
	_entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_entry_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_entry_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_entry_scroll)
	_entry_list = VBoxContainer.new()
	_entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_list.add_theme_constant_override("separation", 4)
	_entry_scroll.add_child(_entry_list)
	_entry_separator = VSeparator.new()
	_content.add_child(_entry_separator)

	_detail_scroll = ScrollContainer.new()
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 10)
	_detail_scroll.add_child(detail)
	_detail_title = Factory.label("GUIDE_CURRENT_SHIP", 32, Art.TEXT_PRIMARY)
	_detail_title.theme_type_variation = &"TitleLabel"
	detail.add_child(_detail_title)
	_preview_well = Factory.preview_well(Vector2(220.0, 210.0))
	detail.add_child(_preview_well)
	_preview = GuidebookPreview.new()
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_well.add_child(_preview)
	_detail_body = Factory.label("", 17, Art.TEXT_PRIMARY)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_body)
	_counterplay_rows = VBoxContainer.new()
	_counterplay_rows.add_theme_constant_override("separation", 5)
	detail.add_child(_counterplay_rows)
	_build_summary = BuildSummaryPanel.new()
	detail.add_child(_build_summary)
	_apply_category_layout()


func refresh_localized_content() -> void:
	if not is_instance_valid(_title_label):
		return
	_title_label.text = tr("GUIDE_TITLE")
	_close_button.text = tr("SETTINGS_CLOSE")
	if _category_buttons.is_empty():
		return
	var category := _active_category
	var entry_id := _active_entry_id
	_rebuild_categories()
	_select_category(category)
	if not entry_id.is_empty():
		_select_entry_by_id(category, entry_id)


func _rebuild_categories() -> void:
	_clear(_category_rail)
	_category_buttons.clear()
	_category_selector.clear()
	for category_variant in _snapshot.get("category_order", []):
		var category_id := StringName(category_variant)
		var key := String(CATEGORY_KEYS.get(category_id, ""))
		var button := _selectable(key)
		button.toggle_mode = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 48.0
		button.pressed.connect(_select_category.bind(category_id))
		_category_rail.add_child(button)
		_category_buttons[category_id] = button
		_category_selector.add_item(tr(key))
		_category_selector.set_item_metadata(
			_category_selector.item_count - 1,
			category_id
		)
	_update_category_states()


func _on_compact_category_selected(index: int) -> void:
	if index < 0 or index >= _category_selector.item_count:
		return
	_select_category(StringName(_category_selector.get_item_metadata(index)))


func _select_category(category: StringName) -> void:
	if not _category_buttons.has(category):
		return
	_active_category = category
	_active_entry_id = &""
	_apply_category_layout()
	_update_category_states()
	_clear(_entry_list)
	_entry_buttons.clear()
	var entries: Array = Dictionary(_snapshot.get("categories", {})).get(category, [])
	for entry_variant in entries:
		var entry := Dictionary(entry_variant)
		var title := "???" if bool(entry.get("locked", true)) else tr(String(entry.get("name_key", "")))
		var button := _selectable(title)
		button.toggle_mode = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 48.0
		var entry_id := StringName(entry.get("id", &""))
		button.pressed.connect(_select_entry.bind(entry))
		_entry_list.add_child(button)
		_entry_buttons[entry_id] = button
	if not entries.is_empty():
		_select_entry(Dictionary(entries[0]))
	_entry_scroll.scroll_vertical = 0
	_detail_scroll.scroll_vertical = 0


func _select_entry(entry: Dictionary) -> void:
	_active_entry_id = StringName(entry.get("id", &""))
	for entry_id in _entry_buttons:
		var button := _entry_buttons[entry_id] as Button
		var selected := StringName(entry_id) == _active_entry_id
		button.button_pressed = selected
		button.theme_type_variation = &"SelectedSelectableButton" if selected else &"SelectableButton"
	_show_entry(entry)
	_detail_scroll.scroll_vertical = 0


func _select_entry_by_id(category: StringName, entry_id: StringName) -> bool:
	var entries: Array = Dictionary(_snapshot.get("categories", {})).get(category, [])
	for entry_variant in entries:
		var entry := Dictionary(entry_variant)
		if StringName(entry.get("id", &"")) == entry_id:
			_select_entry(entry)
			return true
	return false


func _show_entry(entry: Dictionary) -> void:
	if bool(entry.get("locked", false)):
		_detail_title.text = "???"
		_detail_body.visible = false
		_counterplay_rows.visible = false
		_preview.show_preview({"kind":&"locked"})
		_preview_well.visible = true
		_build_summary.visible = false
		return
	_detail_title.text = tr(String(entry.get("name_key", "GUIDE_CURRENT_SHIP")))
	if entry.has("ship"):
		_detail_body.visible = false
		_counterplay_rows.visible = false
		_preview.show_preview({"kind":&"ship"})
		_preview_well.visible = true
		_build_summary.visible = true
		_build_summary.set_snapshot(Dictionary(entry["ship"]))
	else:
		_detail_body.visible = true
		_counterplay_rows.visible = true
		_build_summary.visible = false
		_detail_body.text = tr(String(entry.get("description_key", "")))
		_preview.show_preview(Dictionary(entry.get("preview", {})))
		_preview_well.visible = _preview.visible
		_set_counterplay_rows(entry)


func _set_counterplay_rows(entry: Dictionary) -> void:
	_clear(_counterplay_rows)
	for definition in [
		["GUIDE_ROW_MOVEMENT", String(entry.get("movement_key", "GUIDE_ROW_MOVEMENT_DEFAULT"))],
		["GUIDE_ROW_ATTACK", String(entry.get("attack_key", "GUIDE_ROW_ATTACK_DEFAULT"))],
		["GUIDE_ROW_COUNTER", String(entry.get("counter_key", "GUIDE_ROW_COUNTER_DEFAULT"))],
	]:
		var row := Factory.text_row(String(definition[0]), String(definition[1]), {
			"label_min_width":104.0,
			"label_size":16,
			"value_size":15,
			"value_color":Art.MINT_SOFT,
		})
		(row.get_child(1) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_counterplay_rows.add_child(row)


func _apply_category_layout() -> void:
	if not is_instance_valid(_entry_scroll):
		return
	var show_entry_column := _active_category != &"ship"
	_entry_scroll.visible = show_entry_column
	_entry_separator.visible = show_entry_column
	if _compact:
		_entry_scroll.size_flags_stretch_ratio = 0.34
		_detail_scroll.size_flags_stretch_ratio = 0.66 if show_entry_column else 1.0


func _update_category_states() -> void:
	for category_id in _category_buttons:
		var button := _category_buttons[category_id] as Button
		var selected := StringName(category_id) == _active_category
		button.button_pressed = selected
		button.theme_type_variation = &"SelectedSelectableButton" if selected else &"SelectableButton"
	for index in _category_selector.item_count:
		if StringName(_category_selector.get_item_metadata(index)) == _active_category:
			_category_selector.select(index)
			break


func _focus_first_category() -> void:
	if _compact:
		_category_selector.grab_focus()
	elif _category_buttons.has(_active_category):
		(_category_buttons[_active_category] as Button).grab_focus()


func _selectable(text: String) -> Button:
	return Factory.selectable_button(text)


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func debug_contract() -> Dictionary:
	var preview_contract := _preview.debug_contract()
	return {
		"categories":_category_buttons.size(),
		"category_order":Array(_snapshot.get("category_order", [])).duplicate(),
		"command_height":_close_button.custom_minimum_size.y,
		"minimum_size":custom_minimum_size,
		"hidden_copy_removed":true,
		"active_category":_active_category,
		"compact":_compact,
		"compact_selector_visible":_category_selector.visible,
		"compact_selector_count":_category_selector.item_count,
		"wide_rail_visible":_category_rail.visible,
		"category_has_focus":(
			_category_selector.has_focus()
			if _compact
			else _category_buttons.has(_active_category)
				and (_category_buttons[_active_category] as Button).has_focus()
		),
		"entry_focusables":_entry_buttons.size(),
		"entry_detail_ratios":[
			_entry_scroll.size_flags_stretch_ratio,
			_detail_scroll.size_flags_stretch_ratio,
		],
		"independent_scroll":_entry_scroll != _detail_scroll
			and _entry_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO
			and _detail_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO,
		"ship_entry_column_hidden":_active_category == &"ship" and not _entry_scroll.visible and not _entry_separator.visible,
		"entry_column_visible":_entry_scroll.visible and _entry_separator.visible,
		"ship_detail_full_width":_active_category == &"ship" and not _entry_scroll.visible,
		"structured_counterplay":is_instance_valid(_counterplay_rows),
		"counterplay_rows":_counterplay_rows.get_child_count(),
		"row_panel_count":0,
		"preview_shell_variation":_preview_well.theme_type_variation,
		"preview":preview_contract,
		"build_summary":_build_summary.debug_contract(),
		"title":_title_label.text,
		"close_text":_close_button.text,
	}


func debug_select_entry(category: StringName, entry_id: StringName) -> bool:
	_select_category(category)
	return _select_entry_by_id(category, entry_id)
