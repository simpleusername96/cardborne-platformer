class_name VehicleResultPanel
extends VBoxContainer

## Terminal report surface. Gameplay sends a frozen aggregate; this class only presents it.

signal deployment_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const ReportBody = preload("res://scripts/ui/vehicle_combat_report_body.gd")
const BuildRail = preload("res://scripts/ui/vehicle_upgrade_build_rail.gd")

var _kicker: Label
var _title: Label
var _summary: Label
var _report_body
var _build_rail
var _loadout: Label
var _counters: Label
var _build_heading: Label
var _reward: Label
var _deployment: Button
var _snapshot: Dictionary = {}
var _force_compact := false


func _ready() -> void:
	name = "ResultPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_build()


func open(snapshot: Dictionary) -> bool:
	if (
		not bool(snapshot.get("complete_run", false))
		or int(snapshot.get("stage_count", 0)) != 5
		or int(snapshot.get("final_stage_number", 0)) != 5
		or bool(snapshot.get("has_next_stage", true))
	):
		push_error("VehicleResultPanel.open requires a complete terminal five-stage aggregate.")
		return false
	_snapshot = snapshot.duplicate(true)
	refresh_localized_content()
	_deployment.grab_focus()
	return true


func refresh_localized_content() -> void:
	if _snapshot.is_empty(): return
	_kicker.text = tr("RESULT_STAGE_COMPLETE").replace("%d", str(int(_snapshot.get("stage_count", 5)))).replace("%s", tr("RESULT_ALL_STAGES"))
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
	_build_rail.set_snapshot(Dictionary(_snapshot.get("build_snapshot", {})))
	_build_rail.refresh_localized_content()
	_loadout.text = _loadout_text()
	_counters.text = "%s  ·  %s  ·  %s" % [
		tr("RESULT_PRIMARY_HITS") % int(_snapshot.get("primary_hits", 0)),
		tr("RESULT_DASH_USES") % int(_snapshot.get("dash_uses", 0)),
		tr("RESULT_INSTALLATIONS") % int(_snapshot.get("installations", 0)),
	]
	_build_heading.text = tr("RESULT_BUILD_LOADOUT")
	_reward.text = "%s\n%s" % [tr(String(_snapshot.get("permanent_reward_key", "RESULT_RELAY_MODULE"))), tr(String(_snapshot.get("permanent_reward_detail_key", "RESULT_ROUTE_CONTINUES")))]
	_deployment.text = tr("RESULT_DEPLOYMENT")
	_apply_responsive_layout()


func set_compact_mode(compact: bool) -> void:
	_force_compact = compact
	_apply_responsive_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: _apply_responsive_layout()


func _build() -> void:
	_kicker = Factory.label("", 16, Art.MUSTARD)
	_kicker.theme_type_variation = &"MetricLabel"
	_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_kicker)
	_title = Factory.label("", 38, Art.IVORY_BRIGHT)
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_summary = Factory.label("", 17, Art.MINT_SOFT)
	_summary.theme_type_variation = &"MetricLabel"
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.name = "ResultContentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_report_body = ReportBody.new()
	_report_body.custom_minimum_size.y = 170.0
	content.add_child(_report_body)
	_build_heading = Factory.section_heading("")
	content.add_child(_build_heading)
	_build_rail = BuildRail.new()
	_build_rail.custom_minimum_size.y = 96.0
	content.add_child(_build_rail)
	_loadout = Factory.label("", 16, Art.TEXT_PRIMARY)
	_loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_loadout)
	_counters = Factory.label("", 16, Art.TEXT_PRIMARY)
	_counters.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_counters)
	_reward = Factory.label("", 16, Art.MINT_SOFT)
	_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_reward)
	var actions := CenterContainer.new()
	add_child(actions)
	_deployment = Factory.command_button("", Factory.COMMAND_PRIMARY)
	_deployment.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_deployment, 22)
	_deployment.pressed.connect(func() -> void: deployment_requested.emit())
	actions.add_child(_deployment)


func _loadout_text() -> String:
	var loadout := Dictionary(_snapshot.get("loadout", {}))
	var labels: Array[String] = []
	for key in ["primary_title_key", "active_title_key"]:
		var title_key := String(loadout.get(key, ""))
		if not title_key.is_empty(): labels.append(tr(title_key))
	for title_key_variant in Array(loadout.get("secondary_title_keys", [])):
		var title_key := String(title_key_variant)
		if not title_key.is_empty(): labels.append(tr(title_key))
	if labels.is_empty(): return tr("RESULT_LOADOUT_NONE")
	return tr("RESULT_LOADOUT") % " · ".join(labels)


func _apply_responsive_layout() -> void:
	var compact := _force_compact or (is_inside_tree() and get_window().size.x < 1180)
	if is_instance_valid(_report_body):
		_report_body.custom_minimum_size.y = 150.0 if compact else 170.0
		_report_body.set_compact_mode(compact)
	if is_instance_valid(_build_rail): _build_rail.set_compact_mode(compact)
	if is_instance_valid(_title): Factory.apply_font_size(_title, 30 if compact else 40)
	if is_instance_valid(_deployment): _deployment.custom_minimum_size.y = 44.0 if compact else 48.0


func kicker_text() -> String:
	return _kicker.text


func debug_contract() -> Dictionary:
	return {
		"focusables": _focusable_button_count(),
		"fixed_actions": 1,
		"primary_size": _deployment.custom_minimum_size,
		"summary_text": _summary.text,
		"wide_columns": _report_body.debug_contract()["wide_columns"],
		"compact_tabs": _report_body.debug_contract()["compact_tabs"],
		"scroll_views": _report_body.debug_contract()["scroll_views"],
		"build_visible": _build_rail.visible,
		"loadout_text": _loadout.text,
		"counter_text": _counters.text,
		"reward_text": _reward.text,
		"primary_action": _deployment.text,
		"primary_variation": _deployment.theme_type_variation,
		"initial_focus_is_deployment": _deployment.has_focus(),
	}


func _focusable_button_count() -> int:
	var count := 0
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		if button.focus_mode != Control.FOCUS_NONE and not button.disabled:
			count += 1
	return count
