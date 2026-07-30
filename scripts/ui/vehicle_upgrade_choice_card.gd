class_name VehicleUpgradeChoiceCard
extends Button

## Read-only presentation for one frozen upgrade offer. The parent panel owns
## selection/confirmation, while card definitions and application remain in the
## gameplay progression layer.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const GlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)
const ComponentMeshes = preload(
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)

class LevelPips:
	extends Control

	var next_level := 0
	var max_level := 1
	var active_color := Color.WHITE
	var available_color := Color.WHITE
	var unavailable_color := Color.WHITE


	func _ready() -> void:
		custom_minimum_size = Vector2(132.0, 32.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE


	func configure(
		next_value: int,
		max_value: int,
		active: Color,
		available: Color,
		unavailable: Color
	) -> void:
		next_level = clampi(next_value, 0, 3)
		max_level = clampi(max_value, 1, 3)
		active_color = active
		available_color = available
		unavailable_color = unavailable
		queue_redraw()


	func _draw() -> void:
		var radius := 9.0
		var gap := 38.0
		var start_x := (size.x - gap * 2.0) * 0.5
		for index in 3:
			var center := Vector2(start_x + gap * index, size.y * 0.5)
			if index < next_level:
				draw_circle(center, radius, active_color)
			elif index < max_level:
				draw_arc(center, radius, 0.0, TAU, 24, available_color, 2.0, true)
			else:
				draw_arc(center, radius, 0.0, TAU, 24, unavailable_color, 2.0, true)


var _offer: Dictionary = {}
var _selected := false
var _compact := false
var _content_margin: MarginContainer
var _content_box: VBoxContainer
var _family_badge: PanelContainer
var _family: Label
var _title: Label
var _summary: Label
var _effects: VBoxContainer
var _behavior: Label
var _pips: LevelPips


func _ready() -> void:
	text = ""
	clip_contents = true
	custom_minimum_size = Vector2(304.0, 330.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_stretch_ratio = 1.0
	focus_mode = Control.FOCUS_ALL
	theme_type_variation = &"UpgradeChoiceCard"
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	_build()
	if not _offer.is_empty():
		_refresh()


func set_offer(offer: Dictionary) -> void:
	_offer = offer.duplicate(true)
	set_meta("upgrade_id", StringName(_offer.get("id", &"")))
	if is_node_ready():
		_refresh()


func set_selected_state(value: bool) -> void:
	_selected = value
	theme_type_variation = (
		&"SelectedUpgradeChoiceCard"
		if _selected
		else &"UpgradeChoiceCard"
	)
	queue_redraw()


func set_compact_mode(value: bool) -> void:
	_compact = value
	custom_minimum_size = Vector2(280.0, 286.0) if value else Vector2(304.0, 330.0)
	if not is_node_ready():
		return
	var horizontal_margin := 12 if value else 14
	var vertical_margin := 8 if value else 12
	for side in ["margin_left", "margin_right"]:
		_content_margin.add_theme_constant_override(side, horizontal_margin)
	for side in ["margin_top", "margin_bottom"]:
		_content_margin.add_theme_constant_override(side, vertical_margin)
	_content_box.add_theme_constant_override("separation", 5 if value else 8)
	_family_badge.custom_minimum_size = Vector2(112.0, 26.0) if value else Vector2(118.0, 32.0)
	_family.add_theme_font_size_override("font_size", 13 if value else 14)
	_title.add_theme_font_size_override("font_size", 21 if value else 24)
	_title.custom_minimum_size.y = 44.0 if value else 54.0
	_summary.add_theme_font_size_override("font_size", 14 if value else 15)
	_summary.custom_minimum_size.y = 64.0 if value else 72.0
	_behavior.add_theme_font_size_override("font_size", 14)
	_behavior.custom_minimum_size.y = 34.0
	_pips.custom_minimum_size = Vector2(132.0, 24.0) if value else Vector2(132.0, 32.0)
	_refresh()


func offer_id() -> StringName:
	return StringName(_offer.get("id", &""))


func debug_contract() -> Dictionary:
	return {
		"structured":true,
		"minimum_size":custom_minimum_size,
		"value_rows":(
			(_effects.get_child_count() if is_instance_valid(_effects) else 0)
			+ (1 if is_instance_valid(_behavior) and _behavior.visible else 0)
		),
		"effect_rows":_effects.get_child_count() if is_instance_valid(_effects) else 0,
		"has_scroll":false,
		"pip_slots":3,
		"selected":_selected,
		"compact":_compact,
		"mouse_passthrough":(
			is_instance_valid(_family)
			and _family.mouse_filter == Control.MOUSE_FILTER_IGNORE
		),
	}


func debug_geometry_contract() -> Dictionary:
	var labels: Array[Dictionary] = []
	for node in find_children("*", "Label", true, false):
		var label := node as Label
		if not label.visible:
			continue
		labels.append({
			"name":label.name,
			"text":label.text,
			"rect":label.get_global_rect(),
			"line_count":label.get_line_count(),
			"visible_line_count":label.get_visible_line_count(),
		})
	return {
		"rect":get_global_rect(),
		"labels":labels,
		"selected":_selected,
	}


func _build() -> void:
	_content_margin = MarginContainer.new()
	_content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_margin.add_theme_constant_override("margin_left", 14)
	_content_margin.add_theme_constant_override("margin_top", 12)
	_content_margin.add_theme_constant_override("margin_right", 14)
	_content_margin.add_theme_constant_override("margin_bottom", 12)
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_margin)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", 8)
	_content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_margin.add_child(_content_box)

	var family_lane := CenterContainer.new()
	family_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(family_lane)
	_family_badge = PanelContainer.new()
	_family_badge.theme_type_variation = &"FamilyBadge"
	_family_badge.custom_minimum_size = Vector2(118.0, 32.0)
	_family_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	family_lane.add_child(_family_badge)
	_family = _label(15, Art.INK)
	_family.theme_type_variation = &"MetricLabel"
	_family.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_family.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_family_badge.add_child(_family)
	_title = _label(24, Art.TEXT_PRIMARY)
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size.y = 54.0
	_content_box.add_child(_title)
	_summary = _label(15, Art.TEXT_PRIMARY)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size.y = 72.0
	_content_box.add_child(_summary)
	_effects = VBoxContainer.new()
	_effects.add_theme_constant_override("separation", 4)
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(_effects)
	_behavior = _label(14, Art.SUPPORT)
	_behavior.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_behavior.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_behavior.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_behavior.custom_minimum_size.y = 34.0
	_behavior.visible = false
	_content_box.add_child(_behavior)
	_pips = LevelPips.new()
	_content_box.add_child(_pips)


func _refresh() -> void:
	_family.text = tr(String(_offer.get("family_key", "")))
	_title.text = tr(String(_offer.get("title_key", "")))
	_summary.text = tr(String(_offer.get("summary_key", "")))
	_clear(_effects)
	var accessible_values := PackedStringArray()
	var previews: Array = _offer.get("effect_rows", [])
	for preview_variant in previews.slice(0, 2):
		var preview := Dictionary(preview_variant)
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 24.0
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var stat := _label(14, Art.TEXT_MUTED)
		stat.text = tr(String(preview.get("stat_key", "")))
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(stat)
		var delta := _label(14, Art.TEXT_PRIMARY)
		delta.text = _preview_value(preview)
		delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(delta)
		_effects.add_child(row)
		accessible_values.append("%s %s" % [stat.text, delta.text])
	var behavior_key := String(_offer.get("behavior_change_key", ""))
	_behavior.text = tr(behavior_key) if not behavior_key.is_empty() else ""
	_behavior.visible = not _behavior.text.is_empty()
	_pips.configure(
		int(_offer.get("next_level", 1)),
		int(_offer.get("max_level", 1)),
		Art.MUSTARD,
		Art.IVORY_BRIGHT,
		Color(Art.IVORY_SHADE, 0.42)
	)
	accessibility_name = " · ".join(PackedStringArray([
		_family.text,
		_title.text,
		_summary.text,
		"; ".join(accessible_values),
		_behavior.text,
	]))


func _preview_value(preview: Dictionary) -> String:
	var operation := String(preview.get("operation", "add"))
	var current := float(preview.get("current", 0.0))
	var next := float(preview.get("next", 0.0))
	var current_text := (
		"×%.2f" % current
		if operation == "multiply"
		else "%+.0f" % current
	)
	var next_text := (
		"×%.2f" % next
		if operation == "multiply"
		else "%+.0f" % next
	)
	return "%s → %s" % [current_text, next_text]


func _draw() -> void:
	_draw_upgrade_icon()
	if _selected:
		var center := Vector2(size.x - 20.0, 20.0)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0.0, -9.0),
			center + Vector2(9.0, 0.0),
			center + Vector2(0.0, 9.0),
			center + Vector2(-9.0, 0.0),
		]), Art.MUSTARD)
	if has_focus() and _selected:
		draw_rect(
			Rect2(Vector2(5.0, 5.0), size - Vector2(10.0, 10.0)),
			Art.SYSTEM,
			false,
			float(Art.FOCUS_WIDTH)
		)


