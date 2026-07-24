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
			cycle.count(cycle[-1]) == 1,
			"%s direct cycle has no immediate or four-cycle repeat" % stage_id
		)
		_expect(
			cycle.count(String(BossPatterns.sequence(stage_id, 1)[1])) <= 1,
			"%s direct cycle contains its signature at most once" % stage_id
		)
		boss.phase = &"boss_startup"
		boss.pattern = StringName(BossPatterns.sequence(stage_id, 1)[1])
		_expect(runtime.try_interrupt_signature(boss), "%s signature is interruptible" % stage_id)
		runtime.finish_interrupted_recovery(boss)
		var next_pattern := runtime.select_direct(boss)
		_expect(
			BossPatterns.commit_mode(next_pattern) == &"committed",
			"%s forces a committed direct pattern after interrupt" % stage_id
		)
	_expect(runtime.phase_for_health(0.66) == 1, "phase one ends at 65 percent")
	_expect(runtime.phase_for_health(0.65) == 2, "phase two starts at 65 percent")
	_expect(runtime.phase_for_health(0.30) == 3, "phase three starts at 30 percent")
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
