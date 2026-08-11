class_name VehicleReinforcementFacilityRuntime
extends RefCounted

## Owns one destructible reinforcement facility per stage. It is deliberately
## outside EnemyState, enemy AI, ordinary quota, and enemy reward ownership.

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

const FACILITY_ID := &"reinforcement_fabricator"
const TRIGGER_RATIO := 0.35
const COLLISION_RADIUS := 82.0
const VISUAL_RADIUS := 112.0
const HEALTH_BY_STAGE := [300.0, 390.0, 480.0, 570.0, 680.0]
const INTERVAL_BY_STAGE := [8.0, 7.0, 6.0, 5.0, 4.0]
const LIVE_CHILD_CAP_BY_STAGE := [2, 3, 4, 5, 6]
const TOTAL_CHARGES_BY_STAGE := [2, 3, 4, 5, 6]
const SPENT_RETIRE_DELAY := 0.8
const ROLE_BY_STAGE: Array[StringName] = [
	&"chaser", &"shooter", &"rammer", &"bulkhead_guard", &"splitter_barge",
]

var stage_index := 0
var position := Vector2.ZERO
var health := 0.0
var maximum_health := 0.0
var state: StringName = &"offline"
var spawn_remaining := 0.0
var spawn_serial := 0
var remaining_charges := 0
var live_children := 0
var spent_remaining := 0.0
var _instance_serial := 0
var _carrier_id := &""


func configure(next_stage_index: int, next_position: Vector2) -> void:
	_instance_serial += 1
	stage_index = clampi(next_stage_index, 0, HEALTH_BY_STAGE.size() - 1)
	_carrier_id = StringName(
		"reinforcement_facility:s%d:i%d"
		% [stage_index + 1, _instance_serial]
	)
	position = next_position
	maximum_health = HEALTH_BY_STAGE[stage_index]
	health = maximum_health
	state = &"offline"
	spawn_remaining = INTERVAL_BY_STAGE[stage_index]
	spawn_serial = 0
	remaining_charges = TOTAL_CHARGES_BY_STAGE[stage_index]
	live_children = 0
	spent_remaining = 0.0


func activate_if_ready(defeats: int, quota: int) -> bool:
	if state != &"offline":
		return false
	var trigger_defeats := maxi(1, ceili(float(maxi(1, quota)) * TRIGGER_RATIO))
	if defeats < trigger_defeats:
		return false
	state = &"active"
	spawn_remaining = INTERVAL_BY_STAGE[stage_index]
	return true


func retire() -> void:
	if state in [&"offline", &"active", &"spent"]:
		state = &"retired"


func advance(delta: float, available_global_slots: int) -> Dictionary:
	var elapsed := maxf(0.0, delta)
	if state == &"spent":
		spent_remaining = maxf(0.0, spent_remaining - elapsed)
		if spent_remaining <= 0.0:
			state = &"retired"
		return {}
	if state != &"active":
		return {}
	if remaining_charges <= 0:
		_try_begin_spent()
		return {}
	spawn_remaining = maxf(0.0, spawn_remaining - elapsed)
	if (
		spawn_remaining > 0.0
		or live_children >= LIVE_CHILD_CAP_BY_STAGE[stage_index]
		or available_global_slots <= 0
	):
		return {}
	var serial := spawn_serial
	var angle := TAU * float(serial % 8) / 8.0
	return {
		"id":"facility_reinforcement_%d" % serial,
		"role":ROLE_BY_STAGE[stage_index],
		"pos":position + Vector2.RIGHT.rotated(angle) * (COLLISION_RADIUS + 42.0),
		"active":true,
		"summoned":true,
		"carrier_id":_carrier_id,
		"zone":&"reinforcement_facility",
	}


func note_spawn_accepted() -> void:
	if state != &"active" or remaining_charges <= 0:
		return
	spawn_serial += 1
	remaining_charges -= 1
	live_children += 1
	spawn_remaining = INTERVAL_BY_STAGE[stage_index]
	_try_begin_spent()


func note_child_retired() -> void:
	if live_children > 0:
		live_children -= 1
	_try_begin_spent()


func owns_child(carrier_id: String) -> bool:
	return not _carrier_id.is_empty() and String(_carrier_id) == carrier_id


func _try_begin_spent() -> void:
	if state == &"active" and remaining_charges <= 0 and live_children <= 0:
		state = &"spent"
		spent_remaining = SPENT_RETIRE_DELAY


func receive_damage(amount: float, source_team: StringName, attack_kind: StringName) -> Dictionary:
	var receipt := {
		"accepted":false,
		"destroyed":false,
		"remaining_health":health,
	}
	if (
		state != &"active"
		or source_team != &"player"
		or attack_kind not in [&"direct", &"area"]
	):
		return receipt
	var applied := maxf(0.0, amount)
	if applied <= 0.0:
		return receipt
	health = maxf(0.0, health - applied)
	receipt["accepted"] = true
	receipt["remaining_health"] = health
	if health <= 0.0:
		state = &"destroyed"
		receipt["destroyed"] = true
	return receipt


func first_active_segment_hit(
	from: Vector2,
	to: Vector2,
	padding: float,
	receipt: Dictionary
) -> bool:
	receipt.clear()
	if state != &"active":
		return false
	var hit_t := AttackContract.segment_circle_first_t(
		from, to, position, COLLISION_RADIUS + maxf(0.0, padding)
	)
	if hit_t == INF:
		return false
	receipt["t"] = hit_t
	receipt["position"] = from.lerp(to, hit_t)
	return true


func is_position_clear(candidate: Vector2, actor_radius: float) -> bool:
	if state != &"active":
		return true
	var clearance := COLLISION_RADIUS + maxf(0.0, actor_radius)
	return candidate.distance_squared_to(position) >= clearance * clearance


func snapshot() -> Dictionary:
	return {
		"id":FACILITY_ID,
		"carrier_id":_carrier_id,
		"position":position,
		"health":health,
		"max_health":maximum_health,
		"radius":VISUAL_RADIUS,
		"state":state,
		"visible":state in [&"offline", &"active", &"spent"],
		"spawn_ratio":clampf(
			spawn_remaining / INTERVAL_BY_STAGE[stage_index], 0.0, 1.0
		),
		"role":ROLE_BY_STAGE[stage_index],
		"live_child_cap":LIVE_CHILD_CAP_BY_STAGE[stage_index],
		"total_charges":TOTAL_CHARGES_BY_STAGE[stage_index],
		"remaining_charges":remaining_charges,
		"live_children":live_children,
		"spent_remaining":spent_remaining,
	}
