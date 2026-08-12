class_name VehiclePrimaryWeapon
extends RefCounted

## Owns the built-in primary weapon's held-fire cadence.
## Releasing fire stops the cadence but never changes the next shot.

const BASE_INTERVAL := 0.12
const MIN_INTERVAL := 0.085

var cooldown := 0.0
var input_held := false


func reset() -> void:
	cooldown = 0.0
	input_held = false


func tick(delta: float, held: bool) -> void:
	cooldown = maxf(0.0, cooldown - maxf(0.0, delta))
	input_held = held


func can_fire(firing_allowed: bool = true) -> bool:
	return input_held and firing_allowed and cooldown <= 0.0


func consume_shot(interval: float = BASE_INTERVAL) -> void:
	cooldown = maxf(MIN_INTERVAL, interval)
