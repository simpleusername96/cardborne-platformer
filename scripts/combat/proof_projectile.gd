class_name ProofProjectile
extends Area2D

var direction := Vector2.RIGHT
var speed := 720.0
var damage := 16
var stagger := 8
var source_id: StringName = &"traveler_ranged"
var _lifetime := 0.0


func _ready() -> void:
	collision_layer = 1 << 5
	collision_mask = (1 << 0) | (1 << 2)
	monitoring = true
	body_entered.connect(_on_body_entered)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func configure(origin: Vector2, aim: Vector2, definition: AttackDefinition) -> void:
	global_position = origin
	direction = aim.normalized()
	speed = definition.projectile_speed
	damage = definition.damage
	stagger = definition.stagger
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= 1.8:
		queue_free()


func _draw() -> void:
	draw_polygon(PackedVector2Array([Vector2(13, 0), Vector2(-7, -5), Vector2(-3, 0), Vector2(-7, 5)]), PackedColorArray([Color("d4a33f")]))
	draw_line(Vector2(-4, 0), Vector2(-18, 0), Color("62a9b5"), 3.0)


func _on_body_entered(body: Node) -> void:
	if body.has_method("receive_hit"):
		body.receive_hit(damage, stagger, source_id)
	queue_free()
