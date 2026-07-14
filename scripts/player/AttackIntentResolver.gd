class_name AttackIntentResolver
extends RefCounted

const AttackIntentValue = preload("res://scripts/player/AttackIntent.gd")

const MELEE_TARGET_BUFFER := 16.0
const SELECTION_HYSTERESIS_SECONDS := 0.15
const EPSILON := 0.0001

const REASON_MELEE_TARGET := &"melee_target"
const REASON_RANGED_TARGET := &"ranged_target"
const REASON_HYSTERESIS := &"selection_hysteresis"
const REASON_NO_QUALIFIED_TARGET := &"no_qualified_target"
const REASON_LINE_OF_SIGHT_BLOCKED := &"line_of_sight_blocked"
const REASON_OUT_OF_RANGE := &"out_of_range"
const REASON_RESOURCE_UNAVAILABLE := &"ranged_resource_unavailable"
const REASON_RELOADING := &"ranged_reloading"


## Resolves snapshots only. Target queries, resource spending, and attack execution stay outside.
static func resolve(
	facing: Vector2,
	aim: Vector2,
	target_snapshot: Dictionary,
	melee_action: Dictionary,
	ranged_policy: Dictionary,
	ranged_state: Dictionary,
	previous_selection: Variant = null
) -> AttackIntentValue:
	var origin := _vector_value(
		target_snapshot.get("origin", melee_action.get("origin", Vector2.ZERO)),
		Vector2.ZERO
	)
	var forward := _safe_direction(facing, aim)
	var previous := _previous_state(previous_selection)
	var previous_intent := previous.get("intent") as AttackIntentValue
	if bool(previous.get("action_locked", false)) and previous_intent != null:
		return previous_intent

	var qualified_targets := _qualified_targets(
		target_snapshot.get("targets", []), origin, forward
	)
	var melee_geometry := _melee_geometry(origin, forward, melee_action)
	var melee_target := _nearest_overlapping_target(qualified_targets, melee_geometry)
	var ranged_resolution := _resolve_ranged_target(
		qualified_targets, origin, ranged_policy, ranged_state
	)

	var resolved: AttackIntentValue
	if not melee_target.is_empty():
		resolved = _make_melee_intent(
			origin, forward, melee_action, melee_geometry, melee_target, REASON_MELEE_TARGET
		)
	elif not ranged_resolution.get("target", {}).is_empty():
		resolved = _make_ranged_intent(
			origin,
			forward,
			ranged_policy,
			ranged_resolution.get("target", {}),
			REASON_RANGED_TARGET
		)
	else:
		resolved = _make_melee_intent(
			origin,
			forward,
			melee_action,
			melee_geometry,
			{},
			StringName(ranged_resolution.get("reason", REASON_NO_QUALIFIED_TARGET))
		)

	return _apply_hysteresis(
		resolved,
		previous,
		qualified_targets,
		origin,
		forward,
		melee_action,
		melee_geometry,
		ranged_policy,
		ranged_state
	)


static func _apply_hysteresis(
	resolved: AttackIntentValue,
	previous: Dictionary,
	qualified_targets: Array[Dictionary],
	origin: Vector2,
	forward: Vector2,
	melee_action: Dictionary,
	melee_geometry: Dictionary,
	ranged_policy: Dictionary,
	ranged_state: Dictionary
) -> AttackIntentValue:
	var previous_intent := previous.get("intent") as AttackIntentValue
	var elapsed := float(previous.get("elapsed", INF))
	if (
		previous_intent == null
		or elapsed < 0.0
		or elapsed > SELECTION_HYSTERESIS_SECONDS + EPSILON
		or not resolved.is_targeted()
		or resolved.target_id != previous_intent.target_id
		or resolved.mode == previous_intent.mode
	):
		return resolved

	var previous_target := _target_by_id(qualified_targets, previous_intent.target_id)
	if previous_target.is_empty():
		return resolved

	if (
		previous_intent.mode == AttackIntentValue.MODE_MELEE
		and previous_intent.tool_id == _name_value(melee_action.get("tool_id", &""))
	):
		return _make_melee_intent(
			origin,
			forward,
			melee_action,
			melee_geometry,
			previous_target,
			REASON_HYSTERESIS
		)
	if (
		previous_intent.mode == AttackIntentValue.MODE_RANGED
		and previous_intent.tool_id == _name_value(ranged_policy.get("tool_id", &""))
		and _is_valid_ranged_target(previous_target, origin, ranged_policy, ranged_state)
	):
		return _make_ranged_intent(
			origin, forward, ranged_policy, previous_target, REASON_HYSTERESIS
		)
	return resolved


