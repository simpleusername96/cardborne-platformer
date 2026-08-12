class_name VehicleUpgradeChoiceRow
extends Button

## One compact horizontal upgrade offer. The parent owns confirmation and the
## row only presents one frozen gameplay snapshot.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const WIDE_SIZE := Vector2(820.0, 140.0)
const COMPACT_SIZE := Vector2(540.0, 112.0)
const LARGE_SIZE := Vector2(900.0, 152.0)
const ACCESSIBILITY_SIZE := Vector2(900.0, 210.0)

var _offer: Dictionary = {}
var _selected := false
var _compact := false
var _large := false
var _accessibility_mode := false
var _margin: MarginContainer
var _content: HBoxContainer
var _art_lane: CenterContainer
var _artwork: TextureRect
var _copy: VBoxContainer
var _category: Label
var _title: Label
var _summary: Label
var _effects: HBoxContainer
var _level: Label


func _ready() -> void:
	text = ""
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	theme_type_variation = &"SelectableButton"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()
	_apply_layout_profile()
	if not _offer.is_empty():
		_refresh()


func _build() -> void:
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)
	_content = HBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	_margin.add_child(_content)
	_art_lane = CenterContainer.new()
	_art_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_art_lane)
	_artwork = TextureRect.new()
	_artwork.name = "UpgradeBodyArtwork"
	_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_lane.add_child(_artwork)
	_copy = VBoxContainer.new()
	_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	_copy.add_theme_constant_override("separation", 2)
	_content.add_child(_copy)
	_category = _label(13, Art.SYSTEM)
	_category.name = "CategoryLabel"
	_category.theme_type_variation = &"MetricLabel"
	_copy.add_child(_category)
	_title = _label(22, Art.TEXT_PRIMARY)
	_title.name = "TitleLabel"
	_title.theme_type_variation = &"TitleLabel"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.max_lines_visible = 1
	_copy.add_child(_title)
	_summary = _label(15, Art.TEXT_PRIMARY)
	_summary.name = "SummaryLabel"
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.max_lines_visible = 1
	_copy.add_child(_summary)
	_effects = HBoxContainer.new()
	_effects.add_theme_constant_override("separation", 16)
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_copy.add_child(_effects)
	_level = _label(16, Art.MINT_SOFT)
	_level.name = "LevelLabel"
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level.custom_minimum_size.x = 112.0
	_content.add_child(_level)


func set_offer(offer: Dictionary) -> void:
	_offer = offer.duplicate(true)
	set_meta(&"upgrade_id", StringName(_offer.get("id", &"")))
	if is_node_ready():
		_refresh()


func set_selected_state(value: bool) -> void:
	_selected = value
	theme_type_variation = &"SelectedSelectableButton" if value else &"SelectableButton"


func set_compact_mode(value: bool) -> void:
	_compact = value
	_large = false
	if is_node_ready():
		_apply_layout_profile()
		_refresh()


func set_large_mode(value: bool) -> void:
	_large = value and not _compact and not _accessibility_mode
	if is_node_ready():
		_apply_layout_profile()
		_refresh()


func set_accessibility_mode(enabled: bool) -> void:
	_accessibility_mode = enabled
	if enabled:
		_large = false
	if is_node_ready():
		_apply_layout_profile()
		_refresh()


func offer_id() -> StringName:
	return StringName(_offer.get("id", &""))


func _apply_layout_profile() -> void:
	var artwork_size := Vector2(88.0, 88.0)
	var margin := 14
	var category_size := 13
	var title_size := 22
	var summary_size := 15
	var level_size := 16
	if _accessibility_mode:
		custom_minimum_size = ACCESSIBILITY_SIZE
		artwork_size = Vector2(150.0, 150.0)
		margin = 20
		category_size = 18
		title_size = 30
		summary_size = 22
		level_size = 22
		_summary.max_lines_visible = 2
	elif _large:
		custom_minimum_size = LARGE_SIZE
		artwork_size = Vector2(104.0, 104.0)
		margin = 18
		category_size = 15
		title_size = 25
		summary_size = 17
		level_size = 18
		_summary.max_lines_visible = 1
	elif _compact:
		custom_minimum_size = COMPACT_SIZE
		artwork_size = Vector2(72.0, 72.0)
		margin = 10
		category_size = 12
		title_size = 18
		summary_size = 13
		level_size = 14
		_summary.max_lines_visible = 1
	else:
		custom_minimum_size = WIDE_SIZE
		_summary.max_lines_visible = 1
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		_margin.add_theme_constant_override(side, margin)
	_artwork.custom_minimum_size = artwork_size
	_artwork.size = artwork_size
	Factory.apply_font_size(_category, category_size)
	Factory.apply_font_size(_title, title_size)
	Factory.apply_font_size(_summary, summary_size)
	Factory.apply_font_size(_level, level_size)


func _refresh() -> void:
	if _offer.is_empty():
		return
	_category.text = tr(String(_offer.get("category_key", "")))
	_title.text = tr(String(_offer.get("title_key", "")))
	_summary.text = tr(String(_offer.get("description_key", ""))).strip_edges()
	_summary.visible = not _summary.text.is_empty()
	_level.text = _level_transition_text()
	_artwork.texture = SemanticAssets.texture(StringName(_offer.get("artwork_asset_id", &"")))
	for child in _effects.get_children():
		_effects.remove_child(child)
		child.queue_free()
	var accessible_effects := PackedStringArray()
	for preview_variant in Array(_offer.get("effect_rows", [])).slice(0, 2):
		var preview := Dictionary(preview_variant)
		var phrase := "%s %s" % [
			tr(String(preview.get("stat_key", ""))),
			_preview_value(preview),
		]
		var effect_size := 18 if _accessibility_mode else (16 if _large else (13 if _compact else 14))
		var label := _label(effect_size, Art.MINT_SOFT)
		label.name = "EffectLabel%d" % (_effects.get_child_count() + 1)
		label.text = phrase
		label.max_lines_visible = 1
		_effects.add_child(label)
		accessible_effects.append(phrase)
	accessibility_name = " · ".join(PackedStringArray([
		_category.text, _title.text, _level.text,
		"; ".join(accessible_effects), _summary.text,
	]))


