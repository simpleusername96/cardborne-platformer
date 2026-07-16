extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

@onready var panel: PanelContainer = %PausePanel
@onready var eyebrow_label: Label = %PauseEyebrow
@onready var title_label: Label = %PauseTitle
@onready var context_label: Label = %PauseContext
@onready var accent_rule: ColorRect = %PauseRule
@onready var menu_view: VBoxContainer = %PauseCommands
@onready var confirmation_view: VBoxContainer = %AbandonConfirmation
@onready var warning_title: Label = %AbandonTitle
@onready var warning_label: Label = %AbandonWarning
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var confirm_end_button: Button = %ConfirmEndRunButton
@onready var keep_playing_button: Button = %KeepPlayingButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	Styles.apply_theme(self)
	_style_ui()
	_apply_copy()
	_connect_actions()
	SignalBus.pause_visibility_changed.connect(_on_pause_visibility_changed)
	SignalBus.settings_visibility_changed.connect(_on_settings_visibility_changed)
	UILocalization.locale_changed.connect(_on_locale_changed)
	_layout_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_panel()


func _input(event: InputEvent) -> void:
	if not visible or not (
		event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
	):
		return
	get_viewport().set_input_as_handled()
	if confirmation_view.visible:
		_show_menu()
	else:
		Game.set_pause_menu_open(false)


func _style_ui() -> void:
	Styles.apply_panel(panel, &"ModalSurface")
	Styles.configure_label(eyebrow_label, Styles.TYPE_CAPTION, Styles.AMBER)
	Styles.configure_label(title_label, Styles.TYPE_TITLE, Styles.TEXT)
	Styles.configure_label(context_label, Styles.TYPE_BODY, Styles.TEXT_MUTED)
	Styles.configure_label(warning_title, Styles.TYPE_SECTION, Styles.CORAL)
	Styles.configure_label(warning_label, Styles.TYPE_BODY, Styles.TEXT_MUTED)
	accent_rule.color = Styles.MOSS
	Styles.apply_button(resume_button, Styles.CYAN)
	Styles.apply_button(settings_button, Styles.MOSS, true)
	Styles.apply_button(main_menu_button, Styles.CORAL, true)
	Styles.apply_button(keep_playing_button, Styles.CYAN)
	Styles.apply_button(confirm_end_button, Styles.CORAL, true)


func _connect_actions() -> void:
	resume_button.pressed.connect(func() -> void: Game.set_pause_menu_open(false))
	settings_button.pressed.connect(func() -> void: Game.set_settings_open(true))
	main_menu_button.pressed.connect(_show_confirmation)
	confirm_end_button.pressed.connect(_confirm_main_menu)
	keep_playing_button.pressed.connect(_show_menu)


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
	var profile_name := String(
		RunState.get_hero_combat_loadout_snapshot().get("display_name", "Traveler")
	)
	var location := (
		UILocalization.text(&"Slime Court")
		if RunDirector.phase == RunPhase.Value.BOSS_ACTIVE
		else UILocalization.text(&"Stage {0}", [RunState.current_stage_index + 1])
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
	var panel_size := Vector2(
		minf(400.0, viewport_size.x - 32.0),
		minf(420.0, viewport_size.y - 32.0)
	)
	var right_margin := 32.0 if viewport_size.x >= 720.0 else 16.0
	var panel_position := Vector2(
		viewport_size.x - panel_size.x - right_margin,
		(viewport_size.y - panel_size.y) * 0.5
	)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y


func _apply_copy() -> void:
	eyebrow_label.text = UILocalization.text(&"EXPEDITION")
	title_label.text = UILocalization.text(&"PAUSED")
	resume_button.text = UILocalization.text(&"Resume")
	settings_button.text = UILocalization.text(&"Settings")
	main_menu_button.text = UILocalization.text(&"End Expedition")
	warning_title.text = UILocalization.text(&"END THIS EXPEDITION?")
	warning_label.text = UILocalization.text(
		&"Run cards, coins, and stage progress will be lost. Secured materials stay kept."
	)
	keep_playing_button.text = UILocalization.text(&"Keep Playing")
	confirm_end_button.text = UILocalization.text(&"End Expedition")
	_refresh_context()


func _on_locale_changed(_locale: String = "") -> void:
	_apply_copy()
