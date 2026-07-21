class_name VehicleStageUI
extends CanvasLayer

## Runtime-built HUD and modal surfaces for the vehicle Stage 1 slice.
## The UI presents snapshots and emits intents; the stage remains the gameplay owner.

signal deployment_selected(primary_id: StringName)
signal upgrade_selected(upgrade_id: StringName)
signal resume_requested
signal restart_requested
signal garage_requested
signal replay_requested
signal advance_requested
signal primary_changed(primary_id: StringName)

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const VEHICLE_THEME = preload("res://art/ui/production/vehicle_stage_theme.tres")

const CANVAS := Art.COBALT_VOID
const SURFACE := Art.IVORY
const RAISED := Art.CERAMIC_GREEN
const CYAN := Art.COBALT_WATER
const MOSS := Art.MINT
const AMBER := Art.MUSTARD
const CORAL := Art.CORAL
const OFF_WHITE := Art.IVORY_BRIGHT
const MUTED := Art.INK_MUTED
const VIOLET := Art.BOSS_MAGENTA
const INK := Art.INK


class HealthPips:
	extends Control

	var health := 120.0
	var maximum := 120.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(194.0, 42.0)

	func set_values(value: float, max_value: float) -> void:
		health = value
		maximum = maxf(1.0, max_value)
		queue_redraw()

	func _draw() -> void:
		var ratio := clampf(health / maximum, 0.0, 1.0)
		for index in 5:
			var center := Vector2(18.0 + float(index) * maxf(36.0, (size.x - 36.0) / 4.0), 21.0)
			draw_circle(center + Vector2(3.0, 4.0), 15.0, Art.COBALT_DEEP)
			draw_circle(center, 15.0, Art.MINT_SOFT)
			var pip_fill := clampf(ratio * 5.0 - float(index), 0.0, 1.0)
			if pip_fill > 0.0:
				draw_circle(center, 12.0 * pip_fill, Art.CORAL)
				draw_circle(center, 4.0, Art.IVORY_BRIGHT)


class ActionRailSlot:
	extends Control

	var binding := ""
	var action_name := ""
	var state_text := "READY"
	var accent := Art.MUSTARD
	var cooldown_ratio := 0.0
	var segment_count := 0
	var filled_segments := 0
	var is_primary := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(244.0, 72.0) if is_primary else Vector2(140.0, 72.0)

	func configure(key_text: String, title: String, color: Color, primary: bool = false) -> void:
		binding = key_text
		action_name = title
		accent = color
		is_primary = primary
		custom_minimum_size = Vector2(244.0, 72.0) if is_primary else Vector2(140.0, 72.0)
		queue_redraw()

	func set_state(value: String, ratio: float = 0.0, current_segments: int = 0, maximum_segments: int = 0) -> void:
		state_text = value
		cooldown_ratio = clampf(ratio, 0.0, 1.0)
		filled_segments = maxi(0, current_segments)
		segment_count = maxi(0, maximum_segments)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Art.IVORY_BRIGHT, 0.98))
		draw_rect(Rect2(0.0, 0.0, 6.0, size.y), accent)
		var font := get_theme_default_font()
		if is_primary:
			draw_string(font, Vector2(14.0, 21.0), binding, HORIZONTAL_ALIGNMENT_LEFT, 88.0, 13, accent)
			draw_string(font, Vector2(110.0, 22.0), tr(action_name), HORIZONTAL_ALIGNMENT_LEFT, size.x - 124.0, 16, Art.INK)
		else:
			draw_string(font, Vector2(14.0, 22.0), tr(action_name), HORIZONTAL_ALIGNMENT_LEFT, 66.0, 16, Art.INK)
			draw_string(font, Vector2(80.0, 21.0), binding, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 94.0, 13, accent)
		draw_string(font, Vector2(14.0, 48.0), tr(state_text), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 14, Art.INK)
		var meter_rect := Rect2(14.0, size.y - 12.0, size.x - 28.0, 7.0)
		if is_primary and segment_count > 0:
			var gap := 4.0
			var segment_width := (meter_rect.size.x - gap * float(segment_count - 1)) / float(segment_count)
			for index in segment_count:
				var segment_rect := Rect2(
					meter_rect.position + Vector2(float(index) * (segment_width + gap), 0.0),
					Vector2(segment_width, meter_rect.size.y)
				)
				draw_rect(segment_rect, accent if index < filled_segments else Art.CERAMIC_GREEN_MID)
			if filled_segments < segment_count and cooldown_ratio > 0.0:
				draw_rect(Rect2(meter_rect.position, Vector2(meter_rect.size.x * cooldown_ratio, 2.0)), accent)
		else:
			draw_rect(meter_rect, Art.CERAMIC_GREEN_MID)
			var fill_ratio := cooldown_ratio if is_primary else 1.0 - cooldown_ratio
			draw_rect(Rect2(meter_rect.position, Vector2(meter_rect.size.x * fill_ratio, meter_rect.size.y)), accent)

