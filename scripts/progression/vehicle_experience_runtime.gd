class_name VehicleExperienceRuntime
extends RefCounted

## Run-scoped XP ownership, including capped geometric shards and queued levels.

const MAX_SHARDS := 192
const BASE_PICKUP_RADIUS := 34.0
const ATTRACT_SPEED := 520.0

var run_level := 1
var experience := 0
var pending_level_ups := 0
var shards: Array[Dictionary] = []
var _next_shard_id := 1


func reset() -> void:
	run_level = 1
	experience = 0
	pending_level_ups = 0
	shards.clear()
	_next_shard_id = 1


func required_experience() -> int:
	return mini(72, 26 + 3 * (run_level - 1))


func spawn_shard(position: Vector2, value: int, reward_source: StringName = &"") -> void:
	if value <= 0:
		return
	var reward_sources: Array[StringName] = []
	if reward_source != &"":
		reward_sources.append(reward_source)
	if shards.size() >= MAX_SHARDS:
		var merge_index := _nearest_shard_index(position)
		shards[merge_index]["value"] = int(shards[merge_index]["value"]) + value
		for source in reward_sources:
			if source not in shards[merge_index]["reward_sources"]:
				shards[merge_index]["reward_sources"].append(source)
		return
	shards.append({
		"id":_next_shard_id, "pos":position, "value":value,
		"reward_sources":reward_sources, "pulse":0.0,
	})
	_next_shard_id += 1


func spawn_cluster(position: Vector2, total_value: int, reward_source: StringName = &"") -> void:
	var count := clampi(ceili(float(total_value) / 5.0), 3, 8)
	var remaining := total_value
	for index in count:
		var value := ceili(float(remaining) / float(count - index))
		var angle := TAU * float(index) / float(count)
		spawn_shard(position + Vector2.RIGHT.rotated(angle) * (22.0 + 9.0 * float(index % 2)), value, reward_source if index == 0 else &"")
		remaining -= value


func advance(delta: float, player_position: Vector2, attraction_radius: float, recall_active: bool) -> Dictionary:
	var collected_xp := 0
	var collected_sources: Array[StringName] = []
	var attraction_radius_squared := attraction_radius * attraction_radius
	var collection_radius_squared := BASE_PICKUP_RADIUS * BASE_PICKUP_RADIUS
	for index in range(shards.size() - 1, -1, -1):
		var shard := shards[index]
		shard["pulse"] = fmod(float(shard["pulse"]) + delta, 1.0)
		var position := Vector2(shard["pos"])
		var distance_squared := position.distance_squared_to(player_position)
		if recall_active or distance_squared <= attraction_radius_squared:
			var distance := sqrt(distance_squared)
			var speed := maxf(ATTRACT_SPEED, distance / 0.22) if recall_active else ATTRACT_SPEED
			position = position.move_toward(player_position, speed * delta)
			shard["pos"] = position
			distance_squared = position.distance_squared_to(player_position)
		if distance_squared > collection_radius_squared:
			continue
		collected_xp += int(shard["value"])
		for source in shard["reward_sources"]:
			if source not in collected_sources:
				collected_sources.append(source)
		shards.remove_at(index)
	var levels_gained := _award_experience(collected_xp)
	return {"experience":collected_xp, "levels":levels_gained, "reward_sources":collected_sources}


func _award_experience(value: int) -> int:
	if value <= 0:
		return 0
	experience += value
	var gained := 0
	while experience >= required_experience():
		experience -= required_experience()
		run_level += 1
		pending_level_ups += 1
		gained += 1
	return gained


func consume_pending_level() -> bool:
	if pending_level_ups <= 0:
		return false
	pending_level_ups -= 1
	return true


func snapshot() -> Dictionary:
	return {
		"level":run_level, "experience":experience, "required":required_experience(),
		"pending_levels":pending_level_ups, "shard_count":shards.size(),
	}


func total_uncollected_experience() -> int:
	var total := 0
	for shard in shards:
		total += int(shard["value"])
	return total


func _nearest_shard_index(position: Vector2) -> int:
	var best_index := 0
	var best_distance := INF
	for index in shards.size():
		var distance := position.distance_squared_to(Vector2(shards[index]["pos"]))
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index
