class_name BossPatternSchedule
extends RefCounted

var patterns: Array[BossPatternDefinition]
var neutral_between_patterns: float
var neutral_after: float
var spawned_add_counts: PackedInt32Array


func _init(
	p_patterns: Array[BossPatternDefinition] = [],
	p_neutral_between_patterns: float = 0.0,
	p_neutral_after: float = 0.0,
	p_spawned_add_counts: PackedInt32Array = PackedInt32Array()
) -> void:
	patterns = p_patterns.duplicate()
	neutral_between_patterns = p_neutral_between_patterns
	neutral_after = p_neutral_after
	spawned_add_counts = p_spawned_add_counts.duplicate()


func is_chain() -> bool:
	return patterns.size() > 1


func pattern_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for pattern in patterns:
		ids.append(pattern.id)
	return ids


func spawned_add_count_for(pattern_index: int) -> int:
	if pattern_index < 0 or pattern_index >= spawned_add_counts.size():
		return 0
	return spawned_add_counts[pattern_index]


func total_duration() -> float:
	var duration := neutral_between_patterns + neutral_after
	for pattern in patterns:
		duration += pattern.action_duration()
	return duration


func signature() -> String:
	var spawn_values: Array[String] = []
	for spawn_count in spawned_add_counts:
		spawn_values.append(str(spawn_count))
	return "%s|%.3f|%.3f|%s" % [
		",".join(pattern_ids()),
		neutral_between_patterns,
		neutral_after,
		",".join(spawn_values),
	]
