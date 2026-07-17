class_name ProofProjectile3D
extends Area3D

const SPEED := 18.0

var direction := Vector3.FORWARD
var lifetime := 0.0


func _ready() -> void:
	collision_layer = 1 << 5
	collision_mask = (1 << 0) | (1 << 2)
	monitoring = true
	body_entered.connect(_on_body_entered)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.16
	collision.shape = shape
	add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("d4a33f")
	material.emission_enabled = true
	material.emission = Color("d4a33f")
	material.emission_energy_multiplier = 1.8
	mesh_instance.material_override = material
	add_child(mesh_instance)


func configure(origin: Vector3, requested_direction: Vector3) -> void:
	global_position = origin
	direction = requested_direction.normalized()


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	lifetime += delta
	if lifetime >= 1.4:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("receive_hit"):
		body.receive_hit(16, 8, &"ranged")
	queue_free()
