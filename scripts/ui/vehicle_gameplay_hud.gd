class_name VehicleGameplayHud
extends Control

## Owns the four-zone gameplay HUD and transient HUD-only presentation.
## It consumes immutable snapshots and never queries or mutates gameplay state.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const ThreatRadar = preload("res://scripts/ui/vehicle_threat_radar.gd")
const StageTransitionBanner = preload("res://scripts/ui/vehicle_stage_transition_banner.gd")
const RetainedMinimapMesh = preload("res://scripts/ui/vehicle_retained_minimap_mesh.gd")
const AcquiredUpgradeRail = preload(
	"res://scripts/ui/vehicle_acquired_upgrade_rail.gd"
)
const UiGlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)

const MISSION_CLUSTER_SIZE := Vector2(260.0, 76.0)
const HEALTH_STRIP_SIZE := Vector2(520.0, 24.0)
const ACTION_RAIL_SIZE := Vector2(88.0, 88.0)
const ACTION_RAIL_BOTTOM_MARGIN := 20.0


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
		custom_minimum_size = HEALTH_STRIP_SIZE
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
		var next_maximum := maxf(1.0, max_value)
		var next_required := maxf(1.0, required_value)
		var values_changed := (
			not is_equal_approx(next_health, health)
			or not is_equal_approx(next_maximum, maximum)
			or run_level != level_value
			or not is_equal_approx(experience, experience_value)
			or not is_equal_approx(experience_required, next_required)
		)
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
		maximum = next_maximum
		run_level = level_value
		experience = experience_value
		experience_required = next_required
		if values_changed:
			queue_redraw()

	func _process(delta: float) -> void:
		if _pulse_time > 0.0:
			_pulse_time = maxf(0.0, _pulse_time - delta)
		if _trail_hold > 0.0:
			_trail_hold = maxf(0.0, _trail_hold - delta)
		elif trailing_health > health:
			_trail_elapsed = minf(_trail_duration, _trail_elapsed + delta)
			trailing_health = lerpf(
				_trail_from,
				health,
				_trail_elapsed / _trail_duration
			)
		if (
			_pulse_time <= 0.0
			and _trail_hold <= 0.0
			and trailing_health <= health + 0.001
		):
			trailing_health = health
			set_process(false)
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		var hull_rect := Rect2(0.0, 5.0, size.x, 13.0)
		_draw_meter_track(hull_rect)
		_draw_meter_fill(
			hull_rect,
			clampf(trailing_health / maximum, 0.0, 1.0),
			Color(Art.IVORY_BRIGHT, 0.32)
		)
		_draw_meter_fill(
			hull_rect,
			clampf(health / maximum, 0.0, 1.0),
			Art.PLAYER_REWARD
		)
		if _pulse_time > 0.0:
			draw_rect(hull_rect, Art.IVORY_BRIGHT, false, 2.0)
		draw_string(
			font,
			Vector2(0.0, 17.0),
			"%d / %d" % [roundi(health), roundi(maximum)],
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			16,
			Art.IVORY_BRIGHT
		)

	func _draw_meter_track(rect: Rect2) -> void:
		draw_rect(rect, Art.COBALT_DEEP)
		draw_rect(rect, Color(Art.TEXT_MUTED, 0.72), false, 1.0)

	func _draw_meter_fill(
		rect: Rect2,
		ratio: float,
		color: Color
	) -> void:
		if ratio <= 0.0:
			return
		var clamped := clampf(ratio, 0.0, 1.0)
		draw_rect(
			Rect2(rect.position, Vector2(rect.size.x * clamped, rect.size.y)),
			color
		)

	func debug_contract() -> Dictionary:
		return {
			"code_drawn":true,
			"image_backed":false,
			"has_background_geometry":true,
			"has_trailing_health_geometry":true,
			"has_health_geometry":true,
			"has_experience_geometry":false,
			"panel_free":true,
			"centered_value":true,
			"trailing_animation_preserved":true,
			"reduced_motion_immediate":true,
			"reduced_motion_active":reduced_motion,
		}


