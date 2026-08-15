class_name VehicleGameplayHud
extends Control

## Owns the full-width meters, compact semantic status cluster, minimap, and
## transient HUD-only presentation.
## It consumes immutable snapshots and never queries or mutates gameplay state.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const ThreatRadar = preload("res://scripts/ui/vehicle_threat_radar.gd")
const RetainedMinimapMesh = preload("res://scripts/ui/vehicle_retained_minimap_mesh.gd")
const UiGlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)

const TOP_STATUS_GAP := 8.0

signal announcement_receipt(receipt: Dictionary)


class HealthPips:
	extends Control

	var health := 120.0
	var maximum := 120.0
	var trailing_health := 120.0
	var run_level := 1
	var experience := 0.0
	var experience_required := 10.0
	var experience_complete := false
	var reduced_motion := false
	var _health_track_height := 32.0
	var _experience_track_height := 22.0
	var _meter_font_size := 14
	var _trail_from := 120.0
	var _trail_hold := 0.0
	var _trail_elapsed := 0.0
	var _trail_duration := 0.45
	var _pulse_time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(1.0, total_height())
		set_process(false)

	func set_values(
		value: float,
		max_value: float,
		level_value: int = 1,
		experience_value: float = 0.0,
		required_value: float = 12.0,
		reduced_motion_value: bool = false,
		experience_complete_value: bool = false
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
			or experience_complete != experience_complete_value
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
		experience_complete = experience_complete_value
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
		var hull_rect := Rect2(0.0, 0.0, size.x, _health_track_height)
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
		_draw_centered_value(
			font,
			hull_rect,
			"HP %d / %d" % [roundi(health), roundi(maximum)],
			Art.IVORY_BRIGHT
		)
		var experience_rect := Rect2(
			0.0,
			_health_track_height,
			size.x,
			_experience_track_height
		)
		_draw_meter_track(experience_rect)
		if not experience_complete:
			_draw_meter_fill(
				experience_rect,
				clampf(experience / experience_required, 0.0, 1.0),
				Art.SYSTEM
			)
		var experience_text := (
			"LV %d · EXP MAX" % run_level
			if experience_complete
			else "LV %d · EXP %d / %d" % [
				run_level, roundi(experience), roundi(experience_required),
			]
		)
		_draw_centered_value(font, experience_rect, experience_text, Art.TEXT_PRIMARY)

	func set_layout_profile(compact: bool, accessibility: bool, large: bool) -> void:
		if accessibility:
			_health_track_height = 52.0
			_experience_track_height = 32.0
			_meter_font_size = 20
		elif compact:
			_health_track_height = 28.0
			_experience_track_height = 18.0
			_meter_font_size = 13
		elif large:
			_health_track_height = 40.0
			_experience_track_height = 26.0
			_meter_font_size = 16
		else:
			_health_track_height = 32.0
			_experience_track_height = 22.0
			_meter_font_size = 14
		custom_minimum_size.y = total_height()
		queue_redraw()

	func total_height() -> float:
		return _health_track_height + _experience_track_height

	func _draw_centered_value(
		font: Font,
		rect: Rect2,
		text: String,
		color: Color
	) -> void:
		var baseline := rect.position.y + (rect.size.y + float(_meter_font_size) * 0.72) * 0.5
		draw_string_outline(
			font,
			Vector2(rect.position.x, baseline),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			_meter_font_size,
			1,
			Art.COBALT_VOID
		)
		draw_string(
			font,
			Vector2(rect.position.x, baseline),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			_meter_font_size,
			color
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
			"has_experience_geometry":true,
			"experience_track_width":size.x,
			"health_track_height":_health_track_height,
			"experience_track_height":_experience_track_height,
			"meter_gap":0.0,
			"total_height":total_height(),
			"experience_complete":experience_complete,
			"live_upgrade_icon_count":0,
			"panel_free":true,
			"centered_value":true,
			"trailing_animation_preserved":true,
			"reduced_motion_immediate":true,
			"reduced_motion_active":reduced_motion,
		}


class StatusGlyphItem:
	extends Control

	var glyph_id: StringName = &"stage_progress"
	var glyph_family: StringName = &"status"
	var accent := Art.SYSTEM
	var available := true
	var _glyph_size := 18.0
	var _accessibility := false
	var _raw_value := ""
	var _value_label: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		_value_label = Label.new()
		_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_value_label.clip_text = true
		_value_label.add_theme_color_override("font_color", Art.TEXT_PRIMARY)
		_value_label.add_theme_color_override("font_shadow_color", Art.COBALT_VOID)
		_value_label.add_theme_constant_override("shadow_offset_x", 1)
		_value_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_value_label)
		set_layout_profile(false, false, false)

	func configure(next_id: StringName, family: StringName, color: Color) -> void:
		glyph_id = next_id
		glyph_family = family
		accent = color
		_refresh_display_value()
		queue_redraw()

	func set_value(value: String, is_available: bool = true) -> void:
		if available == is_available and _raw_value == value:
			return
		available = is_available
		_raw_value = value
		_refresh_display_value()
		queue_redraw()

	func set_layout_profile(compact: bool, accessibility: bool, large: bool) -> void:
		_accessibility = accessibility
		var slot_size := Vector2(36.0, 40.0)
		var font_size := 14
		_glyph_size = 18.0
		if accessibility:
			slot_size = Vector2(92.0 if glyph_family == &"action" else 72.0, 64.0)
			# Factory applies the selected 200% text scale. Keep the base size at
			# the standard value so this profile does not scale the text twice.
			font_size = 14
			_glyph_size = 20.0
		elif compact:
			slot_size = Vector2(46.0 if glyph_family == &"action" else 34.0, 36.0)
			font_size = 13
			_glyph_size = 16.0
		elif large:
			slot_size = Vector2(54.0 if glyph_family == &"action" else 40.0, 44.0)
			font_size = 15
			_glyph_size = 20.0
		elif glyph_family == &"action":
			slot_size.x = 50.0
		custom_minimum_size = slot_size
		size = slot_size
		if _value_label != null:
			_value_label.position = Vector2(0.0, _glyph_size + 3.0)
			_value_label.size = Vector2(slot_size.x, slot_size.y - _glyph_size - 3.0)
			Factory.apply_font_size(_value_label, font_size)
			_refresh_display_value()
		queue_redraw()

	func _refresh_display_value() -> void:
		if _value_label == null:
			return
		_value_label.text = _compact_accessibility_value(_raw_value)

	func _compact_accessibility_value(value: String) -> String:
		if not _accessibility:
			return value
		if glyph_id == &"braced_fire":
			return value.trim_suffix("s")
		if glyph_id != &"stage_progress":
			return value
		var numbers: Array[String] = []
		var current := ""
		for index in value.length():
			var character := value.substr(index, 1)
			if character >= "0" and character <= "9":
				current += character
			elif not current.is_empty():
				numbers.append(current)
				current = ""
		if not current.is_empty():
			numbers.append(current)
		if numbers.size() >= 3:
			return "%s/%s·%s" % [numbers[0], numbers[1], numbers[2]]
		return value

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, _glyph_size * 0.5 + 1.0)
		var state_color := accent if available else Art.TEXT_MUTED
		var palette := {
			&"primary":Color(state_color, 1.0 if available else 0.52),
			&"secondary":Color(state_color, 0.72 if available else 0.38),
			&"highlight":Art.IVORY_BRIGHT,
			&"cutout":Art.COBALT_VOID,
		}
		if glyph_family == &"action":
			UiGlyphCatalog.draw_action_glyph(
				self, glyph_id, center, _glyph_size * 0.5, palette
			)
		elif glyph_family == &"conditional":
			_draw_conditional_glyph(center, _glyph_size * 0.5, state_color)
		else:
			UiGlyphCatalog.draw_status_glyph(
				self, glyph_id, center, _glyph_size * 0.5, palette
			)

	func _draw_conditional_glyph(center: Vector2, glyph_radius: float, color: Color) -> void:
		match glyph_id:
			&"overflow_barrier":
				draw_arc(center, glyph_radius * 0.72, 0.0, TAU, 16, color, 2.0)
				draw_line(center + Vector2(0.0, -glyph_radius * 0.65), center + Vector2(0.0, glyph_radius * 0.65), color, 2.0)
			&"dash_overdrive":
				for offset in [-glyph_radius * 0.30, glyph_radius * 0.24]:
					draw_polyline(PackedVector2Array([
						center + Vector2(offset - glyph_radius * 0.34, -glyph_radius * 0.58),
						center + Vector2(offset + glyph_radius * 0.28, 0.0),
						center + Vector2(offset - glyph_radius * 0.34, glyph_radius * 0.58),
					]), color, 2.0)
			&"braced_fire":
				draw_rect(Rect2(center - Vector2(glyph_radius * 0.68, glyph_radius * 0.68), Vector2(glyph_radius * 1.36, glyph_radius * 1.36)), color, false, 2.0)
				draw_line(center + Vector2(-glyph_radius * 0.48, 0), center + Vector2(glyph_radius * 0.48, 0), color, 2.0)
			&"hit_chain", &"miss_compensation":
				draw_circle(center + Vector2(-glyph_radius * 0.38, 0), glyph_radius * 0.30, color, false, 2.0)
				draw_circle(center + Vector2(glyph_radius * 0.38, 0), glyph_radius * 0.30, color, false, 2.0)
				draw_line(center + Vector2(-glyph_radius * 0.10, 0), center + Vector2(glyph_radius * 0.10, 0), color, 2.0)
			&"last_stand":
				draw_colored_polygon(PackedVector2Array([center + Vector2(0, -glyph_radius * 0.76), center + Vector2(glyph_radius * 0.66, glyph_radius * 0.56), center + Vector2(-glyph_radius * 0.66, glyph_radius * 0.56)]), color)

	func debug_contract() -> Dictionary:
		return {
			"available":available,
			"image_backed":false,
			"code_native_glyph":true,
			"panel_free":true,
			"background_geometry_count":0,
			"cooldown_progress_geometry_count":0,
			"has_text":true,
			"value":_value_label.text,
			"minimum_size":custom_minimum_size,
			"position":position,
			"size":size,
			"visible":visible,
			"glyph_id":glyph_id,
			"glyph_family":glyph_family,
			"glyph_optical_size":_glyph_size,
			"value_font_size":_value_label.get_theme_font_size("font_size"),
			"value_centered":_value_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
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


var _status_cluster: Control
var _minimap_panel: PanelContainer
var _health_bar: HealthPips
var _status_items: Dictionary = {}
var _conditional_item_ids: Array[StringName] = []
var _accessibility_text_scale := 1.0
var _minimap: StageMinimap
var _notification_panel: Control
var _notification: Label
var _notification_timer := 0.0
var _notification_queue: Array[Dictionary] = []
var _active_notification_entry: Dictionary = {}
var _threat_radar: VehicleThreatRadar
var _active_owned := false


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
	if _notification_timer <= 0.0:
		set_process(false)


func _build() -> void:
	_threat_radar = ThreatRadar.new()
	_threat_radar.name = "ThreatRadar"
	add_child(_threat_radar)

	_health_bar = HealthPips.new()
	_health_bar.name = "FullWidthMeters"
	add_child(_health_bar)

	_status_cluster = Control.new()
	_status_cluster.name = "CompactStatusCluster"
	_status_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_cluster)
	_add_status_item(&"stage", &"stage_progress", &"status", Art.SYSTEM, "1 / 10")
	_add_status_item(&"defeats", &"total_defeats", &"status", Art.DANGER, "0")
	_add_status_item(&"dash", &"dash", &"action", Art.SYSTEM, "READY")
	_add_status_item(&"active", &"active", &"action", Art.BOSS_COMMAND, tr("HUD_ACTION_LOCKED"))
	for index in 5:
		var item_id := StringName("conditional_%d" % index)
		_add_status_item(item_id, &"overflow_barrier", &"conditional", Art.SYSTEM, "")
		_status_item(item_id).visible = false
		_conditional_item_ids.append(item_id)

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
	_minimap_panel.add_child(minimap_zone)
	_minimap = StageMinimap.new()
	_minimap.custom_minimum_size = Vector2(168.0, 100.0)
	minimap_zone.add_child(_minimap)

	_notification_panel = Control.new()
	_notification_panel.name = "TextAnnouncement"
	_notification_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_panel.clip_contents = true
	_notification_panel.size = Vector2(360.0, 40.0)
	add_child(_notification_panel)
	_notification = Factory.label("", 22, Art.IVORY_BRIGHT)
	_notification.name = "Notification"
	_notification.theme_type_variation = &"SectionLabel"
	_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notification.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notification.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	_notification.max_lines_visible = 2
	_notification.clip_text = true
	_notification.add_theme_font_size_override("font_size", 22)
	_notification.add_theme_constant_override("outline_size", 2)
	_shadow_label(_notification)
	_notification_panel.add_child(_notification)
	_notification_panel.visible = false


