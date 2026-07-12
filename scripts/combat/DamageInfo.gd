class_name DamageInfo
extends RefCounted

var amount: int
var source: Node
var knockback: Vector2
var tags: Array[String]
var attack_id: StringName
var stagger: int
var critical: bool
var secondary_hit: bool


func _init(
	p_amount: int = 1,
	p_source: Node = null,
	p_knockback: Vector2 = Vector2.ZERO,
	p_tags: Array[String] = [],
	p_attack_id: StringName = &"",
	p_stagger: int = 0,
	p_critical: bool = false,
	p_secondary_hit: bool = false
) -> void:
	amount = p_amount
	source = p_source
	knockback = p_knockback
	tags = p_tags.duplicate()
	attack_id = p_attack_id
	stagger = maxi(p_stagger, 0)
	critical = p_critical
	secondary_hit = p_secondary_hit
