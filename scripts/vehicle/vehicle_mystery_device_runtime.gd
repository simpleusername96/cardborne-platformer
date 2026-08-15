class_name VehicleMysteryDeviceRuntime
extends RefCounted

## Dormant neutral facilities activate their symmetric area effect when broken.
## The bounded active timer is advanced here; VehicleRun only applies modifiers.

const DEVICE_COUNT := 3
const DEVICE_HEALTH := 360.0
const DEVICE_RADIUS := 84.0
const ACTIVE_DURATION_SECONDS := 12.0
const HIT_FLASH_SECONDS := 0.14
const OUTCOME_IDS: Array[StringName] = [&"repair", &"barrier", &"gravity", &"cryo", &"weakpoint"]
const OUTCOME_PROFILE := {
	&"repair": {"radius": 1260.0, "hull_restore_per_second": 1.0 / 6.0},
	&"barrier": {"radius": 1260.0, "shield_restore_per_second": 1.0 / 6.0, "shield_cap_max_hull_ratio": 1.0},
	&"gravity": {"radius": 1440.0, "acceleration_multiplier": 0.70, "max_speed_multiplier": 0.70},
	&"cryo": {"radius": 1080.0, "movement_multiplier": 0.82, "attack_cadence_multiplier": 0.82},
	&"weakpoint": {"radius": 1260.0, "received_damage_multiplier": 1.15},
}

var devices: Array[Dictionary] = []
func configure(device_blueprint: Array, layout_seed: int, stage_id: StringName) -> void:
	devices.clear()
	var rotation := _rotation(layout_seed, stage_id)
	for index in mini(DEVICE_COUNT, device_blueprint.size()):
		var blueprint := Dictionary(device_blueprint[index])
		var outcome := rotation[index]
		devices.append({"id": StringName(blueprint.get("id", "facility_%d" % index)), "position": Vector2(blueprint.get("pos", blueprint.get("position", Vector2.ZERO))), "health": DEVICE_HEALTH, "outcome": outcome, "state": &"dormant", "active_remaining": 0.0, "hit_flash_remaining": 0.0})

func advance(delta: float) -> void:
	var step := maxf(0.0, delta)
	for device in devices:
		device["hit_flash_remaining"] = maxf(0.0, float(device.get("hit_flash_remaining", 0.0)) - step)
		if StringName(device["state"]) != &"active":
			continue
		device["active_remaining"] = maxf(0.0, float(device["active_remaining"]) - step)
		if float(device["active_remaining"]) <= 0.0:
			device["state"] = &"expired"

static func accepts_damage(source_team: StringName, attack_kind: StringName) -> bool:
	return source_team in [&"player", &"hostile"] and attack_kind in [&"direct", &"area", &"projectile"]

func receive_damage(device_id: StringName, amount: float, source_team: StringName, attack_kind: StringName) -> Dictionary:
	var device := _device_by_id(device_id)
	var receipt := {"accepted": false, "broken": false, "device_id": device_id, "remaining_health": float(device.get("health", 0.0)), "break_event": {}}
	if device.is_empty() or StringName(device["state"]) != &"dormant" or not accepts_damage(source_team, attack_kind) or amount <= 0.0:
		return receipt
	device["health"] = maxf(0.0, float(device["health"]) - amount)
	device["hit_flash_remaining"] = HIT_FLASH_SECONDS
	receipt["accepted"] = true
	receipt["remaining_health"] = float(device["health"])
	if float(device["health"]) <= 0.0:
		device["state"] = &"active"
		device["active_remaining"] = ACTIVE_DURATION_SECONDS
		receipt["broken"] = true
		receipt["break_event"] = {"kind": &"facility_activated", "device_id": device_id, "source": &"neutral_facility", "grants_experience": false, "drop": &"", "projectiles_blocked": false, "duration": ACTIVE_DURATION_SECONDS}
	return receipt

func modifiers_at(position: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	return fill_modifiers_at(position, result)

func fill_modifiers_at(position: Vector2, output: Array[Dictionary]) -> Array[Dictionary]:
	output.clear()
	var strongest_by_kind: Dictionary = {}
	for device in devices:
		if StringName(device["state"]) != &"active":
			continue
		var profile := Dictionary(OUTCOME_PROFILE[StringName(device["outcome"])])
		if position.distance_to(Vector2(device["position"])) <= float(profile["radius"]):
			var kind := StringName(device["outcome"])
			var candidate := {"facility_id": StringName(device["id"]), "kind": kind, "profile": profile, "applies_to": &"all_actors", "strength": float(device.get("effect_strength", 1.0))}
			var current := Dictionary(strongest_by_kind.get(kind, {}))
			if current.is_empty() or _modifier_precedes(candidate, current):
				strongest_by_kind[kind] = candidate
	var candidates: Array[Dictionary] = []
	for candidate in strongest_by_kind.values():
		candidates.append(Dictionary(candidate))
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left["facility_id"]) < String(right["facility_id"])
	)
	for candidate in candidates:
		if output.size() >= 2:
			break
		output.append(candidate)
	return output


static func _modifier_precedes(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_strength := float(candidate.get("strength", 1.0))
	var current_strength := float(current.get("strength", 1.0))
	if not is_equal_approx(candidate_strength, current_strength):
		return candidate_strength > current_strength
	return String(candidate["facility_id"]) < String(current["facility_id"])

func fill_device_snapshot(output: Array[Dictionary]) -> Array[Dictionary]:
	var source: Array = snapshot()["devices"]
	output.clear()
	for record in source:
		output.append(Dictionary(record))
	return output

func is_position_clear(position: Vector2, actor_radius: float) -> bool:
	for device in devices:
		if StringName(device["state"]) == &"dormant" and position.distance_to(Vector2(device["position"])) < DEVICE_RADIUS + maxf(0.0, actor_radius):
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
		if StringName(device["state"]) != &"dormant":
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
		var active_remaining := float(device.get("active_remaining", 0.0))
		records.append({"id": StringName(device["id"]), "position": Vector2(device["position"]), "radius": DEVICE_RADIUS, "effect_radius": float(profile["radius"]), "health": float(device["health"]), "max_health": DEVICE_HEALTH, "outcome": StringName(device["outcome"]), "state": StringName(device["state"]), "active_remaining": active_remaining, "active_duration": ACTIVE_DURATION_SECONDS, "active_ratio": clampf(active_remaining / ACTIVE_DURATION_SECONDS, 0.0, 1.0), "hit_flash_remaining":float(device.get("hit_flash_remaining", 0.0)), "projectiles_blocked": false})
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
