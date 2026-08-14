class_name VehicleUpgradeBuildRail
extends VBoxContainer

## Category-owned image grids beside mandatory upgrade offers. It consumes only a
## frozen gameplay snapshot and never decides what a player can equip.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const BuildCell = preload("res://scripts/ui/vehicle_upgrade_build_cell.gd")

var _sections: VBoxContainer
var _heading: Label
var _popover_layer: Control
var _popover: PanelContainer
var _popover_text: VBoxContainer
var _active_cell: Control
var _pinned := false
var _compact := false
var _large := false
var _show_heading := true
var _viewport_minimum_height := 0.0
var _snapshot: Dictionary = {}


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 2)
	_heading = Factory.section_heading(tr("UPGRADE_CURRENT_BUILD"))
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_heading.max_lines_visible = 1
	add_child(_heading)
	_sections = VBoxContainer.new()
	_sections.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_sections.add_theme_constant_override("separation", 2)
	add_child(_sections)
	# Keep the floating detail surface outside VBox sizing so opening it cannot
	# push the fixed offer/action region or create modal overflow.
	_popover_layer = Control.new()
	_popover_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popover_layer.clip_contents = false
	add_child(_popover_layer)
	_popover = Factory.surface(Factory.SURFACE_CONTENT)
	_popover.visible = false
	_popover.mouse_filter = Control.MOUSE_FILTER_STOP
	_popover.custom_minimum_size = Vector2(196.0, 0.0)
	_popover.set_as_top_level(true)
	_popover_text = VBoxContainer.new()
	_popover_text.add_theme_constant_override("separation", 4)
	_popover.add_child(_popover_text)
	_popover_layer.add_child(_popover)
	_apply_size_mode()
	set_snapshot(_snapshot)


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if not is_node_ready():
		return
	_apply_size_mode()
	for child in _sections.get_children():
		_sections.remove_child(child)
		child.queue_free()
	_active_cell = null
	_pinned = false
	_hide_popover()
	var dimensions := _dimensions()
	for category_variant in Array(snapshot.get("categories", [])):
		var category := Dictionary(category_variant)
		_add_category_section(category, dimensions)


func refresh_localized_content() -> void:
	_heading.text = tr("UPGRADE_CURRENT_BUILD")
	set_snapshot(_snapshot)


func set_compact_mode(compact: bool) -> void:
	_compact = compact
	_large = false
	if is_node_ready():
		_apply_size_mode()
		set_snapshot(_snapshot)


func set_large_mode(large: bool) -> void:
	_large = large and not _compact
	if is_node_ready():
		_apply_size_mode()
		set_snapshot(_snapshot)


func set_heading_visible(visible: bool) -> void:
	_show_heading = visible
	if not is_node_ready():
		return
	_apply_size_mode()


func set_viewport_minimum_height(value: float) -> void:
	_viewport_minimum_height = maxf(0.0, value)
	if is_node_ready():
		_apply_size_mode()


func _apply_size_mode() -> void:
	custom_minimum_size.x = 168.0 if _compact else (196.0 if _large else 180.0)
	custom_minimum_size.y = _viewport_minimum_height
	if is_instance_valid(_heading):
		_heading.visible = _show_heading
		_heading.add_theme_font_size_override(
			"font_size", 13 if _compact else (15 if _large else 14)
		)
	if is_instance_valid(_sections):
		_sections.add_theme_constant_override("separation", 1 if _compact else 2)


func _add_category_section(category: Dictionary, dimensions: Dictionary) -> void:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	section.add_theme_constant_override("separation", 1)
	_sections.add_child(section)
	var heading := Factory.label(
		tr(String(category.get("heading_key", ""))),
		11 if _compact else 12,
		Art.MUSTARD
	)
	heading.theme_type_variation = &"MetricLabel"
	heading.max_lines_visible = 1
	heading.tooltip_text = tr(String(category.get("description_key", "")))
	heading.accessibility_description = tr(String(category.get("description_key", "")))
	section.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	section.add_child(grid)
	for slot_variant in Array(category.get("slots", [])):
		var slot := Dictionary(slot_variant)
		var cell := BuildCell.new()
		grid.add_child(cell)
		cell.preview_requested.connect(_show_preview)
		cell.pin_requested.connect(_pin_preview)
		cell.preview_closed.connect(_close_preview)
		cell.set_record(Dictionary(slot.get("record", {})), dimensions["cell"], dimensions["art"])


func _dimensions() -> Dictionary:
	if _compact:
		return {"cell":22.0, "art":16.0}
	if _large:
		return {"cell":26.0, "art":20.0}
	return {"cell":24.0, "art":18.0}


func _show_preview(record: Dictionary, cell: Control) -> void:
	if _pinned and _active_cell != cell:
		_pinned = false
	_show_record(record, cell)


func _pin_preview(record: Dictionary, cell: Control) -> void:
	_pinned = true
	_show_record(record, cell)


