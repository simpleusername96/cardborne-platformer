class_name Hitbox
extends Area2D

@export var damage_amount: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var tags: Array[String] = []
@export var starts_active: bool = false
@export var repeat_hits: bool = false

var active: bool = false
var _hit_targets: Dictionary = {}


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	set_active(starts_active)


func set_active(is_active: bool, reset_hits: bool = true) -> void:
	active = is_active
	monitoring = active
	if reset_hits:
		_hit_targets.clear()

	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not active


func _on_area_entered(area: Area2D) -> void:
	if not active or not area.has_method("receive_damage"):
		return

	var target_id := area.get_instance_id()
	if not repeat_hits and _hit_targets.has(target_id):
		return

	if not repeat_hits:
		_hit_targets[target_id] = true
	var damage_info := DamageInfo.new(damage_amount, self, knockback, tags)
	area.receive_damage(damage_info)