class StageMinimap:
	extends Control

	var snapshot: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(176.0, 98.0)

	func set_snapshot(value: Dictionary) -> void:
		snapshot = value.duplicate(true)
		queue_redraw()

	func _draw() -> void:
		var panel_rect := Rect2(Vector2.ZERO, size)
		draw_rect(panel_rect, Art.IVORY_BRIGHT)
		var cols: int = int(snapshot.get("cols", 13))
		var rows: int = int(snapshot.get("rows", 6))
		var cell_size := Vector2(size.x / float(cols), size.y / float(rows))
		var visited: Array = snapshot.get("visited", [])
		for cell_variant in visited:
			var cell: Vector2i = cell_variant
			var rect := Rect2(Vector2(cell.x, cell.y) * cell_size, cell_size - Vector2.ONE)
			draw_rect(rect, Art.CERAMIC_GREEN_MID)
		for marker_variant in snapshot.get("markers", []):
			var marker: Dictionary = marker_variant
			if not bool(marker.get("discovered", false)):
				continue
			var world: Vector2 = marker.get("position", Vector2.ZERO)
			var world_size: Vector2 = snapshot.get("world_size", Vector2(5200.0, 2200.0))
			var point := Vector2(world.x / world_size.x * size.x, world.y / world_size.y * size.y)
			var marker_color: Color = marker.get("color", Art.MUSTARD)
			var kind := String(marker.get("kind", "point"))
			if kind == "boss":
				draw_colored_polygon(PackedVector2Array([
					point + Vector2(0.0, -5.0),
					point + Vector2(5.0, 4.0),
					point + Vector2(-5.0, 4.0),
				]), marker_color)
			elif kind == "objective":
				draw_rect(Rect2(point - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), marker_color)
			elif kind == "reward":
				draw_colored_polygon(_diamond(point, 5.0), marker_color)
			else:
				draw_circle(point, 4.0, marker_color)
		var player: Vector2 = snapshot.get("player", Vector2.ZERO)
		var player_world_size: Vector2 = snapshot.get("world_size", Vector2(5200.0, 2200.0))
		var player_point := Vector2(player.x / player_world_size.x * size.x, player.y / player_world_size.y * size.y)
		draw_colored_polygon(PackedVector2Array([
			player_point + Vector2(0.0, -6.0),
			player_point + Vector2(5.0, 5.0),
			player_point + Vector2(-5.0, 5.0),
		]), Art.MUSTARD)

	func _diamond(center: Vector2, radius: float) -> PackedVector2Array:
		return PackedVector2Array([
			center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
			center + Vector2(0.0, radius), center + Vector2(-radius, 0.0),
		])


var _root: Control
var _hud: Control
var _health_panel: PanelContainer
var _objective_panel: PanelContainer
var _minimap_panel: PanelContainer
var _target_panel: PanelContainer
var _dock_panel: PanelContainer
var _health_bar: HealthPips
var _health_value: Label
var _objective_label: Label
var _objective_detail: Label
var _boss_cluster: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_state: Label
var _target_cluster: VBoxContainer
var _target_name: Label
var _target_bar: ProgressBar
var _target_state: Label
var _primary_slot: ActionRailSlot
var _dash_slot: ActionRailSlot
var _passive_slot: ActionRailSlot
var _skill_slot: ActionRailSlot
var _buff_label: Label
var _minimap: StageMinimap
var _minimap_title: Label
var _notification: Label
var _notification_timer := 0.0

var _dim: ColorRect
var _deployment_center: CenterContainer
var _upgrade_center: CenterContainer
var _pause_center: CenterContainer
var _result_center: CenterContainer
var _garage_center: CenterContainer
var _deployment_buttons: Array[Button] = []
var _deployment_command: Button
var _upgrade_buttons: Array[Button] = []
var _pause_first_button: Button
var _result_first_button: Button
var _result_kicker: Label
var _result_title: Label
var _result_continue_button: Button
var _result_garage_button: Button
var _garage_first_button: Button
var _garage_primary_label: Label
var _garage_passive_label: Label
var _garage_active_label: Label
var _garage_unlock_label: Label
var _garage_summary_label: Label
var _selected_primary := &"repeater"
var _locale_buttons: Array[Button] = []
var _latest_upgrade_cards: Array[Dictionary] = []
var _latest_result_summary: Dictionary = {}
var _latest_garage_data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_build_hud()
	_build_deployment()
	_build_upgrade()
	_build_pause()
	_build_result()
	_build_garage()
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_signal("locale_changed"):
		settings.locale_changed.connect(_on_locale_changed)
	_refresh_localized_content()
	hide_all_modals()
	_hud.visible = false


func _process(delta: float) -> void:
	if _notification_timer > 0.0:
		_notification_timer = maxf(0.0, _notification_timer - delta)
		_notification.modulate.a = minf(1.0, _notification_timer * 3.0)
		if _notification_timer <= 0.0:
			_notification.visible = false


func _build_root() -> void:
	_root = Control.new()
	_root.name = "VehicleStageUIRoot"
	_root.theme = VEHICLE_THEME
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.resized.connect(_apply_responsive_layout)

	_dim = ColorRect.new()
	_dim.name = "ModalDim"
	_dim.color = Art.DIM
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)

	_notification = Label.new()
	_notification.name = "Notification"
	_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notification.add_theme_font_size_override("font_size", 18)
	_notification.add_theme_color_override("font_color", OFF_WHITE)
	_notification.add_theme_color_override("font_shadow_color", CANVAS)
	_notification.add_theme_constant_override("shadow_offset_x", 2)
	_notification.add_theme_constant_override("shadow_offset_y", 2)
	_notification.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_notification.position = Vector2(380.0, 102.0)
	_notification.size = Vector2(520.0, 44.0)
	_notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification.visible = false
	_root.add_child(_notification)


