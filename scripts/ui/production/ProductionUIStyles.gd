class_name ProductionUIStyles
extends RefCounted

const PRODUCTION_THEME: Theme = preload("res://art/ui/production/production_ui_theme.tres")

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

# Shared desktop-web type and target scale. Individual screens may promote a
# label, but essential copy must not fall below the caption size.
const TYPE_CAPTION := 16
const TYPE_BODY := 18
const TYPE_BUTTON := 20
const TYPE_SECTION := 22
const TYPE_TITLE := 32
const TYPE_HERO := 52
const TARGET_HEIGHT := 48


static func panel_style(
	background: Color = SURFACE,
	marker: Color = OUTLINE,
	marker_width: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	# Reserve the marker lane so focus/selection never shifts child layout.
	style.content_margin_left = 4.0
	style.border_color = marker
	style.set_border_width_all(0)
	style.border_width_left = clampi(marker_width, 0, 4)
	style.set_corner_radius_all(0)
	return style


static func flat_style(background: Color = SURFACE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	return style


static func apply_theme(control: Control) -> void:
	control.theme = PRODUCTION_THEME


static func apply_panel(
	panel: PanelContainer,
	variation: StringName = &"FlatPanel"
) -> void:
	apply_theme(panel)
	panel.theme_type_variation = variation
	panel.remove_theme_stylebox_override(&"panel")


static func apply_button(button: Button, accent: Color = CYAN, quiet: bool = false) -> void:
	apply_theme(button)
	button.theme_type_variation = (
		&"DangerButton"
		if accent == CORAL
		else (&"SecondaryButton" if quiet else &"PrimaryButton")
	)
	_clear_button_visual_overrides(button)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, TARGET_HEIGHT)


static func apply_character_card(button: Button, _accent: Color, selected: bool) -> void:
	apply_choice_button(button)
	button.button_pressed = selected


static func apply_choice_button(button: Button) -> void:
	apply_theme(button)
	button.theme_type_variation = &"ChoiceButton"
	_clear_button_visual_overrides(button)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, TARGET_HEIGHT)


static func _clear_button_visual_overrides(button: Button) -> void:
	for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.remove_theme_stylebox_override(style_name)
	for color_name in [
		&"font_color",
		&"font_hover_color",
		&"font_pressed_color",
		&"font_focus_color",
		&"font_disabled_color",
	]:
		button.remove_theme_color_override(color_name)


static func configure_label(label: Label, size: int, color: Color = TEXT) -> void:
	apply_theme(label)
	var variation := &""
	if size == TYPE_SECTION and color == AMBER:
		variation = &"SectionTitle"
	elif size == TYPE_CAPTION and color == TEXT_MUTED:
		variation = &"SecondaryText"
	elif size == TYPE_BUTTON and color == TEXT:
		variation = &"NumericValue"
	label.theme_type_variation = variation
	if variation == &"":
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", color)
	else:
		label.remove_theme_font_size_override(&"font_size")
		label.remove_theme_color_override(&"font_color")


static func action_accent(slot_role: StringName) -> Color:
	return {
		&"basic": AMBER,
		&"attack": AMBER,
		&"melee": AMBER,
		&"ranged": CYAN,
		&"guard": CYAN,
		&"spirit": MOSS,
		&"potion": Color("63b987"),
		&"consumable": Color("63b987"),
	}.get(slot_role, CYAN)


static func hero_accent() -> Color:
	return CYAN
