class_name VehicleEnemyMovementPolicy
extends RefCounted

## Pure role-distance policy. Attack ranges and timing remain in their combat
## owners; this module only resolves continuous ordinary movement intent.

const PURSUIT: StringName = &"pursuit"
const STANDOFF: StringName = &"standoff"
const ESCORT: StringName = &"escort"
const SUPPORT: StringName = &"support"
const STATIONARY: StringName = &"stationary"

const PURSUIT_ARCHETYPES: Array[StringName] = [
	&"ordinary_pursuer_t1", &"ordinary_pursuer_t2", &"ordinary_pursuer_t3",
	&"ordinary_charger_t1", &"ordinary_charger_t2", &"ordinary_charger_t3",
]
const STANDOFF_ARCHETYPES: Array[StringName] = [
	&"ordinary_emitter_t1", &"ordinary_emitter_t2", &"ordinary_emitter_t3",
]
const ESCORT_ARCHETYPES: Array[StringName] = [
	&"ordinary_defender_t1", &"ordinary_defender_t2", &"ordinary_defender_t3",
]
const SUPPORT_ARCHETYPES: Array[StringName] = [
	&"ordinary_coordinator_t1", &"ordinary_coordinator_t2", &"ordinary_coordinator_t3",
]
const STATIONARY_ARCHETYPES: Array[StringName] = [
	&"boss_pattern_fixed_beam_01", &"boss_actor",
]

const DISTANCE_BANDS := {
	&"ordinary_lane_01":Vector2(330.0, 500.0),
	&"ordinary_gap_01":Vector2(390.0, 540.0),
	&"ordinary_support_02":Vector2(300.0, 470.0),
	&"ordinary_growth_01":Vector2(440.0, 600.0),
	&"ordinary_pulse_01":Vector2(300.0, 470.0),
	# Beam Ordinary Enemy Lv.1 keeps its full warning line outside ordinary brawl range.
	&"ordinary_beam_01":Vector2(520.0, 680.0),
	# Range Ordinary Enemy Lv.1 deliberately remains in its tangential pressure band.
	&"ordinary_range_01":Vector2(320.0, 460.0),
	&"ordinary_support_01":Vector2(430.0, 620.0),
	&"ordinary_support_03":Vector2(430.0, 620.0),
}

const PURSUIT_RESPONSE := 9.0
const STANDOFF_RESPONSE := 6.0
const SUPPORT_RESPONSE := 5.0
const PURSUER_RECOVERY_FORWARD_WEIGHT := 0.65
const CHARGER_RECOVERY_FORWARD_WEIGHT := 0.55


static func family(archetype: StringName, role: StringName) -> StringName:
	if archetype in PURSUIT_ARCHETYPES:
		return PURSUIT
	if archetype in STANDOFF_ARCHETYPES:
		return STANDOFF
	if archetype in ESCORT_ARCHETYPES:
		return ESCORT
	if archetype in SUPPORT_ARCHETYPES:
		return SUPPORT
	if archetype in STATIONARY_ARCHETYPES:
		return STATIONARY
	# Compatibility fixtures can specify a behavior without an archetype.
	if role in [&"ordinary_edge_01", &"ordinary_pull_01", &"ordinary_sweep_01", &"ordinary_melee_02"]:
		return PURSUIT
	if role in [&"ordinary_lane_01", &"ordinary_gap_01", &"ordinary_growth_01", &"ordinary_beam_01", &"ordinary_range_01"]:
		return STANDOFF
	if role == &"ordinary_support_02":
		return ESCORT
	if role == &"ordinary_shield_01":
		return ESCORT
	if role in [&"ordinary_pulse_01", &"ordinary_support_01", &"ordinary_support_03"]:
		return SUPPORT
	return STATIONARY


static func distance_band(role: StringName) -> Vector2:
	return Vector2(DISTANCE_BANDS.get(role, Vector2.ZERO))


static func turn_response(movement_family: StringName) -> float:
	match movement_family:
		PURSUIT:
			return PURSUIT_RESPONSE
		STANDOFF:
			return STANDOFF_RESPONSE
		ESCORT, SUPPORT:
			return SUPPORT_RESPONSE
	return 0.0


static func intent(
	archetype: StringName,
	role: StringName,
	position: Vector2,
	target: Vector2,
	strafe_sign: float,
	recovering: bool = false
) -> Dictionary:
	var movement_family := family(archetype, role)
	var movement_direction := direction(
		archetype, role, position, target, strafe_sign, recovering
	)
	var approach := requests_approach(
		archetype, role, position, target, recovering
	)
	var mode := movement_mode(
		archetype, role, position, target, recovering
	)
	return _result(
		movement_family,
		movement_direction,
		approach,
		mode
	)


static func direction(
	archetype: StringName,
	role: StringName,
	position: Vector2,
	target: Vector2,
	strafe_sign: float,
	recovering: bool = false,
	line_of_fire_blocked: bool = false
) -> Vector2:
	var movement_family := family(archetype, role)
	return direction_for_profile(
		movement_family,
		role,
		distance_band(role),
		position,
		target,
		strafe_sign,
		recovering,
		line_of_fire_blocked
	)


