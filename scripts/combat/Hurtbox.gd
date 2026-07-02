class_name Hurtbox
extends Area2D

signal damaged(damage_info: DamageInfo)

@export var receiver_path: NodePath = NodePath("..")

@onready var receiver: Node = get_node_or_null(receiver_path)


func _ready() -> void:
	monitoring = true
	monitorable = true


func receive_damage(damage_info: DamageInfo) -> void:
	damaged.emit(damage_info)
	if receiver != null and receiver.has_method("receive_damage"):
		receiver.receive_damage(damage_info)
