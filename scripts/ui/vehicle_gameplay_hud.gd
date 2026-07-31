class_name VehicleGameplayHud
extends Control

## Owns the four-zone gameplay HUD and transient HUD-only presentation.
## It consumes immutable snapshots and never queries or mutates gameplay state.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const ThreatRadar = preload("res://scripts/ui/vehicle_threat_radar.gd")
const StatusOrbit = preload("res://scripts/ui/vehicle_status_orbit.gd")
const StageTransitionBanner = preload("res://scripts/ui/vehicle_stage_transition_banner.gd")
const RetainedMinimapMesh = preload("res://scripts/ui/vehicle_retained_minimap_mesh.gd")
const UiGlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const UiAssets = preload("res://scripts/ui/vehicle_ui_asset_provider.gd")

const HEALTH_CLUSTER_SIZE := Vector2(216.0, 74.0)
const ACTION_RAIL_SIZE := Vector2(148.0, 44.0)
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
		custom_minimum_size = Vector2(180.0, 46.0)
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
		draw_string(
			font,
			Vector2(0.0, 16.0),
			"LV.%d" % run_level,
			HORIZONTAL_ALIGNMENT_LEFT,
			58.0,
			16,
			Art.MINT_SOFT
		)
		draw_string(
			font,
			Vector2(60.0, 16.0),
			"%d / %d" % [roundi(health), roundi(maximum)],
			HORIZONTAL_ALIGNMENT_RIGHT,
			size.x - 60.0,
			16,
			Art.IVORY_BRIGHT
		)
		var hull_rect := Rect2(0.0, 21.0, size.x, 13.0)
		draw_texture_rect(
			UiAssets.texture(&"meter", &"background"),
			hull_rect,
			false
		)
		_draw_meter_fill(
			UiAssets.texture(&"meter", &"health"),
			hull_rect,
			clampf(trailing_health / maximum, 0.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.48)
		)
		_draw_meter_fill(
			UiAssets.texture(&"meter", &"health"),
			hull_rect,
			clampf(health / maximum, 0.0, 1.0),
			Color.WHITE
		)
		var xp_rect := Rect2(0.0, 39.0, size.x, 7.0)
		draw_texture_rect(
			UiAssets.texture(&"meter", &"background"),
			xp_rect,
			false
		)
		_draw_meter_fill(
			UiAssets.texture(&"meter", &"resource"),
			xp_rect,
			clampf(experience / experience_required, 0.0, 1.0),
			Color.WHITE
		)

	func _draw_meter_fill(
		texture: Texture2D,
		rect: Rect2,
		ratio: float,
		modulate: Color
	) -> void:
		if texture == null or ratio <= 0.0:
			return
		var clamped := clampf(ratio, 0.0, 1.0)
		var texture_size := Vector2(texture.get_size())
		draw_texture_rect_region(
			texture,
			Rect2(rect.position, Vector2(rect.size.x * clamped, rect.size.y)),
			Rect2(
				Vector2.ZERO,
				Vector2(texture_size.x * clamped, texture_size.y)
			),
			modulate
		)