static func direction_for_profile(
	movement_family: StringName,
	role: StringName,
	band: Vector2,
	position: Vector2,
	target: Vector2,
	strafe_sign: float,
	recovering: bool = false,
	line_of_fire_blocked: bool = false
) -> Vector2:
	var offset := target - position
	var distance := maxf(1.0, offset.length())
	var radial := offset / distance
	if movement_family == STATIONARY:
		return Vector2.ZERO
	if movement_family == PURSUIT:
		if recovering and role == &"ordinary_edge_01":
			return _forward_tangent_direction(
				radial, strafe_sign, PURSUER_RECOVERY_FORWARD_WEIGHT
			)
		if recovering and role == &"ordinary_pull_01":
			return _forward_tangent_direction(
				radial, strafe_sign, CHARGER_RECOVERY_FORWARD_WEIGHT
			)
		return radial

	if band == Vector2.ZERO:
		return radial
	var signed_error := _signed_band_error(distance, band)
	var tangent := radial.rotated(signf(strafe_sign) * PI * 0.5)
	if line_of_fire_blocked and signed_error >= -0.35:
		return (
			tangent * 0.82
			+ radial * maxf(0.0, signed_error) * 0.18
		).normalized()
	var tangential_weight := 1.0 - absf(signed_error)
	return (
		radial * signed_error
		+ tangent * tangential_weight
	).normalized()


static func requests_approach(
	archetype: StringName,
	role: StringName,
	position: Vector2,
	target: Vector2,
	recovering: bool = false
) -> bool:
	var movement_family := family(archetype, role)
	return requests_approach_for_profile(
		movement_family,
		role,
		distance_band(role),
		position,
		target,
		recovering
	)


static func requests_approach_for_profile(
	movement_family: StringName,
	role: StringName,
	band: Vector2,
	position: Vector2,
	target: Vector2,
	recovering: bool = false
) -> bool:
	if movement_family == STATIONARY:
		return false
	if movement_family == PURSUIT:
		return true
	if band == Vector2.ZERO:
		return true
	return _signed_band_error(position.distance_to(target), band) > 0.001


static func movement_mode(
	archetype: StringName,
	role: StringName,
	position: Vector2,
	target: Vector2,
	recovering: bool = false
) -> StringName:
	var movement_family := family(archetype, role)
	if movement_family == STATIONARY:
		return &"hold"
	if recovering and role in [&"ordinary_edge_01", &"ordinary_pull_01"]:
		return &"recover"
	if movement_family == PURSUIT or distance_band(role) == Vector2.ZERO:
		return &"approach"
	var signed_error := _signed_band_error(
		position.distance_to(target), distance_band(role)
	)
	return (
		&"approach" if signed_error > 0.001
		else &"retreat" if signed_error < -0.001
		else &"hold"
	)


static func line_of_fire_recovery_requested(
	archetype: StringName,
	role: StringName,
	position: Vector2,
	target: Vector2,
	direct_path_blocked: bool,
	recovering: bool = false
) -> bool:
	if not direct_path_blocked or recovering:
		return false
	var movement_family := family(archetype, role)
	return line_of_fire_recovery_for_profile(
		movement_family,
		distance_band(role),
		position,
		target,
		direct_path_blocked,
		recovering
	)


static func line_of_fire_recovery_for_profile(
	movement_family: StringName,
	band: Vector2,
	position: Vector2,
	target: Vector2,
	direct_path_blocked: bool,
	recovering: bool = false
) -> bool:
	if not direct_path_blocked or recovering:
		return false
	if movement_family != STANDOFF:
		return false
	return (
		band != Vector2.ZERO
		and _signed_band_error(position.distance_to(target), band) >= -0.35
	)


static func route_guidance_requested(
	intent_result: Dictionary,
	direct_path_blocked: bool
) -> bool:
	return bool(intent_result.get("requests_approach", false)) and direct_path_blocked


static func hot_route_guidance_requested(
	requests_direct_approach: bool,
	direct_approach_blocked: bool,
	requests_line_of_fire_recovery: bool
) -> bool:
	return (
		(requests_direct_approach and direct_approach_blocked)
		or requests_line_of_fire_recovery
	)


static func smooth_velocity(
	current: Vector2,
	desired: Vector2,
	response: float,
	delta: float,
	speed_cap: float
) -> Vector2:
	if delta <= 0.0 or response <= 0.0:
		return desired.limit_length(speed_cap)
	var weight := 1.0 - exp(-response * delta)
	return current.lerp(desired, weight).limit_length(speed_cap)


static func _result(
	movement_family: StringName,
	direction: Vector2,
	requests_approach: bool,
	mode: StringName
) -> Dictionary:
	return {
		"family":movement_family,
		"direction":direction,
		"requests_approach":requests_approach,
		"mode":mode,
	}


static func _signed_band_error(distance: float, band: Vector2) -> float:
	var midpoint := (band.x + band.y) * 0.5
	var half_width := maxf(1.0, (band.y - band.x) * 0.5)
	return clampf((maxf(1.0, distance) - midpoint) / half_width, -1.0, 1.0)


static func _forward_tangent_direction(
	radial: Vector2,
	strafe_sign: float,
	forward_weight: float
) -> Vector2:
	var tangent := radial.rotated(signf(strafe_sign) * PI * 0.5)
	return (
		radial * forward_weight
		+ tangent * (1.0 - forward_weight)
	).normalized()
