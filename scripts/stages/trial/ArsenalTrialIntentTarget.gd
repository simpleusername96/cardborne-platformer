class_name ArsenalTrialIntentTarget
extends Node2D

signal intent_confirmed(mode: StringName)

@export_enum("melee", "ranged") var expected_mode: String = "melee"

var current_health: int = 1
var _confirmed: bool = false

@onready var _visual: CanvasItem = get_node("Visual") as CanvasItem
@onready var _label: Label = get_node("Label") as Label


func _ready() -> void:
	add_to_group("enemies")


func receive_damage(_damage_info: DamageInfo) -> void:
	# No hurtbox is authored: the trial reads the committed intent without applying wear.
	pass


func get_intent_target_id() -> StringName:
	return StringName(str(get_instance_id()))


func is_confirmed() -> bool:
	return _confirmed


func confirm_intent(mode: StringName) -> bool:
	if _confirmed or String(mode) != expected_mode:
		return false
	_confirmed = true
	current_health = 0
	remove_from_group("enemies")
	_visual.modulate = Color(0.45, 1.0, 0.70, 0.72)
	_label.text = "CLEAR"
	intent_confirmed.emit(mode)
	return true
