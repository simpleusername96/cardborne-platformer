extends SceneTree

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const ThemeResource: Theme = preload("res://art/ui/production/production_ui_theme.tres")

const THEME_PATH := "res://art/ui/production/production_ui_theme.tres"
const VARIATIONS := {
	&"PrimaryButton": &"Button",
	&"SecondaryButton": &"Button",
	&"DangerButton": &"Button",
	&"IconButton": &"Button",
	&"ChoiceButton": &"Button",
	&"ActionSlot": &"PanelContainer",
	&"PromptBadge": &"PanelContainer",
	&"FlatPanel": &"PanelContainer",
	&"ModalSurface": &"PanelContainer",
	&"HealthMeter": &"ProgressBar",
	&"ResourceMeter": &"ProgressBar",
	&"BossMeter": &"ProgressBar",
	&"SectionTitle": &"Label",
	&"SecondaryText": &"Label",
	&"NumericValue": &"Label",
}
const BUTTON_VARIATIONS := [
	&"PrimaryButton",
	&"SecondaryButton",
	&"DangerButton",
	&"IconButton",
	&"ChoiceButton",
]
const BUTTON_STYLES := [&"normal", &"hover", &"pressed", &"focus", &"disabled"]

var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(
		String(ProjectSettings.get_setting("gui/theme/custom", "")) == THEME_PATH,
		"project must install the production Theme globally"
	)
	_expect(ThemeResource.default_font_size == Styles.TYPE_BODY, "Theme body type must be 18px")
	for variation in VARIATIONS:
		_expect(
			ThemeResource.get_type_variation_base(variation) == VARIATIONS[variation],
			"%s must inherit %s" % [variation, VARIATIONS[variation]]
		)

	for variation in BUTTON_VARIATIONS:
		for style_name in BUTTON_STYLES:
			var box := ThemeResource.get_stylebox(style_name, variation)
			_expect(box is StyleBoxFlat, "%s %s must use StyleBoxFlat" % [variation, style_name])
			if box is StyleBoxFlat:
				_validate_flat_box(
					box as StyleBoxFlat,
					"%s %s" % [variation, style_name],
					style_name == &"focus" or (variation == &"ChoiceButton" and style_name == &"pressed")
				)

	for variation in [&"ActionSlot", &"FlatPanel", &"ModalSurface"]:
		var panel_box := ThemeResource.get_stylebox(&"panel", variation)
		_expect(panel_box is StyleBoxFlat, "%s must use a flat panel" % variation)
		if panel_box is StyleBoxFlat:
			_validate_flat_box(panel_box as StyleBoxFlat, String(variation), false)
	var prompt_box := ThemeResource.get_stylebox(&"panel", &"PromptBadge")
	_expect(prompt_box is StyleBoxFlat, "PromptBadge must use a flat panel")
	if prompt_box is StyleBoxFlat:
		_validate_flat_box(prompt_box as StyleBoxFlat, "PromptBadge", true)

	for variation in [&"HealthMeter", &"ResourceMeter", &"BossMeter"]:
		for style_name in [&"background", &"fill"]:
			var meter_box := ThemeResource.get_stylebox(style_name, variation)
			_expect(meter_box is StyleBoxFlat, "%s %s must be flat" % [variation, style_name])
			if meter_box is StyleBoxFlat:
				_validate_flat_box(meter_box as StyleBoxFlat, "%s %s" % [variation, style_name], false)

	var fallback := Styles.panel_style()
	_validate_flat_box(fallback, "panel_style fallback", false)
	_validate_flat_box(Styles.flat_style(), "flat_style fallback", false)
	var marked := Styles.panel_style(Styles.SURFACE_RAISED, Styles.CYAN, 3)
	_validate_flat_box(marked, "panel_style marker", true)
	_expect(marked.border_width_left == 3, "panel_style marker must use the reserved left lane")

	var primary := Button.new()
	Styles.apply_button(primary, Styles.AMBER)
	_expect(primary.theme == ThemeResource, "semantic buttons must own the production Theme")
	_expect(primary.theme_type_variation == &"PrimaryButton", "primary action variation must resolve")
	_expect(primary.custom_minimum_size.y >= Styles.TARGET_HEIGHT, "primary action must remain 48px high")
	var secondary := Button.new()
	Styles.apply_button(secondary, Styles.MOSS, true)
	_expect(secondary.theme_type_variation == &"SecondaryButton", "quiet action variation must resolve")
	var danger := Button.new()
	Styles.apply_button(danger, Styles.CORAL, true)
	_expect(danger.theme_type_variation == &"DangerButton", "danger action variation must resolve")
	var choice := Button.new()
	Styles.apply_choice_button(choice)
	_expect(choice.theme_type_variation == &"ChoiceButton", "choice variation must resolve")

	var modal := CenteredModalShell.new()
	_expect(modal.theme == ThemeResource, "shared modal must own the production Theme")
	_expect(modal.panel.theme_type_variation == &"ModalSurface", "shared modal panel must use ModalSurface")
	modal.free()
	primary.free()
	secondary.free()
	danger.free()
	choice.free()
	_finish()


func _validate_flat_box(box: StyleBoxFlat, label: String, allow_left_marker: bool) -> void:
	_expect(box.corner_radius_top_left == 0, "%s must have zero top-left radius" % label)
	_expect(box.corner_radius_top_right == 0, "%s must have zero top-right radius" % label)
	_expect(box.corner_radius_bottom_left == 0, "%s must have zero bottom-left radius" % label)
	_expect(box.corner_radius_bottom_right == 0, "%s must have zero bottom-right radius" % label)
	_expect(box.border_width_top == 0, "%s must not draw a top outline" % label)
	_expect(box.border_width_right == 0, "%s must not draw a right outline" % label)
	_expect(box.border_width_bottom == 0, "%s must not draw a bottom outline" % label)
	_expect(
		box.border_width_left <= 4 if allow_left_marker else box.border_width_left == 0,
		"%s may only use the reserved left marker lane" % label
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PRODUCTION_UI_THEME_OK variations=%d buttons=5 panels=4 meters=3 marker=left" % VARIATIONS.size())
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