func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "GameplayHUD"
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_hud)

	_health_panel = _flat_panel()
	_health_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health_panel.position = Vector2(18.0, 16.0)
	_health_panel.size = Vector2(282.0, 84.0)
	_hud.add_child(_health_panel)
	var health_box := VBoxContainer.new()
	health_box.add_theme_constant_override("separation", 0)
	_health_panel.add_child(health_box)
	var health_header := HBoxContainer.new()
	health_box.add_child(health_header)
	var hull_label := _label("UI_HULL_INTEGRITY", 13, INK)
	hull_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_header.add_child(hull_label)
	_health_value = _label("120 / 120", 14, CORAL)
	health_header.add_child(_health_value)
	_health_bar = HealthPips.new()
	health_box.add_child(_health_bar)

	_objective_panel = _flat_panel()
	_objective_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective_panel.position = Vector2(390.0, 16.0)
	_objective_panel.custom_minimum_size = Vector2(500.0, 72.0)
	_objective_panel.size = Vector2(500.0, 72.0)
	_hud.add_child(_objective_panel)
	var objective_box := VBoxContainer.new()
	objective_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_objective_panel.add_child(objective_box)
	_objective_label = _label("OBJECTIVE_CALIBRATE", 19, INK)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_box.add_child(_objective_label)
	_objective_detail = _label("DEPLOY_SELECT_PROMPT", 13, MUTED)
	_objective_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_box.add_child(_objective_detail)

	_minimap_panel = _flat_panel()
	_minimap_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_minimap_panel.position = Vector2(1044.0, 16.0)
	_minimap_panel.size = Vector2(218.0, 144.0)
	_hud.add_child(_minimap_panel)
	var minimap_box := VBoxContainer.new()
	_minimap_panel.add_child(minimap_box)
	_minimap_title = _label("UI_FLOODED_WORKS", 12, INK)
	minimap_box.add_child(_minimap_title)
	_minimap = StageMinimap.new()
	_minimap.custom_minimum_size = Vector2(190.0, 104.0)
	minimap_box.add_child(_minimap)

	_boss_cluster = VBoxContainer.new()
	_boss_cluster.name = "BossCluster"
	_boss_cluster.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_boss_cluster.position = Vector2(320.0, 100.0)
	_boss_cluster.size = Vector2(640.0, 66.0)
	_boss_cluster.add_theme_constant_override("separation", 1)
	_hud.add_child(_boss_cluster)
	_boss_name = _label("ENEMY_FOUNDRY_COLOSSUS", 16, OFF_WHITE)
	_boss_name.add_theme_color_override("font_shadow_color", CANVAS)
	_boss_name.add_theme_constant_override("shadow_offset_x", 2)
	_boss_name.add_theme_constant_override("shadow_offset_y", 2)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_cluster.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.theme_type_variation = &"BossMeter"
	_boss_bar.show_percentage = false
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	_boss_bar.custom_minimum_size = Vector2(640.0, 18.0)
	_boss_cluster.add_child(_boss_bar)
	_boss_state = _label("PATTERN_READING_ARENA", 12, OFF_WHITE)
	_boss_state.add_theme_color_override("font_shadow_color", CANVAS)
	_boss_state.add_theme_constant_override("shadow_offset_x", 2)
	_boss_state.add_theme_constant_override("shadow_offset_y", 2)
	_boss_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_cluster.add_child(_boss_state)
	_boss_cluster.visible = false

	_target_panel = _flat_panel()
	_target_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_target_panel.position = Vector2(1022.0, 298.0)
	_target_panel.size = Vector2(240.0, 124.0)
	_hud.add_child(_target_panel)
	_target_cluster = VBoxContainer.new()
	_target_panel.add_child(_target_cluster)
	var target_header := _label("UI_LOCKED_TARGET", 12, CORAL)
	_target_cluster.add_child(target_header)
	_target_name = _label("—", 16, INK)
	_target_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_cluster.add_child(_target_name)
	_target_bar = ProgressBar.new()
	_target_bar.show_percentage = false
	_target_bar.max_value = 1.0
	_target_bar.value = 1.0
	_target_bar.theme_type_variation = &"HealthMeter"
	_target_bar.custom_minimum_size = Vector2(204.0, 14.0)
	_target_cluster.add_child(_target_bar)
	_target_state = _label("", 12, MUTED)
	_target_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_cluster.add_child(_target_state)
	_target_panel.visible = false
	_target_cluster.set_meta("panel", _target_panel)

	_dock_panel = _flat_panel()
	_dock_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_dock_panel.position = Vector2(278.0, 628.0)
	_dock_panel.size = Vector2(724.0, 82.0)
	_hud.add_child(_dock_panel)
	var dock := HBoxContainer.new()
	dock.add_theme_constant_override("separation", 6)
	_dock_panel.add_child(dock)
	_primary_slot = _action_slot(dock, "SHIFT / LMB", "ACTION_PRIMARY", AMBER, true)
	_passive_slot = _action_slot(dock, "AUTO", "ACTION_SEEKER", MOSS)
	_dash_slot = _action_slot(dock, "SPACE", "ACTION_DASH", CYAN)
	_skill_slot = _action_slot(dock, "Z", "ACTION_EMP", VIOLET)

	_buff_label = _label("", 13, OFF_WHITE)
	_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buff_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_buff_label.position = Vector2(340.0, 596.0)
	_buff_label.size = Vector2(600.0, 28.0)
	_buff_label.add_theme_color_override("font_shadow_color", CANVAS)
	_buff_label.add_theme_constant_override("shadow_offset_x", 2)
	_buff_label.add_theme_constant_override("shadow_offset_y", 2)
	_hud.add_child(_buff_label)
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	if not is_instance_valid(_root) or not is_instance_valid(_objective_panel):
		return
	var compact := _root.size.x < 1100.0
	var objective_width := 360.0 if compact else 500.0
	var health_size := Vector2(232.0, 76.0) if compact else Vector2(282.0, 84.0)
	_health_panel.size = health_size
	_objective_panel.position = Vector2((_root.size.x - objective_width) * 0.5, 16.0)
	_objective_panel.custom_minimum_size = Vector2(objective_width, 72.0)
	_objective_panel.size = Vector2(objective_width, 72.0)
	var minimap_size := Vector2(180.0, 118.0) if compact else Vector2(218.0, 144.0)
	_minimap_panel.size = minimap_size
	_minimap_panel.position = Vector2(_root.size.x - minimap_size.x - 18.0, 16.0)
	_minimap.custom_minimum_size = Vector2(150.0, 76.0) if compact else Vector2(190.0, 104.0)
	var boss_left := health_size.x + 52.0 if compact else (_root.size.x - 640.0) * 0.5
	var boss_width := _root.size.x - boss_left - 18.0 if compact else 640.0
	_boss_cluster.position = Vector2(boss_left, 16.0)
	_boss_cluster.size.x = boss_width
	_boss_bar.custom_minimum_size.x = boss_width
	var target_size := Vector2(210.0, 108.0) if compact else Vector2(240.0, 124.0)
	_target_panel.size = target_size
	_target_panel.position = Vector2(_root.size.x - target_size.x - 18.0, _root.size.y - target_size.y - 112.0)
	var dock_width := minf(724.0, _root.size.x - 36.0)
	_dock_panel.size = Vector2(dock_width, 82.0)
	_dock_panel.position = Vector2((_root.size.x - dock_width) * 0.5, _root.size.y - 94.0)
	_buff_label.position = Vector2((_root.size.x - 600.0) * 0.5, _root.size.y - 120.0)
	_objective_detail.add_theme_font_size_override("font_size", 12 if compact else 13)
	_notification.size.x = 420.0 if compact else 520.0
	_notification.position.x = (_root.size.x - _notification.size.x) * 0.5
	_notification.position.y = 94.0 if _boss_cluster.visible else 102.0


