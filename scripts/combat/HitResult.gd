class_name HitResult
extends RefCounted

var final_damage: int
var critical: bool
var stagger: int
var knockback: Vector2
var tags: Array[String]
var validation_errors: PackedStringArray


func _init(
	p_final_damage: int = 0,
	p_critical: bool = false,
	p_stagger: int = 0,
	p_knockback: Vector2 = Vector2.ZERO,
	p_tags: Array[String] = [],
	p_validation_errors: PackedStringArray = PackedStringArray()
) -> void:
	final_damage = p_final_damage
	critical = p_critical
	stagger = p_stagger
	knockback = p_knockback
	tags = p_tags.duplicate()
	validation_errors = p_validation_errors.duplicate()


func is_valid() -> bool:
	return validation_errors.is_empty()
