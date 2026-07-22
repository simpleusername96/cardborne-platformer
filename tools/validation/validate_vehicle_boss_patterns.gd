extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const Specialist = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")

const EXPECTED_DAMAGE := {
	&"flooded_works":[20.0, 34.0, 26.0, 24.0],
	&"tidal_archive":[20.0, 28.0, 32.0, 34.0],
	&"storm_drydock":[22.0, 28.0, 34.0, 24.0],
	&"coral_switchyard":[36.0, 28.0, 22.0, 30.0],
	&"abyssal_observatory":[34.0, 28.0, 0.0, 30.0],
}

var failures := PackedStringArray()


func _initialize() -> void:
	_expect(Specialist.CARRIER_CHILD_CAP == 3, "boss and carrier summons remain capped at three")
	for stage_index in Catalog.STAGE_IDS.size():
		_validate_stage(Catalog.STAGE_IDS[stage_index], stage_index)
	if failures.is_empty():
		print("VEHICLE_BOSS_PATTERNS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _validate_stage(stage_id: StringName, stage_index: int) -> void:
	var phase_one := Patterns.sequence(stage_id, false)
	var phase_two := Patterns.sequence(stage_id, true)
	_expect(phase_one.size() == 4 and phase_one.duplicate().all(func(pattern): return phase_one.count(pattern) == 1), "%s has four distinct attacks" % stage_id)
	_expect(phase_two != phase_one and phase_two.size() == 4, "%s phase two changes attack ordering" % stage_id)
	var expected: Array = EXPECTED_DAMAGE[stage_id]
	for index in phase_one.size():
		var pattern := phase_one[index]
		var startup := Patterns.startup_seconds(pattern)
		var active := Patterns.active_seconds(pattern)
		var recovery := Patterns.recovery_seconds(pattern)
		_expect(is_equal_approx(Patterns.damage(pattern), float(expected[index])), "%s %s uses final Standard damage" % [stage_id, pattern])
		_expect(startup >= 0.8, "%s %s has a readable startup" % [stage_id, pattern])
		_expect(active >= 0.4 and active <= 1.1, "%s %s has a bounded active window" % [stage_id, pattern])
		_expect(recovery >= 0.9 and recovery <= 1.6, "%s %s has a bounded recovery" % [stage_id, pattern])
		_expect(recovery + 0.75 <= 2.4, "%s %s cannot idle too long before the next startup" % [stage_id, pattern])
	_expect(is_equal_approx(Difficulty.boss_health(stage_index, false), [1250.0, 1350.0, 1450.0, 1550.0, 1650.0][stage_index]), "%s has explicit stage-boss health" % stage_id)
	_expect(is_equal_approx(Difficulty.boss_health(stage_index, true), [560.0, 590.0, 620.0, 650.0, 680.0][stage_index]), "%s has explicit field-boss health" % stage_id)
	var field_patterns := Patterns.field_sequence(stage_id)
	_expect(field_patterns.size() == 3 and field_patterns[2] == Patterns.FIELD_STAGE_VERB[stage_id], "%s field boss has ram, area, and a stage verb" % stage_id)
	_expect(field_patterns.duplicate().all(func(pattern): return field_patterns.count(pattern) == 1), "%s field-boss patterns are distinct" % stage_id)
	for field_pattern in field_patterns:
		var field_definition := Patterns.field_definition(String(field_pattern))
		_expect(float(field_definition["startup"]) >= 0.8, "%s %s field attack has readable startup" % [stage_id, field_pattern])
		_expect(float(field_definition["active"]) >= 0.4 and float(field_definition["active"]) <= 1.1, "%s %s field attack has bounded active time" % [stage_id, field_pattern])
		_expect(float(field_definition["recovery"]) >= 0.9 and float(field_definition["recovery"]) <= 1.6, "%s %s field attack has bounded recovery" % [stage_id, field_pattern])
	_expect(float(Patterns.field_definition(String(field_patterns[2]))["startup"]) >= 1.1, "%s field signature has at least 1.1 seconds of startup" % stage_id)
	var field_signature_damage := float(Patterns.field_definition(String(field_patterns[2]))["damage"])
	_expect(field_signature_damage >= 26.0 and field_signature_damage <= 32.0, "%s field signature stays in its final damage band" % stage_id)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