func _build_deployment() -> void:
	_deployment_center = CenterContainer.new()
	_deployment_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_deployment_center)
	var panel := _modal_panel(Vector2(840.0, 500.0))
	_deployment_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_language_selector())
	var kicker := _label("DEPLOY_KICKER", 14, AMBER)
	box.add_child(kicker)
	var title := _label("DEPLOY_TITLE", 30, INK)
	box.add_child(title)
	var body := _label("DEPLOY_CONTROLS", 15, MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 36.0
	box.add_child(body)
	var choice_row := HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 12)
	choice_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(choice_row)
	var repeater := _choice_button("", Vector2(380.0, 174.0))
	repeater.set_meta("primary_id", &"repeater")
	repeater.pressed.connect(_on_deployment_choice.bind(&"repeater"))
	choice_row.add_child(repeater)
	_deployment_buttons.append(repeater)
	var scatter := _choice_button("", Vector2(380.0, 174.0))
	scatter.set_meta("primary_id", &"scatter")
	scatter.pressed.connect(_on_deployment_choice.bind(&"scatter"))
	choice_row.add_child(scatter)
	_deployment_buttons.append(scatter)
	_deployment_command = _command_button("DEPLOY_COMMAND", &"PrimaryButton")
	_deployment_command.pressed.connect(_on_deployment_confirmed)
	box.add_child(_deployment_command)
	var footer := _label("DEPLOY_FOOTER", 13, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)


func _build_upgrade() -> void:
	_upgrade_center = CenterContainer.new()
	_upgrade_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_upgrade_center)
	var panel := _modal_panel(Vector2(900.0, 470.0))
	_upgrade_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var kicker := _label("UPGRADE_KICKER", 14, AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var title := _label("UPGRADE_TITLE", 27, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var detail := _label("UPGRADE_DETAIL", 14, MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(detail)
	var row := HBoxContainer.new()
	row.name = "UpgradeButtons"
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	for index in 3:
		var button := _choice_button("", Vector2(272.0, 278.0))
		button.name = "UpgradeCard%d" % (index + 1)
		button.pressed.connect(_on_upgrade_button_pressed.bind(button))
		row.add_child(button)
		_upgrade_buttons.append(button)


func _build_pause() -> void:
	_pause_center = CenterContainer.new()
	_pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_pause_center)
	var panel := _modal_panel(Vector2(560.0, 500.0))
	_pause_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := _label("PAUSE_TITLE", 30, INK)
	box.add_child(title)
	var resume := _command_button("PAUSE_RESUME", &"PrimaryButton")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	box.add_child(resume)
	_pause_first_button = resume
	var restart := _command_button("PAUSE_RESTART", &"SecondaryButton")
	restart.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart)
	box.add_child(_label("PAUSE_SETTINGS", 15, AMBER))
	box.add_child(_label("PAUSE_MASTER_VOLUME", 13, INK))
	var master := HSlider.new()
	master.name = "MasterVolume"
	master.min_value = 0.0
	master.max_value = 1.0
	master.step = 0.05
	master.value = _settings_value("master_volume", 1.0)
	master.value_changed.connect(_on_master_volume_changed)
	box.add_child(master)
	box.add_child(_label("PAUSE_EFFECTS_VOLUME", 13, INK))
	var sfx := HSlider.new()
	sfx.name = "SFXVolume"
	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.05
	sfx.value = _settings_value("sfx_volume", 1.0)
	sfx.value_changed.connect(_on_sfx_volume_changed)
	box.add_child(sfx)
	box.add_child(_language_selector())
	var garage := _command_button("PAUSE_ABORT", &"DangerButton")
	garage.pressed.connect(func() -> void: garage_requested.emit())
	box.add_child(garage)


func _build_result() -> void:
	_result_center = CenterContainer.new()
	_result_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_result_center)
	var panel := _modal_panel(Vector2(720.0, 510.0))
	_result_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	_result_kicker = _label("RESULT_KICKER", 14, AMBER)
	_result_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_kicker)
	_result_title = _label("RESULT_TITLE", 34, INK)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_title)
	var summary := _label("", 16, MUTED)
	summary.name = "RunSummary"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.custom_minimum_size.y = 190.0
	box.add_child(summary)
	box.set_meta("summary", summary)
	_result_continue_button = _command_button("RESULT_NEXT_STAGE", &"PrimaryButton")
	_result_continue_button.pressed.connect(func() -> void: advance_requested.emit())
	box.add_child(_result_continue_button)
	_result_garage_button = _command_button("RESULT_REVIEW_GARAGE", &"PrimaryButton")
	_result_garage_button.pressed.connect(func() -> void: garage_requested.emit())
	box.add_child(_result_garage_button)
	_result_first_button = _result_garage_button
	var replay := _command_button("RESULT_REPLAY", &"SecondaryButton")
	replay.pressed.connect(func() -> void: replay_requested.emit())
	box.add_child(replay)