func _draw_upgrade_icon() -> void:
	if _offer.is_empty():
		return
	var family := StringName(_offer.get("family", &""))
	var descriptor := GlyphCatalog.upgrade_family_descriptor(family)
	var color := Art.required_color_roles().get(
		String(descriptor.get("color", &"text_primary")),
		Art.TEXT_PRIMARY
	) as Color
	var center := Vector2(30.0, 29.0)
	var shape := StringName(descriptor.get("shape", &"diamond"))
	match shape:
		&"triple_core":
			for offset in [-7.0, 0.0, 7.0]:
				draw_circle(center + Vector2(offset, 0.0), 2.5, color)
		&"open_brackets":
			draw_line(center + Vector2(-8.0, -7.0), center + Vector2(-8.0, 7.0), color, 2.0)
			draw_line(center + Vector2(8.0, -7.0), center + Vector2(8.0, 7.0), color, 2.0)
		&"bolt":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-2.0, -9.0), center + Vector2(7.0, -2.0),
				center + Vector2(1.0, 0.0), center + Vector2(3.0, 9.0),
				center + Vector2(-7.0, 2.0), center + Vector2(-1.0, 0.0),
			]), color)
		&"split_diamond":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -9.0), center + Vector2(8.0, 0.0),
				center + Vector2(0.0, -2.0), center + Vector2(-8.0, 0.0),
			]), color)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, 2.0), center + Vector2(8.0, 0.0),
				center + Vector2(0.0, 9.0), center + Vector2(-8.0, 0.0),
			]), color)
		&"opposing_chevrons":
			draw_line(center + Vector2(-9.0, -6.0), center, color, 2.0)
			draw_line(center, center + Vector2(-9.0, 6.0), color, 2.0)
			draw_line(center + Vector2(9.0, -6.0), center, color, 2.0)
			draw_line(center, center + Vector2(9.0, 6.0), color, 2.0)
		_:
			var points := ComponentMeshes.primitive_points(shape)
			var transformed := PackedVector2Array()
			for point in points:
				transformed.append(center + point * 9.0)
			if transformed.size() >= 3:
				draw_colored_polygon(transformed, color)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