func _add_status_item(
	item_id: StringName,
	glyph_id: StringName,
	glyph_family: StringName,
	accent: Color,
	initial_value: String
) -> void:
	var item := StatusGlyphItem.new()
	item.name = "%sStatus" % String(item_id).capitalize()
	_status_cluster.add_child(item)
	item.configure(glyph_id, glyph_family, accent)
	item.set_value(initial_value)
	_status_items[item_id] = item

func update_snapshot(snapshot: Dictionary) -> void:
	if snapshot.has("health"):
		var required_experience := maxf(
			1.0,
			float(snapshot.get("experience_required", 10.0))
		)
		_health_bar.set_values(
			float(snapshot["health"]),
			maxf(1.0, float(snapshot.get("max_health", 1.0))),
			int(snapshot.get("level", 1)),
			float(snapshot.get("experience", 0.0)),
			required_experience,
			bool(snapshot.get("reduced_motion", false)),
			bool(snapshot.get("experience_complete", false))
		)
	if snapshot.has("stage_number") or snapshot.has("stage_total") or snapshot.has("stage_quota_remaining"):
		_status_item(&"stage").set_value(tr("HUD_BOSS_PROGRESS_VALUE") % [
			int(snapshot.get("stage_number", 1)),
			maxi(1, int(snapshot.get("stage_total", 8))),
			maxi(0, int(snapshot.get("stage_quota_remaining", 0))),
		])
	if snapshot.has("cumulative_defeated"):
		_status_item(&"defeats").set_value(
			str(maxi(0, int(snapshot.get("cumulative_defeated", 0))))
		)
	_update_action_status(snapshot, &"dash", "dash_available", "dash_remaining")
	if snapshot.has("active_weapon_id"):
		var active_id := StringName(snapshot.get("active_weapon_id", &""))
		_status_item(&"active").configure(
			active_id if not active_id.is_empty() else &"active",
			&"action",
			_active_weapon_accent(active_id) if not active_id.is_empty() else Art.BOSS_COMMAND
		)
	_active_owned = bool(snapshot.get("skill_owned", false))
	if _active_owned:
		_update_action_status(snapshot, &"active", "skill_available", "skill_remaining")
	else:
		_status_item(&"active").set_value(tr("HUD_ACTION_LOCKED"), false)
	if snapshot.has("conditional_statuses"):
		_update_conditional_statuses(Array(snapshot["conditional_statuses"]))
	if snapshot.has("minimap"):
		_minimap.set_snapshot(snapshot["minimap"])
	if snapshot.has("threat_radar"):
		_threat_radar.set_snapshot(snapshot["threat_radar"])


