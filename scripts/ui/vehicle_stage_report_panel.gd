class_name VehicleStageReportPanel
extends VBoxContainer

signal continued

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const DamageSources = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const ReportBody = preload("res://scripts/ui/vehicle_combat_report_body.gd")

const INPUT_GUARD_SECONDS := 0.35

var _snapshot: Dictionary = {}
var _title: Label
var _kicker: Label
var _summary: Label
var _body_scroll: ScrollContainer
var _body_stack: VBoxContainer
var _report_body
var _incoming_box: VBoxContainer
var _continue_button: Button
var _guard := 0.0
var _force_compact := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_build()


func open(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_guard = INPUT_GUARD_SECONDS
	_continue_button.disabled = true
	_refresh_text()
	_report_body.set_snapshot(_snapshot)
	_rebuild_failure_recap()
	_apply_responsive_layout()
	visible = true
	_report_body.focus_target().grab_focus()


func refresh_localized_content() -> void:
	if _snapshot.is_empty():
		return
	var retained_guard := _guard
	open(_snapshot)
	_guard = retained_guard


func _process(delta: float) -> void:
	if _guard <= 0.0:
		return
	_guard = maxf(0.0, _guard - delta)
	if _guard <= 0.0:
		_continue_button.disabled = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_report_body):
		_apply_responsive_layout()


func set_compact_mode(compact: bool) -> void:
	_force_compact = compact
	_apply_responsive_layout()


func set_accessibility_mode(enabled: bool) -> void:
	_body_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
		if enabled
		else ScrollContainer.SCROLL_MODE_AUTO
	)
	_report_body.set_accessibility_mode(enabled)


func _build() -> void:
	_kicker = _label("", 16, Art.MUSTARD)
	_kicker.theme_type_variation = &"MetricLabel"
	add_child(_kicker)
	_title = _label("", 32, Art.IVORY_BRIGHT)
	_title.theme_type_variation = &"TitleLabel"
	add_child(_title)
	_summary = _label("", 17, Art.MINT_SOFT)
	add_child(_summary)
	add_child(HSeparator.new())
	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_body_scroll)
	_body_stack = VBoxContainer.new()
	_body_stack.add_theme_constant_override("separation", 10)
	_body_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.add_child(_body_stack)
	_report_body = ReportBody.new()
	_report_body.custom_minimum_size.y = 220.0
	_body_stack.add_child(_report_body)
	_incoming_box = VBoxContainer.new()
	_incoming_box.add_theme_constant_override("separation", 5)
	_body_stack.add_child(_incoming_box)
	var continue_lane := CenterContainer.new()
	add_child(continue_lane)
	_continue_button = Factory.command_button("", Factory.COMMAND_PRIMARY)
	_continue_button.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_continue_button, 22)
	_continue_button.pressed.connect(_on_continue)
	continue_lane.add_child(_continue_button)


func _refresh_text() -> void:
	var failure := bool(_snapshot.get("failure", false))
	_kicker.text = tr("REPORT_FAILURE_KICKER" if failure else "REPORT_STAGE_KICKER")
	_title.text = tr("REPORT_FAILURE_TITLE" if failure else "REPORT_STAGE_TITLE").replace(
		"%d", str(int(_snapshot.get("stage_number", 1)))
	).replace(
		"%s", tr(String(_snapshot.get("stage_title_key", "")))
	)
	var seconds := maxi(0, roundi(float(_snapshot.get("run_time_seconds", 0.0))))
	_summary.text = tr("REPORT_SUMMARY").replace(
		"%time%", "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
	).replace(
		"%hull%", str(roundi(float(_snapshot.get("hull", 0.0))))
	).replace(
		"%max%", str(roundi(float(_snapshot.get("max_hull", 0.0))))
	)
	_continue_button.text = tr(
		"REPORT_DEPLOYMENT"
		if failure
		else (
			"REPORT_FINAL"
			if not bool(_snapshot.get("has_next_stage", false))
			else "REPORT_CONTINUE"
		)
	)


func _rebuild_failure_recap() -> void:
	_clear(_incoming_box)
	var failure := bool(_snapshot.get("failure", false))
	_incoming_box.visible = failure
	_body_stack.move_child(_incoming_box, 0 if failure else 1)
	if not failure:
		return
	_incoming_box.add_child(Factory.section_heading(tr("REPORT_INCOMING")))
	var last_source := StringName(_snapshot.get("last_incoming_source", &""))
	if last_source != &"":
		var last := _label("", 15, Art.CORAL)
		last.text = tr("REPORT_LAST_HIT").replace(
			"%source%", tr(DamageSources.title_key(last_source, true))
		).replace(
			"%damage%", "%.1f" % float(_snapshot.get("last_incoming_damage", 0.0))
		)
		_incoming_box.add_child(last)
	for row_variant in Array(_snapshot.get("incoming", [])):
		var row := Dictionary(row_variant)
		var line := Factory.text_row(
			tr(String(row.get("title_key", "REPORT_SOURCE_OTHER"))),
			"%.1f" % float(row.get("damage", 0.0)),
			{
				"label_min_width":0.0,
				"label_size":17,
				"value_size":17,
				"label_color":Art.IVORY_BRIGHT,
				"value_color":Art.IVORY_BRIGHT,
			}
		)
		line.set_meta("shared_component", "TextRow")
		_incoming_box.add_child(line)


func _apply_responsive_layout() -> void:
	var compact := _force_compact or (is_inside_tree() and get_window().size.x < 1180)
	if is_instance_valid(_report_body):
		_report_body.set_compact_mode(compact)


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _label(key: String, size: int, color: Color) -> Label:
	var label := Factory.label(tr(key), size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _on_continue() -> void:
	if _guard <= 0.0:
		continued.emit()


func debug_contract() -> Dictionary:
	var body_contract: Dictionary = _report_body.debug_contract()
	return {
		"guard":INPUT_GUARD_SECONDS,
		"defeats":_snapshot.get("defeats", []).size(),
		"outgoing":_snapshot.get("outgoing", []).size(),
		"attributes":_snapshot.get("attributes", []).size(),
		"failure":bool(_snapshot.get("failure", false)),
		"continue_size":_continue_button.custom_minimum_size,
		"wide_dividers":body_contract["wide_dividers"],
		"wide_columns":body_contract["wide_columns"],
		"compact_tabs":body_contract["compact_tabs"],
		"scroll_views":int(body_contract["scroll_views"]) + 1,
		"incoming_visible":_incoming_box.visible,
		"incoming_rows":_snapshot.get("incoming", []).size(),
		"last_hit_present":not StringName(_snapshot.get("last_incoming_source", &"")).is_empty(),
		"fixed_actions":find_children("*", "Button", true, false).size(),
		"summary_text":_summary.text,
		"semantic_icons":body_contract["semantic_icons"],
		"shared_text_rows":_count_shared_text_rows(self),
		"decorated_metric_rows":body_contract["decorated_metric_rows"],
	}


func _count_shared_text_rows(node: Node) -> int:
	var count := (
		1
		if node.has_meta("shared_component")
		and node.get_meta("shared_component") == "TextRow"
		else 0
	)
	for child in node.get_children():
		count += _count_shared_text_rows(child)
	return count