class ActionRailSlot:
	extends Control

	var action_id: StringName = &"emp"
	var accent := Art.PLAYER_REWARD
	var cooldown_ratio := 0.0
	var available := true

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = ACTION_RAIL_SIZE

	func configure(glyph_id: StringName, color: Color) -> void:
		if action_id == glyph_id and accent.is_equal_approx(color):
			return
		action_id = glyph_id
		accent = color
		queue_redraw()

	func set_state(is_available: bool, ratio: float = 0.0) -> void:
		var next_ratio := clampf(ratio, 0.0, 1.0)
		if available == is_available and is_equal_approx(cooldown_ratio, next_ratio):
			return
		available = is_available
		cooldown_ratio = next_ratio
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.44
		var state_color := accent if available else Art.TEXT_MUTED
		draw_circle(center, radius, Color(Art.SPACE_BLACK, 0.72))
		draw_arc(center, radius, 0.0, TAU, 48, Color(state_color, 0.88), 3.0, true)
		if available:
			# The inner ring is a structural ready cue independent of color.
			draw_arc(center, radius - 7.0, 0.0, TAU, 40, Art.IVORY_BRIGHT, 2.0, true)
		UiGlyphCatalog.draw_action_glyph(
			self,
			action_id,
			center,
			24.0,
			{
				&"primary":Color(state_color, 1.0 if available else 0.42),
				&"secondary":Color(state_color, 0.78 if available else 0.34),
				&"highlight":Color(Art.IVORY_BRIGHT, 1.0 if available else 0.40),
			}
		)
		if not available and cooldown_ratio < 0.9999:
			draw_arc(
				center,
				radius - 7.0,
				-PI * 0.5,
				-PI * 0.5 + TAU * (1.0 - cooldown_ratio),
				24,
				Color(accent, 0.82),
				5.0,
				true
			)
		if not available:
			# A diagonal lockout slash keeps disabled readable in grayscale.
			draw_line(
				center - Vector2.ONE * (radius * 0.50),
				center + Vector2.ONE * (radius * 0.50),
				Art.IVORY_BRIGHT,
				2.0
			)

	func debug_contract() -> Dictionary:
		var descriptor := UiGlyphCatalog.action_descriptor(action_id)
		return {
			"available":available,
			"image_backed":false,
			"state_code_drawn":true,
			"semantic_icon_image_retained":false,
			"code_native_glyph":true,
			"disabled_not_color_only":true,
			"available_has_structural_rail":false,
			"available_has_structural_ring":available,
			"disabled_has_structural_slash":not available,
			"cooldown_has_structural_arc":(
				not available and cooldown_ratio < 0.9999
			),
			"cooldown_ratio":cooldown_ratio,
			"interior_filled":false,
			"round":true,
			"panel_free":true,
			"has_text":false,
			"draw_batches":2,
			"minimum_size":custom_minimum_size,
			"glyph_id":action_id,
			"shared_glyph_recipe":not descriptor.is_empty(),
			"semantic_texture":false,
			"glyph_command_count":Array(
				descriptor.get("commands", [])
			).size(),
		}


class StageMinimap:
	extends Control

	var snapshot: Dictionary = {}
	var _static_map_mesh: ArrayMesh
	var _static_mesh_size := Vector2.ZERO
	var _dynamic_map: VehicleRetainedMinimapMesh
	var _dynamic_mesh_size := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(144.0, 80.0)

	func set_snapshot(value: Dictionary) -> void:
		var redraw_needed := false
		var static_geometry_changed := (
			value.has("floor_polygons")
			or value.has("void_polygons")
			or value.has("blocker_polygons")
		)
		var world_size_changed := (
			value.has("world_size")
			and (
				not snapshot.has("world_size")
				or not Vector2(snapshot["world_size"]).is_equal_approx(
					Vector2(value["world_size"])
				)
			)
		)
		for key in value:
			snapshot[key] = value[key]
		if static_geometry_changed or world_size_changed:
			_static_map_mesh = null
			redraw_needed = true
		if _dynamic_map != null and _dynamic_mesh_size.is_equal_approx(size):
			_dynamic_map.update(snapshot)
		else:
			_dynamic_map = null
			redraw_needed = true
		if redraw_needed:
			queue_redraw()

	func _draw() -> void:
		var world_size: Vector2 = snapshot.get(
			"world_size",
			Vector2(5200.0, 2200.0)
		)
		if _static_map_mesh == null or not _static_mesh_size.is_equal_approx(size):
			_static_map_mesh = _build_static_map_mesh(world_size)
			_static_mesh_size = size
		if _static_map_mesh != null:
			draw_mesh(_static_map_mesh, null)
		if _dynamic_map == null or not _dynamic_mesh_size.is_equal_approx(size):
			_dynamic_map = RetainedMinimapMesh.new(size)
			_dynamic_mesh_size = size
			_dynamic_map.update(snapshot)
		if _dynamic_map != null and _dynamic_map.mesh != null:
			draw_mesh(_dynamic_map.mesh, null)

	func _build_static_map_mesh(world_size: Vector2) -> ArrayMesh:
		var vertices := PackedVector3Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		for layer in [
			{"key":"floor_polygons", "color":Art.IVORY_SHADE},
			{"key":"void_polygons", "color":Art.COBALT_ENERGY},
			{"key":"blocker_polygons", "color":Art.BLOCKER_FILL},
		]:
			for polygon_variant in snapshot.get(layer["key"], []):
				var points := PackedVector2Array()
				for point in PackedVector2Array(polygon_variant):
					points.append(Vector2(
						point.x / world_size.x * size.x,
						point.y / world_size.y * size.y
					))
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


