class_name VehicleUpgradeChoiceCard
extends Button

## Read-only presentation for one frozen upgrade offer. The parent panel owns
## selection/confirmation, while card definitions and application remain in the
## gameplay progression layer.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const PixelCatalog = preload("res://scripts/presentation/vehicle_pixel_asset_catalog.gd")

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
var _effect: Label
var _impact_title: Label
var _impact: Label
var _values: VBoxContainer
var _pips: LevelPips
var _pixel_catalog


func _ready() -> void:
	text = ""
	clip_contents = true
	custom_minimum_size = Vector2(282.0, 336.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_stretch_ratio = 1.0
	focus_mode = Control.FOCUS_ALL
	theme_type_variation = &"UpgradeChoiceCard"
	_pixel_catalog = PixelCatalog.new()
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
	custom_minimum_size = Vector2(276.0, 290.0) if value else Vector2(282.0, 336.0)
	if not is_node_ready():
		return
	var horizontal_margin := 14 if value else 20
	var vertical_margin := 8 if value else 18
	for side in ["margin_left", "margin_right"]:
		_content_margin.add_theme_constant_override(side, horizontal_margin)
	for side in ["margin_top", "margin_bottom"]:
		_content_margin.add_theme_constant_override(side, vertical_margin)
	_content_box.add_theme_constant_override("separation", 4 if value else 10)
	_family_badge.custom_minimum_size = Vector2(112.0, 26.0) if value else Vector2(118.0, 32.0)
	_family.add_theme_font_size_override("font_size", 13 if value else 15)
	_title.add_theme_font_size_override("font_size", 23 if value else 30)
	_title.custom_minimum_size.y = 34.0 if value else 46.0
	_effect.add_theme_font_size_override("font_size", 14 if value else 17)
	_effect.custom_minimum_size.y = 54.0 if value else 82.0
	_impact_title.add_theme_font_size_override("font_size", 12 if value else 14)
	_impact.add_theme_font_size_override("font_size", 21 if value else 28)
	_impact.custom_minimum_size.y = 30.0 if value else 42.0
	_pips.custom_minimum_size = Vector2(132.0, 24.0) if value else Vector2(132.0, 32.0)
	_refresh()


func offer_id() -> StringName:
	return StringName(_offer.get("id", &""))


func debug_contract() -> Dictionary:
	return {
		"structured":true,
		"minimum_size":custom_minimum_size,
		"value_rows":(
			(_values.get_child_count() if is_instance_valid(_values) else 0)
			+ (1 if is_instance_valid(_impact) and not _impact.text.is_empty() else 0)
		),
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
	_content_margin.add_theme_constant_override("margin_left", 20)
	_content_margin.add_theme_constant_override("margin_top", 18)
	_content_margin.add_theme_constant_override("margin_right", 20)
	_content_margin.add_theme_constant_override("margin_bottom", 18)
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_margin)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", 10)
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
	_title = _label(30, Art.IVORY_BRIGHT)
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size.y = 46.0
	_content_box.add_child(_title)
	_effect = _label(17, Art.IVORY_BRIGHT)
	_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_effect.custom_minimum_size.y = 82.0
	_content_box.add_child(_effect)
	_impact_title = _label(14, Art.MINT_SOFT)
	_impact_title.theme_type_variation = &"MetricLabel"
	_impact_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_impact_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_impact_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_child(_impact_title)
	_impact = _label(28, Art.IVORY_BRIGHT)
	_impact.theme_type_variation = &"TitleLabel"
	_impact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_impact.custom_minimum_size.y = 42.0
	_content_box.add_child(_impact)
	_values = VBoxContainer.new()
	_values.add_theme_constant_override("separation", 3)
	_values.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(_values)
	_pips = LevelPips.new()
	_content_box.add_child(_pips)


func _refresh() -> void:
	_family.text = tr(String(_offer.get("family_key", "")))
	_title.text = tr(String(_offer.get("title_key", "")))
	_effect.text = tr(String(_offer.get("description_key", "")))
	_clear(_values)
	var accessible_values := PackedStringArray()
	var previews: Array = _offer.get("value_previews", [])
	if previews.is_empty():
		_impact_title.text = tr("UPGRADE_CARD_LEVEL")
		_impact.text = tr("UPGRADE_CARD_LEVEL_VALUE").replace(
			"%level%",
			str(int(_offer.get("next_level", 1)))
		)
	else:
		var primary_preview := Dictionary(previews[0])
		_impact_title.text = tr(String(primary_preview.get("stat_key", "")))
		_impact.text = _preview_value(primary_preview)
		accessible_values.append("%s %s" % [_impact_title.text, _impact.text])
	for preview_index in range(1, previews.size()):
		var preview_variant = previews[preview_index]
		var preview := Dictionary(preview_variant)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var stat := _label(14, Art.MINT_SOFT)
		stat.text = tr(String(preview.get("stat_key", "")))
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _compact:
			stat.add_theme_font_size_override("font_size", 12)
		row.add_child(stat)
		var delta := _label(15, Art.IVORY_BRIGHT)
		delta.text = _preview_value(preview)
		delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _compact:
			delta.add_theme_font_size_override("font_size", 13)
		row.add_child(delta)
		_values.add_child(row)
		accessible_values.append("%s %s" % [stat.text, delta.text])
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
		_effect.text,
		"; ".join(accessible_values),
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
	if has_focus():
		draw_rect(Rect2(7.0, 10.0, 5.0, size.y - 20.0), Art.IVORY_BRIGHT)


func _draw_upgrade_icon() -> void:
	if _pixel_catalog == null or not _pixel_catalog.is_ready() or _offer.is_empty():
		return
	var upgrade_id := StringName(_offer.get("id", &""))
	var frame: Dictionary = _pixel_catalog.frame(
		&"upgrade_card_icons", upgrade_id, 0, &"normal", 0
	)
	if frame.is_empty():
		return
	var texture: Texture2D = _pixel_catalog.texture(&"upgrade_card_icons")
	if texture == null:
		return
	var region := Array(frame["region"])
	draw_texture_rect_region(
		texture,
		Rect2(14.0, 12.0, 42.0, 42.0),
		Rect2(
			float(region[0]), float(region[1]),
			float(region[2]), float(region[3])
		),
		Color.WHITE
	)


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
