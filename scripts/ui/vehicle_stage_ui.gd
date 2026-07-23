class_name VehicleStageUI
extends CanvasLayer

## Runtime-built HUD and modal surfaces for the vehicle run.
## The UI presents snapshots and emits intents; the stage remains the gameplay owner.

signal deployment_selected(primary_id: StringName, difficulty_id: StringName)
signal upgrade_selected(upgrade_id: StringName)
signal upgrade_declined
signal upgrade_previewed(upgrade_id: StringName)
signal pause_requested
signal resume_requested
signal restart_requested
signal garage_requested
signal replay_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const VEHICLE_THEME = preload("res://art/ui/production/vehicle_stage_theme.tres")
const UpgradeChoicePanel = preload("res://scripts/ui/vehicle_upgrade_choice_panel.gd")
const ThreatRadar = preload("res://scripts/ui/vehicle_threat_radar.gd")
const StatusOrbit = preload("res://scripts/ui/vehicle_status_orbit.gd")
const SettingsPanel = preload("res://scripts/ui/vehicle_settings_panel.gd")
const GuidebookPanel = preload("res://scripts/ui/vehicle_guidebook_panel.gd")
const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")

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
	var trailing_health := 120.0
	var run_level := 1
	var experience := 0.0
	var experience_required := 12.0
	var reduced_motion := false
	var _trail_from := 120.0
	var _trail_hold := 0.0
	var _trail_elapsed := 0.0
	var _trail_duration := 0.45
	var _pulse_time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(160.0, 42.0)
		set_process(false)

	func set_values(
		value: float,
		max_value: float,
		level_value: int = 1,
		experience_value: float = 0.0,
		required_value: float = 12.0,
		reduced_motion_value: bool = false
	) -> void:
		var next_health := clampf(value, 0.0, maxf(1.0, max_value))
		reduced_motion = reduced_motion_value
		if next_health < health:
			if reduced_motion:
				trailing_health = next_health
				_pulse_time = 0.20
			else:
				_trail_from = maxf(health, trailing_health)
				trailing_health = _trail_from
				_trail_hold = 0.18
				_trail_elapsed = 0.0
			set_process(true)
		elif next_health > health:
			trailing_health = next_health
		health = next_health
		maximum = maxf(1.0, max_value)
		run_level = level_value
		experience = experience_value
		experience_required = maxf(1.0, required_value)
		queue_redraw()

	func _process(delta: float) -> void:
		if _pulse_time > 0.0:
			_pulse_time = maxf(0.0, _pulse_time - delta)
		if _trail_hold > 0.0:
			_trail_hold = maxf(0.0, _trail_hold - delta)
		elif trailing_health > health:
			_trail_elapsed = minf(_trail_duration, _trail_elapsed + delta)
			trailing_health = lerpf(_trail_from, health, _trail_elapsed / _trail_duration)
		if _pulse_time <= 0.0 and _trail_hold <= 0.0 and trailing_health <= health + 0.001:
			trailing_health = health
			set_process(false)
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		draw_string(font, Vector2(0.0, 14.0), "LV.%d" % run_level, HORIZONTAL_ALIGNMENT_LEFT, 52.0, 14, Art.CERAMIC_GREEN)
		draw_string(font, Vector2(54.0, 14.0), "%d / %d" % [roundi(health), roundi(maximum)], HORIZONTAL_ALIGNMENT_RIGHT, size.x - 54.0, 14, Art.INK)
		var hull_rect := Rect2(0.0, 18.0, size.x, 12.0)
		draw_rect(hull_rect, Art.IVORY_SHADE)
		draw_rect(
			Rect2(
				hull_rect.position,
				Vector2(hull_rect.size.x * clampf(trailing_health / maximum, 0.0, 1.0), hull_rect.size.y)
			),
			Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.55)
		)
		draw_rect(Rect2(hull_rect.position, Vector2(hull_rect.size.x * clampf(health / maximum, 0.0, 1.0), hull_rect.size.y)), Art.CORAL)
		if _pulse_time > 0.0:
			draw_rect(hull_rect.grow(2.0), Art.CORAL, false, 2.0)
		var xp_rect := Rect2(0.0, 35.0, size.x, 6.0)
		draw_rect(xp_rect, Art.CERAMIC_GREEN_MID)
		draw_rect(Rect2(xp_rect.position, Vector2(xp_rect.size.x * clampf(experience / experience_required, 0.0, 1.0), xp_rect.size.y)), Art.MUSTARD)


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
		custom_minimum_size = Vector2(64.0, 56.0) if is_primary else Vector2(52.0, 56.0)

	func configure(key_text: String, title: String, color: Color, primary: bool = false) -> void:
		binding = key_text
		action_name = title
		accent = color
		is_primary = primary
		custom_minimum_size = Vector2(64.0, 56.0) if is_primary else Vector2(52.0, 56.0)
		queue_redraw()

	func set_state(value: String, ratio: float = 0.0, current_segments: int = 0, maximum_segments: int = 0) -> void:
		state_text = value
		cooldown_ratio = clampf(ratio, 0.0, 1.0)
		filled_segments = maxi(0, current_segments)
		segment_count = maxi(0, maximum_segments)
		queue_redraw()

	func set_binding(value: String) -> void:
		binding = value
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		var center := Vector2(size.x * 0.5, 23.0)
		var radius := 21.0 if is_primary else 19.0
		draw_circle(center + Vector2(2.0, 3.0), radius + 2.0, Color(Art.COBALT_DEEP, 0.90))
		draw_circle(center, radius, Art.IVORY_BRIGHT)
		var progress := cooldown_ratio if is_primary else 1.0 - cooldown_ratio
		draw_arc(center, radius - 1.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(progress, 0.0, 1.0), 24, accent, 4.0, true)
		match action_name:
			"ACTION_PRIMARY":
				draw_colored_polygon(PackedVector2Array([center + Vector2(9.0, 0.0), center + Vector2(-7.0, -6.0), center + Vector2(-7.0, 6.0)]), accent)
			"ACTION_SEEKER":
				for offset in [-7.0, 0.0, 7.0]: draw_circle(center + Vector2(offset, 0.0), 3.0, accent)
			"ACTION_DASH":
				draw_colored_polygon(PackedVector2Array([center + Vector2(-8.0, -7.0), center + Vector2(2.0, 0.0), center + Vector2(-8.0, 7.0), center + Vector2(9.0, 0.0)]), accent)
			_:
				draw_colored_polygon(PackedVector2Array([center + Vector2(0.0, -9.0), center + Vector2(8.0, 7.0), center, center + Vector2(-8.0, 7.0)]), accent)
		draw_string(font, Vector2(0.0, size.y - 6.0), binding, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Art.INK)