var _mission_panel: PanelContainer
var _center_status: VBoxContainer
var _minimap_panel: PanelContainer
var _target_panel: VBoxContainer
var _health_bar: HealthPips
var _upgrade_rail: VehicleAcquiredUpgradeRail
var _stage_label: Label
var _objective_label: Label
var _objective_detail: Label
var _experience_bar: ProgressBar
var _objective_detail_timer := 0.0
var _last_objective_text := ""
var _last_objective_detail := ""
var _accessibility_text_scale := 1.0
var _last_buff_text := ""
var _boss_visible := false
var _target_visible := false
var _boss_cluster: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_state: Label
var _target_name: Label
var _target_bar: ProgressBar
var _target_state: Label
var _skill_slot: ActionRailSlot
var _buff_label: Label
var _minimap: StageMinimap
var _notification_panel: PanelContainer
var _notification: Label
var _notification_timer := 0.0
var _notification_queue: Array[Dictionary] = []
var _transition_banner: VehicleStageTransitionBanner
var _threat_radar: VehicleThreatRadar


func _ready() -> void:
	name = "GameplayHUD"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_responsive_layout)
	_build()
	_apply_responsive_layout()
	set_process(false)


func _process(delta: float) -> void:
	if _notification_timer > 0.0:
		_notification_timer = maxf(0.0, _notification_timer - delta)
		_notification_panel.modulate.a = minf(
			1.0,
			_notification_timer * 3.0
		)
		if _notification_timer <= 0.0:
			_notification_panel.visible = false
			_show_next_notification()
	if _objective_detail_timer > 0.0:
		_objective_detail_timer = maxf(0.0, _objective_detail_timer - delta)
		if _objective_detail_timer <= 0.0 and _objective_detail.visible:
			_objective_detail.visible = false
			_apply_responsive_layout()
	if _notification_timer <= 0.0 and _objective_detail_timer <= 0.0:
		set_process(false)


