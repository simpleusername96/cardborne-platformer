class_name VehicleStatusRuntime
extends RefCounted

## Applies bounded independent elemental stacks and returns explicit DOT damage.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const StatusProfile = preload("res://scripts/combat/vehicle_status_profile.gd")

const TICK_SECONDS := 0.25
const DOT_KINDS: Array[StringName] = [&"burn", &"poison"]


static func apply(enemy: EnemyState, profile: VehicleStatusProfile) -> void:
	if profile == null:
		return
	if profile.burn_enabled:
		_add_stack(
			enemy, &"burn", profile.burn_dps_per_stack, profile.burn_duration,
			profile.burn_max_stacks
		)
	if profile.poison_enabled:
		_add_stack(
			enemy, &"poison", profile.poison_dps_per_stack, profile.poison_duration,
			profile.poison_max_stacks
		)
	if profile.chill_enabled:
		var boss_scale := 0.5 if enemy.role == &"stage_boss" else 1.0
		var status: Dictionary = enemy.statuses.get(&"chill", {
			"magnitude_per_stack":profile.chill_magnitude_per_stack * boss_scale,
			"time":0.0,
			"stacks":0,
			"max_stacks":profile.chill_max_stacks,
		})
		status["magnitude_per_stack"] = profile.chill_magnitude_per_stack * boss_scale
		status["time"] = profile.chill_duration * boss_scale
		status["stacks"] = mini(profile.chill_max_stacks, int(status["stacks"]) + 1)
		status["max_stacks"] = profile.chill_max_stacks
		enemy.statuses[&"chill"] = status


static func tick(enemy: EnemyState, delta: float) -> Dictionary:
	var statuses := enemy.statuses
	var damage := {"burn":0.0, "poison":0.0}
	if statuses.is_empty():
		return damage
	for kind in DOT_KINDS:
		if not statuses.has(kind):
			continue
		var status: Dictionary = statuses[kind]
		status["time"] = float(status["time"]) - delta
		status["tick"] = float(status["tick"]) - delta
		while float(status["tick"]) <= 0.0 and float(status["time"]) > 0.0:
			status["tick"] = float(status["tick"]) + TICK_SECONDS
			damage[kind] = float(damage[kind]) + (
				float(status["dps_per_stack"])
				* float(status["stacks"])
				* TICK_SECONDS
			)
		if float(status["time"]) <= 0.0:
			statuses.erase(kind)
		else:
			statuses[kind] = status
	if statuses.has(&"chill"):
		var chill: Dictionary = statuses[&"chill"]
		chill["time"] = float(chill["time"]) - delta
		if float(chill["time"]) <= 0.0:
			statuses.erase(&"chill")
		else:
			statuses[&"chill"] = chill
	return damage


static func speed_multiplier(enemy: EnemyState) -> float:
	if not enemy.statuses.has(&"chill"):
		return 1.0
	var chill: Dictionary = enemy.statuses[&"chill"]
	return maxf(
		0.50,
		1.0 - float(chill["magnitude_per_stack"]) * float(chill["stacks"])
	)


static func stack_count(enemy: EnemyState, kind: StringName) -> int:
	if not enemy.statuses.has(kind):
		return 0
	return int(enemy.statuses[kind].get("stacks", 1))


static func _add_stack(
	enemy: EnemyState,
	kind: StringName,
	dps_per_stack: float,
	duration: float,
	max_stacks: int
) -> void:
	var status: Dictionary = enemy.statuses.get(kind, {
		"dps_per_stack":dps_per_stack,
		"duration":duration,
		"time":0.0,
		"tick":TICK_SECONDS,
		"stacks":0,
		"max_stacks":max_stacks,
	})
	status["dps_per_stack"] = dps_per_stack
	status["duration"] = duration
	status["time"] = duration
	status["stacks"] = mini(max_stacks, int(status["stacks"]) + 1)
	status["max_stacks"] = max_stacks
	enemy.statuses[kind] = status