class StageMinimap:
	extends Control

	var snapshot: Dictionary = {}
	var _static_map_mesh: ArrayMesh
	var _static_mesh_size := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(144.0, 80.0)

	func set_snapshot(value: Dictionary) -> void:
		# Static geometry arrives once; position/discovery channels merge at 10 Hz.
		for key in value:
			snapshot[key] = value[key]
		if (
			value.has("floor_polygons")
			or value.has("water_polygons")
			or value.has("blocker_polygons")
			or value.has("world_size")
		):
			_static_map_mesh = null
		queue_redraw()

	func _draw() -> void:
		var panel_rect := Rect2(Vector2.ZERO, size)
		draw_rect(panel_rect, Art.COBALT_DEEP)
		var cols: int = int(snapshot.get("cols", 13))
		var rows: int = int(snapshot.get("rows", 6))
		var cell_size := Vector2(size.x / float(cols), size.y / float(rows))
		var world_size: Vector2 = snapshot.get("world_size", Vector2(5200.0, 2200.0))
		if _static_map_mesh == null or not _static_mesh_size.is_equal_approx(size):
			_static_map_mesh = _build_static_map_mesh(world_size)
			_static_mesh_size = size
		if _static_map_mesh != null:
			draw_mesh(_static_map_mesh, null)
		var visited: Array = snapshot.get("visited", [])
		var visited_lookup: Dictionary = {}
		for cell_variant in visited:
			visited_lookup[Vector2i(cell_variant)] = true
		var concealment_color := Color(Art.COBALT_VOID, 0.82)
		for row in rows:
			# Merge adjacent concealed cells so the 16x10 exploration mask costs
			# one draw per row run instead of one draw per undiscovered cell.
			var concealed_run_start := -1
			for column in range(cols + 1):
				var concealed := (
					column < cols
					and not visited_lookup.has(Vector2i(column, row))
				)
				if concealed and concealed_run_start < 0:
					concealed_run_start = column
				elif not concealed and concealed_run_start >= 0:
					draw_rect(
						Rect2(
							Vector2(concealed_run_start, row) * cell_size,
							Vector2(
								float(column - concealed_run_start) * cell_size.x,
								cell_size.y
							) + Vector2.ONE
						),
						concealment_color
					)
					concealed_run_start = -1
		for marker_variant in snapshot.get("markers", []):
			var marker: Dictionary = marker_variant
			if not bool(marker.get("discovered", false)):
				continue
			var world: Vector2 = marker.get("position", Vector2.ZERO)
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
			elif kind == "mechanic":
				var direction := Vector2.RIGHT.rotated(float(int(marker.get("orientation", 0))) * PI * 0.5)
				draw_circle(point, 5.0, marker_color)
				draw_line(point - direction * 6.0, point + direction * 6.0, Art.IVORY_BRIGHT, 2.5)
			elif kind == "blocker":
				draw_rect(Rect2(point - Vector2(5.0, 2.5), Vector2(10.0, 5.0)), marker_color)
			else:
				draw_circle(point, 4.0, marker_color)
		var player: Vector2 = snapshot.get("player", Vector2.ZERO)
		var player_point := Vector2(player.x / world_size.x * size.x, player.y / world_size.y * size.y)
		draw_colored_polygon(PackedVector2Array([
			player_point + Vector2(0.0, -6.0),
			player_point + Vector2(5.0, 5.0),
			player_point + Vector2(-5.0, 5.0),
		]), Art.MUSTARD)

	func _build_static_map_mesh(world_size: Vector2) -> ArrayMesh:
		var vertices := PackedVector3Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		for layer in [
			{"key": "floor_polygons", "color": Art.IVORY_SHADE},
			{"key": "water_polygons", "color": Art.COBALT_WATER},
			{"key": "blocker_polygons", "color": Art.BLOCKER_FILL},
		]:
			for polygon_variant in snapshot.get(layer["key"], []):
				var points := _scaled_polygon(PackedVector2Array(polygon_variant), world_size)
				var triangles := Geometry2D.triangulate_polygon(points)
				var vertex_offset := vertices.size()
				for point in points:
					vertices.append(Vector3(point.x, point.y, 0.0))
					colors.append(Color(layer["color"]))
				for index in triangles:
					indices.append(vertex_offset + index)
		if vertices.is_empty():
			return null
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh

	func _scaled_polygon(polygon: PackedVector2Array, world_size: Vector2) -> PackedVector2Array:
		var result := PackedVector2Array()
		for point in polygon:
			result.append(Vector2(point.x / world_size.x * size.x, point.y / world_size.y * size.y))
		return result

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
var _objective_label: Label
var _objective_detail: Label
var _objective_detail_timer := 0.0
var _last_objective_text := ""
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
var _notification_queue: Array[Dictionary] = []
var _threat_radar
var _status_orbit

