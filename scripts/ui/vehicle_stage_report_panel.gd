class_name VehicleStageReportPanel
extends VBoxContainer

signal continued
signal garage_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const DamageSources = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")

const INPUT_GUARD_SECONDS := 0.35

var _snapshot: Dictionary = {}
var _title: Label
var _kicker: Label
var _content: HBoxContainer
var _tabs: TabContainer
var _defeat_box: VBoxContainer
var _damage_box: VBoxContainer
var _incoming_box: VBoxContainer
var _continue_button: Button
var _guard := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_build()


func open(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_guard = INPUT_GUARD_SECONDS
	_continue_button.disabled = true
	_kicker.text = tr("REPORT_FAILURE_KICKER" if bool(_snapshot.get("failure", false)) else "REPORT_STAGE_KICKER")
	_title.text = tr(
		"REPORT_FAILURE_TITLE"
		if bool(_snapshot.get("failure", false))
		else "REPORT_STAGE_TITLE"
	).replace(
		"%d", str(int(_snapshot.get("stage_number", 1)))
	).replace(
		"%s", tr(String(_snapshot.get("stage_title_key", "")))
	)
	_rebuild()
	_tabs.set_tab_title(0, tr("REPORT_DEFEATS"))
	_tabs.set_tab_title(1, tr("REPORT_OUTGOING"))
	visible = true
	_continue_button.grab_focus()


func _process(delta: float) -> void:
	if _guard <= 0.0:
		return
	_guard = maxf(0.0, _guard - delta)
	if _guard <= 0.0:
		_continue_button.disabled = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_tabs):
		var compact := get_viewport_rect().size.x <= 1000.0
		_tabs.visible = compact
		_content.visible = not compact


func _build() -> void:
	_kicker = _label("", 14, Art.MUSTARD)
	add_child(_kicker)
	_title = _label("", 28, Art.INK)
	add_child(_title)
	_content = HBoxContainer.new()
	_content.add_theme_constant_override("separation", 18)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content)
	_defeat_box = _scroll_column("REPORT_DEFEATS")
	_damage_box = _scroll_column("REPORT_OUTGOING")
	_content.add_child(_wrap_panel(_defeat_box))
	_content.add_child(_wrap_panel(_damage_box))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	var compact_defeats := _scroll_column("REPORT_DEFEATS")
	var compact_damage := _scroll_column("REPORT_OUTGOING")
	_tabs.add_child(_wrap_panel(compact_defeats, "Defeats"))
	_tabs.add_child(_wrap_panel(compact_damage, "Damage"))
	_tabs.set_meta("defeats", compact_defeats)
	_tabs.set_meta("damage", compact_damage)
	_incoming_box = VBoxContainer.new()
	_incoming_box.add_theme_constant_override("separation", 5)
	add_child(_incoming_box)
	_continue_button = Button.new()
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.custom_minimum_size.y = 48.0
	_continue_button.focus_mode = Control.FOCUS_ALL
	_continue_button.pressed.connect(_on_continue)
	add_child(_continue_button)


func _rebuild() -> void:
	var compact_defeats := _tabs.get_meta("defeats") as VBoxContainer
	var compact_damage := _tabs.get_meta("damage") as VBoxContainer
	for box in [_defeat_box, compact_defeats]:
		_fill_defeats(box)
	for box in [_damage_box, compact_damage]:
		_fill_damage(box)
	_clear(_incoming_box)
	var failure := bool(_snapshot.get("failure", false))
	_incoming_box.visible = failure
	if failure:
		_incoming_box.add_child(_section("REPORT_INCOMING"))
		var last_source := StringName(_snapshot.get("last_incoming_source", &""))
		if last_source != &"":
			var last := _label("", 15, Art.CORAL)
			last.text = tr("REPORT_LAST_HIT").replace(
				"%source%", tr(DamageSources.title_key(last_source, true))
			).replace(
				"%damage%", "%.1f" % float(_snapshot.get("last_incoming_damage", 0.0))
			)
			_incoming_box.add_child(last)
		for row in _snapshot.get("incoming", []):
			_incoming_box.add_child(_damage_row(Dictionary(row), false))
	_continue_button.text = tr("REPORT_GARAGE" if failure else ("REPORT_FINAL" if not bool(_snapshot.get("has_next_stage", false)) else "REPORT_CONTINUE"))


func _fill_defeats(box: VBoxContainer) -> void:
	_clear_rows(box)
	var rows: Array = _snapshot.get("defeats", [])
	if rows.is_empty():
		box.add_child(_label("REPORT_NONE", 15, Art.INK_MUTED))
	for row in rows:
		var data := Dictionary(row)
		var label := _label("", 15, Art.INK)
		label.text = "%s  ×%d" % [tr(String(data["name_key"])), int(data["count"])]
		box.add_child(label)
	for row in _snapshot.get("elites", []):
		var data := Dictionary(row)
		var label := _label("", 14, Art.BOSS_MAGENTA)
		label.text = "◇ %s  ×%d" % [tr(String(data["name_key"])), int(data["count"])]
		box.add_child(label)


func _fill_damage(box: VBoxContainer) -> void:
	_clear_rows(box)
	var rows: Array = _snapshot.get("outgoing", [])
	if rows.is_empty():
		box.add_child(_label("REPORT_ZERO_DAMAGE", 15, Art.INK_MUTED))
	for row in rows:
		box.add_child(_damage_row(Dictionary(row), true))


func _damage_row(row: Dictionary, show_percentage: bool) -> Label:
	var label := _label("", 15, Art.INK)
	label.text = "%s  ·  %.1f%s" % [
		tr(String(row["title_key"])),
		float(row["damage"]),
		("  ·  %.1f%%" % (float(row.get("percentage_tenths", 0)) / 10.0)) if show_percentage else "",
	]
	return label


func _scroll_column(title_key: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.set_meta("heading_key", title_key)
	box.add_child(_section(title_key))
	return box


func _wrap_panel(box: VBoxContainer, node_name: String = "") -> ScrollContainer:
	var scroll := ScrollContainer.new()
	if not node_name.is_empty():
		scroll.name = node_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	margin.add_child(box)
	return scroll


func _clear_rows(box: VBoxContainer) -> void:
	for child in box.get_children():
		if child == box.get_child(0):
			continue
		child.queue_free()


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _section(key: String) -> Label:
	return _label(key, 17, Art.MUSTARD)


func _label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _on_continue() -> void:
	if _guard > 0.0:
		return
	if bool(_snapshot.get("failure", false)):
		garage_requested.emit()
	else:
		continued.emit()


func debug_contract() -> Dictionary:
	return {
		"guard":INPUT_GUARD_SECONDS,
		"defeats":_snapshot.get("defeats", []).size(),
		"outgoing":_snapshot.get("outgoing", []).size(),
		"failure":bool(_snapshot.get("failure", false)),
	}
