class_name VehicleLateBossMechanics
extends RefCounted

## Owns the state schedules and damage rules unique to stages 9-12. Pattern
## sequencing stays in VehicleBossPatterns and collision stays in VehicleRun.

const REFLECT_ARC_RADIANS := deg_to_rad(100.0)
const REFLECT_ACTIVE_SECONDS := 5.0
const REFLECT_EXPOSED_SECONDS := 15.0
const REFLECT_CUE_SECONDS := 1.0
const REFLECT_DAMAGE_SCALE := 0.35
const REFLECT_DAMAGE_CAP := 24.0

const RESONANCE_MAX_DISTANCE := 760.0
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

const CROSSING_WALL_BASE_SPEED := 320.0
const CROSSING_WALL_SPEED_SCALE := 0.70
const CROSSING_WALL_DAMAGE_SCALE := 0.70
const COMPRESSION_WALL_BASE_SPEED := 620.0
const COMPRESSION_WALL_SPEED_SCALE := 0.70
const COMPRESSION_WALL_DAMAGE_SCALE := 0.70


static func crossing_wall_speed() -> float:
	return CROSSING_WALL_BASE_SPEED * CROSSING_WALL_SPEED_SCALE


static func crossing_wall_damage(base_damage: float) -> float:
	return maxf(0.0, base_damage) * CROSSING_WALL_DAMAGE_SCALE


static func compression_wall_speed() -> float:
	return COMPRESSION_WALL_BASE_SPEED * COMPRESSION_WALL_SPEED_SCALE


static func compression_wall_damage(base_damage: float) -> float:
	return maxf(0.0, base_damage) * COMPRESSION_WALL_DAMAGE_SCALE


static func reflection_active(elapsed_seconds: float) -> bool:
	return reflection_cycle_time(elapsed_seconds) >= REFLECT_EXPOSED_SECONDS


static func reflection_cue_active(elapsed_seconds: float) -> bool:
	var cycle_time := reflection_cycle_time(elapsed_seconds)
	return cycle_time >= REFLECT_EXPOSED_SECONDS - REFLECT_CUE_SECONDS \
		and cycle_time < REFLECT_EXPOSED_SECONDS


static func reflection_cycle_time(elapsed_seconds: float) -> float:
	return fposmod(
		maxf(0.0, elapsed_seconds), REFLECT_EXPOSED_SECONDS + REFLECT_ACTIVE_SECONDS
	)


static func hits_reflection_plate(
	facing: Vector2,
	incoming_velocity: Vector2,
	elapsed_seconds: float
) -> bool:
	if not reflection_active(elapsed_seconds):
		return false
	return hits_reflection_arc(facing, incoming_velocity)


static func hits_reflection_arc(
	facing: Vector2,
	incoming_velocity: Vector2
) -> bool:
	var forward := facing.normalized()
	var toward_source := -incoming_velocity.normalized()
	if forward.is_zero_approx() or toward_source.is_zero_approx():
		return false
	return absf(forward.angle_to(toward_source)) <= REFLECT_ARC_RADIANS * 0.5


static func reflected_damage(original_damage: float) -> float:
	return minf(REFLECT_DAMAGE_CAP, maxf(0.0, original_damage) * REFLECT_DAMAGE_SCALE)


static func resonance_max_distance() -> float:
	return RESONANCE_MAX_DISTANCE


static func resonance_damage_multiplier(
	distance: float,
	_elapsed_seconds: float = 0.0
) -> float:
	return 1.0 if distance <= RESONANCE_MAX_DISTANCE else RESONANCE_OUTSIDE_DAMAGE_SCALE


static func overload_active(elapsed_seconds: float) -> bool:
	if elapsed_seconds < OVERLOAD_FIRST_DELAY:
		return false
	return fposmod(elapsed_seconds - OVERLOAD_FIRST_DELAY, OVERLOAD_INTERVAL_SECONDS) < OVERLOAD_ACTIVE_SECONDS


static func overload_cadence_delta(delta: float, elapsed_seconds: float) -> float:
	return delta / OVERLOAD_CADENCE_SCALE if overload_active(elapsed_seconds) else delta
