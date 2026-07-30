class_name VehicleVisualSheetCanvas
extends Control

## Deterministic sheet renderer fed by the runtime visual token provider.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ComponentMeshes = preload(
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)
const FONT_PATH := "res://art/ui/production/fonts/NotoSansKR-Variable.ttf"

var sheet_id: StringName = &"foundation"
var _font: Font


func _ready() -> void:
	_font = load(FONT_PATH) as Font
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Art.SPACE_BLACK)
	if sheet_id == &"foundation":
		_draw_foundation()
	else:
		_draw_controls()


func _draw_foundation() -> void:
	_draw_header(
		"01  FOUNDATION TOKENS",
		"일반 SF · flat two-plane · semantic role first",
		"provider  VehicleStageVisualProfile"
	)
	var roles := Art.required_color_roles()
	var role_order := [
		"space_black", "world_canvas", "surface", "raised", "line",
		"text_primary", "text_muted", "player_reward", "danger", "boss_command",
		"support", "system", "thermal", "toxin", "cryo", "arc",
	]
	for index in role_order.size():
		var column := index % 4
		var row := index / 4
		var rect := Rect2(72.0 + column * 310.0, 190.0 + row * 116.0, 278.0, 88.0)
		_draw_token(rect, role_order[index], Color(roles[role_order[index]]))

	var type_x := 1370.0
	_label(Vector2(type_x, 190.0), "TYPE SCALE / Noto Sans KR", 20, Art.TEXT_PRIMARY)
	var type_labels := ["caption", "body", "label", "section", "title", "display"]
	for index in Art.TYPE_SCALE_WIDE.size():
		var font_size := int(Art.TYPE_SCALE_WIDE[index])
		_label(
			Vector2(type_x, 242.0 + index * 72.0),
			"%s  %d  기체 상태 / SHIP STATUS" % [type_labels[index], font_size],
			font_size,
			Art.TEXT_PRIMARY if index > 1 else Art.TEXT_MUTED
		)

	_label(Vector2(72.0, 734.0), "SPACING", 20, Art.TEXT_PRIMARY)
	var spacing_x := 72.0
	for spacing in Art.SPACING_SCALE:
		draw_rect(Rect2(spacing_x, 774.0, float(spacing) * 4.0, 18.0), Art.SYSTEM)
		_label(Vector2(spacing_x, 826.0), str(spacing), 15, Art.TEXT_MUTED)
		spacing_x += float(spacing) * 4.0 + 34.0

	_label(Vector2(790.0, 734.0), "COMPONENT GRAMMAR", 20, Art.TEXT_PRIMARY)
	_draw_component(
		Vector2(900.0, 864.0), &"forward_wedge", Art.PLAYER_REWARD, "player / reward"
	)
	_draw_component(
		Vector2(1134.0, 864.0), &"split_spear", Art.DANGER, "threat"
	)
	_draw_component(
		Vector2(1368.0, 864.0), &"solid_chevron", Art.SUPPORT, "support"
	)
	_draw_component(
		Vector2(1602.0, 864.0), &"diamond", Art.BOSS_COMMAND, "boss / command"
	)
	_draw_component(
		Vector2(1836.0, 864.0), &"slab", Art.SYSTEM, "system"
	)
	_label(
		Vector2(72.0, 1082.0),
		"shape + notch + rail pattern carry meaning; color is secondary",
		15,
		Art.TEXT_MUTED
	)