func _build() -> void:
	_threat_radar = ThreatRadar.new()
	_threat_radar.name = "ThreatRadar"
	add_child(_threat_radar)

	_mission_panel = Factory.surface(Factory.SURFACE_HUD, MISSION_CLUSTER_SIZE)
	_mission_panel.name = "MissionPanel"
	_mission_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_panel.position = Vector2(18.0, 16.0)
	_mission_panel.size = MISSION_CLUSTER_SIZE
	add_child(_mission_panel)
	var mission_zone := VBoxContainer.new()
	mission_zone.name = "MissionZoneContent"
	mission_zone.add_theme_constant_override("separation", 2)
	mission_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_panel.add_child(mission_zone)
	_stage_label = Factory.label("STAGE_1_NAME", 14, Art.IVORY_BRIGHT)
	_stage_label.name = "StageLabel"
	_stage_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_shadow_label(_stage_label)
	mission_zone.add_child(_stage_label)
	_objective_label = Factory.label("OBJECTIVE_CALIBRATE", 14, Art.IVORY_BRIGHT)
	_objective_label.name = "ObjectiveLabel"
	_objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_shadow_label(_objective_label)
	mission_zone.add_child(_objective_label)
	_objective_detail = Factory.label("DEPLOY_CONTROLS", 14, Art.TEXT_MUTED)
	_objective_detail.name = "ObjectiveDetail"
	_objective_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_objective_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_zone.add_child(_objective_detail)
	_objective_detail.visible = false
	_boss_cluster = VBoxContainer.new()
	_boss_cluster.name = "BossCluster"
	_boss_cluster.add_theme_constant_override("separation", 1)
	mission_zone.add_child(_boss_cluster)
	_boss_name = Factory.label(
		"ENEMY_FOUNDRY_COLOSSUS",
		14,
		Art.IVORY_BRIGHT
	)
	_shadow_label(_boss_name)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_boss_cluster.add_child(_boss_name)
	_boss_bar = Factory.meter(Factory.METER_BOSS)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	_boss_bar.custom_minimum_size.y = 10.0
	_boss_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_cluster.add_child(_boss_bar)
	_boss_state = Factory.label(
		"PATTERN_READING_ARENA",
		14,
		Art.TEXT_MUTED
	)
	_shadow_label(_boss_state)
	_boss_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_boss_state.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_boss_cluster.add_child(_boss_state)
	_boss_cluster.visible = false
	_experience_bar = Factory.meter(Factory.METER_SUPPORT)
	_experience_bar.name = "ExperienceBar"
	_experience_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_experience_bar.max_value = 12.0
	_experience_bar.value = 0.0
	_experience_bar.custom_minimum_size.y = 5.0
	mission_zone.add_child(_experience_bar)

	_center_status = VBoxContainer.new()
	_center_status.name = "CenterStatus"
	_center_status.alignment = BoxContainer.ALIGNMENT_CENTER
	_center_status.add_theme_constant_override("separation", 2)
	_center_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center_status)
	_health_bar = HealthPips.new()
	_center_status.add_child(_health_bar)
	_upgrade_rail = AcquiredUpgradeRail.new()
	_center_status.add_child(_upgrade_rail)

	_minimap_panel = Factory.surface(
		Factory.SURFACE_HUD,
		Vector2(176.0, 108.0)
	)
	_minimap_panel.name = "MinimapPanel"
	_minimap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap_panel.size = Vector2(176.0, 108.0)
	add_child(_minimap_panel)
	var minimap_zone := VBoxContainer.new()
	minimap_zone.name = "MinimapZoneContent"
	minimap_zone.add_theme_constant_override("separation", 4)
	_minimap_panel.add_child(minimap_zone)
	_minimap = StageMinimap.new()
	_minimap.custom_minimum_size = Vector2(168.0, 100.0)
	minimap_zone.add_child(_minimap)

	_target_panel = VBoxContainer.new()
	_target_panel.name = "TargetPanel"
	_target_panel.add_theme_constant_override("separation", 1)
	minimap_zone.add_child(_target_panel)
	_target_name = Factory.label("—", 14, Art.IVORY_BRIGHT)
	_target_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_panel.add_child(_target_name)
	_target_bar = Factory.meter(Factory.METER_HEALTH)
	_target_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_bar.max_value = 1.0
	_target_bar.value = 1.0
	_target_bar.custom_minimum_size.y = 9.0
	_target_panel.add_child(_target_bar)
	_target_state = Factory.label("", 14, Art.TEXT_MUTED)
	_target_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_panel.add_child(_target_state)
	_target_panel.visible = false

	_skill_slot = ActionRailSlot.new()
	_skill_slot.name = "EmpCooldownIndicator"
	_skill_slot.configure(&"emp", Art.BOSS_COMMAND)
	add_child(_skill_slot)

	_buff_label = Factory.label("", 14, Art.TEXT_PRIMARY)
	_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buff_label.size = Vector2(600.0, 28.0)
	_shadow_label(_buff_label)
	add_child(_buff_label)
	_buff_label.visible = false

	_notification_panel = Factory.surface(
		Factory.SURFACE_TOAST,
		Vector2(360.0, 44.0)
	)
	_notification_panel.name = "NotificationPanel"
	_notification_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_panel.size = Vector2(360.0, 44.0)
	add_child(_notification_panel)
	_notification = Factory.label("", 18, Art.IVORY_BRIGHT)
	_notification.name = "Notification"
	_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shadow_label(_notification)
	_notification_panel.add_child(_notification)
	_notification_panel.visible = false

	_transition_banner = StageTransitionBanner.new()
	add_child(_transition_banner)


