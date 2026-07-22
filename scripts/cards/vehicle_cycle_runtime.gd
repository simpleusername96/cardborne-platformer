class_name VehicleCycleRuntime
extends RefCounted

## Owns the three recurring upgrade cycles and exposes compact HUD state.

const ORDER: Array[StringName] = [&"aegis_cycle", &"overclock_cycle", &"thruster_cycle"]
const PERIODS := {&"aegis_cycle":14.0, &"overclock_cycle":12.0, &"thruster_cycle":10.0}
const DURATIONS := {&"aegis_cycle":5.0, &"overclock_cycle":4.0, &"thruster_cycle":3.5}

var states: Dictionary = {}


func reset() -> void:
	states.clear()


func sync_build(build: VehicleRunBuild) -> Dictionary:
	var activations := {}
	for upgrade_id in ORDER:
		var level := build.level_of(upgrade_id)
		if level <= 0:
			states.erase(upgrade_id)
			continue
		if not states.has(upgrade_id):
			states[upgrade_id] = {"level":level, "active":_duration(upgrade_id, level), "recharge":0.0}
			activations[upgrade_id] = level
		else:
			var prior_level := int(states[upgrade_id]["level"])
			states[upgrade_id]["level"] = level
			if level > prior_level:
				states[upgrade_id]["active"] = _duration(upgrade_id, level)
				states[upgrade_id]["recharge"] = 0.0
				activations[upgrade_id] = level
	return activations


func advance(delta: float) -> Array[StringName]:
	var activated: Array[StringName] = []
	for upgrade_id in ORDER:
		if not states.has(upgrade_id):
			continue
		var state: Dictionary = states[upgrade_id]
		if float(state["active"]) > 0.0:
			state["active"] = maxf(0.0, float(state["active"]) - delta)
			if float(state["active"]) <= 0.0:
				state["recharge"] = float(PERIODS[upgrade_id])
		else:
			state["recharge"] = maxf(0.0, float(state["recharge"]) - delta)
			if float(state["recharge"]) <= 0.0:
				state["active"] = _duration(upgrade_id, int(state["level"]))
				activated.append(upgrade_id)
	return activated


func is_active(upgrade_id: StringName) -> bool:
	return states.has(upgrade_id) and float(states[upgrade_id]["active"]) > 0.0


func level(upgrade_id: StringName) -> int:
	return int(states.get(upgrade_id, {}).get("level", 0))


func hud_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for upgrade_id in ORDER:
		if not states.has(upgrade_id):
			continue
		var state: Dictionary = states[upgrade_id]
		var active := float(state["active"])
		var duration := _duration(upgrade_id, int(state["level"]))
		var recharge := float(state["recharge"])
		var period := float(PERIODS[upgrade_id])
		result.append({
			"id":upgrade_id, "active":active > 0.0, "seconds":active if active > 0.0 else recharge,
			"progress":active / duration if active > 0.0 else 1.0 - recharge / period,
			"level":int(state["level"]),
		})
	return result


func _duration(upgrade_id: StringName, level: int) -> float:
	if upgrade_id == &"aegis_cycle" and level >= 2:
		return 6.0
	return float(DURATIONS[upgrade_id])
