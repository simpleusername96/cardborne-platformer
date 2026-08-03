class_name VehicleGaragePanel
extends VBoxContainer

## Formats the persistent loadout/unlock snapshot and emits navigation intent.
## Run state and persistence remain outside this presentation component.

signal replay_requested
signal settings_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

var _summary_label: Label
var _sections_scroll: ScrollContainer
var _sections: HBoxContainer
var _loadout: VBoxContainer
var _recovery: VBoxContainer
var _primary_value: Label
var _passive_value: Label
var _active_value: Label
var _unlock_value: Label
var _build_value: Label
var _rows: Array[HBoxContainer] = []
var _first_button: Button
var _settings_button: Button
var _data: Dictionary = {}


func _ready() -> void:
	name = "GaragePanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	_build()


func _build() -> void:
	var kicker := Factory.label("GARAGE_KICKER", 16, Art.MUSTARD)
	kicker.theme_type_variation = &"MetricLabel"
	add_child(kicker)
	var title := Factory.label("GARAGE_TITLE", 38, Art.TEXT_PRIMARY)
	title.theme_type_variation = &"TitleLabel"
	add_child(title)
	_summary_label = Factory.label("GARAGE_HULL_RESET", 17, Art.TEXT_PRIMARY)
	_summary_label.theme_type_variation = &"MetricLabel"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	_sections_scroll = ScrollContainer.new()
	_sections_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sections_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sections_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_sections_scroll)
	_sections = HBoxContainer.new()
	_sections.add_theme_constant_override("separation", 28)
	_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sections_scroll.add_child(_sections)

	_loadout = _section("GARAGE_LOADOUT")
	_loadout.size_flags_stretch_ratio = 1.0
	_sections.add_child(_loadout)
	_primary_value = _add_row(_loadout, "GARAGE_PRIMARY", Art.TEXT_PRIMARY)
	_passive_value = _add_row(_loadout, "GARAGE_PASSIVE", Art.SYSTEM)
	_active_value = _add_row(_loadout, "GARAGE_ACTIVE", Art.BOSS_MAGENTA)

	_sections.add_child(VSeparator.new())
	_recovery = _section("GARAGE_MODULE")
	_recovery.size_flags_stretch_ratio = 1.0
	_sections.add_child(_recovery)
	_unlock_value = _add_row(_recovery, "GARAGE_MODULE", Art.MINT_SOFT)
	_build_value = _add_row(_recovery, "GARAGE_RUN_BUILD", Art.TEXT_PRIMARY)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	add_child(footer)
	_first_button = Factory.command_button(
		"GARAGE_LAUNCH",
		Factory.COMMAND_PRIMARY
	)
	_first_button.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_first_button, 22)
	_first_button.pressed.connect(func() -> void: replay_requested.emit())
	footer.add_child(_first_button)
	_settings_button = Factory.command_button(
		"GARAGE_SETTINGS",
		Factory.COMMAND_SECONDARY
	)
	_settings_button.custom_minimum_size = Vector2(190.0, 44.0)
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	footer.add_child(_settings_button)


func open(data: Dictionary) -> void:
	_data = data.duplicate(true)
	refresh_localized_content()
	_first_button.grab_focus()


func refresh_localized_content() -> void:
	_primary_value.text = tr("PRIMARY_PULSE_CANNON")
	var secondary_names: Array[String] = []
	for family in _data.get("secondaries", []):
		secondary_names.append("%s Lv.%d" % [
			tr(String(family["name_key"])),
			int(family["level"]),
		])
	_passive_value.text = (
		tr("SHIP_STATUS_NONE")
		if secondary_names.is_empty()
		else ", ".join(secondary_names)
	)
	_active_value.text = tr("GARAGE_ACTIVE_EMP")
	if _data.is_empty():
		_summary_label.text = tr("GARAGE_HULL_RESET")
		_unlock_value.text = tr("GARAGE_NO_MODULE")
		_unlock_value.add_theme_color_override("font_color", Art.MINT_SOFT)
		_build_value.text = tr("SHIP_STATUS_NONE")
		return
	var clear_count := int(_data.get("clear_count", 0))
	_summary_label.text = "%s · %s" % [
		tr("GARAGE_STAGE_CLEARS") % clear_count,
		tr("GARAGE_HULL_RESET"),
	]
	var unlocks: Array[String] = []
	if bool(_data.get("relay_module_unlocked", false)):
		unlocks.append(tr("GARAGE_RELAY_MODULE"))
	if bool(_data.get("field_module_unlocked", false)):
		unlocks.append(tr("GARAGE_DREDGE_MODULE"))
	_unlock_value.text = (
		tr("GARAGE_NO_MODULE") if unlocks.is_empty() else " · ".join(unlocks)
	)
	_unlock_value.add_theme_color_override(
		"font_color",
		Art.MINT_SOFT if unlocks.is_empty() else Art.MUSTARD
	)
	var build_summary := String(_data.get("build_summary", ""))
	_build_value.text = (
		tr("SHIP_STATUS_NONE") if build_summary.is_empty() else build_summary
	)


func set_compact_mode(compact: bool) -> void:
	add_theme_constant_override("separation", 9 if compact else 14)
	_sections.add_theme_constant_override("separation", 16 if compact else 28)
	for row in _rows:
		(row.get_child(0) as Label).custom_minimum_size.x = (
			104.0 if compact else 136.0
		)
	_first_button.custom_minimum_size = (
		Vector2(260.0, 44.0) if compact else Vector2(300.0, 48.0)
	)
	_settings_button.custom_minimum_size.y = 44.0


func debug_contract() -> Dictionary:
	return {
		"focusables":_focusable_count(),
		"columns":2,
		"rows":_rows.size(),
		"nested_summary_panel":false,
		"primary_action":"GARAGE_LAUNCH",
		"secondary_action":"GARAGE_SETTINGS",
	}


func _section(title_key: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	box.add_child(Factory.section_heading(title_key))
	box.add_child(HSeparator.new())
	return box


func _add_row(
	parent: VBoxContainer,
	label_key: String,
	value_color: Color
) -> Label:
	var row := Factory.text_row(label_key, "", {
		"label_min_width":136.0,
		"label_size":15,
		"value_size":16,
		"value_color":value_color,
	})
	var value := row.get_child(1) as Label
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(row)
	_rows.append(row)
	return value


func _focusable_count() -> int:
	var count := 0
	for node in find_children("*", "Control", true, false):
		if (node as Control).focus_mode != Control.FOCUS_NONE:
			count += 1
	return count
