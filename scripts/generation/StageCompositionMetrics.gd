class_name StageCompositionMetrics
extends RefCounted

## Product-facing composition checks for the reviewed fixed stages. Geometry
## legality alone cannot prove that a route has enough vertical or combat rhythm.

const REFERENCE_VIEWPORT_HEIGHT := 720.0
const MEANINGFUL_ROUTE_DELTA := 64.0
const MULTI_ELEVATION_COMBAT_DELTA := 96.0
const MIN_MEANINGFUL_ELEVATION_CHANGES := 6
const MIN_MULTI_ELEVATION_COMBAT_ROOMS := 2
const MAX_CONSECUTIVE_EMPTY_REQUIRED_ROOMS := 2
const ENEMY_FLOORS := {
	&"ruin_approach": 8,
	&"flooded_works": 10,
	&"broken_sanctum": 12,
}


static func analyze(plan: StagePlan, assembly: StageAssemblyResult) -> Dictionary:
	if plan == null or assembly == null or not assembly.success:
		return {}
	var required_rooms := _required_rooms(plan)
	var hosts := assembly.get_room_hosts()
	var encounters_by_room := _encounters_by_required_room(plan, required_rooms)
	var route_tops: Array[float] = []
	var multi_elevation_rooms: Array[String] = []
	var combat_room_ids: Array[String] = []
	var enemy_count := 0
	var max_empty_run := 0
	var current_empty_run := 0
	var room_rows: Array[Dictionary] = []

	for room in required_rooms:
		var room_key := String(room.id)
		var host := hosts.get(room_key) as RoomTemplateHost
		var encounter_count := int(encounters_by_room.get(room_key, 0))
		enemy_count += encounter_count
		if encounter_count > 0:
			combat_room_ids.append(room_key)
			current_empty_run = 0
		else:
			current_empty_run += 1
			max_empty_run = maxi(max_empty_run, current_empty_run)

		var local_route_tops := _ordered_critical_support_tops(host)
		for local_top in local_route_tops:
			route_tops.append(local_top + host.position.y)
		var enemy_span := _planned_enemy_vertical_span(plan, room.id, host)
		if encounter_count >= 2 and enemy_span >= MULTI_ELEVATION_COMBAT_DELTA:
			multi_elevation_rooms.append(room_key)
		room_rows.append({
			"room_id": room_key,
			"route_index": room.route_index,
			"enemy_count": encounter_count,
			"enemy_vertical_span": enemy_span,
			"critical_support_count": local_route_tops.size(),
		})

	var min_top := 0.0
	var max_top := 0.0
	if not route_tops.is_empty():
		min_top = route_tops[0]
		max_top = route_tops[0]
		for top in route_tops:
			min_top = minf(min_top, top)
			max_top = maxf(max_top, top)
	var cumulative_ascent := 0.0
	var cumulative_descent := 0.0
	var meaningful_changes := 0
	for index in range(1, route_tops.size()):
		var delta := route_tops[index - 1] - route_tops[index]
		if delta > 0.0:
			cumulative_ascent += delta
		else:
			cumulative_descent += -delta
		if absf(delta) >= MEANINGFUL_ROUTE_DELTA:
			meaningful_changes += 1

	return {
		"stage_id": String(plan.profile_id),
		"critical_route_vertical_range": max_top - min_top,
		"critical_route_min_top": min_top,
		"critical_route_max_top": max_top,
		"cumulative_ascent": cumulative_ascent,
		"cumulative_descent": cumulative_descent,
		"meaningful_elevation_changes": meaningful_changes,
		"multi_elevation_combat_room_count": multi_elevation_rooms.size(),
		"multi_elevation_combat_rooms": multi_elevation_rooms,
		"actual_enemy_count": enemy_count,
		"combat_room_count": combat_room_ids.size(),
		"combat_rooms": combat_room_ids,
		"max_consecutive_empty_required_rooms": max_empty_run,
		"required_room_count": required_rooms.size(),
		"rooms": room_rows,
	}