func _build_garage() -> void:
	_garage_center = CenterContainer.new()
	_garage_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_garage_center)
	var panel := _modal_panel(Vector2(860.0, 510.0))
	_garage_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var kicker := _label("GARAGE_KICKER", 14, AMBER)
	box.add_child(kicker)
	var title := _label("GARAGE_TITLE", 30, INK)
	box.add_child(title)
	_garage_summary_label = _label("GARAGE_HULL_RESET", 15, MUTED)
	box.add_child(_garage_summary_label)
	var sections := HBoxContainer.new()
	sections.add_theme_constant_override("separation", 28)
	sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(sections)
	var loadout_box := VBoxContainer.new()
	loadout_box.custom_minimum_size.x = 420.0
	loadout_box.add_theme_constant_override("separation", 12)
	sections.add_child(loadout_box)
	loadout_box.add_child(_label("GARAGE_LOADOUT", 16, AMBER))
	_garage_primary_label = _label("", 19, INK)
	loadout_box.add_child(_garage_primary_label)
	_garage_passive_label = _label("", 16, RAISED)
	loadout_box.add_child(_garage_passive_label)
	_garage_active_label = _label("", 16, VIOLET)
	loadout_box.add_child(_garage_active_label)
	_garage_unlock_label = _label("", 15, MUTED)
	_garage_unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_box.add_child(_garage_unlock_label)

	var settings_box := VBoxContainer.new()
	settings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.add_theme_constant_override("separation", 8)
	sections.add_child(settings_box)
	settings_box.add_child(_label("GARAGE_SETTINGS", 16, AMBER))
	settings_box.add_child(_label("PAUSE_MASTER_VOLUME", 13, MUTED))
	var master := HSlider.new()
	master.min_value = 0.0
	master.max_value = 1.0
	master.step = 0.05
	master.value = _settings_value("master_volume", 1.0)
	master.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master.value_changed.connect(_on_master_volume_changed)
	settings_box.add_child(master)
	settings_box.add_child(_label("PAUSE_EFFECTS_VOLUME", 13, MUTED))
	var sfx := HSlider.new()
	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.05
	sfx.value = _settings_value("sfx_volume", 1.0)
	sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx.value_changed.connect(_on_sfx_volume_changed)
	settings_box.add_child(sfx)
	settings_box.add_child(_language_selector())

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var toggle := _command_button("GARAGE_SWAP_PRIMARY", &"SecondaryButton")
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle.pressed.connect(_on_toggle_primary)
	footer.add_child(toggle)
	var replay := _command_button("GARAGE_LAUNCH", &"PrimaryButton")
	replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay.pressed.connect(func() -> void: replay_requested.emit())
	footer.add_child(replay)
	_garage_first_button = replay


