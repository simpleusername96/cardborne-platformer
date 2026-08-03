class_name VehicleDeploymentPanel
extends VBoxContainer

## Owns the fixed-Hard deployment composition and emits launch intent. The run
## remains the owner of loadout and combat state.

signal deploy_requested(primary_id: StringName)
signal settings_requested
signal practice_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const CRAFT_ASSET_ID := &"attachment/player_craft_body"
const CRAFT_NOSE_UP_ROTATION := -PI / 2.0

var _field_label: Label
var _title: Label
var _body_scroll: ScrollContainer
var _body: HBoxContainer
var _identity_box: VBoxContainer
var _controls_box: VBoxContainer
var _craft_preview: PanelContainer
var _craft_texture: TextureRect
var _weapon_summary: Label
var _control_rows: Array[HBoxContainer] = []
var _binding_labels: Dictionary = {}
var _command: Button
var _secondary_actions: HBoxContainer
var _field_name_key := "FIELD_DROWNED_RUIN"
var _bindings: Dictionary = {}
var _compact := false


func _ready() -> void:
	name = "DeploymentPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	_build()


func _build() -> void:
	_build_header()
	_build_body()
	_build_footer()


func _build_header() -> void:
	_field_label = Factory.label("DEPLOY_FIELD_TEMPLATE", 16, Art.SYSTEM)
	_field_label.theme_type_variation = &"MetricLabel"
	_field_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_field_label)
	_title = Factory.label("DEPLOY_TITLE", 42, Art.TEXT_PRIMARY)
	_title.theme_type_variation = &"DisplayLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_title)


func _build_body() -> void:
	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_body_scroll)

	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 24)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.add_child(_body)

	_identity_box = VBoxContainer.new()
	_identity_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_identity_box.size_flags_stretch_ratio = 0.4
	_identity_box.add_theme_constant_override("separation", 8)
	_body.add_child(_identity_box)
	_identity_box.add_child(Factory.section_heading("DEPLOY_PRIMARY_HEADING"))
	var weapon_name := Factory.label("PRIMARY_PULSE_CANNON", 20, Art.MUSTARD)
	weapon_name.theme_type_variation = &"MetricLabel"
	_identity_box.add_child(weapon_name)
	_build_craft_preview()
	_weapon_summary = Factory.label(
		"DEPLOY_PULSE_CANNON_SUMMARY",
		15,
		Art.TEXT_PRIMARY
	)
	_weapon_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_weapon_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_identity_box.add_child(_weapon_summary)

	_body.add_child(VSeparator.new())
	_controls_box = VBoxContainer.new()
	_controls_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls_box.size_flags_stretch_ratio = 0.6
	_controls_box.add_theme_constant_override("separation", 10)
	_body.add_child(_controls_box)
	_controls_box.add_child(Factory.section_heading("DEPLOY_CONTROLS_HEADING"))
	_add_control_row(
		"SETTINGS_MOVEMENT_RESERVED",
		"DEPLOY_CONTROL_MOVE_BINDING"
	)
	_add_control_row(
		"DEPLOY_CONTROL_AIM_FIRE",
		"DEPLOY_CONTROL_AIM_PRIMARY_BINDING",
		&"primary_fire"
	)
	_add_control_row(
		"ACTION_DASH",
		"DEPLOY_CONTROL_ACTION_BINDING",
		&"dash"
	)
	_add_control_row(
		"ACTION_EMP",
		"DEPLOY_CONTROL_ACTION_BINDING",
		&"active_skill"
	)


func _build_craft_preview() -> void:
	_craft_preview = Factory.preview_well(Vector2(150.0, 150.0))
	_craft_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_identity_box.add_child(_craft_preview)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_craft_preview.add_child(center)
	_craft_texture = TextureRect.new()
	_craft_texture.texture = SemanticAssets.texture(CRAFT_ASSET_ID)
	_craft_texture.custom_minimum_size = Vector2(126.0, 126.0)
	_craft_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_craft_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_craft_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_craft_texture.pivot_offset = Vector2(63.0, 63.0)
	_craft_texture.rotation = CRAFT_NOSE_UP_ROTATION
	center.add_child(_craft_texture)


