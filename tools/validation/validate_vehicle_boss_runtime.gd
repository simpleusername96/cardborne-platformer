extends SceneTree

const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")

var _failures: Array[String] = []


func _init() -> void:
	var runtime := BossRuntime.new()
	var previous_gap := INF
	var previous_initial_delay := INF
	for stage_index in 5:
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
		var cycle: Array[String] = []
		for _index in 4:
			cycle.append(runtime.select_direct(boss))
		_expect(
			cycle.duplicate().all(func(pattern): return cycle.count(pattern) == 1),
			"%s direct cycle contains four distinct attacks" % stage_id
		)
		for pattern in cycle:
			_expect(
				BossPatterns.commit_mode(pattern) == &"committed",
				"%s direct selection stays committed" % stage_id
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
		for _index in 4:
			later_cycle.append(runtime.select_direct(boss))
		for pattern in later_cycle:
			_expect(
				BossPatterns.commit_mode(pattern) == &"committed",
				"%s phase-two direct selection stays committed" % stage_id
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
	_finish()


func _boss() -> EnemyState:
	var boss := EnemyState.new()
	boss.health = 100.0
	boss.max_health = 100.0
	boss.boss_phase = 1
	boss.pattern_index = 0
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
