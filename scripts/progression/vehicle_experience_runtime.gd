class_name VehicleExperienceRuntime
extends RefCounted

## Run-scoped XP ownership, including capped geometric shards and queued levels.

const MAX_SHARDS := 192
const BASE_PICKUP_RADIUS := 34.0
const ATTRACT_SPEED := 520.0
const EARLY_LEVEL_REQUIREMENTS: Array[int] = [14, 16, 18, 21, 25]
const SMOOTH_GROWTH_BASE := 25.0
const SMOOTH_LINEAR_GROWTH := 5.0
const SMOOTH_QUADRATIC_GROWTH := 0.31
const MAX_LEVEL_REQUIREMENT := 1536
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")

var run_level := 1
var experience := 0
var pending_level_ups := 0
var progression_complete := false
var shards: Array[ExperienceShard] = []
var _next_shard_id := 1
var _pool: Array[ExperienceShard] = []
var _advance_receipt: Dictionary = {}
var _collected_sources: Array[StringName] = []


func _init() -> void:
	for _index in MAX_SHARDS:
		_pool.append(ExperienceShard.new())
	_advance_receipt = {
		"experience":0,
		"levels":0,
		"reward_sources":_collected_sources,
	}


func reset() -> void:
	run_level = 1
	experience = 0
	pending_level_ups = 0
	progression_complete = false
	clear_shards()
	_next_shard_id = 1


func clear_shards() -> void:
	while not shards.is_empty():
		_pool.append(shards.pop_back())


func required_experience() -> int:
	if run_level <= EARLY_LEVEL_REQUIREMENTS.size():
		return EARLY_LEVEL_REQUIREMENTS[run_level - 1]
	var levels_after_early := float(run_level - EARLY_LEVEL_REQUIREMENTS.size())
	return mini(MAX_LEVEL_REQUIREMENT, roundi(
		SMOOTH_GROWTH_BASE
		+ SMOOTH_LINEAR_GROWTH * levels_after_early
		+ SMOOTH_QUADRATIC_GROWTH * levels_after_early * levels_after_early
	))


func spawn_shard(
	position: Vector2, value: int, reward_source: StringName = &"",
	authored := false
) -> void:
	if progression_complete or value <= 0:
		return
	if shards.size() >= MAX_SHARDS:
		var merge_index := _nearest_shard_index(position)
		shards[merge_index].value += value
		if reward_source != &"" and reward_source not in shards[merge_index].reward_sources:
			shards[merge_index].reward_sources.append(reward_source)
		return
	var shard: ExperienceShard = _pool.pop_back()
	shard.configure(_next_shard_id, position, value, reward_source, authored)
	shards.append(shard)
	_next_shard_id += 1


func spawn_cluster(position: Vector2, total_value: int, reward_source: StringName = &"") -> void:
	if progression_complete or total_value <= 0:
		return
	var count := clampi(ceili(float(total_value) / 5.0), 3, 8)
	var remaining := total_value
	for index in count:
		var value := ceili(float(remaining) / float(count - index))
		var angle := TAU * float(index) / float(count)
		spawn_shard(position + Vector2.RIGHT.rotated(angle) * (22.0 + 9.0 * float(index % 2)), value, reward_source if index == 0 else &"")
		remaining -= value


func advance(
	delta: float,
	player_position: Vector2,
	attraction_radius: float,
	recall_remaining: float
) -> Dictionary:
	var collected_xp := 0
	_collected_sources.clear()
	_advance_receipt.clear()
	_advance_receipt["experience"] = 0
	_advance_receipt["levels"] = 0
	_advance_receipt["reward_sources"] = _collected_sources
	if progression_complete:
		return _advance_receipt
	var attraction_radius_squared := attraction_radius * attraction_radius
	var collection_radius_squared := BASE_PICKUP_RADIUS * BASE_PICKUP_RADIUS
	var recall_active := recall_remaining > 0.0
	var index := 0
	while index < shards.size():
		var shard: ExperienceShard = shards[index]
		if shard.authored and not shard.published:
			index += 1
			continue
		var position := shard.pos
		var distance_squared := position.distance_squared_to(player_position)
		if recall_active or distance_squared <= attraction_radius_squared:
			var distance := sqrt(distance_squared)
			var travel_time := maxf(delta, recall_remaining)
			var speed := (
				maxf(ATTRACT_SPEED, distance / maxf(travel_time, 0.0001))
				if recall_active
				else ATTRACT_SPEED
			)
			position = position.move_toward(player_position, speed * delta)
			shard.pos = position
			distance_squared = position.distance_squared_to(player_position)
		if distance_squared > collection_radius_squared:
			index += 1
			continue
		collected_xp += shard.value
		for source in shard.reward_sources:
			if source not in _collected_sources:
				_collected_sources.append(source)
		_swap_remove(index)
	var levels_gained := _award_experience(collected_xp)
	_advance_receipt["experience"] = collected_xp
	_advance_receipt["levels"] = levels_gained
	return _advance_receipt


func _swap_remove(index: int) -> void:
	var retired: ExperienceShard = shards[index]
	var last_index := shards.size() - 1
	if index != last_index:
		shards[index] = shards[last_index]
	shards.pop_back()
	_pool.append(retired)


func _award_experience(value: int) -> int:
	if progression_complete or value <= 0:
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


func clear_pending_levels() -> void:
	pending_level_ups = 0


## Ends run progression only after the catalog proves that no compatible card
## remains. Gameplay can keep calling the normal XP paths without creating
## hidden shards or queued rewards after this point.
func complete_progression() -> bool:
	if progression_complete:
		return false
	progression_complete = true
	experience = 0
	clear_pending_levels()
	clear_shards()
	return true


func snapshot() -> Dictionary:
	var authored_published := 0
	for shard in shards:
		if shard.authored and shard.published:
			authored_published += 1
	return {
		"level":run_level, "experience":experience, "required":required_experience(),
		"pending_levels":pending_level_ups, "shard_count":shards.size(),
		"authored_published_count":authored_published,
		"shard_pool":_pool.size(), "complete":progression_complete,
	}


func validate_capacity() -> bool:
	return shards.size() + _pool.size() == MAX_SHARDS


func total_uncollected_experience() -> int:
	var total := 0
	for shard in shards:
		total += shard.value
	return total


func _nearest_shard_index(position: Vector2) -> int:
	var best_index := 0
	var best_distance := INF
	for index in shards.size():
		var distance := position.distance_squared_to(shards[index].pos)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index