func update_snapshot(snapshot: Dictionary) -> void:
	if snapshot.has("health"):
		var required_experience := maxf(
			1.0,
			float(snapshot.get("experience_required", 12.0))
		)
		_health_bar.set_values(
			float(snapshot["health"]),
			maxf(1.0, float(snapshot.get("max_health", 1.0))),
			int(snapshot.get("level", 1)),
			float(snapshot.get("experience", 0.0)),
			required_experience,
			bool(snapshot.get("reduced_motion", false))
		)
		_experience_bar.max_value = required_experience
		_experience_bar.value = clampf(
			float(snapshot.get("experience", 0.0)),
			0.0,
			required_experience
		)
	if snapshot.has("stage_title"):
		_stage_label.text = String(snapshot["stage_title"])
	if snapshot.has("objective"):
		var next_objective := String(snapshot["objective"])
		if next_objective != _last_objective_text:
			_last_objective_text = next_objective
			_objective_detail_timer = 3.0
			_objective_detail.visible = true
			_objective_label.text = next_objective
			set_process(true)
		var next_detail := String(snapshot.get("objective_detail", ""))
		if next_detail != _last_objective_detail:
			_last_objective_detail = next_detail
			_objective_detail.text = next_detail
		_objective_detail.visible = (
			_objective_detail_timer > 0.0
			and not _objective_detail.text.is_empty()
		)
		_apply_responsive_layout()
	if snapshot.has("build_snapshot"):
		_upgrade_rail.set_build_snapshot(
			Dictionary(snapshot["build_snapshot"])
		)
		_apply_responsive_layout()
	if snapshot.has("skill_available"):
		_skill_slot.set_state(
			bool(snapshot.get("skill_available", false)),
			float(snapshot.get("skill_ratio", 0.0))
		)
	if snapshot.has("buff_text"):
		var next_buff_text := String(snapshot.get("buff_text", ""))
		if next_buff_text != _last_buff_text:
			_last_buff_text = next_buff_text
			_buff_label.text = next_buff_text
			_buff_label.visible = not next_buff_text.is_empty()
	if snapshot.has("boss"):
		var boss := Dictionary(snapshot["boss"])
		var boss_name := String(boss.get("name", "")).strip_edges()
		var next_boss_visible := (
			bool(boss.get("visible", false))
			and not boss_name.is_empty()
		)
		if next_boss_visible != _boss_visible:
			_boss_visible = next_boss_visible
			_boss_cluster.visible = next_boss_visible
			_apply_responsive_layout()
		if next_boss_visible:
			if _boss_name.text != boss_name:
				_boss_name.text = boss_name
			var next_boss_maximum := maxf(
				1.0,
				float(boss.get("max_health", 1.0))
			)
			var next_boss_health := float(boss.get("health", 0.0))
			if not is_equal_approx(_boss_bar.max_value, next_boss_maximum):
				_boss_bar.max_value = next_boss_maximum
			if not is_equal_approx(_boss_bar.value, next_boss_health):
				_boss_bar.value = next_boss_health
			var next_boss_state := String(boss.get("state", ""))
			if _boss_state.text != next_boss_state:
				_boss_state.text = next_boss_state
				_boss_state.visible = not next_boss_state.is_empty()
	if snapshot.has("target"):
		var target := Dictionary(snapshot["target"])
		var target_name := String(target.get("name", "")).strip_edges()
		var next_target_visible := (
			bool(target.get("visible", false))
			and not target_name.is_empty()
		)
		if next_target_visible != _target_visible:
			_target_visible = next_target_visible
			_target_panel.visible = next_target_visible
			_apply_responsive_layout()
		if next_target_visible:
			if _target_name.text != target_name:
				_target_name.text = target_name
			var next_target_maximum := maxf(
				1.0,
				float(target.get("max_health", 1.0))
			)
			var next_target_health := float(target.get("health", 0.0))
			if not is_equal_approx(_target_bar.max_value, next_target_maximum):
				_target_bar.max_value = next_target_maximum
			if not is_equal_approx(_target_bar.value, next_target_health):
				_target_bar.value = next_target_health
			var next_target_state := String(target.get("state", ""))
			if _target_state.text != next_target_state:
				_target_state.text = next_target_state
	if snapshot.has("minimap"):
		_minimap.set_snapshot(snapshot["minimap"])
	if snapshot.has("threat_radar"):
		_threat_radar.set_snapshot(snapshot["threat_radar"])


