class_name VehicleGaragePanel
extends VBoxContainer

## Garage review composition. Persistent loadout and unlock data arrive as a
## snapshot; this component only formats it and emits navigation intent.

signal replay_requested
signal settings_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

var _summary_label: Label
var _primary_label: Label
var _passive_label: Label
var _active_label: Label
var _unlock_label: Label
var _build_label: Label
var _first_button: Button
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
	var title := Factory.label("GARAGE_TITLE", 38, Art.IVORY_BRIGHT)
	title.theme_type_variation = &"TitleLabel"
	add_child(title)
	var summary_band := PanelContainer.new()
	summary_band.theme_type_variation = &"SummaryBand"
	add_child(summary_band)
	_summary_label = Factory.label(
		"GARAGE_HULL_RESET",
		17,
		Art.IVORY_BRIGHT
	)
	_summary_label.theme_type_variation = &"MetricLabel"
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_band.add_child(_summary_label)
	var sections := HBoxContainer.new()
	sections.add_theme_constant_override("separation", 28)
	sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(sections)
	var loadout := VBoxContainer.new()
	loadout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout.add_theme_constant_override("separation", 14)
	sections.add_child(loadout)
	var loadout_title := Factory.label(
		"GARAGE_LOADOUT",
		20,
		Art.MUSTARD
	)
	loadout_title.theme_type_variation = &"SectionLabel"
	loadout.add_child(loadout_title)
	loadout.add_child(HSeparator.new())
	_primary_label = Factory.label("", 20, Art.IVORY_BRIGHT)
	_primary_label.theme_type_variation = &"MetricLabel"
	loadout.add_child(_primary_label)
	_passive_label = Factory.label("", 18, Art.SYSTEM)
	_passive_label.theme_type_variation = &"MetricLabel"
	loadout.add_child(_passive_label)
	_active_label = Factory.label("", 18, Art.BOSS_MAGENTA)
	_active_label.theme_type_variation = &"MetricLabel"
	loadout.add_child(_active_label)
	sections.add_child(VSeparator.new())
	var recovery := VBoxContainer.new()
	recovery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recovery.add_theme_constant_override("separation", 12)
	sections.add_child(recovery)
	var module_title := Factory.label("GARAGE_MODULE", 20, Art.MUSTARD)
	module_title.theme_type_variation = &"SectionLabel"
	recovery.add_child(module_title)
	recovery.add_child(HSeparator.new())
	_unlock_label = Factory.label("", 17, Art.MINT_SOFT)
	_unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recovery.add_child(_unlock_label)
	var build_title := Factory.label(
		"GARAGE_RUN_BUILD",
		20,
		Art.MUSTARD
	)
	build_title.theme_type_variation = &"SectionLabel"
	recovery.add_child(build_title)
	recovery.add_child(HSeparator.new())
	_build_label = Factory.label("", 17, Art.IVORY_BRIGHT)
	_build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recovery.add_child(_build_label)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	add_child(footer)
	_first_button = Factory.command_button(
		"GARAGE_LAUNCH",
		&"PrimaryButton"
	)
	_first_button.custom_minimum_size = Vector2(300.0, 48.0)
	_first_button.add_theme_font_size_override("font_size", 22)
	_first_button.pressed.connect(func() -> void: replay_requested.emit())
	footer.add_child(_first_button)
	var settings := Factory.command_button(
		"GARAGE_SETTINGS",
		&"SecondaryButton"
	)
	settings.custom_minimum_size.x = 190.0
	settings.pressed.connect(func() -> void: settings_requested.emit())
	footer.add_child(settings)


func open(data: Dictionary) -> void:
	_data = data.duplicate(true)
	refresh_localized_content()
	_first_button.grab_focus()


func refresh_localized_content() -> void:
	_primary_label.text = "%s  ·  %s" % [
		tr("GARAGE_PRIMARY"),
		tr("PRIMARY_PULSE_CANNON"),
	]
	var secondary_names: Array[String] = []
	for family in _data.get("secondaries", []):
		secondary_names.append(
			"%s Lv.%d" % [
				tr(String(family["name_key"])),
				int(family["level"]),
			]
		)
	_passive_label.text = "%s  ·  %s" % [
		tr("GARAGE_PASSIVE"),
		tr("SHIP_STATUS_NONE")
			if secondary_names.is_empty()
			else ", ".join(secondary_names),
	]
	_active_label.text = "%s  ·  %s" % [
		tr("GARAGE_ACTIVE"),
		tr("GARAGE_ACTIVE_EMP"),
	]
	if _data.is_empty():
		_summary_label.text = tr("GARAGE_HULL_RESET")
		_unlock_label.text = "%s  ·  %s" % [
			tr("GARAGE_MODULE"),
			tr("GARAGE_NO_MODULE"),
		]
		_build_label.text = tr("SHIP_STATUS_NONE")
		return
	var clear_count := int(_data.get("clear_count", 0))
	_summary_label.text = "%s  ·  %s" % [
		tr("GARAGE_STAGE_CLEARS") % clear_count,
		tr("GARAGE_HULL_RESET"),
	]
	var unlocks: Array[String] = []
	if bool(_data.get("relay_module_unlocked", false)):
		unlocks.append(tr("GARAGE_RELAY_MODULE"))
	if bool(_data.get("field_module_unlocked", false)):
		unlocks.append(tr("GARAGE_DREDGE_MODULE"))
	if unlocks.is_empty():
		_unlock_label.text = "%s  ·  %s" % [
			tr("GARAGE_MODULE"),
			tr("GARAGE_NO_MODULE"),
		]
		_unlock_label.add_theme_color_override(
			"font_color",
			Art.MINT_SOFT
		)
	else:
		_unlock_label.text = "%s  ·  %s" % [
			tr("GARAGE_MODULE"),
			"  •  ".join(unlocks),
		]
		_unlock_label.add_theme_color_override(
			"font_color",
			Art.MUSTARD
		)
	var build_summary := String(_data.get("build_summary", ""))
	_build_label.text = (
		tr("SHIP_STATUS_NONE")
		if build_summary.is_empty()
		else build_summary
	)


func set_compact_mode(compact: bool) -> void:
	add_theme_constant_override("separation", 9 if compact else 14)
	_first_button.custom_minimum_size.y = 44.0 if compact else 48.0


func debug_contract() -> Dictionary:
	return {
		"focusables":_focusable_count(),
	}


func _focusable_count() -> int:
	var count := 0
	for node in find_children("*", "Control", true, false):
		if (node as Control).focus_mode != Control.FOCUS_NONE:
			count += 1
	return count
