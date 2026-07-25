class_name VehicleBuildSummaryPanel
extends VBoxContainer

## Shared read-only renderer for Settings and the Guidebook Ship entry.
## Gameplay owns every value in the frozen snapshot; this surface only groups
## stable IDs so both consumers present the same build truth.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const STAT_GROUPS: Array[Dictionary] = [
	{
		"key":"SHIP_STATUS_GROUP_MOBILITY",
		"ids":[&"hull", &"speed", &"dash_cooldown"],
	},
	{
		"key":"SHIP_STATUS_GROUP_PRIMARY",
		"ids":[&"primary_damage", &"fire_rate", &"projectile_speed", &"breach_charge"],
	},
	{
		"key":"SHIP_STATUS_GROUP_EMP",
		"ids":[&"emp_damage", &"emp_cooldown"],
	},
]

var _snapshot: Dictionary = {}
var _empty_label: Label
var _summary_strip: HBoxContainer
var _summary_labels: Array[Label] = []
var _stat_groups: HBoxContainer
var _stat_grids: Array[GridContainer] = []
var _secondary_box: VBoxContainer
var _upgrade_box: VBoxContainer
var _secondary_title: Label
var _upgrade_title: Label
var _rendered_stat_count := 0


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_empty_label = _label("SHIP_STATUS_EMPTY", 16, Art.INK_MUTED)
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_label.custom_minimum_size.y = 54.0
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_empty_label)
	_build_summary_strip()
	_build_stat_groups()
	_secondary_title = _section("SHIP_STATUS_SECONDARIES")
	add_child(_secondary_title)
	_secondary_box = VBoxContainer.new()
	_secondary_box.add_theme_constant_override("separation", 5)
	add_child(_secondary_box)
	_upgrade_title = _section("SHIP_STATUS_UPGRADES")
	add_child(_upgrade_title)
	_upgrade_box = VBoxContainer.new()
	_upgrade_box.add_theme_constant_override("separation", 7)
	add_child(_upgrade_box)
	set_snapshot({})


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if not is_node_ready():
		return
	var active := bool(_snapshot.get("active", false))
	_empty_label.visible = not active
	_summary_strip.visible = active
	_stat_groups.visible = active
	_secondary_box.visible = active
	_upgrade_box.visible = active
	_secondary_title.visible = active
	_upgrade_title.visible = active
	for grid in _stat_grids:
		_clear(grid)
	_clear(_secondary_box)
	_clear(_upgrade_box)
	_rendered_stat_count = 0
	if not active:
		return
	_refresh_summary()
	_refresh_stats()
	_refresh_secondaries()
	_refresh_upgrades()


func _build_summary_strip() -> void:
	_summary_strip = HBoxContainer.new()
	_summary_strip.add_theme_constant_override("separation", 14)
	_summary_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_summary_strip)
	for index in 3:
		if index > 0:
			_summary_strip.add_child(VSeparator.new())
		var label := _label("", 16, Art.INK)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_summary_strip.add_child(label)
		_summary_labels.append(label)


func _build_stat_groups() -> void:
	_stat_groups = HBoxContainer.new()
	_stat_groups.add_theme_constant_override("separation", 18)
	_stat_groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_stat_groups)
	for group in STAT_GROUPS:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_stretch_ratio = 1.0
		box.add_child(_section(String(group["key"])))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 6)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(grid)
		_stat_groups.add_child(box)
		_stat_grids.append(grid)


func _refresh_summary() -> void:
	var run_state := Dictionary(_snapshot.get("run_state", {}))
	_summary_labels[0].text = tr("SHIP_STATUS_SUMMARY_LEVEL").replace(
		"%level%", str(int(run_state.get("level", 1)))
	)
	_summary_labels[1].text = tr("SHIP_STATUS_SUMMARY_HULL").replace(
		"%current%", str(roundi(float(run_state.get("health", 0.0))))
	).replace(
		"%max%", str(roundi(float(run_state.get("max_health", 0.0))))
	)
	_summary_labels[2].text = tr("SHIP_STATUS_SUMMARY_XP").replace(
		"%current%", str(int(run_state.get("experience", 0)))
	).replace(
		"%required%", str(int(run_state.get("experience_required", 0)))
	)