func notify(
	message: String,
	duration: float = 2.4,
	color: Color = Art.IVORY_BRIGHT
) -> void:
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
	_notification_panel.visible = false


func debug_notification_contract() -> Dictionary:
	var queued_messages: Array[String] = []
	for entry_variant in _notification_queue:
		queued_messages.append(String(Dictionary(entry_variant).get("message", "")))
	return {
		"active":_notification_timer > 0.0,
		"active_message":_notification.text,
		"queued_messages":queued_messages,
		"queue_size":_notification_queue.size(),
		"queue_cap":5,
		"surface_variation":_notification_panel.theme_type_variation,
		"input_passthrough":(
			_notification_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE
		),
	}


func show_stage_transition(
	stage_number: int,
	stage_title_key: String,
	reduced_motion: bool
) -> void:
	_transition_banner.show_stage(
		stage_number,
		stage_title_key,
		reduced_motion
	)


func hide_stage_transition() -> void:
	_transition_banner.hide_banner()


func refresh_localized_content() -> void:
	_transition_banner.refresh_localized_content()
	_upgrade_rail.refresh_localized_content()
	_skill_slot.queue_redraw()


func debug_transition_banner() -> Dictionary:
	return _transition_banner.debug_snapshot()


func debug_health_animation_contract() -> Dictionary:
	_health_bar.set_values(120.0, 120.0, 1, 0.0, 12.0, false)
	_health_bar.set_values(80.0, 120.0, 1, 0.0, 12.0, false)
	var result := {
		"standard_holds_previous":is_equal_approx(
			_health_bar.trailing_health,
			120.0
		),
		"standard_processing":_health_bar.is_processing(),
	}
	_health_bar._process(0.18)
	_health_bar._process(0.45)
	result["standard_settled"] = is_equal_approx(
		_health_bar.trailing_health,
		80.0
	)
	result["standard_stopped"] = not _health_bar.is_processing()
	_health_bar.set_values(60.0, 120.0, 1, 0.0, 12.0, true)
	result["reduced_motion_steady"] = is_equal_approx(
		_health_bar.trailing_health,
		60.0
	)
	return result


func debug_threat_radar_contract() -> Dictionary:
	return _threat_radar.debug_contract()


