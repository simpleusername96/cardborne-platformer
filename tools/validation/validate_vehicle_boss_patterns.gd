extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")

var failures: Array[String] = []


func _initialize() -> void:
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		var phase_one := Patterns.sequence(stage_id, false)
		var phase_two := Patterns.sequence(stage_id, true)
		_expect(phase_one.size() == 4 and phase_one.duplicate().all(func(pattern): return phase_one.count(pattern) == 1), "%s has four distinct attacks" % stage_id)
		_expect(phase_two.size() == 4 and phase_two != phase_one, "%s changes order in phase two" % stage_id)
		for pattern in phase_one:
			_expect(Patterns.startup_seconds(pattern) >= 0.8, "%s startup is visible" % pattern)
			_expect(Patterns.active_seconds(pattern) >= 0.4, "%s active window is explicit" % pattern)
			_expect(Patterns.recovery_seconds(pattern) >= 0.9, "%s recovery is explicit" % pattern)
			if Patterns.kind(pattern) in [&"lanes", &"fan", &"cross"]:
				_expect(Patterns.volley_interval(pattern) > 0.0 and Patterns.volley_limit(pattern, false) >= 3, "%s repeats aimed projectile volleys" % pattern)
				_expect(Patterns.volley_limit(pattern, true) > Patterns.volley_limit(pattern, false), "%s adds one phase-two volley" % pattern)
		_expect(Difficulty.boss_health(stage_index) > 0.0, "%s has bounded boss health" % stage_id)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_PATTERNS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