static func validate_fixed_stage(
	plan: StagePlan,
	assembly: StageAssemblyResult
) -> PackedStringArray:
	var errors := PackedStringArray()
	var metrics := analyze(plan, assembly)
	if metrics.is_empty():
		errors.append("Stage composition validation needs a successful plan and assembly.")
		return errors
	var stage_id := StringName(metrics["stage_id"])
	if not ENEMY_FLOORS.has(stage_id):
		errors.append("Stage '%s' has no fixed composition contract." % stage_id)
		return errors
	var enemy_floor := int(ENEMY_FLOORS[stage_id])
	if int(metrics["actual_enemy_count"]) < enemy_floor:
		errors.append(
			"Stage '%s' has %d required-route enemies; minimum is %d."
			% [stage_id, metrics["actual_enemy_count"], enemy_floor]
		)
	if float(metrics["critical_route_vertical_range"]) < REFERENCE_VIEWPORT_HEIGHT:
		errors.append(
			"Stage '%s' vertical range is %.1f px; minimum is %.1f px."
			% [stage_id, metrics["critical_route_vertical_range"], REFERENCE_VIEWPORT_HEIGHT]
		)
	if int(metrics["meaningful_elevation_changes"]) < MIN_MEANINGFUL_ELEVATION_CHANGES:
		errors.append(
			"Stage '%s' has %d meaningful route elevation changes; minimum is %d."
			% [
				stage_id,
				metrics["meaningful_elevation_changes"],
				MIN_MEANINGFUL_ELEVATION_CHANGES,
			]
		)
	if (
		int(metrics["multi_elevation_combat_room_count"])
		< MIN_MULTI_ELEVATION_COMBAT_ROOMS
	):
		errors.append(
			"Stage '%s' has %d multi-elevation combat rooms; minimum is %d."
			% [
				stage_id,
				metrics["multi_elevation_combat_room_count"],
				MIN_MULTI_ELEVATION_COMBAT_ROOMS,
			]
		)
	if (
		int(metrics["max_consecutive_empty_required_rooms"])
		> MAX_CONSECUTIVE_EMPTY_REQUIRED_ROOMS
	):
		errors.append(
			"Stage '%s' has %d consecutive empty required rooms; maximum is %d."
			% [
				stage_id,
				metrics["max_consecutive_empty_required_rooms"],
				MAX_CONSECUTIVE_EMPTY_REQUIRED_ROOMS,
			]
		)
	return errors


static func _required_rooms(plan: StagePlan) -> Array[PlannedRoom]:
	var rooms: Array[PlannedRoom] = []
	for room in plan.get_rooms():
		if room.required_route:
			rooms.append(room)
	rooms.sort_custom(
		func(left: PlannedRoom, right: PlannedRoom) -> bool:
			return left.route_index < right.route_index
	)
	return rooms


static func _encounters_by_required_room(
	plan: StagePlan,
	required_rooms: Array[PlannedRoom]
) -> Dictionary:
	var required_ids := {}
	var counts := {}
	for room in required_rooms:
		required_ids[String(room.id)] = true
		counts[String(room.id)] = 0
	for encounter in plan.get_encounters():
		var room_key := String(encounter.room_id)
		if required_ids.has(room_key):
			counts[room_key] = int(counts[room_key]) + 1
	return counts


static func _ordered_critical_support_tops(host: RoomTemplateHost) -> Array[float]:
	var rows: Array[Dictionary] = []
	if host == null:
		return []
	for root_name in [&"Terrain", &"OneWay"]:
		var root := host.get_node_or_null(String(root_name))
		if root == null:
			continue
		for child in root.get_children():
			if not child is StaticBody2D or not bool(child.get_meta("critical", false)):
				continue
			rows.append({
				"x": child.position.x,
				"top": float(child.get_meta("support_top", child.position.y)),
			})
	rows.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return float(left["x"]) < float(right["x"])
	)
	var tops: Array[float] = []
	for row in rows:
		var top := float(row["top"])
		if tops.is_empty() or not is_equal_approx(tops[-1], top):
			tops.append(top)
	return tops


static func _planned_enemy_vertical_span(
	plan: StagePlan,
	room_id: StringName,
	host: RoomTemplateHost
) -> float:
	if host == null:
		return 0.0
	var min_y := INF
	var max_y := -INF
	var count := 0
	for encounter in plan.get_encounters():
		if encounter.room_id != room_id:
			continue
		var anchor := host.get_anchor_by_id(&"Enemy", encounter.anchor_id)
		if anchor == null:
			continue
		min_y = minf(min_y, anchor.position.y)
		max_y = maxf(max_y, anchor.position.y)
		count += 1
	return max_y - min_y if count >= 2 else 0.0