func _refresh_stats() -> void:
	var by_id: Dictionary = {}
	for stat_variant in _snapshot.get("stats", []):
		var stat := Dictionary(stat_variant)
		by_id[StringName(stat.get("id", &""))] = stat
	var rendered_ids: Dictionary = {}
	for group_index in STAT_GROUPS.size():
		var grid := _stat_grids[group_index]
		for stat_id_variant in STAT_GROUPS[group_index]["ids"]:
			var stat_id := StringName(stat_id_variant)
			if not by_id.has(stat_id):
				continue
			_append_stat_row(grid, Dictionary(by_id[stat_id]))
			rendered_ids[stat_id] = true
	for stat_id_variant in by_id:
		var stat_id := StringName(stat_id_variant)
		if rendered_ids.has(stat_id):
			continue
		_append_stat_row(_stat_grids[-1], Dictionary(by_id[stat_id]))


func _append_stat_row(grid: GridContainer, stat: Dictionary) -> void:
	var key_label := _label(String(stat.get("label_key", "")), 14, Art.INK_MUTED)
	key_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := _label("", 15, Art.INK)
	value_label.text = _format_value(stat)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(key_label)
	grid.add_child(value_label)
	_rendered_stat_count += 1


func _refresh_secondaries() -> void:
	var secondaries: Array = _snapshot.get("secondaries", [])
	if secondaries.is_empty():
		_secondary_box.add_child(_label("SHIP_STATUS_NONE", 15, Art.INK_MUTED))
		return
	for secondary_variant in secondaries:
		var row := Dictionary(secondary_variant)
		var label := _label("", 15, Art.INK)
		label.text = "%s  ·  %s" % [
			tr(String(row.get("name_key", ""))),
			tr("SHIP_STATUS_LEVEL").replace(
				"%d", str(int(row.get("level", 1)))
			),
		]
		_secondary_box.add_child(label)


func _refresh_upgrades() -> void:
	var upgrades: Array = _snapshot.get("upgrades", [])
	if upgrades.is_empty():
		_upgrade_box.add_child(_label("SHIP_STATUS_NONE", 15, Art.INK_MUTED))
		return
	for upgrade_variant in upgrades:
		var row := Dictionary(upgrade_variant)
		var label := _label("", 15, Art.INK)
		label.text = "%s  ·  %s\n%s" % [
			tr(String(row.get("title_key", ""))),
			tr("SHIP_STATUS_LEVEL_MAX").replace(
				"%level%", str(int(row.get("level", 0)))
			).replace(
				"%max%", str(int(row.get("max_level", 1)))
			),
			tr(String(row.get("description_key", ""))),
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_upgrade_box.add_child(label)


func _format_value(stat: Dictionary) -> String:
	var value := float(stat.get("value", 0.0))
	var decimals := int(stat.get("decimals", 0))
	var formatted := ("%.*f" % [decimals, value])
	var unit_key := String(stat.get("unit_key", ""))
	return formatted if unit_key.is_empty() else "%s %s" % [formatted, tr(unit_key)]


func _section(key: String) -> Label:
	return _label(key, 17, Art.MUSTARD)


func _label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	# Keep unformatted localization keys on controls so Godot can update static
	# headings immediately when the locale changes.
	label.text = key
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


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
		"stat_groups":_stat_grids.size(),
		"summary_visible":is_instance_valid(_summary_strip) and _summary_strip.visible,
		"empty_only":(
			not active
			and _empty_label.visible
			and not _summary_strip.visible
			and not _stat_groups.visible
		),
		"summary_level_text":(
			_summary_labels[0].text
			if not _summary_labels.is_empty()
			else ""
		),
		"first_group_title":(
			tr(((_stat_groups.get_child(0) as VBoxContainer).get_child(0) as Label).text)
			if is_instance_valid(_stat_groups) and _stat_groups.get_child_count() > 0
			else ""
		),
		"upgrades":_snapshot.get("upgrades", []).size(),
	}
