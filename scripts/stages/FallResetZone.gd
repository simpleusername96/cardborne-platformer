class_name FallResetZone
extends Area2D

@export var zone_size: Vector2 = Vector2(2000.0, 160.0)
@export var reason: String = "fall"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	body_entered.connect(_on_body_entered)
	_ensure_shape()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var active_stage := get_tree().get_first_node_in_group("active_stage")
	if active_stage != null and active_stage.has_method("reset_player_after_fall"):
		active_stage.reset_player_after_fall(reason)
	elif active_stage != null and active_stage.has_method("respawn_player"):
		active_stage.respawn_player(reason)


func _ensure_shape() -> void:
	if get_node_or_null("CollisionShape2D") != null:
		return

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)