static func _qualified_targets(
	raw_targets: Variant,
	origin: Vector2,
	forward: Vector2
) -> Array[Dictionary]:
	var qualified: Array[Dictionary] = []
	if not raw_targets is Array:
		return qualified
	for raw_target in raw_targets:
		if not raw_target is Dictionary:
			continue
		var target: Dictionary = raw_target
		var target_id := _name_value(target.get("id", &""))
		if (
			String(target_id).is_empty()
			or not bool(target.get("alive", false))
			or not bool(target.get("discovered", false))
			or not bool(target.get("targetable", true))
			or not bool(target.get("is_enemy", true))
			or not bool(target.get("on_screen", true))
		):
			continue
		var to_target := _target_center(target) - origin
		if not to_target.is_zero_approx() and to_target.dot(forward) < -EPSILON:
			continue
		qualified.append(target)
	return qualified


static func _nearest_overlapping_target(
	targets: Array[Dictionary],
	melee_geometry: Dictionary
) -> Dictionary:
	var targeting_rect: Rect2 = melee_geometry.get("targeting_rect", Rect2())
	var nearest: Dictionary = {}
	var nearest_distance := INF
	var origin: Vector2 = melee_geometry.get("origin", Vector2.ZERO)
	for target in targets:
		var hurtbox := _target_rect(target)
		if not targeting_rect.intersects(hurtbox, true):
			continue
		var distance := _distance_squared_to_rect(origin, hurtbox)
		if _is_preferred_target(target, distance, nearest, nearest_distance):
			nearest = target
			nearest_distance = distance
	return nearest


static func _resolve_ranged_target(
	targets: Array[Dictionary],
	origin: Vector2,
	policy: Dictionary,
	state: Dictionary
) -> Dictionary:
	if targets.is_empty():
		return {"target": {}, "reason": REASON_NO_QUALIFIED_TARGET}
	if not _has_ranged_resource(policy, state):
		return {"target": {}, "reason": REASON_RESOURCE_UNAVAILABLE}
	if _is_reloading(state):
		return {"target": {}, "reason": REASON_RELOADING}

	var nearest: Dictionary = {}
	var nearest_distance := INF
	var saw_clear_line := false
	var saw_in_range := false
	for target in targets:
		var has_line := (
			not bool(policy.get("requires_line_of_sight", true))
			or bool(target.get("line_of_sight", false))
		)
		if has_line:
			saw_clear_line = true
		var distance := origin.distance_to(_target_center(target))
		var in_range := _is_within_range(distance, policy)
		if in_range:
			saw_in_range = true
		if not has_line or not in_range:
			continue
		var distance_squared := distance * distance
		if _is_preferred_target(target, distance_squared, nearest, nearest_distance):
			nearest = target
			nearest_distance = distance_squared
	if not nearest.is_empty():
		return {"target": nearest, "reason": REASON_RANGED_TARGET}
	if not saw_clear_line:
		return {"target": {}, "reason": REASON_LINE_OF_SIGHT_BLOCKED}
	if not saw_in_range:
		return {"target": {}, "reason": REASON_OUT_OF_RANGE}
	return {"target": {}, "reason": REASON_NO_QUALIFIED_TARGET}


static func _is_valid_ranged_target(
	target: Dictionary,
	origin: Vector2,
	policy: Dictionary,
	state: Dictionary
) -> bool:
	if not _has_ranged_resource(policy, state) or _is_reloading(state):
		return false
	if (
		bool(policy.get("requires_line_of_sight", true))
		and not bool(target.get("line_of_sight", false))
	):
		return false
	return _is_within_range(origin.distance_to(_target_center(target)), policy)


static func _make_melee_intent(
	origin: Vector2,
	forward: Vector2,
	action: Dictionary,
	geometry: Dictionary,
	target: Dictionary,
	reason: StringName
) -> AttackIntentValue:
	return AttackIntentValue.new(
		AttackIntentValue.MODE_MELEE,
		_name_value(action.get("tool_id", &"")),
		_name_value(target.get("id", &"")),
		origin,
		forward,
		maxi(int(action.get("resource_cost", 0)), 0),
		reason,
		geometry,
		_name_value(action.get("resource_id", &""))
	)


static func _make_ranged_intent(
	origin: Vector2,
	forward: Vector2,
	policy: Dictionary,
	target: Dictionary,
	reason: StringName
) -> AttackIntentValue:
	var target_point := _target_center(target)
	var direction := target_point - origin
	if direction.is_zero_approx():
		direction = forward
	direction = direction.normalized()
	var maximum_range := maxf(float(policy.get("range", 0.0)), 0.0)
	var geometry: Dictionary = {}
	if policy.get("geometry", {}) is Dictionary:
		geometry = (policy.get("geometry", {}) as Dictionary).duplicate(true)
	geometry.merge({
		"kind": _name_value(geometry.get("kind", &"line")),
		"origin": origin,
		"path": PackedVector2Array([origin, origin + direction * maximum_range]),
		"target_point": target_point,
		"maximum_range": maximum_range,
	}, true)
	return AttackIntentValue.new(
		AttackIntentValue.MODE_RANGED,
		_name_value(policy.get("tool_id", &"")),
		_name_value(target.get("id", &"")),
		origin,
		direction,
		maxi(int(policy.get("resource_cost", 0)), 0),
		reason,
		geometry,
		_name_value(policy.get("resource_id", &""))
	)


