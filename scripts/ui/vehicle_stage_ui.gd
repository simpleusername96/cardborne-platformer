class_name VehicleStageUI
extends CanvasLayer

## Routes run snapshots and UI intents between responsibility-shaped HUD and
## modal components. Screen layout construction belongs to those components.

signal deployment_selected(primary_id: StringName)
signal boss_practice_selected(request: Dictionary)
signal upgrade_selected(upgrade_id: StringName)
signal upgrade_previewed(upgrade_id: StringName)
signal pause_requested
signal resume_requested
signal restart_requested
signal garage_requested
signal replay_requested
signal stage_report_continued

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const VEHICLE_THEME = preload(
	"res://art/visuals/production/ui/vehicle_stage_theme.tres"
)
const GameplayHud = preload("res://scripts/ui/vehicle_gameplay_hud.gd")
const ModalHost = preload("res://scripts/ui/vehicle_modal_host.gd")
const DeploymentPanel = preload(
	"res://scripts/ui/vehicle_deployment_panel.gd"
)
const PausePanel = preload("res://scripts/ui/vehicle_pause_panel.gd")
const ResultPanel = preload("res://scripts/ui/vehicle_result_panel.gd")
const GaragePanel = preload("res://scripts/ui/vehicle_garage_panel.gd")
const BossPracticePanel = preload(
	"res://scripts/ui/vehicle_boss_practice_panel.gd"
)
const UpgradeChoicePanel = preload(
	"res://scripts/ui/vehicle_upgrade_choice_panel.gd"
)
const SettingsPanel = preload("res://scripts/ui/vehicle_settings_panel.gd")
const GuidebookPanel = preload("res://scripts/ui/vehicle_guidebook_panel.gd")
const StageReportPanel = preload(
	"res://scripts/ui/vehicle_stage_report_panel.gd"
)
const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const MODAL_MINIMUMS := {
	"deployment":Vector2(1176.0, 636.0),
	"upgrade":Vector2(1376.0, 616.0),
	"pause":Vector2(520.0, 430.0),
	"result":Vector2(900.0, 560.0),
	"report":Vector2(1200.0, 640.0),
	"garage":Vector2(960.0, 560.0),
	"settings":Vector2(920.0, 570.0),
	"guidebook":Vector2(1160.0, 636.0),
	"practice":Vector2(720.0, 610.0),
}

var _root: Control
var _dim: ColorRect
var _hud: VehicleGameplayHud
var _hosts: Dictionary = {}

var _deployment_panel: VehicleDeploymentPanel
var _upgrade_panel: VehicleUpgradeChoicePanel
var _pause_panel: VehiclePausePanel
var _result_panel: VehicleResultPanel
var _report_panel: VehicleStageReportPanel
var _garage_panel: VehicleGaragePanel
var _settings_panel: VehicleSettingsPanel
var _guide_panel: VehicleGuidebookPanel
var _practice_panel: VehicleBossPracticePanel

var _selected_primary := &"pulse_cannon"
var _selected_field_name_key := "FIELD_DROWNED_RUIN"
var _settings_return_surface := "deployment"
var _guide_return_surface := "pause"
var _latest_guidebook_snapshot: Dictionary = {}
var _latest_build_snapshot: Dictionary = {}
var _latest_upgrade_cards: Array[Dictionary] = []
var _latest_garage_data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_root()
	_install_components()
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_signal("locale_changed"):
		settings.locale_changed.connect(_on_locale_changed)
	if settings != null and settings.has_signal("controls_changed"):
		settings.controls_changed.connect(_on_controls_changed)
	_refresh_localized_content()
	_refresh_input_bindings()
	hide_all_modals()
	_hud.visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if _host_visible("pause"):
		resume_requested.emit()
	elif _hud.visible:
		pause_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func _create_root() -> void:
	_root = Control.new()
	_root.name = "VehicleStageUIRoot"
	_root.theme = VEHICLE_THEME
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_hud = GameplayHud.new()
	_root.add_child(_hud)

	_dim = ColorRect.new()
	_dim.name = "ModalDim"
	_dim.color = Art.DIM
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)


