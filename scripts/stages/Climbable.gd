class_name Climbable
extends Area2D

@export var climbable_size: Vector2 = Vector2(42.0, 240.0)
@export var visual_color: Color = Color(0.72, 0.78, 0.52, 0.82)

var _route_enabled := true


func _ready() -> void:
	collision_layer = 256
	collision_mask = 4
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_ensure_shape_and_visual()
	_apply_route_enabled()


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = climbable_size
		shape.shape = rect
		add_child(shape)

	if get_node_or_null("Visual") == null:
		var visual := Polygon2D.new()
		visual.name = "Visual"
		visual.color = visual_color
		var half := climbable_size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half.x * 0.18, -half.y),
			Vector2(half.x * 0.18, -half.y),
			Vector2(half.x * 0.18, half.y),
			Vector2(-half.x * 0.18, half.y)
		])
		add_child(visual)


func _on_body_entered(body: Node) -> void:
	if body.has_method("enter_climbable"):
		body.enter_climbable(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("exit_climbable"):
		body.exit_climbable(self)


func get_climb_axis_x() -> float:
	return global_position.x


func set_route_enabled(enabled: bool) -> void:
	_route_enabled = enabled
	_apply_route_enabled()


func is_route_enabled() -> bool:
	return _route_enabled


func _apply_route_enabled() -> void:
	visible = _route_enabled
	monitoring = _route_enabled
	monitorable = _route_enabled
	collision_layer = 256 if _route_enabled else 0
	collision_mask = 4 if _route_enabled else 0
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", not _route_enabled)
