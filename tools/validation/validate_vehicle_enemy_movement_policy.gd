extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const Policy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EncounterDirector = preload(
	"res://scripts/encounters/vehicle_encounter_director.gd"
)
const LocalSteering = preload("res://scripts/enemies/vehicle_enemy_local_steering.gd")
const UpdateSchedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_family_coverage()
	_validate_band_oracles()
	_validate_continuity_and_recovery()
	_validate_route_and_speed_contracts()
	_validate_cached_profile_equivalence()
	_validate_cadence_and_overlap_contracts()
	_finish()


func _validate_family_coverage() -> void:
	var expected := {
		&"ordinary_melee_01":Policy.PURSUIT,
		&"ordinary_edge_01":Policy.PURSUIT,
		&"ordinary_pull_01":Policy.PURSUIT,
		&"ordinary_shield_01":Policy.PURSUIT,
		&"ordinary_pulse_01":Policy.PURSUIT,
		&"ordinary_area_01":Policy.PURSUIT,
		&"ordinary_ranged_01":Policy.STANDOFF,
		&"ordinary_lane_01":Policy.STANDOFF,
		&"ordinary_gap_01":Policy.STANDOFF,
		&"ordinary_growth_01":Policy.STANDOFF,
		&"ordinary_beam_01":Policy.STANDOFF,
		&"ordinary_range_01":Policy.STANDOFF,
		&"ordinary_sweep_01":Policy.PURSUIT,
		&"ordinary_melee_02":Policy.PURSUIT,
		&"ordinary_support_02":Policy.ESCORT,
		&"ordinary_support_01":Policy.SUPPORT,
		&"ordinary_support_03":Policy.SUPPORT,
		&"ordinary_fixed_ranged_01":Policy.STATIONARY,
		&"ordinary_fixed_area_01":Policy.STATIONARY,
		&"ordinary_fixed_ranged_02":Policy.STATIONARY,
		&"ordinary_fixed_beam_01":Policy.STATIONARY,
		&"ordinary_fixed_support_01":Policy.STATIONARY,
		&"boss_actor":Policy.STATIONARY,
	}
	for archetype in Archetypes.DEFINITIONS:
		var definition: Dictionary = Archetypes.DEFINITIONS[archetype]
		_expect(
			expected.has(archetype)
				and Policy.family(archetype, StringName(definition["behavior"]))
					== expected[archetype],
			"%s resolves exactly one movement family" % archetype
		)


func _validate_band_oracles() -> void:
	for role in Policy.DISTANCE_BANDS:
		var band := Vector2(Policy.DISTANCE_BANDS[role])
		var midpoint := (band.x + band.y) * 0.5
		var result := _intent(role, midpoint, 1.0)
		var direction := Vector2(result["direction"])
		_expect(
			absf(direction.x) <= 0.001 and direction.y > 0.99
				and StringName(result["mode"]) == &"hold"
				and not bool(result["requests_approach"]),
			"%s uses deterministic tangential motion at its band midpoint" % role
		)
		var close := _intent(role, maxf(1.0, band.x - 90.0), 1.0)
		var far := _intent(role, band.y + 90.0, 1.0)
		var lower_edge := _intent(role, band.x, 1.0)
		var upper_edge := _intent(role, band.y, 1.0)
		_expect(
			Vector2(close["direction"]).x < 0.0
				and StringName(close["mode"]) == &"retreat",
			"%s retreats below its distance band" % role
		)
		_expect(
			Vector2(far["direction"]).x > 0.0
				and bool(far["requests_approach"]),
			"%s approaches above its distance band" % role
		)
		_expect(
			Vector2(lower_edge["direction"]).x < -0.99
				and StringName(lower_edge["mode"]) == &"retreat",
			"%s retreats at its exact lower edge" % role
		)
		_expect(
			Vector2(upper_edge["direction"]).x > 0.99
				and bool(upper_edge["requests_approach"]),
			"%s approaches at its exact upper edge" % role
		)


func _validate_continuity_and_recovery() -> void:
	for role in Policy.DISTANCE_BANDS:
		var band := Vector2(Policy.DISTANCE_BANDS[role])
		for edge in [band.x, band.y]:
			var before := Vector2(_intent(role, edge - 0.1, 1.0)["direction"])
			var after := Vector2(_intent(role, edge + 0.1, 1.0)["direction"])
			_expect(
				before.dot(after) > 0.99,
				"%s crosses a band edge without an intent flip" % role
			)
	var positive := Vector2(_intent(&"ordinary_gap_01", 465.0, 1.0)["direction"])
	var replay := Vector2(_intent(&"ordinary_gap_01", 465.0, 1.0)["direction"])
	var negative := Vector2(_intent(&"ordinary_gap_01", 465.0, -1.0)["direction"])
	_expect(
		positive == replay and positive.y > 0.99 and negative.y < -0.99,
		"strafe sign is deterministic"
	)
	for strafe_sign in [-1.0, 1.0]:
		var edge_enemy_recovery := Policy.intent(
			&"ordinary_edge_01", &"ordinary_edge_01", Vector2.ZERO, Vector2(200.0, 0.0), strafe_sign, true
		)
		var edge_enemy_direction := Vector2(edge_enemy_recovery["direction"])
		_expect(
			absf(edge_enemy_direction.x) <= 0.001
				and absf(edge_enemy_direction.y) > 0.99
				and edge_enemy_direction.y * strafe_sign > 0.99
				and not bool(edge_enemy_recovery["requests_approach"]),
			"Chaser recovery peels laterally without negative radial motion for either strafe sign"
		)
	var pull_enemy_recovery := Policy.intent(
		&"ordinary_pull_01", &"ordinary_pull_01", Vector2.ZERO, Vector2(200.0, 0.0), -1.0, true
	)
	_expect(
		Vector2(pull_enemy_recovery["direction"]).x < -0.99
			and not bool(pull_enemy_recovery["requests_approach"]),
		"pull_enemy recovery reverses without requesting a route"
	)
	var smoothed := Policy.smooth_velocity(
		Vector2(-155.0, 0.0), Vector2(155.0, 0.0), Policy.STANDOFF_RESPONSE,
		1.0 / 60.0, 155.0
	)
	_expect(smoothed.x < 0.0, "one motion tick cannot reverse a ranged velocity")