var _dim: ColorRect
var _deployment_center: CenterContainer
var _upgrade_center: CenterContainer
var _upgrade_panel: VehicleUpgradeChoicePanel
var _pause_center: CenterContainer
var _result_center: CenterContainer
var _garage_center: CenterContainer
var _settings_center: CenterContainer
var _settings_panel: VehicleSettingsPanel
var _guide_center: CenterContainer
var _guide_panel: VehicleGuidebookPanel
var _deployment_command: Button
var _deployment_controls_label: Label
var _deployment_difficulty_detail: Label
var _deployment_difficulty_buttons: Dictionary = {}
var _upgrade_buttons: Array[Button] = []
var _pause_first_button: Button
var _result_first_button: Button
var _result_kicker: Label
var _result_title: Label
var _result_garage_button: Button
var _garage_first_button: Button
var _garage_primary_label: Label
var _garage_passive_label: Label
var _garage_active_label: Label
var _garage_unlock_label: Label
var _garage_summary_label: Label
var _selected_primary := &"pulse_cannon"
var _selected_run_difficulty: StringName = RunDifficulty.DEFAULT
var _settings_return_surface := "deployment"
var _guide_return_surface := "pause"
var _latest_guidebook_snapshot: Dictionary = {}
var _latest_upgrade_cards: Array[Dictionary] = []
var _latest_upgrade_optional := false
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
	_build_settings()
	_build_guidebook()
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_signal("locale_changed"):
		settings.locale_changed.connect(_on_locale_changed)
	if settings != null and settings.has_signal("controls_changed"):
		settings.controls_changed.connect(_on_controls_changed)
	_refresh_localized_content()
	_refresh_input_bindings()
	hide_all_modals()
	_hud.visible = false


func _process(delta: float) -> void:
	if _notification_timer > 0.0:
		_notification_timer = maxf(0.0, _notification_timer - delta)
		_notification.modulate.a = minf(1.0, _notification_timer * 3.0)
		if _notification_timer <= 0.0:
			_notification.visible = false
			_show_next_notification()
	if _objective_detail_timer > 0.0:
		_objective_detail_timer = maxf(0.0, _objective_detail_timer - delta)
		if _objective_detail_timer <= 0.0:
			_objective_detail.visible = false
		_objective_detail.visible = _objective_detail_timer > 0.0


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if is_instance_valid(_pause_center) and _pause_center.visible:
		resume_requested.emit()
	elif is_instance_valid(_hud) and _hud.visible:
		pause_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()


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
	_notification.position = Vector2(460.0, 76.0)
	_notification.size = Vector2(360.0, 36.0)
	_notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification.visible = false
	_root.add_child(_notification)


