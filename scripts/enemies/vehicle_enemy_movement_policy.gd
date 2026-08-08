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
	&"artillery_spotter":Vector2(520.0, 760.0),
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
	var offset := target - position
	var distance := maxf(1.0, offset.length())
	var radial := offset / distance
	if movement_family == STATIONARY:
		return _result(movement_family, Vector2.ZERO, false, &"hold")
	if movement_family == PURSUIT:
		if recovering and role == &"chaser":
			return _result(
				movement_family,
				-radial.rotated(signf(strafe_sign) * 0.35),
				false,
				&"recover"
			)
		if recovering and role == &"rammer":
			return _result(movement_family, -radial, false, &"recover")
		return _result(movement_family, radial, true, &"approach")

	var band := distance_band(role)
	if band == Vector2.ZERO:
		return _result(movement_family, radial, true, &"approach")
	var midpoint := (band.x + band.y) * 0.5
	var half_width := maxf(1.0, (band.y - band.x) * 0.5)
	var signed_error := clampf((distance - midpoint) / half_width, -1.0, 1.0)
	var tangential_weight := 1.0 - absf(signed_error)
	var tangent := radial.rotated(signf(strafe_sign) * PI * 0.5)
	var direction := (
		radial * signed_error
		+ tangent * tangential_weight
	).normalized()
	var mode: StringName = (
		&"approach" if signed_error > 0.001
		else &"retreat" if signed_error < -0.001
		else &"hold"
	)
	return _result(
		movement_family,
		direction,
		signed_error > 0.001,
		mode
	)


static func route_guidance_requested(
	intent_result: Dictionary,
	direct_path_blocked: bool
) -> bool:
	return bool(intent_result.get("requests_approach", false)) and direct_path_blocked


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
