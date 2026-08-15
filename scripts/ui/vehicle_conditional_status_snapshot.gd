class_name VehicleConditionalStatusSnapshot
extends RefCounted

## Converts gameplay-owned conditional state into a compact, language-neutral
## HUD receipt. The HUD owns glyphs and layout, never card activation rules.

const MAX_VISIBLE := 5


static func build(
	overflow_level: int,
	barrier_strength: float,
	barrier_remaining: float,
	dash_level: int,
	dash_remaining: float,
	braced_level: int,
	braced_segments: int,
	braced_remaining: float,
	hit_level: int,
	hit_stacks: int,
	miss_level: int,
	miss_stacks: int,
	last_stand_level: int,
	last_stand_bonus: float
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	_append_if(rows, last_stand_level > 0 and last_stand_bonus > 0.0, &"last_stand", "+%d%%" % roundi(last_stand_bonus * 100.0))
	_append_if(rows, overflow_level > 0 and barrier_strength > 0.0 and barrier_remaining > 0.0, &"overflow_barrier", _seconds(barrier_remaining))
	_append_if(rows, dash_level > 0 and dash_remaining > 0.0, &"dash_overdrive", _seconds(dash_remaining))
	_append_if(rows, braced_level > 0 and braced_segments > 0 and braced_remaining > 0.0, &"braced_fire", "%d·%s" % [braced_segments, _seconds(braced_remaining)])
	_append_if(rows, hit_level > 0 and hit_stacks > 0, &"hit_chain", "×%d" % hit_stacks)
	_append_if(rows, miss_level > 0 and miss_stacks > 0, &"miss_compensation", "×%d" % miss_stacks)
	if rows.size() > MAX_VISIBLE:
		rows.resize(MAX_VISIBLE)
	return rows


static func _append_if(rows: Array[Dictionary], condition: bool, id: StringName, value: String) -> void:
	if condition:
		rows.append({"id":id, "value":value})


static func _seconds(value: float) -> String:
	return "%.1fs" % maxf(0.0, value)