func _install_components() -> void:
	_deployment_panel = DeploymentPanel.new()
	_mount_modal("deployment", _deployment_panel)
	_deployment_panel.deploy_requested.connect(_on_deployment_selected)
	_deployment_panel.settings_requested.connect(
		_show_settings.bind("deployment")
	)
	_deployment_panel.practice_requested.connect(_show_boss_practice)

	_upgrade_panel = UpgradeChoicePanel.new()
	_mount_modal("upgrade", _upgrade_panel)
	_upgrade_panel.confirmed.connect(
		func(upgrade_id: StringName) -> void:
			upgrade_selected.emit(upgrade_id)
	)
	_upgrade_panel.selected.connect(
		func(upgrade_id: StringName) -> void:
			upgrade_previewed.emit(upgrade_id)
	)

	_pause_panel = PausePanel.new()
	_mount_modal("pause", _pause_panel)
	_pause_panel.resume_requested.connect(
		func() -> void: resume_requested.emit()
	)
	_pause_panel.restart_requested.connect(
		func() -> void: restart_requested.emit()
	)
	_pause_panel.garage_requested.connect(
		func() -> void: garage_requested.emit()
	)
	_pause_panel.settings_requested.connect(_show_settings.bind("pause"))
	_pause_panel.guide_requested.connect(_show_guidebook.bind("pause"))

	_result_panel = ResultPanel.new()
	_mount_modal("result", _result_panel)
	_result_panel.garage_requested.connect(
		func() -> void: garage_requested.emit()
	)
	_result_panel.replay_requested.connect(
		func() -> void: replay_requested.emit()
	)

	_report_panel = StageReportPanel.new()
	_mount_modal("report", _report_panel)
	_report_panel.continued.connect(
		func() -> void: stage_report_continued.emit()
	)
	_report_panel.garage_requested.connect(
		func() -> void: garage_requested.emit()
	)

	_garage_panel = GaragePanel.new()
	_mount_modal("garage", _garage_panel)
	_garage_panel.replay_requested.connect(
		func() -> void: replay_requested.emit()
	)
	_garage_panel.settings_requested.connect(_show_settings.bind("garage"))

	_settings_panel = SettingsPanel.new()
	_mount_modal("settings", _settings_panel)
	_settings_panel.close_requested.connect(_close_settings)
	_settings_panel.guide_requested.connect(
		_show_guidebook.bind("settings")
	)

	_guide_panel = GuidebookPanel.new()
	_mount_modal("guidebook", _guide_panel)
	_guide_panel.close_requested.connect(_close_guidebook)

	if OS.is_debug_build():
		_practice_panel = BossPracticePanel.new()
		_mount_modal("practice", _practice_panel)
		_practice_panel.selected.connect(
			func(request: Dictionary) -> void:
				boss_practice_selected.emit(request)
		)
		_practice_panel.back_requested.connect(show_deployment.bind(
			_selected_primary,
			_selected_field_name_key
		))


func _mount_modal(surface: String, content: Control) -> void:
	var host := ModalHost.new()
	host.name = "%sHost" % surface.capitalize().replace(" ", "")
	host.configure(content, Vector2(MODAL_MINIMUMS[surface]))
	_root.add_child(host)
	_hosts[surface] = host


func update_hud(snapshot: Dictionary) -> void:
	if snapshot.has("guidebook"):
		_latest_guidebook_snapshot = Dictionary(
			snapshot["guidebook"]
		).duplicate(true)
	if snapshot.has("build_snapshot"):
		_latest_build_snapshot = Dictionary(
			snapshot["build_snapshot"]
		).duplicate(true)
	_hud.update_snapshot(snapshot)


