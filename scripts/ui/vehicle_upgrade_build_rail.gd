class_name VehicleUpgradeBuildRail
extends VBoxContainer

## Compact frozen build summary shown beside upgrade offers.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

var _scroll: ScrollContainer
var _rows: VBoxContainer
var _empty: Label


func _ready() -> void:
	custom_minimum_size.x = 264.0
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	add_child(Factory.section_heading("UPGRADE_CURRENT_BUILD"))
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 5)
	_scroll.add_child(_rows)
	_empty = Factory.label("SHIP_STATUS_NONE", 15, Art.TEXT_MUTED)
	_rows.add_child(_empty)


func set_snapshot(snapshot: Dictionary) -> void:
	if not is_node_ready():
		return
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var upgrades: Array = snapshot.get("upgrades", [])
	if upgrades.is_empty():
		_empty = Factory.label("SHIP_STATUS_NONE", 15, Art.TEXT_MUTED)
		_rows.add_child(_empty)
		return
	var last_category: StringName = &""
	for upgrade_variant in upgrades:
		var upgrade := Dictionary(upgrade_variant)
		var category := StringName(upgrade.get("category", &""))
		if category != last_category:
			last_category = category
			var category_key := "UPGRADE_CATEGORY_%s" % String(category).to_upper()
			var heading := Factory.label(category_key, 13, Art.MINT_SOFT)
			heading.add_theme_constant_override("outline_size", 1)
			_rows.add_child(heading)
		_rows.add_child(Factory.text_row(
			String(upgrade.get("title_key", "")),
			tr("SHIP_STATUS_LEVEL").replace(
				"%d", str(int(upgrade.get("level", 0)))
			),
			{"label_min_width":150.0, "label_size":14, "value_size":14}
		))


func set_compact_mode(compact: bool) -> void:
	custom_minimum_size.x = 154.0 if compact else 264.0


func debug_contract() -> Dictionary:
	return {
		"minimum_width":custom_minimum_size.x,
		"row_count":_rows.get_child_count() if is_instance_valid(_rows) else 0,
		"scroll_enabled":is_instance_valid(_scroll),
	}