func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "GameplayHUD"
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_hud)
	_threat_radar = ThreatRadar.new()
	_threat_radar.name = "ThreatRadar"
	_hud.add_child(_threat_radar)
	_status_orbit = StatusOrbit.new()
	_status_orbit.name = "StatusOrbit"
	_hud.add_child(_status_orbit)

	_health_panel = _flat_panel()
	_set_panel_margins(_health_panel, 8, 4, 8, 4)
	_health_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health_panel.position = Vector2(18.0, 16.0)
	_health_panel.size = Vector2(184.0, 54.0)
	_hud.add_child(_health_panel)
	_health_bar = HealthPips.new()
	_health_panel.add_child(_health_bar)

	_objective_panel = _flat_panel()
	_set_panel_margins(_objective_panel, 10, 3, 10, 3)
	_objective_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective_panel.position = Vector2(460.0, 16.0)
	_objective_panel.custom_minimum_size = Vector2(360.0, 44.0)
	_objective_panel.size = Vector2(360.0, 44.0)
	_hud.add_child(_objective_panel)
	var objective_box := VBoxContainer.new()
	objective_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_objective_panel.add_child(objective_box)
	_objective_label = _label("OBJECTIVE_CALIBRATE", 15, INK)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_box.add_child(_objective_label)
	_objective_detail = _label("DEPLOY_CONTROLS", 12, MUTED)
	_objective_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_box.add_child(_objective_detail)

	_minimap_panel = _flat_panel()
	_set_panel_margins(_minimap_panel, 8, 5, 8, 5)
	_minimap_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_minimap_panel.position = Vector2(1094.0, 16.0)
	_minimap_panel.size = Vector2(168.0, 112.0)
	_hud.add_child(_minimap_panel)
	var minimap_box := VBoxContainer.new()
	_minimap_panel.add_child(minimap_box)
	_minimap_title = _label("UI_FLOODED_WORKS", 12, INK)
	minimap_box.add_child(_minimap_title)
	_minimap = StageMinimap.new()
	_minimap.custom_minimum_size = Vector2(144.0, 80.0)
	minimap_box.add_child(_minimap)

	_boss_cluster = VBoxContainer.new()
	_boss_cluster.name = "BossCluster"
	_boss_cluster.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_boss_cluster.position = Vector2(380.0, 70.0)
	_boss_cluster.size = Vector2(520.0, 40.0)
	_boss_cluster.add_theme_constant_override("separation", 1)
	_hud.add_child(_boss_cluster)
	_boss_name = _label("ENEMY_FOUNDRY_COLOSSUS", 14, OFF_WHITE)
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
	_boss_bar.custom_minimum_size = Vector2(520.0, 10.0)
	_boss_cluster.add_child(_boss_bar)
	_boss_state = _label("PATTERN_READING_ARENA", 9, OFF_WHITE)
	_boss_state.add_theme_color_override("font_shadow_color", CANVAS)
	_boss_state.add_theme_constant_override("shadow_offset_x", 2)
	_boss_state.add_theme_constant_override("shadow_offset_y", 2)
	_boss_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_cluster.add_child(_boss_state)
	_boss_state.visible = false
	_boss_cluster.visible = false

	_target_panel = _flat_panel()
	_set_panel_margins(_target_panel, 8, 5, 8, 5)
	_target_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_target_panel.position = Vector2(1078.0, 310.0)
	_target_panel.size = Vector2(184.0, 64.0)
	_hud.add_child(_target_panel)
	_target_cluster = VBoxContainer.new()
	_target_panel.add_child(_target_cluster)
	_target_name = _label("—", 14, INK)
	_target_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_cluster.add_child(_target_name)
	_target_bar = ProgressBar.new()
	_target_bar.show_percentage = false
	_target_bar.max_value = 1.0
	_target_bar.value = 1.0
	_target_bar.theme_type_variation = &"HealthMeter"
	_target_bar.custom_minimum_size = Vector2(160.0, 9.0)
	_target_cluster.add_child(_target_bar)
	_target_state = _label("", 12, MUTED)
	_target_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_cluster.add_child(_target_state)
	_target_panel.visible = false
	_target_cluster.set_meta("panel", _target_panel)

	_dock_panel = _flat_panel()
	_set_panel_margins(_dock_panel, 4, 2, 4, 2)
	_dock_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_dock_panel.position = Vector2(502.0, 644.0)
	_dock_panel.size = Vector2(276.0, 60.0)
	_hud.add_child(_dock_panel)
	var dock := HBoxContainer.new()
	dock.add_theme_constant_override("separation", 6)
	_dock_panel.add_child(dock)
	_primary_slot = _action_slot(dock, "LMB", "ACTION_PRIMARY", AMBER, true)
	_passive_slot = _action_slot(dock, "AUTO", "ACTION_SEEKER", MOSS)
	_dash_slot = _action_slot(dock, "SPACE", "ACTION_DASH", CYAN)
	_skill_slot = _action_slot(dock, "SHIFT", "ACTION_EMP", VIOLET)

	_buff_label = _label("", 13, OFF_WHITE)
	_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buff_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_buff_label.position = Vector2(340.0, 596.0)
	_buff_label.size = Vector2(600.0, 28.0)
	_buff_label.add_theme_color_override("font_shadow_color", CANVAS)
	_buff_label.add_theme_constant_override("shadow_offset_x", 2)
	_buff_label.add_theme_constant_override("shadow_offset_y", 2)
	_hud.add_child(_buff_label)
	_buff_label.visible = false
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	if not is_instance_valid(_root) or not is_instance_valid(_objective_panel):
		return
	var compact := _root.size.x < 1100.0
	var objective_width := 300.0 if compact else 360.0
	var objective_height := 40.0 if compact else 44.0
	var health_size := Vector2(168.0, 50.0) if compact else Vector2(184.0, 54.0)
	_health_panel.size = health_size
	_objective_panel.position = Vector2((_root.size.x - objective_width) * 0.5, 16.0)
	_objective_panel.custom_minimum_size = Vector2(objective_width, objective_height)
	_objective_panel.size = Vector2(objective_width, objective_height)
	var minimap_size := Vector2(144.0, 96.0) if compact else Vector2(168.0, 112.0)
	_minimap_panel.size = minimap_size
	_minimap_panel.position = Vector2(_root.size.x - minimap_size.x - 18.0, 16.0)
	_minimap.custom_minimum_size = Vector2(120.0, 64.0) if compact else Vector2(144.0, 80.0)
	var boss_width := minf(520.0, _root.size.x - health_size.x - minimap_size.x - 72.0)
	var boss_left := (_root.size.x - boss_width) * 0.5
	_boss_cluster.position = Vector2(boss_left, 16.0)
	_boss_cluster.size.x = boss_width
	_boss_bar.custom_minimum_size.x = boss_width
	var target_size := Vector2(168.0, 60.0) if compact else Vector2(184.0, 64.0)
	_target_panel.size = target_size
	_target_panel.position = Vector2(_root.size.x - target_size.x - 18.0, _root.size.y - target_size.y - 82.0)
	var dock_width := 276.0
	_dock_panel.size = Vector2(dock_width, 60.0)
	_dock_panel.position = Vector2((_root.size.x - dock_width) * 0.5, _root.size.y - 72.0)
	_objective_detail.add_theme_font_size_override("font_size", 12 if compact else 13)
	_notification.size.x = 320.0 if compact else 360.0
	_notification.position.x = (_root.size.x - _notification.size.x) * 0.5
	_notification.position.y = 68.0 if _boss_cluster.visible else 72.0


