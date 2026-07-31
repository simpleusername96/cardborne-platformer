class_name VehicleDeploymentPanel
extends VBoxContainer

## Owns deployment composition and selection presentation. It emits deployment
## intent; the run remains the owner of loadout, difficulty and launch state.

signal deploy_requested(primary_id: StringName, difficulty_id: StringName)
signal settings_requested
signal practice_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")


class ControlHintGlyph:
	extends TextureRect

	const SemanticAssets = preload(
		"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
	)

	var kind: StringName = &"move"
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if custom_minimum_size == Vector2.ZERO:
			custom_minimum_size = Vector2(40.0, 40.0)
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	func configure(value: StringName, _color: Color = Art.MINT) -> void:
		kind = value
		texture = SemanticAssets.texture(StringName({
			&"move": &"cue/guide_ship",
			&"aim": &"cue/target_bracket_corner",
			&"primary": &"hud/action_primary",
			&"dash": &"hud/action_dash",
		}.get(kind, &"hud/action_emp")))


var _field_label: Label
var _title: Label
var _header_rule: ColorRect
var _body: HBoxContainer
var _controls_box: VBoxContainer
var _difficulty_box: VBoxContainer
var _control_rows: Array[Control] = []
var _control_glyphs: Array[ControlHintGlyph] = []
var _primary_section_nodes: Array[Control] = []
var _weapon_summary: Label
var _difficulty_detail: Label
var _difficulty_buttons: Dictionary = {}
var _binding_labels: Dictionary = {}
var _command: Button
var _secondary_actions: HBoxContainer
var _selected_difficulty: StringName = RunDifficulty.DEFAULT
var _field_name_key := "FIELD_DROWNED_RUIN"
var _bindings: Dictionary = {}
var _compact := false


func _ready() -> void:
	name = "DeploymentPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_build()


