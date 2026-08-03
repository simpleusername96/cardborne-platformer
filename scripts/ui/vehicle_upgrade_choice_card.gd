class_name VehicleUpgradeChoiceCard
extends Button

## Read-only presentation for one frozen upgrade offer. The parent panel owns
## selection/confirmation, while card definitions and application remain in the
## gameplay progression layer.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const UpgradeGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd"
)


var _offer: Dictionary = {}
var _selected := false
var _compact := false
var _content_margin: MarginContainer
var _content_box: VBoxContainer
var _family: Label
var _title: Label
var _summary: Label
var _art_lane: CenterContainer
var _glyph: VehicleUpgradeGlyphRenderer
var _effects: VBoxContainer
var _behavior: Label


func _ready() -> void:
	text = ""
	clip_contents = true
	custom_minimum_size = Vector2(304.0, 330.0)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_ALL
	theme_type_variation = &"SelectableButton"
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
		&"SelectedSelectableButton"
		if _selected
		else &"SelectableButton"
	)


func set_compact_mode(value: bool) -> void:
	_compact = value
	custom_minimum_size = Vector2(244.0, 286.0) if value else Vector2(304.0, 330.0)
	if not is_node_ready():
		return
	var horizontal_margin := 10 if value else 14
	var vertical_margin := 5 if value else 6
	for side in ["margin_left", "margin_right"]:
		_content_margin.add_theme_constant_override(side, horizontal_margin)
	for side in ["margin_top", "margin_bottom"]:
		_content_margin.add_theme_constant_override(side, vertical_margin)
	_content_box.add_theme_constant_override("separation", 2 if value else 3)
	_glyph.custom_minimum_size = (
		Vector2(64.0, 64.0) if value else Vector2(88.0, 88.0)
	)
	Factory.apply_font_size(_family, 13 if value else 14)
	Factory.apply_font_size(_title, 22 if value else 24)
	_title.custom_minimum_size.y = 48.0 if value else 52.0
	Factory.apply_font_size(_summary, 15 if value else 16)
	_summary.custom_minimum_size.y = 54.0 if value else 60.0
	Factory.apply_font_size(_behavior, 15 if value else 16)
	_behavior.custom_minimum_size.y = 28.0 if value else 32.0
	_refresh()


func set_accessibility_mode(enabled: bool) -> void:
	if not enabled:
		return
	custom_minimum_size = Vector2(356.0, 520.0)
	_title.custom_minimum_size.y = 104.0
	_summary.custom_minimum_size.y = 120.0
	_behavior.custom_minimum_size.y = 64.0
	_glyph.custom_minimum_size = Vector2(112.0, 112.0)
	_refresh()


func offer_id() -> StringName:
	return StringName(_offer.get("id", &""))


func debug_contract() -> Dictionary:
	var normal_style := get_theme_stylebox(&"normal")
	var focus_style := get_theme_stylebox(&"focus")
	var glyph_contract := _glyph.debug_contract()
	return {
		"structured":true,
		"minimum_size":custom_minimum_size,
		"actual_size":size,
		"value_rows":(
			(_effects.get_child_count() if is_instance_valid(_effects) else 0)
			+ (1 if is_instance_valid(_behavior) and _behavior.visible else 0)
		),
		"effect_rows":_effects.get_child_count() if is_instance_valid(_effects) else 0,
		"has_scroll":false,
		"pip_slots":0,
		"stage_pip_count":0,
		"selected":_selected,
		"compact":_compact,
		"type_sizes":{
			"family":_family.get_theme_font_size("font_size"),
			"title":_title.get_theme_font_size("font_size"),
			"summary":_summary.get_theme_font_size("font_size"),
			"behavior":_behavior.get_theme_font_size("font_size"),
		},
		"summary_max_lines":_summary.max_lines_visible,
		"header_art_count":0,
		"body_art_count":1 if is_instance_valid(_glyph) else 0,
		"family_badge_count":0,
		"body_art_size":_glyph.custom_minimum_size,
		"body_art_asset_id":glyph_contract["asset_id"],
		"body_order":[
			"family", "title", "summary", "art", "effects", "behavior",
		],
		"state_cues":{
			"normal_flat":normal_style is StyleBoxFlat,
			"focus_flat":focus_style is StyleBoxFlat,
			"selected_corner":true,
			"focus_corner":true,
			"disabled_corner":true,
			"variation":theme_type_variation,
		},
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
		labels.append(_label_geometry(label))
	return {
		"rect":get_global_rect(),
		"content_rect":_content_box.get_global_rect(),
		"labels":labels,
		"glyph":_glyph.debug_contract(),
		"selected":_selected,
		"disabled":disabled,
		"summary_max_lines":_summary.max_lines_visible,
	}


func _build() -> void:
	_content_margin = MarginContainer.new()
	_content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_margin.add_theme_constant_override("margin_left", 14)
	_content_margin.add_theme_constant_override("margin_top", 6)
	_content_margin.add_theme_constant_override("margin_right", 14)
	_content_margin.add_theme_constant_override("margin_bottom", 6)
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_margin)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", 3)
	_content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_margin.add_child(_content_box)

	_family = _label(14, Art.TEXT_PRIMARY)
	_family.name = "FamilyLabel"
	_family.theme_type_variation = &"MetricLabel"
	_family.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_family.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content_box.add_child(_family)
	_title = _label(24, Art.TEXT_PRIMARY)
	_title.name = "TitleLabel"
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.max_lines_visible = 2
	_title.custom_minimum_size.y = 52.0
	_content_box.add_child(_title)
	_summary = _label(16, Art.TEXT_PRIMARY)
	_summary.name = "SummaryLabel"
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.max_lines_visible = 3
	_summary.custom_minimum_size.y = 60.0
	_content_box.add_child(_summary)
	_art_lane = CenterContainer.new()
	_art_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(_art_lane)
	_glyph = UpgradeGlyphRenderer.new()
	_glyph.name = "UpgradeBodyArtwork"
	_glyph.custom_minimum_size = Vector2(88.0, 88.0)
	_art_lane.add_child(_glyph)
	_effects = VBoxContainer.new()
	_effects.add_theme_constant_override("separation", 4)
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(_effects)
	_behavior = _label(16, Art.SUPPORT)
	_behavior.name = "BehaviorLabel"
	_behavior.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_behavior.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_behavior.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_behavior.max_lines_visible = 2
	_behavior.custom_minimum_size.y = 32.0
	_behavior.visible = false
	_content_box.add_child(_behavior)