func _build_deployment() -> void:
	_deployment_center = CenterContainer.new()
	_deployment_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_deployment_center)
	var panel := _modal_panel(Vector2(840.0, 620.0))
	_deployment_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var kicker := _label("DEPLOY_KICKER", 14, AMBER)
	box.add_child(kicker)
	var title := _label("DEPLOY_TITLE", 30, INK)
	box.add_child(title)
	_deployment_controls_label = _label("DEPLOY_CONTROLS", 15, MUTED)
	_deployment_controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_deployment_controls_label.custom_minimum_size.y = 36.0
	box.add_child(_deployment_controls_label)
	var cannon := _label("DEPLOY_PULSE_CANNON_SUMMARY", 19, RAISED)
	cannon.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cannon.custom_minimum_size.y = 104.0
	cannon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cannon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cannon)
	var difficulty_label := _label("DEPLOY_DIFFICULTY_LABEL", 16, INK)
	box.add_child(difficulty_label)
	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation", 10)
	box.add_child(difficulty_row)
	for difficulty_id in RunDifficulty.IDS:
		var button := _command_button(
			_difficulty_title_key(difficulty_id),
			&"SecondaryButton"
		)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_run_difficulty.bind(difficulty_id))
		difficulty_row.add_child(button)
		_deployment_difficulty_buttons[difficulty_id] = button
	_deployment_difficulty_detail = _label("DEPLOY_DIFFICULTY_HARD_DETAIL", 14, MUTED)
	_deployment_difficulty_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_deployment_difficulty_detail.custom_minimum_size.y = 38.0
	_deployment_difficulty_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_deployment_difficulty_detail)
	_deployment_command = _command_button("DEPLOY_COMMAND", &"PrimaryButton")
	_deployment_command.pressed.connect(_on_deployment_confirmed)
	box.add_child(_deployment_command)
	var settings_button := _command_button("SETTINGS_OPEN", &"SecondaryButton")
	settings_button.pressed.connect(_show_settings.bind("deployment"))
	box.add_child(settings_button)
	var footer := _label("DEPLOY_FOOTER", 13, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)


func _build_upgrade() -> void:
	_upgrade_center = CenterContainer.new()
	_upgrade_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_upgrade_center)
	var panel := _modal_panel(Vector2(900.0, 520.0))
	_upgrade_center.add_child(panel)
	_upgrade_panel = UpgradeChoicePanel.new()
	_upgrade_panel.confirmed.connect(func(upgrade_id: StringName) -> void: upgrade_selected.emit(upgrade_id))
	_upgrade_panel.declined.connect(func() -> void: upgrade_declined.emit())
	_upgrade_panel.selected.connect(func(upgrade_id: StringName) -> void: upgrade_previewed.emit(upgrade_id))
	panel.add_child(_upgrade_panel)
	_upgrade_buttons = _upgrade_panel.buttons()


func _build_pause() -> void:
	_pause_center = CenterContainer.new()
	_pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_pause_center)
	var panel := _modal_panel(Vector2(560.0, 500.0))
	_pause_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)
	var title := _label("PAUSE_TITLE", 30, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var guide := _command_button("?", &"SecondaryButton")
	guide.tooltip_text = tr("GUIDE_TITLE")
	guide.accessibility_name = tr("GUIDE_TITLE")
	guide.custom_minimum_size = Vector2(44.0, 44.0)
	guide.pressed.connect(_show_guidebook.bind("pause"))
	header.add_child(guide)
	var resume := _command_button("PAUSE_RESUME", &"PrimaryButton")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	box.add_child(resume)
	_pause_first_button = resume
	var restart := _command_button("PAUSE_RESTART", &"SecondaryButton")
	restart.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart)
	var settings_button := _command_button("PAUSE_SETTINGS", &"SecondaryButton")
	settings_button.pressed.connect(_show_settings.bind("pause"))
	box.add_child(settings_button)
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

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var replay := _command_button("GARAGE_LAUNCH", &"PrimaryButton")
	replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay.pressed.connect(func() -> void: replay_requested.emit())
	footer.add_child(replay)
	var settings_button := _command_button("GARAGE_SETTINGS", &"SecondaryButton")
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(_show_settings.bind("garage"))
	footer.add_child(settings_button)
	_garage_first_button = replay


func _build_settings() -> void:
	_settings_center = CenterContainer.new()
	_settings_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_settings_center)
	var panel := _modal_panel(Vector2(840.0, 500.0))
	_settings_center.add_child(panel)
	_settings_panel = SettingsPanel.new()
	_settings_panel.close_requested.connect(_close_settings)
	_settings_panel.guide_requested.connect(_show_guidebook.bind("settings"))
	panel.add_child(_settings_panel)


func _build_guidebook() -> void:
	_guide_center = CenterContainer.new()
	_guide_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_guide_center)
	var panel := _modal_panel(Vector2(920.0, 540.0))
	_guide_center.add_child(panel)
	_guide_panel = GuidebookPanel.new()
	_guide_panel.close_requested.connect(_close_guidebook)
	panel.add_child(_guide_panel)


