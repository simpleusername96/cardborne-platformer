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
		custom_minimum_size = Vector2(244.0, 46.0)

	func set_values(value: float, max_value: float) -> void:
		health = value
		maximum = maxf(1.0, max_value)
		queue_redraw()

	func _draw() -> void:
		var ratio := clampf(health / maximum, 0.0, 1.0)
		for index in 5:
			var center := Vector2(24.0 + float(index) * 45.0, 23.0)
			draw_circle(center + Vector2(4.0, 5.0), 18.0, Art.COBALT_DEEP)
			draw_circle(center, 18.0, Art.MINT_SOFT)
			var pip_fill := clampf(ratio * 5.0 - float(index), 0.0, 1.0)
			if pip_fill > 0.0:
				draw_circle(center, 14.0 * pip_fill, Art.CORAL)
				draw_circle(center, 5.0, Art.IVORY_BRIGHT)


class ActionMedallion:
	extends Control

	var binding := ""
	var action_name := ""
	var state_text := "READY"
	var accent := Art.MUSTARD
	var cooldown_ratio := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(112.0, 92.0)

	func configure(key_text: String, title: String, color: Color) -> void:
		binding = key_text
		action_name = title
		accent = color
		queue_redraw()

	func set_state(value: String, ratio: float = 0.0) -> void:
		state_text = value
		cooldown_ratio = clampf(ratio, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, 44.0)
		var radius := 38.0
		var points := PackedVector2Array()
		for index in 8:
			points.append(center + Vector2.RIGHT.rotated(PI / 8.0 + TAU * float(index) / 8.0) * radius)
		draw_colored_polygon(points, Art.COBALT_DEEP)
		var inner := PackedVector2Array()
		for index in 8:
			inner.append(center + Vector2.RIGHT.rotated(PI / 8.0 + TAU * float(index) / 8.0) * (radius - 5.0))
		draw_colored_polygon(inner, Art.IVORY_BRIGHT)
		draw_circle(center, 25.0, Art.CERAMIC_GREEN)
		if cooldown_ratio > 0.0:
			draw_circle(center, 25.0 * cooldown_ratio, Art.INK_MUTED)
		var font := get_theme_default_font()
		draw_string(font, Vector2(0.0, 24.0), binding, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, accent)
		draw_string(font, Vector2(0.0, 50.0), action_name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Art.IVORY_BRIGHT)
		draw_string(font, Vector2(0.0, 86.0), state_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Art.INK)

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
var _primary_slot: ActionMedallion
var _dash_slot: ActionMedallion
var _passive_slot: ActionMedallion
var _skill_slot: ActionMedallion
var _buff_label: Label
var _minimap: StageMinimap
var _notification: Label
var _notification_timer := 0.0

var _dim: ColorRect
var _deployment_center: CenterContainer
var _upgrade_center: CenterContainer
var _pause_center: CenterContainer
var _result_center: CenterContainer
var _garage_center: CenterContainer
var _deployment_buttons: Array[Button] = []
var _upgrade_buttons: Array[Button] = []
var _pause_first_button: Button
var _result_first_button: Button
var _garage_first_button: Button
var _garage_primary_label: Label
var _garage_unlock_label: Label
var _garage_summary_label: Label
var _selected_primary := &"repeater"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_build_hud()
	_build_deployment()
	_build_upgrade()
	_build_pause()
	_build_result()
	_build_garage()
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
	var hull_label := _label("HULL INTEGRITY", 13, INK)
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
	_objective_label = _label("DEPLOYMENT", 19, INK)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_box.add_child(_objective_label)
	_objective_detail = _label("Select a primary weapon", 13, MUTED)
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
	var map_title := _label("FLOODED WORKS", 12, INK)
	minimap_box.add_child(map_title)
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
	_boss_name = _label("FOUNDRY COLOSSUS", 16, OFF_WHITE)
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
	_boss_state = _label("READING THE ARENA", 12, OFF_WHITE)
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
	var target_header := _label("LOCKED TARGET", 12, CORAL)
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

	_dock_panel = _transparent_panel()
	_dock_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_dock_panel.position = Vector2(398.0, 608.0)
	_dock_panel.size = Vector2(484.0, 100.0)
	_hud.add_child(_dock_panel)
	var dock := HBoxContainer.new()
	dock.add_theme_constant_override("separation", 12)
	_dock_panel.add_child(dock)
	_primary_slot = _action_slot(dock, "SHIFT", "PRIMARY", AMBER)
	_passive_slot = _action_slot(dock, "AUTO", "SEEKER", MOSS)
	_dash_slot = _action_slot(dock, "SPACE", "DASH", CYAN)
	_skill_slot = _action_slot(dock, "Z", "EMP", VIOLET)

	_buff_label = _label("", 13, OFF_WHITE)
	_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buff_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_buff_label.position = Vector2(340.0, 582.0)
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
	var objective_width := 350.0 if compact else 500.0
	_objective_panel.position = Vector2((_root.size.x - objective_width) * 0.5, 16.0)
	_objective_panel.custom_minimum_size = Vector2(objective_width, 72.0)
	_objective_panel.size = Vector2(objective_width, 72.0)
	_minimap_panel.position = Vector2(_root.size.x - 236.0, 16.0)
	_boss_cluster.position = Vector2((_root.size.x - 640.0) * 0.5, 100.0)
	_target_panel.position = Vector2(_root.size.x - 258.0, (_root.size.y - 124.0) * 0.5)
	_dock_panel.position = Vector2((_root.size.x - 484.0) * 0.5, _root.size.y - 112.0)
	_buff_label.position = Vector2((_root.size.x - 600.0) * 0.5, _root.size.y - 138.0)
	_objective_detail.add_theme_font_size_override("font_size", 12 if compact else 13)
	_notification.size.x = 420.0 if compact else 520.0
	_notification.position.x = (_root.size.x - _notification.size.x) * 0.5


