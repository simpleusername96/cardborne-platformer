class_name ArsenalTrialPickup
extends Area2D

signal collected(player: Node)

var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func is_collected() -> bool:
	return _collected


func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	set_deferred("monitoring", false)
	visible = false
	collected.emit(body)
