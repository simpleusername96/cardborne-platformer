class_name Hazard
extends Hitbox

@export var hazard_size: Vector2 = Vector2(140.0, 22.0)
@export var hazard_color: Color = Color(0.95, 0.24, 0.16, 0.90)


func _ready() -> void:
	collision_layer = 64
	collision_mask = 4
	starts_active = true
	repeat_hits = true
	tags = ["hazard"]
	_ensure_shape_and_visual()
	super._ready()


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = hazard_size
		shape.shape = rect
		add_child(shape)

	if get_node_or_null("Visual") == null:
		var visual := Polygon2D.new()
		visual.name = "Visual"
		visual.color = hazard_color
		var half := hazard_size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y)
		])
		add_child(visual)
