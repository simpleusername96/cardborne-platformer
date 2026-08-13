class_name VehicleStatusRuntime
extends RefCounted

## Applies bounded Toxin, Chill, and Shock state and returns explicit toxin DOT.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const PrimaryPayload = preload("res://scripts/combat/vehicle_primary_payload_profile.gd")

const TICK_SECONDS := 0.25
const APPLICATION_PULSE_SECONDS := 0.16
const DOT_KINDS: Array[StringName] = [&"poison"]


static func apply(enemy: EnemyState, profile: VehiclePrimaryPayloadProfile) -> void:
	if profile == null:
		return
	if profile.poison_enabled:
		_add_stack(
			enemy, &"poison", profile.poison_dps_per_stack, profile.poison_duration,
			profile.poison_max_stacks
		)
		enemy.toxin_application_pulse = 1.0
		enemy.toxin_application_delay = maxf(
			enemy.toxin_application_delay,
			enemy.flash
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
		enemy.cryo_application_pulse = 1.0
		enemy.cryo_application_delay = maxf(
			enemy.cryo_application_delay,
			enemy.flash
		)
	if profile.shock_enabled and not enemy.statuses.has(&"shock"):
		var shock_boss_scale := 0.5 if enemy.role == &"stage_boss" else 1.0
		enemy.statuses[&"shock"] = {
			"time":profile.shock_lock_duration * shock_boss_scale,
			"lockout":profile.shock_reapply_seconds,
		}
		enemy.shock_application_pulse = 1.0
		enemy.shock_application_delay = maxf(enemy.shock_application_delay, enemy.flash)
	_sync_presentation_scalars(enemy)


static func tick(enemy: EnemyState, delta: float) -> Dictionary:
	var statuses := enemy.statuses
	var damage := {"poison":0.0}
	var toxin_timing := _advance_application_pulse(
		enemy.toxin_application_pulse,
		enemy.toxin_application_delay,
		delta
	)
	enemy.toxin_application_pulse = toxin_timing.x
	enemy.toxin_application_delay = toxin_timing.y
	var cryo_timing := _advance_application_pulse(
		enemy.cryo_application_pulse,
		enemy.cryo_application_delay,
		delta
	)
	enemy.cryo_application_pulse = cryo_timing.x
	enemy.cryo_application_delay = cryo_timing.y
	var shock_timing := _advance_application_pulse(
		enemy.shock_application_pulse,
		enemy.shock_application_delay,
		delta
	)
	enemy.shock_application_pulse = shock_timing.x
	enemy.shock_application_delay = shock_timing.y
	if statuses.is_empty():
		_sync_presentation_scalars(enemy)
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
	if statuses.has(&"shock"):
		var shock: Dictionary = statuses[&"shock"]
		shock["time"] = maxf(0.0, float(shock["time"]) - delta)
		shock["lockout"] = maxf(0.0, float(shock["lockout"]) - delta)
		if float(shock["lockout"]) <= 0.0:
			statuses.erase(&"shock")
		else:
			statuses[&"shock"] = shock
	_sync_presentation_scalars(enemy)
	return damage


static func speed_multiplier(enemy: EnemyState) -> float:
	if not enemy.statuses.has(&"chill"):
		return 1.0
	var chill: Dictionary = enemy.statuses[&"chill"]
	return maxf(
		0.50,
		1.0 - float(chill["magnitude_per_stack"]) * float(chill["stacks"])
	)


static func attack_commit_blocked(enemy: EnemyState) -> bool:
	if not enemy.statuses.has(&"shock"):
		return false
	return float(Dictionary(enemy.statuses[&"shock"]).get("time", 0.0)) > 0.0


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


static func _sync_presentation_scalars(enemy: EnemyState) -> void:
	enemy.toxin_stack_ratio = _stack_ratio(enemy.statuses, &"poison")
	enemy.cryo_stack_ratio = _stack_ratio(enemy.statuses, &"chill")
	enemy.shock_stack_ratio = 1.0 if attack_commit_blocked(enemy) else 0.0


static func _stack_ratio(statuses: Dictionary, kind: StringName) -> float:
	if not statuses.has(kind):
		return 0.0
	var status: Dictionary = statuses[kind]
	var max_stacks := maxi(1, int(status.get("max_stacks", 1)))
	return clampf(float(status.get("stacks", 0)) / float(max_stacks), 0.0, 1.0)


static func _advance_application_pulse(
	pulse: float,
	delay: float,
	delta: float
) -> Vector2:
	var step := maxf(0.0, delta)
	var queued := maxf(0.0, delay)
	var pulse_step := step
	if queued > 0.0:
		pulse_step = maxf(0.0, step - queued)
		queued = maxf(0.0, queued - step)
	return Vector2(
		maxf(0.0, pulse - pulse_step / APPLICATION_PULSE_SECONDS),
		queued
	)
