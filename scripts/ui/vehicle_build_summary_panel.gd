class_name VehicleBuildSummaryPanel
extends VBoxContainer

## Shared read-only build renderer for Settings and Guidebook. Gameplay owns
## every value; this component presents the snapshot through shared TextRows.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

const STAT_GROUPS: Array[Dictionary] = [
	{"key":"SHIP_STATUS_GROUP_MOBILITY", "ids":[&"hull", &"speed", &"dash_cooldown"]},
	{"key":"SHIP_STATUS_GROUP_PRIMARY", "ids":[&"primary_damage", &"fire_rate", &"projectile_speed"]},
	{"key":"SHIP_STATUS_GROUP_EMP", "ids":[&"emp_damage", &"emp_cooldown"]},
]

var _snapshot: Dictionary = {}
var _empty_label: Label
var _summary_rows: VBoxContainer
var _summary_values: Array[Label] = []
var _stat_groups: HBoxContainer
var _stat_boxes: Array[VBoxContainer] = []
var _secondary_box: VBoxContainer
var _upgrade_box: VBoxContainer
var _secondary_title: Label
var _upgrade_title: Label
var _rendered_stat_count := 0
var _rendered_text_row_count := 0


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_empty_label = Factory.label("SHIP_STATUS_EMPTY", 17, Art.MINT_SOFT)
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_label.custom_minimum_size.y = 54.0
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_empty_label)
	_build_summary_rows()
	_build_stat_groups()
	set_snapshot({})


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if not is_node_ready():
		return
	var active := bool(_snapshot.get("active", false))
	_empty_label.visible = not active
	_summary_rows.visible = active
	_stat_groups.visible = active
	_secondary_box.visible = active
	_upgrade_box.visible = active
	_secondary_title.visible = active
	_upgrade_title.visible = active
	for box in _stat_boxes:
		_clear_dynamic_rows(box)
	_clear(_secondary_box)
	_clear(_upgrade_box)
	_rendered_stat_count = 0
	_rendered_text_row_count = 3 if active else 0
	if not active:
		return
	_refresh_summary()
	_refresh_stats()
	_refresh_secondaries()
	_refresh_upgrades()


func _build_summary_rows() -> void:
	_summary_rows = VBoxContainer.new()
	_summary_rows.add_theme_constant_override("separation", 4)
	add_child(_summary_rows)
	for _index in 3:
		var row := Factory.text_row("", "", {
			"value_size":17,
			"value_color":Art.TEXT_PRIMARY,
		})
		(row.get_child(0) as Label).visible = false
		var value := row.get_child(1) as Label
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_summary_rows.add_child(row)
		_summary_values.append(value)


func _build_stat_groups() -> void:
	_stat_groups = HBoxContainer.new()
	_stat_groups.add_theme_constant_override("separation", 24)
	_stat_groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_stat_groups)
	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 12)
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stat_groups.add_child(left_column)
	_stat_groups.add_child(VSeparator.new())
	var right_column := VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 12)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stat_groups.add_child(right_column)
	for group_index in STAT_GROUPS.size():
		var group := STAT_GROUPS[group_index]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(Factory.section_heading(String(group["key"])))
		(left_column if group_index < 2 else right_column).add_child(box)
		_stat_boxes.append(box)
	_secondary_title = Factory.section_heading("SHIP_STATUS_SECONDARIES")
	right_column.add_child(_secondary_title)
	_secondary_box = VBoxContainer.new()
	_secondary_box.add_theme_constant_override("separation", 4)
	right_column.add_child(_secondary_box)
	_upgrade_title = Factory.section_heading("SHIP_STATUS_UPGRADES")
	right_column.add_child(_upgrade_title)
	_upgrade_box = VBoxContainer.new()
	_upgrade_box.add_theme_constant_override("separation", 4)
	right_column.add_child(_upgrade_box)


func _refresh_summary() -> void:
	var run_state := Dictionary(_snapshot.get("run_state", {}))
	_summary_values[0].text = tr("SHIP_STATUS_SUMMARY_LEVEL").replace(
		"%level%", str(int(run_state.get("level", 1)))
	)
	_summary_values[1].text = tr("SHIP_STATUS_SUMMARY_HULL").replace(
		"%current%", str(roundi(float(run_state.get("health", 0.0))))
	).replace("%max%", str(roundi(float(run_state.get("max_health", 0.0)))))
	_summary_values[2].text = tr("SHIP_STATUS_SUMMARY_XP").replace(
		"%current%", str(int(run_state.get("experience", 0)))
	).replace("%required%", str(int(run_state.get("experience_required", 0))))


