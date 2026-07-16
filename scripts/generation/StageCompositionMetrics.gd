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


static func analyze(
	plan: StagePlan,
	assembly: StageAssemblyResult,
	movement_limits: Dictionary = {}
) -> Dictionary:
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
	var meaningful_ascent_transitions := 0
	var meaningful_descent_transitions := 0
	var direction_reversals := 0
	var previous_direction := 0
	for index in range(1, route_tops.size()):
		var delta := route_tops[index - 1] - route_tops[index]
		if delta > 0.0:
			cumulative_ascent += delta
		else:
			cumulative_descent += -delta
		if absf(delta) >= MEANINGFUL_ROUTE_DELTA:
			meaningful_changes += 1
			var direction := 1 if delta > 0.0 else -1
			if direction > 0:
				meaningful_ascent_transitions += 1
			else:
				meaningful_descent_transitions += 1
			if previous_direction != 0 and previous_direction != direction:
				direction_reversals += 1
			previous_direction = direction
	var optional_diagnostics := _optional_branch_diagnostics(plan, required_rooms)
	var transition_diagnostics := _required_transition_diagnostics(
		required_rooms,
		hosts,
		movement_limits
	)

	return {
		"stage_id": String(plan.profile_id),
		"critical_route_vertical_range": max_top - min_top,
		"critical_route_min_top": min_top,
		"critical_route_max_top": max_top,
		"cumulative_ascent": cumulative_ascent,
		"cumulative_descent": cumulative_descent,
		"meaningful_elevation_changes": meaningful_changes,
		"meaningful_ascent_transitions": meaningful_ascent_transitions,
		"meaningful_descent_transitions": meaningful_descent_transitions,
		"direction_reversals": direction_reversals,
		"multi_elevation_combat_room_count": multi_elevation_rooms.size(),
		"multi_elevation_combat_rooms": multi_elevation_rooms,
		"actual_enemy_count": enemy_count,
		"combat_room_count": combat_room_ids.size(),
		"combat_rooms": combat_room_ids,
		"max_consecutive_empty_required_rooms": max_empty_run,
		"required_room_count": required_rooms.size(),
		"optional_branch_count": int(optional_diagnostics["branches"].size()),
		"same_hub_return_count": optional_diagnostics["same_hub_return_count"],
		"forward_rejoin_count": optional_diagnostics["forward_rejoin_count"],
		"optional_branches": optional_diagnostics["branches"],
		"required_transition_count": transition_diagnostics["transitions"].size(),
		"required_transitions": transition_diagnostics["transitions"],
		"near_limit_required_transition_count": (
			transition_diagnostics["near_limit_ids"].size()
		),
		"near_limit_required_transition_ids": transition_diagnostics["near_limit_ids"],
		"max_near_limit_chain": transition_diagnostics["max_near_limit_chain"],
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


static func validate_target_structure(
	plan: StagePlan,
	assembly: StageAssemblyResult
) -> PackedStringArray:
	var errors := PackedStringArray()
	var metrics := analyze(plan, assembly)
	if metrics.is_empty():
		errors.append("Target structure validation needs a successful plan and assembly.")
		return errors
	var stage_id := StringName(metrics["stage_id"])
	var expected_optional: int = {
		&"ruin_approach": 1,
		&"flooded_works": 1,
		&"broken_sanctum": 2,
	}.get(stage_id, -1)
	if expected_optional < 0:
		errors.append("Stage '%s' has no target structure contract." % stage_id)
		return errors
	if int(metrics["forward_rejoin_count"]) != expected_optional:
		errors.append(
			"Stage '%s' has %d forward optional rejoins; expected %d."
			% [stage_id, metrics["forward_rejoin_count"], expected_optional]
		)
	if int(metrics["same_hub_return_count"]) > 0:
		errors.append(
			"Stage '%s' still has %d same-hub optional returns; expected 0."
			% [stage_id, metrics["same_hub_return_count"]]
		)
	match stage_id:
		&"ruin_approach":
			if int(metrics["meaningful_descent_transitions"]) < 2:
				errors.append(
					"Stage 'ruin_approach' has %d meaningful descents; expected at least 2."
					% metrics["meaningful_descent_transitions"]
				)
			if int(metrics["direction_reversals"]) < 2:
				errors.append(
					"Stage 'ruin_approach' has %d direction reversals; expected at least 2."
					% metrics["direction_reversals"]
				)
		&"flooded_works":
			if int(metrics["meaningful_descent_transitions"]) < 3:
				errors.append(
					"Stage 'flooded_works' has %d meaningful descents; expected at least 3."
					% metrics["meaningful_descent_transitions"]
				)
			if int(metrics["meaningful_ascent_transitions"]) < 3:
				errors.append(
					"Stage 'flooded_works' has %d meaningful ascents; expected at least 3."
					% metrics["meaningful_ascent_transitions"]
				)
		&"broken_sanctum":
			var branches := metrics["optional_branches"] as Array
			var origin_indices: Array[int] = []
			for branch_value in branches:
				origin_indices.append(int((branch_value as Dictionary)["origin_route_index"]))
			origin_indices.sort()
			if origin_indices.size() != 2 or origin_indices[0] > 3 or origin_indices[1] < 6:
				errors.append(
					"Stage 'broken_sanctum' optional origins are %s; expected one early and one late."
					% origin_indices
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
	var tops: Array[float] = []
	for row in _ordered_critical_support_rows(host):
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


static func _optional_branch_diagnostics(
	plan: StagePlan,
	required_rooms: Array[PlannedRoom]
) -> Dictionary:
	var branches: Array[Dictionary] = []
	var same_hub_return_count := 0
	var forward_rejoin_count := 0
	for room in plan.get_rooms():
		if room.required_route:
			continue
		var incoming: PlannedConnection
		var outgoing: PlannedConnection
		for connection in plan.get_connections():
			if connection.route_role == &"optional" and connection.to_room_id == room.id:
				incoming = connection
			elif connection.route_role == &"return" and connection.from_room_id == room.id:
				outgoing = connection
		if incoming == null or outgoing == null:
			continue
		var origin_index := _required_index(required_rooms, incoming.from_room_id)
		var rejoin_index := _required_index(required_rooms, outgoing.to_room_id)
		var same_hub := origin_index >= 0 and origin_index == rejoin_index
		var forward_rejoin := origin_index >= 0 and rejoin_index > origin_index
		if same_hub:
			same_hub_return_count += 1
		if forward_rejoin:
			forward_rejoin_count += 1
		branches.append({
			"room_id": String(room.id),
			"origin_room_id": String(incoming.from_room_id),
			"rejoin_room_id": String(outgoing.to_room_id),
			"origin_route_index": origin_index,
			"rejoin_route_index": rejoin_index,
			"divergence_span": rejoin_index - origin_index,
			"stage_position": (
				float(origin_index) / float(maxi(required_rooms.size() - 1, 1))
				if origin_index >= 0
				else -1.0
			),
			"same_hub_return": same_hub,
			"forward_rejoin": forward_rejoin,
		})
	branches.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return String(left["room_id"]) < String(right["room_id"])
	)
	return {
		"branches": branches,
		"same_hub_return_count": same_hub_return_count,
		"forward_rejoin_count": forward_rejoin_count,
	}


static func _required_index(
	required_rooms: Array[PlannedRoom],
	room_id: StringName
) -> int:
	for index in required_rooms.size():
		if required_rooms[index].id == room_id:
			return index
	return -1


static func _required_transition_diagnostics(
	required_rooms: Array[PlannedRoom],
	hosts: Dictionary,
	movement_limits: Dictionary
) -> Dictionary:
	var transitions: Array[Dictionary] = []
	var near_limit_ids: Array[String] = []
	var max_near_limit_chain := 0
	var current_chain := 0
	var least_metrics := movement_limits.get("least_metrics", {}) as Dictionary
	var theoretical_gap := float(least_metrics.get(
		"route_reach",
		movement_limits.get("max_required_gap", 0.0)
	))
	var theoretical_ledge := float(least_metrics.get(
		"route_ledge_height",
		movement_limits.get("max_required_ledge", 0.0)
	))
	for room in required_rooms:
		var host := hosts.get(String(room.id)) as RoomTemplateHost
		var rows := _ordered_critical_support_rows(host)
		current_chain = 0
		for index in range(1, rows.size()):
			var previous := rows[index - 1] as Dictionary
			var current := rows[index] as Dictionary
			var gap := maxf(
				float(current["x"])
				- (float(previous["x"]) + float(previous["width"])),
				0.0
			)
			var rise := maxf(float(previous["top"]) - float(current["top"]), 0.0)
			var gap_ratio := gap / theoretical_gap if theoretical_gap > 0.0 else 0.0
			var ledge_ratio := (
				rise / theoretical_ledge
				if theoretical_ledge > 0.0
				else 0.0
			)
			var maximum_ratio := maxf(gap_ratio, ledge_ratio)
			var transition_id := "%s:%02d" % [room.id, index - 1]
			var comfort := (
				"routine"
				if maximum_ratio <= 0.45
				else ("challenge" if maximum_ratio <= 0.60 else "near_limit")
			)
			transitions.append({
				"id": transition_id,
				"room_id": String(room.id),
				"surface_index": index - 1,
				"gap": gap,
				"rise": rise,
				"gap_ratio": gap_ratio,
				"ledge_ratio": ledge_ratio,
				"maximum_ratio": maximum_ratio,
				"comfort": comfort,
			})
			if maximum_ratio > 0.60:
				near_limit_ids.append(transition_id)
				current_chain += 1
				max_near_limit_chain = maxi(max_near_limit_chain, current_chain)
			else:
				current_chain = 0
	return {
		"transitions": transitions,
		"near_limit_ids": near_limit_ids,
		"max_near_limit_chain": max_near_limit_chain,
	}


static func _ordered_critical_support_rows(host: RoomTemplateHost) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if host == null:
		return rows
	for root_name in [&"Terrain", &"OneWay"]:
		var root := host.get_node_or_null(String(root_name))
		if root == null:
			continue
		for child in root.get_children():
			if not child is StaticBody2D or not bool(child.get_meta("critical", false)):
				continue
			var width := float(child.get_meta("support_width", 0.0))
			rows.append({
				"id": String(child.get_meta("surface_id", child.name)),
				"x": child.position.x - width * 0.5,
				"width": width,
				"top": float(child.get_meta("support_top", child.position.y)),
			})
	rows.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return float(left["x"]) < float(right["x"])
	)
	return rows