func _refresh() -> void:
	_family.text = tr(String(_offer.get("family_key", "")))
	_title.text = tr(String(_offer.get("title_key", "")))
	_summary.text = tr(String(_offer.get("summary_key", "")))
	_refresh_family_glyph()
	_clear(_effects)
	var accessible_values := PackedStringArray()
	var previews: Array = _offer.get("effect_rows", [])
	for preview_variant in previews.slice(0, 2):
		var preview := Dictionary(preview_variant)
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 18.0 if _compact else 20.0
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var stat := _label(13 if _compact else 14, Art.TEXT_MUTED)
		stat.name = "StatLabel%d" % (_effects.get_child_count() + 1)
		stat.text = tr(String(preview.get("stat_key", "")))
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(stat)
		var delta := _label(13 if _compact else 14, Art.TEXT_PRIMARY)
		delta.name = "DeltaLabel%d" % (_effects.get_child_count() + 1)
		delta.text = _preview_value(preview)
		delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(delta)
		_effects.add_child(row)
		accessible_values.append("%s %s" % [stat.text, delta.text])
	var behavior_key := String(_offer.get("behavior_change_key", ""))
	_behavior.text = tr(behavior_key) if not behavior_key.is_empty() else ""
	_behavior.visible = not _behavior.text.is_empty()
	_refresh_summary_budget()
	var accessibility_parts := PackedStringArray([
		_family.text,
		_title.text,
		_summary.text,
		"; ".join(accessible_values),
		_behavior.text,
	])
	var non_empty_parts := PackedStringArray()
	for part in accessibility_parts:
		if not part.is_empty():
			non_empty_parts.append(part)
	accessibility_name = " · ".join(non_empty_parts)


func _refresh_summary_budget() -> void:
	var sparse_compact := (
		_compact
		and _effects.get_child_count() == 0
		and not _behavior.visible
	)
	_summary.max_lines_visible = 4 if sparse_compact else 3
	_summary.custom_minimum_size.y = (
		64.0
		if sparse_compact
		else (54.0 if _compact else 60.0)
	)


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


func _refresh_family_glyph() -> void:
	var family := StringName(_offer.get("family", &"secondary"))
	_glyph.configure(family, {})


func _label_geometry(label: Label) -> Dictionary:
	var label_rect := label.get_global_rect()
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var break_flags := TextServer.BREAK_MANDATORY
	match label.autowrap_mode:
		TextServer.AUTOWRAP_ARBITRARY:
			break_flags |= TextServer.BREAK_GRAPHEME_BOUND
		TextServer.AUTOWRAP_WORD:
			break_flags |= TextServer.BREAK_WORD_BOUND
		TextServer.AUTOWRAP_WORD_SMART:
			break_flags |= (
				TextServer.BREAK_WORD_BOUND
				| TextServer.BREAK_ADAPTIVE
			)
	break_flags |= label.autowrap_trim_flags
	var glyph_size := font.get_multiline_string_size(
		label.text,
		label.horizontal_alignment,
		label.size.x,
		font_size,
		-1,
		break_flags
	)
	var shaped_height := 0.0
	for line_index in label.get_line_count():
		shaped_height += float(label.get_line_height(line_index))
	glyph_size.y = maxf(glyph_size.y, shaped_height)
	var glyph_position := label_rect.position
	match label.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			glyph_position.x += (label_rect.size.x - glyph_size.x) * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			glyph_position.x += label_rect.size.x - glyph_size.x
	match label.vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			glyph_position.y += (label_rect.size.y - glyph_size.y) * 0.5
		VERTICAL_ALIGNMENT_BOTTOM:
			glyph_position.y += label_rect.size.y - glyph_size.y
	var glyph_rect := Rect2(glyph_position, glyph_size).grow(
		float(label.get_theme_constant("outline_size"))
	)
	return {
		"name":label.name,
		"text":label.text,
		"rect":label_rect,
		"glyph_rect":glyph_rect,
		"glyph_size":glyph_size,
		"font_size":font_size,
		"line_count":label.get_line_count(),
		"visible_line_count":label.get_visible_line_count(),
	}


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	Factory.apply_font_size(label, font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
