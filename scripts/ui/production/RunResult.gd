extends Control

signal menu_requested
signal retry_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var title_label: Label
var detail_label: Label
var retry_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func configure(victory: bool, profile_name: String) -> void:
	if title_label == null:
		return
	title_label.text = "EXPEDITION COMPLETE" if victory else "RUN ENDED"
	title_label.add_theme_color_override("font_color", Styles.AMBER if victory else Styles.CORAL)
	detail_label.text = "%s returned from the Lower Ruins." % profile_name if victory else "%s was lost in the Lower Ruins." % profile_name
	retry_button.text = "Run Again" if victory else "Retry"


func _build_ui() -> void:
	var backdrop := BackdropScene.new()
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(520.0, 0.0)
	content.add_theme_constant_override("separation", 16)
	center.add_child(content)

	var marker := ColorRect.new()
	marker.color = Styles.AMBER
	marker.custom_minimum_size = Vector2(90.0, 5.0)
	marker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(marker)

	title_label = Label.new()
	title_label.text = "EXPEDITION COMPLETE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(title_label, 40, Styles.AMBER)
	content.add_child(title_label)

	detail_label = Label.new()
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(0.0, 44.0)
	Styles.configure_label(detail_label, 17, Styles.TEXT_MUTED)
	content.add_child(detail_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	content.add_child(button_row)

	retry_button = Button.new()
	retry_button.text = "Run Again"
	retry_button.custom_minimum_size = Vector2(180.0, 48.0)
	Styles.apply_button(retry_button, Styles.AMBER)
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	button_row.add_child(retry_button)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(180.0, 48.0)
	Styles.apply_button(menu_button, Styles.MOSS, true)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	button_row.add_child(menu_button)
	retry_button.grab_focus()