class ActionRailSlot:
	extends Control

	var action_id: StringName = &"seeker"
	var accent := Art.PLAYER_REWARD
	var cooldown_ratio := 0.0
	var available := true

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(44.0, 44.0)

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
		var radius := 19.0
		var state_texture := UiAssets.texture(
			&"small_state",
			&"pip_available" if available else &"disabled"
		)
		if state_texture != null:
			draw_texture_rect(
				state_texture,
				Rect2(center - Vector2.ONE * 21.0, Vector2.ONE * 42.0),
				false,
				Color.WHITE
			)
		var icon := SemanticAssets.texture(
			StringName("hud/action_%s" % action_id)
		)
		if icon != null:
			var icon_size := Vector2.ONE * 28.0
			draw_texture_rect(
				icon,
				Rect2(center - icon_size * 0.5, icon_size),
				false,
				Color(1.0, 1.0, 1.0, 1.0 if available else 0.42)
			)
		if not available and cooldown_ratio < 0.9999:
			draw_arc(
				center,
				radius - 3.0,
				-PI * 0.5,
				-PI * 0.5 + TAU * (1.0 - cooldown_ratio),
				24,
				Color(accent, 0.82),
				2.0,
				true
			)

	func debug_contract() -> Dictionary:
		var descriptor := UiGlyphCatalog.action_descriptor(action_id)
		return {
			"available":available,
			"image_backed":true,
			"interior_filled":false,
			"has_text":false,
			"draw_batches":2 if not available else 1,
			"minimum_size":custom_minimum_size,
			"glyph_id":action_id,
			"shared_glyph_recipe":not descriptor.is_empty(),
			"semantic_texture":SemanticAssets.has_asset(
				StringName("hud/action_%s" % action_id)
			),
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
		_draw_semantic_markers(world_size)

	func _draw_semantic_markers(world_size: Vector2) -> void:
		if not bool(snapshot.get("semantic_markers", false)):
			return
		_draw_marker_texture(
			&"hud/minimap_marker_player",
			_map_point(
				Vector2(snapshot.get("player", Vector2.ZERO)),
				world_size
			),
			14.0
		)
		for marker_variant in Array(snapshot.get("markers", [])):
			var marker := Dictionary(marker_variant)
			if not bool(marker.get("discovered", false)):
				continue
			var kind := StringName(marker.get("kind", &""))
			var asset_id := &""
			match kind:
				&"boss":
					asset_id = &"hud/minimap_marker_boss"
				&"elite":
					asset_id = &"hud/minimap_marker_elite"
				&"stationary":
					asset_id = &"hud/minimap_marker_hostile"
				&"objective":
					asset_id = (
						&"hud/minimap_marker_objective_locked"
						if bool(marker.get("locked", false))
						else &"hud/minimap_marker_objective_active"
					)
			if asset_id == &"":
				continue
			_draw_marker_texture(
				asset_id,
				_map_point(Vector2(marker["position"]), world_size),
				16.0 if kind in [&"boss", &"objective"] else 13.0
			)
		var cols := maxi(1, int(snapshot.get("cols", 13)))
		var rows := maxi(1, int(snapshot.get("rows", 6)))
		var cell_size := Vector2(size.x / float(cols), size.y / float(rows))
		for cluster_variant in Array(snapshot.get("enemy_clusters", [])):
			var cluster := Dictionary(cluster_variant)
			var point := (
				Vector2(Vector2i(cluster["cell"])) + Vector2(0.5, 0.5)
			) * cell_size
			_draw_marker_texture(
				&"hud/minimap_marker_hostile",
				point,
				11.0 if int(cluster.get("count", 1)) <= 4 else 14.0
			)

	func _map_point(world_point: Vector2, world_size: Vector2) -> Vector2:
		return Vector2(
			world_point.x / maxf(1.0, world_size.x) * size.x,
			world_point.y / maxf(1.0, world_size.y) * size.y
		)

	func _draw_marker_texture(
		asset_id: StringName,
		center: Vector2,
		extent: float
	) -> void:
		var texture := SemanticAssets.texture(asset_id)
		if texture == null:
			return
		var marker_size := Vector2.ONE * extent
		draw_texture_rect(
			texture,
			Rect2(center - marker_size * 0.5, marker_size),
			false,
			Color.WHITE
		)

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
var _last_objective_detail := ""
var _last_buff_text := ""
var _boss_visible := false
var _target_visible := false
var _boss_cluster: PanelContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_state: Label
var _target_name: Label
var _target_bar: ProgressBar
var _target_state: Label
var _dash_slot: ActionRailSlot
var _passive_slot: ActionRailSlot
var _skill_slot: ActionRailSlot
var _buff_label: Label
var _minimap: StageMinimap
var _notification_panel: PanelContainer
var _notification: Label
var _notification_timer := 0.0
var _notification_queue: Array[Dictionary] = []
var _transition_banner: VehicleStageTransitionBanner
var _threat_radar: VehicleThreatRadar
var _status_orbit: VehicleStatusOrbit


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
		_objective_detail.visible = _objective_detail_timer > 0.0
	if _notification_timer <= 0.0 and _objective_detail_timer <= 0.0:
		set_process(false)


func _build() -> void:
	_threat_radar = ThreatRadar.new()
	_threat_radar.name = "ThreatRadar"
	add_child(_threat_radar)
	_status_orbit = StatusOrbit.new()
	_status_orbit.name = "StatusOrbit"
	add_child(_status_orbit)

	_health_panel = Factory.flat_panel()
	_health_panel.name = "HealthPanel"
	_health_panel.theme_type_variation = &"HudHealthResource"
	_health_panel.position = Vector2(18.0, 16.0)
	_health_panel.size = HEALTH_CLUSTER_SIZE
	add_child(_health_panel)
	_health_bar = HealthPips.new()
	_health_panel.add_child(_health_bar)

	_objective_panel = Factory.flat_panel()
	_objective_panel.name = "ObjectivePanel"
	_objective_panel.theme_type_variation = &"HudObjectiveBoss"
	_objective_panel.custom_minimum_size = Vector2(360.0, 44.0)
	_objective_panel.size = Vector2(360.0, 44.0)
	add_child(_objective_panel)
	var objective_box := VBoxContainer.new()
	objective_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_objective_panel.add_child(objective_box)
	_objective_label = Factory.label(
		"OBJECTIVE_CALIBRATE",
		15,
		Art.IVORY_BRIGHT
	)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_box.add_child(_objective_label)
	_objective_detail = Factory.label("DEPLOY_CONTROLS", 14, Art.TEXT_MUTED)
	_objective_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_box.add_child(_objective_detail)

	_minimap_panel = Factory.flat_panel()
	_minimap_panel.name = "MinimapPanel"
	_minimap_panel.theme_type_variation = &"HudMinimapTarget"
	_minimap_panel.size = Vector2(176.0, 108.0)
	add_child(_minimap_panel)
	_minimap = StageMinimap.new()
	_minimap.custom_minimum_size = Vector2(168.0, 100.0)
	_minimap_panel.add_child(_minimap)

	_boss_cluster = PanelContainer.new()
	_boss_cluster.name = "BossCluster"
	_boss_cluster.theme_type_variation = &"HudObjectiveBoss"
	_boss_cluster.size = Vector2(520.0, 58.0)
	add_child(_boss_cluster)
	var boss_box := VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 1)
	_boss_cluster.add_child(boss_box)
	_boss_name = Factory.label(
		"ENEMY_FOUNDRY_COLOSSUS",
		14,
		Art.IVORY_BRIGHT
	)
	_shadow_label(_boss_name)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.theme_type_variation = &"BossMeter"
	_boss_bar.show_percentage = false
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	_boss_bar.custom_minimum_size = Vector2(520.0, 10.0)
	boss_box.add_child(_boss_bar)
	_boss_state = Factory.label(
		"PATTERN_READING_ARENA",
		14,
		Art.TEXT_MUTED
	)
	_shadow_label(_boss_state)
	_boss_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_state.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	boss_box.add_child(_boss_state)
	_boss_cluster.visible = false

	_target_panel = Factory.flat_panel()
	_target_panel.name = "TargetPanel"
	_target_panel.theme_type_variation = &"HudMinimapTarget"
	_target_panel.size = Vector2(184.0, 64.0)
	add_child(_target_panel)
	var target_cluster := VBoxContainer.new()
	_target_panel.add_child(target_cluster)
	_target_name = Factory.label("—", 14, Art.IVORY_BRIGHT)
	_target_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_cluster.add_child(_target_name)
	_target_bar = ProgressBar.new()
	_target_bar.show_percentage = false
	_target_bar.max_value = 1.0
	_target_bar.value = 1.0
	_target_bar.theme_type_variation = &"HealthMeter"
	_target_bar.custom_minimum_size = Vector2(160.0, 9.0)
	target_cluster.add_child(_target_bar)
	_target_state = Factory.label("", 14, Art.TEXT_MUTED)
	_target_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_cluster.add_child(_target_state)
	_target_panel.visible = false

	_dock_panel = PanelContainer.new()
	_dock_panel.name = "ActionRail"
	_dock_panel.theme_type_variation = &"HudActionRail"
	_dock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dock_panel.size = ACTION_RAIL_SIZE
	add_child(_dock_panel)
	var dock := HBoxContainer.new()
	dock.add_theme_constant_override("separation", 8)
	dock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dock_panel.add_child(dock)
	_passive_slot = _action_slot(dock, &"seeker", Art.SUPPORT)
	_dash_slot = _action_slot(dock, &"dash", Art.SYSTEM)
	_skill_slot = _action_slot(dock, &"emp", Art.BOSS_COMMAND)

	_buff_label = Factory.label("", 14, Art.TEXT_PRIMARY)
	_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buff_label.size = Vector2(600.0, 28.0)
	_shadow_label(_buff_label)
	add_child(_buff_label)
	_buff_label.visible = false

	_notification_panel = PanelContainer.new()
	_notification_panel.name = "NotificationPanel"
	_notification_panel.theme_type_variation = &"HudToast"
	_notification_panel.size = Vector2(360.0, 36.0)
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
			set_process(true)
		var next_detail := String(snapshot.get("objective_detail", ""))
		if next_detail != _last_objective_detail:
			_last_objective_detail = next_detail
			_objective_detail.text = next_detail
	if snapshot.has("dash_available"):
		_dash_slot.set_state(
			bool(snapshot["dash_available"]),
			float(snapshot.get("dash_ratio", 0.0))
		)
		_passive_slot.set_state(
			bool(snapshot.get("passive_available", false)),
			float(snapshot.get("passive_ratio", 0.0))
		)
		_skill_slot.set_state(
			bool(snapshot.get("skill_available", false)),
			float(snapshot.get("skill_ratio", 0.0))
		)
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
			_objective_panel.visible = true
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
	if snapshot.has("status_orbit"):
		_status_orbit.set_snapshot(snapshot["status_orbit"])


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
	_passive_slot.queue_redraw()
	_dash_slot.queue_redraw()
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