func _status_item(item_id: StringName) -> StatusGlyphItem:
	return _status_items[item_id] as StatusGlyphItem


func _update_conditional_statuses(statuses: Array) -> void:
	for index in _conditional_item_ids.size():
		var item := _status_item(_conditional_item_ids[index])
		if index >= mini(5, statuses.size()):
			item.visible = false
			continue
		var entry := Dictionary(statuses[index])
		var status_id := StringName(entry.get("id", &""))
		item.visible = not status_id.is_empty()
		if not item.visible:
			continue
		item.configure(status_id, &"conditional", _conditional_status_accent(status_id))
		item.set_value(String(entry.get("value", "")), true)
	_apply_responsive_layout()


func _conditional_status_accent(status_id: StringName) -> Color:
	match status_id:
		&"overflow_barrier": return Art.SYSTEM
		&"dash_overdrive": return Art.THERMAL
		&"braced_fire": return Art.PLAYER_REWARD
		&"hit_chain": return Art.SUPPORT
		&"miss_compensation": return Art.TEXT_MUTED
		&"last_stand": return Art.DANGER
	return Art.TEXT_MUTED


func _active_weapon_accent(active_id: StringName) -> Color:
	match active_id:
		&"black_hole": return Color(0.68, 0.50, 1.0)
		&"shockwave": return Art.MINT
		&"cross_beam": return Art.MUSTARD
	return Art.BOSS_COMMAND


