class_name ProductionUIStyles
extends RefCounted

const BACKGROUND := Color("12171a")
const SURFACE := Color("1c2428")
const SURFACE_RAISED := Color("263136")
const TEXT := Color("f0f1e8")
const TEXT_MUTED := Color("a8b4ae")
const MOSS := Color("6f8f62")
const CYAN := Color("62a9b5")
const AMBER := Color("d4a33f")
const CORAL := Color("d9654f")
const OUTLINE := Color("526068")
const HEALTH := Color("c54d45")
const HEALTH_LOW := Color("e66b52")
const XP := Color("62bdc7")
const SCRAP := Color("b88a59")
const THREAD := Color("6fd5d1")
const RESIDUE := Color("75b96c")
const BOSS_CORE := Color("aa89cf")


static func panel_style(
	background: Color = SURFACE,
	border: Color = OUTLINE,
	border_width: int = 1
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	return style


static func apply_button(button: Button, accent: Color = CYAN, quiet: bool = false) -> void:
	var normal_bg := Color(SURFACE, 0.90) if quiet else SURFACE_RAISED
	button.add_theme_stylebox_override("normal", panel_style(normal_bg, OUTLINE))
	button.add_theme_stylebox_override("hover", panel_style(SURFACE_RAISED.lightened(0.08), accent))
	button.add_theme_stylebox_override("pressed", panel_style(SURFACE_RAISED.darkened(0.08), accent, 2))
	button.add_theme_stylebox_override("focus", panel_style(SURFACE_RAISED, accent, 2))
	button.add_theme_stylebox_override("disabled", panel_style(Color(SURFACE, 0.55), Color(OUTLINE, 0.45)))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED, 0.55))
	button.add_theme_font_size_override("font_size", 17)


static func apply_character_card(button: Button, accent: Color, selected: bool) -> void:
	var border := accent if selected else OUTLINE
	var width := 3 if selected else 1
	button.add_theme_stylebox_override("normal", panel_style(Color(SURFACE, 0.96), border, width))
	button.add_theme_stylebox_override("hover", panel_style(SURFACE_RAISED, accent, 2))
	button.add_theme_stylebox_override("pressed", panel_style(SURFACE_RAISED.darkened(0.06), accent, 3))
	button.add_theme_stylebox_override("focus", panel_style(Color(SURFACE, 0.96), accent, 3))


static func configure_label(label: Label, size: int, color: Color = TEXT) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func action_accent(slot_role: StringName) -> Color:
	return {
		&"basic": AMBER,
		&"attack": AMBER,
		&"melee": AMBER,
		&"ranged": CYAN,
		&"guard": CYAN,
		&"spirit": MOSS,
		&"potion": Color("63b987"),
		&"heavy": Color("d8894b"),
		&"skill_1": CYAN,
		&"skill_2": MOSS,
		&"skill_3": Color("c5b45c"),
		&"consumable": Color("63b987"),
	}.get(slot_role, CYAN)


static func class_accent(profile_id: StringName) -> Color:
	return {
		&"warrior": AMBER,
		&"archer": CYAN,
		&"assassin": Color("c088cf"),
	}.get(profile_id, CYAN)
