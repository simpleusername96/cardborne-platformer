class_name VehicleStageReportPanel
extends VBoxContainer

signal continued
signal garage_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const DamageSources = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")
const CombatMeshIcon = preload("res://scripts/ui/vehicle_combat_mesh_icon.gd")
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const INPUT_GUARD_SECONDS := 0.35

class AttributeIcon:
	extends Control

	var attribute: StringName = &"kinetic"

	func _ready() -> void:
		custom_minimum_size = Vector2(30.0, 30.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_attribute(value: StringName) -> void:
		attribute = value
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var texture := SemanticAssets.texture(
			StringName("projectile/hostile_%s" % attribute)
		)
		if texture == null:
			return
		var extent := Vector2.ONE * 28.0
		draw_texture_rect(
			texture,
			Rect2(center - extent * 0.5, extent),
			false,
			Color.WHITE
		)


var _snapshot: Dictionary = {}
var _title: Label
var _kicker: Label
var _summary: Label
var _content: HBoxContainer
var _tabs: TabContainer
var _defeat_box: VBoxContainer
var _damage_box: VBoxContainer
var _attribute_box: VBoxContainer
var _incoming_box: VBoxContainer
var _continue_button: Button
var _guard := 0.0


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
	var seconds := maxi(0, roundi(float(_snapshot.get("clear_time", 0.0))))
	_summary.text = tr("REPORT_SUMMARY").replace(
		"%time%", "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
	).replace(
		"%hull%", str(roundi(float(_snapshot.get("hull", 0.0))))
	).replace(
		"%max%", str(roundi(float(_snapshot.get("max_hull", 0.0))))
	)
	_rebuild()
	_tabs.set_tab_title(0, tr("REPORT_DEFEATS"))
	_tabs.set_tab_title(1, tr("REPORT_OUTGOING"))
	_tabs.set_tab_title(2, tr("REPORT_ATTRIBUTES"))
	_apply_responsive_layout()
	visible = true
	(_tabs if _tabs.visible else _content).grab_focus()


func _process(delta: float) -> void:
	if _guard <= 0.0:
		return
	_guard = maxf(0.0, _guard - delta)
	if _guard <= 0.0:
		_continue_button.disabled = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_tabs):
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var compact := get_window().size.x < 1180
	_tabs.visible = compact
	_content.visible = not compact


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
	_content = HBoxContainer.new()
	_content.focus_mode = Control.FOCUS_ALL
	_content.add_theme_constant_override("separation", 18)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content)
	_defeat_box = _scroll_column("REPORT_DEFEATS")
	_damage_box = _scroll_column("REPORT_OUTGOING")
	_attribute_box = _scroll_column("REPORT_ATTRIBUTES")
	_content.add_child(_wrap_panel(_defeat_box))
	_content.add_child(VSeparator.new())
	_content.add_child(_wrap_panel(_damage_box))
	_content.add_child(VSeparator.new())
	_content.add_child(_wrap_panel(_attribute_box))
	_tabs = TabContainer.new()
	_tabs.focus_mode = Control.FOCUS_ALL
	_tabs.custom_minimum_size.y = 220.0
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	var compact_defeats := _scroll_column("REPORT_DEFEATS")
	var compact_damage := _scroll_column("REPORT_OUTGOING")
	var compact_attributes := _scroll_column("REPORT_ATTRIBUTES")
	_tabs.add_child(_wrap_panel(compact_defeats, "Defeats"))
	_tabs.add_child(_wrap_panel(compact_damage, "Damage"))
	_tabs.add_child(_wrap_panel(compact_attributes, "Attributes"))
	_tabs.set_meta("defeats", compact_defeats)
	_tabs.set_meta("damage", compact_damage)
	_tabs.set_meta("attributes", compact_attributes)
	_incoming_box = VBoxContainer.new()
	_incoming_box.add_theme_constant_override("separation", 5)
	add_child(_incoming_box)
	var continue_lane := CenterContainer.new()
	add_child(continue_lane)
	_continue_button = Button.new()
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.custom_minimum_size = Vector2(300.0, 48.0)
	_continue_button.add_theme_font_size_override("font_size", 22)
	_continue_button.focus_mode = Control.FOCUS_ALL
	_continue_button.pressed.connect(_on_continue)
	continue_lane.add_child(_continue_button)