func update_hud(snapshot: Dictionary) -> void:
	if not is_instance_valid(_hud):
		return
	_health_bar.set_values(
		float(snapshot.get("health", 0.0)),
		maxf(1.0, float(snapshot.get("max_health", 1.0)))
	)
	_health_value.text = "%d / %d" % [
		roundi(float(snapshot.get("health", 0.0))),
		roundi(float(snapshot.get("max_health", 0.0))),
	]
	_objective_label.text = String(snapshot.get("objective", ""))
	_objective_detail.text = String(snapshot.get("objective_detail", ""))
	_minimap_title.text = String(snapshot.get("stage_title", tr("UI_FLOODED_WORKS")))

	_primary_slot.action_name = String(snapshot.get("primary_name", "ACTION_PRIMARY"))
	_primary_slot.set_state(
		String(snapshot.get("primary_state", "STATE_LIVE")),
		float(snapshot.get("primary_ratio", 0.0))
	)
	_dash_slot.set_state(String(snapshot.get("dash_state", "STATE_READY")), float(snapshot.get("dash_ratio", 0.0)))
	_passive_slot.set_state(String(snapshot.get("passive_state", "STATE_READY")), float(snapshot.get("passive_ratio", 0.0)))
	_skill_slot.set_state(String(snapshot.get("skill_state", "STATE_READY")), float(snapshot.get("skill_ratio", 0.0)))
	_buff_label.text = String(snapshot.get("buff_text", ""))

	var boss: Dictionary = snapshot.get("boss", {})
	_boss_cluster.visible = bool(boss.get("visible", false))
	_objective_panel.visible = not _boss_cluster.visible
	_minimap_panel.visible = not _boss_cluster.visible
	_notification.position.y = 94.0 if _boss_cluster.visible else 102.0
	if _boss_cluster.visible:
		_boss_name.text = String(boss.get("name", "BOSS"))
		_boss_bar.max_value = maxf(1.0, float(boss.get("max_health", 1.0)))
		_boss_bar.value = float(boss.get("health", 0.0))
		_boss_state.text = String(boss.get("state", ""))

	var target: Dictionary = snapshot.get("target", {})
	var target_panel: Control = _target_cluster.get_meta("panel")
	target_panel.visible = bool(target.get("visible", false))
	if target_panel.visible:
		_target_name.text = String(target.get("name", "TARGET"))
		_target_bar.max_value = maxf(1.0, float(target.get("max_health", 1.0)))
		_target_bar.value = float(target.get("health", 0.0))
		_target_state.text = String(target.get("state", ""))

	_minimap.set_snapshot(snapshot.get("minimap", {}))


func show_deployment(selected_primary: StringName = &"repeater") -> void:
	hide_all_modals()
	_selected_primary = selected_primary
	_dim.visible = true
	_deployment_center.visible = true
	_hud.visible = false
	for button in _deployment_buttons:
		button.disabled = false
	_refresh_deployment_selection()
	if not _deployment_buttons.is_empty():
		var index := 0 if selected_primary == &"repeater" else 1
		_deployment_buttons[index].grab_focus()


func show_upgrade(cards: Array[Dictionary]) -> void:
	hide_all_modals()
	_dim.visible = true
	_upgrade_center.visible = true
	_hud.visible = false
	_latest_upgrade_cards = cards.duplicate(true)
	_refresh_upgrade_cards()


func _refresh_upgrade_cards() -> void:
	for index in _upgrade_buttons.size():
		var button := _upgrade_buttons[index]
		if index >= _latest_upgrade_cards.size():
			button.visible = false
			continue
		var card: Dictionary = _latest_upgrade_cards[index]
		button.visible = true
		button.disabled = false
		button.set_meta("upgrade_id", StringName(card["id"]))
		button.text = "%s\n\n%s\n\n%s\n\n%s" % [
			tr(String(card["family_key"])),
			tr(String(card["title_key"])),
			tr(String(card["description_key"])),
			tr("UPGRADE_SHORTCUT") % (index + 1),
		]
	for button in _upgrade_buttons:
		if button.visible:
			button.grab_focus()
			break


func show_pause() -> void:
	hide_all_modals()
	_dim.visible = true
	_pause_center.visible = true
	_hud.visible = false
	_pause_first_button.grab_focus()


func show_result(summary: Dictionary) -> void:
	hide_all_modals()
	_dim.visible = true
	_result_center.visible = true
	_hud.visible = false
	_latest_result_summary = summary.duplicate(true)
	var has_next := bool(summary.get("has_next_stage", false))
	_result_continue_button.visible = has_next
	_result_continue_button.text = tr("RESULT_NEXT_STAGE").replace("%s", tr(String(summary.get("next_stage_key", "STAGE_TIDAL_ARCHIVE"))))
	_result_kicker.text = tr("RESULT_STAGE_COMPLETE").replace("%d", str(int(summary.get("stage_number", 1)))).replace("%s", tr(String(summary.get("stage_title_key", "STAGE_FLOODED_WORKS"))))
	_result_title.text = tr("RESULT_TITLE_CONTINUE") if has_next else tr("RESULT_TITLE_FINAL")
	_result_first_button = _result_continue_button if has_next else _result_garage_button
	_refresh_result_summary()
	_result_first_button.grab_focus()


func show_garage(data: Dictionary) -> void:
	hide_all_modals()
	_dim.visible = true
	_garage_center.visible = true
	_hud.visible = false
	_latest_garage_data = data.duplicate(true)
	_selected_primary = StringName(data.get("selected_primary", "repeater"))
	_refresh_garage_content()
	_garage_first_button.grab_focus()


func show_gameplay() -> void:
	hide_all_modals()
	_hud.visible = true


func hide_all_modals() -> void:
	if not is_instance_valid(_dim):
		return
	_dim.visible = false
	_deployment_center.visible = false
	_upgrade_center.visible = false
	_pause_center.visible = false
	_result_center.visible = false
	_garage_center.visible = false


func notify(message: String, duration: float = 2.4, color: Color = OFF_WHITE) -> void:
	_notification.text = message
	_notification.add_theme_color_override("font_color", color)
	_notification.modulate.a = 1.0
	_notification.visible = true
	_notification_timer = duration


func set_hud_visible(visible: bool) -> void:
	_hud.visible = visible


func is_modal_visible() -> bool:
	return _dim.visible


func debug_layout_minimums() -> Dictionary:
	return {
		"deployment": Vector2(840.0, 500.0),
		"upgrade": Vector2(900.0, 470.0),
		"pause": Vector2(560.0, 500.0),
		"result": Vector2(720.0, 510.0),
		"garage": Vector2(860.0, 510.0),
	}


