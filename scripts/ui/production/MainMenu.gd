extends Control

signal new_run_requested
signal settings_requested
signal quit_requested

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

@onready var region_label: Label = %RegionLabel
@onready var title_label: Label = %TitleLabel
@onready var invitation_label: Label = %InvitationLabel
@onready var accent_rule: ColorRect = %AccentRule
@onready var new_run_button: Button = %NewRunButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	_style_ui()
	new_run_button.pressed.connect(func() -> void: new_run_requested.emit())
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	new_run_button.grab_focus()


func _style_ui() -> void:
	Styles.configure_label(region_label, 15, Styles.AMBER)
	Styles.configure_label(title_label, 52, Styles.TEXT)
	Styles.configure_label(invitation_label, 16, Styles.TEXT_MUTED)
	accent_rule.color = Styles.MOSS
	Styles.apply_button(new_run_button, Styles.CYAN)
	Styles.apply_button(settings_button, Styles.MOSS, true)
	Styles.apply_button(quit_button, Styles.CORAL, true)