func _rebuild() -> void:
	var compact_defeats := _tabs.get_meta("defeats") as VBoxContainer
	var compact_damage := _tabs.get_meta("damage") as VBoxContainer
	var compact_attributes := _tabs.get_meta("attributes") as VBoxContainer
	for box in [_defeat_box, compact_defeats]:
		_fill_defeats(box)
	for box in [_damage_box, compact_damage]:
		_fill_damage(box)
	for box in [_attribute_box, compact_attributes]:
		_fill_attributes(box)
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
		box.add_child(_label("REPORT_NONE", 17, Art.MINT_SOFT))
	for row in rows:
		var data := Dictionary(row)
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 8)
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var icon := CombatMeshIcon.new()
		icon.set_enemy(StringName(data["id"]))
		row_box.add_child(icon)
		var name_box := VBoxContainer.new()
		name_box.add_theme_constant_override("separation", 1)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := _label("", 17, Art.IVORY_BRIGHT)
		label.theme_type_variation = &"MetricLabel"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = tr(String(data["name_key"]))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_box.add_child(label)
		var elite_count := int(data.get("elite_count", 0))
		if elite_count > 0:
			var elite := _label("", 14, Art.BOSS_MAGENTA)
			elite.text = tr("REPORT_ELITE_COUNT").replace(
				"%count%", str(elite_count)
			)
			name_box.add_child(elite)
		row_box.add_child(name_box)
		var count := _label("", 17, Art.IVORY_BRIGHT)
		count.theme_type_variation = &"MetricLabel"
		count.text = "×%d" % int(data["count"])
		count.custom_minimum_size.x = 48.0
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row_box.add_child(count)
		box.add_child(row_box)


func _fill_damage(box: VBoxContainer) -> void:
	_clear_rows(box)
	var rows: Array = _snapshot.get("outgoing", [])
	if rows.is_empty():
		box.add_child(_label("REPORT_ZERO_DAMAGE", 17, Art.MINT_SOFT))
	for row in rows:
		box.add_child(_damage_row(Dictionary(row), true))
	var total := float(_snapshot.get("total_outgoing", 0.0))
	if total > 0.0:
		box.add_child(_metric_row(
			tr("REPORT_TOTAL_DAMAGE_LABEL"),
			"%.1f" % total,
			"",
			Art.MUSTARD
		))


func _fill_attributes(box: VBoxContainer) -> void:
	_clear_rows(box)
	var rows: Array = _snapshot.get("attributes", [])
	if rows.is_empty():
		box.add_child(_label("REPORT_NONE", 17, Art.MINT_SOFT))
	for row_variant in rows:
		var row := Dictionary(row_variant)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var icon := AttributeIcon.new()
		icon.set_attribute(StringName(row["id"]))
		line.add_child(icon)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 1)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(_damage_row(row, true))
		var applications := int(row.get("applications", 0))
		if applications > 0:
			var applications_label := _label("", 14, Art.MINT_SOFT)
			applications_label.text = tr("REPORT_ATTRIBUTE_APPLICATIONS").replace(
				"%count%", str(applications)
			)
			applications_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			content.add_child(applications_label)
		line.add_child(content)
		box.add_child(line)


func _damage_row(row: Dictionary, show_percentage: bool) -> HBoxContainer:
	return _metric_row(
		tr(String(row["title_key"])),
		"%.1f" % float(row["damage"]),
		(
			"%.1f%%" % (float(row.get("percentage_tenths", 0)) / 10.0)
			if show_percentage
			else ""
		),
		Art.IVORY_BRIGHT
	)


func _metric_row(
	title: String,
	value: String,
	percentage: String,
	color: Color
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_label := _label("", 17, color)
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	var value_label := _label("", 17, color)
	value_label.theme_type_variation = &"MetricLabel"
	value_label.text = value
	value_label.custom_minimum_size.x = 72.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	if not percentage.is_empty():
		var percentage_label := _label("", 17, color)
		percentage_label.theme_type_variation = &"MetricLabel"
		percentage_label.text = percentage
		percentage_label.custom_minimum_size.x = 68.0
		percentage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(percentage_label)
	return row


func _scroll_column(title_key: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		node.remove_child(child)
		child.queue_free()


func _section(key: String) -> Label:
	var label := _label(key, 22, Art.MUSTARD)
	label.theme_type_variation = &"SectionLabel"
	return label


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
		"attributes":_snapshot.get("attributes", []).size(),
		"failure":bool(_snapshot.get("failure", false)),
		"continue_size":_continue_button.custom_minimum_size,
		"wide_dividers":_content.find_children("*", "VSeparator", true, false).size(),
	}