func _build() -> void:
	_field_label = Factory.label(
		"DEPLOY_FIELD_TEMPLATE",
		16,
		Art.SYSTEM
	)
	_field_label.theme_type_variation = &"MetricLabel"
	_field_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_field_label)
	_title = Factory.label("DEPLOY_TITLE", 42, Art.IVORY_BRIGHT)
	_title.theme_type_variation = &"DisplayLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_header_rule = ColorRect.new()
	_header_rule.color = Art.SYSTEM
	_header_rule.custom_minimum_size.y = 7.0
	_header_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header_rule)

	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 28)
	_body.custom_minimum_size.y = 322.0
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_body)
	_controls_box = VBoxContainer.new()
	_controls_box.custom_minimum_size.x = 522.0
	_controls_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls_box.add_theme_constant_override("separation", 3)
	_body.add_child(_controls_box)
	_controls_box.add_child(Factory.section_heading(
		"DEPLOY_CONTROLS_HEADING"
	))
	_add_control_row(
		&"move",
		"SETTINGS_MOVEMENT_RESERVED",
		"DEPLOY_CONTROL_MOVE_BINDING"
	)
	_add_control_row(
		&"aim",
		"DEPLOY_CONTROL_AIM",
		"DEPLOY_CONTROL_AIM_BINDING"
	)
	_add_control_row(
		&"primary",
		"ACTION_PRIMARY",
		"DEPLOY_CONTROL_PRIMARY_BINDING",
		&"primary_fire"
	)
	_add_control_row(
		&"dash",
		"ACTION_DASH",
		"DEPLOY_CONTROL_ACTION_BINDING",
		&"dash"
	)
	_add_control_row(
		&"emp",
		"ACTION_EMP",
		"DEPLOY_CONTROL_ACTION_BINDING",
		&"active_skill"
	)
	var primary_separator := HSeparator.new()
	_controls_box.add_child(primary_separator)
	_primary_section_nodes.append(primary_separator)
	var primary_heading := Factory.section_heading(
		"DEPLOY_PRIMARY_HEADING"
	)
	_controls_box.add_child(primary_heading)
	_primary_section_nodes.append(primary_heading)
	var weapon_row := HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 14)
	_controls_box.add_child(weapon_row)
	_primary_section_nodes.append(weapon_row)
	var weapon_glyph := ControlHintGlyph.new()
	weapon_glyph.configure(&"primary", Art.MUSTARD)
	weapon_glyph.custom_minimum_size = Vector2(48.0, 48.0)
	weapon_row.add_child(weapon_glyph)
	_control_glyphs.append(weapon_glyph)
	_weapon_summary = Factory.label(
		"DEPLOY_PULSE_CANNON_SUMMARY",
		16,
		Art.IVORY_BRIGHT
	)
	_weapon_summary.theme_type_variation = &"MetricLabel"
	_weapon_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_weapon_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_weapon_summary.custom_minimum_size.y = 64.0
	_weapon_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_weapon_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_row.add_child(_weapon_summary)

	_body.add_child(VSeparator.new())
	_difficulty_box = VBoxContainer.new()
	_difficulty_box.custom_minimum_size.x = 520.0
	_difficulty_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_difficulty_box.add_theme_constant_override("separation", 12)
	_body.add_child(_difficulty_box)
	_difficulty_box.add_child(Factory.section_heading(
		"DEPLOY_DIFFICULTY_LABEL"
	))
	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation", 10)
	_difficulty_box.add_child(difficulty_row)
	for difficulty_id in RunDifficulty.IDS:
		var button := Factory.command_button(
			_difficulty_title_key(difficulty_id),
			&"SecondaryButton"
		)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 72.0
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_select_difficulty.bind(difficulty_id))
		difficulty_row.add_child(button)
		_difficulty_buttons[difficulty_id] = button
	_difficulty_detail = Factory.label(
		"DEPLOY_DIFFICULTY_HARD_DETAIL",
		16,
		Art.MINT_SOFT
	)
	_difficulty_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_difficulty_detail.custom_minimum_size.y = 96.0
	_difficulty_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_difficulty_box.add_child(_difficulty_detail)

	var deploy_lane := CenterContainer.new()
	add_child(deploy_lane)
	_command = Factory.command_button("DEPLOY_COMMAND", &"PrimaryButton")
	_command.custom_minimum_size = Vector2(300.0, 48.0)
	_command.add_theme_font_size_override("font_size", 22)
	_command.pressed.connect(func() -> void:
		deploy_requested.emit(&"pulse_cannon", _selected_difficulty)
	)
	deploy_lane.add_child(_command)

	_secondary_actions = HBoxContainer.new()
	_secondary_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_secondary_actions.add_theme_constant_override("separation", 14)
	add_child(_secondary_actions)
	var settings := Factory.command_button(
		"SETTINGS_OPEN",
		&"SecondaryButton"
	)
	settings.custom_minimum_size.x = 140.0
	settings.pressed.connect(func() -> void: settings_requested.emit())
	_secondary_actions.add_child(settings)
	if OS.is_debug_build():
		var practice := Factory.command_button(
			"BOSS_PRACTICE_OPEN",
			&"SecondaryButton"
		)
		practice.custom_minimum_size.x = 180.0
		practice.pressed.connect(func() -> void: practice_requested.emit())
		_secondary_actions.add_child(practice)


func open(
	difficulty_id: StringName,
	field_name_key: String
) -> void:
	_selected_difficulty = RunDifficulty.normalize(difficulty_id)
	_field_name_key = field_name_key
	refresh_localized_content()
	_command.grab_focus()


func set_compact_mode(compact: bool) -> void:
	if _compact == compact and _body != null:
		return
	_compact = compact
	_body.custom_minimum_size.y = 270.0 if compact else 322.0
	_body.add_theme_constant_override("separation", 16 if compact else 28)
	_controls_box.custom_minimum_size.x = 400.0 if compact else 522.0
	_difficulty_box.custom_minimum_size.x = 400.0 if compact else 520.0
	_title.add_theme_font_size_override("font_size", 30 if compact else 40)
	_field_label.add_theme_font_size_override("font_size", 14 if compact else 16)
	for row in _control_rows:
		row.custom_minimum_size.y = 28.0 if compact else 36.0
	for glyph in _control_glyphs:
		glyph.custom_minimum_size = (
			Vector2(30.0, 30.0)
			if compact
			else Vector2(34.0, 34.0)
		)
	_weapon_summary.custom_minimum_size.y = 30.0 if compact else 64.0
	_weapon_summary.autowrap_mode = (
		TextServer.AUTOWRAP_OFF
		if compact
		else TextServer.AUTOWRAP_WORD_SMART
	)
	for primary_node in _primary_section_nodes:
		primary_node.visible = true
	_field_label.visible = not compact
	_header_rule.visible = not compact
	_difficulty_detail.custom_minimum_size.y = 72.0 if compact else 96.0
	for button_variant in _difficulty_buttons.values():
		var button := button_variant as Button
		button.custom_minimum_size.y = 58.0 if compact else 72.0
		button.add_theme_font_size_override("font_size", 17 if compact else 22)
	_command.custom_minimum_size.y = 48.0
	_secondary_actions.add_theme_constant_override(
		"separation",
		10 if compact else 14
	)
	refresh_localized_content()


