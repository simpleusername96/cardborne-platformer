class_name RewardChoiceCard
extends Button

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Assets = preload("res://scripts/ui/production/ProductionUIAssets.gd")
const GlyphScript = preload("res://scripts/ui/production/components/RewardChoiceGlyph.gd")
const Text = preload("res://scripts/ui/localization/LocalizedText.gd")

var choice_id: StringName

var _accent: Color = Styles.CYAN
var _action_text := "CHOOSE"
var _base_enabled := true
var _selected := false
var _pointer_inside := false
var _built := false
var _pending_view: Dictionary = {}

var _category_label: Label
var _rarity_label: Label
var _glyph: Control
var _art: TextureRect
var _art_asset_id: StringName
var _surface: ColorRect
var _focus_marker: ColorRect
var _title_label: Label
var _description_label: Label
var _value_label: Label
var _footer_label: Label
var _state_label: Label
var _content: VBoxContainer
var _glyph_center: CenterContainer
var _margin: MarginContainer


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	_build_content()
	focus_entered.connect(_refresh_state)
	focus_exited.connect(_refresh_state)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_apply_responsive_layout)
	var localization := get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.connect(&"locale_changed", _on_locale_changed)
	_built = true
	if not _pending_view.is_empty():
		_apply_view(_pending_view)
	_apply_responsive_layout()
	_refresh_state()


func configure_choice(identifier: StringName, view: Dictionary) -> void:
	choice_id = identifier
	_pending_view = view.duplicate(true)
	if _built:
		_apply_view(_pending_view)


func set_commit_pending(is_selected: bool) -> void:
	_selected = is_selected
	disabled = true
	_refresh_state()


func restore_interaction() -> void:
	_selected = false
	disabled = not _base_enabled
	_refresh_state()


func mark_committed(is_selected: bool) -> void:
	_selected = is_selected
	disabled = true
	_refresh_state()


func get_visible_copy() -> String:
	return "\n".join([
		_category_label.text,
		_rarity_label.text,
		_title_label.text,
		_description_label.text,
		_value_label.text,
		_footer_label.text,
		_state_label.text,
	])


func get_art_asset_id() -> StringName:
	return _art_asset_id


func get_art_texture_path() -> String:
	return _art.texture.resource_path if _art != null and _art.texture != null else ""


func has_visible_text_overflow() -> bool:
	for label in [
		_category_label,
		_rarity_label,
		_title_label,
		_description_label,
		_value_label,
		_footer_label,
		_state_label,
	]:
		if label.visible:
			if label.size.y + 0.5 < label.get_minimum_size().y:
				return true
			if label.get_line_count() > label.get_visible_line_count():
				return true
	return false


