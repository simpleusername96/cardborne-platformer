class_name VehicleExperienceShard
extends RefCounted

## Fixed-shape pooled field XP state.

var id := 0
var pos := Vector2.ZERO
var value := 0
var reward_sources: Array[StringName] = []


func configure(next_id: int, position: Vector2, amount: int, source: StringName) -> void:
	id = next_id
	pos = position
	value = amount
	reward_sources.clear()
	if source != &"":
		reward_sources.append(source)
