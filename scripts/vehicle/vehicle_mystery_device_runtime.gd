class_name VehicleMysteryDeviceRuntime
extends RefCounted

## Owns one-stage mystery-device state only. VehicleRun applies returned effects.

const DEVICE_COUNT := 3
const DEVICE_HEALTH := 90.0
const DEVICE_RADIUS := 84.0
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const OUTCOME_IDS: Array[StringName] = [
	&"gravity_pull",
	&"cryo_lock",
	&"weakpoint_expose",
]
const OUTCOME_PROFILE := {
	&"gravity_pull":{"radius":480.0, "duration":5.0},
	&"cryo_lock":{"radius":360.0, "duration":3.0},
	&"weakpoint_expose":{"radius":420.0, "duration":5.0},
}

var devices: Array[Dictionary] = []
var active_effects: Array[Dictionary] = []


func configure(device_blueprint: Array, layout_seed: int, stage_id: StringName) -> void:
	devices.clear()
	active_effects.clear()
	var available := _shuffled_outcomes(layout_seed, stage_id)
	var assigned: Dictionary = {}
	for index in mini(DEVICE_COUNT, device_blueprint.size()):
		var blueprint := Dictionary(device_blueprint[index])
		var requested := StringName(blueprint.get("outcome", &""))
		var outcome := requested if requested in OUTCOME_IDS and not assigned.has(requested) else &""
		if outcome.is_empty():
			outcome = _take_next_outcome(available, assigned)
		assigned[outcome] = true
		devices.append({
			"id":StringName(blueprint.get("id", "mystery_device_%d" % (index + 1))),
			"position":Vector2(blueprint.get("pos", blueprint.get("position", Vector2.ZERO))),
			"health":DEVICE_HEALTH,
			"outcome":outcome,
			"revealed":false,
			"state":&"intact",
		})


static func accepts_damage(source_team: StringName, attack_kind: StringName) -> bool:
	## Hostile, AI, contact, and environmental damage never affect this object.
	return source_team == &"player" and attack_kind in [&"direct", &"area"]


func receive_damage(
	device_id: StringName,
	amount: float,
	source_team: StringName,
	attack_kind: StringName
) -> Dictionary:
	var receipt := {
		"accepted":false,
		"broken":false,
		"device_id":device_id,
		"remaining_health":0.0,
		"revealed_now":false,
		"revealed_outcome":&"",
		"break_event":{},
	}
	var device := _device_by_id(device_id)
	if device.is_empty():
		return receipt
	receipt["remaining_health"] = float(device["health"])
	if not accepts_damage(source_team, attack_kind) or StringName(device["state"]) != &"intact":
		return receipt
	var applied := maxf(0.0, amount)
	if applied <= 0.0:
		return receipt
	device["health"] = maxf(0.0, float(device["health"]) - applied)
	var revealed_now := not bool(device.get("revealed", false))
	device["revealed"] = true
	receipt["accepted"] = true
	receipt["remaining_health"] = float(device["health"])
	receipt["revealed_now"] = revealed_now
	receipt["revealed_outcome"] = StringName(device["outcome"])
	if float(device["health"]) > 0.0:
		return receipt
	device["state"] = &"resolved"
	var event := _break_event(device)
	active_effects.append(event)
	receipt["broken"] = true
	receipt["break_event"] = event
	return receipt


func advance(delta: float) -> Array[Dictionary]:
	var retired: Array[Dictionary] = []
	return advance_into(delta, retired)


func advance_into(delta: float, retired: Array[Dictionary]) -> Array[Dictionary]:
	## Hot-path form. The caller keeps and reuses the returned receipt buffer.
	retired.clear()
	var elapsed := maxf(0.0, delta)
	for index in range(active_effects.size() - 1, -1, -1):
		var effect := active_effects[index]
		effect["remaining_seconds"] = maxf(0.0, float(effect["remaining_seconds"]) - elapsed)
		if float(effect["remaining_seconds"]) > 0.0:
			continue
		retired.append({
			"kind":&"mystery_device_effect_retired",
			"effect_id":StringName(effect["effect_id"]),
			"position":Vector2(effect["position"]),
			"radius":float(effect["radius"]),
			"duration":float(effect["duration"]),
		})
		var device := _device_by_id(StringName(effect["device_id"]))
		if not device.is_empty():
			device["state"] = &"retired"
		active_effects.remove_at(index)
	return retired


