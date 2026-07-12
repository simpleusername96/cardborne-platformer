class_name SwitchInteractable
extends Interactable

@export var body_size: Vector2 = Vector2(48.0, 72.0)
@export var idle_color: Color = Color(0.38, 0.64, 0.90, 0.90)
@export var active_color: Color = Color(0.42, 0.94, 0.62, 0.95)

var _visual: Polygon2D
var _active: bool = false


func _ready() -> void:
	collision_layer = 256
	collision_mask = 4
	_ensure_shape_and_visual()
	set_active(_active)
	super._ready()


func set_active(active: bool) -> void:
	_active = active
	if _visual != null:
		_visual.color = active_color if active else idle_color


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = body_size
		shape.position = Vector2(0.0, -body_size.y * 0.5)
		shape.shape = rectangle
		add_child(shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		var half_width := body_size.x * 0.5
		_visual.polygon = PackedVector2Array([
			Vector2(-half_width, -body_size.y),
			Vector2(half_width, -body_size.y),
			Vector2(half_width, 0.0),
			Vector2(-half_width, 0.0),
		])
		add_child(_visual)
