class_name DamageableDummy
extends StaticBody2D

signal health_changed(current: int, maximum: int)

const MAX_HEALTH := 120

var health := MAX_HEALTH
var flash_remaining := 0.0
var reset_remaining := 0.0


func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask = 0
	queue_redraw()


func _process(delta: float) -> void:
	flash_remaining = maxf(0.0, flash_remaining - delta)
	if reset_remaining > 0.0:
		reset_remaining -= delta
		if reset_remaining <= 0.0:
			reset_dummy()
	queue_redraw()


func receive_hit(damage: int, _stagger: int, _source_id: StringName) -> void:
	if health <= 0:
		return
	health = maxi(0, health - damage)
	flash_remaining = 0.10
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		reset_remaining = 1.0


func reset_dummy() -> void:
	health = MAX_HEALTH
	reset_remaining = 0.0
	health_changed.emit(health, MAX_HEALTH)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 16), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 27.0, Color(0.02, 0.04, 0.05, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var body_color := Color("f0f1e8") if flash_remaining > 0.0 else Color("6f8f62")
	draw_polygon(PackedVector2Array([Vector2(0, -34), Vector2(24, -4), Vector2(18, 28), Vector2(-18, 28), Vector2(-24, -4)]), PackedColorArray([body_color]))
	draw_circle(Vector2.ZERO, 9.0, Color("12171a"))
	draw_rect(Rect2(-34, -52, 68, 6), Color("12171a"))
	draw_rect(Rect2(-34, -52, 68.0 * health / MAX_HEALTH, 6), Color("d9654f"))