func _build_deployment() -> void:
	_deployment_center = CenterContainer.new()
	_deployment_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_deployment_center)
	var panel := _modal_panel(Vector2(820.0, 500.0))
	_deployment_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var kicker := _label("FLOODED WORKS  ·  STAGE 1", 14, AMBER)
	box.add_child(kicker)
	var title := _label("DEPLOY THE SALVAGE SKIFF", 30, INK)
	box.add_child(title)
	var body := _label(
		"ARROWS / WASD move  ·  Mouse aims  ·  SHIFT fires  ·  SPACE dashes  ·  Z releases EMP  ·  Seeker fires automatically",
		16,
		MUTED
	)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 48.0
	box.add_child(body)
	var choice_row := HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 12)
	choice_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(choice_row)
	var repeater := _choice_button(
		"I  RAPID REPEATER\n\nLONG RANGE  ·  9 ROUNDS / SEC\nSustained pressure against installations\n\nDEPLOY WITH REPEATER",
		Vector2(365.0, 230.0)
	)
	repeater.pressed.connect(func() -> void: deployment_selected.emit(&"repeater"))
	choice_row.add_child(repeater)
	_deployment_buttons.append(repeater)
	var scatter := _choice_button(
		"II  SCATTER ARRAY\n\nSHORT RANGE  ·  3 PROJECTILES\nHeavy pressure while circling close\n\nDEPLOY WITH SCATTER",
		Vector2(365.0, 230.0)
	)
	scatter.pressed.connect(func() -> void: deployment_selected.emit(&"scatter"))
	choice_row.add_child(scatter)
	_deployment_buttons.append(scatter)
	var footer := _label("Ordinary threats may be bypassed. Only the Colossus basin seals.", 13, MUTED)
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
	var kicker := _label("SALVAGE CACHE", 14, AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var title := _label("CHOOSE ONE LIVE CIRCUIT", 27, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var detail := _label("Combat is suspended. The selected circuit applies immediately.", 14, MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(detail)
	var row := HBoxContainer.new()
	row.name = "UpgradeButtons"
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	for index in 3:
		var button := _choice_button("CIRCUIT %d" % (index + 1), Vector2(272.0, 278.0))
		button.name = "UpgradeCard%d" % (index + 1)
		button.pressed.connect(_on_upgrade_button_pressed.bind(button))
		row.add_child(button)
		_upgrade_buttons.append(button)


func _build_pause() -> void:
	_pause_center = CenterContainer.new()
	_pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_pause_center)
	var panel := _modal_panel(Vector2(480.0, 430.0))
	_pause_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := _label("PAUSED", 30, INK)
	box.add_child(title)
	var resume := _command_button("RESUME", &"PrimaryButton")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	box.add_child(resume)
	_pause_first_button = resume
	var restart := _command_button("RESTART STAGE 1", &"SecondaryButton")
	restart.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart)
	box.add_child(_label("MASTER VOLUME", 13, INK))
	var master := HSlider.new()
	master.name = "MasterVolume"
	master.min_value = 0.0
	master.max_value = 1.0
	master.step = 0.05
	master.value = _settings_value("master_volume", 1.0)
	master.value_changed.connect(_on_master_volume_changed)
	box.add_child(master)
	box.add_child(_label("EFFECTS VOLUME", 13, INK))
	var sfx := HSlider.new()
	sfx.name = "SFXVolume"
	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.05
	sfx.value = _settings_value("sfx_volume", 1.0)
	sfx.value_changed.connect(_on_sfx_volume_changed)
	box.add_child(sfx)
	var garage := _command_button("ABORT TO GARAGE", &"SecondaryButton")
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
	var kicker := _label("STAGE 1 COMPLETE", 14, AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var title := _label("THE RELAY IS QUIET", 34, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var summary := _label("", 16, MUTED)
	summary.name = "RunSummary"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.custom_minimum_size.y = 190.0
	box.add_child(summary)
	box.set_meta("summary", summary)
	var garage := _command_button("REVIEW GARAGE & MODULE", &"PrimaryButton")
	garage.pressed.connect(func() -> void: garage_requested.emit())
	box.add_child(garage)
	_result_first_button = garage
	var replay := _command_button("REPLAY STAGE 1", &"SecondaryButton")
	replay.pressed.connect(func() -> void: replay_requested.emit())
	box.add_child(replay)


func _build_garage() -> void:
	_garage_center = CenterContainer.new()
	_garage_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_garage_center)
	var panel := _modal_panel(Vector2(820.0, 500.0))
	_garage_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var kicker := _label("COMPACT GARAGE", 14, AMBER)
	box.add_child(kicker)
	var title := _label("SALVAGE SKIFF LOADOUT", 30, INK)
	box.add_child(title)
	_garage_summary_label = _label("Hull reset to full. Repairs never block another deployment.", 15, MUTED)
	box.add_child(_garage_summary_label)
	var loadout_box := VBoxContainer.new()
	loadout_box.custom_minimum_size = Vector2(760.0, 132.0)
	box.add_child(loadout_box)
	_garage_primary_label = _label("PRIMARY  ·  RAPID REPEATER", 19, INK)
	loadout_box.add_child(_garage_primary_label)
	loadout_box.add_child(_label("PASSIVE  ·  AUTO SEEKER LAUNCHER", 16, RAISED))
	loadout_box.add_child(_label("ACTIVE  ·  EMP NOVA", 16, VIOLET))
	_garage_unlock_label = _label("MODULE  ·  Colossus Relay locked", 15, MUTED)
	loadout_box.add_child(_garage_unlock_label)
	var toggle := _command_button("SWAP PRIMARY WEAPON", &"SecondaryButton")
	toggle.pressed.connect(_on_toggle_primary)
	box.add_child(toggle)
	var replay := _command_button("LAUNCH STAGE 1", &"PrimaryButton")
	replay.pressed.connect(func() -> void: replay_requested.emit())
	box.add_child(replay)
	_garage_first_button = replay
	var settings_row := HBoxContainer.new()
	settings_row.add_theme_constant_override("separation", 12)
	box.add_child(settings_row)
	var master_label := _label("MASTER", 13, MUTED)
	master_label.custom_minimum_size.x = 92.0
	settings_row.add_child(master_label)
	var master := HSlider.new()
	master.min_value = 0.0
	master.max_value = 1.0
	master.step = 0.05
	master.value = _settings_value("master_volume", 1.0)
	master.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master.value_changed.connect(_on_master_volume_changed)
	settings_row.add_child(master)
	var sfx_label := _label("SFX", 13, MUTED)
	sfx_label.custom_minimum_size.x = 50.0
	settings_row.add_child(sfx_label)
	var sfx := HSlider.new()
	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.05
	sfx.value = _settings_value("sfx_volume", 1.0)
	sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx.value_changed.connect(_on_sfx_volume_changed)
	settings_row.add_child(sfx)


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

	_primary_slot.action_name = String(snapshot.get("primary_name", "PRIMARY"))
	_primary_slot.set_state(String(snapshot.get("primary_state", "LIVE")), float(snapshot.get("primary_ratio", 0.0)))
	_dash_slot.set_state(String(snapshot.get("dash_state", "READY")), float(snapshot.get("dash_ratio", 0.0)))
	_passive_slot.set_state(String(snapshot.get("passive_state", "READY")), float(snapshot.get("passive_ratio", 0.0)))
	_skill_slot.set_state(String(snapshot.get("skill_state", "READY")), float(snapshot.get("skill_ratio", 0.0)))
	_buff_label.text = String(snapshot.get("buff_text", ""))

	var boss: Dictionary = snapshot.get("boss", {})
	_boss_cluster.visible = bool(boss.get("visible", false))
	_notification.position.y = 188.0 if _boss_cluster.visible else 110.0
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
	if not _deployment_buttons.is_empty():
		var index := 0 if selected_primary == &"repeater" else 1
		_deployment_buttons[index].grab_focus()


func show_upgrade(cards: Array[Dictionary]) -> void:
	hide_all_modals()
	_dim.visible = true
	_upgrade_center.visible = true
	_hud.visible = true
	for index in _upgrade_buttons.size():
		var button := _upgrade_buttons[index]
		if index >= cards.size():
			button.visible = false
			continue
		var card: Dictionary = cards[index]
		button.visible = true
		button.disabled = false
		button.set_meta("upgrade_id", StringName(card["id"]))
		button.text = "%s\n\n%s\n\n%s\n\n[%d]" % [
			String(card["family"]),
			String(card["title"]),
			String(card["description"]),
			index + 1,
		]
	if not _upgrade_buttons.is_empty():
		_upgrade_buttons[0].grab_focus()


func show_pause() -> void:
	hide_all_modals()
	_dim.visible = true
	_pause_center.visible = true
	_hud.visible = true
	_pause_first_button.grab_focus()


func show_result(summary: Dictionary) -> void:
	hide_all_modals()
	_dim.visible = true
	_result_center.visible = true
	_hud.visible = false
	var summary_label: Label = _result_center.get_child(0).get_child(0).get_meta("summary")
	summary_label.text = (
		"Clear time: %s\nHull integrity: %d%%\nUpgrade: %s\nOptional Warden: %s\n"
		+ "Primary hits: %d  •  Dash uses: %d  •  Priority installations destroyed: %d\n\n"
		+ "Persistent reward acquired: COLOSSUS RELAY MODULE"
	) % [
		String(summary.get("time", "0:00")),
		roundi(float(summary.get("health_ratio", 0.0)) * 100.0),
		String(summary.get("upgrade", "None")),
		"DEFEATED" if bool(summary.get("field_boss_defeated", false)) else "BYPASSED",
		int(summary.get("primary_hits", 0)),
		int(summary.get("dash_uses", 0)),
		int(summary.get("installations", 0)),
	]
	_result_first_button.grab_focus()


func show_garage(data: Dictionary) -> void:
	hide_all_modals()
	_dim.visible = true
	_garage_center.visible = true
	_hud.visible = false
	_selected_primary = StringName(data.get("selected_primary", "repeater"))
	_refresh_garage_primary()
	var clear_count := int(data.get("clear_count", 0))
	var field_module := bool(data.get("field_module_unlocked", false))
	var relay_module := bool(data.get("relay_module_unlocked", false))
	_garage_summary_label.text = "Stage clears: %d. Hull reset to full; repairs never block another deployment." % clear_count
	var unlocks: Array[String] = []
	if relay_module:
		unlocks.append("Colossus Relay: EMP starts each run 20% charged")
	if field_module:
		unlocks.append("Dredge Capacitor: seeker cadence improved")
	if unlocks.is_empty():
		_garage_unlock_label.text = "MODULE  ·  No persistent module unlocked yet"
		_garage_unlock_label.add_theme_color_override("font_color", MUTED)
	else:
		_garage_unlock_label.text = "MODULE  ·  " + "  •  ".join(unlocks)
		_garage_unlock_label.add_theme_color_override("font_color", AMBER)
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
		"deployment": Vector2(820.0, 500.0),
		"upgrade": Vector2(900.0, 470.0),
		"pause": Vector2(480.0, 430.0),
		"result": Vector2(720.0, 510.0),
		"garage": Vector2(820.0, 500.0),
	}


func debug_ui_contract(viewport_width: float = 1280.0) -> Dictionary:
	var compact := viewport_width < 1100.0
	var objective_width := 350.0 if compact else 500.0
	var health_end := 18.0 + 282.0
	var objective_start := viewport_width * 0.5 - objective_width * 0.5
	var objective_end := objective_start + objective_width
	var minimap_start := viewport_width - 236.0
	return {
		"theme_path": _root.theme.resource_path if _root.theme != null else "",
		"command_min_height": _pause_first_button.custom_minimum_size.y,
		"action_medallion_size": _primary_slot.custom_minimum_size,
		"minimap_size": _minimap.custom_minimum_size,
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
	}


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


func _refresh_garage_primary() -> void:
	if _selected_primary == &"scatter":
		_garage_primary_label.text = "PRIMARY  ·  SCATTER ARRAY"
	else:
		_garage_primary_label.text = "PRIMARY  ·  RAPID REPEATER"


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


func _transparent_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HUDTransparent"
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


func _action_slot(parent: HBoxContainer, binding: String, title: String, color: Color) -> ActionMedallion:
	var medallion := ActionMedallion.new()
	medallion.configure(binding, title, color)
	parent.add_child(medallion)
	return medallion


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
