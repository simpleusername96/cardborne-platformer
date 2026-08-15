class_name VehicleMysteryDeviceRuntime
extends RefCounted

## Persistent neutral facilities. They never block projectiles and affect every
## eligible actor inside their radius; VehicleRun applies the returned modifier.

const DEVICE_COUNT := 3
const DEVICE_HEALTH := 360.0
const DEVICE_RADIUS := 84.0
const OUTCOME_IDS: Array[StringName] = [&"repair", &"barrier", &"gravity", &"cryo", &"weakpoint"]
const OUTCOME_PROFILE := {
	&"repair": {"radius": 420.0, "hull_restore_per_second": 1.0 / 3.0},
	&"barrier": {"radius": 420.0, "shield_restore_per_second": 1.0 / 3.0, "shield_cap_max_hull_ratio": 1.0},
	&"gravity": {"radius": 480.0, "acceleration_multiplier": 0.55, "max_speed_multiplier": 0.55},
	&"cryo": {"radius": 360.0, "movement_multiplier": 0.70, "attack_cadence_multiplier": 0.70},
	&"weakpoint": {"radius": 420.0, "received_damage_multiplier": 1.25},
}

var devices: Array[Dictionary] = []
func configure(device_blueprint: Array, layout_seed: int, stage_id: StringName) -> void:
	devices.clear()
	var rotation := _rotation(layout_seed, stage_id)
	for index in mini(DEVICE_COUNT, device_blueprint.size()):
		var blueprint := Dictionary(device_blueprint[index])
		var outcome := rotation[index]
		devices.append({"id": StringName(blueprint.get("id", "facility_%d" % index)), "position": Vector2(blueprint.get("pos", blueprint.get("position", Vector2.ZERO))), "health": DEVICE_HEALTH, "outcome": outcome, "state": &"intact"})

static func accepts_damage(source_team: StringName, attack_kind: StringName) -> bool:
	return source_team in [&"player", &"hostile"] and attack_kind in [&"direct", &"area", &"projectile"]

func receive_damage(device_id: StringName, amount: float, source_team: StringName, attack_kind: StringName) -> Dictionary:
	var device := _device_by_id(device_id)
	var receipt := {"accepted": false, "broken": false, "device_id": device_id, "remaining_health": float(device.get("health", 0.0)), "break_event": {}}
	if device.is_empty() or StringName(device["state"]) != &"intact" or not accepts_damage(source_team, attack_kind) or amount <= 0.0:
		return receipt
	device["health"] = maxf(0.0, float(device["health"]) - amount)
	receipt["accepted"] = true
	receipt["remaining_health"] = float(device["health"])
	if float(device["health"]) <= 0.0:
		device["state"] = &"destroyed"
		receipt["broken"] = true
		receipt["break_event"] = {"kind": &"facility_destroyed", "device_id": device_id, "source": &"neutral_facility", "grants_experience": false, "drop": &"", "projectiles_blocked": false}
	return receipt

func modifiers_at(position: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	return fill_modifiers_at(position, result)

func fill_modifiers_at(position: Vector2, output: Array[Dictionary]) -> Array[Dictionary]:
	output.clear()
	for device in devices:
		if StringName(device["state"]) != &"intact":
			continue
		var profile := Dictionary(OUTCOME_PROFILE[StringName(device["outcome"])])
		if position.distance_to(Vector2(device["position"])) <= float(profile["radius"]):
			output.append({"facility_id": StringName(device["id"]), "kind": StringName(device["outcome"]), "profile": profile, "applies_to": &"all_actors"})
	return output

func fill_device_snapshot(output: Array[Dictionary]) -> Array[Dictionary]:
	var source: Array = snapshot()["devices"]
	output.clear()
	for record in source:
		output.append(Dictionary(record))
	return output

func is_position_clear(position: Vector2, actor_radius: float) -> bool:
	for device in devices:
		if StringName(device["state"]) == &"intact" and position.distance_to(Vector2(device["position"])) < DEVICE_RADIUS + maxf(0.0, actor_radius):
			return false
	return true

func first_intact_segment_hit(_from: Vector2, _to: Vector2, _padding: float, receipt: Dictionary) -> bool:
	# Facilities are explicitly projectile-pass-through.
	receipt.clear()
	return false

func first_damageable_segment_hit(from: Vector2, to: Vector2, padding: float, receipt: Dictionary) -> bool:
	receipt.clear()
	for index in devices.size():
		var device := devices[index]
		if StringName(device["state"]) != &"intact":
			continue
		var position := Vector2(device["position"])
		if Geometry2D.get_closest_point_to_segment(position, from, to).distance_to(position) <= DEVICE_RADIUS + maxf(0.0, padding):
			receipt["device_id"] = StringName(device["id"])
			receipt["device_index"] = index
			receipt["position"] = position
			return true
	return false

func snapshot() -> Dictionary:
	var records: Array[Dictionary] = []
	for device in devices:
		var profile := Dictionary(OUTCOME_PROFILE[StringName(device["outcome"])])
		records.append({"id": StringName(device["id"]), "position": Vector2(device["position"]), "radius": DEVICE_RADIUS, "effect_radius": float(profile["radius"]), "health": float(device["health"]), "max_health": DEVICE_HEALTH, "outcome": StringName(device["outcome"]), "state": StringName(device["state"]), "projectiles_blocked": false})
	return {"devices": records}

func _rotation(layout_seed: int, stage_id: StringName) -> Array[StringName]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s:neutral-facility-v1" % [layout_seed, String(stage_id)])
	var pool := OUTCOME_IDS.duplicate()
	for index in range(pool.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var held: StringName = pool[index]
		pool[index] = pool[swap]
		pool[swap] = held
	return [pool[0], pool[1], pool[2]]

func _device_by_id(device_id: StringName) -> Dictionary:
	for device in devices:
		if StringName(device["id"]) == device_id:
			return device
	return {}
