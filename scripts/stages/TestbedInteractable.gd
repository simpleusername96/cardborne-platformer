class_name TestbedInteractable
extends Interactable

@export var result_message: String = "Interaction checked"
@export var body_size: Vector2 = Vector2(48.0, 72.0)

var _visual: Polygon2D


func _ready() -> void:
	collision_layer = 256
	collision_mask = 4
	_ensure_shape_and_visual()
	super._ready()


func interact(player: Node) -> void:
	super.interact(player)
	SignalBus.status_message_changed.emit(result_message)
	if _visual != null:
		_visual.color = Color(0.42, 0.94, 0.62, 0.95)


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = body_size
		shape.position = Vector2(0.0, -body_size.y * 0.5)
		shape.shape = rect
		add_child(shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = Color(0.38, 0.64, 0.90, 0.90)
		var half_x := body_size.x * 0.5
		_visual.polygon = PackedVector2Array([
			Vector2(-half_x, -body_size.y),
			Vector2(half_x, -body_size.y),
			Vector2(half_x, 0.0),
			Vector2(-half_x, 0.0)
		])
		add_child(_visual)