func debug_ui_contract(viewport_width: float = 1280.0) -> Dictionary:
	var compact := viewport_width < 1100.0
	var objective_width := 360.0 if compact else 500.0
	var health_end := 18.0 + (232.0 if compact else 282.0)
	var objective_start := viewport_width * 0.5 - objective_width * 0.5
	var objective_end := objective_start + objective_width
	var minimap_start := viewport_width - (198.0 if compact else 236.0)
	var body_font_weight := 0.0
	if _root.theme.default_font is FontVariation:
		body_font_weight = float((_root.theme.default_font as FontVariation).variation_opentype.get("wght", 0.0))
	return {
		"theme_path": _root.theme.resource_path if _root.theme != null else "",
		"command_min_height": _pause_first_button.custom_minimum_size.y,
		"action_rail_size": Vector2(minf(724.0, viewport_width - 36.0), 82.0),
		"primary_slot_size": _primary_slot.custom_minimum_size,
		"secondary_slot_size": _dash_slot.custom_minimum_size,
		"body_font_weight": body_font_weight,
		"minimap_size": Vector2(150.0, 76.0) if compact else Vector2(190.0, 104.0),
		"top_clusters_do_not_overlap": health_end <= objective_start and objective_end <= minimap_start,
		"deployment_focusables": _deployment_center.find_children("*", "Button", true, false).size(),
		"upgrade_focusables": _upgrade_center.find_children("*", "Button", true, false).size(),
		"pause_focusables": _pause_center.find_children("*", "Control", true, false).filter(
			func(control: Control) -> bool: return control.focus_mode != Control.FOCUS_NONE
		).size(),
		"result_focusables": _result_center.find_children("*", "Button", true, false).size(),
		"garage_focusables": _garage_center.find_children("*", "Control", true, false).filter(
			func(control: Control) -> bool: return control.focus_mode != Control.FOCUS_NONE
		).size(),
		"locale": TranslationServer.get_locale().left(2),
		"locale_controls": _locale_buttons.size(),
	}


func debug_modal_contract(surface: String) -> Dictionary:
	match surface:
		"deployment":
			show_deployment(_selected_primary)
		"upgrade":
			show_upgrade([])
		"pause":
			show_pause()
		"result":
			show_result({"upgrade": "UPGRADE_NONE"})
		"garage":
			show_garage({})
	return {"surface": surface, "hud_hidden": not _hud.visible, "dim_visible": _dim.visible}


func _on_upgrade_button_pressed(button: Button) -> void:
	if button.disabled:
		return
	for other in _upgrade_buttons:
		other.disabled = true
	upgrade_selected.emit(StringName(button.get_meta("upgrade_id", "")))


func _on_toggle_primary() -> void:
	_selected_primary = &"scatter" if _selected_primary == &"repeater" else &"repeater"
	_refresh_garage_primary()
	primary_changed.emit(_selected_primary)


func _on_deployment_choice(primary_id: StringName) -> void:
	_selected_primary = primary_id
	_refresh_deployment_selection()


func _on_deployment_confirmed() -> void:
	deployment_selected.emit(_selected_primary)


func _refresh_deployment_selection() -> void:
	for button in _deployment_buttons:
		var primary_id := StringName(button.get_meta("primary_id", &"repeater"))
		var selected := primary_id == _selected_primary
		button.theme_type_variation = &"SelectedChoiceButton" if selected else &"ChoiceButton"
		button.text = _deployment_card_text(primary_id, selected)


func _deployment_card_text(primary_id: StringName, selected: bool) -> String:
	var prefix := "✓  " if selected else ""
	if primary_id == &"scatter":
		return "%sII  %s\n\n%s\n%s" % [
			prefix, tr("DEPLOY_SCATTER_TITLE"), tr("DEPLOY_SCATTER_META"), tr("DEPLOY_SCATTER_DESC"),
		]
	return "%sI  %s\n\n%s\n%s" % [
		prefix, tr("DEPLOY_REPEATER_TITLE"), tr("DEPLOY_REPEATER_META"), tr("DEPLOY_REPEATER_DESC"),
	]


func _refresh_result_summary() -> void:
	if _latest_result_summary.is_empty():
		return
	var summary_label: Label = _result_center.get_child(0).get_child(0).get_meta("summary")
	var result := _latest_result_summary
	var warden_state := tr("RESULT_DEFEATED") if bool(result.get("field_boss_defeated", false)) else tr("RESULT_BYPASSED")
	var reward_heading := tr("RESULT_ROUTE_CONTINUES") if bool(result.get("has_next_stage", false)) else tr("RESULT_REWARD")
	var reward_detail := tr(String(result.get("next_stage_key", ""))) if bool(result.get("has_next_stage", false)) else tr("RESULT_RELAY_MODULE")
	summary_label.text = "%s\n%s\n%s\n%s\n%s\n\n%s\n%s  ·  %s  ·  %s\n\n%s\n✦  %s" % [
		tr("RESULT_RUN"),
		tr("RESULT_CLEAR_TIME") % String(result.get("time", "0:00")),
		tr("RESULT_HULL") % roundi(float(result.get("health_ratio", 0.0)) * 100.0),
		tr("RESULT_UPGRADE") % tr(String(result.get("upgrade", "UPGRADE_NONE"))),
		tr("RESULT_WARDEN") % warden_state,
		tr("RESULT_PERFORMANCE"),
		tr("RESULT_PRIMARY_HITS") % int(result.get("primary_hits", 0)),
		tr("RESULT_DASH_USES") % int(result.get("dash_uses", 0)),
		tr("RESULT_INSTALLATIONS") % int(result.get("installations", 0)),
		reward_heading,
		reward_detail,
	]


