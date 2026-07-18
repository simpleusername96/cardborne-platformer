class_name BossHazardZone3D
extends Area3D

var startup := 0.8
var active := 0.18
var damage := 20
var blockable := false
var elapsed := 0.0
var applied := false
var visual: MeshInstance3D


func configure(size: Vector2, startup_seconds: float, active_seconds: float, requested_damage: int, can_block: bool) -> void:
	startup = startup_seconds
	active = active_seconds
	damage = requested_damage
	blockable = can_block
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.8, size.y)
	collision.position.y = 0.4
	collision.shape = shape
	add_child(collision)
	visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.035, size.y)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.78, 0.30, 0.25, 0.25)
	mesh.material = material
	visual.mesh = mesh
	visual.position.y = 0.03
	add_child(visual)


func _ready() -> void:
	add_to_group(&"combat_effects")
	collision_layer = 0
	collision_mask = 1 << 1


func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= startup and not applied:
		applied = true
		(visual.mesh.material as StandardMaterial3D).albedo_color = Color(0.94, 0.77, 0.42, 0.68)
		for body in get_overlapping_bodies():
			if body.has_method("apply_damage"):
				body.apply_damage(DamageRequest3D.new(damage, 20, DamageRequest3D.Team.ENEMY, &"slime_king", blockable))
	if elapsed >= startup + active:
		queue_free()
