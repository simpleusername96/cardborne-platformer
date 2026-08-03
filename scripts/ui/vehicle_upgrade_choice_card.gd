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

const WIDE_SIZE := Vector2(352.0, 432.0)
const COMPACT_SIZE := Vector2(280.0, 378.0)
const ACCESSIBILITY_SIZE := Vector2(520.0, 920.0)


var _offer: Dictionary = {}
var _selected := false
var _compact := false
var _accessibility_mode := false
var _content_margin: MarginContainer
var _content_box: VBoxContainer
var _family: Label
var _title: Label
var _dossier: HBoxContainer
var _art_lane: CenterContainer
var _glyph: VehicleUpgradeGlyphRenderer
var _body_divider: VSeparator
var _change_lane: VBoxContainer
var _level: Label
var _change_rule: HSeparator
var _effects: VBoxContainer
var _comparison_fallback: Label
var _footer_rule: HSeparator
var _footer_box: VBoxContainer
var _summary: Label
var _behavior: Label


func _ready() -> void:
	text = ""
	clip_contents = true
	custom_minimum_size = WIDE_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_ALL
	theme_type_variation = &"SelectableButton"
	_build()
	_apply_layout_profile()
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
	if not is_node_ready():
		custom_minimum_size = COMPACT_SIZE if value else WIDE_SIZE
		return
	_apply_layout_profile()
	_refresh()


func set_accessibility_mode(enabled: bool) -> void:
	_accessibility_mode = enabled
	if not is_node_ready():
		return
	_apply_layout_profile()
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
			+ (1 if is_instance_valid(_comparison_fallback) and _comparison_fallback.visible else 0)
			+ (1 if is_instance_valid(_behavior) and _behavior.visible else 0)
			+ (1 if is_instance_valid(_level) and _level.visible else 0)
		),
		"effect_rows":_effects.get_child_count() if is_instance_valid(_effects) else 0,
		"has_scroll":false,
		"pip_slots":0,
		"stage_pip_count":0,
		"selected":_selected,
		"compact":_compact,
		"accessibility_mode":_accessibility_mode,
		"dossier_split":true,
		"body_divider_count":1,
		"description_in_comparison":_comparison_fallback.visible,
		"footer_visible":_footer_box.visible,
		"type_sizes":{
			"family":_family.get_theme_font_size("font_size"),
			"level":_level.get_theme_font_size("font_size"),
			"title":_title.get_theme_font_size("font_size"),
			"summary":_summary.get_theme_font_size("font_size"),
			"behavior":_behavior.get_theme_font_size("font_size"),
		},
		"summary_max_lines":_summary.max_lines_visible,
		"comparison_max_lines":_comparison_fallback.max_lines_visible,
		"header_art_count":0,
		"body_art_count":1 if is_instance_valid(_glyph) else 0,
		"family_badge_count":0,
		"level_visible":_level.visible,
		"level_text":_level.text,
		"current_level":int(_offer.get("current_level", 0)),
		"next_level":int(_offer.get("next_level", 1)),
		"max_level":int(_offer.get("max_level", 1)),
		"body_art_size":_glyph.custom_minimum_size,
		"body_art_asset_id":glyph_contract["asset_id"],
		"body_order":[
			"family",
			"title",
			"dossier:art/divider/level/effects",
			"description",
			"behavior",
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
		"dossier_rect":_dossier.get_global_rect(),
		"art_lane_rect":_art_lane.get_global_rect(),
		"change_lane_rect":_change_lane.get_global_rect(),
		"body_divider_rect":_body_divider.get_global_rect(),
		"footer_rect":_footer_box.get_global_rect() if _footer_box.visible else Rect2(),
		"labels":labels,
		"glyph":_glyph.debug_contract(),
		"selected":_selected,
		"disabled":disabled,
		"summary_max_lines":_summary.max_lines_visible,
	}