func _refresh_stats() -> void:
	var by_id: Dictionary = {}
	for stat_variant in _snapshot.get("stats", []):
		var stat := Dictionary(stat_variant)
		by_id[StringName(stat.get("id", &""))] = stat
	var rendered_ids: Dictionary = {}
	for group_index in STAT_GROUPS.size():
		for stat_id_variant in STAT_GROUPS[group_index]["ids"]:
			var stat_id := StringName(stat_id_variant)
			if not by_id.has(stat_id):
				continue
			_append_stat_row(_stat_boxes[group_index], Dictionary(by_id[stat_id]))
			rendered_ids[stat_id] = true
	for stat_id_variant in by_id:
		var stat_id := StringName(stat_id_variant)
		if not rendered_ids.has(stat_id):
			_append_stat_row(_stat_boxes[-1], Dictionary(by_id[stat_id]))


func _append_stat_row(parent: VBoxContainer, stat: Dictionary) -> void:
	var row := Factory.text_row(
		String(stat.get("label_key", "")),
		_format_value(stat),
		{"label_min_width":128.0, "value_size":16}
	)
	parent.add_child(row)
	_rendered_stat_count += 1
	_rendered_text_row_count += 1


func _refresh_secondaries() -> void:
	var secondaries: Array = _snapshot.get("secondaries", [])
	if secondaries.is_empty():
		_append_named_row(_secondary_box, "SHIP_STATUS_NONE", "")
		return
	for secondary_variant in secondaries:
		var row := Dictionary(secondary_variant)
		_append_named_row(
			_secondary_box,
			String(row.get("name_key", "")),
			tr("SHIP_STATUS_LEVEL").replace("%d", str(int(row.get("level", 1))))
		)


func _refresh_upgrades() -> void:
	var upgrades: Array = _snapshot.get("upgrades", [])
	if upgrades.is_empty():
		_append_named_row(_upgrade_box, "SHIP_STATUS_NONE", "")
		return
	for upgrade_variant in upgrades:
		var row := Dictionary(upgrade_variant)
		_append_named_row(
			_upgrade_box,
			String(row.get("title_key", "")),
			tr("SHIP_STATUS_LEVEL_MAX").replace(
				"%level%", str(int(row.get("level", 0)))
			).replace("%max%", str(int(row.get("max_level", 1))))
		)


func _append_named_row(parent: VBoxContainer, label_key: String, value: String) -> void:
	parent.add_child(Factory.text_row(label_key, value, {
		"label_min_width":128.0,
		"label_size":15,
		"value_size":15,
	}))
	_rendered_text_row_count += 1


func _format_value(stat: Dictionary) -> String:
	var value := float(stat.get("value", 0.0))
	var decimals := int(stat.get("decimals", 0))
	var formatted := "%.*f" % [decimals, value]
	var unit_key := String(stat.get("unit_key", ""))
	return formatted if unit_key.is_empty() else "%s %s" % [formatted, tr(unit_key)]


func _clear_dynamic_rows(box: VBoxContainer) -> void:
	for index in range(box.get_child_count() - 1, 0, -1):
		var child := box.get_child(index)
		box.remove_child(child)
		child.queue_free()


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func debug_contract() -> Dictionary:
	var active := bool(_snapshot.get("active", false))
	return {
		"active":active,
		"stats":_snapshot.get("stats", []).size(),
		"rendered_stats":_rendered_stat_count,
		"stat_groups":_stat_boxes.size(),
		"summary_visible":is_instance_valid(_summary_rows) and _summary_rows.visible,
		"summary_panel_count":0,
		"text_row_count":_rendered_text_row_count,
		"empty_only":not active and _empty_label.visible and not _summary_rows.visible,
		"summary_level_text":_summary_values[0].text if not _summary_values.is_empty() else "",
		"first_group_title":tr(String(STAT_GROUPS[0]["key"])),
		"upgrades":_snapshot.get("upgrades", []).size(),
	}
