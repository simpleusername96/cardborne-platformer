extends SceneTree

const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const PhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")

var _failures: Array[String] = []


class BossServiceStub:
	extends RefCounted

	var player_position := Vector2.ZERO
	var damage_calls := 0
	var identity_activation_calls := 0
	var radial_projectiles_fired := 0
	var radial_projectile_damage := 0.0
	var long_bank_projectiles_fired := 0


	func _boss_fire_aimed_burst(
		_boss: EnemyState,
		_pattern: String,
		_damage: float
	) -> void:
		pass


	func _damage_player(
		_damage: float,
		_source: String,
		_is_contact: bool,
		_is_hostile: bool,
		_is_boss: bool
	) -> void:
		damage_calls += 1


	func _on_boss_direct_attack_complete(_boss: EnemyState) -> void:
		pass


	func _activate_boss_identity_pattern(
		_boss: EnemyState,
		_pattern: String
	) -> void:
		identity_activation_calls += 1


	func _fire_boss_radial_volley(volley: Dictionary) -> void:
		radial_projectiles_fired += int(volley.get("count", 0))
		radial_projectile_damage = float(volley.get("damage", 0.0))


	func _spawn_boss_long_banks(_event: Dictionary) -> void:
		long_bank_projectiles_fired += 10


func _init() -> void:
	var runtime := BossRuntime.new()
	_expect(BossProfiles.PROFILES.size() == 12, "boss offense reads twelve absolute profiles")
	_validate_stage_selection(runtime)
	_validate_squad_cadence(runtime)
	_validate_autonomous_cadence(runtime)
	_validate_late_stage_direct_area_coverage(runtime)
	_validate_direct_beam_growth(runtime)
	_validate_switch_sweep_geometry()
	_validate_direct_identity_activation(runtime)
	_validate_radial_volley_schedule(runtime)
	_validate_direct_recovery_scale(runtime)
	_validate_direct_long_banks(runtime)
	_validate_phase_receipts(runtime)
	_finish()


func _validate_stage_selection(runtime: BossRuntime) -> void:
	for stage_index in 12:
		var stage_id := StringName("stage_%d" % (stage_index + 1))
		runtime.configure(stage_id)
		var boss := _boss()
		var common := BossPatterns.common_sequence(stage_id, 1)
		var signatures := BossPatterns.signature_sequence(stage_id, 1)
		_expect(
			common.size() == (4 if stage_index == 0 else 6),
			"%s exposes the cumulative tutorial common pool" % stage_id
		)
		for pattern in common:
			_expect(
				BossPatterns.is_common(pattern)
					and BossRuntime.supports_direct_pattern(pattern),
				"%s common selection has an explicit direct route: %s" % [stage_id, pattern]
			)
		for pattern in signatures:
			_expect(
				BossPatterns.is_signature(stage_id, pattern)
					and BossRuntime.supports_direct_pattern(pattern),
				"%s signature selection has an explicit direct route: %s" % [stage_id, pattern]
			)

		var first := runtime.select_direct(boss)
		boss.last_pattern = StringName(first)
		var second := runtime.select_direct(boss)
		_expect(
			first in common and second in common and first != second,
			"%s opens with two non-repeating common attacks" % stage_id
		)
		var third := runtime.select_direct(boss)
		if signatures.is_empty():
			_expect(third in common, "%s continues the common pool without a direct signature" % stage_id)
		else:
			_expect(third in signatures, "%s inserts one signature after two common attacks" % stage_id)
			var fourth := runtime.select_direct(boss)
			_expect(fourth in common, "%s returns to the common language after its signature" % stage_id)

		for phase in range(1, 4):
			_expect(
				is_equal_approx(runtime.read_gap(phase), BossProfiles.read_gap(stage_index, phase)),
				"%s phase %d preserves its exact direct read gap" % [stage_id, phase]
			)
			var phase_common := BossPatterns.common_sequence(stage_id, phase)
			_expect(
				phase_common.size() == common.size()
					and phase_common.all(func(pattern): return pattern in common),
				"%s phase %d reorders without removing common attacks" % [stage_id, phase]
			)


