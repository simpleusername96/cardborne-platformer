class_name VehicleUiComponentFactory
extends RefCounted

## Shared construction primitives for runtime UI components. Screen hierarchy,
## state, copy, and signals remain inside each owning component.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ModalSurface = preload("res://scripts/ui/vehicle_modal_surface.gd")

const SURFACE_MODAL := &"modal"
const SURFACE_CONTENT := &"content"
const SURFACE_HUD := &"hud"
const SURFACE_TOAST := &"toast"
const COMMAND_PRIMARY := &"primary"
const COMMAND_SECONDARY := &"secondary"
const COMMAND_DANGER := &"danger"
const METER_HEALTH := &"health"
const METER_RESOURCE := &"resource"
const METER_BOSS := &"boss"
const METER_COOLDOWN := &"cooldown"
const METER_SUPPORT := &"support"

const SURFACE_VARIATIONS := {
	SURFACE_MODAL: &"ModalSurface",
	SURFACE_CONTENT: &"ContentSurface",
	SURFACE_HUD: &"HudSurface",
	SURFACE_TOAST: &"ToastSurface",
	&"ModalSurface": &"ModalSurface",
	&"ModalSurfaceCompact": &"ModalSurfaceCompact",
	&"ContentSurface": &"ContentSurface",
	&"HudSurface": &"HudSurface",
	&"ToastSurface": &"ToastSurface",
	&"FlatPanel": &"ContentSurface",
	&"HudStatusGroup": &"HudSurface",
	&"HudHealthResource": &"HudSurface",
	&"HudObjectiveBoss": &"HudSurface",
	&"HudMinimapTarget": &"HudSurface",
	&"HudActionRail": &"HudSurface",
	&"HudToast": &"ToastSurface",
	&"FamilyBadge": &"ContentSurface",
	&"SummaryBand": &"ContentSurface",
	&"ContentInset": &"ContentSurface",
	&"ContentSummary": &"ContentSurface",
}

const COMMAND_VARIATIONS := {
	COMMAND_PRIMARY: &"PrimaryButton",
	COMMAND_SECONDARY: &"SecondaryButton",
	COMMAND_DANGER: &"DangerButton",
	&"PrimaryButton": &"PrimaryButton",
	&"SecondaryButton": &"SecondaryButton",
	&"DangerButton": &"DangerButton",
	&"TertiaryDangerButton": &"DangerButton",
	&"ChoiceButton": &"SelectableButton",
	&"SelectedChoiceButton": &"SelectedSelectableButton",
	&"SelectedRailButton": &"SelectedSelectableButton",
	&"UpgradeChoiceCard": &"SelectableButton",
	&"SelectedUpgradeChoiceCard": &"SelectedSelectableButton",
}

const METER_VARIATIONS := {
	METER_HEALTH: &"HealthMeter",
	METER_RESOURCE: &"ResourceMeter",
	METER_BOSS: &"BossMeter",
	METER_COOLDOWN: &"CooldownMeter",
	METER_SUPPORT: &"SupportMeter",
	&"HealthMeter": &"HealthMeter",
	&"ResourceMeter": &"ResourceMeter",
	&"BossMeter": &"BossMeter",
	&"CooldownMeter": &"CooldownMeter",
	&"SupportMeter": &"SupportMeter",
}


static func surface(
	role: StringName,
	minimum_size := Vector2.ZERO
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = _mapped_variation(
		SURFACE_VARIATIONS,
		role,
		&"ContentSurface",
		"surface"
	)
	panel.custom_minimum_size = minimum_size
	return panel


static func modal_surface(minimum_size: Vector2) -> PanelContainer:
	var panel := ModalSurface.new()
	panel.theme_type_variation = &"ModalSurface"
	panel.custom_minimum_size = minimum_size
	return panel


static func flat_panel() -> PanelContainer:
	# Temporary compatibility entry. HUD migration removes its final consumers.
	return surface(SURFACE_HUD)


static func label(
	text: String,
	font_size: int,
	color: Color = Art.IVORY_BRIGHT
) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", color)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control


static func command_button(text: String, role: StringName) -> Button:
	var button := Button.new()
	button.theme_type_variation = _mapped_variation(
		COMMAND_VARIATIONS,
		role,
		&"SecondaryButton",
		"command"
	)
	button.text = text
	button.custom_minimum_size.y = 44.0
	button.focus_mode = Control.FOCUS_ALL
	return button


static func selectable_button(text: String, selected := false) -> Button:
	var button := command_button(
		text,
		&"SelectedSelectableButton" if selected else &"SelectableButton"
	)
	button.toggle_mode = true
	button.button_pressed = selected
	return button


static func text_row(
	label_text: String,
	value_text: String,
	options := {}
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(
		"separation",
		int(options.get("separation", 12))
	)
	var row_label := label(
		label_text,
		int(options.get("label_size", 15)),
		Color(options.get("label_color", Art.TEXT_MUTED))
	)
	row_label.custom_minimum_size.x = float(options.get("label_min_width", 148.0))
	row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(row_label)
	var value := label(
		value_text,
		int(options.get("value_size", 15)),
		Color(options.get("value_color", Art.TEXT_PRIMARY))
	)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value)
	return row


static func section_heading(text: String) -> Label:
	var heading := label(text, 22, Art.MUSTARD)
	heading.theme_type_variation = &"SectionLabel"
	return heading


static func preview_well(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PreviewFrame"
	panel.custom_minimum_size = minimum_size
	return panel


static func meter(role: StringName) -> ProgressBar:
	var control := ProgressBar.new()
	control.theme_type_variation = _mapped_variation(
		METER_VARIATIONS,
		role,
		&"ResourceMeter",
		"meter"
	)
	control.show_percentage = false
	return control


static func _mapped_variation(
	roles: Dictionary,
	role: StringName,
	fallback: StringName,
	context: String
) -> StringName:
	if roles.has(role):
		return StringName(roles[role])
	push_error("Unknown shared UI %s role: %s" % [context, role])
	return fallback
