class_name VehicleStatusOrbit
extends Control

## Two shape-coded recurring upgrade timers placed inside the threat radar.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const UiAssets = preload("res://scripts/ui/vehicle_ui_asset_provider.gd")
const BADGE_RADIUS := 12.0
const ORBIT_RADIUS := 62.0
const ANGLES := [-2.05, -1.10]

var snapshot: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_snapshot(value: Dictionary) -> void:
	snapshot = value
	queue_redraw()


func _draw() -> void:
	var states: Array = snapshot.get("states", [])
	if states.is_empty():
		return
	var center: Vector2 = snapshot.get("center", size * 0.5)
	center.x = clampf(center.x, 112.0, size.x - 112.0)
	center.y = clampf(center.y, 112.0, size.y - 112.0)
	for index in mini(2, states.size()):
		var state: Dictionary = states[index]
		var badge_center := center + Vector2.RIGHT.rotated(float(ANGLES[index])) * ORBIT_RADIUS
		_draw_badge(badge_center, state)


func _draw_badge(center: Vector2, state: Dictionary) -> void:
	var upgrade_id := StringName(state.get("id", &""))
	var active := bool(state.get("active", false))
	var progress := clampf(float(state.get("progress", 0.0)), 0.0, 1.0)
	var color := Art.MINT if upgrade_id == &"aegis_cycle" else (Art.CORAL if upgrade_id == &"overclock_cycle" else Art.MUSTARD)
	var frame := UiAssets.texture(
		&"small_state",
		&"pip_filled" if active else &"pip_available"
	)
	if frame != null:
		var frame_size := Vector2.ONE * (BADGE_RADIUS + 5.0) * 2.0
		draw_texture_rect(
			frame,
			Rect2(center - frame_size * 0.5, frame_size),
			false,
			Color.WHITE
		)
	draw_arc(center, BADGE_RADIUS + 2.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 20, color, 3.5, true)
	var icon := SemanticAssets.texture(
		&"hud/upgrade_defense"
		if upgrade_id == &"aegis_cycle"
		else &"hud/upgrade_support"
	)
	if icon != null:
		var icon_size := Vector2.ONE * 18.0
		draw_texture_rect(
			icon,
			Rect2(center - icon_size * 0.5, icon_size),
			false,
			Color.WHITE
		)


func debug_contract() -> Dictionary:
	return {
		"maximum_badges":2,
		"badge_diameter":24.0,
		"orbit_radius":ORBIT_RADIUS,
		"image_coded":true,
	}