static func _melee_geometry(
	origin: Vector2,
	forward: Vector2,
	action: Dictionary
) -> Dictionary:
	var size := _vector_value(action.get("hitbox_size", Vector2.ONE), Vector2.ONE)
	size = Vector2(maxf(absf(size.x), EPSILON), maxf(absf(size.y), EPSILON))
	var offset := _vector_value(action.get("hitbox_offset", Vector2.ZERO), Vector2.ZERO)
	# Side-scroller attacks mirror horizontal reach only; vertical placement stays fixed.
	var horizontal_direction := -1.0 if forward.x < 0.0 else 1.0
	var center := origin + Vector2(offset.x * horizontal_direction, offset.y)
	var hit_rect := Rect2(center - size * 0.5, size)
	var geometry: Dictionary = {}
	if action.get("geometry", {}) is Dictionary:
		geometry = (action.get("geometry", {}) as Dictionary).duplicate(true)
	geometry.merge({
		"kind": &"rect",
		"origin": origin,
		"rect": hit_rect,
		"targeting_rect": hit_rect.grow(MELEE_TARGET_BUFFER),
		"targeting_buffer": MELEE_TARGET_BUFFER,
	}, true)
	return geometry


static func _target_rect(target: Dictionary) -> Rect2:
	var explicit_rect: Variant = target.get("hurtbox_rect", null)
	if explicit_rect is Rect2:
		return explicit_rect
	var center := _target_center(target)
	var size := _vector_value(target.get("hurtbox_size", Vector2.ONE), Vector2.ONE)
	size = Vector2(maxf(absf(size.x), EPSILON), maxf(absf(size.y), EPSILON))
	return Rect2(center - size * 0.5, size)


static func _target_center(target: Dictionary) -> Vector2:
	var explicit_rect: Variant = target.get("hurtbox_rect", null)
	if explicit_rect is Rect2:
		return explicit_rect.get_center()
	return _vector_value(target.get("position", Vector2.ZERO), Vector2.ZERO)


static func _distance_squared_to_rect(point: Vector2, rect: Rect2) -> float:
	var closest := Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
	return point.distance_squared_to(closest)


static func _is_preferred_target(
	candidate: Dictionary,
	distance: float,
	current: Dictionary,
	current_distance: float
) -> bool:
	if current.is_empty() or distance < current_distance - EPSILON:
		return true
	if not is_equal_approx(distance, current_distance):
		return false
	return String(candidate.get("id", "")) < String(current.get("id", ""))


static func _target_by_id(targets: Array[Dictionary], target_id: StringName) -> Dictionary:
	for target in targets:
		if _name_value(target.get("id", &"")) == target_id:
			return target
	return {}


static func _has_ranged_resource(policy: Dictionary, state: Dictionary) -> bool:
	var cost := maxi(int(policy.get("resource_cost", 0)), 0)
	if cost == 0:
		return true
	if not bool(state.get("resource_available", true)):
		return false
	var available := int(state.get("resource_count", state.get("resource", 0)))
	return available >= cost


static func _is_reloading(state: Dictionary) -> bool:
	return (
		bool(state.get("reloading", false))
		or not bool(state.get("loaded", true))
		or float(state.get("reload_remaining", 0.0)) > EPSILON
	)


static func _is_within_range(distance: float, policy: Dictionary) -> bool:
	var maximum_range := float(policy.get("range", 0.0))
	return maximum_range > 0.0 and distance <= maximum_range + EPSILON


static func _previous_state(previous_selection: Variant) -> Dictionary:
	if previous_selection is AttackIntentValue:
		return {"intent": previous_selection, "elapsed": INF, "action_locked": false}
	if previous_selection is Dictionary:
		return {
			"intent": previous_selection.get("intent"),
			"elapsed": previous_selection.get(
				"elapsed", previous_selection.get("elapsed_since_selection", INF)
			),
			"action_locked": previous_selection.get("action_locked", false),
		}
	return {"intent": null, "elapsed": INF, "action_locked": false}


static func _safe_direction(primary: Vector2, fallback: Vector2) -> Vector2:
	if not primary.is_zero_approx():
		return primary.normalized()
	if not fallback.is_zero_approx():
		return fallback.normalized()
	return Vector2.RIGHT


static func _vector_value(value: Variant, fallback: Vector2) -> Vector2:
	return value as Vector2 if value is Vector2 else fallback


static func _name_value(value: Variant) -> StringName:
	return StringName(str(value))