func is_position_clear(position: Vector2, actor_radius: float) -> bool:
	var clearance_radius := maxf(0.0, actor_radius) + DEVICE_RADIUS
	var clearance_squared := clearance_radius * clearance_radius
	for device in devices:
		if StringName(device["state"]) != &"intact":
			continue
		if position.distance_squared_to(Vector2(device["position"])) <= clearance_squared:
			return false
	return true


func first_intact_segment_hit(
	from: Vector2,
	to: Vector2,
	padding: float,
	receipt: Dictionary
) -> bool:
	## Fills caller-owned receipt with id/t/position; never exposes the hidden outcome.
	receipt.clear()
	var first_t := INF
	var first_device_index := -1
	var hit_radius := DEVICE_RADIUS + maxf(0.0, padding)
	for index in devices.size():
		var device := devices[index]
		if StringName(device["state"]) != &"intact":
			continue
		var candidate_t := AttackContract.segment_circle_first_t(
			from, to, Vector2(device["position"]), hit_radius
		)
		if candidate_t < first_t:
			first_t = candidate_t
			first_device_index = index
	if first_device_index < 0:
		return false
	var first_device := devices[first_device_index]
	receipt["device_id"] = StringName(first_device["id"])
	receipt["t"] = first_t
	receipt["position"] = from.lerp(to, first_t)
	return true


func snapshot() -> Dictionary:
	var device_snapshot: Array[Dictionary] = []
	var effect_snapshot: Array[Dictionary] = []
	fill_device_snapshot(device_snapshot)
	fill_active_effect_snapshot(effect_snapshot)
	return {"devices":device_snapshot, "active_effects":effect_snapshot}


func fill_device_snapshot(output: Array[Dictionary]) -> Array[Dictionary]:
	while output.size() < devices.size():
		output.append({})
	output.resize(devices.size())
	for index in devices.size():
		var device := devices[index]
		var record := output[index]
		record.clear()
		record["id"] = StringName(device["id"])
		record["position"] = Vector2(device["position"])
		record["radius"] = DEVICE_RADIUS
		record["health"] = float(device["health"])
		record["max_health"] = DEVICE_HEALTH
		record["state"] = StringName(device["state"])
		record["visible"] = StringName(device["state"]) != &"retired"
		if bool(device.get("revealed", false)):
			record["revealed_outcome"] = StringName(device["outcome"])
	return output


func fill_active_effect_snapshot(output: Array[Dictionary]) -> Array[Dictionary]:
	while output.size() < active_effects.size():
		output.append({})
	output.resize(active_effects.size())
	for index in active_effects.size():
		var effect := active_effects[index]
		var record := output[index]
		record.clear()
		for key in effect:
			record[key] = effect[key]
	return output


func is_intact(device_id: StringName) -> bool:
	var device := _device_by_id(device_id)
	return not device.is_empty() and StringName(device["state"]) == &"intact"


func intact_devices_snapshot() -> Array[Dictionary]:
	var all_devices: Array[Dictionary] = []
	fill_device_snapshot(all_devices)
	var result: Array[Dictionary] = []
	for device in all_devices:
		var record := Dictionary(device)
		if StringName(record["state"]) == &"intact":
			result.append(record)
	return result


func _break_event(device: Dictionary) -> Dictionary:
	var outcome := StringName(device["outcome"])
	var profile := Dictionary(OUTCOME_PROFILE[outcome])
	return {
		"kind":&"mystery_device_broken",
		"device_id":StringName(device["id"]),
		"effect_id":outcome,
		"position":Vector2(device["position"]),
		"radius":float(profile["radius"]),
		"duration":float(profile["duration"]),
		"remaining_seconds":float(profile["duration"]),
		## The device is never an enemy, quota subject, XP source, or drop source.
		"device_counts_for_quota":false,
		"grants_experience":false,
		"drop":&"",
	}


func _device_by_id(device_id: StringName) -> Dictionary:
	for device in devices:
		if StringName(device["id"]) == device_id:
			return device
	return {}


func _shuffled_outcomes(layout_seed: int, stage_id: StringName) -> Array[StringName]:
	var result := OUTCOME_IDS.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s:mystery-device-v1" % [layout_seed, String(stage_id)])
	for index in range(result.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held: StringName = result[index]
		result[index] = result[swap_index]
		result[swap_index] = held
	return result


func _take_next_outcome(available: Array[StringName], assigned: Dictionary) -> StringName:
	for outcome in available:
		if not assigned.has(outcome):
			return outcome
	return OUTCOME_IDS[0]
