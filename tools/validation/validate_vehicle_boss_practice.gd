extends SceneTree

const Practice = preload("res://scripts/bosses/vehicle_boss_practice_session.gd")

var _failures: Array[String] = []


func _init() -> void:
	var session := Practice.new()
	var errors := session.configure({
		"stage_id":&"stage_3",
		"field_id":&"storm_drydock_field",
		"phase":3,
		"pattern":"titan_pulse",
		"invulnerable":true,
	})
	_expect(errors.is_empty() and session.active, "valid practice request configures")
	var snapshot := session.snapshot()
	_expect(
		not bool(snapshot["rewards_enabled"])
			and not bool(snapshot["persistence_enabled"]),
		"practice cannot enable rewards or persistence"
	)
	_expect(session.is_pattern_loop() and session.health_ratio() == 0.20, "phase-three pattern loop uses its fixed health")
	errors = session.configure({
		"stage_id":&"stage_9",
		"field_id":&"missing",
		"phase":4,
		"pattern":"missing",
	})
	_expect(errors.size() == 4 and not session.active, "malformed practice arguments fail without substitution")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_BOSS_PRACTICE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
