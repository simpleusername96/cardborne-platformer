extends SceneTree

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const PrimaryPayload = preload("res://scripts/combat/vehicle_primary_payload_profile.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")

var failures: Array[String] = []


func _initialize() -> void:
	for error in AttackContract.validate_contract():
		failures.append(error)

	_expect(AttackContract.power_tier(10.0) == &"light", "ten damage remains in the light power tier")
	_expect(AttackContract.power_tier(10.1) == &"standard", "damage above ten enters the standard power tier")
	_expect(AttackContract.power_tier(20.0) == &"heavy", "twenty damage enters the heavy power tier")
	_expect(
		AttackContract.THREAT_TIERS == [&"ordinary", &"trait", &"boss"],
		"threat tier contract exposes exactly ordinary, trait, and boss"
	)
	_expect(
		AttackContract.threat_tier_for(&"ordinary_lane_01") == AttackContract.THREAT_ORDINARY
		and AttackContract.threat_tier_for(&"ordinary_lane_01", &"slow") == AttackContract.THREAT_TRAIT
		and AttackContract.threat_tier_for(&"boss", &"slow") == AttackContract.THREAT_BOSS,
		"source role and family trait map to one deterministic threat tier"
	)
	_expect(is_equal_approx(AttackContract.hostile_projectile_radius(4.0), 6.0), "light hostile projectile radius is six")
	_expect(is_equal_approx(AttackContract.hostile_projectile_radius(12.0), 7.5), "standard hostile projectile radius is seven and a half")
	_expect(is_equal_approx(AttackContract.hostile_projectile_radius(24.0), 9.0), "heavy hostile projectile radius is nine")
	_expect(
		is_equal_approx(
			AttackContract.projectile_danger_half_width(9.0),
			Rules.PLAYER_RADIUS + 9.0
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
		is_equal_approx(AttackContract.EMITTED_BEAM_GROWTH_SECONDS, 0.20)
			and is_zero_approx(
				AttackContract.emitted_beam_growth_ratio(0.80, 0.80)
			)
			and is_equal_approx(
				AttackContract.emitted_beam_growth_ratio(0.70, 0.80), 0.50
			)
			and is_equal_approx(
				AttackContract.emitted_beam_growth_ratio(0.60, 0.80), 1.0
			),
		"emitted beams grow from zero to full collision length over exactly 0.20 seconds"
	)
	_expect(
		AttackContract.emitted_beam_live_origin(
			Vector2(-100.0, 0.0), Vector2.ZERO, 0.5,
			AttackContract.EMITTED_BEAM_BIDIRECTIONAL
		).is_equal_approx(Vector2(-50.0, 0.0))
			and AttackContract.emitted_beam_live_endpoint(
				Vector2.ZERO, Vector2(100.0, 0.0), 0.5
			).is_equal_approx(Vector2(50.0, 0.0))
			and AttackContract.emitted_beam_live_origin(
				Vector2(-100.0, 0.0), Vector2.ZERO, 0.5,
				AttackContract.EMITTED_BEAM_FORWARD
			).is_equal_approx(Vector2(-100.0, 0.0)),
		"emitted-beam endpoints distinguish bidirectional boss fire from forward fire"
	)
	_expect(
		AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS > 0.0
			and AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS <= 0.4
			and AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS
				< AttackContract.HOSTILE_PROJECTILE_LIFETIME,
		"projectile startup keeps a bounded radar-readiness horizon"
	)
	_expect(
		StringName(AttackContract.ORDINARY_ATTACKS[&"ordinary_gap_01"]["kind"])
			== &"projectile"
			and StringName(AttackContract.ORDINARY_ATTACKS[&"ordinary_growth_01"]["kind"])
				== &"ground_impact",
		"ordinary controller stays projectile-based while artillery owns a marked ground impact"
	)
	var emitter_bolt := AttackContract.ordinary_attack(&"ordinary_lane_01")
	var defender_bash := AttackContract.ordinary_attack(&"ordinary_shield_01")
	var coordinator_bolt := AttackContract.ordinary_attack(&"ordinary_pulse_01")
	_expect(
		StringName(emitter_bolt.get("kind", &"")) == &"projectile"
			and is_equal_approx(float(emitter_bolt.get("startup", 0.0)), 0.62)
			and is_equal_approx(float(emitter_bolt.get("speed", 0.0)), 560.0)
			and is_equal_approx(float(emitter_bolt.get("range", 0.0)), 700.0)
			and is_equal_approx(float(emitter_bolt.get("recovery", 0.0)), 0.64)
			and is_equal_approx(float(emitter_bolt.get("cooldown", 0.0)), 0.70),
		"Emitter exposes the exact faster ranged-pressure contract"
	)
	_expect(
		StringName(defender_bash.get("kind", &"")) == &"charge"
			and is_equal_approx(float(defender_bash.get("startup", 0.0)), 0.60)
			and is_equal_approx(float(defender_bash.get("active", 0.0)), 0.24)
			and is_equal_approx(float(defender_bash.get("damage", 0.0)), 14.0)
			and is_equal_approx(float(defender_bash.get("speed", 0.0)), 500.0)
			and is_equal_approx(float(defender_bash.get("recovery", 0.0)), 1.40),
		"unpaired defender exposes the exact shield-bash contract"
	)
	_expect(
		StringName(coordinator_bolt.get("kind", &"")) == &"projectile"
			and is_equal_approx(float(coordinator_bolt.get("startup", 0.0)), 0.80)
			and is_equal_approx(float(coordinator_bolt.get("damage", 0.0)), 12.0)
			and is_equal_approx(float(coordinator_bolt.get("speed", 0.0)), 470.0)
			and is_equal_approx(float(coordinator_bolt.get("origin_offset", 0.0)), 34.0)
			and is_equal_approx(float(coordinator_bolt.get("range", 0.0)), 660.0)
			and is_equal_approx(float(coordinator_bolt.get("recovery", 0.0)), 1.32),
		"coordinator exposes the exact direct-projectile contract"
	)
	var emitter_travel_seconds := (
		(float(emitter_bolt["range"]) - float(emitter_bolt["origin_offset"]))
		/ Director.effective_hostile_projectile_speed(float(emitter_bolt["speed"]))
	)
	var coordinator_travel_seconds := (
		(float(coordinator_bolt["range"]) - float(coordinator_bolt["origin_offset"]))
		/ Director.effective_hostile_projectile_speed(float(coordinator_bolt["speed"]))
	)
	_expect(
		emitter_travel_seconds < AttackContract.HOSTILE_PROJECTILE_LIFETIME
			and coordinator_travel_seconds < AttackContract.HOSTILE_PROJECTILE_LIFETIME
			and float(emitter_bolt["startup"]) + emitter_travel_seconds > 2.0
			and float(coordinator_bolt["startup"]) + coordinator_travel_seconds > 2.0,
		"maximum-range shots arrive within lifetime while preserving over two seconds of warning plus travel"
	)
	_expect(
		Director.STAGE_MAX_RANGED_COMMITS == [3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4]
			and ProjectileStore.HOSTILE_CAPACITY == 120
			and ProjectileStore.HOSTILE_BOSS_RESERVE == 24,
		"ranged tuning preserves commit caps and the 96-shot ordinary hostile budget"
	)
	var rail: Dictionary = AttackContract.ordinary_attack(&"ordinary_beam_01")
	var orbit: Dictionary = AttackContract.ordinary_attack(&"ordinary_range_01")
	var bombing: Dictionary = AttackContract.ordinary_attack(&"ordinary_sweep_01")
	_expect(
		is_equal_approx(float(rail["startup"]), 1.40)
			and is_equal_approx(float(rail["recovery"]), 2.20)
			and bool(rail["relocates_after_attack"]),
		"Beam Ordinary Enemy Lv.1 exposes its exact line warning and relocation recovery"
	)
	_expect(
		StringName(orbit["kind"]) == &"burst"
			and int(orbit["burst_count"]) == 3,
		"Range Ordinary Enemy Lv.1 exposes a three-shot inward pressure burst"
	)
	_expect(
		StringName(bombing["kind"]) == &"ground_burst"
			and int(bombing["blast_count"]) == 3
			and float(bombing["blast_delay"]) > 0.0,
		"Sweep Ordinary Enemy Lv.1 exposes three delayed normal-damage ground blasts"
	)
	_expect(
		is_zero_approx(AttackContract.warning_readiness(0.8, 0.8))
			and is_equal_approx(AttackContract.warning_readiness(0.4, 0.8), 0.5)
			and is_equal_approx(AttackContract.warning_readiness(0.0, 0.8), 1.0),
		"warning readiness advances monotonically from startup to impact"
	)
	_expect(
		is_equal_approx(AttackContract.bombardment_warning(0.48), 1.23)
			and is_equal_approx(
				AttackContract.warned_startup_seconds(1.15, &"ground_impact"),
				1.90
			)
			and is_equal_approx(
				AttackContract.warned_startup_seconds(0.62, &"projectile"),
				0.62
			)
			and AttackContract.radial_band_boundaries(100.0) == PackedFloat32Array([0.5])
			and AttackContract.radial_band_boundaries(180.0) == PackedFloat32Array([1.0 / 3.0, 2.0 / 3.0]),
		"one combat owner exposes the warning addition and matching radial boundaries"
	)
	_expect(
		is_equal_approx(AttackContract.radial_damage(20.0, 0.0, 100.0), 20.0),
		"small radial damage is full strength at its center"
	)
	_expect(
		is_equal_approx(AttackContract.radial_damage(20.0, 50.0, 100.0), 20.0)
			and is_equal_approx(AttackContract.radial_damage(20.0, 50.1, 100.0), 9.0)
			and is_equal_approx(AttackContract.radial_damage(20.0, 100.0, 100.0), 9.0),
		"small bombardment uses exact full and 45-percent radial bands"
	)
	_expect(
		is_equal_approx(AttackContract.radial_damage(20.0, 60.0, 180.0), 20.0)
			and is_equal_approx(AttackContract.radial_damage(20.0, 60.1, 180.0), 14.0)
			and is_equal_approx(AttackContract.radial_damage(20.0, 120.0, 180.0), 14.0)
			and is_equal_approx(AttackContract.radial_damage(20.0, 120.1, 180.0), 8.0)
			and is_equal_approx(AttackContract.radial_damage(20.0, 180.0, 180.0), 8.0),
		"large bombardment uses exact full, 70-percent, and 40-percent radial bands"
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
	_expect(
		is_equal_approx(
			AttackContract.relative_sweep_first_t(
				Vector2(-100.0, 0.0), Vector2(100.0, 0.0),
				Vector2(100.0, 0.0), Vector2(-100.0, 0.0), 20.0
			),
			0.45
		),
		"relative sweep returns the first simultaneous between-endpoint contact"
	)
	_expect(
		AttackContract.relative_sweep_first_t(
			Vector2(-100.0, 20.1), Vector2(100.0, 20.1),
			Vector2.ZERO, Vector2.ZERO, 20.0
		) == INF,
		"relative sweep does not enlarge the exact combined circle"
	)
	_expect(
		is_zero_approx(AttackContract.segment_segment_distance(
			Vector2(-100.0, 0.0), Vector2(100.0, 0.0),
			Vector2(0.0, -100.0), Vector2(0.0, 100.0)
		))
			and is_equal_approx(AttackContract.segment_segment_distance(
				Vector2(-100.0, 30.0), Vector2(100.0, 30.0),
				Vector2(-50.0, 0.0), Vector2(50.0, 0.0)
			), 30.0),
		"segment distance distinguishes corridor crossings from exact outside paths"
	)

	var profile := PrimaryPayload.new()
	profile.thermal_enabled = true
	_expect(
		AttackContract.condition_mask_for_profile(profile) == 0
			and profile.affinity() == AttackContract.THERMAL,
		"thermal affinity is explicit and does not claim a persistent condition"
	)
	profile.poison_enabled = true
	profile.chill_enabled = true
	_expect(
		AttackContract.affinity_for_condition_mask(
			AttackContract.condition_mask_for_profile(profile)
		) == AttackContract.HYBRID,
		"combined persistent toxin and chill payloads present as hybrid"
	)
	profile.poison_enabled = false
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
	enemy.role = &"ordinary_lane_01"
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
	enemy.family_trait = &"slow"
	AttackTelegraphs.refresh_ordinary(enemy, resolve_path)
	_expect(
		enemy.attack_telegraphs.all(
			func(item): return item["threat_tier"] == AttackContract.THREAT_TRAIT
		),
		"family-trait telegraphs retain their source threat tier"
	)
	enemy.role = &"boss"
	enemy.family_trait = &""
	enemy.phase = &"boss_startup"
	enemy.phase_time = 0.85
	AttackTelegraphs.refresh_boss(enemy, "slag_ring", resolve_path)
	_expect(
		not enemy.attack_telegraphs.is_empty()
		and enemy.attack_telegraphs.all(
			func(item): return item["threat_tier"] == AttackContract.THREAT_BOSS
		),
		"boss telegraphs retain the boss threat tier"
	)
	AttackTelegraphs.refresh_boss(enemy, "boss_pattern_fixed_beam_01_call", resolve_path)
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