func show_deployment(
	selected: StringName = &"pulse_cannon",
	field_name_key: String = "FIELD_DROWNED_RUIN"
) -> void:
	hide_all_modals()
	_selected_primary = &"pulse_cannon" if selected.is_empty() else selected
	_selected_field_name_key = field_name_key
	_deployment_panel.open(_selected_field_name_key)
	_show_modal("deployment")


func show_upgrade(cards: Array[Dictionary]) -> void:
	hide_all_modals()
	_latest_upgrade_cards = cards.duplicate(true)
	_upgrade_panel.open(cards)
	_show_modal("upgrade")


func upgrade_apply_failed(reason: String) -> void:
	_upgrade_panel.apply_failed(reason)


func show_pause() -> void:
	hide_all_modals()
	_pause_panel.open()
	_show_modal("pause")


func show_result(summary: Dictionary) -> void:
	if not _result_panel.open(summary):
		return
	hide_all_modals()
	_show_modal("result")


func show_garage(data: Dictionary) -> void:
	hide_all_modals()
	_latest_garage_data = data.duplicate(true)
	_selected_primary = &"pulse_cannon"
	_garage_panel.open(data)
	_show_modal("garage")


func show_gameplay() -> void:
	hide_all_modals()
	_hud.visible = true


func debug_health_animation_contract() -> Dictionary:
	return _hud.debug_health_animation_contract()


func debug_submit_deployment() -> void:
	_deployment_panel.debug_submit()


func show_stage_report(snapshot: Dictionary) -> void:
	hide_all_modals()
	_report_panel.open(snapshot)
	_show_modal("report")


func hide_all_modals() -> void:
	if _dim == null:
		return
	_dim.visible = false
	for host_variant in _hosts.values():
		(host_variant as VehicleModalHost).visible = false


func notify(
	message: String,
	duration: float = 2.4,
	color: Color = Art.IVORY_BRIGHT
) -> void:
	_hud.notify(message, duration, color)


func notify_immediate(
	message: String,
	duration: float = 2.4,
	color: Color = Art.IVORY_BRIGHT
) -> void:
	_hud.notify_immediate(message, duration, color)


func clear_notifications() -> void:
	_hud.clear_notifications()


func debug_notification_contract() -> Dictionary:
	return _hud.debug_notification_contract()


func set_hud_visible(next_visible: bool) -> void:
	_hud.visible = next_visible


func is_modal_visible() -> bool:
	return _dim.visible


func debug_surface_visible(surface: String) -> bool:
	return _host_visible(surface)


func debug_hud_visible() -> bool:
	return _hud.visible


func debug_layout_minimums() -> Dictionary:
	return MODAL_MINIMUMS.duplicate(true)


func debug_modal_geometry(surface: String) -> Dictionary:
	var host := _host(surface)
	var content := host.content
	return {
		"viewport_rect":Rect2(Vector2.ZERO, _root.size),
		"host_rect":host.get_global_rect(),
		"surface_rect":host.surface_rect(),
		"content_rect":(
			content.get_global_rect()
			if content != null
			else Rect2()
		),
		"content_minimum":(
			content.get_combined_minimum_size()
			if content != null
			else Vector2.ZERO
		),
		"host":host.debug_contract(),
	}


