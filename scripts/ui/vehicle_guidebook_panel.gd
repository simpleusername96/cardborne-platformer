class_name VehicleGuidebookPanel
extends VBoxContainer

signal close_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const BuildSummaryPanel = preload("res://scripts/ui/vehicle_build_summary_panel.gd")
const GuidebookPreview = preload("res://scripts/ui/vehicle_guidebook_preview.gd")


class CounterplayGlyph:
	extends Control

	var kind: StringName = &"movement"


	func _ready() -> void:
		custom_minimum_size = Vector2(44.0, 44.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE


	func configure(value: StringName) -> void:
		kind = value
		queue_redraw()


	func _draw() -> void:
		var center := size * 0.5
		match kind:
			&"attack":
				draw_circle(center + Vector2(-8.0, 3.0), 7.0, Art.BOSS_MAGENTA)
				draw_circle(center + Vector2(4.0, -7.0), 6.0, Art.BOSS_MAGENTA)
				draw_circle(center + Vector2(8.0, 8.0), 6.0, Art.BOSS_MAGENTA)
			&"counter":
				draw_colored_polygon(PackedVector2Array([
					center + Vector2(0.0, -16.0),
					center + Vector2(13.0, -10.0),
					center + Vector2(11.0, 7.0),
					center + Vector2(0.0, 17.0),
					center + Vector2(-11.0, 7.0),
					center + Vector2(-13.0, -10.0),
				]), Art.MINT)
				draw_line(
					center + Vector2(0.0, -13.0),
					center + Vector2(0.0, 13.0),
					Art.IVORY_BRIGHT,
					3.0
				)
			_:
				draw_arc(center, 13.0, -PI * 0.15, PI * 1.45, 28, Art.CERAMIC_GREEN_LIGHT, 5.0, true)
				draw_colored_polygon(PackedVector2Array([
					center + Vector2(-15.0, -3.0),
					center + Vector2(-6.0, -10.0),
					center + Vector2(-5.0, 2.0),
				]), Art.CERAMIC_GREEN_LIGHT)

var _snapshot: Dictionary = {}
var _category_rail: VBoxContainer
var _entry_list: VBoxContainer
var _entry_scroll: ScrollContainer
var _entry_separator: VSeparator
var _title_label: Label
var _detail_title: Label
var _detail_body: Label
var _build_summary: VehicleBuildSummaryPanel
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
	refresh_localized_content()
	visible = true
	_rebuild_categories()
	_select_category(&"ship")
	_close_button.grab_focus()


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
	add_child(header)
	_title_label = _label("GUIDE_TITLE", 40, Art.INK)
	_title_label.theme_type_variation = &"DisplayLabel"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_close_button = _button("SETTINGS_CLOSE")
	_close_button.custom_minimum_size = Vector2(136.0, 48.0)
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(_close_button)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(content)
	_category_rail = VBoxContainer.new()
	_category_rail.custom_minimum_size.x = 198.0
	_category_rail.add_theme_constant_override("separation", 8)
	content.add_child(_category_rail)
	var separator := VSeparator.new()
	content.add_child(separator)
	_entry_scroll = ScrollContainer.new()
	_entry_scroll.custom_minimum_size.x = 230.0
	_entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_entry_scroll)
	_entry_list = VBoxContainer.new()
	_entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_list.add_theme_constant_override("separation", 6)
	_entry_scroll.add_child(_entry_list)
	_entry_separator = VSeparator.new()
	content.add_child(_entry_separator)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail)
	_detail_title = _label("GUIDE_CURRENT_SHIP", 32, Art.INK)
	_detail_title.theme_type_variation = &"TitleLabel"
	detail.add_child(_detail_title)
	_preview = GuidebookPreview.new()
	_preview.custom_minimum_size.y = 210.0
	detail.add_child(_preview)
	_detail_body = _label("", 17, Art.INK)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_detail_body)
	_counterplay_rows = VBoxContainer.new()
	_counterplay_rows.add_theme_constant_override("separation", 6)
	detail.add_child(_counterplay_rows)
	_build_summary = BuildSummaryPanel.new()
	_build_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_build_summary)
	_apply_category_layout()


func refresh_localized_content() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = tr("GUIDE_TITLE")
	if is_instance_valid(_close_button):
		_close_button.text = tr("SETTINGS_CLOSE")


func _rebuild_categories() -> void:
	_clear(_category_rail)
	_category_buttons.clear()
	var keys := {
		&"ship":"GUIDE_CATEGORY_SHIP", &"mobile":"GUIDE_CATEGORY_MOBILE",
		&"stationary":"GUIDE_CATEGORY_STATIONARY", &"bosses":"GUIDE_CATEGORY_BOSSES",
		&"objects":"GUIDE_CATEGORY_OBJECTS",
	}
	for category in _snapshot.get("category_order", []):
		var category_id := StringName(category)
		var button := _button(String(keys.get(category_id, "???")))
		button.custom_minimum_size.y = 56.0
		button.pressed.connect(_select_category.bind(category_id))
		_category_rail.add_child(button)
		_category_buttons[category_id] = button
	_update_category_states()


