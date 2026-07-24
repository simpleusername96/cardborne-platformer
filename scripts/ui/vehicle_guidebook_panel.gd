class_name VehicleGuidebookPanel
extends VBoxContainer

signal close_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const BuildSummaryPanel = preload("res://scripts/ui/vehicle_build_summary_panel.gd")
const GuidebookPreview = preload("res://scripts/ui/vehicle_guidebook_preview.gd")

var _snapshot: Dictionary = {}
var _category_rail: VBoxContainer
var _entry_list: VBoxContainer
var _detail_title: Label
var _detail_body: Label
var _build_summary: VehicleBuildSummaryPanel
var _preview: VehicleGuidebookPreview
var _counterplay: Label
var _close_button: Button
var _active_category: StringName = &"ship"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func open(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
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
	custom_minimum_size = Vector2(860.0, 500.0)
	add_theme_constant_override("separation", 12)
	var header := HBoxContainer.new()
	add_child(header)
	var title := _label("GUIDE_TITLE", 30, Art.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_close_button = _button("SETTINGS_CLOSE")
	_close_button.custom_minimum_size = Vector2(112.0, 44.0)
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(_close_button)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(content)
	_category_rail = VBoxContainer.new()
	_category_rail.custom_minimum_size.x = 136.0
	_category_rail.add_theme_constant_override("separation", 8)
	content.add_child(_category_rail)
	var separator := VSeparator.new()
	content.add_child(separator)
	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size.x = 200.0
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(list_scroll)
	_entry_list = VBoxContainer.new()
	_entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_list.add_theme_constant_override("separation", 6)
	list_scroll.add_child(_entry_list)
	content.add_child(VSeparator.new())
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail)
	_detail_title = _label("GUIDE_CURRENT_SHIP", 25, Art.INK)
	detail.add_child(_detail_title)
	_preview = GuidebookPreview.new()
	detail.add_child(_preview)
	_detail_body = _label("", 16, Art.INK)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_detail_body)
	_counterplay = _label("", 14, Art.INK_MUTED)
	_counterplay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_counterplay)
	_build_summary = BuildSummaryPanel.new()
	_build_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_build_summary)


func _rebuild_categories() -> void:
	_clear(_category_rail)
	var keys := {
		&"ship":"GUIDE_CATEGORY_SHIP", &"mobile":"GUIDE_CATEGORY_MOBILE",
		&"stationary":"GUIDE_CATEGORY_STATIONARY", &"bosses":"GUIDE_CATEGORY_BOSSES",
		&"objects":"GUIDE_CATEGORY_OBJECTS",
	}
	for category in _snapshot.get("category_order", []):
		var button := _button(String(keys.get(StringName(category), "???")))
		button.custom_minimum_size.y = 44.0
		button.pressed.connect(_select_category.bind(StringName(category)))
		_category_rail.add_child(button)


func _select_category(category: StringName) -> void:
	_active_category = category
	_clear(_entry_list)
	var entries: Array = Dictionary(_snapshot.get("categories", {})).get(category, [])
	for entry in entries:
		var title := "???" if bool(entry.get("locked", true)) else tr(String(entry.get("name_key", "")))
		var button := _button(title)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 44.0
		button.pressed.connect(_show_entry.bind(Dictionary(entry)))
		_entry_list.add_child(button)
	if not entries.is_empty():
		_show_entry(Dictionary(entries[0]))


func _show_entry(entry: Dictionary) -> void:
	if bool(entry.get("locked", false)):
		_detail_title.text = "???"
		_detail_body.visible = true
		_detail_body.text = ""
		_counterplay.visible = false
		_preview.show_preview({})
		_build_summary.visible = false
		return
	_detail_title.text = tr(String(entry.get("name_key", "GUIDE_CURRENT_SHIP")))
	if entry.has("ship"):
		_detail_body.visible = false
		_counterplay.visible = false
		_preview.show_preview({})
		_build_summary.visible = true
		_build_summary.set_snapshot(Dictionary(entry["ship"]))
	else:
		_detail_body.visible = true
		_counterplay.visible = true
		_build_summary.visible = false
		_detail_body.text = tr(String(entry.get("description_key", "")))
		_preview.show_preview(Dictionary(entry.get("preview", {})))
		_counterplay.text = "%s  %s\n%s  %s\n%s  %s" % [
			tr("GUIDE_ROW_MOVEMENT"), tr(String(entry.get("movement_key", "GUIDE_ROW_MOVEMENT_DEFAULT"))),
			tr("GUIDE_ROW_ATTACK"), tr(String(entry.get("attack_key", "GUIDE_ROW_ATTACK_DEFAULT"))),
			tr("GUIDE_ROW_COUNTER"), tr(String(entry.get("counter_key", "GUIDE_ROW_COUNTER_DEFAULT"))),
		]


func _button(key_or_text: String) -> Button:
	var button := Button.new()
	button.text = tr(key_or_text) if key_or_text.begins_with("GUIDE_") or key_or_text == "SETTINGS_CLOSE" else key_or_text
	button.theme_type_variation = &"SecondaryButton"
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	return button


func _label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func debug_contract() -> Dictionary:
	return {"categories":5, "command_height":44, "minimum_size":custom_minimum_size, "hidden_copy_removed":true}
