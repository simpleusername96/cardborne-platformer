class_name PlayerVisualOverlay
extends Node2D

const INK := Color("172025")
const METAL := Color("dce4df")
const LEATHER := Color("79513f")
const GOLD := Color("e0ae48")
const GUARD_CYAN := Color("4fd2e8")
const GUARD_CORAL := Color("ff5945")

var _hero_id: StringName = &"traveler"
var _hero_color := Color("3dbdc2")
var _player: Node
var _combat_controller: Node
var _animation_time: float = 0.0
var _guard_phase: StringName = &"idle"
var _guard_feedback_outcome: StringName = &""
var _guard_feedback_event_id: int = 0
var _guard_feedback_time: float = 0.0


func _ready() -> void:
	_player = get_parent().get_parent()
	_combat_controller = _player.get_node_or_null("CombatController") if _player != null else null
	queue_redraw()


func configure(hero_id: StringName, hero_color: Color) -> void:
	_hero_id = hero_id
	_hero_color = hero_color
	queue_redraw()


func get_visual_contract() -> Dictionary:
	return {
		"hero_id": String(_hero_id),
		"hero_color": _hero_color,
		"guard_phase": _guard_phase,
		"defense_outcome": _guard_feedback_outcome,
		"defense_event_id": _guard_feedback_event_id,
		"defense_effect_visible": _guard_feedback_time > 0.0,
	}


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_animation_time += maxf(delta, 0.0)
	_update_guard_visual(maxf(delta, 0.0))
	var velocity_value: Variant = _player.get("velocity")
	var velocity := velocity_value as Vector2 if velocity_value is Vector2 else Vector2.ZERO
	var grounded := bool(_player.call("is_on_floor")) if _player.has_method("is_on_floor") else false
	var dashing := bool(_player.get("is_dashing"))
	position.y = sin(_animation_time * 13.0) * 1.5 if grounded and absf(velocity.x) > 18.0 else 0.0
	rotation = clampf(velocity.x / 2600.0, -0.065, 0.065)
	if dashing:
		scale = Vector2(1.14, 0.9)
	elif not grounded:
		scale = Vector2(0.94, 1.08) if velocity.y < 0.0 else Vector2(1.06, 0.94)
	else:
		scale = Vector2.ONE


func _update_guard_visual(delta: float) -> void:
	_guard_feedback_time = maxf(_guard_feedback_time - delta, 0.0)
	if _combat_controller == null or not is_instance_valid(_combat_controller):
		return
	var snapshot: Dictionary = _combat_controller.call("get_state_snapshot")
	var guard: Dictionary = snapshot.get("guard", {})
	var feedback: Dictionary = snapshot.get("defense_feedback", {})
	var next_phase := StringName(guard.get("phase", &"idle"))
	var next_outcome := StringName(
		feedback.get("outcome", &"") if bool(feedback.get("active", false)) else &""
	)
	var next_event_id := int(feedback.get("event_id", 0))
	var changed := next_phase != _guard_phase or next_outcome != _guard_feedback_outcome
	if next_event_id != _guard_feedback_event_id and bool(feedback.get("active", false)):
		_guard_feedback_time = 0.32
		changed = true
	_guard_phase = next_phase
	_guard_feedback_outcome = next_outcome
	_guard_feedback_event_id = next_event_id
	if changed or _guard_feedback_time > 0.0:
		queue_redraw()


func _draw() -> void:
	_draw_common()
	_draw_traveler()


func _draw_common() -> void:
	draw_line(Vector2(-9, -7), Vector2(-11, 3), INK, 6.0)
	draw_line(Vector2(8, -7), Vector2(11, 3), INK, 6.0)
	draw_line(Vector2(-11, 3), Vector2(-3, 3), _hero_color.lightened(0.18), 4.0)
	draw_line(Vector2(11, 3), Vector2(3, 3), _hero_color.lightened(0.18), 4.0)
	draw_circle(Vector2(7, -55), 1.8, INK)


