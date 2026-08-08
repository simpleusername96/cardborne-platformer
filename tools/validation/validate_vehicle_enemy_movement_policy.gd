extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const Policy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_family_coverage()
	_validate_band_oracles()
	_validate_continuity_and_recovery()
	_validate_route_and_speed_contracts()
	_finish()


func _validate_family_coverage() -> void:
	var expected := {
		&"scrap_drone":Policy.PURSUIT,
		&"chaser":Policy.PURSUIT,
		&"rammer":Policy.PURSUIT,
		&"bulkhead_guard":Policy.PURSUIT,
		&"splitter_barge":Policy.PURSUIT,
		&"spark_minelet":Policy.PURSUIT,
		&"needle_drone":Policy.STANDOFF,
		&"shooter":Policy.STANDOFF,
		&"controller":Policy.STANDOFF,
		&"artillery_spotter":Policy.STANDOFF,
		&"shield_escort":Policy.ESCORT,
		&"repair_tender":Policy.SUPPORT,
		&"drone_carrier":Policy.SUPPORT,
		&"turret":Policy.STATIONARY,
		&"mine":Policy.STATIONARY,
		&"interceptor_tower":Policy.STATIONARY,
		&"beam_sentinel":Policy.STATIONARY,
		&"generator":Policy.STATIONARY,
		&"stage_boss":Policy.STATIONARY,
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
	var midpoint_cases := {
		&"shooter":415.0,
		&"controller":465.0,
		&"artillery_spotter":640.0,
		&"shield_escort":385.0,
		&"repair_tender":525.0,
	}
	for role in midpoint_cases:
		var result := _intent(role, float(midpoint_cases[role]), 1.0)
		var direction := Vector2(result["direction"])
		_expect(
			absf(direction.x) <= 0.001 and direction.y > 0.99
				and StringName(result["mode"]) == &"hold"
				and not bool(result["requests_approach"]),
			"%s uses deterministic tangential motion at its band midpoint" % role
		)
	var close := _intent(&"shooter", 240.0, 1.0)
	var far := _intent(&"shooter", 620.0, 1.0)
	_expect(
		Vector2(close["direction"]).x < -0.99
			and StringName(close["mode"]) == &"retreat",
		"close ranged roles retreat"
	)
	_expect(
		Vector2(far["direction"]).x > 0.99
			and bool(far["requests_approach"]),
		"far ranged roles approach"
	)


func _validate_continuity_and_recovery() -> void:
	for edge in [330.0, 500.0]:
		var before := Vector2(_intent(&"shooter", edge - 0.1, 1.0)["direction"])
		var after := Vector2(_intent(&"shooter", edge + 0.1, 1.0)["direction"])
		_expect(before.dot(after) > 0.99, "shooter crosses band edge without an intent flip")
	var positive := Vector2(_intent(&"controller", 465.0, 1.0)["direction"])
	var replay := Vector2(_intent(&"controller", 465.0, 1.0)["direction"])
	var negative := Vector2(_intent(&"controller", 465.0, -1.0)["direction"])
	_expect(
		positive == replay and positive.y > 0.99 and negative.y < -0.99,
		"strafe sign is deterministic"
	)
	var chaser_recovery := Policy.intent(
		&"chaser", &"chaser", Vector2.ZERO, Vector2(200.0, 0.0), 1.0, true
	)
	_expect(
		Vector2(chaser_recovery["direction"]).x < 0.0
			and not bool(chaser_recovery["requests_approach"]),
		"pursuit recovery backs out without requesting a route"
	)
	var smoothed := Policy.smooth_velocity(
		Vector2(-155.0, 0.0), Vector2(155.0, 0.0), Policy.STANDOFF_RESPONSE,
		1.0 / 60.0, 155.0
	)
	_expect(smoothed.x < 0.0, "one motion tick cannot reverse a ranged velocity")


func _validate_route_and_speed_contracts() -> void:
	var hold := _intent(&"shooter", 415.0, 1.0)
	var approach := _intent(&"shooter", 620.0, 1.0)
	_expect(
		not Policy.route_guidance_requested(hold, true)
			and not Policy.route_guidance_requested(approach, false)
			and Policy.route_guidance_requested(approach, true),
		"route guidance requires both approach intent and a blocked direct path"
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
