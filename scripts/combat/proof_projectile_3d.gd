class_name ProofProjectile3D
extends Area3D

const SPEED := 18.0
const PROJECTILE_TEXTURE := preload(
	"res://art/world/flooded_works/isometric/effects/traveler-ranged-bolt-v1.png"
)

var direction := Vector3.FORWARD
var lifetime := 0.0
var visual: Sprite3D


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

	visual = Sprite3D.new()
	visual.name = "RasterBolt"
	visual.texture = PROJECTILE_TEXTURE
	visual.pixel_size = 0.003
	visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	visual.no_depth_test = true
	add_child(visual)


func configure(origin: Vector3, requested_direction: Vector3) -> void:
	global_position = origin
	direction = requested_direction.normalized()
	_update_visual_rotation()


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	_update_visual_rotation()
	lifetime += delta
	if lifetime >= 1.4:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("receive_hit"):
		body.receive_hit(16, 8, &"ranged")
	queue_free()


func _update_visual_rotation() -> void:
	if visual == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen_x := direction.dot(camera.global_basis.x)
	var screen_y := direction.dot(camera.global_basis.y)
	visual.rotation.z = atan2(screen_y, screen_x)