func _draw_traveler() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13, -64), Vector2(0, -72), Vector2(13, -64),
		Vector2(10, -58), Vector2(-10, -58),
	]), METAL)
	draw_line(Vector2(-12, -44), Vector2(12, -44), GOLD, 4.0)
	var shield_offset := _shield_offset()
	var shield_color := Color("647b84")
	if _guard_phase == &"active":
		shield_color = shield_color.lightened(0.18)
	elif _guard_phase == &"recovery":
		shield_color = shield_color.darkened(0.22)
	draw_colored_polygon(PackedVector2Array([
		Vector2(17, -44) + shield_offset,
		Vector2(28, -38) + shield_offset,
		Vector2(27, -14) + shield_offset,
		Vector2(20, -6) + shield_offset,
		Vector2(14, -16) + shield_offset,
	]), shield_color)
	draw_line(
		Vector2(19, -34) + shield_offset,
		Vector2(25, -17) + shield_offset,
		METAL,
		2.5
	)
	draw_line(Vector2(-19, -40), Vector2(-25, -4), LEATHER, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-29, -4), Vector2(-20, -5), Vector2(-23, 7), Vector2(-34, 10),
	]), METAL)
	_draw_guard_phase()
	_draw_guard_feedback()


func _shield_offset() -> Vector2:
	match _guard_phase:
		&"startup":
			return Vector2(3.0, -1.0)
		&"active":
			return Vector2(7.0, -2.0)
		&"recovery":
			return Vector2(-2.0, 4.0)
		_:
			return Vector2.ZERO


func _draw_guard_phase() -> void:
	match _guard_phase:
		&"startup":
			draw_line(Vector2(34, -42), Vector2(41, -35), GUARD_CYAN, 2.0, true)
			draw_line(Vector2(41, -35), Vector2(34, -28), GUARD_CYAN, 2.0, true)
		&"active":
			draw_arc(Vector2(17, -26), 31.0, -1.05, 1.05, 18, GUARD_CYAN, 3.0, true)
			draw_line(Vector2(43, -42), Vector2(43, -10), Color(GUARD_CYAN, 0.45), 1.0, true)
		&"recovery":
			draw_line(Vector2(28, -10), Vector2(38, -2), GUARD_CYAN.darkened(0.35), 2.0, true)
			draw_line(Vector2(32, -7), Vector2(38, -7), GUARD_CYAN.darkened(0.35), 2.0, true)


func _draw_guard_feedback() -> void:
	if _guard_feedback_time <= 0.0:
		return
	var fade := clampf(_guard_feedback_time / 0.32, 0.0, 1.0)
	match _guard_feedback_outcome:
		&"normal_block":
			var color := Color(GUARD_CYAN, fade)
			for offset_y in [-11.0, 0.0, 11.0]:
				draw_line(Vector2(42, -26 + offset_y), Vector2(55, -26 + offset_y * 1.2), color, 2.5, true)
		&"precise_block":
			var color := Color(GOLD.lightened(0.16), fade)
			draw_arc(Vector2(38, -26), 18.0, 0.0, TAU, 20, color, 2.5, true)
			draw_colored_polygon(PackedVector2Array([
				Vector2(38, -48), Vector2(43, -26), Vector2(38, -4), Vector2(33, -26),
			]), Color(color, fade * 0.7))
		&"guard_break":
			var color := Color(GUARD_CORAL, fade)
			draw_polyline(PackedVector2Array([
				Vector2(37, -47), Vector2(30, -33), Vector2(42, -27), Vector2(32, -13),
			]), color, 3.0, true)
			draw_line(Vector2(44, -41), Vector2(53, -49), color, 2.5, true)
			draw_line(Vector2(44, -11), Vector2(54, -4), color, 2.5, true)
		&"guard_failed":
			var color := Color(GUARD_CORAL, fade * 0.8)
			draw_line(Vector2(31, -44), Vector2(47, -8), color, 2.0, true)
			draw_line(Vector2(47, -44), Vector2(31, -8), color, 2.0, true)