func _validate_route_and_speed_contracts() -> void:
	var hold := _intent(&"ordinary_lane_01", 415.0, 1.0)
	var approach := _intent(&"ordinary_lane_01", 620.0, 1.0)
	_expect(
		not Policy.route_guidance_requested(hold, true)
			and not Policy.route_guidance_requested(approach, false)
			and Policy.route_guidance_requested(approach, true),
		"route guidance requires both approach intent and a blocked direct path"
	)
	var blocked_direction := Policy.direction(
		&"ordinary_lane_01",
		&"ordinary_lane_01",
		Vector2.ZERO,
		Vector2(415.0, 0.0),
		1.0,
		false,
		true
	)
	var recovery_requested := Policy.line_of_fire_recovery_requested(
		&"ordinary_lane_01",
		&"ordinary_lane_01",
		Vector2.ZERO,
		Vector2(415.0, 0.0),
		true
	)
	_expect(
		blocked_direction.y > 0.99
			and recovery_requested
			and Policy.hot_route_guidance_requested(
				false, false, recovery_requested
			),
		"blocked standoff movement requests a lateral firing-lane recovery"
	)
	_expect(
		not Policy.line_of_fire_recovery_requested(
			&"ordinary_lane_01",
			&"ordinary_lane_01",
			Vector2.ZERO,
			Vector2(200.0, 0.0),
			true
		),
		"a ranged enemy that is too close retreats before lane recovery"
	)
	var artillery_attack: Dictionary = (
		AttackContract.ORDINARY_ATTACKS[&"ordinary_growth_01"]
	)
	var artillery_band := Policy.distance_band(&"ordinary_growth_01")
	var artillery_reach := (
		EncounterDirector.effective_hostile_projectile_speed(
			float(artillery_attack["speed"])
		)
		* AttackContract.HOSTILE_PROJECTILE_LIFETIME
		+ float(artillery_attack["origin_offset"])
	)
	_expect(
		artillery_band == Vector2(440.0, 600.0)
			and artillery_reach + 0.001 >= artillery_band.y,
		"artillery holds inside the stationary-target reach of its real shell"
	)


func _validate_cached_profile_equivalence() -> void:
	for archetype in Archetypes.DEFINITIONS:
		var definition: Dictionary = Archetypes.DEFINITIONS[archetype]
		var role := StringName(definition["behavior"])
		var movement_family := Policy.family(archetype, role)
		var band := Policy.distance_band(role)
		for distance in [120.0, 420.0, 720.0]:
			var target := Vector2(distance, 35.0)
			for recovering in [false, true]:
				for blocked in [false, true]:
					_expect(
						Policy.direction(
							archetype, role, Vector2.ZERO, target, -1.0,
							recovering, blocked
						).is_equal_approx(
							Policy.direction_for_profile(
								movement_family, role, band, Vector2.ZERO,
								target, -1.0, recovering, blocked
							)
						),
						"%s cached direction matches the public policy" % archetype
					)
					_expect(
						Policy.requests_approach(
							archetype, role, Vector2.ZERO, target, recovering
						) == Policy.requests_approach_for_profile(
							movement_family, role, band, Vector2.ZERO, target,
							recovering
						),
						"%s cached approach matches the public policy" % archetype
					)
					_expect(
						Policy.line_of_fire_recovery_requested(
							archetype, role, Vector2.ZERO, target, blocked,
							recovering
						) == Policy.line_of_fire_recovery_for_profile(
							movement_family, band, Vector2.ZERO, target, blocked,
							recovering
						),
						"%s cached lane recovery matches the public policy" % archetype
					)


func _validate_cadence_and_overlap_contracts() -> void:
	_expect(
		is_equal_approx(UpdateSchedule.DECISION_INTERVAL, 0.10)
			and is_equal_approx(UpdateSchedule.NEAR_MOTION_INTERVAL, 1.0 / 30.0)
			and is_equal_approx(UpdateSchedule.FAR_MOTION_INTERVAL, 1.0 / 20.0),
		"movement policy preserves 10 Hz decisions and 30/20 Hz motion"
	)
	_expect(
		LocalSteering.MAX_OVERLAP_NEIGHBORS == 8,
		"movement policy preserves the eight-neighbor overlap ceiling"
	)
	var capped := Policy.smooth_velocity(
		Vector2(500.0, 0.0), Vector2(500.0, 500.0),
		Policy.PURSUIT_RESPONSE, 0.5, 120.0
	)
	_expect(capped.length() <= 120.001, "smoothed movement never exceeds role speed")
	_expect(
		Policy.turn_response(Policy.PURSUIT) == 9.0
			and Policy.turn_response(Policy.STANDOFF) == 6.0
			and Policy.turn_response(Policy.ESCORT) == 5.0
			and Policy.turn_response(Policy.SUPPORT) == 5.0,
		"movement families expose the locked turn responses"
	)


func _intent(role: StringName, distance: float, strafe_sign: float) -> Dictionary:
	return Policy.intent(role, role, Vector2.ZERO, Vector2(distance, 0.0), strafe_sign)


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
