class_name CombatDecoy
extends Area2D

signal expired

var duration: float = 0.8
var slow_duration: float = 0.0
var slow_scale: float = 0.65
var slow_radius: float = 72.0

var _remaining: float = 0.0


func _ready() -> void:
	add_to_group("enemy_decoy")
	collision_layer = 0
	collision_mask = 8
	monitoring = true
	monitorable = false
	_remaining = duration
	_ensure_shape()
	_ensure_visual()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_remaining = maxf(_remaining - delta, 0.0)
	modulate.a = clampf(_remaining / maxf(duration, 0.01), 0.15, 1.0)
	if _remaining <= 0.0:
		expired.emit()
		queue_free()


func get_remaining_time() -> float:
	return _remaining


func _on_body_entered(body: Node) -> void:
	if slow_duration > 0.0 and body.has_method("apply_external_slow"):
		body.call("apply_external_slow", slow_duration, slow_scale)


func _ensure_shape() -> void:
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = slow_radius
	collision.shape = circle
	add_child(collision)


func _ensure_visual() -> void:
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.z_index = 15
	visual.color = Color(0.48, 0.34, 0.72, 0.46)
	visual.polygon = PackedVector2Array([
		Vector2(-22.0, 0.0),
		Vector2(-16.0, -38.0),
		Vector2(0.0, -50.0),
		Vector2(16.0, -38.0),
		Vector2(22.0, 0.0),
	])
	add_child(visual)
