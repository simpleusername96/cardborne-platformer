extends Node2D

@export var max_health: int = 3

var current_health: int

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	current_health = max_health


func receive_damage(damage_info: DamageInfo) -> void:
	current_health = maxi(current_health - damage_info.amount, 0)
	SignalBus.status_message_changed.emit("Dummy HP %d / %d" % [current_health, max_health])
	flash()
	if current_health <= 0:
		current_health = max_health
		SignalBus.status_message_changed.emit("Dummy reset")


func flash() -> void:
	if visual == null:
		return

	var original_color := visual.color
	visual.color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(visual):
		visual.color = original_color