func refresh_localized_content() -> void:
	var field_text := tr("DEPLOY_FIELD_TEMPLATE").replace(
		"%s",
		tr(_field_name_key)
	)
	_field_label.text = field_text
	_title.text = (
		"%s · %s" % [tr("DEPLOY_TITLE"), tr(_field_name_key)]
		if _compact
		else tr("DEPLOY_TITLE")
	)
	for difficulty_id in _difficulty_buttons:
		var button := _difficulty_buttons[difficulty_id] as Button
		button.text = tr(_difficulty_title_key(difficulty_id))
		button.theme_type_variation = (
			&"SelectedChoiceButton"
			if difficulty_id == _selected_difficulty
			else &"SecondaryButton"
		)
	_difficulty_detail.text = tr(
		_difficulty_detail_key(_selected_difficulty)
	)
	refresh_input_bindings(_bindings)


func refresh_input_bindings(bindings: Dictionary) -> void:
	_bindings = bindings.duplicate(true)
	if _bindings.is_empty():
		_bindings = InputProfile.default_descriptors()
	for action_variant in _binding_labels:
		var action := StringName(action_variant)
		var binding := InputProfile.action_display_name(action, _bindings)
		var label := _binding_labels[action] as Label
		label.text = (
			tr("DEPLOY_CONTROL_PRIMARY_BINDING") % binding
			if action == &"primary_fire"
			else tr("DEPLOY_CONTROL_ACTION_BINDING") % binding
		)


func debug_contract() -> Dictionary:
	return {
		"focusables":find_children("*", "Button", true, false).size(),
		"difficulty_choices":_difficulty_buttons.size(),
		"difficulty_min_height":_minimum_difficulty_button_height(),
		"difficulty":_selected_difficulty,
		"primary_size":_command.custom_minimum_size,
		"compact":_compact,
	}


func selected_difficulty() -> StringName:
	return _selected_difficulty


func debug_submit(difficulty_id: StringName) -> void:
	_select_difficulty(difficulty_id)
	_command.pressed.emit()


func _add_control_row(
	glyph_kind: StringName,
	title_key: String,
	binding_key: String,
	action: StringName = &""
) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 36.0
	row.add_theme_constant_override("separation", 10)
	_controls_box.add_child(row)
	_control_rows.append(row)
	var glyph := ControlHintGlyph.new()
	glyph.configure(glyph_kind, Art.MINT)
	glyph.custom_minimum_size = Vector2(34.0, 34.0)
	row.add_child(glyph)
	_control_glyphs.append(glyph)
	var title := Factory.label(title_key, 16, Art.IVORY_BRIGHT)
	title.theme_type_variation = &"MetricLabel"
	title.custom_minimum_size.x = 132.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var binding := Factory.label(binding_key, 15, Art.MINT_SOFT)
	binding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	binding.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	binding.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(binding)
	if not action.is_empty():
		_binding_labels[action] = binding


func _select_difficulty(difficulty_id: StringName) -> void:
	_selected_difficulty = RunDifficulty.normalize(difficulty_id)
	refresh_localized_content()


func _difficulty_title_key(difficulty_id: StringName) -> String:
	match RunDifficulty.normalize(difficulty_id):
		RunDifficulty.EASY:
			return "DIFFICULTY_EASY"
		RunDifficulty.NORMAL:
			return "DIFFICULTY_NORMAL"
	return "DIFFICULTY_HARD"


func _difficulty_detail_key(difficulty_id: StringName) -> String:
	match RunDifficulty.normalize(difficulty_id):
		RunDifficulty.EASY:
			return "DEPLOY_DIFFICULTY_EASY_DETAIL"
		RunDifficulty.NORMAL:
			return "DEPLOY_DIFFICULTY_NORMAL_DETAIL"
	return "DEPLOY_DIFFICULTY_HARD_DETAIL"


func _minimum_difficulty_button_height() -> float:
	var minimum_height := INF
	for button_variant in _difficulty_buttons.values():
		minimum_height = minf(
			minimum_height,
			(button_variant as Button).custom_minimum_size.y
		)
	return 0.0 if is_inf(minimum_height) else minimum_height
