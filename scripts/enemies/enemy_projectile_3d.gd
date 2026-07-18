class_name EnemyProjectile3D
extends Area3D

const SPEED := 10.5

var direction := Vector3.FORWARD
var lifetime := 0.0


func _ready() -> void:
	add_to_group(&"combat_projectiles")
	collision_layer = 1 << 5
	collision_mask = (1 << 0) | (1 << 1)
	body_entered.connect(_on_body_entered)


func configure(origin: Vector3, target: Vector3) -> void:
	global_position = origin
	direction = (target - origin).normalized()
	direction.y = 0.0


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	lifetime += delta
	if lifetime >= 2.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		body.apply_damage(DamageRequest3D.new(14, 10, DamageRequest3D.Team.ENEMY, &"foundry_bolt"))
	queue_free()
