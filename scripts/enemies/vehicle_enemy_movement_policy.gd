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
	&"scrap_drone", &"chaser", &"rammer", &"bulkhead_guard",
	&"splitter_barge", &"spark_minelet",
]
const STANDOFF_ARCHETYPES: Array[StringName] = [
	&"needle_drone", &"shooter", &"controller", &"artillery_spotter",
]
const ESCORT_ARCHETYPES: Array[StringName] = [&"shield_escort"]
const SUPPORT_ARCHETYPES: Array[StringName] = [&"repair_tender", &"drone_carrier"]

const DISTANCE_BANDS := {
	&"shooter":Vector2(330.0, 500.0),
	&"controller":Vector2(390.0, 540.0),
	&"shield_escort":Vector2(300.0, 470.0),
	&"artillery_spotter":Vector2(440.0, 600.0),
	&"repair_tender":Vector2(430.0, 620.0),
	&"drone_carrier":Vector2(430.0, 620.0),
}

const PURSUIT_RESPONSE := 9.0
const STANDOFF_RESPONSE := 6.0
const SUPPORT_RESPONSE := 5.0


static func family(archetype: StringName, role: StringName) -> StringName:
	if archetype in PURSUIT_ARCHETYPES:
		return PURSUIT
	if archetype in STANDOFF_ARCHETYPES:
		return STANDOFF
	if archetype in ESCORT_ARCHETYPES:
		return ESCORT
	if archetype in SUPPORT_ARCHETYPES:
		return SUPPORT
	# Compatibility fixtures can specify a behavior without an archetype.
	if role in [&"chaser", &"rammer", &"bulkhead_guard", &"splitter_barge"]:
		return PURSUIT
	if role in [&"shooter", &"controller", &"artillery_spotter"]:
		return STANDOFF
	if role == &"shield_escort":
		return ESCORT
	if role in [&"repair_tender", &"drone_carrier"]:
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
		if recovering and role == &"chaser":
			# A recovering Chaser peels sideways. It must not keep backing away,
			# because recovery is a short reposition rather than a retreat order.
			return radial.rotated(signf(strafe_sign) * PI * 0.5)
		if recovering and role == &"rammer":
			return -radial
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
		if recovering and role in [&"chaser", &"rammer"]:
			return false
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
	if recovering and role in [&"chaser", &"rammer"]:
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