func _select_category(category: StringName) -> void:
	_active_category = category
	_active_entry_id = &""
	_apply_category_layout()
	_update_category_states()
	_clear(_entry_list)
	_entry_buttons.clear()
	var entries: Array = Dictionary(_snapshot.get("categories", {})).get(category, [])
	for entry in entries:
		var title := "???" if bool(entry.get("locked", true)) else tr(String(entry.get("name_key", "")))
		var button := _button(title)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 56.0
		var entry_data := Dictionary(entry)
		var entry_id := StringName(entry_data.get("id", &""))
		button.pressed.connect(_select_entry.bind(entry_data))
		_entry_list.add_child(button)
		_entry_buttons[entry_id] = button
	if not entries.is_empty():
		_select_entry(Dictionary(entries[0]))


func _select_entry(entry: Dictionary) -> void:
	_active_entry_id = StringName(entry.get("id", &""))
	for entry_id in _entry_buttons:
		var button := _entry_buttons[entry_id] as Button
		button.theme_type_variation = (
			&"SelectedChoiceButton"
			if StringName(entry_id) == _active_entry_id
			else &"SecondaryButton"
		)
	_show_entry(entry)


func _show_entry(entry: Dictionary) -> void:
	if bool(entry.get("locked", false)):
		_detail_title.text = "???"
		_detail_body.visible = true
		_detail_body.text = ""
		_counterplay_rows.visible = false
		_preview.show_preview({"kind":&"locked"})
		_build_summary.visible = false
		return
	_detail_title.text = tr(String(entry.get("name_key", "GUIDE_CURRENT_SHIP")))
	if entry.has("ship"):
		_detail_body.visible = false
		_counterplay_rows.visible = false
		_preview.show_preview({})
		_build_summary.visible = true
		_build_summary.set_snapshot(Dictionary(entry["ship"]))
	else:
		_detail_body.visible = true
		_counterplay_rows.visible = true
		_build_summary.visible = false
		_detail_body.text = tr(String(entry.get("description_key", "")))
		_preview.show_preview(Dictionary(entry.get("preview", {})))
		_set_counterplay_rows(entry)


func _set_counterplay_rows(entry: Dictionary) -> void:
	_clear(_counterplay_rows)
	for definition in [
		[&"movement", "GUIDE_ROW_MOVEMENT", String(entry.get("movement_key", "GUIDE_ROW_MOVEMENT_DEFAULT"))],
		[&"attack", "GUIDE_ROW_ATTACK", String(entry.get("attack_key", "GUIDE_ROW_ATTACK_DEFAULT"))],
		[&"counter", "GUIDE_ROW_COUNTER", String(entry.get("counter_key", "GUIDE_ROW_COUNTER_DEFAULT"))],
	]:
		var plate := PanelContainer.new()
		plate.theme_type_variation = &"SummaryBand"
		plate.custom_minimum_size.y = 56.0
		_counterplay_rows.add_child(plate)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		plate.add_child(row)
		var glyph := CounterplayGlyph.new()
		glyph.configure(StringName(definition[0]))
		row.add_child(glyph)
		var heading := _label(String(definition[1]), 18, Art.INK)
		heading.theme_type_variation = &"SectionLabel"
		heading.custom_minimum_size.x = 86.0
		heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(heading)
		var body := _label(String(definition[2]), 15, Art.INK_MUTED)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(body)


func _apply_category_layout() -> void:
	var show_entry_column := _active_category != &"ship"
	if is_instance_valid(_entry_scroll):
		_entry_scroll.visible = show_entry_column
	if is_instance_valid(_entry_separator):
		_entry_separator.visible = show_entry_column


func _update_category_states() -> void:
	for category_id in _category_buttons:
		var button := _category_buttons[category_id] as Button
		button.theme_type_variation = (
			&"SelectedRailButton"
			if StringName(category_id) == _active_category
			else &"SecondaryButton"
		)


func _button(key_or_text: String) -> Button:
	var button := Button.new()
	button.text = tr(key_or_text) if key_or_text.begins_with("GUIDE_") or key_or_text == "SETTINGS_CLOSE" else key_or_text
	button.theme_type_variation = &"SecondaryButton"
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 19)
	return button


func _label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func debug_contract() -> Dictionary:
	return {
		"categories":5,
		"command_height":44,
		"minimum_size":custom_minimum_size,
		"hidden_copy_removed":true,
		"active_category":_active_category,
		"ship_entry_column_hidden":(
			_active_category == &"ship"
			and not _entry_scroll.visible
			and not _entry_separator.visible
		),
		"entry_column_visible":_entry_scroll.visible and _entry_separator.visible,
		"structured_counterplay":is_instance_valid(_counterplay_rows),
		"title":_title_label.text,
		"close_text":_close_button.text,
	}


func debug_select_entry(category: StringName, entry_id: StringName) -> bool:
	_select_category(category)
	var entries: Array = Dictionary(_snapshot.get("categories", {})).get(
		category, []
	)
	for entry in entries:
		if StringName(entry.get("id", &"")) == entry_id:
			_select_entry(Dictionary(entry))
			return true
	return false
