class_name DestructibleObstacle
extends Node2D

@export var max_health: int = 3
@export var obstacle_size: Vector2 = Vector2(54.0, 86.0)

var current_health: int

var _solid: StaticBody2D
var _visual: Polygon2D


func _ready() -> void:
	current_health = max_health
	_ensure_body()
	_ensure_hurtbox()


func receive_damage(damage_info: DamageInfo) -> void:
	if current_health <= 0:
		return

	current_health = maxi(current_health - damage_info.amount, 0)
	SignalBus.status_message_changed.emit("%s HP %d / %d" % [name, current_health, max_health])
	_flash()
	if current_health <= 0:
		_destroy()


func _ensure_body() -> void:
	_solid = get_node_or_null("Solid") as StaticBody2D
	if _solid == null:
		_solid = StaticBody2D.new()
		_solid.name = "Solid"
		_solid.collision_layer = 1
		_solid.collision_mask = 0
		add_child(_solid)

	if _solid.get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = obstacle_size
		shape.position = Vector2(0.0, -obstacle_size.y * 0.5)
		shape.shape = rect
		_solid.add_child(shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = Color(0.66, 0.46, 0.24, 1.0)
		var half_x := obstacle_size.x * 0.5
		_visual.polygon = PackedVector2Array([
			Vector2(-half_x, -obstacle_size.y),
			Vector2(half_x, -obstacle_size.y),
			Vector2(half_x, 0.0),
			Vector2(-half_x, 0.0)
		])
		add_child(_visual)


func _ensure_hurtbox() -> void:
	if get_node_or_null("Hurtbox") != null:
		return

	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.position = Vector2(0.0, -obstacle_size.y * 0.5)
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 16
	hurtbox.receiver_path = NodePath("..")
	add_child(hurtbox)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = obstacle_size
	shape.shape = rect
	hurtbox.add_child(shape)


func _destroy() -> void:
	SignalBus.status_message_changed.emit("%s destroyed: route opened" % name)
	if _solid != null:
		_solid.collision_layer = 0
		_solid.collision_mask = 0
		for child in _solid.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	if _visual != null:
		_visual.color = Color(0.36, 0.29, 0.22, 0.35)
		_visual.scale.y = 0.18

	for child in get_children():
		if child is Hurtbox:
			var hurtbox := child as Hurtbox
			hurtbox.set_deferred("monitorable", false)
			hurtbox.set_deferred("monitoring", false)


func _flash() -> void:
	if _visual == null:
		return

	var original_color := _visual.color
	_visual.color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_visual) and current_health > 0:
		_visual.color = original_color