func update_hud(snapshot: Dictionary) -> void:
	if not is_instance_valid(_hud):
		return
	if snapshot.has("guidebook"):
		_latest_guidebook_snapshot = Dictionary(snapshot["guidebook"]).duplicate(true)
	if snapshot.has("health"):
		_health_bar.set_values(
			float(snapshot["health"]),
			maxf(1.0, float(snapshot.get("max_health", 1.0))),
			int(snapshot.get("level", 1)),
			float(snapshot.get("experience", 0.0)),
			float(snapshot.get("experience_required", 12.0)),
			bool(snapshot.get("reduced_motion", false))
		)
	if snapshot.has("objective"):
		var next_objective := String(snapshot["objective"])
		if next_objective != _last_objective_text:
			_last_objective_text = next_objective
			_objective_detail_timer = 3.0
			_objective_detail.visible = true
		_objective_label.text = next_objective
		_objective_detail.text = String(snapshot.get("objective_detail", ""))
		_minimap_title.text = String(snapshot.get("stage_title", tr("UI_FLOODED_WORKS")))
	if snapshot.has("primary_state"):
		_primary_slot.action_name = String(snapshot.get("primary_name", "ACTION_PRIMARY"))
		_primary_slot.set_state(String(snapshot["primary_state"]), float(snapshot.get("primary_ratio", 0.0)))
		_dash_slot.set_state(String(snapshot.get("dash_state", "STATE_READY")), float(snapshot.get("dash_ratio", 0.0)))
		_passive_slot.set_state(String(snapshot.get("passive_state", "STATE_READY")), float(snapshot.get("passive_ratio", 0.0)))
		_skill_slot.set_state(String(snapshot.get("skill_state", "STATE_READY")), float(snapshot.get("skill_ratio", 0.0)))
		_buff_label.text = String(snapshot.get("buff_text", ""))
	if snapshot.has("boss"):
		var boss: Dictionary = snapshot["boss"]
		_boss_cluster.visible = bool(boss.get("visible", false))
		_objective_panel.visible = not _boss_cluster.visible
		_minimap_panel.visible = true
		_notification.position.y = 68.0 if _boss_cluster.visible else 72.0
		if _boss_cluster.visible:
			_boss_name.text = String(boss.get("name", "BOSS"))
			_boss_bar.max_value = maxf(1.0, float(boss.get("max_health", 1.0)))
			_boss_bar.value = float(boss.get("health", 0.0))
			_boss_state.text = String(boss.get("state", ""))
	if snapshot.has("target"):
		var target: Dictionary = snapshot["target"]
		var target_panel: Control = _target_cluster.get_meta("panel")
		target_panel.visible = bool(target.get("visible", false))
		if target_panel.visible:
			_target_name.text = String(target.get("name", "TARGET"))
			_target_bar.max_value = maxf(1.0, float(target.get("max_health", 1.0)))
			_target_bar.value = float(target.get("health", 0.0))
			_target_state.text = String(target.get("state", ""))
	if snapshot.has("minimap"):
		_minimap.set_snapshot(snapshot["minimap"])
	if snapshot.has("threat_radar"):
		_threat_radar.set_snapshot(snapshot["threat_radar"])
	if snapshot.has("status_orbit"):
		_status_orbit.set_snapshot(snapshot["status_orbit"])


func show_deployment(
	_selected: StringName = &"pulse_cannon",
	difficulty_id: StringName = RunDifficulty.DEFAULT
) -> void:
	hide_all_modals()
	_selected_primary = &"pulse_cannon"
	_selected_run_difficulty = RunDifficulty.normalize(difficulty_id)
	_refresh_difficulty_selection()
	_dim.visible = true
	_deployment_center.visible = true
	_hud.visible = false
	_deployment_command.grab_focus()


func show_upgrade(cards: Array[Dictionary], optional: bool = false) -> void:
	hide_all_modals()
	_dim.visible = true
	_upgrade_center.visible = true
	_hud.visible = false
	_latest_upgrade_cards = cards.duplicate(true)
	_latest_upgrade_optional = optional
	_upgrade_panel.open(cards, optional)


func upgrade_apply_failed(reason: String) -> void:
	_upgrade_panel.apply_failed(reason)


func _refresh_upgrade_cards() -> void:
	_upgrade_panel.open(_latest_upgrade_cards, _latest_upgrade_optional)


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
	var has_next := false
	_result_kicker.text = tr("RESULT_STAGE_COMPLETE").replace("%d", str(int(summary.get("stage_number", 1)))).replace("%s", tr(String(summary.get("stage_title_key", "STAGE_FLOODED_WORKS"))))
	_result_title.text = tr("RESULT_TITLE_FINAL")
	_result_first_button = _result_garage_button
	_refresh_result_summary()
	_result_first_button.grab_focus()


func show_garage(data: Dictionary) -> void:
	hide_all_modals()
	_dim.visible = true
	_garage_center.visible = true
	_hud.visible = false
	_latest_garage_data = data.duplicate(true)
	_selected_primary = &"pulse_cannon"
	_refresh_garage_content()
	_garage_first_button.grab_focus()


func show_gameplay() -> void:
	hide_all_modals()
	_hud.visible = true


func _show_settings(return_surface: String) -> void:
	_settings_return_surface = return_surface
	hide_all_modals()
	_dim.visible = true
	_settings_center.visible = true
	_hud.visible = false
	_settings_panel.open()


func _close_settings() -> void:
	match _settings_return_surface:
		"pause":
			show_pause()
		"garage":
			show_garage(_latest_garage_data)
		_:
			show_deployment(_selected_primary, _selected_run_difficulty)


func _show_guidebook(return_surface: String) -> void:
	_guide_return_surface = return_surface
	hide_all_modals()
	_dim.visible = true
	_guide_center.visible = true
	_hud.visible = false
	_guide_panel.open(_latest_guidebook_snapshot)


func _close_guidebook() -> void:
	if _guide_return_surface == "settings":
		_show_settings(_settings_return_surface)
	else:
		show_pause()


func hide_all_modals() -> void:
	if not is_instance_valid(_dim):
		return
	# Modal layers own attention; transient combat notifications must not peek
	# above their top edge at compact resolutions.
	_notification.visible = false
	_dim.visible = false
	_deployment_center.visible = false
	_upgrade_center.visible = false
	_pause_center.visible = false
	_result_center.visible = false
	_garage_center.visible = false
	_settings_center.visible = false
	_guide_center.visible = false


func notify(message: String, duration: float = 2.4, color: Color = OFF_WHITE) -> void:
	var entry := {"message":message, "duration":duration, "color":color}
	if _notification_timer > 0.0:
		if _notification_queue.size() >= 5:
			_notification_queue.pop_front()
		_notification_queue.append(entry)
		return
	_show_notification(entry)


