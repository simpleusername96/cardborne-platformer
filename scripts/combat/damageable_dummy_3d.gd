class_name DamageableDummy3D
extends StaticBody3D

const MAX_HEALTH := 120

var health := MAX_HEALTH
var reset_remaining := 0.0

@onready var health_fill: MeshInstance3D = $HealthFill


func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask = 0
	_update_health_fill()


func _process(delta: float) -> void:
	if reset_remaining > 0.0:
		reset_remaining -= delta
		if reset_remaining <= 0.0:
			reset_dummy()


func receive_hit(damage: int, _stagger: int, _source_id: StringName) -> void:
	if health <= 0:
		return
	health = maxi(0, health - damage)
	_update_health_fill()
	if health <= 0:
		reset_remaining = 1.0


func reset_dummy() -> void:
	health = MAX_HEALTH
	reset_remaining = 0.0
	_update_health_fill()


func _update_health_fill() -> void:
	var ratio := float(health) / float(MAX_HEALTH)
	health_fill.scale.x = ratio
	health_fill.position.x = -0.6 * (1.0 - ratio)
