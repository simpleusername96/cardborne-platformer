class_name VehicleEnemyMovementPolicy
extends RefCounted

## Default ordinary-enemy movement is direct seek. Attack range, timing, and
## commitment remain in their combat owners; this module only supplies a safe
## desired movement vector toward the player's current craft position.

const PURSUIT: StringName = &"pursuit"
const STANDOFF: StringName = &"standoff"
const ESCORT: StringName = &"escort"
const SUPPORT: StringName = &"support"
const STATIONARY: StringName = &"stationary"

# Compatibility identifiers remain because runtime diagnostics and fixtures can
# still contain the previous labels. No live mobile archetype resolves to them.
const MOBILE_ARCHETYPES: Array[StringName] = [
	&"ordinary_melee_01",
	&"ordinary_edge_01",
	&"ordinary_pull_01",
	&"ordinary_shield_01",
	&"ordinary_pulse_01",
	&"ordinary_area_01",
	&"ordinary_sweep_01",
	&"ordinary_melee_02",
	&"ordinary_reflect_01",
	&"ordinary_overload_01",
	&"ordinary_ranged_01",
	&"ordinary_lane_01",
	&"ordinary_gap_01",
	&"ordinary_growth_01",
	&"ordinary_beam_01",
	&"ordinary_range_01",
	&"ordinary_compression_01",
	&"ordinary_resonance_01",
	&"ordinary_support_01",
	&"ordinary_support_02",
	&"ordinary_support_03",
]

# Kept as a public compatibility surface for validators and runtime callers.
# Direct pursuit owns no role-specific distance bands.
const DISTANCE_BANDS := {}

const PURSUIT_RESPONSE := 9.0
const STANDOFF_RESPONSE := PURSUIT_RESPONSE
const SUPPORT_RESPONSE := PURSUIT_RESPONSE


static func family(archetype: StringName, role: StringName) -> StringName:
	if archetype in MOBILE_ARCHETYPES or role in MOBILE_ARCHETYPES:
		return PURSUIT
	return STATIONARY


static func distance_band(_role: StringName) -> Vector2:
	return Vector2.ZERO


static func turn_response(movement_family: StringName) -> float:
	return 0.0 if movement_family == STATIONARY else PURSUIT_RESPONSE


static func intent(
	archetype: StringName,
	role: StringName,
	position: Vector2,
	target: Vector2,
	strafe_sign: float,
	recovering: bool = false
) -> Dictionary:
	var movement_family := family(archetype, role)
	return _result(
		movement_family,
		direction(
			archetype,
			role,
			position,
			target,
			strafe_sign,
			recovering
		),
		requests_approach(
			archetype,
			role,
			position,
			target,
			recovering
		),
		movement_mode(
			archetype,
			role,
			position,
			target,
			recovering
		)
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
	return direction_for_profile(
		family(archetype, role),
		role,
		Vector2.ZERO,
		position,
		target,
		strafe_sign,
		recovering,
		line_of_fire_blocked
	)


static func direction_for_profile(
	movement_family: StringName,
	_role: StringName,
	_band: Vector2,
	position: Vector2,
	target: Vector2,
	_strafe_sign: float,
	_recovering: bool = false,
	_line_of_fire_blocked: bool = false
) -> Vector2:
	if movement_family == STATIONARY:
		return Vector2.ZERO
	return position.direction_to(target)


static func requests_approach(
	archetype: StringName,
	role: StringName,
	position: Vector2,
	target: Vector2,
	recovering: bool = false
) -> bool:
	return requests_approach_for_profile(
		family(archetype, role),
		role,
		Vector2.ZERO,
		position,
		target,
		recovering
	)


static func requests_approach_for_profile(
	movement_family: StringName,
	_role: StringName,
	_band: Vector2,
	_position: Vector2,
	_target: Vector2,
	_recovering: bool = false
) -> bool:
	return movement_family != STATIONARY


static func movement_mode(
	archetype: StringName,
	role: StringName,
	_position: Vector2,
	_target: Vector2,
	_recovering: bool = false
) -> StringName:
	return &"hold" if family(archetype, role) == STATIONARY else &"approach"


static func line_of_fire_recovery_requested(
	_archetype: StringName,
	_role: StringName,
	_position: Vector2,
	_target: Vector2,
	_direct_path_blocked: bool,
	_recovering: bool = false
) -> bool:
	return false


static func line_of_fire_recovery_for_profile(
	_movement_family: StringName,
	_band: Vector2,
	_position: Vector2,
	_target: Vector2,
	_direct_path_blocked: bool,
	_recovering: bool = false
) -> bool:
	return false


static func route_guidance_requested(
	intent_result: Dictionary,
	direct_path_blocked: bool
) -> bool:
	return bool(intent_result.get("requests_approach", false)) and direct_path_blocked


static func hot_route_guidance_requested(
	requests_direct_approach: bool,
	direct_approach_blocked: bool,
	_requests_line_of_fire_recovery: bool
) -> bool:
	return requests_direct_approach and direct_approach_blocked


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
	direction_value: Vector2,
	requests_approach_value: bool,
	mode: StringName
) -> Dictionary:
	return {
		"family":movement_family,
		"direction":direction_value,
		"requests_approach":requests_approach_value,
		"mode":mode,
	}