func _build() -> void:
	_content_margin = MarginContainer.new()
	_content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_margin)

	_content_box = VBoxContainer.new()
	_content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_margin.add_child(_content_box)

	_family = _label(16, Art.SYSTEM)
	_family.name = "FamilyLabel"
	_family.theme_type_variation = &"MetricLabel"
	_family.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_family.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content_box.add_child(_family)

	_title = _label(28, Art.TEXT_PRIMARY)
	_title.name = "TitleLabel"
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.max_lines_visible = 2
	_content_box.add_child(_title)

	_dossier = HBoxContainer.new()
	_dossier.name = "DossierBody"
	_dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dossier.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dossier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(_dossier)

	_art_lane = CenterContainer.new()
	_art_lane.name = "ArtworkLane"
	_art_lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art_lane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_art_lane.size_flags_stretch_ratio = 0.95
	_art_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dossier.add_child(_art_lane)
	_glyph = UpgradeGlyphRenderer.new()
	_glyph.name = "UpgradeBodyArtwork"
	_art_lane.add_child(_glyph)

	_body_divider = VSeparator.new()
	_body_divider.name = "DossierDivider"
	_body_divider.custom_minimum_size.x = 1.0
	_body_divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dossier.add_child(_body_divider)

	_change_lane = VBoxContainer.new()
	_change_lane.name = "ChangeLane"
	_change_lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_change_lane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_change_lane.size_flags_stretch_ratio = 1.05
	_change_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dossier.add_child(_change_lane)

	_level = _label(18, Art.SYSTEM)
	_level.name = "LevelLabel"
	_level.theme_type_variation = &"MetricLabel"
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_change_lane.add_child(_level)

	_change_rule = HSeparator.new()
	_change_rule.name = "ChangeRule"
	_change_rule.custom_minimum_size.y = 1.0
	_change_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_change_lane.add_child(_change_rule)

	_effects = VBoxContainer.new()
	_effects.name = "EffectRows"
	_effects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effects.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_change_lane.add_child(_effects)

	_comparison_fallback = _label(16, Art.TEXT_PRIMARY)
	_comparison_fallback.name = "ComparisonDescriptionLabel"
	_comparison_fallback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comparison_fallback.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_comparison_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_comparison_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_comparison_fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comparison_fallback.visible = false
	_change_lane.add_child(_comparison_fallback)

	_footer_rule = HSeparator.new()
	_footer_rule.name = "DescriptionRule"
	_footer_rule.custom_minimum_size.y = 1.0
	_footer_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(_footer_rule)

	_footer_box = VBoxContainer.new()
	_footer_box.name = "DescriptionFooter"
	_footer_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_child(_footer_box)

	_summary = _label(16, Art.TEXT_PRIMARY)
	_summary.name = "SummaryLabel"
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_summary.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary.size_flags_stretch_ratio = 2.0
	_footer_box.add_child(_summary)

	_behavior = _label(15, Art.SUPPORT)
	_behavior.name = "BehaviorLabel"
	_behavior.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_behavior.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_behavior.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_behavior.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_behavior.visible = false
	_footer_box.add_child(_behavior)


func _apply_layout_profile() -> void:
	var horizontal_margin := 24
	var vertical_margin := 20
	var content_gap := 8
	var body_gap := 12
	var change_gap := 6
	var effect_gap := 6
	var footer_gap := 6
	var family_size := 16
	var title_size := 28
	var level_size := 18
	var summary_size := 16
	var behavior_size := 15
	var dossier_height := 174.0
	var glyph_size := Vector2(120.0, 120.0)
	var art_lane_width := 120.0
	var change_lane_width := 132.0
	var family_height := 20.0
	var title_height := 54.0
	var footer_height := 88.0
	var summary_height := 52.0
	var behavior_height := 28.0
	if _accessibility_mode:
		custom_minimum_size = ACCESSIBILITY_SIZE
		horizontal_margin = 20
		vertical_margin = 16
		content_gap = 10
		body_gap = 16
		change_gap = 10
		effect_gap = 12
		footer_gap = 8
		dossier_height = 340.0
		glyph_size = Vector2(176.0, 176.0)
		art_lane_width = 176.0
		change_lane_width = 268.0
		family_height = 44.0
		title_height = 144.0
		footer_height = 290.0
		summary_height = 200.0
		behavior_height = 82.0
	elif _compact:
		custom_minimum_size = COMPACT_SIZE
		horizontal_margin = 14
		vertical_margin = 10
		content_gap = 6
		body_gap = 8
		change_gap = 5
		effect_gap = 5
		footer_gap = 4
		family_size = 13
		title_size = 22
		level_size = 15
		summary_size = 14
		behavior_size = 13
		dossier_height = 182.0
		glyph_size = Vector2(88.0, 88.0)
		art_lane_width = 88.0
		change_lane_width = 140.0
		family_height = 18.0
		title_height = 48.0
		footer_height = 72.0
		summary_height = 42.0
		behavior_height = 24.0
	else:
		custom_minimum_size = WIDE_SIZE

	for side in ["margin_left", "margin_right"]:
		_content_margin.add_theme_constant_override(side, horizontal_margin)
	for side in ["margin_top", "margin_bottom"]:
		_content_margin.add_theme_constant_override(side, vertical_margin)
	_content_box.add_theme_constant_override("separation", content_gap)
	_dossier.add_theme_constant_override("separation", body_gap)
	_change_lane.add_theme_constant_override("separation", change_gap)
	_effects.add_theme_constant_override("separation", effect_gap)
	_footer_box.add_theme_constant_override("separation", footer_gap)
	_family.custom_minimum_size.y = family_height
	_title.custom_minimum_size.y = title_height
	_dossier.custom_minimum_size.y = dossier_height
	_art_lane.custom_minimum_size.x = art_lane_width
	_change_lane.custom_minimum_size.x = change_lane_width
	_glyph.custom_minimum_size = glyph_size
	_footer_box.custom_minimum_size.y = footer_height
	_summary.custom_minimum_size.y = summary_height
	_behavior.custom_minimum_size.y = behavior_height
	Factory.apply_font_size(_family, family_size)
	Factory.apply_font_size(_title, title_size)
	Factory.apply_font_size(_level, level_size)
	Factory.apply_font_size(_comparison_fallback, summary_size)
	Factory.apply_font_size(_summary, summary_size)
	Factory.apply_font_size(_behavior, behavior_size)
	_refresh_text_budgets()