func _build_content() -> void:
	Styles.apply_theme(self)
	theme_type_variation = &"ChoiceButton"
	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color",
		"font_disabled_color",
	]:
		add_theme_color_override(color_name, Color.TRANSPARENT)
	add_theme_font_size_override("font_size", 1)
	_surface = ColorRect.new()
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.color = Styles.SURFACE
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_focus_marker = ColorRect.new()
	_focus_marker.name = "FocusMarker"
	_focus_marker.anchor_bottom = 1.0
	_focus_marker.offset_right = 4.0
	_focus_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_marker.visible = false
	add_child(_focus_marker)

	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_%s" % side, 14)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(_content)

	var meta := HBoxContainer.new()
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(meta)
	_category_label = _label(Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_category_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(_category_label)
	_rarity_label = _label(Styles.TYPE_CAPTION, _accent)
	_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(_rarity_label)

	_glyph_center = CenterContainer.new()
	_glyph_center.custom_minimum_size = Vector2(0.0, 52.0)
	_glyph_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_glyph_center)
	_art = TextureRect.new()
	_art.name = "CardIllustration"
	_art.custom_minimum_size = Vector2(96.0, 96.0)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_glyph_center.add_child(_art)
	_glyph = GlyphScript.new()
	_glyph_center.add_child(_glyph)

	_title_label = _label(24, Styles.TEXT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.max_lines_visible = 2
	_title_label.custom_minimum_size = Vector2(0.0, 50.0)
	_content.add_child(_title_label)

	_description_label = _label(Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_description_label)

	var divider := ColorRect.new()
	divider.color = Color(Styles.OUTLINE, 0.62)
	divider.custom_minimum_size = Vector2(0.0, 1.0)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(divider)

	_value_label = _label(Styles.TYPE_CAPTION, Styles.TEXT)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_value_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(footer)
	_footer_label = _label(Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_footer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_footer_label)
	_state_label = _label(Styles.TYPE_CAPTION, _accent)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(_state_label)


func _apply_view(view: Dictionary) -> void:
	_accent = view.get("accent", Styles.CYAN)
	_action_text = String(view.get("action", "CHOOSE")).to_upper()
	_base_enabled = bool(view.get("enabled", true))
	text = String(view.get("title", "Reward"))
	tooltip_text = "%s. %s. %s" % [
		text,
		String(view.get("description", "")),
		String(view.get("value", "")),
	]
	_category_label.text = String(view.get("category", "REWARD")).to_upper()
	_rarity_label.text = String(view.get("rarity", "")).to_upper()
	_rarity_label.visible = not _rarity_label.text.is_empty()
	_title_label.text = text
	_description_label.text = String(view.get("description", ""))
	_value_label.text = String(view.get("value", ""))
	_value_label.visible = not _value_label.text.is_empty()
	_footer_label.text = String(view.get("footer", "")).to_upper()
	_footer_label.visible = not _footer_label.text.is_empty()
	_art_asset_id = Assets.asset_id_for_owner(choice_id)
	_art.texture = Assets.texture(_art_asset_id) if _art_asset_id != &"" else null
	_art.visible = _art.texture != null
	_glyph.visible = not _art.visible
	_glyph.call("configure", StringName(view.get("glyph", &"card")), _accent)
	disabled = not _base_enabled
	_selected = false
	_refresh_state()


func _refresh_state() -> void:
	if not _built:
		return
	var highlighted := has_focus() or _pointer_inside or _selected
	# Opaque choice surfaces keep backdrop marks from reading as reward mechanics.
	var background := Styles.SURFACE_RAISED if highlighted else Styles.SURFACE
	_surface.color = background
	_focus_marker.color = _accent
	_focus_marker.visible = highlighted
	_rarity_label.add_theme_color_override("font_color", _accent)
	_state_label.add_theme_color_override(
		"font_color",
		_accent if highlighted and not disabled else Styles.TEXT_MUTED
	)
	if _selected:
		_state_label.text = _t("SELECTED")
	elif disabled:
		_state_label.text = _t("UNAVAILABLE" if not _base_enabled else "WAITING")
	elif has_focus() or _pointer_inside:
		_state_label.text = _t("FOCUSED")
	else:
		_state_label.text = _action_text


func _on_mouse_entered() -> void:
	_pointer_inside = true
	_refresh_state()


func _on_mouse_exited() -> void:
	_pointer_inside = false
	_refresh_state()


func _on_locale_changed(_locale: String) -> void:
	_refresh_state()


func _apply_responsive_layout() -> void:
	if not _built:
		return
	var compact := size.y < 390.0 or size.x < 320.0
	var inset := 10 if compact else 14
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_%s" % side, inset)
	_content.add_theme_constant_override("separation", 4 if compact else 6)
	_glyph_center.custom_minimum_size.y = 96.0 if compact else 120.0
	_art.custom_minimum_size = Vector2(92.0, 92.0) if compact else Vector2(116.0, 116.0)
	_title_label.add_theme_font_size_override("font_size", 21 if compact else 24)
	_title_label.custom_minimum_size.y = 44.0 if compact else 50.0
	_description_label.add_theme_font_size_override("font_size", Styles.TYPE_CAPTION)
	_value_label.add_theme_font_size_override("font_size", Styles.TYPE_CAPTION)


func _t(source: Variant, values: Array = []) -> String:
	return Text.resolve(self, source, values)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Styles.configure_label(label, font_size, color)
	return label
