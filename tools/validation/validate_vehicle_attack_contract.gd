extends SceneTree

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StatusProfile = preload("res://scripts/combat/vehicle_status_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
	for error in AttackContract.validate_contract():
		failures.append(error)

	_expect(AttackContract.power_tier(10.0) == &"light", "ten damage remains in the light power tier")
	_expect(AttackContract.power_tier(10.1) == &"standard", "damage above ten enters the standard power tier")
	_expect(AttackContract.power_tier(20.0) == &"heavy", "twenty damage enters the heavy power tier")
	_expect(
		AttackContract.THREAT_TIERS == [&"ordinary", &"elite", &"boss"],
		"threat tier contract exposes exactly ordinary, elite, and boss"
	)
	_expect(
		AttackContract.threat_tier_for(&"shooter") == AttackContract.THREAT_ORDINARY
		and AttackContract.threat_tier_for(&"shooter", &"heavy") == AttackContract.THREAT_ELITE
		and AttackContract.threat_tier_for(&"stage_boss", &"heavy") == AttackContract.THREAT_BOSS,
		"source role and elite trait map to one deterministic threat tier"
	)
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
		"projectile startup keeps a bounded radar-readiness horizon"
	)
	_expect(
		StringName(AttackContract.ORDINARY_ATTACKS[&"controller"]["kind"])
			== &"projectile"
			and StringName(AttackContract.ORDINARY_ATTACKS[&"artillery_spotter"]["kind"])
				== &"projectile",
		"ordinary controller and artillery roles never create ranged area bombardments"
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
	_validate_telegraph_threat_tiers()
	_finish()


func _validate_telegraph_threat_tiers() -> void:
	var resolve_path := func(
		origin: Vector2,
		direction: Vector2,
		distance: float,
		_padding: float
	) -> Vector2:
		return origin + direction * distance
	var enemy := EnemyState.new()
	enemy.role = &"shooter"
	enemy.phase = &"startup"
	enemy.phase_time = 0.62
	enemy.pos = Vector2(100.0, 100.0)
	enemy.committed_dir = Vector2.RIGHT
	AttackTelegraphs.refresh_ordinary(enemy, resolve_path)
	_expect(
		not enemy.attack_telegraphs.is_empty()
		and enemy.attack_telegraphs.all(
			func(item): return item["threat_tier"] == AttackContract.THREAT_ORDINARY
		),
		"ordinary telegraphs retain their source threat tier"
	)
	enemy.elite_trait = &"overclocked"
	AttackTelegraphs.refresh_ordinary(enemy, resolve_path)
	_expect(
		enemy.attack_telegraphs.all(
			func(item): return item["threat_tier"] == AttackContract.THREAT_ELITE
		),
		"elite telegraphs retain their source threat tier"
	)
	enemy.role = &"stage_boss"
	enemy.elite_trait = &""
	enemy.phase = &"boss_startup"
	enemy.phase_time = 0.85
	AttackTelegraphs.refresh_boss(enemy, "foundry_burst", resolve_path)
	_expect(
		not enemy.attack_telegraphs.is_empty()
		and enemy.attack_telegraphs.all(
			func(item): return item["threat_tier"] == AttackContract.THREAT_BOSS
		),
		"boss telegraphs retain the boss threat tier"
	)
	AttackTelegraphs.refresh_boss(enemy, "beam_sentinel_call", resolve_path)
	_expect(
		enemy.attack_telegraphs.size() == 1
		and enemy.attack_telegraphs[0]["delivery"] == &"support"
		and enemy.attack_telegraphs[0]["threat_tier"] == AttackContract.THREAT_BOSS,
		"zero-damage boss summons retain one boss-tier support telegraph"
	)


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
