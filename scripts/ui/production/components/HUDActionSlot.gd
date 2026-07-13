class_name HUDActionSlot
extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Glyph = preload("res://scripts/ui/production/components/HUDGlyph.gd")

var _view_model: Dictionary = {}
var _input_label: Label
var _count_label: Label
var _name_label: Label
var _state_label: Label
var _glyph: HUDGlyph


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(92.0, 104.0)
	_build_children()
	_apply_view_model()


func configure(view_model: Dictionary) -> void:
	_view_model = view_model.duplicate(true)
	_apply_view_model()


func get_display_snapshot() -> Dictionary:
	return {
		"slot_role": String(_view_model.get("slot_role", "")),
		"label": _name_label.text if _name_label != null else "",
		"input": _input_label.text if _input_label != null else "",
		"state": _state_label.text if _state_label != null else "",
		"count": _count_label.text if _count_label != null else "",
		"available": bool(_view_model.get("available", false)),
		"active": bool(_view_model.get("active", false)),
		"cooldown": float(_view_model.get("cooldown", 0.0)),
		"charge_fraction": float(_view_model.get("charge_fraction", 0.0)),
		"rect": get_rect(),
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_children()
		queue_redraw()


func _draw() -> void:
	var role := StringName(_view_model.get("slot_role", &"basic"))
	var accent := Styles.action_accent(role)
	var available := bool(_view_model.get("available", false))
	var cooldown := float(_view_model.get("cooldown", 0.0))
	var active := bool(_view_model.get("active", false))
	var border := accent if active else Styles.OUTLINE
	var border_width := 2 if active else 1
	var background := Color(Styles.SURFACE_RAISED, 0.97 if available else 0.76)
	draw_style_box(
		Styles.panel_style(background, border, border_width),
		Rect2(Vector2.ZERO, size)
	)

	var badge_width := minf(maxf(_input_label.get_minimum_size().x + 10.0, 24.0), size.x - 28.0)
	draw_style_box(
		Styles.panel_style(Color("11171a"), Color(accent, 0.78), 1),
		Rect2(5.0, 5.0, badge_width, 18.0)
	)

	if not available or cooldown > 0.05:
		draw_rect(Rect2(1.0, 24.0, size.x - 2.0, size.y - 25.0), Color("101518a8"))
		if not available:
			draw_line(
				Vector2(8.0, size.y * 0.58),
				Vector2(size.x - 8.0, size.y * 0.35),
				Color(Styles.TEXT_MUTED, 0.52),
				2.0,
				true
			)

	var charge := clampf(float(_view_model.get("charge_fraction", 0.0)), 0.0, 1.0)
	if charge > 0.0:
		var rail := Rect2(5.0, size.y - 39.0, size.x - 10.0, 3.0)
		draw_rect(rail, Color(Styles.OUTLINE, 0.72))
		draw_rect(Rect2(rail.position, Vector2(rail.size.x * charge, rail.size.y)), accent)


func _build_children() -> void:
	_glyph = Glyph.new()
	_glyph.name = "ActionGlyph"
	add_child(_glyph)

	_input_label = _new_label("InputBadge", 12, Styles.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_count_label = _new_label("Count", 12, Styles.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_name_label = _new_label("ActionName", 12, Styles.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.max_lines_visible = 2
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_state_label = _new_label("ActionState", 13, Styles.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_layout_children()


func _new_label(
	label_name: String,
	font_size: int,
	color: Color,
	alignment: HorizontalAlignment
) -> Label:
	var label := Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(label, font_size, color)
	add_child(label)
	return label


func _layout_children() -> void:
	if _glyph == null:
		return
	_glyph.position = Vector2((size.x - 32.0) * 0.5, 22.0)
	_glyph.size = Vector2(32.0, 32.0)
	_input_label.position = Vector2(5.0, 5.0)
	_input_label.size = Vector2(size.x - 34.0, 18.0)
	_count_label.position = Vector2(size.x - 29.0, 5.0)
	_count_label.size = Vector2(24.0, 18.0)
	_state_label.position = Vector2(4.0, 26.0)
	_state_label.size = Vector2(size.x - 8.0, 30.0)
	_name_label.position = Vector2(4.0, size.y - 35.0)
	_name_label.size = Vector2(size.x - 8.0, 33.0)


func _apply_view_model() -> void:
	if _input_label == null:
		return
	var role := StringName(_view_model.get("slot_role", &"basic"))
	var accent := Styles.action_accent(role)
	var available := bool(_view_model.get("available", false))
	var cooldown := maxf(float(_view_model.get("cooldown", 0.0)), 0.0)
	var charge := clampf(float(_view_model.get("charge_fraction", 0.0)), 0.0, 1.0)
	var charges := int(_view_model.get("charges", -1))

	_input_label.text = String(_view_model.get("input", "--"))
	_name_label.text = String(_view_model.get("label", role)).to_upper()
	_count_label.text = "x%d" % charges if charges >= 0 else ""
	_state_label.text = ""
	if not available:
		_state_label.text = "EMPTY" if role == &"consumable" else "LOCKED"
	elif cooldown > 0.05:
		_state_label.text = "%.1fs" % cooldown
	elif charge > 0.0:
		_state_label.text = "%d%%" % int(round(charge * 100.0))

	_state_label.add_theme_color_override("font_color", accent if charge > 0.0 else Styles.TEXT)
	_glyph.configure(role, accent, not available or cooldown > 0.05)
	_glyph.visible = _state_label.text.is_empty()
	_layout_children()
	queue_redraw()
