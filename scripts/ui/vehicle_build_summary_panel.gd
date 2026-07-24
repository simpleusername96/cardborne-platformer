class_name VehicleBuildSummaryPanel
extends VBoxContainer

## Shared read-only rendering for Settings and the guidebook Ship entry.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var _snapshot: Dictionary = {}
var _empty_label: Label
var _stat_grid: GridContainer
var _secondary_box: VBoxContainer
var _upgrade_box: VBoxContainer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_empty_label = _label("SHIP_STATUS_EMPTY", 16, Art.INK_MUTED)
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_empty_label)
	_stat_grid = GridContainer.new()
	_stat_grid.columns = 2
	_stat_grid.add_theme_constant_override("h_separation", 20)
	_stat_grid.add_theme_constant_override("v_separation", 8)
	add_child(_stat_grid)
	add_child(_section("SHIP_STATUS_SECONDARIES"))
	_secondary_box = VBoxContainer.new()
	_secondary_box.add_theme_constant_override("separation", 5)
	add_child(_secondary_box)
	add_child(_section("SHIP_STATUS_UPGRADES"))
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
	_stat_grid.visible = active
	_secondary_box.visible = active
	_upgrade_box.visible = active
	_clear(_stat_grid)
	_clear(_secondary_box)
	_clear(_upgrade_box)
	if not active:
		return
	for stat in _snapshot.get("stats", []):
		var key_label := _label(String(stat.get("label_key", "")), 15, Art.INK_MUTED)
		var value_label := _label("", 16, Art.INK)
		value_label.text = _format_value(Dictionary(stat))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_stat_grid.add_child(key_label)
		_stat_grid.add_child(value_label)
	var secondaries: Array = _snapshot.get("secondaries", [])
	if secondaries.is_empty():
		_secondary_box.add_child(_label("SHIP_STATUS_NONE", 15, Art.INK_MUTED))
	else:
		for secondary in secondaries:
			var row := Dictionary(secondary)
			var text := "%s  ·  %s" % [
				tr(String(row.get("name_key", ""))),
				tr("SHIP_STATUS_LEVEL") % int(row.get("level", 1)),
			]
			var label := _label("", 15, Art.INK)
			label.text = text
			_secondary_box.add_child(label)
	var upgrades: Array = _snapshot.get("upgrades", [])
	if upgrades.is_empty():
		_upgrade_box.add_child(_label("SHIP_STATUS_NONE", 15, Art.INK_MUTED))
	else:
		for upgrade in upgrades:
			var row := Dictionary(upgrade)
			var label := _label("", 15, Art.INK)
			label.text = "%s  ·  %s\n%s" % [
				tr(String(row.get("title_key", ""))),
				tr("SHIP_STATUS_LEVEL_MAX") % [
					int(row.get("level", 0)),
					int(row.get("max_level", 1)),
				],
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
	label.text = tr(key)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func debug_contract() -> Dictionary:
	return {
		"active":bool(_snapshot.get("active", false)),
		"stats":_snapshot.get("stats", []).size(),
		"upgrades":_snapshot.get("upgrades", []).size(),
	}