func debug_ui_contract(viewport_width: float = 1280.0) -> Dictionary:
	var compact := viewport_width < 1100.0
	var viewport_height := viewport_width * 9.0 / 16.0
	# This debug contract is parameterized by width, so probe the deployment
	# responsive state for the same width instead of whichever test viewport
	# happened to settle first.
	_deployment_panel.set_compact_mode(compact)
	var deployment_surface_size := Vector2(
		minf(
			MODAL_MINIMUMS["deployment"].x,
			viewport_width - 48.0
		),
		minf(
			MODAL_MINIMUMS["deployment"].y,
			viewport_height - 24.0
		)
	)
	var body_font_weight := 0.0
	if _root.theme.default_font is FontVariation:
		body_font_weight = float(
			(_root.theme.default_font as FontVariation)
			.variation_opentype.get("weight", 0.0)
		)
	var hud_contract := _hud.debug_contract(viewport_width)
	var deployment_contract := _deployment_panel.debug_contract()
	var pause_contract := _pause_panel.debug_contract()
	var result_contract := _result_panel.debug_contract()
	var garage_contract := _garage_panel.debug_contract()
	var contract := {
		"theme_path":(
			_root.theme.resource_path
			if _root.theme != null
			else ""
		),
		"ui_foundation":{
			"loaded":_root.theme != null,
			"provider":"res://art/visuals/production/ui/vehicle_stage_theme.tres",
			"modal_surface_count":find_children(
				"*",
				"VehicleModalSurface",
				true,
				false
			).size(),
			"modal_frame":(
				_host("deployment").surface.call("debug_contract")
				if _host("deployment").surface != null
				else {}
			),
			"texture_filter":_root.texture_filter,
		},
		"shared_style_foundation":{
			"modal":(
				_root.theme.get_stylebox(
					&"panel",
					&"ModalSurface"
				) is StyleBoxFlat
			),
			"hud":(
				_root.theme.get_stylebox(
					&"panel",
					&"HudSurface"
				) is StyleBoxFlat
			),
			"button":(
				_root.theme.get_stylebox(
					&"normal",
					&"Button"
				) is StyleBoxFlat
			),
			"upgrade_card":(
				_root.theme.get_stylebox(
					&"normal",
					&"SelectableButton"
				) is StyleBoxFlat
			),
			"tab":(
				_root.theme.get_stylebox(
					&"tab_selected",
					&"TabBar"
				) is StyleBoxFlat
			),
			"non_code_native_style_count":_theme_non_code_native_style_count(),
		},
		"command_min_height":pause_contract["command_min_height"],
		"body_font_weight":body_font_weight,
		"deployment_focusables":deployment_contract["focusables"],
		"deployment_has_difficulty_ui":deployment_contract["has_difficulty_ui"],
		"deployment_control_rows":deployment_contract["control_rows"],
		"deployment_preview_asset_id":deployment_contract["preview_asset_id"],
		"deployment_preview_rotation":deployment_contract["preview_rotation"],
		"deployment_body_scroll":deployment_contract["body_scroll"],
		"deployment_body_ratios":deployment_contract["body_ratios"],
		"deployment_fixed_header":deployment_contract["fixed_header"],
		"deployment_fixed_footer":deployment_contract["fixed_footer"],
		"deployment_action_row_type":deployment_contract["action_row_type"],
		"deployment_action_count":deployment_contract["action_count"],
		"deployment_action_order":deployment_contract["action_order"],
		"deployment_action_variations":deployment_contract["action_variations"],
		"deployment_compact":deployment_contract["compact"],
		"deployment_primary_size":deployment_contract["primary_size"],
		"deployment_surface_size":deployment_surface_size,
		"display_font_size":_root.theme.get_font_size(
			&"font_size",
			&"DisplayLabel"
		),
		"modal_minimums":debug_layout_minimums(),
		"upgrade_focusables":_host("upgrade").find_children(
			"*",
			"Button",
			true,
			false
		).size(),
		"upgrade_choice":_upgrade_panel.debug_contract(),
		"has_selectable_theme":(
			_root.theme.get_type_variation_base(
				&"SelectableButton"
			) == &"Button"
			and _root.theme.get_type_variation_base(
				&"SelectedSelectableButton"
			) == &"Button"
		),
		"has_danger_theme":(
			_root.theme.get_type_variation_base(
				&"DangerButton"
			) == &"Button"
		),
		"pause_focusables":pause_contract["focusables"],
		"pause_abort_variation":pause_contract["abort_variation"],
		"pause_command_stack_type":pause_contract["command_stack_type"],
		"pause_command_order":pause_contract["command_order"],
		"pause_command_widths":pause_contract["command_widths"],
		"result_focusables":result_contract["focusables"],
		"garage_focusables":garage_contract["focusables"],
		"garage_columns":garage_contract["columns"],
		"garage_rows":garage_contract["rows"],
		"garage_nested_summary_panel":garage_contract["nested_summary_panel"],
		"garage_primary_action":garage_contract["primary_action"],
		"garage_secondary_action":garage_contract["secondary_action"],
		"locale":TranslationServer.get_locale().left(2),
		"settings":_settings_panel.debug_contract(),
		"component_owners":{
			"hud":_hud.get_script().resource_path,
			"deployment":_deployment_panel.get_script().resource_path,
			"pause":_pause_panel.get_script().resource_path,
			"guidebook":_guide_panel.get_script().resource_path,
			"result":_result_panel.get_script().resource_path,
			"garage":_garage_panel.get_script().resource_path,
			"practice":(
				_practice_panel.get_script().resource_path
				if _practice_panel != null
				else ""
			),
		},
	}
	contract.merge(hud_contract, true)
	return contract