func debug_status_orbit_contract() -> Dictionary:
	return _status_orbit.debug_contract()


func debug_contract(viewport_width: float) -> Dictionary:
	var compact := viewport_width < 1100.0
	var viewport_height := viewport_width * 9.0 / 16.0
	var objective_size := Vector2(
		300.0 if compact else 360.0,
		40.0 if compact else 44.0
	)
	var minimap_size := (
		Vector2(160.0, 98.0)
		if compact
		else Vector2(176.0, 108.0)
	)
	var target_size := (
		Vector2(168.0, 60.0)
		if compact
		else Vector2(184.0, 64.0)
	)
	var dock_position := Vector2(
		(viewport_width - ACTION_RAIL_SIZE.x) * 0.5,
		viewport_height - ACTION_RAIL_SIZE.y - ACTION_RAIL_BOTTOM_MARGIN
	)
	var objective_start := viewport_width * 0.5 - objective_size.x * 0.5
	var minimap_start := viewport_width - minimap_size.x - 18.0
	var opaque_rects := [
		Rect2(Vector2(18.0, 16.0), HEALTH_CLUSTER_SIZE),
		Rect2(Vector2(objective_start, 16.0), objective_size),
		Rect2(Vector2(minimap_start, 16.0), minimap_size),
		Rect2(
			Vector2(
				viewport_width - target_size.x - 18.0,
				viewport_height - target_size.y - 82.0
			),
			target_size
		),
		Rect2(dock_position, ACTION_RAIL_SIZE),
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
		"action_slot_count":3,
		"shows_primary_slot":false,
		"action_slot_contracts":[
			_passive_slot.debug_contract(),
			_dash_slot.debug_contract(),
			_skill_slot.debug_contract(),
		],
		"secondary_slot_size":_dash_slot.custom_minimum_size,
		"minimap_size":minimap_size,
		"health_cluster_size":HEALTH_CLUSTER_SIZE,
		"objective_cluster_size":objective_size,
		"target_cluster_size":target_size,
		"boss_strip_size":Vector2(
			minf(520.0, viewport_width - 424.0),
			58.0
		),
		"boss_objective_coexist":_objective_panel.visible,
		"opaque_combat_area_ratio":(
			opaque_area / (viewport_width * viewport_height)
		),
		"central_safe_clear":central_safe_clear,
		"top_clusters_do_not_overlap":(
			18.0 + HEALTH_CLUSTER_SIZE.x <= objective_start
			and objective_start + objective_size.x <= minimap_start
		),
		"zone_count":4,
		"notification_inside_hud":_notification_panel.get_parent() == self,
		"status_font_sizes":{
			"objective_detail":_objective_detail.get_theme_font_size(
				"font_size"
			),
			"boss_state":_boss_state.get_theme_font_size("font_size"),
			"target_state":_target_state.get_theme_font_size("font_size"),
			"buff":_buff_label.get_theme_font_size("font_size"),
		},
	}


