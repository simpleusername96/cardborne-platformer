extends Control

signal back_requested
signal run_requested(profile_index: int)

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const PortraitScene = preload("res://scripts/ui/production/ProductionPortrait.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var selected_index: int = 0
var _profiles: Array[CharacterProfile] = []
var _card_buttons: Array[Button] = []
var _selected_labels: Array[Label] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for profile in RunState.profiles:
		_profiles.append(profile)
	selected_index = clampi(RunState.selected_profile_index, 0, maxi(_profiles.size() - 1, 0))
	_build_ui()
	_update_selection()


func _build_ui() -> void:
	var backdrop := BackdropScene.new()
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 28)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0.0, 48.0)
	header.add_theme_constant_override("separation", 16)
	page.add_child(header)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(104.0, 44.0)
	Styles.apply_button(back, Styles.MOSS, true)
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)

	var title := Label.new()
	title.text = "CHOOSE YOUR RUNNER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(title, 32)
	header.add_child(title)

	var header_balance := Control.new()
	header_balance.custom_minimum_size = Vector2(104.0, 44.0)
	header.add_child(header_balance)

	var cards := HBoxContainer.new()
	cards.name = "CharacterCards"
	cards.add_theme_constant_override("separation", 18)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(cards)

	for profile_index in _profiles.size():
		cards.add_child(_build_character_card(profile_index, _profiles[profile_index]))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.custom_minimum_size = Vector2(0.0, 52.0)
	page.add_child(footer)

	var start := Button.new()
	start.name = "StartRunButton"
	start.text = "Start Run"
	start.custom_minimum_size = Vector2(240.0, 48.0)
	start.disabled = _profiles.is_empty()
	Styles.apply_button(start, Styles.AMBER)
	start.pressed.connect(func() -> void: run_requested.emit(selected_index))
	footer.add_child(start)

	if not _card_buttons.is_empty():
		_card_buttons[selected_index].grab_focus()


func _build_character_card(profile_index: int, profile: CharacterProfile) -> Button:
	var card := Button.new()
	card.name = "CharacterCard_%s" % profile.id
	card.text = ""
	card.custom_minimum_size = Vector2(250.0, 340.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.pressed.connect(func() -> void: _select_profile(profile_index))
	_card_buttons.append(card)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 18.0
	margin.offset_top = 16.0
	margin.offset_right = -18.0
	margin.offset_bottom = -16.0
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var name_label := Label.new()
	name_label.text = profile.display_name.to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(name_label, 23)
	content.add_child(name_label)

	var portrait_center := CenterContainer.new()
	portrait_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_center.custom_minimum_size = Vector2(0.0, 118.0)
	content.add_child(portrait_center)

	var portrait := PortraitScene.new()
	portrait.custom_minimum_size = Vector2(150.0, 118.0)
	portrait.configure(profile.id, profile.visual_color)
	portrait_center.add_child(portrait)

	var trait_label := Label.new()
	trait_label.text = profile.trait_summary
	trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trait_label.custom_minimum_size = Vector2(0.0, 44.0)
	Styles.configure_label(trait_label, 14, Styles.TEXT_MUTED)
	content.add_child(trait_label)

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 12)
	stats.add_theme_constant_override("v_separation", 4)
	content.add_child(stats)
	_add_stat(stats, "HEALTH", str(profile.max_health))
	_add_stat(stats, "DAMAGE", str(profile.attack_damage))
	_add_stat(stats, "MOVE", str(roundi(profile.move_speed)))
	_add_stat(stats, "DASH", str(profile.dash_charges))

	var flexible := Control.new()
	flexible.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(flexible)

	var selected := Label.new()
	selected.text = "SELECTED"
	selected.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected.custom_minimum_size = Vector2(0.0, 24.0)
	Styles.configure_label(selected, 13, profile.visual_color)
	content.add_child(selected)
	_selected_labels.append(selected)
	return card


func _add_stat(grid: GridContainer, stat_name: String, value: String) -> void:
	var name_label := Label.new()
	name_label.text = stat_name
	Styles.configure_label(name_label, 12, Styles.TEXT_MUTED)
	grid.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(value_label, 14)
	grid.add_child(value_label)


func _select_profile(profile_index: int) -> void:
	selected_index = clampi(profile_index, 0, maxi(_profiles.size() - 1, 0))
	_update_selection()


func _update_selection() -> void:
	for profile_index in _card_buttons.size():
		var is_selected := profile_index == selected_index
		Styles.apply_character_card(
			_card_buttons[profile_index],
			_profiles[profile_index].visual_color,
			is_selected
		)
		_selected_labels[profile_index].visible = is_selected
