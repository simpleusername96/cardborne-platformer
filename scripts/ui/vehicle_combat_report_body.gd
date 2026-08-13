class_name VehicleCombatReportBody
extends VBoxContainer

## Shared, presentation-only combat metrics used by stage and final reports.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const CombatMeshIcon = preload("res://scripts/ui/vehicle_combat_mesh_icon.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")


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
		var color := Art.attack_color(attribute)
		var points := PackedVector2Array([
			center + Vector2(12.0, 0.0),
			center + Vector2(-5.0, -8.0),
			center + Vector2(-11.0, 0.0),
			center + Vector2(-5.0, 8.0),
		])
		draw_colored_polygon(points, color)
		draw_polyline(
			PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
			Art.INK,
			2.0,
			true
		)


var _snapshot: Dictionary = {}
var _content: HBoxContainer
var _tabs: TabContainer
var _metric_scrolls: Array[ScrollContainer] = []
var _force_compact := false


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build()


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_rebuild()


func set_compact_mode(compact: bool) -> void:
	_force_compact = compact
	_apply_responsive_layout()


func set_accessibility_mode(enabled: bool) -> void:
	for scroll in _metric_scrolls:
		scroll.vertical_scroll_mode = (
			ScrollContainer.SCROLL_MODE_DISABLED
			if enabled
			else ScrollContainer.SCROLL_MODE_AUTO
		)


func refresh_localized_content() -> void:
	_rebuild()


func focus_target() -> Control:
	return _tabs if _tabs.visible else _content


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _build() -> void:
	_content = HBoxContainer.new()
	_content.focus_mode = Control.FOCUS_ALL
	_content.add_theme_constant_override("separation", 18)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content)
	for index in 3:
		_content.add_child(_scroll_column(index, false))
		if index < 2:
			_content.add_child(VSeparator.new())
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.focus_mode = Control.FOCUS_ALL
	add_child(_tabs)
	for index in 3:
		_tabs.add_child(_scroll_column(index, true))
	_apply_responsive_layout()


func _rebuild() -> void:
	if not is_instance_valid(_content):
		return
	for index in 3:
		_fill_column(_box_for(_content.get_child(index * 2)), index)
	for index in _tabs.get_tab_count():
		var scroll := _tabs.get_tab_control(index) as ScrollContainer
		_fill_column(_box_for(scroll), index)
		_tabs.set_tab_title(index, tr(_heading_key(index)))


func _scroll_column(index: int, compact: bool) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	_metric_scrolls.append(scroll)
	scroll.name = "Compact%s" % index if compact else "Wide%s" % index
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	return scroll


func _box_for(scroll_node: Node) -> VBoxContainer:
	var scroll := scroll_node as ScrollContainer
	return scroll.get_child(0).get_child(0) as VBoxContainer


func _fill_column(box: VBoxContainer, index: int) -> void:
	_clear(box)
	box.add_child(Factory.section_heading(tr(_heading_key(index))))
	var rows: Array = _snapshot.get(_rows_key(index), [])
	if rows.is_empty():
		box.add_child(Factory.label(
			tr("REPORT_ZERO_DAMAGE" if index == 1 else "REPORT_NONE"),
			17,
			Art.MINT_SOFT
		))
		return
	match index:
		0:
			_fill_defeats(box, rows)
		1:
			_fill_damage(box, rows, "total_outgoing")
		2:
			_fill_attributes(box, rows)


func _fill_defeats(box: VBoxContainer, rows: Array) -> void:
	for row_variant in rows:
		var row := Dictionary(row_variant)
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 8)
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var icon := CombatMeshIcon.new()
		icon.set_enemy(StringName(row.get("id", &"scrap_drone")))
		row_box.add_child(icon)
		var name_box := VBoxContainer.new()
		name_box.add_theme_constant_override("separation", 1)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_box.add_child(_metric_row(
			tr(String(row.get("name_key", "REPORT_SOURCE_OTHER"))),
			"×%d" % int(row.get("count", 0)),
			"",
			Art.IVORY_BRIGHT
		))
		var elite_count := int(row.get("elite_count", 0))
		if elite_count > 0:
			var elite := Factory.label(
				tr("REPORT_ELITE_COUNT").replace("%count%", str(elite_count)),
				14,
				Art.BOSS_MAGENTA
			)
			elite.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			name_box.add_child(elite)
		row_box.add_child(name_box)
		box.add_child(row_box)


