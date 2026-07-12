class_name PlayerVisualOverlay
extends Node2D

const INK := Color("172025")
const METAL := Color("dce4df")
const LEATHER := Color("79513f")
const GOLD := Color("e0ae48")

var _profile_id: StringName = &"warrior"
var _profile_color := Color("52b8ea")
var _player: Node
var _animation_time: float = 0.0


func _ready() -> void:
	_player = get_parent().get_parent()
	queue_redraw()


func configure(profile_id: StringName, profile_color: Color) -> void:
	_profile_id = profile_id
	_profile_color = profile_color
	queue_redraw()


func get_visual_contract() -> Dictionary:
	return {"profile_id": String(_profile_id), "profile_color": _profile_color}


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_animation_time += maxf(delta, 0.0)
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


func _draw() -> void:
	_draw_common()
	match _profile_id:
		&"archer":
			_draw_archer()
		&"assassin":
			_draw_assassin()
		_:
			_draw_warrior()


func _draw_common() -> void:
	draw_line(Vector2(-9, -7), Vector2(-11, 3), INK, 6.0)
	draw_line(Vector2(8, -7), Vector2(11, 3), INK, 6.0)
	draw_line(Vector2(-11, 3), Vector2(-3, 3), _profile_color.lightened(0.18), 4.0)
	draw_line(Vector2(11, 3), Vector2(3, 3), _profile_color.lightened(0.18), 4.0)
	draw_circle(Vector2(7, -55), 1.8, INK)


func _draw_warrior() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13, -64), Vector2(0, -72), Vector2(13, -64),
		Vector2(10, -58), Vector2(-10, -58),
	]), METAL)
	draw_line(Vector2(-12, -44), Vector2(12, -44), GOLD, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(17, -44), Vector2(28, -38), Vector2(27, -14),
		Vector2(20, -6), Vector2(14, -16),
	]), Color("647b84"))
	draw_line(Vector2(19, -34), Vector2(25, -17), METAL, 2.5)
	draw_line(Vector2(-19, -40), Vector2(-25, -4), LEATHER, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-29, -4), Vector2(-20, -5), Vector2(-23, 7), Vector2(-34, 10),
	]), METAL)


func _draw_archer() -> void:
	draw_arc(Vector2(0, -55), 13.5, PI, TAU, 14, Color("3c3940"), 5.0)
	draw_line(Vector2(-13, -42), Vector2(-18, -4), LEATHER, 5.0)
	for offset in [-4.0, 0.0, 4.0]:
		draw_line(Vector2(-18 + offset * 0.2, -43), Vector2(-24 + offset, -61), METAL, 1.6)
	draw_arc(Vector2(24, -27), 23.0, -1.25, 1.25, 18, GOLD, 3.0)
	draw_line(Vector2(31, -49), Vector2(31, -5), METAL, 1.6)
	draw_circle(Vector2(8, -55), 2.0, Color("9de6c8"))


func _draw_assassin() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -62), Vector2(0, -72), Vector2(14, -62),
		Vector2(11, -48), Vector2(-11, -48),
	]), Color("2f293d"))
	draw_rect(Rect2(-11, -55, 22, 5), INK)
	draw_circle(Vector2(7, -53), 1.8, Color("dc7cf0"))
	draw_line(Vector2(-17, -35), Vector2(-27, 0), LEATHER, 3.5)
	draw_line(Vector2(17, -35), Vector2(29, 0), LEATHER, 3.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-31, 0), Vector2(-24, -2), Vector2(-28, 10), Vector2(-37, 14),
	]), METAL)
	draw_colored_polygon(PackedVector2Array([
		Vector2(32, 0), Vector2(25, -2), Vector2(30, 10), Vector2(39, 13),
	]), METAL)