func _apply_responsive_layout() -> void:
	if _objective_panel == null:
		return
	var compact := size.x < 1100.0
	var objective_size := Vector2(
		300.0 if compact else 360.0,
		40.0 if compact else 44.0
	)
	_health_panel.position = Vector2(18.0, 16.0)
	_health_panel.size = HEALTH_CLUSTER_SIZE
	_objective_panel.position = Vector2(
		(size.x - objective_size.x) * 0.5,
		76.0 if _boss_cluster.visible else 16.0
	)
	_objective_panel.custom_minimum_size = objective_size
	_objective_panel.size = objective_size
	var minimap_size := (
		Vector2(160.0, 98.0)
		if compact
		else Vector2(176.0, 108.0)
	)
	_minimap_panel.size = minimap_size
	_minimap_panel.position = Vector2(
		size.x - minimap_size.x - 18.0,
		16.0
	)
	_minimap.custom_minimum_size = minimap_size - Vector2(8.0, 8.0)
	var boss_width := minf(
		520.0,
		size.x - HEALTH_CLUSTER_SIZE.x - minimap_size.x - 72.0
	)
	_boss_cluster.position = Vector2(
		(size.x - boss_width) * 0.5,
		16.0
	)
	_boss_cluster.size.x = boss_width
	_boss_bar.custom_minimum_size.x = boss_width
	var target_size := (
		Vector2(168.0, 60.0)
		if compact
		else Vector2(184.0, 64.0)
	)
	_target_panel.size = target_size
	_target_panel.position = Vector2(
		size.x - target_size.x - 18.0,
		size.y - target_size.y - 82.0
	)
	_dock_panel.size = ACTION_RAIL_SIZE
	_dock_panel.position = Vector2(
		(size.x - ACTION_RAIL_SIZE.x) * 0.5,
		size.y - ACTION_RAIL_SIZE.y - ACTION_RAIL_BOTTOM_MARGIN
	)
	_buff_label.position = Vector2(
		(size.x - _buff_label.size.x) * 0.5,
		size.y - 124.0
	)
	_objective_detail.add_theme_font_size_override(
		"font_size",
		14
	)
	_notification_panel.size.x = 320.0 if compact else 360.0
	_notification_panel.position = Vector2(
		(size.x - _notification_panel.size.x) * 0.5,
		156.0 if _boss_cluster.visible else 72.0
	)
	_transition_banner.apply_viewport(size)


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


func _action_slot(
	parent: HBoxContainer,
	action_id: StringName,
	color: Color
) -> ActionRailSlot:
	var slot := ActionRailSlot.new()
	slot.configure(action_id, color)
	parent.add_child(slot)
	return slot


func _shadow_label(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Art.COBALT_VOID)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