func _fill_damage(box: VBoxContainer, rows: Array, total_key: String) -> void:
	for row_variant in rows:
		box.add_child(_damage_row(Dictionary(row_variant), true))
	var total := float(_snapshot.get(total_key, 0.0))
	if total > 0.0:
		box.add_child(_metric_row(
			tr("REPORT_TOTAL_DAMAGE_LABEL"),
			"%.1f" % total,
			"",
			Art.MUSTARD
		))


func _fill_attributes(box: VBoxContainer, rows: Array) -> void:
	for row_variant in rows:
		var row := Dictionary(row_variant)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var icon := AttributeIcon.new()
		icon.set_attribute(StringName(row.get("id", &"kinetic")))
		line.add_child(icon)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 1)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(_damage_row(row, true))
		var applications := int(row.get("applications", 0))
		if applications > 0:
			var applications_label := Factory.label(
				tr("REPORT_ATTRIBUTE_APPLICATIONS").replace("%count%", str(applications)),
				14,
				Art.MINT_SOFT
			)
			applications_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			content.add_child(applications_label)
		line.add_child(content)
		box.add_child(line)
	var total := float(_snapshot.get("total_attributes", 0.0))
	if total > 0.0:
		box.add_child(_metric_row(
			tr("REPORT_TOTAL_DAMAGE_LABEL"),
			"%.1f" % total,
			"",
			Art.MUSTARD
		))


func _damage_row(row: Dictionary, show_percentage: bool) -> HBoxContainer:
	return _metric_row(
		tr(String(row.get("title_key", "REPORT_SOURCE_OTHER"))),
		"%.1f" % float(row.get("damage", 0.0)),
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
	var row := Factory.text_row(title, value, {
		"separation":8,
		"label_min_width":0.0,
		"label_size":17,
		"value_size":17,
		"label_color":color,
		"value_color":color,
	})
	row.set_meta("shared_component", "TextRow")
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := row.get_child(1) as Label
	value_label.theme_type_variation = &"MetricLabel"
	value_label.custom_minimum_size.x = 72.0
	if not percentage.is_empty():
		var percentage_label := Factory.label(percentage, 17, color)
		percentage_label.theme_type_variation = &"MetricLabel"
		percentage_label.custom_minimum_size.x = 68.0
		percentage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(percentage_label)
	return row


func _heading_key(index: int) -> String:
	return ["REPORT_DEFEATS", "REPORT_OUTGOING", "REPORT_ATTRIBUTES"][index]


func _rows_key(index: int) -> String:
	return ["defeats", "outgoing", "attributes"][index]


func _apply_responsive_layout() -> void:
	var compact := _force_compact or (is_inside_tree() and get_window().size.x < 1180)
	if is_instance_valid(_tabs):
		_tabs.visible = compact
	if is_instance_valid(_content):
		_content.visible = not compact


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func debug_contract() -> Dictionary:
	return {
		"wide_dividers":_content.find_children("*", "VSeparator", true, false).size(),
		"wide_columns":_count_children_of_type(_content, "ScrollContainer"),
		"compact_tabs":_tabs.get_tab_count(),
		"scroll_views":_metric_scrolls.size(),
		"semantic_icons":_count_semantic_icons(self),
		"shared_text_rows":_count_shared_text_rows(self),
		"decorated_metric_rows":_count_decorated_metric_rows(self),
	}


func _count_children_of_type(node: Node, type_name: String) -> int:
	var count := 0
	for child in node.get_children():
		if child.is_class(type_name):
			count += 1
	return count


func _count_semantic_icons(node: Node) -> int:
	var count := 1 if node is CombatMeshIcon or node is AttributeIcon else 0
	for child in node.get_children():
		count += _count_semantic_icons(child)
	return count


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


func _count_decorated_metric_rows(node: Node) -> int:
	var count := 0
	if node.has_meta("shared_component") and node.get_meta("shared_component") == "TextRow":
		count += node.find_children("*", "PanelContainer", true, false).size()
	for child in node.get_children():
		count += _count_decorated_metric_rows(child)
	return count