func _show_record(record: Dictionary, cell: Control) -> void:
	if _active_cell != null and is_instance_valid(_active_cell):
		_active_cell.call("clear_focus_state")
	_active_cell = cell
	for child in _popover_text.get_children():
		_popover_text.remove_child(child)
		child.queue_free()
	var title := Factory.label(
		"%s · Lv.%d" % [tr(String(record.get("title_key", ""))), int(record.get("level", 0))],
		14,
		Art.TEXT_PRIMARY
	)
	title.theme_type_variation = &"SectionLabel"
	_popover_text.add_child(title)
	var rows: Array = record.get("effect_rows", [])
	for row_variant in rows.slice(0, 2):
		var row := Dictionary(row_variant)
		var stat := tr(String(row.get("stat_key", "")))
		var current := float(row.get("current", 0.0))
		var next := float(row.get("next", current))
		_popover_text.add_child(Factory.label(
			"%s %s" % [stat, _effect_text(current, next)], 13, Art.MINT_SOFT
		))
	var description := Factory.label(
		tr(String(record.get("description_key", ""))).strip_edges(), 13, Art.TEXT_MUTED
	)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 180.0
	description.max_lines_visible = 2
	_popover_text.add_child(description)
	_popover.visible = true
	await get_tree().process_frame
	if not is_instance_valid(cell) or cell != _active_cell:
		_hide_popover()
		return
	_popover.reset_size()
	var viewport_rect := get_viewport_rect()
	var cell_rect := cell.get_global_rect()
	var above := cell_rect.position.y - _popover.size.y - 8.0
	var y := above if above >= viewport_rect.position.y else cell_rect.end.y + 8.0
	_popover.global_position = Vector2(
		clampf(cell_rect.position.x, viewport_rect.position.x, viewport_rect.end.x - _popover.size.x),
		y
	)


func _effect_text(current: float, next: float) -> String:
	if is_equal_approx(current, next):
		return _format_effect(next)
	return "%s → %s" % [_format_effect(current), _format_effect(next)]


func _format_effect(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _hide_popover() -> void:
	if is_instance_valid(_popover):
		_popover.visible = false
	if _active_cell != null and is_instance_valid(_active_cell):
		_active_cell.call("clear_focus_state")
	_active_cell = null
	_pinned = false


func _close_preview(cell: Control) -> void:
	if _pinned or cell != _active_cell:
		return
	call_deferred("_hide_transient_preview", cell)


func _hide_transient_preview(cell: Control) -> void:
	if not _pinned and cell == _active_cell:
		_hide_popover()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(_popover) or not _popover.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_hide_popover()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		var mouse_position := get_viewport().get_mouse_position()
		var inside_popover := _popover.get_global_rect().has_point(mouse_position)
		var inside_cell := (
			_active_cell != null
			and is_instance_valid(_active_cell)
			and _active_cell.get_global_rect().has_point(mouse_position)
		)
		if not inside_popover and not inside_cell:
			_hide_popover()


func debug_open_first_preview() -> bool:
	if not is_instance_valid(_sections):
		return false
	for grid in _grids():
		for child in grid.get_children():
			if child.has_method("is_filled") and bool(child.call("is_filled")):
				_show_preview(Dictionary(child.call("record")), child as Control)
				return true
	return false


func debug_contract() -> Dictionary:
	var filled := 0
	var focusable := 0
	var artwork_ids: Array[StringName] = []
	var heading_texts: Array[String] = []
	if is_instance_valid(_sections):
		for section in _sections.get_children():
			for child in section.get_children():
				if child is Label:
					heading_texts.append((child as Label).text)
	for grid in _grids():
		for child in grid.get_children():
			if child.has_method("is_filled"):
				var cell := child as Control
				if bool(child.call("is_filled")):
					filled += 1
					focusable += 1
					artwork_ids.append(StringName(Dictionary(child.call("record")).get("artwork_asset_id", &"")))
	var dimensions := _dimensions()
	var grids_left_aligned := true
	var largest_rendered_cell := Vector2.ZERO
	for grid in _grids():
		grids_left_aligned = (
			grids_left_aligned
			and grid.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN
		)
		for child in grid.get_children():
			if child is Control:
				var rendered_size := (child as Control).size
				largest_rendered_cell.x = maxf(largest_rendered_cell.x, rendered_size.x)
				largest_rendered_cell.y = maxf(largest_rendered_cell.y, rendered_size.y)
	return {
		"minimum_width":custom_minimum_size.x,
		"columns":4,
		"cell_count":_cell_count(),
		"section_count":_sections.get_child_count() if is_instance_valid(_sections) else 0,
		"category_capacities":_category_capacities(),
		"heading_texts":heading_texts,
		"filled_count":filled,
		"focusable_count":focusable,
		"artwork_ids":artwork_ids,
		"popover_visible":_popover.visible if is_instance_valid(_popover) else false,
		"scroll_enabled":false,
		"sections_minimum_height":_sections.get_combined_minimum_size().y if is_instance_valid(_sections) else 0.0,
		"heading_visible":_heading.visible if is_instance_valid(_heading) else false,
		"minimum_height":custom_minimum_size.y,
		"viewport_minimum_height":_viewport_minimum_height,
		"cell_size":dimensions["cell"],
		"artwork_size":dimensions["art"],
		"largest_rendered_cell":largest_rendered_cell,
		"grids_left_aligned":grids_left_aligned,
	}


func _grids() -> Array[GridContainer]:
	var grids: Array[GridContainer] = []
	if not is_instance_valid(_sections):
		return grids
	for section in _sections.get_children():
		for child in section.get_children():
			if child is GridContainer:
				grids.append(child as GridContainer)
	return grids


func _cell_count() -> int:
	var count := 0
	for grid in _grids():
		count += grid.get_child_count()
	return count


func _category_capacities() -> Array[int]:
	var capacities: Array[int] = []
	for grid in _grids():
		capacities.append(grid.get_child_count())
	return capacities
