extends SceneTree

const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

var _failures: Array[String] = []


class BossServiceStub:
	extends RefCounted

	var player_position := Vector2.ZERO
	var damage_calls := 0
	var identity_activation_calls := 0


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


func _init() -> void:
	var runtime := BossRuntime.new()
	_expect(
		BossRuntime.PHASE_GAPS == [0.40, 0.30, 0.24]
			and BossRuntime.AUTONOMOUS_INTERVALS == [4.8, 3.9, 3.1]
			and is_equal_approx(BossRuntime.DIRECT_RECOVERY_SCALE, 0.72),
		"boss offense owns the exact read gaps, autonomous intervals, and recovery scale"
	)
	var previous_gap := INF
	var previous_initial_delay := INF
	for boss_index in 8:
		var stage_index := boss_index
		var stage_id := StringName("stage_%d" % (stage_index + 1))
		runtime.configure(stage_id)
		var configured := runtime.snapshot()
		_expect(
			is_equal_approx(
				float(configured["autonomous_timer"]),
				3.2 * StageDifficulty.boss_cadence_scale(stage_index)
			),
			"%s applies stage cadence to the initial autonomous delay" % stage_id
		)
		_expect(
			runtime.read_gap(1) <= previous_gap
				and float(configured["autonomous_timer"]) <= previous_initial_delay,
			"%s never slows the stage-owned direct or autonomous cadence" % stage_id
		)
		previous_gap = runtime.read_gap(1)
		previous_initial_delay = float(configured["autonomous_timer"])
		var boss := _boss()
		for phase in range(1, 4):
			_expect(
				is_equal_approx(
					runtime.read_gap(phase),
					float(BossRuntime.PHASE_GAPS[phase - 1])
						* StageDifficulty.boss_cadence_scale(stage_index)
				),
				"%s phase %d applies the exact direct read gap" % [stage_id, phase]
			)
			boss.boss_phase = phase
			runtime.autonomous_timer = 0.0
			runtime.advance_autonomous(0.0, boss, Vector2(320.0, 180.0))
			_expect(
				is_equal_approx(
					float(runtime.snapshot()["autonomous_timer"]),
					float(BossRuntime.AUTONOMOUS_INTERVALS[phase - 1])
						* StageDifficulty.boss_cadence_scale(stage_index)
				),
				"%s phase %d applies the exact autonomous interval" % [stage_id, phase]
			)
		boss.boss_phase = 1
		var cycle: Array[String] = []
		for _index in 5:
			cycle.append(runtime.select_direct(boss))
		_expect(
			cycle.duplicate().all(func(pattern): return cycle.count(pattern) == 1),
			"%s direct cycle contains five distinct attacks" % stage_id
		)
		for pattern in cycle:
			_expect(
				BossPatterns.commit_mode(pattern) in [&"committed", &"autonomous"],
				"%s direct selection declares execution ownership" % stage_id
			)
		boss.last_pattern = StringName(BossPatterns.sequence(stage_id, 1)[0])
		boss.pattern_index = 0
		_expect(
			runtime.select_direct(boss) != String(boss.last_pattern),
			"%s does not immediately repeat its last direct attack" % stage_id
		)
		boss.boss_phase = 2
		boss.pattern_index = 0
		var later_cycle: Array[String] = []
		for _index in 5:
			later_cycle.append(runtime.select_direct(boss))
		for pattern in later_cycle:
			_expect(
				BossPatterns.commit_mode(pattern) in [&"committed", &"autonomous"],
				"%s phase-two direct selection declares execution ownership" % stage_id
			)
		var events := runtime.advance_autonomous(10.0, boss, Vector2(320.0, 180.0))
		_expect(events.size() == 1, "%s emits its next bounded autonomous attack" % stage_id)
		if not events.is_empty():
			var event := events[0]
			_expect(
				StringName(event["kind"]) == BossPatterns.kind(String(event["pattern"])),
				"%s preserves the authored autonomous shape" % stage_id
			)
			_expect(
				is_equal_approx(
					float(event["damage"]),
					BossPatterns.damage(String(event["pattern"]), stage_index)
				) and is_equal_approx(
					float(event["radius"]),
					BossPatterns.radius(String(event["pattern"]), stage_index)
				) and is_equal_approx(
					float(event["width"]),
					BossPatterns.width(String(event["pattern"]), stage_index)
				),
				"%s autonomous event uses stage-scaled damage and footprint" % stage_id
			)
	_expect(
		runtime.read_gap(1) > runtime.read_gap(3),
		"direct-pattern read cadence escalates without owning semantic phase floors"
	)
	_validate_late_stage_direct_area_coverage(runtime)
	_validate_direct_beam_growth(runtime)
	_validate_direct_identity_activation(runtime)
	_validate_direct_recovery_scale(runtime)
	_validate_phase_receipts(runtime)
	_finish()


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
	var pattern := "thermal_ring"
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
		"Cycle 8 direct area damage reaches beyond the default boss footprint"
	)


func _validate_direct_recovery_scale(runtime: BossRuntime) -> void:
	runtime.configure(&"stage_2")
	var services := BossServiceStub.new()
	var boss := _boss()
	boss.pattern = &"thermal_ring"
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
				BossPatterns.recovery_seconds("thermal_ring")
					* 0.72
					* StageDifficulty.boss_cadence_scale(1)
			),
		"direct recovery applies both its offense scale and the cycle cadence scale"
	)


func _validate_direct_identity_activation(runtime: BossRuntime) -> void:
	for case in [
		{&"stage_id":&"stage_7", &"pattern":&"crossing_weave_a"},
		{&"stage_id":&"stage_8", &"pattern":&"alternating_sectors_a"},
	]:
		runtime.configure(StringName(case[&"stage_id"]))
		var services := BossServiceStub.new()
		var boss := _boss()
		boss.pattern = StringName(case[&"pattern"])
		boss.phase = &"boss_active"
		boss.phase_time = 0.5
		boss.pattern_volleys = 0
		runtime.update_active(boss, 0.01, services)
		_expect(
			services.identity_activation_calls == 1 and boss.pattern_volleys == 1,
			"%s direct identity activates its prepared collision geometry exactly once"
				% String(case[&"pattern"])
		)
		runtime.update_active(boss, 0.01, services)
		_expect(
			services.identity_activation_calls == 1,
			"%s direct identity cannot activate twice" % String(case[&"pattern"])
		)


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
	boss.phase_time = BossPatterns.active_seconds("switch_sweep") - 0.15
	runtime.update_active(boss, 0.0, services)
	_expect(
		services.damage_calls == 1,
		"direct boss beam damage reaches the player when its 0.15-second segment arrives"
	)


func _boss() -> EnemyState:
	var boss := EnemyState.new()
	boss.health = 100.0
	boss.max_health = 100.0
	boss.boss_phase = 1
	boss.pattern_index = 0
	boss.visual_radius = 146.0
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
