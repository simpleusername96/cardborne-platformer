extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const Policy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")
const LocalSteering = preload("res://scripts/enemies/vehicle_enemy_local_steering.gd")
const UpdateSchedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")

const STATIONARY_ARCHETYPES: Array[StringName] = [
	&"ordinary_fixed_ranged_01",
	&"ordinary_fixed_area_01",
	&"ordinary_fixed_ranged_02",
	&"ordinary_fixed_beam_01",
	&"ordinary_fixed_support_01",
	&"boss_actor",
]

var failures: Array[String] = []


func _initialize() -> void:
	_validate_family_coverage()
	_validate_direct_seek()
	_validate_route_contracts()
	_validate_cached_profile_equivalence()
	_validate_cadence_and_overlap_contracts()
	_finish()


func _validate_family_coverage() -> void:
	for archetype in Archetypes.DEFINITIONS:
		var definition: Dictionary = Archetypes.DEFINITIONS[archetype]
		var expected := (
			Policy.STATIONARY
			if archetype in STATIONARY_ARCHETYPES
			else Policy.PURSUIT
		)
		_expect(
			Policy.family(archetype, StringName(definition["behavior"])) == expected,
			"%s resolves to the simplified movement family" % archetype
		)
	_expect(
		Policy.family(&"ordinary_mine", &"ordinary_mine") == Policy.STATIONARY,
		"unknown ordinary hazards do not become mobile implicitly"
	)
	_expect(
		Policy.DISTANCE_BANDS.is_empty(),
		"direct pursuit owns no role-specific distance bands"
	)


func _validate_direct_seek() -> void:
	var target := Vector2(240.0, -80.0)
	var expected_direction := target.normalized()
	var mobile_roles: Array[StringName] = [
		&"ordinary_melee_01",
		&"ordinary_lane_01",
		&"ordinary_growth_01",
		&"ordinary_beam_01",
		&"ordinary_range_01",
		&"ordinary_support_01",
		&"ordinary_support_02",
		&"ordinary_support_03",
	]
	for role in mobile_roles:
		var result := Policy.intent(
			role,
			role,
			Vector2.ZERO,
			target,
			1.0,
			false
		)
		_expect(
			StringName(result["family"]) == Policy.PURSUIT
				and Vector2(result["direction"]).is_equal_approx(expected_direction)
				and bool(result["requests_approach"])
				and StringName(result["mode"]) == &"approach",
			"%s directly seeks the player's current position" % role
		)
		var alternate := Policy.direction(
			role,
			role,
			Vector2.ZERO,
			target,
			-1.0,
			true,
			true
		)
		_expect(
			alternate.is_equal_approx(expected_direction),
			"%s seek direction ignores former strafe, recovery, and lane inputs" % role
		)
		_expect(
			Policy.distance_band(role) == Vector2.ZERO,
			"%s has no active movement distance band" % role
		)

	var fixed := Policy.intent(
		&"ordinary_fixed_ranged_01",
		&"ordinary_fixed_ranged_01",
		Vector2.ZERO,
		target,
		1.0
	)
	_expect(
		StringName(fixed["family"]) == Policy.STATIONARY
			and Vector2(fixed["direction"]) == Vector2.ZERO
			and not bool(fixed["requests_approach"])
			and StringName(fixed["mode"]) == &"hold",
		"fixed ordinary installations remain stationary"
	)
	_expect(
		Policy.direction(
			&"ordinary_melee_01",
			&"ordinary_melee_01",
			target,
			target,
			1.0
		) == Vector2.ZERO,
		"direct seek is stable when enemy and target positions coincide"
	)


func _validate_route_contracts() -> void:
	var mobile := Policy.intent(
		&"ordinary_lane_01",
		&"ordinary_lane_01",
		Vector2.ZERO,
		Vector2(600.0, 0.0),
		1.0
	)
	_expect(
		not Policy.route_guidance_requested(mobile, false)
			and Policy.route_guidance_requested(mobile, true),
		"route guidance is reserved for blocked direct pursuit"
	)
	_expect(
		not Policy.line_of_fire_recovery_requested(
			&"ordinary_lane_01",
			&"ordinary_lane_01",
			Vector2.ZERO,
			Vector2(400.0, 0.0),
			true
		),
		"blocked firing lanes do not create a separate movement behavior"
	)
	_expect(
		not Policy.hot_route_guidance_requested(false, false, true)
			and Policy.hot_route_guidance_requested(true, true, true),
		"hot route guidance ignores the retired firing-lane recovery input"
	)


func _validate_cached_profile_equivalence() -> void:
	for archetype in Archetypes.DEFINITIONS:
		var definition: Dictionary = Archetypes.DEFINITIONS[archetype]
		var role := StringName(definition["behavior"])
		var movement_family := Policy.family(archetype, role)
		for target in [Vector2(120.0, 35.0), Vector2(720.0, -90.0)]:
			for recovering in [false, true]:
				for blocked in [false, true]:
					_expect(
						Policy.direction(
							archetype,
							role,
							Vector2.ZERO,
							target,
							-1.0,
							recovering,
							blocked
						).is_equal_approx(
							Policy.direction_for_profile(
								movement_family,
								role,
								Vector2.ZERO,
								Vector2.ZERO,
								target,
								-1.0,
								recovering,
								blocked
							)
						),
						"%s cached direction matches the public policy" % archetype
					)
					_expect(
						Policy.requests_approach(
							archetype,
							role,
							Vector2.ZERO,
							target,
							recovering
						) == Policy.requests_approach_for_profile(
							movement_family,
							role,
							Vector2.ZERO,
							Vector2.ZERO,
							target,
							recovering
						),
						"%s cached approach matches the public policy" % archetype
					)
					_expect(
						not Policy.line_of_fire_recovery_for_profile(
							movement_family,
							Vector2.ZERO,
							Vector2.ZERO,
							target,
							blocked,
							recovering
						),
						"%s has no cached firing-lane recovery" % archetype
					)


func _validate_cadence_and_overlap_contracts() -> void:
	_expect(
		is_equal_approx(UpdateSchedule.DECISION_INTERVAL, 0.10)
			and is_equal_approx(UpdateSchedule.NEAR_MOTION_INTERVAL, 1.0 / 30.0)
			and is_equal_approx(UpdateSchedule.FAR_MOTION_INTERVAL, 1.0 / 20.0),
		"simplified pursuit preserves 10 Hz decisions and 30/20 Hz motion"
	)
	_expect(
		LocalSteering.MAX_OVERLAP_NEIGHBORS == 8,
		"simplified pursuit preserves the eight-neighbor overlap ceiling"
	)
	var capped := Policy.smooth_velocity(
		Vector2(500.0, 0.0),
		Vector2(500.0, 500.0),
		Policy.PURSUIT_RESPONSE,
		0.5,
		120.0
	)
	_expect(
		capped.length() <= 120.001,
		"smoothed pursuit never exceeds the role speed"
	)
	_expect(
		Policy.turn_response(Policy.PURSUIT) == Policy.PURSUIT_RESPONSE
			and Policy.turn_response(Policy.STANDOFF) == Policy.PURSUIT_RESPONSE
			and Policy.turn_response(Policy.ESCORT) == Policy.PURSUIT_RESPONSE
			and Policy.turn_response(Policy.SUPPORT) == Policy.PURSUIT_RESPONSE
			and Policy.turn_response(Policy.STATIONARY) == 0.0,
		"legacy mobile labels fall back to the one pursuit response"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_MOVEMENT_POLICY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