func _theme_non_code_native_style_count() -> int:
	var count := 0
	for theme_type in _root.theme.get_type_list():
		for style_name in _root.theme.get_stylebox_list(theme_type):
			var style := _root.theme.get_stylebox(style_name, theme_type)
			if not (style is StyleBoxFlat or style is StyleBoxLine or style is StyleBoxEmpty):
				count += 1
	return count


func debug_set_text_scale(scale: float) -> void:
	# Capture-only accessibility probe: image chrome remains unchanged while
	# the localized dynamic text layer is magnified.
	var clamped := clampf(scale, 1.0, 2.0)
	VehicleUiComponentFactory.set_debug_text_scale(clamped)
	var scaled_theme := VEHICLE_THEME.duplicate(true) as Theme
	scaled_theme.default_font_size = maxi(
		1,
		roundi(float(VEHICLE_THEME.default_font_size) * clamped)
	)
	for type_name in scaled_theme.get_type_list():
		for font_size_name in scaled_theme.get_font_size_list(type_name):
			var base_size := VEHICLE_THEME.get_font_size(
				font_size_name,
				type_name
			)
			scaled_theme.set_font_size(
				font_size_name,
				type_name,
				maxi(1, roundi(float(base_size) * clamped))
			)
	_root.theme = scaled_theme
	for host_variant in _hosts.values():
		(host_variant as VehicleModalHost).set_accessibility_compact(clamped > 1.0)
	_hud.set_accessibility_text_scale(clamped)
	_scale_local_font_overrides(_root, clamped)


func _scale_local_font_overrides(node: Node, scale: float) -> void:
	if node is Control:
		var control := node as Control
		if control.has_theme_font_size_override(&"font_size"):
			var current := control.get_theme_font_size(&"font_size")
			var base := int(control.get_meta(&"capture_base_font_size", current))
			var applied := int(control.get_meta(&"capture_applied_font_size", current))
			if current != applied:
				base = current
			var scaled := maxi(1, roundi(float(base) * scale))
			control.set_meta(&"capture_base_font_size", base)
			control.set_meta(&"capture_applied_font_size", scaled)
			control.add_theme_font_size_override(&"font_size", scaled)
	for child in node.get_children():
		_scale_local_font_overrides(child, scale)


func debug_modal_contract(
	surface: String,
	result_stage_title_key: String = "STAGE_DROWNED_RUINS_1"
) -> Dictionary:
	match surface:
		"deployment":
			show_deployment(
				_selected_primary,
				_selected_field_name_key
			)
		"upgrade":
			show_upgrade([])
		"pause":
			show_pause()
		"result":
			show_result({
				"stage_number":1,
				"stage_title_key":result_stage_title_key,
				"has_next_stage":true,
				"upgrade":"UPGRADE_NONE",
			})
		"report":
			show_stage_report({})
		"garage":
			show_garage({})
		"settings":
			_show_settings("deployment")
		"guidebook":
			_show_guidebook("settings")
		"practice":
			_show_boss_practice()
	return {
		"surface":surface,
		"hud_hidden":not _hud.visible,
		"dim_visible":_dim.visible,
		"result_kicker":_result_panel.kicker_text(),
		"host":(
			_host(surface).debug_contract()
			if _hosts.has(surface)
			else {}
		),
	}


