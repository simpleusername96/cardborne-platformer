extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const BINDING_HINT := "Select an action, then press a new key."
const ACTION_LABELS := {
	"move_left": "Move left",
	"move_right": "Move right",
	"jump": "Jump",
	"dash": "Dash",
	"attack": "Attack",
	"guard": "Guard",
	"use_consumable": "Potion",
	"climb_up": "Climb up",
	"climb_down": "Climb down",
	"crouch": "Crouch / drop",
	"interact": "Interact",
	"pause": "Pause / back",
}

@onready var shell_backdrop: Control = %ShellBackdrop
@onready var panel: PanelContainer = %SettingsPanel
@onready var title_label: Label = %SettingsTitle
@onready var accent_rule: ColorRect = %SettingsRule
@onready var close_button: Button = %CloseButton
@onready var restore_all_button: Button = %RestoreAllButton
@onready var bindings_box: VBoxContainer = %BindingsBox
@onready var warning_label: Label = %BindingStatus
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SfxValue
@onready var screen_shake_toggle: CheckBox = %ScreenShakeToggle
@onready var damage_flash_toggle: CheckBox = %DamageFlashToggle
@onready var language_selector: OptionButton = %LanguageSelector

var binding_row_controls: Dictionary = {}
var capture_action_name: String = ""
var _previous_focus: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style_ui()
	_configure_settings_controls()
	_rebuild_binding_rows()
	_apply_copy()
	close_button.pressed.connect(func() -> void: Game.set_settings_open(false))
	restore_all_button.pressed.connect(_restore_all_defaults)
	SignalBus.settings_visibility_changed.connect(_on_settings_visibility_changed)
	SignalBus.input_bindings_changed.connect(_on_input_bindings_changed)
	UILocalization.locale_changed.connect(_on_locale_changed)
	_layout_panel()
	call_deferred("_layout_panel")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_panel()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if not capture_action_name.is_empty():
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo:
				get_viewport().set_input_as_handled()
				var keycode := (
					key_event.physical_keycode
					if key_event.physical_keycode != KEY_NONE
					else key_event.keycode
				)
				if keycode == KEY_ESCAPE:
					_clear_capture(true)
					return
				_apply_captured_key(key_event)
		return

	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.set_settings_open(false)


