class_name DamageInfo
extends RefCounted

var amount: int
var source: Node
var knockback: Vector2
var tags: Array[String]


func _init(
	p_amount: int = 1,
	p_source: Node = null,
	p_knockback: Vector2 = Vector2.ZERO,
	p_tags: Array[String] = []
) -> void:
	amount = p_amount
	source = p_source
	knockback = p_knockback
	tags = p_tags.duplicate()
