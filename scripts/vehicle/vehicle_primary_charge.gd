class_name VehiclePrimaryCharge
extends RefCounted

## Owns the primary weapon's deliberate attack-energy rhythm.
## One accepted press consumes all stored energy; presentation only reads snapshots.

const FULL_CHARGE_SECONDS := 3.0
const MIN_FIRE_ENERGY := 0.34
const CHARGED_THRESHOLD := 0.67
const FULL_EPSILON := 0.999

var energy := 1.0


func reset(full: bool = true) -> void:
	energy = 1.0 if full else 0.0


func tick(delta: float) -> void:
	energy = minf(1.0, energy + maxf(0.0, delta) / FULL_CHARGE_SECONDS)


func can_release() -> bool:
	return energy >= MIN_FIRE_ENERGY


func release() -> float:
	if not can_release():
		return 0.0
	var released := energy
	energy = 0.0
	return released


func tier() -> StringName:
	if energy < MIN_FIRE_ENERGY:
		return &"unavailable"
	if energy < CHARGED_THRESHOLD:
		return &"quick"
	if energy < FULL_EPSILON:
		return &"charged"
	return &"full"


func remaining_to_full() -> float:
	return maxf(0.0, (1.0 - energy) * FULL_CHARGE_SECONDS)


func damage_scale(released_energy: float) -> float:
	# A quick emergency shot remains useful, while patience more than doubles output.
	return lerpf(0.55, 1.55, clampf(released_energy, MIN_FIRE_ENERGY, 1.0))
