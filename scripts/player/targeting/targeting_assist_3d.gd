class_name TargetingAssist3D
extends Node3D

class TargetingResult:
	var target: Node3D = null
	var direction := Vector3.FORWARD
	var assisted := false

	func _init(resolved_target: Node3D, resolved_direction: Vector3, was_assisted: bool) -> void:
		target = resolved_target
		direction = resolved_direction
		assisted = was_assisted


const ATTACK_TARGET_GROUP := &"attack_targets"
const TARGET_POINT_PATH := NodePath("TargetPoint")
const WORLD_AND_ENEMY_MASK := (1 << 0) | (1 << 2)
const STICKINESS_SECONDS := 0.45
const SCORE_TIE_EPSILON := 0.001
const ANGLE_SCORE_WEIGHT := 0.75
const DISTANCE_SCORE_WEIGHT := 0.25

const MELEE_MAX_DISTANCE := 2.75
const MELEE_FULL_CONE_DEGREES := 110.0
const MELEE_NEAR_DISTANCE := 1.60
const MELEE_NEAR_FULL_CONE_DEGREES := 160.0
const RANGED_MAX_DISTANCE := 14.0
const RANGED_FULL_CONE_DEGREES := 50.0

var _warned_contract_ids: Dictionary = {}
var _sticky_targets: Dictionary = {}
var _sticky_until: Dictionary = {}
var _marker_remaining := 0.0
var _marked_target: Node3D = null

@onready var target_marker: MeshInstance3D = $TargetMarker


func _ready() -> void:
	target_marker.top_level = true
	target_marker.visible = false


func _process(delta: float) -> void:
	if _marker_remaining <= 0.0:
		return
	if (
		_marked_target == null
		or not is_instance_valid(_marked_target)
		or not _has_target_contract(_marked_target)
		or not bool(_marked_target.call("is_targetable"))
	):
		_hide_marker()
		return
	_marker_remaining = maxf(0.0, _marker_remaining - delta)
	if _marker_remaining <= 0.0:
		target_marker.visible = false


func resolve_attack(
	kind: StringName,
	origin: Vector3,
	intended_direction: Vector3,
) -> TargetingResult:
	var intended := _planar_direction(intended_direction)
	var parameters := _parameters_for(kind)
	if parameters.is_empty():
		_hide_marker()
		return TargetingResult.new(null, intended, false)

	var now := Time.get_ticks_msec() / 1000.0
	var sticky_target := _sticky_targets.get(kind) as Node3D
	if (
		sticky_target != null
		and is_instance_valid(sticky_target)
		and now <= float(_sticky_until.get(kind, 0.0))
		and _is_valid_candidate(sticky_target, kind, origin, intended)
	):
		var sticky_direction := _direction_to_target(sticky_target, origin)
		if intended.dot(sticky_direction) >= 0.0:
			_show_marker(sticky_target)
			return TargetingResult.new(sticky_target, sticky_direction, true)

	var best_target: Node3D = null
	var best_direction := intended
	var best_score := INF
	for candidate_node in get_tree().get_nodes_in_group(ATTACK_TARGET_GROUP):
		var candidate := candidate_node as Node3D
		if candidate == null or not _has_target_contract(candidate):
			continue
		if not _is_valid_candidate(candidate, kind, origin, intended):
			continue
		var target_point := candidate.get_node(TARGET_POINT_PATH) as Marker3D
		var direction := _planar_direction(target_point.global_position - origin)
		var distance := origin.distance_to(target_point.global_position)
		var half_cone := _half_cone_radians(kind, distance)
		var angular_error := acos(clampf(intended.dot(direction), -1.0, 1.0))
		var score := (
			ANGLE_SCORE_WEIGHT * angular_error / half_cone
			+ DISTANCE_SCORE_WEIGHT * distance / float(parameters.max_distance)
		)
		if (
			score < best_score - SCORE_TIE_EPSILON
			or (
				absf(score - best_score) <= SCORE_TIE_EPSILON
				and (best_target == null or candidate.get_instance_id() < best_target.get_instance_id())
			)
		):
			best_target = candidate
			best_direction = direction
			best_score = score

	if best_target == null:
		_sticky_targets.erase(kind)
		_sticky_until.erase(kind)
		_hide_marker()
		return TargetingResult.new(null, intended, false)

	_sticky_targets[kind] = best_target
	_sticky_until[kind] = now + STICKINESS_SECONDS
	_show_marker(best_target)
	return TargetingResult.new(best_target, best_direction, true)


func reset_assist() -> void:
	_sticky_targets.clear()
	_sticky_until.clear()
	_hide_marker()


func _parameters_for(kind: StringName) -> Dictionary:
	match kind:
		&"melee":
			return {"max_distance": MELEE_MAX_DISTANCE}
		&"ranged":
			return {"max_distance": RANGED_MAX_DISTANCE}
		_:
			push_warning("Unknown targeting attack kind: %s" % kind)
			return {}


func _is_valid_candidate(
	target: Node3D,
	kind: StringName,
	origin: Vector3,
	intended: Vector3,
) -> bool:
	if not _has_target_contract(target) or not bool(target.call("is_targetable")):
		return false
	var target_point := target.get_node(TARGET_POINT_PATH) as Marker3D
	var offset := target_point.global_position - origin
	var direction := _planar_direction(offset)
	var distance := origin.distance_to(target_point.global_position)
	var max_distance := float(_parameters_for(kind).get("max_distance", 0.0))
	if distance > max_distance or direction.length_squared() <= 0.0001:
		return false
	var angular_error := acos(clampf(intended.dot(direction), -1.0, 1.0))
	if angular_error > _half_cone_radians(kind, distance):
		return false
	return _has_line_of_sight(target, origin, target_point.global_position)


func _half_cone_radians(kind: StringName, distance: float) -> float:
	if kind == &"melee":
		var full_cone := (
			MELEE_NEAR_FULL_CONE_DEGREES
			if distance <= MELEE_NEAR_DISTANCE
			else MELEE_FULL_CONE_DEGREES
		)
		return deg_to_rad(full_cone * 0.5)
	return deg_to_rad(RANGED_FULL_CONE_DEGREES * 0.5)


func _has_line_of_sight(target: Node3D, origin: Vector3, destination: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin, destination, WORLD_AND_ENEMY_MASK)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == target


func _has_target_contract(target: Node3D) -> bool:
	var valid := target.has_method("is_targetable") and target.has_node(TARGET_POINT_PATH)
	if not valid and not _warned_contract_ids.has(target.get_instance_id()):
		_warned_contract_ids[target.get_instance_id()] = true
		push_warning(
			"Ignoring attack target without is_targetable() and TargetPoint: %s" % target.get_path()
		)
	return valid


func _direction_to_target(target: Node3D, origin: Vector3) -> Vector3:
	var point := target.get_node(TARGET_POINT_PATH) as Marker3D
	return _planar_direction(point.global_position - origin)


func _planar_direction(value: Vector3) -> Vector3:
	var planar := Vector3(value.x, 0.0, value.z)
	return planar.normalized() if planar.length_squared() > 0.0001 else Vector3.FORWARD


func _show_marker(target: Node3D) -> void:
	var point := target.get_node(TARGET_POINT_PATH) as Marker3D
	_marked_target = target
	target_marker.global_position = Vector3(point.global_position.x, 0.04, point.global_position.z)
	target_marker.visible = true
	_marker_remaining = 0.35


func _hide_marker() -> void:
	_marker_remaining = 0.0
	_marked_target = null
	target_marker.visible = false
