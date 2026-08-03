class_name VehicleResultPanel
extends VBoxContainer

## Stage/final result composition. It formats a supplied summary and emits only
## garage or replay intent.

signal garage_requested
signal replay_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

var _kicker: Label
var _title: Label
var _metric_labels: Array[Label] = []
var _performance_title: Label
var _performance_label: Label
var _reward_title: Label
var _reward_label: Label
var _first_button: Button
var _replay_button: Button
var _summary: Dictionary = {}


func _ready() -> void:
	name = "ResultPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	_build()


func _build() -> void:
	_kicker = Factory.label("", 16, Art.MUSTARD)
	_kicker.theme_type_variation = &"MetricLabel"
	_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_kicker)
	_title = Factory.label("", 38, Art.IVORY_BRIGHT)
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	add_child(HSeparator.new())
	var summary_row := Factory.text_row("", "", {
		"separation":16,
		"label_min_width":0.0,
		"label_size":17,
		"value_size":17,
		"label_color":Art.TEXT_PRIMARY,
		"value_color":Art.TEXT_PRIMARY,
	})
	summary_row.name = "SummaryTextRow"
	summary_row.set_meta("shared_component", "TextRow")
	add_child(summary_row)
	var left_metric := summary_row.get_child(0) as Label
	var right_metric := summary_row.get_child(1) as Label
	var center_metric := Factory.label("", 17, Art.TEXT_PRIMARY)
	center_metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_metric.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_row.add_child(center_metric)
	summary_row.move_child(center_metric, 1)
	left_metric.theme_type_variation = &"MetricLabel"
	left_metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	right_metric.theme_type_variation = &"MetricLabel"
	right_metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	center_metric.theme_type_variation = &"MetricLabel"
	_metric_labels.assign([left_metric, center_metric, right_metric])
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 22)
	detail_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(detail_row)
	var performance_box := VBoxContainer.new()
	performance_box.add_theme_constant_override("separation", 10)
	performance_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(performance_box)
	_performance_title = Factory.label(
		tr("RESULT_PERFORMANCE"),
		20,
		Art.MUSTARD
	)
	_performance_title.theme_type_variation = &"SectionLabel"
	performance_box.add_child(_performance_title)
	_performance_label = Factory.label("", 18, Art.IVORY_BRIGHT)
	_performance_label.theme_type_variation = &"MetricLabel"
	_performance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	performance_box.add_child(_performance_label)
	detail_row.add_child(VSeparator.new())
	var reward_box := VBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 10)
	reward_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(reward_box)
	_reward_title = Factory.label(tr("RESULT_REWARD"), 20, Art.MUSTARD)
	_reward_title.theme_type_variation = &"SectionLabel"
	reward_box.add_child(_reward_title)
	_reward_label = Factory.label("", 18, Art.IVORY_BRIGHT)
	_reward_label.theme_type_variation = &"MetricLabel"
	_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_box.add_child(_reward_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	add_child(actions)
	_first_button = Factory.command_button(
		tr("RESULT_REVIEW_GARAGE"),
		Factory.COMMAND_PRIMARY
	)
	_first_button.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_first_button, 22)
	_first_button.pressed.connect(func() -> void: garage_requested.emit())
	actions.add_child(_first_button)
	_replay_button = Factory.command_button(
		tr("RESULT_REPLAY"),
		Factory.COMMAND_SECONDARY
	)
	_replay_button.custom_minimum_size.x = 210.0
	_replay_button.pressed.connect(func() -> void: replay_requested.emit())
	actions.add_child(_replay_button)


func open(summary: Dictionary) -> bool:
	var stage_title_key := String(summary.get("stage_title_key", ""))
	if stage_title_key.is_empty():
		push_error("VehicleResultPanel.open requires stage_title_key.")
		return false
	_summary = summary.duplicate(true)
	refresh_localized_content()
	_first_button.grab_focus()
	return true


func refresh_localized_content() -> void:
	if _summary.is_empty():
		return
	var stage_title_key := String(_summary["stage_title_key"])
	var has_next := bool(_summary.get("has_next_stage", false))
	_kicker.text = (
		tr("RESULT_STAGE_COMPLETE")
		.replace("%d", str(int(_summary.get("stage_number", 1))))
		.replace("%s", tr(stage_title_key))
	)
	_title.text = tr(
		"RESULT_TITLE_CONTINUE"
		if has_next
		else "RESULT_TITLE_FINAL"
	)
	_performance_title.text = tr("RESULT_PERFORMANCE")
	_reward_title.text = tr("RESULT_REWARD")
	_first_button.text = tr("RESULT_REVIEW_GARAGE")
	_replay_button.text = tr("RESULT_REPLAY")
	_metric_labels[0].text = tr("RESULT_CLEAR_TIME") % String(
		_summary.get("time", "0:00")
	)
	_metric_labels[1].text = tr("RESULT_HULL") % roundi(
		float(_summary.get("health_ratio", 0.0)) * 100.0
	)
	_metric_labels[2].text = tr("RESULT_UPGRADE") % tr(
		String(_summary.get("upgrade", "UPGRADE_NONE"))
	)
	_performance_label.text = "%s\n%s\n%s" % [
		tr("RESULT_PRIMARY_HITS") % int(_summary.get("primary_hits", 0)),
		tr("RESULT_DASH_USES") % int(_summary.get("dash_uses", 0)),
		tr("RESULT_INSTALLATIONS") % int(
			_summary.get("installations", 0)
		),
	]
	_reward_label.text = "%s\n%s" % [
		tr("RESULT_RELAY_MODULE"),
		tr("RESULT_ROUTE_CONTINUES"),
	]


func set_compact_mode(compact: bool) -> void:
	add_theme_constant_override("separation", 9 if compact else 14)
	Factory.apply_font_size(_title, 30 if compact else 40)
	_first_button.custom_minimum_size.y = 44.0 if compact else 48.0


func kicker_text() -> String:
	return _kicker.text


func debug_contract() -> Dictionary:
	var summary_texts: Array[String] = []
	for label in _metric_labels:
		summary_texts.append(label.text)
	return {
		"focusables":find_children("*", "Button", true, false).size(),
		"primary_size":_first_button.custom_minimum_size,
		"summary_text_rows":find_children("SummaryTextRow", "HBoxContainer", true, false).size(),
		"summary_surfaces":find_children("*", "PanelContainer", true, false).size(),
		"summary_values":_metric_labels.size(),
		"performance_visible":not _performance_label.text.is_empty(),
		"reward_visible":not _reward_label.text.is_empty(),
		"initial_focus_is_garage":_first_button.has_focus(),
		"summary_texts":summary_texts,
		"performance_text":_performance_label.text,
		"reward_text":_reward_label.text,
		"primary_action":_first_button.text,
		"secondary_action":_replay_button.text,
		"primary_variation":_first_button.theme_type_variation,
		"secondary_variation":_replay_button.theme_type_variation,
	}
