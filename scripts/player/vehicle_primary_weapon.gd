class_name VehiclePrimaryWeapon
extends RefCounted

## Owns the neutral Pulse Cannon cadence and the idle-powered opening shot.
## Charge only strengthens the next shot; it never gates ordinary held fire.

const BASE_INTERVAL := 0.12
const MIN_INTERVAL := 0.085
const FULL_OPENING_SECONDS := 1.0
const BONUS_START_SECONDS := 0.25
const FULL_EPSILON := 0.999
const FULL_HEALTH_SCALE := 1.75
const FULL_STRUCTURE_SCALE := 3.0
const FULL_STAGGER_SCALE := 3.0
const FULL_RADIUS_SCALE := 1.5

var cooldown := 0.0
var idle_seconds := FULL_OPENING_SECONDS
var input_held := false
var full_opening_seconds := FULL_OPENING_SECONDS


func reset(opening_ready: bool = true) -> void:
	cooldown = 0.0
	idle_seconds = full_opening_seconds if opening_ready else 0.0
	input_held = false


func tick(delta: float, held: bool, firing_allowed: bool) -> void:
	cooldown = maxf(0.0, cooldown - maxf(0.0, delta))
	input_held = held
	if not held or not firing_allowed:
		idle_seconds = minf(full_opening_seconds, idle_seconds + maxf(0.0, delta))


func can_fire(firing_allowed: bool = true) -> bool:
	return input_held and firing_allowed and cooldown <= 0.0


func consume_shot(interval: float = BASE_INTERVAL) -> Dictionary:
	var opening_ratio := charge_ratio()
	var bonus_ratio := 0.0
	if idle_seconds >= BONUS_START_SECONDS:
		bonus_ratio = inverse_lerp(minf(BONUS_START_SECONDS, full_opening_seconds), full_opening_seconds, idle_seconds)
	var result := {
		"opening_ratio": opening_ratio,
		"bonus_ratio": clampf(bonus_ratio, 0.0, 1.0),
		"full_opening": opening_ratio >= FULL_EPSILON,
		"damage_scale": lerpf(1.0, FULL_HEALTH_SCALE, clampf(bonus_ratio, 0.0, 1.0)),
		"structure_scale": lerpf(1.0, FULL_STRUCTURE_SCALE, clampf(bonus_ratio, 0.0, 1.0)),
		"radius_scale": lerpf(1.0, FULL_RADIUS_SCALE, clampf(bonus_ratio, 0.0, 1.0)),
		"stagger_scale": lerpf(1.0, FULL_STAGGER_SCALE, clampf(bonus_ratio, 0.0, 1.0)),
	}
	cooldown = maxf(MIN_INTERVAL, interval)
	idle_seconds = 0.0
	return result


func charge_ratio() -> float:
	return clampf(idle_seconds / full_opening_seconds, 0.0, 1.0)


func set_full_opening_seconds(seconds: float) -> void:
	full_opening_seconds = maxf(BONUS_START_SECONDS + 0.01, seconds)
	idle_seconds = minf(idle_seconds, full_opening_seconds)


func tier() -> StringName:
	if input_held:
		return &"firing"
	if charge_ratio() >= FULL_EPSILON:
		return &"ready"
	if idle_seconds >= BONUS_START_SECONDS:
		return &"charging"
	return &"idle"


func snapshot() -> Dictionary:
	return {
		"cooldown": cooldown,
		"idle_seconds": idle_seconds,
		"charge_ratio": charge_ratio(),
		"tier": tier(),
		"input_held": input_held,
		"full_opening_seconds": full_opening_seconds,
	}
