class_name VehicleDeploymentPanel
extends VBoxContainer

## Owns the fixed-Hard deployment composition and emits launch intent. The run
## remains the owner of loadout and combat state.

signal deploy_requested(primary_id: StringName)
signal settings_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const CRAFT_ASSET_ID := &"attachment/player_craft_body"
const CRAFT_NOSE_UP_ROTATION := -PI / 2.0

var _header: HBoxContainer
var _title: Label
var _settings_button: Button
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
var _actions: HBoxContainer
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
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 12)
	add_child(_header)
	_title = Factory.label("DEPLOY_TITLE", 42, Art.TEXT_PRIMARY)
	_title.theme_type_variation = &"DisplayLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(_title)
	_settings_button = Factory.icon_command_button(
		"⚙", "SETTINGS_TITLE", Factory.COMMAND_SECONDARY
	)
	_settings_button.name = "SettingsButton"
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_header.add_child(_settings_button)


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
		"ACTION_ACTIVE_WEAPON",
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
	_actions = HBoxContainer.new()
	_actions.name = "DeploymentActions"
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_actions.add_theme_constant_override("separation", 14)
	add_child(_actions)
	_command = Factory.command_button("DEPLOY_COMMAND", Factory.COMMAND_PRIMARY)
	_command.name = "DeployButton"
	_command.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_command, 22)
	_command.pressed.connect(
		func() -> void: deploy_requested.emit(&"pulse_cannon")
	)
	_actions.add_child(_command)


func open() -> void:
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
	_actions.add_theme_constant_override(
		"separation",
		10 if compact else 14
	)
	refresh_localized_content()


func refresh_localized_content() -> void:
	_title.text = tr("DEPLOY_TITLE")
	Factory.refresh_icon_command_button(_settings_button)
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
	var action_order := PackedStringArray()
	var action_variations := PackedStringArray()
	for child in _actions.get_children():
		if child is Button:
			var button := child as Button
			action_order.append(button.name)
			action_variations.append(String(button.theme_type_variation))
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
		"fixed_header":_header.get_parent() == self,
		"fixed_footer":_actions.get_parent() == self,
		"primary_size":_command.custom_minimum_size,
		"action_row_type":_actions.get_class(),
		"action_count":_actions.get_child_count(),
		"action_order":action_order,
		"action_variations":action_variations,
		"settings_in_header":_settings_button.get_parent() == _header,
		"settings_size":_settings_button.custom_minimum_size,
		"settings_accessibility_name":_settings_button.accessibility_name,
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
