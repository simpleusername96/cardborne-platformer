extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var panel: PanelContainer
var menu_view: VBoxContainer
var confirmation_view: VBoxContainer
var context_label: Label
var resume_button: Button
var settings_button: Button
var main_menu_button: Button
var confirm_end_button: Button
var keep_playing_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	SignalBus.pause_visibility_changed.connect(_on_pause_visibility_changed)
	SignalBus.settings_visibility_changed.connect(_on_settings_visibility_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_panel()


func _input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if confirmation_view.visible:
		_show_menu()
	else:
		Game.set_pause_menu_open(false)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.98), Styles.OUTLINE)
	)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 14)
	margin.add_child(root_box)

	var title := Label.new()
	title.name = "PauseTitle"
	title.text = "EXPEDITION PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(title, 27)
	root_box.add_child(title)

	context_label = Label.new()
	context_label.name = "PauseContext"
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(context_label, 14, Styles.TEXT_MUTED)
	root_box.add_child(context_label)

	var rule := ColorRect.new()
	rule.color = Styles.MOSS
	rule.custom_minimum_size = Vector2(72.0, 3.0)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_box.add_child(rule)

	menu_view = VBoxContainer.new()
	menu_view.name = "PauseCommands"
	menu_view.add_theme_constant_override("separation", 9)
	root_box.add_child(menu_view)

	resume_button = _menu_button("Resume", Styles.CYAN)
	resume_button.name = "ResumeButton"
	resume_button.pressed.connect(func() -> void: Game.set_pause_menu_open(false))
	menu_view.add_child(resume_button)

	settings_button = _menu_button("Settings", Styles.MOSS)
	settings_button.name = "SettingsButton"
	settings_button.pressed.connect(func() -> void: Game.set_settings_open(true))
	menu_view.add_child(settings_button)

	main_menu_button = _menu_button("Main Menu", Styles.CORAL, true)
	main_menu_button.name = "MainMenuButton"
	main_menu_button.pressed.connect(_show_confirmation)
	menu_view.add_child(main_menu_button)

	confirmation_view = VBoxContainer.new()
	confirmation_view.name = "AbandonConfirmation"
	confirmation_view.visible = false
	confirmation_view.add_theme_constant_override("separation", 10)
	root_box.add_child(confirmation_view)

	var warning_title := Label.new()
	warning_title.text = "END THIS RUN?"
	warning_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(warning_title, 20, Styles.CORAL)
	confirmation_view.add_child(warning_title)

	var warning := Label.new()
	warning.name = "AbandonWarning"
	warning.text = "Run cards, coins, and stage progress will be lost."
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.custom_minimum_size = Vector2(0.0, 42.0)
	Styles.configure_label(warning, 14, Styles.TEXT_MUTED)
	confirmation_view.add_child(warning)

	confirm_end_button = _menu_button("End Run", Styles.CORAL)
	confirm_end_button.name = "ConfirmEndRunButton"
	confirm_end_button.pressed.connect(_confirm_main_menu)
	confirmation_view.add_child(confirm_end_button)

	keep_playing_button = _menu_button("Keep Playing", Styles.CYAN, true)
	keep_playing_button.name = "KeepPlayingButton"
	keep_playing_button.pressed.connect(_show_menu)
	confirmation_view.add_child(keep_playing_button)

	_layout_panel()


func _menu_button(label_text: String, accent: Color, quiet: bool = false) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(320.0, 46.0)
	Styles.apply_button(button, accent, quiet)
	return button


func _show_confirmation() -> void:
	menu_view.visible = false
	confirmation_view.visible = true
	keep_playing_button.grab_focus()


func _show_menu() -> void:
	confirmation_view.visible = false
	menu_view.visible = true
	resume_button.grab_focus()


func _confirm_main_menu() -> void:
	Game.close_overlays()
	RunDirector.show_main_menu()


func _refresh_context() -> void:
	var profile_name := "Adventurer"
	if RunState.selected_profile != null:
		profile_name = RunState.selected_profile.display_name
	var location := "Slime Court" if RunDirector.phase == RunPhase.Value.BOSS_ACTIVE else (
		"Stage %d" % (RunState.current_stage_index + 1)
	)
	context_label.text = "%s  |  %s" % [profile_name, location]


func _refresh_visibility() -> void:
	visible = Game.pause_menu_open and not Game.settings_open
	if visible:
		_refresh_context()
		_show_menu()


func _on_pause_visibility_changed(_is_visible: bool) -> void:
	_refresh_visibility()


func _on_settings_visibility_changed(_is_visible: bool) -> void:
	_refresh_visibility()


func _layout_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var panel_size := Vector2(minf(420.0, viewport_size.x - 32.0), 360.0)
	var panel_position := (viewport_size - panel_size) * 0.5
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y