func _style_ui() -> void:
	panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.99), Styles.OUTLINE)
	)
	Styles.configure_label(title_label, Styles.TYPE_TITLE, Styles.TEXT)
	accent_rule.color = Styles.MOSS
	Styles.apply_button(close_button, Styles.CYAN, true)
	Styles.apply_button(restore_all_button, Styles.MOSS, true)
	for label in [%AudioHeading, %LanguageHeading, %FeedbackHeading, %ControlsHeading]:
		Styles.configure_label(label as Label, Styles.TYPE_SECTION, Styles.AMBER)
	for label in [%ActionColumn, %KeyboardColumn]:
		Styles.configure_label(label as Label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	for label in [%MasterLabel, %MusicLabel, %SfxLabel]:
		Styles.configure_label(label as Label, Styles.TYPE_BODY, Styles.TEXT)
	for label in [master_value, music_value, sfx_value]:
		Styles.configure_label(label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	Styles.configure_label(warning_label, Styles.TYPE_BODY, Styles.TEXT_MUTED)
	screen_shake_toggle.add_theme_font_size_override("font_size", Styles.TYPE_BODY)
	damage_flash_toggle.add_theme_font_size_override("font_size", Styles.TYPE_BODY)
	screen_shake_toggle.add_theme_color_override("font_color", Styles.TEXT)
	damage_flash_toggle.add_theme_color_override("font_color", Styles.TEXT)
	language_selector.add_theme_font_size_override("font_size", Styles.TYPE_BODY)
	language_selector.custom_minimum_size.y = Styles.TARGET_HEIGHT


func _configure_settings_controls() -> void:
	_configure_slider(master_slider, master_value, "master_volume")
	_configure_slider(music_slider, music_value, "music_volume")
	_configure_slider(sfx_slider, sfx_value, "sfx_volume")
	screen_shake_toggle.set_pressed_no_signal(
		bool(RunState.get_setting("screen_shake", true))
	)
	damage_flash_toggle.set_pressed_no_signal(
		bool(RunState.get_setting("damage_flash", true))
	)
	screen_shake_toggle.toggled.connect(func(enabled: bool) -> void:
		RunState.set_setting("screen_shake", enabled)
	)
	damage_flash_toggle.toggled.connect(func(enabled: bool) -> void:
		RunState.set_setting("damage_flash", enabled)
	)
	_configure_language_selector()


func _configure_language_selector() -> void:
	language_selector.clear()
	language_selector.add_item("English")
	language_selector.set_item_metadata(0, "en")
	language_selector.add_item("한국어")
	language_selector.set_item_metadata(1, "ko")
	_sync_language_selector()
	language_selector.item_selected.connect(_on_language_selected)


func _sync_language_selector() -> void:
	var active_locale := UILocalization.get_locale()
	for index in language_selector.item_count:
		if String(language_selector.get_item_metadata(index)) == active_locale:
			language_selector.select(index)
			return


func _on_language_selected(index: int) -> void:
	UILocalization.set_locale(String(language_selector.get_item_metadata(index)))


func _configure_slider(slider: HSlider, value_label: Label, setting_name: String) -> void:
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.set_value_no_signal(float(RunState.get_setting(setting_name, 0.8)) * 100.0)
	_update_slider_value(value_label, slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		RunState.set_setting(setting_name, value / 100.0)
		_update_slider_value(value_label, value)
	)


func _update_slider_value(label: Label, value: float) -> void:
	label.text = "%d%%" % int(round(value))


func _make_binding_row(row_info: Dictionary) -> HBoxContainer:
	var action_name := String(row_info["action"])
	var action_label := UILocalization.text(
		StringName(ACTION_LABELS.get(action_name, String(row_info["label"]).capitalize()))
	)

	var row := HBoxContainer.new()
	row.name = "Binding_%s" % action_name
	row.custom_minimum_size = Vector2(0.0, Styles.TARGET_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var action := Label.new()
	action.text = action_label
	action.custom_minimum_size = Vector2(128.0, 0.0)
	action.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(action, Styles.TYPE_BODY, Styles.TEXT)
	row.add_child(action)

	var keyboard_button := Button.new()
	keyboard_button.text = String(row_info.get("binding", "Unbound"))
	keyboard_button.custom_minimum_size = Vector2(148.0, Styles.TARGET_HEIGHT)
	keyboard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keyboard_button.clip_text = true
	Styles.apply_button(keyboard_button, Styles.CYAN, true)
	keyboard_button.pressed.connect(func() -> void:
		_begin_capture(action_name, action_label)
	)
	row.add_child(keyboard_button)

	var default_button := Button.new()
	default_button.text = UILocalization.text(&"Default")
	default_button.custom_minimum_size = Vector2(104.0, Styles.TARGET_HEIGHT)
	Styles.apply_button(default_button, Styles.MOSS, true)
	default_button.pressed.connect(func() -> void:
		_restore_action_default(action_name)
	)
	row.add_child(default_button)

	binding_row_controls[action_name] = {
		"keyboard": keyboard_button,
	}
	return row


func _rebuild_binding_rows() -> void:
	if bindings_box == null:
		return
	for child in bindings_box.get_children():
		bindings_box.remove_child(child)
		child.queue_free()
	binding_row_controls.clear()
	for row_info in Game.get_input_binding_rows():
		bindings_box.add_child(_make_binding_row(row_info))
	call_deferred("_layout_panel")


func _refresh_binding_rows() -> void:
	for row_info in Game.get_input_binding_rows():
		var action_name := String(row_info["action"])
		if not binding_row_controls.has(action_name):
			_rebuild_binding_rows()
			return
		var controls: Dictionary = binding_row_controls[action_name]
		var keyboard_button := controls["keyboard"] as Button
		keyboard_button.text = (
			UILocalization.text(&"Press a key")
			if action_name == capture_action_name
			else String(row_info.get("binding", UILocalization.text(&"Unbound")))
		)


func _begin_capture(action_name: String, action_label: String) -> void:
	capture_action_name = action_name
	warning_label.text = UILocalization.text(&"Press a key for {0}. Esc cancels.", [action_label])
	_refresh_binding_rows()


func _apply_captured_key(key_event: InputEventKey) -> void:
	var result := Game.remap_action_to_event(capture_action_name, key_event)
	if bool(result.get("ok", false)):
		capture_action_name = ""
		warning_label.text = UILocalization.text(&"Binding updated.")
		_refresh_binding_rows()
	else:
		warning_label.text = UILocalization.text(&"That key is already used. Choose another.")


func _clear_capture(show_message: bool) -> void:
	capture_action_name = ""
	if show_message:
		warning_label.text = UILocalization.text(&"Remap canceled.")
	_refresh_binding_rows()


func _restore_action_default(action_name: String) -> void:
	var result := Game.restore_action_default(action_name)
	capture_action_name = ""
	warning_label.text = (
		UILocalization.text(&"Default restored.")
		if bool(result.get("ok", false))
		else UILocalization.text(&"Unable to restore that key.")
	)
	_refresh_binding_rows()


func _restore_all_defaults() -> void:
	Game.restore_all_input_defaults()
	capture_action_name = ""
	warning_label.text = UILocalization.text(&"Default bindings restored.")
	_refresh_binding_rows()


func _layout_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var panel_size := Vector2(
		minf(900.0, viewport_size.x - 24.0),
		minf(650.0, viewport_size.y - 24.0)
	)
	var panel_position := (viewport_size - panel_size) * 0.5
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y


func _on_settings_visibility_changed(is_visible: bool) -> void:
	if is_visible:
		var focus_owner := get_viewport().gui_get_focus_owner()
		_previous_focus = focus_owner if focus_owner != null and not is_ancestor_of(focus_owner) else null
	visible = is_visible
	if visible:
		shell_backdrop.visible = not Game.pause_menu_open
		_apply_copy()
		_refresh_binding_rows()
		close_button.grab_focus()
	else:
		_clear_capture(false)
		call_deferred("_restore_previous_focus")


func _on_input_bindings_changed() -> void:
	if visible:
		_refresh_binding_rows()


func _restore_previous_focus() -> void:
	if (
		_previous_focus != null
		and is_instance_valid(_previous_focus)
		and _previous_focus.is_visible_in_tree()
		and _previous_focus.focus_mode != Control.FOCUS_NONE
	):
		_previous_focus.grab_focus()
	_previous_focus = null


func _apply_copy() -> void:
	title_label.text = UILocalization.text(&"SETTINGS")
	close_button.text = UILocalization.text(&"Back" if Game.pause_menu_open else &"Close")
	%AudioHeading.text = UILocalization.text(&"AUDIO")
	%MasterLabel.text = UILocalization.text(&"Master")
	%MusicLabel.text = UILocalization.text(&"Music")
	%SfxLabel.text = UILocalization.text(&"SFX")
	%LanguageHeading.text = UILocalization.text(&"LANGUAGE")
	%FeedbackHeading.text = UILocalization.text(&"FEEDBACK")
	screen_shake_toggle.text = UILocalization.text(&"Screen shake")
	damage_flash_toggle.text = UILocalization.text(&"Damage flash")
	%ControlsHeading.text = UILocalization.text(&"CONTROLS")
	restore_all_button.text = UILocalization.text(&"Restore All")
	%ActionColumn.text = UILocalization.text(&"ACTION")
	%KeyboardColumn.text = UILocalization.text(&"KEY")
	if capture_action_name.is_empty():
		warning_label.text = UILocalization.text(StringName(BINDING_HINT))
	_sync_language_selector()


func _on_locale_changed(_locale: String = "") -> void:
	_apply_copy()
	_rebuild_binding_rows()
