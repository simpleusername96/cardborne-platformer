class_name EnemyPressureZone3D
extends Area3D

const STARTUP := 0.65
const ACTIVE := 0.18

var elapsed := 0.0
var applied := false
var visual: MeshInstance3D


func _ready() -> void:
	add_to_group(&"combat_effects")
	collision_layer = 0
	collision_mask = 1 << 1
	var shape_node := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.65
	shape.height = 0.8
	shape_node.shape = shape
	add_child(shape_node)
	visual = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.65
	mesh.bottom_radius = 1.65
	mesh.height = 0.04
	mesh.radial_segments = 32
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.85, 0.40, 0.31, 0.28)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	visual.mesh = mesh
	add_child(visual)


func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= STARTUP and not applied:
		applied = true
		(visual.mesh.material as StandardMaterial3D).albedo_color = Color(0.94, 0.80, 0.42, 0.62)
		for body in get_overlapping_bodies():
			if body.has_method("apply_damage"):
				body.apply_damage(DamageRequest3D.new(18, 0, DamageRequest3D.Team.ENEMY, &"pressure_zone", false))
	if elapsed >= STARTUP + ACTIVE:
		queue_free()
