class_name VehicleViewportSupplyPolicy
extends RefCounted

## Owns publication and off-screen retirement for persistent map pickups.

const SAFETY_MARGIN := 240.0
const RETIRE_SECONDS := 60.0


static func refresh_pickups(
	pickups: Array[Dictionary],
	anchors: Array[Vector2],
	visible_world: Rect2,
	player_position: Vector2,
	delta: float
) -> void:
	refresh_direct_items(pickups, [], anchors, visible_world, player_position, delta)


static func refresh_direct_items(
	pickups: Array[Dictionary],
	shards: Array,
	anchors: Array[Vector2],
	visible_world: Rect2,
	player_position: Vector2,
	delta: float
) -> void:
	var expanded := visible_world.grow(SAFETY_MARGIN)
	var candidates: Array = []
	for pickup in pickups:
		if bool(pickup.get("active", false)):
			candidates.append(pickup)
	for shard in shards:
		if bool(shard.authored):
			candidates.append(shard)
	var selected: Variant = null
	var selected_distance := INF
	for candidate in candidates:
		var position := _position(candidate)
		if _published(candidate) and visible_world.has_point(position):
			var distance := player_position.distance_squared_to(position)
			if distance < selected_distance:
				selected = candidate
				selected_distance = distance
	if selected == null:
		for candidate in candidates:
			var distance := player_position.distance_squared_to(_position(candidate))
			if distance < selected_distance:
				selected = candidate
				selected_distance = distance
	for candidate in candidates:
		var should_publish: bool = is_same(candidate, selected)
		_set_published(candidate, should_publish)
		if not should_publish:
			_set_elapsed(candidate, 0.0)
			continue
		_set_elapsed(candidate, _elapsed(candidate) + maxf(0.0, delta))
		if (
			_elapsed(candidate) >= RETIRE_SECONDS
			and not expanded.has_point(_position(candidate))
		):
			if _relocate_outside(candidate, candidates, anchors, expanded, player_position):
				_set_elapsed(candidate, 0.0)
			else:
				_set_published(candidate, false)


static func _relocate_outside(
	item: Variant,
	items: Array,
	anchors: Array[Vector2],
	expanded: Rect2,
	player_position: Vector2
) -> bool:
	var current := _position(item)
	var best := Vector2.ZERO
	var best_distance := INF
	var found := false
	for anchor in anchors:
		if anchor.is_equal_approx(current) or expanded.has_point(anchor):
			continue
		var occupied := false
		for other in items:
			if other != item and _position(other).distance_to(anchor) < 1.0:
				occupied = true
				break
		if occupied:
			continue
		var distance := player_position.distance_squared_to(anchor)
		if distance < best_distance:
			best = anchor
			best_distance = distance
			found = true
	if found:
		_set_position(item, best)
	return found


static func _position(item: Variant) -> Vector2:
	return Vector2(item["pos"]) if item is Dictionary else Vector2(item.pos)


static func _set_position(item: Variant, value: Vector2) -> void:
	if item is Dictionary:
		item["pos"] = value
	else:
		item.pos = value


static func _published(item: Variant) -> bool:
	return bool(item.get("published", false)) if item is Dictionary else bool(item.published)


static func _set_published(item: Variant, value: bool) -> void:
	if item is Dictionary:
		item["published"] = value
	else:
		item.published = value


static func _elapsed(item: Variant) -> float:
	return float(item.get("published_elapsed", 0.0)) if item is Dictionary else float(item.published_elapsed)


static func _set_elapsed(item: Variant, value: float) -> void:
	if item is Dictionary:
		item["published_elapsed"] = value
	else:
		item.published_elapsed = value
