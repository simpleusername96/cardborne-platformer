class_name PlayerVisualOverlay
extends Node2D

const INK := Color("172025")
const METAL := Color("dce4df")
const LEATHER := Color("79513f")
const GOLD := Color("e0ae48")

var _hero_id: StringName = &"traveler"
var _hero_color := Color("3dbdc2")
var _player: Node
var _animation_time: float = 0.0


func _ready() -> void:
	_player = get_parent().get_parent()
	queue_redraw()


func configure(hero_id: StringName, hero_color: Color) -> void:
	_hero_id = hero_id
	_hero_color = hero_color
	queue_redraw()


func get_visual_contract() -> Dictionary:
	return {"hero_id": String(_hero_id), "hero_color": _hero_color}


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
	draw_colored_polygon(PackedVector2Array([
		Vector2(17, -44), Vector2(28, -38), Vector2(27, -14),
		Vector2(20, -6), Vector2(14, -16),
	]), Color("647b84"))
	draw_line(Vector2(19, -34), Vector2(25, -17), METAL, 2.5)
	draw_line(Vector2(-19, -40), Vector2(-25, -4), LEATHER, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-29, -4), Vector2(-20, -5), Vector2(-23, 7), Vector2(-34, 10),
	]), METAL)
