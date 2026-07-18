class_name WaterloggedCrate3D
extends StaticBody3D

signal broken(crate: WaterloggedCrate3D)

const MAX_HEALTH := 20

@export var drop_id: StringName

var health := MAX_HEALTH
var is_broken := false

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var visual: MeshInstance3D = $Visual


func _ready() -> void:
	collision_layer = (1 << 0) | (1 << 2)
	collision_mask = 0


func apply_damage(request: DamageRequest3D) -> DamageResult3D:
	if is_broken or request.team != DamageRequest3D.Team.PLAYER:
		return DamageResult3D.rejected()
	health = maxi(0, health - request.damage)
	if health <= 0:
		_break_once()
	return DamageResult3D.applied(request.damage, request.stagger, is_broken)


func is_targetable() -> bool:
	return false


func restore_broken(value: bool) -> void:
	is_broken = value
	health = 0 if value else MAX_HEALTH
	visual.visible = not value
	collision.disabled = value


func _break_once() -> void:
	if is_broken:
		return
	is_broken = true
	visual.visible = false
	collision.set_deferred("disabled", true)
	broken.emit(self)
