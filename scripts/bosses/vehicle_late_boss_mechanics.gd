class_name VehicleLateBossMechanics
extends RefCounted

## Owns the state schedules and damage rules unique to stages 9-12. Pattern
## sequencing stays in VehicleBossPatterns and collision stays in VehicleRun.

const REFLECT_ARC_RADIANS := deg_to_rad(100.0)
const REFLECT_ACTIVE_SECONDS := 6.0
const REFLECT_EXPOSED_SECONDS := 2.0
const REFLECT_DAMAGE_SCALE := 0.35
const REFLECT_DAMAGE_CAP := 24.0

const RESONANCE_INNER := 420.0
const RESONANCE_OUTER := 760.0
const RESONANCE_SHIFTED_INNER := 520.0
const RESONANCE_SHIFTED_OUTER := 880.0
const RESONANCE_INTERVAL_SECONDS := 8.0
const RESONANCE_CUE_SECONDS := 1.0
const RESONANCE_OUTSIDE_DAMAGE_SCALE := 0.20

const OVERLOAD_FIRST_DELAY := 12.0
const OVERLOAD_INTERVAL_SECONDS := 18.0
const OVERLOAD_ACTIVE_SECONDS := 6.0
const OVERLOAD_MOVE_SCALE := 1.35
const OVERLOAD_CADENCE_SCALE := 0.75
const OVERLOAD_DEALT_DAMAGE_SCALE := 1.30
const OVERLOAD_RECEIVED_DAMAGE_SCALE := 1.50

const COMPRESSION_DEPTH := 180.0
const COMPRESSION_GAP := 360.0
const COMPRESSION_MAX_SHIFT := 280.0
const COMPRESSION_PAIR_DELAY := 0.45
const COMPRESSION_EDGE_CUE_SECONDS := 0.75


static func reflection_active(elapsed_seconds: float) -> bool:
	return fposmod(maxf(0.0, elapsed_seconds), REFLECT_ACTIVE_SECONDS + REFLECT_EXPOSED_SECONDS) < REFLECT_ACTIVE_SECONDS


static func hits_reflection_plate(
	facing: Vector2,
	incoming_velocity: Vector2,
	elapsed_seconds: float
) -> bool:
	if not reflection_active(elapsed_seconds):
		return false
	var forward := facing.normalized()
	var toward_source := -incoming_velocity.normalized()
	if forward.is_zero_approx() or toward_source.is_zero_approx():
		return false
	return absf(forward.angle_to(toward_source)) <= REFLECT_ARC_RADIANS * 0.5


static func reflected_damage(original_damage: float) -> float:
	return minf(REFLECT_DAMAGE_CAP, maxf(0.0, original_damage) * REFLECT_DAMAGE_SCALE)


static func resonance_shifted(elapsed_seconds: float) -> bool:
	var cycle := floori(maxf(0.0, elapsed_seconds) / RESONANCE_INTERVAL_SECONDS)
	return cycle % 2 == 1


static func resonance_cue_active(elapsed_seconds: float) -> bool:
	var cycle_time := fposmod(maxf(0.0, elapsed_seconds), RESONANCE_INTERVAL_SECONDS)
	return cycle_time >= RESONANCE_INTERVAL_SECONDS - RESONANCE_CUE_SECONDS


static func resonance_band(elapsed_seconds: float) -> Vector2:
	return (
		Vector2(RESONANCE_SHIFTED_INNER, RESONANCE_SHIFTED_OUTER)
		if resonance_shifted(elapsed_seconds)
		else Vector2(RESONANCE_INNER, RESONANCE_OUTER)
	)


static func resonance_damage_multiplier(distance: float, elapsed_seconds: float) -> float:
	var band := resonance_band(elapsed_seconds)
	return 1.0 if distance >= band.x and distance <= band.y else RESONANCE_OUTSIDE_DAMAGE_SCALE


static func overload_active(elapsed_seconds: float) -> bool:
	if elapsed_seconds < OVERLOAD_FIRST_DELAY:
		return false
	return fposmod(elapsed_seconds - OVERLOAD_FIRST_DELAY, OVERLOAD_INTERVAL_SECONDS) < OVERLOAD_ACTIVE_SECONDS


static func overload_cadence_delta(delta: float, elapsed_seconds: float) -> float:
	return delta / OVERLOAD_CADENCE_SCALE if overload_active(elapsed_seconds) else delta
