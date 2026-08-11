extends SceneTree

## Structural gate for the shared code-native UI component foundation.

const THEME_PATH := "res://art/visuals/production/ui/vehicle_stage_theme.tres"
const FACTORY_PATH := "res://scripts/ui/vehicle_ui_component_factory.gd"
const Factory = preload(FACTORY_PATH)
const PausePanel = preload("res://scripts/ui/vehicle_pause_panel.gd")

const REQUIRED_VARIATIONS := {
	&"ModalSurface": &"PanelContainer",
	&"ModalSurfaceCompact": &"PanelContainer",
	&"ContentSurface": &"PanelContainer",
	&"HudSurface": &"PanelContainer",
	&"ToastSurface": &"PanelContainer",
	&"PrimaryButton": &"Button",
	&"SecondaryButton": &"Button",
	&"DangerButton": &"Button",
	&"SelectableButton": &"Button",
	&"SelectedSelectableButton": &"Button",
	&"HealthMeter": &"ProgressBar",
	&"ResourceMeter": &"ProgressBar",
	&"BossMeter": &"ProgressBar",
	&"CooldownMeter": &"ProgressBar",
	&"SupportMeter": &"ProgressBar",
	&"PreviewFrame": &"PanelContainer",
	&"PreviewLocked": &"PanelContainer",
	&"PreviewFocused": &"PanelContainer",
	&"DisplayLabel": &"Label",
	&"TitleLabel": &"Label",
	&"SectionLabel": &"Label",
	&"MetricLabel": &"Label",
}

const RETIRED_VARIATIONS := [
	&"Surface",
	&"ChoiceButton",
	&"SelectedChoiceButton",
	&"SelectedRailButton",
	&"UpgradeChoiceCard",
	&"SelectedUpgradeChoiceCard",
	&"TertiaryDangerButton",
	&"FlatPanel",
	&"HudStatusGroup",
	&"HUDTransparent",
	&"FamilyBadge",
	&"SummaryBand",
	&"ContentInset",
	&"ContentSummary",
	&"HudHealthResource",
	&"HudObjectiveBoss",
	&"HudMinimapTarget",
	&"HudActionRail",
	&"HudToast",
]

var failures: Array[String] = []
var _theme: Theme


func _initialize() -> void:
	_theme = load(THEME_PATH) as Theme
	_validate_theme()
	_validate_factory()
	await _validate_pause()
	_validate_local_style_ownership()
	_finish()


func _validate_theme() -> void:
	_expect(_theme != null, "shared UI Theme loads")
	if _theme == null:
		return
	var source := FileAccess.get_file_as_string(THEME_PATH)
	_expect(not source.contains("StyleBoxTexture"), "Theme contains zero StyleBoxTexture")
	_expect(not source.contains(".png"), "Theme contains zero raster chrome reference")
	for variation in REQUIRED_VARIATIONS:
		_expect(
			_theme.get_type_variation_base(variation) == REQUIRED_VARIATIONS[variation],
			"required Theme variation exists: %s" % variation
		)
	for retired in RETIRED_VARIATIONS:
		_expect(
			_theme.get_type_variation_base(retired).is_empty()
				and not source.contains("\n%s/base_type" % retired),
			"retired Theme compatibility variation is absent: %s" % retired
		)
	var focus := _theme.get_stylebox(&"focus", &"Button") as StyleBoxFlat
	var selected := _theme.get_stylebox(
		&"normal",
		&"SelectedSelectableButton"
	) as StyleBoxFlat
	var disabled := _theme.get_stylebox(&"disabled", &"Button") as StyleBoxFlat
	_expect(
		focus != null and focus.border_width_left >= 2,
		"focus uses a visible structural outline"
	)
	_expect(
		selected != null and selected.border_width_left >= 3,
		"selection uses a structural amber rail"
	)
	_expect(
		disabled != null
			and disabled.border_width_left > 0
			and disabled.border_width_top == 0,
		"disabled uses a structural broken boundary"
	)


func _validate_factory() -> void:
	var source := FileAccess.get_file_as_string(FACTORY_PATH)
	for signature in [
		"static func surface(",
		"static func modal_surface(",
		"static func command_button(",
		"static func selectable_button(",
		"static func text_row(",
		"static func section_heading(",
		"static func preview_well(",
		"static func meter(",
	]:
		_expect(source.contains(signature), "factory exposes %s" % signature)
	_expect(
		source.contains("SURFACE_VARIATIONS")
			and source.contains("COMMAND_VARIATIONS")
			and source.contains("Unknown shared UI"),
		"factory owns explicit semantic role maps with an unknown-role error"
	)
	for retired in RETIRED_VARIATIONS:
		_expect(
			not source.contains('&"%s"' % retired),
			"factory contains no retired compatibility role: %s" % retired
		)
	_expect(not source.contains("static func flat_panel("), "factory removes the temporary flat_panel compatibility entry")
	var command := Factory.command_button("TEST", Factory.COMMAND_PRIMARY)
	_expect(
		command.custom_minimum_size.y >= 44.0
			and command.focus_mode == Control.FOCUS_ALL,
		"shared Command keeps its minimum target and focus contract"
	)
	command.free()
	var selectable := Factory.selectable_button("TEST", true)
	_expect(
		selectable.theme_type_variation == &"SelectedSelectableButton"
			and selectable.toggle_mode
			and selectable.button_pressed,
		"shared Selectable maps semantic selected state directly"
	)
	selectable.free()


func _validate_pause() -> void:
	var root_control := Control.new()
	root_control.theme = _theme
	root_control.size = Vector2(520.0, 430.0)
	get_root().add_child(root_control)
	var pause := PausePanel.new()
	root_control.add_child(pause)
	await process_frame
	var contract := pause.debug_contract()
	_expect(
		String(contract["command_stack_type"]) == "VBoxContainer",
		"Pause owns one vertical command stack"
	)
	_expect(
		Array(contract["command_order"]) == [
			"PAUSE_RESUME",
			"PAUSE_RESTART",
			"PAUSE_SETTINGS",
			"PAUSE_ABORT",
		],
		"Pause command order is Resume, Restart, Settings, Abort"
	)
	for width in Array(contract["command_widths"]):
		_expect(is_equal_approx(float(width), 360.0), "Pause commands share one width")
	_expect(
		float(contract["command_min_height"]) >= 48.0,
		"Pause command targets are at least 48 px high"
	)
	_expect(
		StringName(contract["abort_variation"]) == &"DangerButton",
		"Pause Abort action uses the shared danger role"
	)
	root_control.queue_free()
	await process_frame


func _validate_local_style_ownership() -> void:
	for file_name in DirAccess.get_files_at("res://scripts/ui"):
		if not file_name.ends_with(".gd"):
			continue
		var path := "res://scripts/ui/%s" % file_name
		var source := FileAccess.get_file_as_string(path)
		for forbidden in [
			"StyleBoxFlat.new(",
			"StyleBoxTexture.new(",
			"StyleBoxLine.new(",
		]:
			_expect(
				not source.contains(forbidden),
				"screen does not create local chrome: %s -> %s" % [path, forbidden]
			)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_UI_COMPONENTS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