func _validate_squad_cadence(runtime: BossRuntime) -> void:
	for stage_index in 12:
		var stage_id := StringName("stage_%d" % (stage_index + 1))
		runtime.configure(stage_id)
		var boss := _boss()
		_expect(
			runtime.advance_squad(BossRuntime.SQUAD_INTERVAL_SECONDS - 0.01, boss).is_empty(),
			"%s does not call a squad before ten seconds" % stage_id
		)
		var squad := runtime.advance_squad(0.01, boss)
		_expect(
			StringName(squad.get("pattern", &"")) == &"common_squad_call"
				and Array(squad.get("roles", [])).size() == PhaseCatalog.squad_roles(stage_id, 1).size()
				and StringName(squad.get("tactic_id", &"")) == PhaseCatalog.squad_tactic_id(stage_id, 1),
			"%s emits its authored common squad at ten seconds" % stage_id
		)
		_expect(
			runtime.advance_squad(BossRuntime.SQUAD_INTERVAL_SECONDS, boss, true).is_empty()
				and is_zero_approx(float(runtime.snapshot()["squad_timer"])),
			"%s holds a due squad while a major signature is active" % stage_id
		)
		var released := runtime.advance_squad(0.0, boss, false)
		_expect(
			not released.is_empty() and int(released.get("phase", 0)) == 1,
			"%s releases the held squad after the signature ends" % stage_id
		)


func _validate_autonomous_cadence(runtime: BossRuntime) -> void:
	for stage_index in 12:
		var stage_id := StringName("stage_%d" % (stage_index + 1))
		runtime.configure(stage_id)
		var sequence := BossPatterns.autonomous_sequence(stage_id)
		var snapshot := runtime.snapshot()
		if sequence.is_empty():
			_expect(
				is_inf(float(snapshot["autonomous_timer"]))
					and runtime.advance_autonomous(999.0, _boss(), Vector2.ZERO).is_empty(),
				"%s disables its unused independent scheduler" % stage_id
			)
			continue
		_expect(
			is_equal_approx(
				float(snapshot["autonomous_timer"]),
				float(BossProfiles.profile(stage_index)["initial_autonomous_delay"])
			),
			"%s preserves its initial independent-system delay" % stage_id
		)
		var boss := _boss()
		boss.boss_phase = 2
		var events := runtime.advance_autonomous(999.0, boss, Vector2(320.0, 180.0))
		_expect(events.size() == 1, "%s emits one bounded independent signature event" % stage_id)
		if events.is_empty():
			continue
		var event := events[0]
		_expect(
			String(event["pattern"]) in sequence
				and BossPatterns.is_signature(stage_id, String(event["pattern"]))
				and BossRuntime.supports_autonomous_pattern(String(event["pattern"])),
			"%s independent event remains stage-signature work" % stage_id
		)
		_expect(
			is_equal_approx(
				float(runtime.snapshot()["autonomous_timer"]),
				BossProfiles.autonomous_interval(stage_index, 2)
			),
			"%s resets to its exact phase-two independent interval" % stage_id
		)

	_expect(
		BossPatterns.autonomous_sequence(&"stage_6").is_empty(),
		"Stage 6 has one direct owner for distance-growth ordnance"
	)


