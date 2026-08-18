class_name VehicleExperienceShard
extends RefCounted

## Fixed-shape pooled field XP state.

var id := 0
var pos := Vector2.ZERO
var value := 0
var reward_sources: Array[StringName] = []
var authored := false
var published := true
var published_elapsed := 0.0


func configure(
	next_id: int, position: Vector2, amount: int, source: StringName,
	is_authored := false
) -> void:
	id = next_id
	pos = position
	value = amount
	authored = is_authored
	published = not authored
	published_elapsed = 0.0
	reward_sources.clear()
	if source != &"":
		reward_sources.append(source)