func clear_notifications() -> void:
	_notification_queue.clear()
	_notification_timer = 0.0
	_notification.visible = false


func _show_next_notification() -> void:
	if _notification_queue.is_empty():
		return
	_show_notification(_notification_queue.pop_front())


func _show_notification(entry: Dictionary) -> void:
	_notification.text = String(entry["message"])
	_notification.add_theme_color_override("font_color", Color(entry["color"]))
	_notification.modulate.a = 1.0
	_notification.visible = true
	_notification_timer = float(entry["duration"])


func set_hud_visible(visible: bool) -> void:
	_hud.visible = visible


func is_modal_visible() -> bool:
	return _dim.visible


func debug_layout_minimums() -> Dictionary:
	return {
		"deployment": Vector2(840.0, 620.0),
		"upgrade": Vector2(900.0, 520.0),
		"pause": Vector2(560.0, 500.0),
		"result": Vector2(720.0, 510.0),
		"garage": Vector2(860.0, 510.0),
		"settings": Vector2(840.0, 500.0),
		"guidebook": Vector2(860.0, 500.0),
	}


func debug_ui_contract(viewport_width: float = 1280.0) -> Dictionary:
	var compact := viewport_width < 1100.0
	var viewport_height := viewport_width * 9.0 / 16.0
	var objective_width := 300.0 if compact else 360.0
	var objective_height := 40.0 if compact else 44.0
	var health_size := Vector2(168.0, 50.0) if compact else Vector2(184.0, 54.0)
	var minimap_size := Vector2(144.0, 96.0) if compact else Vector2(168.0, 112.0)
	var target_size := Vector2(168.0, 60.0) if compact else Vector2(184.0, 64.0)
	var dock_size := Vector2(276.0, 60.0)
	var health_end := 18.0 + (168.0 if compact else 184.0)
	var objective_start := viewport_width * 0.5 - objective_width * 0.5
	var objective_end := objective_start + objective_width
	var minimap_start := viewport_width - (162.0 if compact else 186.0)
	var body_font_weight := 0.0
	if _root.theme.default_font is FontVariation:
		body_font_weight = float((_root.theme.default_font as FontVariation).variation_opentype.get("wght", 0.0))
	var opaque_rects := [
		Rect2(Vector2(18.0, 16.0), health_size),
		Rect2(Vector2(objective_start, 16.0), Vector2(objective_width, objective_height)),
		Rect2(Vector2(viewport_width - minimap_size.x - 18.0, 16.0), minimap_size),
		Rect2(Vector2(viewport_width - target_size.x - 18.0, viewport_height - target_size.y - 82.0), target_size),
		Rect2(Vector2((viewport_width - dock_size.x) * 0.5, viewport_height - 72.0), dock_size),
	]
	var opaque_area := 0.0
	var central_safe := Rect2(Vector2(viewport_width * 0.20, viewport_height * 0.20), Vector2(viewport_width * 0.60, viewport_height * 0.60))
	var central_safe_clear := true
	for rect in opaque_rects:
		opaque_area += Rect2(rect).get_area()
		central_safe_clear = central_safe_clear and not Rect2(rect).intersects(central_safe)
	return {
		"theme_path": _root.theme.resource_path if _root.theme != null else "",
		"command_min_height": _pause_first_button.custom_minimum_size.y,
		"action_rail_size": Vector2(276.0, 60.0),
		"primary_slot_size": _primary_slot.custom_minimum_size,
		"secondary_slot_size": _dash_slot.custom_minimum_size,
		"body_font_weight": body_font_weight,
		"minimap_size": minimap_size,
		"health_cluster_size": health_size,
		"objective_cluster_size": Vector2(objective_width, objective_height),
		"target_cluster_size": target_size,
		"boss_strip_size": Vector2(minf(520.0, viewport_width - 424.0), 40.0),
		"opaque_combat_area_ratio": opaque_area / (viewport_width * viewport_height),
		"central_safe_clear": central_safe_clear,
		"top_clusters_do_not_overlap": health_end <= objective_start and objective_end <= minimap_start,
		"deployment_focusables": _deployment_center.find_children("*", "Button", true, false).size(),
		"deployment_difficulty_choices": _deployment_difficulty_buttons.size(),
		"deployment_difficulty_min_height": _minimum_difficulty_button_height(),
		"deployment_difficulty": _selected_run_difficulty,
		"upgrade_focusables": _upgrade_center.find_children("*", "Button", true, false).size(),
		"pause_focusables": _pause_center.find_children("*", "Control", true, false).filter(
			func(control: Control) -> bool: return control.focus_mode != Control.FOCUS_NONE
		).size(),
		"result_focusables": _result_center.find_children("*", "Button", true, false).size(),
		"garage_focusables": _garage_center.find_children("*", "Control", true, false).filter(
			func(control: Control) -> bool: return control.focus_mode != Control.FOCUS_NONE
		).size(),
		"locale": TranslationServer.get_locale().left(2),
		"settings": _settings_panel.debug_contract(),
	}


func debug_modal_contract(surface: String) -> Dictionary:
	match surface:
		"deployment":
			show_deployment(_selected_primary, _selected_run_difficulty)
		"upgrade":
			show_upgrade([])
		"pause":
			show_pause()
		"result":
			show_result({"upgrade": "UPGRADE_NONE"})
		"garage":
			show_garage({})
		"settings":
			_show_settings("deployment")
		"guidebook":
			_show_guidebook("settings")
	return {"surface": surface, "hud_hidden": not _hud.visible, "dim_visible": _dim.visible}


func debug_gameplay_settings_contract() -> Dictionary:
	_show_settings("deployment")
	_settings_panel.debug_show_gameplay_page()
	return _settings_panel.debug_contract()