func _draw_controls() -> void:
	_draw_header(
		"10  UI CONTROL STATES",
		"one border · one semantic rail · 44 px minimum target",
		"provider  VehicleStageVisualProfile / Noto Sans KR"
	)
	var states := [
		{"id": "normal", "label": "기본 / NORMAL", "line": Art.LINE, "rail": Color.TRANSPARENT, "text": Art.TEXT_PRIMARY},
		{"id": "hover", "label": "가리킴 / HOVER", "line": Art.LINE, "rail": Art.SYSTEM, "text": Art.TEXT_PRIMARY},
		{"id": "focus", "label": "키보드 초점 / FOCUS", "line": Art.SYSTEM, "rail": Art.SYSTEM, "text": Art.TEXT_PRIMARY},
		{"id": "selected", "label": "선택 / SELECTED", "line": Art.LINE, "rail": Art.PLAYER_REWARD, "text": Art.TEXT_PRIMARY},
		{"id": "disabled", "label": "비활성 / DISABLED", "line": Art.LINE.darkened(0.35), "rail": Color.TRANSPARENT, "text": Art.TEXT_MUTED.darkened(0.28)},
		{"id": "danger", "label": "위험 / DANGER", "line": Art.DANGER, "rail": Art.DANGER, "text": Art.DANGER},
	]
	for index in states.size():
		var column := index % 3
		var row := index / 3
		var rect := Rect2(72.0 + column * 624.0, 210.0 + row * 176.0, 568.0, 132.0)
		_draw_control_state(rect, Dictionary(states[index]))

	_label(Vector2(72.0, 620.0), "PANEL HIERARCHY", 20, Art.TEXT_PRIMARY)
	var modal := Rect2(72.0, 660.0, 1190.0, 360.0)
	_draw_panel(modal, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(modal.position + Vector2(28.0, 48.0), "함선 시스템 / SHIP SYSTEMS", 28, Art.TEXT_PRIMARY)
	_label(
		modal.position + Vector2(28.0, 84.0),
		"Title → content → action. Decoration never competes with task hierarchy.",
		15,
		Art.TEXT_MUTED
	)
	_draw_panel(Rect2(100.0, 782.0, 710.0, 180.0), Art.WORLD_CANVAS, Art.LINE, Color.TRANSPARENT)
	_label(Vector2(128.0, 830.0), "현재 상태", 17, Art.TEXT_PRIMARY)
	_label(Vector2(128.0, 870.0), "장갑  100 / 100", 15, Art.TEXT_MUTED)
	_label(Vector2(128.0, 906.0), "추진  준비", 15, Art.SUPPORT)
	_draw_button(Rect2(862.0, 886.0, 348.0, 64.0), "확인 / CONFIRM", Art.PLAYER_REWARD, true)

	_label(Vector2(1340.0, 620.0), "CONTROL FAMILY", 20, Art.TEXT_PRIMARY)
	_draw_button(Rect2(1340.0, 676.0, 560.0, 64.0), "주요 행동 / PRIMARY", Art.PLAYER_REWARD, true)
	_draw_button(Rect2(1340.0, 764.0, 560.0, 64.0), "보조 행동 / SECONDARY", Art.SYSTEM, false)
	_draw_button(Rect2(1340.0, 852.0, 560.0, 64.0), "위험 행동 / DANGER", Art.DANGER, false)
	_draw_checkbox(Rect2(1340.0, 948.0, 560.0, 56.0), "모션 감소 / REDUCED MOTION")
	_label(
		Vector2(72.0, 1082.0),
		"selected, focus, disabled, and danger remain identifiable without hue alone",
		15,
		Art.TEXT_MUTED
	)


func _draw_header(title: String, subtitle: String, provider: String) -> void:
	_label(Vector2(72.0, 84.0), title, 36, Art.TEXT_PRIMARY)
	_label(Vector2(72.0, 126.0), subtitle, 17, Art.TEXT_MUTED)
	_label(Vector2(1510.0, 84.0), provider, 14, Art.SYSTEM)
	draw_line(Vector2(72.0, 154.0), Vector2(1976.0, 154.0), Art.LINE, 1.0)


func _draw_token(rect: Rect2, role: String, color: Color) -> void:
	draw_rect(rect, Art.SURFACE)
	draw_rect(Rect2(rect.position, Vector2(74.0, rect.size.y)), color)
	draw_rect(rect, Art.LINE, false, 1.0)
	_label(rect.position + Vector2(92.0, 34.0), role, 15, Art.TEXT_PRIMARY)
	_label(rect.position + Vector2(92.0, 63.0), "#%s" % color.to_html(false).to_upper(), 13, Art.TEXT_MUTED)


func _draw_component(
	center: Vector2,
	primitive_id: StringName,
	color: Color,
	caption: String
) -> void:
	var points := ComponentMeshes.primitive_points(primitive_id)
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(center + point * 58.0)
	var shadow := PackedVector2Array()
	for point in transformed:
		shadow.append(point + Vector2(8.0, 10.0))
	draw_colored_polygon(shadow, Art.SPACE_BLACK)
	draw_colored_polygon(transformed, color)
	_label(center + Vector2(-72.0, 102.0), caption, 13, Art.TEXT_MUTED)


func _draw_control_state(rect: Rect2, state: Dictionary) -> void:
	_draw_panel(rect, Art.SURFACE, Color(state["line"]), Color(state["rail"]))
	if String(state["id"]) == "focus":
		draw_rect(rect.grow(4.0), Art.SYSTEM, false, 2.0)
	if String(state["id"]) == "selected":
		var marker := PackedVector2Array([
			rect.position + Vector2(40.0, 66.0),
			rect.position + Vector2(48.0, 58.0),
			rect.position + Vector2(56.0, 66.0),
			rect.position + Vector2(48.0, 74.0),
		])
		draw_colored_polygon(marker, Art.PLAYER_REWARD)
	_label(rect.position + Vector2(76.0, 57.0), String(state["label"]), 17, Color(state["text"]))
	_label(rect.position + Vector2(76.0, 88.0), String(state["id"]), 13, Art.TEXT_MUTED)


func _draw_panel(rect: Rect2, fill: Color, line: Color, rail: Color) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, line, false, 1.0)
	if rail.a > 0.0:
		draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), rail)


func _draw_button(rect: Rect2, text: String, accent: Color, filled: bool) -> void:
	draw_rect(rect, accent if filled else Art.SURFACE)
	draw_rect(rect, accent, false, 1.0)
	if not filled:
		draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), accent)
	var text_color := Art.SPACE_BLACK if filled else Art.TEXT_PRIMARY
	_label(rect.position + Vector2(22.0, 39.0), text, 17, text_color)


func _draw_checkbox(rect: Rect2, text: String) -> void:
	_draw_panel(rect, Art.SURFACE, Art.LINE, Color.TRANSPARENT)
	var box := Rect2(rect.position + Vector2(18.0, 14.0), Vector2(28.0, 28.0))
	draw_rect(box, Art.SYSTEM, false, 2.0)
	draw_line(box.position + Vector2(6.0, 14.0), box.position + Vector2(12.0, 21.0), Art.SYSTEM, 3.0)
	draw_line(box.position + Vector2(12.0, 21.0), box.position + Vector2(23.0, 7.0), Art.SYSTEM, 3.0)
	_label(rect.position + Vector2(64.0, 36.0), text, 16, Art.TEXT_PRIMARY)


func _label(position: Vector2, text: String, font_size: int, color: Color) -> void:
	if _font == null:
		return
	draw_string(
		_font,
		position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)
