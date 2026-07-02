class_name StageCheckpoint
extends Area2D

@export var checkpoint_id: String = "checkpoint"
@export var respawn_offset: Vector2 = Vector2.ZERO
@export var checkpoint_size: Vector2 = Vector2(64.0, 96.0)

var _visual: Polygon2D


func _ready() -> void:
	collision_layer = 256
	collision_mask = 4
	body_entered.connect(_on_body_entered)
	_ensure_shape_and_visual()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var active_stage := get_tree().get_first_node_in_group("active_stage")
	if active_stage != null and active_stage.has_method("set_checkpoint"):
		active_stage.set_checkpoint(checkpoint_id, global_position + respawn_offset)
		_set_active_visual()


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = checkpoint_size
		shape.position = Vector2(0.0, -checkpoint_size.y * 0.5)
		shape.shape = rect
		add_child(shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = Color(0.30, 0.70, 1.0, 0.70)
		_visual.polygon = PackedVector2Array([
			Vector2(-16.0, -72.0),
			Vector2(16.0, -72.0),
			Vector2(16.0, 0.0),
			Vector2(-16.0, 0.0),
		])
		add_child(_visual)


func _set_active_visual() -> void:
	if _visual != null:
		_visual.color = Color(0.35, 1.0, 0.62, 0.92)
