extends Control

signal new_run_requested
signal settings_requested

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

@onready var region_label: Label = %RegionLabel
@onready var title_label: Label = %TitleLabel
@onready var invitation_label: Label = %InvitationLabel
@onready var accent_rule: ColorRect = %AccentRule
@onready var new_run_button: Button = %NewRunButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	Styles.apply_theme(self)
	_style_ui()
	_apply_copy()
	new_run_button.pressed.connect(func() -> void: new_run_requested.emit())
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	UILocalization.locale_changed.connect(_on_locale_changed)
	new_run_button.grab_focus()


func _style_ui() -> void:
	Styles.configure_label(region_label, Styles.TYPE_CAPTION, Styles.AMBER)
	Styles.configure_label(title_label, Styles.TYPE_HERO, Styles.TEXT)
	Styles.configure_label(invitation_label, Styles.TYPE_BODY, Styles.TEXT_MUTED)
	accent_rule.color = Styles.MOSS
	Styles.apply_button(new_run_button, Styles.CYAN)
	Styles.apply_button(settings_button, Styles.MOSS, true)


func _apply_copy() -> void:
	region_label.text = UILocalization.text(&"LOWER RUINS")
	invitation_label.text = UILocalization.text(&"THE CROWN WAITS BELOW")
	new_run_button.text = UILocalization.text(&"Begin Expedition")
	settings_button.text = UILocalization.text(&"Settings")


func _on_locale_changed(_locale: String = "") -> void:
	_apply_copy()