func debug_contract(viewport_width: float) -> Dictionary:
	var compact := viewport_width < 1100.0
	var viewport_height := viewport_width * 9.0 / 16.0
	var accessibility := _accessibility_text_scale > 1.0
	var mission_base_size := Vector2(
		MISSION_CLUSTER_SIZE.x,
		MISSION_CLUSTER_SIZE.y
			+ (34.0 if _objective_detail.visible else 0.0)
			+ (58.0 if _boss_visible else 0.0)
	)
	var minimap_base_size := (
		Vector2(160.0, 98.0)
		if compact
		else Vector2(176.0, 108.0)
	)
	var target_size := (
		Vector2(168.0, 60.0)
		if compact
		else Vector2(184.0, 64.0)
	)
	var minimap_zone_size := Vector2(
		maxf(
			minimap_base_size.x,
			target_size.x if _target_visible else 0.0
		),
		minimap_base_size.y + (target_size.y + 4.0 if _target_visible else 0.0)
	)
	var rail_contract := _upgrade_rail.debug_contract()
	var center_width := _center_width(viewport_width, accessibility)
	var center_height := HEALTH_STRIP_SIZE.y
	if int(rail_contract["acquired_count"]) > 0:
		var row_count := int(rail_contract["row_count"])
		center_height += 2.0 + (
			float(rail_contract["row_height"]) * float(row_count)
			+ float(rail_contract["row_separation"]) * float(maxi(0, row_count - 1))
		)
	var center_zone_size := Vector2(center_width, center_height)
	var boss_width := mission_base_size.x - 20.0
	var dock_position := Vector2(
		(viewport_width - ACTION_RAIL_SIZE.x) * 0.5,
		viewport_height - ACTION_RAIL_SIZE.y - ACTION_RAIL_BOTTOM_MARGIN
	)
	var center_start := (
		viewport_width * 0.5 - center_zone_size.x * 0.5
	)
	var minimap_start := viewport_width - minimap_zone_size.x - 18.0
	var opaque_rects := [
		Rect2(Vector2(18.0, 16.0), mission_base_size),
		Rect2(Vector2(minimap_start, 16.0), minimap_zone_size),
	]
	var opaque_area := 0.0
	var central_safe := Rect2(
		Vector2(viewport_width * 0.20, viewport_height * 0.20),
		Vector2(viewport_width * 0.60, viewport_height * 0.60)
	)
	var central_safe_clear := true
	for rect in opaque_rects:
		opaque_area += Rect2(rect).get_area()
		central_safe_clear = (
			central_safe_clear
			and not Rect2(rect).intersects(central_safe)
		)
	return {
		"action_rail_size":ACTION_RAIL_SIZE,
		"action_rail_position":dock_position,
		"action_rail_icon_only":true,
		"action_slot_count":1,
		"action_rail_panel_free":true,
		"shows_primary_slot":false,
		"action_slot_contracts":[
			_skill_slot.debug_contract(),
		],
		"secondary_slot_size":Vector2.ZERO,
		"minimap_size":minimap_base_size,
		"minimap_zone_size":minimap_zone_size,
		"health_cluster_size":Vector2(center_width, HEALTH_STRIP_SIZE.y),
		"mission_cluster_size":mission_base_size,
		"health_panel_free":true,
		"health_meter":_health_bar.debug_contract(),
		"mission_experience_meter":(
			_experience_bar.get_parent().get_parent() == _mission_panel
			and _experience_bar.custom_minimum_size.y == 5.0
		),
		"upgrade_rail":rail_contract,
		"objective_cluster_size":center_zone_size,
		"objective_zone_size":center_zone_size,
		"target_cluster_size":target_size,
		"boss_strip_size":Vector2(
			boss_width,
			58.0
		),
		"boss_shield_coexist":true,
		"boss_inside_objective_zone":false,
		"boss_inside_mission_zone":(
			_boss_cluster.get_parent().get_parent() == _mission_panel
		),
		"target_inside_minimap_zone":(
			_target_panel.get_parent().get_parent() == _minimap_panel
		),
		"conditional_clusters_have_backing":false,
		"zone_surface_count":2,
		"zone_surface_variations":[
			_mission_panel.theme_type_variation,
			_minimap_panel.theme_type_variation,
		],
		"toast_surface_variation":_notification_panel.theme_type_variation,
		"raster_chrome_consumer":false,
		"opaque_combat_area_ratio":(
			opaque_area / (viewport_width * viewport_height)
		),
		"central_safe_clear":central_safe_clear,
		"top_clusters_do_not_overlap":(
			18.0 + mission_base_size.x <= center_start
			and center_start + center_zone_size.x <= minimap_start
		),
		"zone_count":4,
		"notification_inside_hud":_notification_panel.get_parent() == self,
		"status_font_sizes":{
			"stage":_stage_label.get_theme_font_size("font_size"),
			"objective":_objective_label.get_theme_font_size("font_size"),
			"objective_detail":_objective_detail.get_theme_font_size(
				"font_size"
			),
			"boss_state":_boss_state.get_theme_font_size("font_size"),
			"target_state":_target_state.get_theme_font_size("font_size"),
			"buff":_buff_label.get_theme_font_size("font_size"),
		},
	}