func _preview_value(preview: Dictionary) -> String:
	var parts := _preview_value_parts(preview)
	return parts[1] if not bool(preview.get("show_current", true)) else "%s → %s" % [parts[0], parts[1]]


func _preview_value_parts(preview: Dictionary) -> PackedStringArray:
	var operation := String(preview.get("operation", "add"))
	var unit := String(preview.get("display_unit", "none"))
	var current := float(preview.get("current", 0.0))
	var next := float(preview.get("next", 0.0))
	if unit == "percent":
		return PackedStringArray([_percent_text(current), _percent_text(next)])
	if unit == "seconds":
		return PackedStringArray(["%ss" % _plain_number(current), "%ss" % _plain_number(next)])
	if operation == "multiply":
		return PackedStringArray(["×%.2f" % current, "×%.2f" % next])
	if bool(preview.get("absolute_value", false)):
		return PackedStringArray([_plain_number(current), _plain_number(next)])
	return PackedStringArray(["%+.0f" % current, "%+.0f" % next])


func _plain_number(value: float) -> String:
	return str(roundi(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _percent_text(value: float) -> String:
	return "%d%%" % roundi(value) if is_equal_approx(value, roundf(value)) else "%.1f%%" % value


func _level_transition_text() -> String:
	var current := tr("UPGRADE_CARD_LEVEL_VALUE").replace(
		"%level%", str(int(_offer.get("current_level", 0)))
	)
	return "%s → %d" % [current, int(_offer.get("next_level", 1))]


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	Factory.apply_font_size(label, font_size)
	return label


func debug_contract() -> Dictionary:
	return {
		"structured":true, "visible":visible,
		"minimum_size":custom_minimum_size, "actual_size":size,
		"value_rows":_effects.get_child_count() + 1,
		"effect_rows":_effects.get_child_count(), "has_scroll":false,
		"pip_slots":0, "stage_pip_count":0,
		"selected":_selected, "compact":_compact, "large":_large,
		"accessibility_mode":_accessibility_mode,
		"dossier_split":false, "vertical_dossier":false,
		"body_divider_count":0, "description_in_comparison":false,
		"description_visible":_summary.visible,
		"summary_color":_summary.get_theme_color("font_color"),
		"footer_visible":false,
		"type_sizes":{
			"category":_category.get_theme_font_size("font_size"),
			"level":_level.get_theme_font_size("font_size"),
			"title":_title.get_theme_font_size("font_size"),
			"summary":_summary.get_theme_font_size("font_size"),
		},
		"summary_max_lines":_summary.max_lines_visible,
		"header_art_count":0, "body_art_count":1, "category_badge_count":0,
		"level_visible":_level.visible, "level_text":_level.text,
		"current_level":int(_offer.get("current_level", 0)),
		"next_level":int(_offer.get("next_level", 1)),
		"max_level":int(_offer.get("max_level", 1)),
		"body_art_size":_artwork.custom_minimum_size,
		"body_art_asset_id":StringName(_offer.get("artwork_asset_id", &"")),
		"body_order":["art", "category/title/summary/effects", "level"],
		"state_cues":{
			"normal_flat":get_theme_stylebox(&"normal") is StyleBoxFlat,
			"focus_flat":get_theme_stylebox(&"focus") is StyleBoxFlat,
			"selected_corner":true, "focus_corner":true, "disabled_corner":true,
		},
		"mouse_passthrough":_category.mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}


func debug_geometry_contract() -> Dictionary:
	var labels: Array[Dictionary] = []
	for node in find_children("*", "Label", true, false):
		var label := node as Label
		if label.visible:
			labels.append(_label_geometry(label))
	return {
		"rect":get_global_rect(), "content_rect":_content.get_global_rect(),
		"labels":labels,
		"artwork":{
			"asset_id":StringName(_offer.get("artwork_asset_id", &"")),
			"texture_loaded":_artwork.texture != null,
			"rect":_artwork.get_global_rect(),
		},
		"selected":_selected, "disabled":disabled,
		"summary_max_lines":_summary.max_lines_visible,
	}


func _label_geometry(label: Label) -> Dictionary:
	var label_rect := label.get_global_rect()
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var break_flags := TextServer.BREAK_MANDATORY
	if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
		break_flags |= TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var glyph_size := font.get_multiline_string_size(
		label.text, label.horizontal_alignment, label.size.x, font_size, -1, break_flags
	)
	var glyph_position := label_rect.position
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		glyph_position.x += label_rect.size.x - glyph_size.x
	if label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
		glyph_position.y += (label_rect.size.y - glyph_size.y) * 0.5
	return {
		"name":label.name, "text":label.text, "rect":label_rect,
		"glyph_rect":Rect2(glyph_position, glyph_size), "glyph_size":glyph_size,
		"font_size":font_size, "line_count":label.get_line_count(),
		"visible_line_count":label.get_visible_line_count(),
	}