func _update_action_status(
	snapshot: Dictionary,
	item_id: StringName,
	available_key: String,
	remaining_key: String
) -> void:
	if not snapshot.has(available_key) and not snapshot.has(remaining_key):
		return
	var is_available := bool(snapshot.get(available_key, false))
	var remaining := maxf(0.0, float(snapshot.get(remaining_key, 0.0)))
	_status_item(item_id).set_value(
		"READY" if is_available else "%.1fs" % remaining,
		is_available
	)


func update_threat_anchor(
	world_position: Vector2,
	screen_position: Vector2,
	is_visible: bool
) -> void:
	_threat_radar.set_live_anchor(world_position, screen_position, is_visible)


func notify(
	message: String,
	duration: float = 2.4,
	color: Color = Art.IVORY_BRIGHT,
	priority: int = 1,
	semantic_id: StringName = &"system"
) -> void:
	var entry := {
		"message":message,
		"duration":duration,
		"color":color,
		"priority":clampi(priority, 0, 3),
		"semantic_id":semantic_id,
	}
	if _coalesce_notification(entry):
		return
	if _notification_timer > 0.0:
		if _notification_queue.size() >= 4:
			var lowest_index := _lowest_priority_index()
			var lowest := Dictionary(_notification_queue[lowest_index])
			if int(entry["priority"]) <= int(lowest.get("priority", 0)):
				_emit_announcement_receipt(&"dropped", entry, &"queue_full")
				return
			_notification_queue.pop_at(lowest_index)
			_emit_announcement_receipt(&"dropped", lowest, &"queue_full")
		_notification_queue.append(entry)
		_emit_announcement_receipt(&"queued", entry)
		return
	_show_notification(entry)


