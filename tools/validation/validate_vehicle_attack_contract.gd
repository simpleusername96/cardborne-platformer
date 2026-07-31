extends SceneTree

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StatusProfile = preload("res://scripts/combat/vehicle_status_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
	for error in AttackContract.validate_contract():
		failures.append(error)

	_expect(AttackContract.power_tier(10.0) == &"light", "ten damage remains in the light power tier")
	_expect(AttackContract.power_tier(10.1) == &"standard", "damage above ten enters the standard power tier")
	_expect(AttackContract.power_tier(20.0) == &"heavy", "twenty damage enters the heavy power tier")
	_expect(is_equal_approx(AttackContract.hostile_projectile_radius(4.0), 5.0), "light hostile projectile radius is five")
	_expect(is_equal_approx(AttackContract.hostile_projectile_radius(12.0), 6.0), "standard hostile projectile radius is six")
	_expect(is_equal_approx(AttackContract.hostile_projectile_radius(24.0), 7.0), "heavy hostile projectile radius is seven")
	_expect(
		is_equal_approx(
			AttackContract.projectile_danger_half_width(7.0),
			Rules.PLAYER_RADIUS + 7.0
		),
		"projectile danger corridor exactly expands by the player radius"
	)
	_expect(
		is_equal_approx(
			AttackContract.contact_danger_half_width(33.0, 10.0),
			Rules.PLAYER_RADIUS + 43.0
		),
		"contact danger corridor exactly expands by both colliders and padding"
	)
	_expect(
		is_equal_approx(
			AttackContract.beam_danger_half_width(54.0),
			Rules.PLAYER_RADIUS + 27.0
		),
		"beam danger corridor exactly expands by the player radius"
	)
	_expect(
		AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS > 0.0
			and AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS <= 0.4
			and AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS
				< AttackContract.HOSTILE_PROJECTILE_LIFETIME,
		"projectile startup exposes a short lead of at most 0.4 seconds"
	)
	_expect(
		is_zero_approx(AttackContract.warning_readiness(0.8, 0.8))
			and is_equal_approx(AttackContract.warning_readiness(0.4, 0.8), 0.5)
			and is_equal_approx(AttackContract.warning_readiness(0.0, 0.8), 1.0),
		"warning readiness advances monotonically from startup to impact"
	)
	_expect(
		is_equal_approx(AttackContract.radial_damage(20.0, 0.0, 100.0), 20.0),
		"radial damage is full strength at its center"
	)
	_expect(
		is_equal_approx(AttackContract.radial_damage(20.0, 50.0, 100.0), 14.5),
		"radial damage falls linearly at its midpoint"
	)
	_expect(
		is_equal_approx(AttackContract.radial_damage(20.0, 100.0, 100.0), 9.0),
		"radial damage retains forty-five percent strength at its visible edge"
	)
	_expect(
		is_zero_approx(AttackContract.radial_damage(20.0, 100.1, 100.0)),
		"radial damage ends outside its visible boundary"
	)
	_expect(
		is_equal_approx(
			AttackContract.segment_circle_first_t(
				Vector2.ZERO,
				Vector2(100.0, 0.0),
				Vector2(50.0, 0.0),
				10.0
			),
			0.4
		),
		"path clipping returns the first exact circle contact"
	)
	_expect(
		AttackContract.segment_circle_first_t(
			Vector2.ZERO,
			Vector2(100.0, 0.0),
			Vector2(50.0, 30.0),
			10.0
		) == INF,
		"path clipping leaves a missed circle untouched"
	)

	var profile := StatusProfile.new()
	profile.burn_enabled = true
	_expect(
		AttackContract.affinity_for_condition_mask(
			AttackContract.condition_mask_for_profile(profile)
		) == AttackContract.THERMAL,
		"a burn payload presents as thermal"
	)
	profile.poison_enabled = true
	_expect(
		AttackContract.affinity_for_condition_mask(
			AttackContract.condition_mask_for_profile(profile)
		) == AttackContract.HYBRID,
		"stacked burn and poison payloads present as hybrid"
	)
	profile.burn_enabled = false
	profile.poison_enabled = false
	profile.chill_enabled = true
	_expect(
		AttackContract.affinity_for_condition_mask(
			AttackContract.condition_mask_for_profile(profile)
		) == AttackContract.CRYO,
		"a chill payload presents as cryo"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ATTACK_CONTRACT_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