func _refresh_garage_content() -> void:
	_refresh_garage_primary()
	_garage_passive_label.text = "%s  ·  %s" % [tr("GARAGE_PASSIVE"), tr("GARAGE_PASSIVE_SEEKER")]
	_garage_active_label.text = "%s  ·  %s" % [tr("GARAGE_ACTIVE"), tr("GARAGE_ACTIVE_EMP")]
	if _latest_garage_data.is_empty():
		_garage_summary_label.text = tr("GARAGE_HULL_RESET")
		_garage_unlock_label.text = "%s  ·  %s" % [tr("GARAGE_MODULE"), tr("GARAGE_NO_MODULE")]
		return
	var clear_count := int(_latest_garage_data.get("clear_count", 0))
	_garage_summary_label.text = "%s  ·  %s" % [tr("GARAGE_STAGE_CLEARS") % clear_count, tr("GARAGE_HULL_RESET")]
	var unlocks: Array[String] = []
	if bool(_latest_garage_data.get("relay_module_unlocked", false)):
		unlocks.append(tr("GARAGE_RELAY_MODULE"))
	if bool(_latest_garage_data.get("field_module_unlocked", false)):
		unlocks.append(tr("GARAGE_DREDGE_MODULE"))
	if unlocks.is_empty():
		_garage_unlock_label.text = "%s  ·  %s" % [tr("GARAGE_MODULE"), tr("GARAGE_NO_MODULE")]
		_garage_unlock_label.add_theme_color_override("font_color", MUTED)
	else:
		_garage_unlock_label.text = "%s  ·  %s" % [tr("GARAGE_MODULE"), "  •  ".join(unlocks)]
		_garage_unlock_label.add_theme_color_override("font_color", AMBER)


func _refresh_garage_primary() -> void:
	if _selected_primary == &"scatter":
		_garage_primary_label.text = "%s  ·  %s" % [tr("GARAGE_PRIMARY"), tr("PRIMARY_SCATTER")]
	else:
		_garage_primary_label.text = "%s  ·  %s" % [tr("GARAGE_PRIMARY"), tr("PRIMARY_REPEATER")]


func _language_selector() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_label("LANGUAGE_LABEL", 13, MUTED))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	for locale in ["ko", "en"]:
		var button := _command_button("LANGUAGE_KO" if locale == "ko" else "LANGUAGE_EN", &"SecondaryButton")
		button.custom_minimum_size = Vector2(76.0, 34.0)
		button.set_meta("locale", locale)
		button.pressed.connect(_on_locale_button_pressed.bind(locale))
		row.add_child(button)
		_locale_buttons.append(button)
	return row


func _on_locale_button_pressed(locale: String) -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_method("set_ui_locale"):
		settings.call("set_ui_locale", locale)
	else:
		TranslationServer.set_locale(locale)
		_refresh_localized_content()


func _on_locale_changed(_locale: String) -> void:
	_refresh_localized_content()


func _refresh_localized_content() -> void:
	_refresh_deployment_selection()
	_refresh_garage_content()
	_refresh_result_summary()
	_refresh_locale_buttons()
	_primary_slot.queue_redraw()
	_passive_slot.queue_redraw()
	_dash_slot.queue_redraw()
	_skill_slot.queue_redraw()
	if not _latest_upgrade_cards.is_empty() and _upgrade_center.visible:
		_refresh_upgrade_cards()


func _refresh_locale_buttons() -> void:
	var current := TranslationServer.get_locale().left(2)
	for button in _locale_buttons:
		button.theme_type_variation = &"SelectedChoiceButton" if String(button.get_meta("locale", "")) == current else &"SecondaryButton"


func _on_master_volume_changed(value: float) -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_method("set_master_volume"):
		settings.call("set_master_volume", value)


func _on_sfx_volume_changed(value: float) -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_method("set_sfx_volume"):
		settings.call("set_sfx_volume", value)


func _settings_value(property_name: StringName, fallback: float) -> float:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings == null:
		return fallback
	var value: Variant = settings.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback


func _flat_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"FlatPanel"
	panel.add_theme_constant_override("margin_left", 14)
	panel.add_theme_constant_override("margin_top", 10)
	panel.add_theme_constant_override("margin_right", 14)
	panel.add_theme_constant_override("margin_bottom", 10)
	return panel


func _modal_panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ModalSurface"
	panel.custom_minimum_size = minimum_size
	panel.add_theme_constant_override("margin_left", 24)
	panel.add_theme_constant_override("margin_top", 22)
	panel.add_theme_constant_override("margin_right", 24)
	panel.add_theme_constant_override("margin_bottom", 22)
	return panel


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _action_slot(parent: HBoxContainer, binding: String, title: String, color: Color, primary: bool = false) -> ActionRailSlot:
	var slot := ActionRailSlot.new()
	slot.configure(binding, title, color, primary)
	parent.add_child(slot)
	return slot


func _choice_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ChoiceButton"
	button.text = text
	button.custom_minimum_size = minimum_size
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	return button


func _command_button(text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.theme_type_variation = variation
	button.text = text
	button.custom_minimum_size.y = 44.0
	button.focus_mode = Control.FOCUS_ALL
	return button
