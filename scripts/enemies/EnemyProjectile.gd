class_name EnemyProjectile
extends Hitbox

signal terrain_hit(body: PhysicsBody2D)

@export var projectile_size: Vector2 = Vector2(28.0, 14.0)
@export var projectile_color: Color = Color(0.95, 0.74, 0.24, 0.95)
@export var lifetime: float = 2.4

var velocity: Vector2 = Vector2.ZERO
var _life_timer: float = 0.0


func _ready() -> void:
	collision_layer = 32
	# Solid authored terrain (layer 1) blocks basic projectiles. One-way
	# traversal surfaces (layer 2) remain permeable unless promoted to solid cover.
	collision_mask = 5
	starts_active = true
	repeat_hits = false
	tags = ["enemy_projectile"]
	_life_timer = lifetime
	_ensure_shape_and_visual()
	body_entered.connect(_on_body_entered)
	super._ready()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = projectile_size
		shape.shape = rect
		add_child(shape)

	if get_node_or_null("Visual") == null:
		var visual := Polygon2D.new()
		visual.name = "Visual"
		visual.color = projectile_color
		var half := projectile_size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x + 7.0, 0.0),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		add_child(visual)


func _on_body_entered(body: Node2D) -> void:
	if not active or not body is PhysicsBody2D:
		return
	var physics_body := body as PhysicsBody2D
	if (physics_body.collision_layer & 1) == 0:
		return
	terrain_hit.emit(physics_body)
	set_active(false)
	queue_free()