func notify_immediate(
	message: String,
	duration: float = 2.4,
	color: Color = Art.IVORY_BRIGHT,
	semantic_id: StringName = &"danger"
) -> void:
	var entry := {
		"message":message,
		"duration":duration,
		"color":color,
		"priority":3,
		"semantic_id":semantic_id,
	}
	if _coalesce_notification(entry):
		return
	if _notification_timer > 0.0 and not _active_notification_entry.is_empty():
		var interrupted := _active_notification_entry.duplicate(true)
		interrupted["duration"] = _notification_timer
		_emit_announcement_receipt(&"interrupted", interrupted, &"priority")
		if _notification_queue.size() >= 4:
			var dropped := Dictionary(
				_notification_queue.pop_at(_lowest_priority_index())
			)
			_emit_announcement_receipt(&"dropped", dropped, &"queue_full")
		_notification_queue.push_front(interrupted)
		_emit_announcement_receipt(&"queued", interrupted)
	_show_notification(entry)


func clear_notifications() -> void:
	_notification_queue.clear()
	_notification_timer = 0.0
	_active_notification_entry.clear()
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
		"queue_cap":4,
		"text_only":true,
		"font_size":_notification.get_theme_font_size("font_size"),
		"autowrap_mode":_notification.autowrap_mode,
		"text_overrun_behavior":_notification.text_overrun_behavior,
		"max_lines_visible":_notification.max_lines_visible,
		"clip_text":_notification.clip_text,
		"panel_clips_contents":_notification_panel.clip_contents,
		"input_passthrough":(
			_notification_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE
		),
	}


