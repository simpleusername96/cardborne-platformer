extends SceneTree

const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var _failures: Array[String] = []


func _init() -> void:
	var runtime := BossRuntime.new()
	for stage_index in 5:
		var stage_id := StringName("stage_%d" % (stage_index + 1))
		runtime.configure(stage_id)
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