func _validate_phase_receipts(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_2")
	var boss := _boss()
	boss.phase = &"boss_read"
	boss.phase_time = 0.0
	var blocked := runtime.advance_direct_phase(boss, 0.0, true)
	_expect(
		BossRuntime.valid_phase_receipt(blocked)
			and StringName(blocked["action"]) == BossRuntime.ACTION_REPOSITION,
		"blocked direct commit remains in the read reposition phase"
	)
	var selected := runtime.advance_direct_phase(boss, 0.0, false)
	_expect(
		BossRuntime.valid_phase_receipt(selected)
			and StringName(selected["action"]) == BossRuntime.ACTION_SELECT_DIRECT,
		"unblocked read completion requests one direct selection"
	)
	boss.phase = &"boss_startup"
	boss.phase_time = 0.1
	_expect(
		StringName(runtime.advance_direct_phase(boss, 0.01, false)["action"])
			== BossRuntime.ACTION_REFRESH_STARTUP,
		"startup remains visible until its authored timer completes"
	)
	_expect(
		StringName(runtime.advance_direct_phase(boss, 0.2, false)["action"])
			== BossRuntime.ACTION_BEGIN_ACTIVE,
		"completed startup requests one active transition"
	)
	boss.phase = &"boss_recovery"
	boss.phase_time = 0.0
	var recovery := runtime.advance_direct_phase(boss, 0.0, false)
	_expect(
		StringName(recovery["action"]) == BossRuntime.ACTION_REPOSITION
			and boss.phase == &"boss_read"
			and is_equal_approx(boss.phase_time, runtime.read_gap(boss.boss_phase)),
		"recovery completion returns to one runtime-owned read gap"
	)


func _validate_late_stage_direct_area_coverage(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_8")
	var pattern := "common_radial_bombardment"
	var default_radius := BossPatterns.radius(pattern)
	var stage_radius := BossPatterns.radius(pattern, 7)
	var services := BossServiceStub.new()
	services.player_position = Vector2((default_radius + stage_radius) * 0.5, 0.0)
	var boss := _boss()
	boss.pattern = StringName(pattern)
	boss.phase = &"boss_active"
	boss.phase_time = 0.5
	boss.pattern_volleys = 0
	boss.hit_committed = false
	boss.committed_target = Vector2.ZERO
	runtime.update_active(boss, 0.01, services)
	_expect(
		services.damage_calls == 1,
		"Cycle 8 common radial damage reaches its authored boss footprint"
	)


func _validate_direct_recovery_scale(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_1")
	var services := BossServiceStub.new()
	var boss := _boss()
	boss.pattern = &"common_radial_bombardment"
	boss.phase = &"boss_active"
	boss.phase_time = 0.01
	boss.pattern_volleys = 1
	boss.hit_committed = true
	boss.committed_target = Vector2.ZERO
	runtime.update_active(boss, 0.02, services)
	_expect(
		boss.phase == &"boss_recovery"
			and is_equal_approx(
				boss.phase_time,
				BossPatterns.recovery_seconds("common_radial_bombardment", 0)
			),
		"direct recovery reads the common pattern's absolute value"
	)


func _validate_direct_long_banks(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_6")
	var services := BossServiceStub.new()
	var boss := _boss()
	boss.pattern = &"long_bank_barrage"
	boss.committed_target = Vector2(900.0, 0.0)
	runtime.begin_active(boss, services)
	_expect(
		services.long_bank_projectiles_fired == 10 and boss.pattern_volleys == 1,
		"Stage 6 direct long-bank selection emits ten growth projectiles once"
	)
	runtime.update_active(boss, 0.01, services)
	_expect(services.long_bank_projectiles_fired == 10, "direct long banks cannot emit twice")


func _validate_direct_identity_activation(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_7")
	var services := BossServiceStub.new()
	var boss := _boss()
	boss.pattern = &"crossing_weave_a"
	boss.phase = &"boss_active"
	boss.phase_time = 0.5
	boss.pattern_volleys = 0
	runtime.update_active(boss, 0.01, services)
	_expect(
		services.identity_activation_calls == 1 and boss.pattern_volleys == 1,
		"crossing_weave_a activates its prepared collision geometry exactly once"
	)
	runtime.update_active(boss, 0.01, services)
	_expect(
		services.identity_activation_calls == 1,
		"crossing_weave_a direct identity cannot activate twice"
	)

	runtime.configure(&"stage_8")
	services = BossServiceStub.new()
	boss = _boss()
	boss.pattern = &"radial_volley_a"
	boss.phase = &"boss_active"
	boss.phase_time = 0.5
	boss.pattern_volleys = 0
	runtime.update_active(boss, 0.01, services)
	_expect(
		services.identity_activation_calls == 0 and boss.pattern_volleys == 1,
		"Stage 8 radial volley owns no hidden collision-zone activation"
	)


func _validate_radial_volley_schedule(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_8")
	var event := {
		"id":"radial_schedule",
		"pattern":"radial_volley_a",
		"startup":BossPatterns.startup_seconds("radial_volley_a"),
		"origin":Vector2(400.0, 300.0),
		"damage":BossPatterns.damage("radial_volley_a", 7),
		"affinity":BossPatterns.affinity("radial_volley_a"),
	}
	for index in BossRuntime.MAX_PENDING_RADIAL_VOLLEYS:
		event["id"] = "radial_schedule_%d" % index
		_expect(runtime.schedule_radial_volley(event), "radial-volley queue accepts its fixed capacity")
	_expect(
		not runtime.schedule_radial_volley(event)
			and runtime.pending_radial_volley_count() == BossRuntime.MAX_PENDING_RADIAL_VOLLEYS,
		"radial-volley queue rejects overflow without changing its capacity"
	)
	var services := BossServiceStub.new()
	runtime.advance_pending_attacks(BossPatterns.startup_seconds("radial_volley_a") + 0.54, services)
	_expect(services.radial_projectiles_fired == 0, "radial volleys stay hidden before their delay")
	runtime.advance_pending_attacks(0.02, services)
	_expect(
		services.radial_projectiles_fired == BossRuntime.MAX_PENDING_RADIAL_VOLLEYS * 12
			and runtime.pending_radial_volley_count() == 0
			and is_equal_approx(
				services.radial_projectile_damage,
				BossPatterns.damage("radial_volley_a", 7)
			),
		"each scheduled radial volley fires once and retires"
	)
	_expect(runtime.schedule_radial_volley(event), "radial-volley queue accepts work after retirement")
	runtime.clear_pending_attacks()
	_expect(runtime.pending_radial_volley_count() == 0, "boss cleanup clears delayed radial volleys")


func _validate_direct_beam_growth(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_4")
	var services := BossServiceStub.new()
	services.player_position = Vector2(400.0, 0.0)
	var boss := _boss()
	boss.pos = Vector2.ZERO
	boss.pattern = &"switch_sweep"
	boss.phase = &"boss_active"
	boss.phase_time = BossPatterns.active_seconds("switch_sweep")
	boss.beam_end = Vector2(1000.0, 0.0)
	boss.attack_telegraphs = [{
		"delivery":&"beam",
		"from":Vector2.ZERO,
		"to":Vector2(1000.0, 0.0),
		"beam_emitter":Vector2.ZERO,
		"beam_emission_mode":AttackContract.EMITTED_BEAM_FORWARD,
	}]
	boss.hit_committed = false
	runtime.update_active(boss, 0.01, services)
	_expect(
		services.damage_calls == 0,
		"direct boss beam cannot damage beyond its first growing segment"
	)
	boss.phase_time = BossPatterns.active_seconds("switch_sweep", 3) - 0.15
	runtime.update_active(boss, 0.0, services)
	_expect(
		services.damage_calls == 1,
		"direct boss beam damage reaches the player when its 0.15-second segment arrives"
	)


func _validate_switch_sweep_geometry() -> void:
	var boss := _boss()
	boss.phase = &"boss_startup"
	boss.pattern = &"switch_sweep"
	boss.committed_dir = Vector2.RIGHT
	AttackTelegraphs.refresh_boss(
		boss,
		"switch_sweep",
		func(origin: Vector2, direction: Vector2, distance: float, _padding: float):
			return origin + direction * distance,
		Callable(),
		3
	)
	_expect(boss.attack_telegraphs.size() == 3, "Stage 4 switch sweep authors three beam headings")
	var delays: Array[float] = []
	for descriptor in boss.attack_telegraphs:
		delays.append(float(descriptor.get("beam_release_delay", -1.0)))
		_expect(
			StringName(descriptor.get("beam_topology", &"")) == &"sequential_sweep"
				and StringName(descriptor.get("beam_emission_mode", &""))
					== AttackContract.EMITTED_BEAM_FORWARD,
			"each switch-sweep step is a collision-backed forward emitted beam"
		)
	_expect(delays == [0.0, 0.18, 0.36], "switch-sweep headings release in one fixed sequence")


func _boss() -> EnemyState:
	var boss := EnemyState.new()
	boss.health = 100.0
	boss.max_health = 100.0
	boss.boss_phase = 1
	boss.pattern_index = 0
	boss.visual_radius = 146.0
	boss.radius = 76.0
	return boss


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_BOSS_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