func _refresh() -> void:
	if _offer.is_empty():
		return
	_family.text = tr(String(_offer.get("family_key", "")))
	_level.text = _level_transition_text()
	_title.text = tr(String(_offer.get("title_key", "")))
	_summary.text = tr(String(_offer.get("summary_key", "")))
	_comparison_fallback.text = _summary.text
	_refresh_family_glyph()
	_clear(_effects)
	var accessible_values := PackedStringArray()
	var previews: Array = _offer.get("effect_rows", [])
	for preview_variant in previews.slice(0, 2):
		var preview := Dictionary(preview_variant)
		var row_number := _effects.get_child_count() + 1
		var row := VBoxContainer.new()
		row.name = "EffectRow%d" % row_number
		row.add_theme_constant_override("separation", 2 if _compact else 4)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var stat := _label(_effect_stat_size(), Art.TEXT_PRIMARY)
		stat.name = "StatLabel%d" % row_number
		stat.text = tr(String(preview.get("stat_key", "")))
		stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stat.max_lines_visible = 2 if _compact or _accessibility_mode else 1
		row.add_child(stat)
		var delta_row := HBoxContainer.new()
		delta_row.name = "DeltaRow%d" % row_number
		delta_row.add_theme_constant_override("separation", 4)
		delta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var parts := _preview_value_parts(preview)
		var current := _label(_effect_value_size(), Art.TEXT_PRIMARY)
		current.name = "CurrentValueLabel%d" % row_number
		current.text = String(parts[0])
		delta_row.add_child(current)
		var arrow := _label(_effect_value_size(), Art.TEXT_MUTED)
		arrow.name = "ValueArrowLabel%d" % row_number
		arrow.text = "→"
		delta_row.add_child(arrow)
		var next := _label(_effect_value_size(), Art.SYSTEM)
		next.name = "NextValueLabel%d" % row_number
		next.text = String(parts[1])
		delta_row.add_child(next)
		row.add_child(delta_row)
		_effects.add_child(row)
		accessible_values.append("%s %s" % [stat.text, _preview_value(preview)])
	_effects.visible = _effects.get_child_count() > 0
	_comparison_fallback.visible = not _effects.visible
	_summary.visible = _effects.visible and not _summary.text.is_empty()
	var behavior_key := String(_offer.get("behavior_change_key", ""))
	_behavior.text = tr(behavior_key) if not behavior_key.is_empty() else ""
	_behavior.visible = (
		not _behavior.text.is_empty()
		and _behavior.text != _summary.text
	)
	_footer_box.visible = _summary.visible or _behavior.visible
	_footer_rule.visible = _footer_box.visible
	_refresh_text_budgets()
	var accessibility_parts := PackedStringArray([
		_family.text,
		_title.text,
		_level.text,
		"; ".join(accessible_values),
		_summary.text,
		_behavior.text,
	])
	var non_empty_parts := PackedStringArray()
	for part in accessibility_parts:
		if not part.is_empty():
			non_empty_parts.append(part)
	accessibility_name = " · ".join(non_empty_parts)


func _refresh_text_budgets() -> void:
	if _accessibility_mode:
		_comparison_fallback.max_lines_visible = 6
		_summary.max_lines_visible = 5
		_behavior.max_lines_visible = 2
		return
	if _compact:
		_comparison_fallback.max_lines_visible = 7
		_summary.max_lines_visible = 3
		_behavior.max_lines_visible = 2
		return
	_comparison_fallback.max_lines_visible = 6
	_summary.max_lines_visible = 3
	_behavior.max_lines_visible = 2


func _effect_stat_size() -> int:
	return 14 if _compact and not _accessibility_mode else 16


func _effect_value_size() -> int:
	return 15 if _compact and not _accessibility_mode else 16


func _preview_value(preview: Dictionary) -> String:
	var parts := _preview_value_parts(preview)
	return "%s → %s" % [parts[0], parts[1]]


func _preview_value_parts(preview: Dictionary) -> PackedStringArray:
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
	return PackedStringArray([current_text, next_text])


func _level_transition_text() -> String:
	var template := tr("UPGRADE_CARD_LEVEL_VALUE")
	var current_text := template.replace(
		"%level%",
		str(int(_offer.get("current_level", 0)))
	)
	return "%s → %d" % [
		current_text,
		int(_offer.get("next_level", 1)),
	]


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