func _build_footer() -> void:
	var deploy_lane := CenterContainer.new()
	add_child(deploy_lane)
	_command = Factory.command_button("DEPLOY_COMMAND", Factory.COMMAND_PRIMARY)
	_command.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_command, 22)
	_command.pressed.connect(
		func() -> void: deploy_requested.emit(&"pulse_cannon")
	)
	deploy_lane.add_child(_command)

	_secondary_actions = HBoxContainer.new()
	_secondary_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_secondary_actions.add_theme_constant_override("separation", 14)
	add_child(_secondary_actions)
	var settings := Factory.command_button(
		"SETTINGS_OPEN",
		Factory.COMMAND_SECONDARY
	)
	settings.custom_minimum_size.x = 140.0
	settings.pressed.connect(func() -> void: settings_requested.emit())
	_secondary_actions.add_child(settings)
	if OS.is_debug_build():
		var practice := Factory.command_button(
			"BOSS_PRACTICE_OPEN",
			Factory.COMMAND_SECONDARY
		)
		practice.custom_minimum_size.x = 180.0
		practice.pressed.connect(func() -> void: practice_requested.emit())
		_secondary_actions.add_child(practice)


func open(field_name_key: String) -> void:
	_field_name_key = field_name_key
	refresh_localized_content()
	_command.grab_focus()


func set_compact_mode(compact: bool) -> void:
	if _compact == compact and _body != null:
		return
	_compact = compact
	add_theme_constant_override("separation", 5 if compact else 8)
	_body.add_theme_constant_override("separation", 14 if compact else 24)
	_identity_box.add_theme_constant_override("separation", 5 if compact else 8)
	_controls_box.add_theme_constant_override("separation", 6 if compact else 10)
	Factory.apply_font_size(_title, 30 if compact else 42)
	Factory.apply_font_size(_field_label, 14 if compact else 16)
	_craft_preview.custom_minimum_size = (
		Vector2(104.0, 104.0) if compact else Vector2(150.0, 150.0)
	)
	_craft_texture.custom_minimum_size = (
		Vector2(88.0, 88.0) if compact else Vector2(126.0, 126.0)
	)
	_craft_texture.pivot_offset = _craft_texture.custom_minimum_size * 0.5
	_body_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
		if compact
		else ScrollContainer.SCROLL_MODE_DISABLED
	)
	for row in _control_rows:
		row.custom_minimum_size.y = 38.0 if compact else 44.0
		(row.get_child(0) as Label).custom_minimum_size.x = (
			112.0 if compact else 148.0
		)
	_command.custom_minimum_size = (
		Vector2(260.0, 44.0) if compact else Vector2(300.0, 48.0)
	)
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
	_field_label.visible = not _compact
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
			tr("DEPLOY_CONTROL_AIM_PRIMARY_BINDING").replace("%s", binding)
			if action == &"primary_fire"
			else tr("DEPLOY_CONTROL_ACTION_BINDING").replace("%s", binding)
		)


func debug_contract() -> Dictionary:
	return {
		"focusables":find_children("*", "Button", true, false).size(),
		"has_difficulty_ui":false,
		"control_rows":_control_rows.size(),
		"preview_asset_id":CRAFT_ASSET_ID,
		"preview_rotation":_craft_texture.rotation,
		"body_scroll":_body_scroll.vertical_scroll_mode,
		"body_ratios":[
			_identity_box.size_flags_stretch_ratio,
			_controls_box.size_flags_stretch_ratio,
		],
		"fixed_header":_field_label.get_parent() == self,
		"fixed_footer":_command.get_parent().get_parent() == self,
		"primary_size":_command.custom_minimum_size,
		"compact":_compact,
	}


func debug_submit() -> void:
	_command.pressed.emit()


func _add_control_row(
	title_key: String,
	binding_key: String,
	action: StringName = &""
) -> void:
	var row := Factory.text_row(title_key, binding_key, {
		"label_size":16,
		"value_size":15,
		"label_color":Art.TEXT_PRIMARY,
		"value_color":Art.MINT_SOFT,
	})
	row.custom_minimum_size.y = 44.0
	var value := row.get_child(1) as Label
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_controls_box.add_child(row)
	_control_rows.append(row)
	if not action.is_empty():
		_binding_labels[action] = value