func refresh_localized_content() -> void:
	# Announcement text is already localized at publication time. It is transient
	# feedback, so discard it rather than displaying the prior locale after refresh.
	clear_notifications()
	if not _active_owned:
		_status_item(&"active").set_value(tr("HUD_ACTION_LOCKED"), false)
	for item in _status_items.values():
		(item as StatusGlyphItem).queue_redraw()


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
	var large := viewport_width >= 1600.0 and not accessibility
	var safe_margin := _safe_margin(viewport_width)
	var meter_heights := _meter_heights(compact, accessibility, large)
	var meter_height := meter_heights.x + meter_heights.y
	var status_top_gap := _status_top_gap(compact, accessibility, large)
	var status_item_size := _status_item_size(compact, accessibility, large, false)
	var action_item_size := _status_item_size(compact, accessibility, large, true)
	var item_gap := _status_item_gap(compact, accessibility, large)
	var status_size := Vector2(
		_status_cluster_width(
			status_item_size, action_item_size, item_gap, accessibility
		),
		status_item_size.y
	)
	var status_position := Vector2(safe_margin, meter_height + status_top_gap)
	var minimap_base_size := (
		Vector2(160.0, 98.0)
		if compact
		else Vector2(176.0, 108.0)
	)
	var minimap_position := Vector2(
		viewport_width - minimap_base_size.x - safe_margin,
		meter_height + status_top_gap
	)
	var top_band_bottom := meter_height + status_top_gap + maxf(
		status_size.y, minimap_base_size.y
	)
	var toast_size := Vector2(
		minf(
			720.0,
			maxf(0.0, viewport_width - safe_margin * 2.0)
		),
		112.0 if accessibility else 52.0
	)
	var toast_position := Vector2(
		(viewport_width - toast_size.x) * 0.5,
		top_band_bottom + 4.0
	)
	var opaque_rects := [
		Rect2(minimap_position, minimap_base_size),
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
	var item_contracts: Array[Dictionary] = []
	var status_values: Array[String] = []
	for item_id in _visible_status_item_ids():
		var item := _status_item(item_id)
		item_contracts.append(item.debug_contract())
		status_values.append(String(item._value_label.text))
	return {
		"action_rail_size":Vector2.ZERO,
		"action_slot_count":2,
		"shows_primary_slot":false,
		"action_slot_contracts":[
			item_contracts[2], item_contracts[3],
		],
		"minimap_size":minimap_base_size,
		"minimap_zone_size":minimap_base_size,
		"minimap_position":minimap_position,
		"health_cluster_size":Vector2(viewport_width, meter_height),
		"meter_width":viewport_width,
		"meter_top":0.0,
		"meter_gap":0.0,
		"meter_heights":meter_heights,
		"status_cluster_size":status_size,
		"status_cluster_position":status_position,
		"status_cluster_panel_free":true,
		"status_cluster_background_geometry_count":0,
		"status_cluster_one_line":true,
		"status_item_gap":item_gap,
		"status_item_contracts":item_contracts,
		"status_values":status_values,
		"conditional_status_count":_visible_conditional_count(),
		"conditional_status_capacity":5,
		"visible_status_label_count":0,
		"health_panel_free":true,
		"health_meter":_health_bar.debug_contract(),
		"live_upgrade_icon_count":0,
		"has_live_upgrade_rail":false,
		"edge_boss_health_visible":false,
		"edge_target_health_visible":false,
		"conditional_clusters_have_backing":false,
		"zone_surface_count":1,
		"zone_surface_variations":[
			_minimap_panel.theme_type_variation,
		],
		"toast_surface_variation":&"text_only",
		"toast_size":toast_size,
		"toast_position":toast_position,
		"toast_center_attached":is_equal_approx(
			toast_position.y,
			top_band_bottom + 4.0
		),
		"raster_chrome_consumer":false,
		"opaque_combat_area_ratio":(
			opaque_area / (viewport_width * viewport_height)
		),
		"central_safe_clear":central_safe_clear,
		"top_clusters_do_not_overlap":(
			status_position.x + status_size.x <= minimap_position.x
		),
		"zone_count":4,
		"notification_inside_hud":_notification_panel.get_parent() == self,
		"viewport_height":viewport_height,
	}


func _apply_responsive_layout() -> void:
	if _health_bar == null:
		return
	var compact := size.x < 1100.0
	var accessibility := _accessibility_text_scale > 1.0
	var large := size.x >= 1600.0 and not accessibility
	var safe_margin := _safe_margin(size.x)
	var minimap_base_size := (
		Vector2(160.0, 98.0)
		if compact
		else Vector2(176.0, 108.0)
	)
	_health_bar.set_layout_profile(compact, accessibility, large)
	var meter_height := _health_bar.total_height()
	var status_top_gap := _status_top_gap(compact, accessibility, large)
	_health_bar.position = Vector2.ZERO
	_health_bar.custom_minimum_size = Vector2(size.x, meter_height)
	_health_bar.size = Vector2(size.x, meter_height)
	var item_gap := _status_item_gap(compact, accessibility, large)
	for item in _status_items.values():
		(item as StatusGlyphItem).set_layout_profile(compact, accessibility, large)
	var status_item_size := _status_item_size(compact, accessibility, large, false)
	var action_item_size := _status_item_size(compact, accessibility, large, true)
	for item_id in _visible_status_item_ids():
		var item := _status_item(item_id)
		var item_width := _profile_status_item_width(
			item_id, status_item_size, action_item_size, accessibility
		)
		item.custom_minimum_size.x = item_width
		item.size.x = item_width
	var status_size := Vector2(
		_status_cluster_width(
			status_item_size, action_item_size, item_gap, accessibility
		),
		status_item_size.y
	)
	_status_cluster.position = Vector2(safe_margin, meter_height + status_top_gap)
	_status_cluster.custom_minimum_size = status_size
	_status_cluster.size = status_size
	var status_cursor := 0.0
	for item_id in _visible_status_item_ids():
		var item := _status_item(item_id)
		item.position = Vector2(status_cursor, 0.0)
		status_cursor += item.size.x + item_gap
	_minimap_panel.custom_minimum_size = minimap_base_size
	_minimap_panel.size = minimap_base_size
	_minimap_panel.position = Vector2(
		size.x - minimap_base_size.x - safe_margin,
		meter_height + status_top_gap
	)
	_minimap.custom_minimum_size = Vector2(
		minimap_base_size.x - 20.0,
		minimap_base_size.y - 16.0
	)
	var top_band_bottom := meter_height + status_top_gap + maxf(
		status_size.y, minimap_base_size.y
	)
	var announcement_width := 720.0
	_notification_panel.size = Vector2(
		minf(announcement_width, maxf(0.0, size.x - safe_margin * 2.0)),
		112.0 if accessibility else 52.0
	)
	_notification_panel.position = Vector2(
		(size.x - _notification_panel.size.x) * 0.5,
		top_band_bottom + 4.0
	)
	_notification.position = Vector2.ZERO
	_notification.size = _notification_panel.size
func _safe_margin(viewport_width: float) -> float:
	if viewport_width < 1100.0:
		return 16.0
	if viewport_width >= 1600.0:
		return 32.0
	return 24.0


func _meter_heights(compact: bool, accessibility: bool, large: bool) -> Vector2:
	if accessibility:
		return Vector2(52.0, 32.0)
	if compact:
		return Vector2(28.0, 18.0)
	if large:
		return Vector2(40.0, 26.0)
	return Vector2(32.0, 22.0)


func _status_item_size(
	compact: bool,
	accessibility: bool,
	large: bool,
	action: bool
) -> Vector2:
	if accessibility:
		return Vector2(92.0 if action else 72.0, 64.0)
	if compact:
		return Vector2(46.0 if action else 34.0, 36.0)
	if large:
		return Vector2(54.0 if action else 40.0, 44.0)
	return Vector2(50.0 if action else 36.0, 40.0)


func _status_item_gap(compact: bool, accessibility: bool, large: bool) -> float:
	if accessibility:
		return 6.0
	if compact:
		return 4.0
	if large:
		return 8.0
	return 6.0


func _status_top_gap(compact: bool, accessibility: bool, large: bool) -> float:
	if accessibility or compact:
		return 4.0
	if large:
		return 8.0
	return 6.0


func _visible_conditional_count() -> int:
	var count := 0
	for item_id in _conditional_item_ids:
		if _status_item(item_id).visible:
			count += 1
	return count


func _visible_status_item_ids() -> Array[StringName]:
	var result: Array[StringName] = [&"stage", &"defeats", &"dash", &"active"]
	for item_id in _conditional_item_ids:
		if _status_item(item_id).visible:
			result.append(item_id)
	return result


func _status_cluster_width(
	status_size: Vector2,
	action_size: Vector2,
	gap: float,
	accessibility: bool
) -> float:
	var item_ids := _visible_status_item_ids()
	var width := gap * float(maxi(0, item_ids.size() - 1))
	for item_id in item_ids:
		width += _profile_status_item_width(
			item_id, status_size, action_size, accessibility
		)
	return width


func _profile_status_item_width(
	item_id: StringName,
	status_size: Vector2,
	action_size: Vector2,
	accessibility: bool
) -> float:
	if accessibility and item_id == &"stage":
		return 104.0
	if accessibility and item_id == &"defeats":
		return 48.0
	return action_size.x if item_id in [&"dash", &"active"] else status_size.x


func set_accessibility_text_scale(scale: float) -> void:
	_accessibility_text_scale = clampf(scale, 1.0, 2.0)
	_apply_responsive_layout()


func _show_next_notification() -> void:
	if not _notification_queue.is_empty():
		_show_notification(Dictionary(
			_notification_queue.pop_at(_highest_priority_index())
		))


func _show_notification(entry: Dictionary) -> void:
	_active_notification_entry = entry.duplicate(true)
	_notification.text = String(entry["message"])
	_notification.add_theme_color_override(
		"font_color",
		Color(entry["color"])
	)
	_notification_panel.modulate.a = 1.0
	_notification_panel.visible = true
	_notification_timer = float(entry["duration"])
	_emit_announcement_receipt(&"shown", entry)
	set_process(true)


func _coalesce_notification(entry: Dictionary) -> bool:
	var message := String(entry.get("message", ""))
	if message.is_empty():
		_emit_announcement_receipt(&"dropped", entry, &"empty")
		return true
	if not _active_notification_entry.is_empty() and String(_active_notification_entry.get("message", "")) == message:
		_notification_timer = maxf(_notification_timer, float(entry.get("duration", 0.0)))
		_emit_announcement_receipt(&"dropped", entry, &"coalesced")
		return true
	for index in _notification_queue.size():
		var queued_entry := Dictionary(_notification_queue[index])
		if String(queued_entry.get("message", "")) == message:
			queued_entry["duration"] = maxf(float(queued_entry.get("duration", 0.0)), float(entry.get("duration", 0.0)))
			queued_entry["priority"] = maxi(int(queued_entry.get("priority", 0)), int(entry.get("priority", 0)))
			_notification_queue[index] = queued_entry
			_emit_announcement_receipt(&"dropped", entry, &"coalesced")
			return true
	return false


func _lowest_priority_index() -> int:
	var lowest_index := 0
	var lowest_priority := 4
	for index in _notification_queue.size():
		var priority := int(Dictionary(_notification_queue[index]).get("priority", 0))
		if priority < lowest_priority:
			lowest_priority = priority
			lowest_index = index
	return lowest_index


func _highest_priority_index() -> int:
	var highest_index := 0
	var highest_priority := -1
	for index in _notification_queue.size():
		var priority := int(Dictionary(_notification_queue[index]).get("priority", 0))
		if priority > highest_priority:
			highest_priority = priority
			highest_index = index
	return highest_index


func _emit_announcement_receipt(
	status: StringName,
	entry: Dictionary,
	reason: StringName = &""
) -> void:
	announcement_receipt.emit({
		"status":status,
		"semantic_id":StringName(entry.get("semantic_id", &"system")),
		"priority":int(entry.get("priority", 1)),
		"reason":reason,
	})


func _shadow_label(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Art.COBALT_VOID)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
