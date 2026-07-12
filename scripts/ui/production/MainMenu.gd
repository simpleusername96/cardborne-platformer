extends Control

signal new_run_requested
signal settings_requested
signal testbed_requested
signal quit_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var backdrop := BackdropScene.new()
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)

	var layout := HBoxContainer.new()
	margin.add_child(layout)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(340.0, 0.0)
	menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.add_theme_constant_override("separation", 12)
	layout.add_child(menu)

	var region := Label.new()
	region.text = "LOWER RUINS"
	Styles.configure_label(region, 16, Styles.AMBER)
	menu.add_child(region)

	var title := Label.new()
	title.text = "CARDBORNE"
	Styles.configure_label(title, 52)
	menu.add_child(title)

	var rule := ColorRect.new()
	rule.color = Styles.MOSS
	rule.custom_minimum_size = Vector2(86.0, 4.0)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu.add_child(rule)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 64.0)
	menu.add_child(spacer)

	var new_run := _menu_button("New Run", Styles.CYAN)
	new_run.pressed.connect(func() -> void: new_run_requested.emit())
	menu.add_child(new_run)

	var settings := _menu_button("Settings", Styles.MOSS)
	settings.pressed.connect(func() -> void: settings_requested.emit())
	menu.add_child(settings)

	var quit := _menu_button("Quit", Styles.CORAL, true)
	quit.pressed.connect(func() -> void: quit_requested.emit())
	menu.add_child(quit)

	if OS.is_debug_build():
		var dev_spacer := Control.new()
		dev_spacer.custom_minimum_size = Vector2(0.0, 18.0)
		menu.add_child(dev_spacer)
		var testbed := _menu_button("Developer Testbed", Styles.AMBER, true)
		testbed.add_theme_font_size_override("font_size", 14)
		testbed.custom_minimum_size = Vector2(248.0, 44.0)
		testbed.pressed.connect(func() -> void: testbed_requested.emit())
		menu.add_child(testbed)

	var flexible_space := Control.new()
	flexible_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(flexible_space)
	new_run.grab_focus()


func _menu_button(label_text: String, accent: Color, quiet: bool = false) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(286.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	Styles.apply_button(button, accent, quiet)
	return button
