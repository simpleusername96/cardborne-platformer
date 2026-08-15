class_name VehicleResultPanel
extends VBoxContainer

## Terminal report surface. Gameplay sends a frozen aggregate; this class only presents it.

signal deployment_requested
signal diagnostic_export_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const ReportBody = preload("res://scripts/ui/vehicle_combat_report_body.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

var _kicker: Label
var _title: Label
var _summary: Label
var _report_body: VehicleCombatReportBody
var _deployment: Button
var _diagnostic_export: Button
var _diagnostic_status: Label
var _snapshot: Dictionary = {}
var _force_compact := false


func _ready() -> void:
	name = "ResultPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_build()


func open(snapshot: Dictionary) -> bool:
	var required_cycle_count := CombatStages.STAGE_IDS.size()
	if (
		not bool(snapshot.get("complete_run", false))
		or int(snapshot.get("stage_count", 0)) != required_cycle_count
		or int(snapshot.get("final_stage_number", 0)) != required_cycle_count
		or bool(snapshot.get("has_next_stage", true))
	):
		push_error("VehicleResultPanel.open requires a complete terminal boss-cycle aggregate.")
		return false
	_snapshot = snapshot.duplicate(true)
	refresh_localized_content()
	_deployment.grab_focus()
	return true


func refresh_localized_content() -> void:
	if _snapshot.is_empty():
		return
	_kicker.text = tr("RESULT_STAGE_COMPLETE").replace("%d", str(int(_snapshot.get("stage_count", CombatStages.STAGE_IDS.size())))).replace("%s", tr("RESULT_ALL_STAGES"))
	_title.text = tr("RESULT_TITLE_FINAL")
	var seconds := maxi(0, roundi(float(_snapshot.get("active_run_elapsed_seconds", _snapshot.get("run_time_seconds", 0.0)))))
	var hull := roundi(float(_snapshot.get("hull", 0.0)))
	var max_hull := roundi(float(_snapshot.get("max_hull", 0.0)))
	_summary.text = "%s  ·  %s  ·  %s" % [
		tr("RESULT_TOTAL_PLAY_TIME") % ("%d:%02d" % [floori(seconds / 60.0), seconds % 60]),
		tr("RESULT_HULL_EXACT").replace("%current%", str(hull)).replace("%max%", str(max_hull)),
		tr("RESULT_TOTAL_DEFEATS") % int(_snapshot.get("total_defeats", 0)),
	]
	_report_body.set_snapshot(_snapshot)
	_diagnostic_export.text = tr("DIAGNOSTICS_EXPORT")
	_diagnostic_export.accessibility_name = tr("DIAGNOSTICS_EXPORT")
	_deployment.text = tr("RESULT_DEPLOYMENT")
	_apply_responsive_layout()


func set_compact_mode(compact: bool) -> void:
	_force_compact = compact
	_apply_responsive_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _build() -> void:
	_kicker = Factory.label("", 16, Art.MUSTARD)
	_kicker.theme_type_variation = &"MetricLabel"
	_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_kicker)
	_title = Factory.label("", 38, Art.IVORY_BRIGHT)
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_title)
	_summary = Factory.label("", 17, Art.MINT_SOFT)
	_summary.theme_type_variation = &"MetricLabel"
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.name = "ResultContentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var content_stack := VBoxContainer.new()
	content_stack.add_theme_constant_override("separation", 12)
	content_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_stack)
	_report_body = ReportBody.new()
	content_stack.add_child(_report_body)
	_diagnostic_export = Factory.command_button(tr("DIAGNOSTICS_EXPORT"), Factory.COMMAND_SECONDARY)
	_diagnostic_export.custom_minimum_size = Vector2(260.0, 44.0)
	_diagnostic_export.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_diagnostic_export.pressed.connect(func() -> void: diagnostic_export_requested.emit())
	content_stack.add_child(_diagnostic_export)
	_diagnostic_status = Factory.label("", 14, Art.MINT_SOFT)
	_diagnostic_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_diagnostic_status.visible = false
	content_stack.add_child(_diagnostic_status)
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(actions)
	_deployment = Factory.command_button("", Factory.COMMAND_PRIMARY)
	_deployment.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_deployment, 22)
	_deployment.pressed.connect(func() -> void: deployment_requested.emit())
	actions.add_child(_deployment)


func _apply_responsive_layout() -> void:
	var compact := _force_compact or (is_inside_tree() and get_window().size.x < 1180)
	if is_instance_valid(_report_body):
		_report_body.set_compact_mode(compact)
	if is_instance_valid(_title):
		Factory.apply_font_size(_title, 30 if compact else 40)
	if is_instance_valid(_deployment):
		_deployment.custom_minimum_size.y = 44.0 if compact else 48.0


func kicker_text() -> String:
	return _kicker.text


func debug_contract() -> Dictionary:
	return {
		"focusables": _focusable_button_count(),
		"fixed_actions": 1,
		"primary_size": _deployment.custom_minimum_size,
		"summary_text": _summary.text,
		"report": _report_body.debug_contract(),
		"single_outer_scroll":find_children("*", "ScrollContainer", true, false).size() == 1,
		"primary_action": _deployment.text,
		"primary_variation": _deployment.theme_type_variation,
		"initial_focus_is_deployment": _deployment.has_focus(),
		"diagnostic_export_visible":is_instance_valid(_diagnostic_export) and _diagnostic_export.visible,
	}


func set_diagnostic_status(message_key: String) -> void:
	_diagnostic_status.text = tr(message_key)
	_diagnostic_status.visible = not message_key.is_empty()


func _focusable_button_count() -> int:
	var count := 0
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		if button.focus_mode != Control.FOCUS_NONE and not button.disabled:
			count += 1
	return count