func debug_select_upgrade(index: int) -> void:
	_upgrade_panel.call("_process", 0.36)
	_upgrade_panel.call("_select", index)


func debug_threat_radar_contract() -> Dictionary:
	return _threat_radar.debug_contract()


func debug_status_orbit_contract() -> Dictionary:
	return _status_orbit.debug_contract()


func _on_deployment_confirmed() -> void:
	deployment_selected.emit(&"pulse_cannon", _selected_run_difficulty)


func _select_run_difficulty(difficulty_id: StringName) -> void:
	_selected_run_difficulty = RunDifficulty.normalize(difficulty_id)
	_refresh_difficulty_selection()


func _refresh_difficulty_selection() -> void:
	if not is_instance_valid(_deployment_difficulty_detail):
		return
	for difficulty_id in _deployment_difficulty_buttons:
		var button := _deployment_difficulty_buttons[difficulty_id] as Button
		button.text = tr(_difficulty_title_key(difficulty_id))
		button.theme_type_variation = (
			&"SelectedChoiceButton"
			if difficulty_id == _selected_run_difficulty
			else &"SecondaryButton"
		)
	_deployment_difficulty_detail.text = tr(_difficulty_detail_key(_selected_run_difficulty))


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
	for button_variant in _deployment_difficulty_buttons.values():
		minimum_height = minf(minimum_height, (button_variant as Button).custom_minimum_size.y)
	return 0.0 if is_inf(minimum_height) else minimum_height


func _refresh_result_summary() -> void:
	if _latest_result_summary.is_empty():
		return
	var summary_label: Label = _result_center.get_child(0).get_child(0).get_meta("summary")
	var result := _latest_result_summary
	summary_label.text = "%s\n%s\n%s\n%s\n\n%s\n%s  ·  %s  ·  %s\n\n%s\n✦  %s" % [
		tr("RESULT_RUN"),
		tr("RESULT_CLEAR_TIME") % String(result.get("time", "0:00")),
		tr("RESULT_HULL") % roundi(float(result.get("health_ratio", 0.0)) * 100.0),
		tr("RESULT_UPGRADE") % tr(String(result.get("upgrade", "UPGRADE_NONE"))),
		tr("RESULT_PERFORMANCE"),
		tr("RESULT_PRIMARY_HITS") % int(result.get("primary_hits", 0)),
		tr("RESULT_DASH_USES") % int(result.get("dash_uses", 0)),
		tr("RESULT_INSTALLATIONS") % int(result.get("installations", 0)),
		tr("RESULT_REWARD"),
		tr("RESULT_RELAY_MODULE"),
	]


func _refresh_garage_content() -> void:
	_refresh_garage_primary()
	var secondary_names: Array[String] = []
	for family in _latest_garage_data.get("secondaries", []):
		secondary_names.append("%s Lv.%d" % [tr(String(family["name_key"])), int(family["level"])])
	_garage_passive_label.text = "%s  ·  %s" % [tr("GARAGE_PASSIVE"), ", ".join(secondary_names)]
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
	var build_summary := String(_latest_garage_data.get("build_summary", ""))
	if not build_summary.is_empty():
		_garage_unlock_label.text += "\n%s  ·  %s" % [tr("GARAGE_RUN_BUILD"), build_summary]


func _refresh_garage_primary() -> void:
	_garage_primary_label.text = "%s  ·  %s" % [tr("GARAGE_PRIMARY"), tr("PRIMARY_PULSE_CANNON")]


func _on_locale_changed(_locale: String) -> void:
	_refresh_localized_content()


func _refresh_localized_content() -> void:
	_refresh_garage_content()
	_refresh_result_summary()
	_refresh_difficulty_selection()
	_refresh_input_bindings()
	_primary_slot.queue_redraw()
	_passive_slot.queue_redraw()
	_dash_slot.queue_redraw()
	_skill_slot.queue_redraw()
	if not _latest_upgrade_cards.is_empty() and _upgrade_center.visible:
		_refresh_upgrade_cards()

func _on_controls_changed(_action: StringName) -> void:
	_refresh_input_bindings()


func _refresh_input_bindings() -> void:
	if not is_instance_valid(_primary_slot):
		return
	var settings := get_node_or_null("/root/SettingsStore")
	var bindings := InputProfile.default_descriptors()
	if settings != null:
		bindings = settings.control_bindings
	_primary_slot.set_binding(InputProfile.action_display_name(&"primary_fire", bindings))
	_dash_slot.set_binding(InputProfile.action_display_name(&"dash", bindings))
	_skill_slot.set_binding(InputProfile.action_display_name(&"active_skill", bindings))
	if is_instance_valid(_deployment_controls_label):
		_deployment_controls_label.text = tr("DEPLOY_CONTROLS_TEMPLATE") % [
			InputProfile.action_display_name(&"primary_fire", bindings),
			InputProfile.action_display_name(&"dash", bindings),
			InputProfile.action_display_name(&"active_skill", bindings),
		]


func _flat_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"FlatPanel"
	panel.add_theme_constant_override("margin_left", 14)
	panel.add_theme_constant_override("margin_top", 10)
	panel.add_theme_constant_override("margin_right", 14)
	panel.add_theme_constant_override("margin_bottom", 10)
	return panel


func _set_panel_margins(panel: PanelContainer, left: int, top: int, right: int, bottom: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Art.IVORY_BRIGHT, 0.96)
	style.content_margin_left = left
	style.content_margin_top = top
	style.content_margin_right = right
	style.content_margin_bottom = bottom
	panel.add_theme_stylebox_override("panel", style)


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
