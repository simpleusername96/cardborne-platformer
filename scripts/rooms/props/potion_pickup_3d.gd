class_name PotionPickup3D
extends Area3D

signal collected(pickup: PotionPickup3D)

var was_collected := false


func _ready() -> void:
	add_to_group(&"room_pickups")
	collision_layer = 0
	collision_mask = 1 << 1
	body_entered.connect(_on_body_entered)


func restore_collected(value: bool) -> void:
	was_collected = value
	visible = not value
	monitoring = not value


func _on_body_entered(body: Node3D) -> void:
	if was_collected or not body is Traveler3D:
		return
	var traveler := body as Traveler3D
	if not traveler.add_potion_charge():
		traveler.action_traced.emit("Potion capacity full")
		return
	was_collected = true
	visible = false
	set_deferred("monitoring", false)
	collected.emit(self)
