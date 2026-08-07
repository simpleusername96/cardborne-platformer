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
const ROLE_BY_STAGE: Array[StringName] = [
	&"chaser", &"shooter", &"rammer", &"bulkhead_guard", &"splitter_barge",
]

var stage_index := 0
var position := Vector2.ZERO
var health := 0.0
var maximum_health := 0.0
var state: StringName = &"dormant"
var spawn_remaining := 0.0
var spawn_serial := 0


func configure(next_stage_index: int, next_position: Vector2) -> void:
	stage_index = clampi(next_stage_index, 0, HEALTH_BY_STAGE.size() - 1)
	position = next_position
	maximum_health = HEALTH_BY_STAGE[stage_index]
	health = maximum_health
	state = &"dormant"
	spawn_remaining = INTERVAL_BY_STAGE[stage_index]
	spawn_serial = 0


func activate_if_ready(defeats: int, quota: int) -> bool:
	if state != &"dormant":
		return false
	var trigger_defeats := maxi(1, ceili(float(maxi(1, quota)) * TRIGGER_RATIO))
	if defeats < trigger_defeats:
		return false
	state = &"active"
	spawn_remaining = INTERVAL_BY_STAGE[stage_index]
	return true


func retire() -> void:
	if state in [&"dormant", &"active"]:
		state = &"retired"


func advance(delta: float, live_children: int, available_global_slots: int) -> Dictionary:
	if state != &"active":
		return {}
	spawn_remaining = maxf(0.0, spawn_remaining - maxf(0.0, delta))
	if (
		spawn_remaining > 0.0
		or live_children >= LIVE_CHILD_CAP_BY_STAGE[stage_index]
		or available_global_slots <= 0
	):
		return {}
	spawn_remaining = INTERVAL_BY_STAGE[stage_index]
	var serial := spawn_serial
	spawn_serial += 1
	var angle := TAU * float(serial % 8) / 8.0
	return {
		"id":"facility_reinforcement_%d" % serial,
		"role":ROLE_BY_STAGE[stage_index],
		"pos":position + Vector2.RIGHT.rotated(angle) * (COLLISION_RADIUS + 42.0),
		"active":true,
		"summoned":true,
		"carrier_id":"reinforcement_facility",
		"zone":&"reinforcement_facility",
	}


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
		"position":position,
		"health":health,
		"max_health":maximum_health,
		"radius":VISUAL_RADIUS,
		"state":state,
		"visible":state == &"active",
		"spawn_ratio":clampf(
			spawn_remaining / INTERVAL_BY_STAGE[stage_index], 0.0, 1.0
		),
		"role":ROLE_BY_STAGE[stage_index],
		"live_child_cap":LIVE_CHILD_CAP_BY_STAGE[stage_index],
	}