func debug_gameplay_settings_contract() -> Dictionary:
	_show_settings("deployment")
	_settings_panel.debug_show_gameplay_page()
	return _settings_panel.debug_contract()


func debug_active_settings_contract() -> Dictionary:
	_show_settings("pause")
	return _settings_panel.debug_contract()


func debug_guide_entry(
	snapshot: Dictionary,
	category: StringName,
	entry_id: StringName
) -> bool:
	_latest_guidebook_snapshot = snapshot.duplicate(true)
	_show_guidebook("settings")
	return _guide_panel.debug_select_entry(category, entry_id)


func debug_select_upgrade(index: int) -> void:
	_upgrade_panel.call("_process", 0.36)
	_upgrade_panel.call("_select", index)


func debug_upgrade_geometry() -> Dictionary:
	return {
		"viewport_rect":Rect2(Vector2.ZERO, _root.size),
		"surface_rect":_host("upgrade").surface_rect(),
		"panel":_upgrade_panel.debug_geometry_contract(),
	}


func debug_practice_option_texts() -> PackedStringArray:
	return (
		_practice_panel.debug_option_texts()
		if _practice_panel != null
		else PackedStringArray()
	)


func debug_threat_radar_contract() -> Dictionary:
	return _hud.debug_threat_radar_contract()


func _show_modal(surface: String) -> void:
	_dim.visible = true
	_hud.visible = false
	var host := _host(surface)
	host.visible = true
	host.refresh_layout()


func _show_settings(return_surface: String) -> void:
	_settings_return_surface = return_surface
	hide_all_modals()
	_settings_panel.set_build_snapshot(
		_latest_build_snapshot
		if return_surface == "pause"
		else {}
	)
	_settings_panel.open()
	_show_modal("settings")


func _close_settings() -> void:
	match _settings_return_surface:
		"pause":
			show_pause()
		"garage":
			show_garage(_latest_garage_data)
		_:
			show_deployment(
				_selected_primary,
				_selected_field_name_key
			)


func _show_guidebook(return_surface: String) -> void:
	_guide_return_surface = return_surface
	hide_all_modals()
	_guide_panel.open(_latest_guidebook_snapshot)
	_show_modal("guidebook")


func _close_guidebook() -> void:
	if _guide_return_surface == "settings":
		_show_settings(_settings_return_surface)
	else:
		show_pause()


func _show_boss_practice() -> void:
	if _practice_panel == null:
		return
	hide_all_modals()
	_practice_panel.open()
	_show_modal("practice")


func _on_deployment_selected(primary_id: StringName) -> void:
	_selected_primary = primary_id
	deployment_selected.emit(primary_id)


func _on_locale_changed(_locale: String) -> void:
	_refresh_localized_content()


func _refresh_localized_content() -> void:
	_deployment_panel.refresh_localized_content()
	_result_panel.refresh_localized_content()
	_garage_panel.refresh_localized_content()
	_guide_panel.refresh_localized_content()
	_hud.refresh_localized_content()
	if _practice_panel != null:
		_practice_panel.refresh_localized_content()
	if not _latest_upgrade_cards.is_empty() and _host_visible("upgrade"):
		_upgrade_panel.open(_latest_upgrade_cards)


func _on_controls_changed(_action: StringName) -> void:
	_refresh_input_bindings()


func _refresh_input_bindings() -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	var bindings := InputProfile.default_descriptors()
	if settings != null:
		bindings = settings.control_bindings
	_deployment_panel.refresh_input_bindings(bindings)


func _host(surface: String) -> VehicleModalHost:
	return _hosts[surface] as VehicleModalHost


func _host_visible(surface: String) -> bool:
	return _hosts.has(surface) and _host(surface).visible