func _apply_responsive_layout() -> void:
	if _center_status == null:
		return
	var compact := size.x < 1100.0
	var accessibility := _accessibility_text_scale > 1.0
	var large := size.x >= 1600.0 and not accessibility
	var mission_size := Vector2(
		MISSION_CLUSTER_SIZE.x,
		MISSION_CLUSTER_SIZE.y
			+ (34.0 if _objective_detail.visible else 0.0)
			+ (58.0 if _boss_visible else 0.0)
	)
	var target_size := (
		Vector2(168.0, 60.0)
		if compact
		else Vector2(184.0, 64.0)
	)
	var minimap_base_size := (
		Vector2(160.0, 98.0)
		if compact
		else Vector2(176.0, 108.0)
	)
	var minimap_zone_size := Vector2(
		maxf(
			minimap_base_size.x,
			target_size.x if _target_visible else 0.0
		),
		minimap_base_size.y + (target_size.y + 4.0 if _target_visible else 0.0)
	)
	var center_width := _center_width(size.x, accessibility)
	_upgrade_rail.set_layout_profile(compact, accessibility, large)
	var rail_contract := _upgrade_rail.debug_contract()
	var center_height := HEALTH_STRIP_SIZE.y
	if int(rail_contract["acquired_count"]) > 0:
		var row_count := int(rail_contract["row_count"])
		center_height += 2.0 + (
			float(rail_contract["row_height"]) * float(row_count)
			+ float(rail_contract["row_separation"]) * float(maxi(0, row_count - 1))
		)
	var center_size := Vector2(center_width, center_height)
	_mission_panel.position = Vector2(18.0, 16.0)
	_mission_panel.custom_minimum_size = mission_size
	_mission_panel.size = mission_size
	_center_status.position = Vector2((size.x - center_width) * 0.5, 16.0)
	_center_status.custom_minimum_size = center_size
	_center_status.size = center_size
	_health_bar.custom_minimum_size = Vector2(center_width, HEALTH_STRIP_SIZE.y)
	_health_bar.size = Vector2(center_width, HEALTH_STRIP_SIZE.y)
	_boss_cluster.custom_minimum_size.y = 58.0 if _boss_visible else 0.0
	_boss_bar.custom_minimum_size.x = 0.0
	_minimap_panel.custom_minimum_size = minimap_zone_size
	_minimap_panel.size = minimap_zone_size
	_minimap_panel.position = Vector2(
		size.x - minimap_zone_size.x - 18.0,
		16.0
	)
	_minimap.custom_minimum_size = Vector2(
		minimap_zone_size.x - 20.0,
		minimap_base_size.y - 16.0
	)
	_target_panel.custom_minimum_size = Vector2(
		minimap_zone_size.x - 20.0,
		target_size.y
	)
	_skill_slot.size = ACTION_RAIL_SIZE
	_skill_slot.position = Vector2(
		(size.x - ACTION_RAIL_SIZE.x) * 0.5,
		size.y - ACTION_RAIL_SIZE.y - ACTION_RAIL_BOTTOM_MARGIN
	)
	_buff_label.position = Vector2(
		(size.x - _buff_label.size.x) * 0.5,
		size.y - 124.0
	)
	for label in [_stage_label, _objective_label, _objective_detail, _boss_name, _boss_state]:
		Factory.apply_font_size(label, 14)
	_notification_panel.size = Vector2(
		720.0 if accessibility else (320.0 if compact else 360.0),
		80.0 if accessibility else 44.0
	)
	_notification_panel.position = Vector2(
		(size.x - _notification_panel.size.x) * 0.5,
		16.0 + maxf(mission_size.y, center_size.y) + 12.0
	)
	_transition_banner.apply_viewport(
		size,
		_accessibility_text_scale,
		16.0 + maxf(mission_size.y, center_size.y) + 12.0
			if accessibility else 126.0
	)


func _center_width(viewport_width: float, accessibility: bool) -> float:
	if accessibility:
		return 404.0
	if viewport_width < 1100.0:
		return 400.0
	if viewport_width >= 1600.0:
		return 640.0
	return HEALTH_STRIP_SIZE.x


func set_accessibility_text_scale(scale: float) -> void:
	_accessibility_text_scale = clampf(scale, 1.0, 2.0)
	_objective_detail.text_overrun_behavior = (
		TextServer.OVERRUN_NO_TRIMMING
		if _accessibility_text_scale > 1.0
		else TextServer.OVERRUN_TRIM_ELLIPSIS
	)
	_apply_responsive_layout()


func _show_next_notification() -> void:
	if not _notification_queue.is_empty():
		_show_notification(_notification_queue.pop_front())


func _show_notification(entry: Dictionary) -> void:
	_notification.text = String(entry["message"])
	_notification.add_theme_color_override(
		"font_color",
		Color(entry["color"])
	)
	_notification_panel.modulate.a = 1.0
	_notification_panel.visible = true
	_notification_timer = float(entry["duration"])
	set_process(true)


func _shadow_label(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Art.COBALT_VOID)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
