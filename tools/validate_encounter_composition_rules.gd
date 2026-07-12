extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	var template := RoomTemplateData.new()
	template.forbidden_pairs = [&"sentry", &"timed_poison_vent"]
	var selected: Array[Dictionary] = []

	_expect(
		EncounterCompositionRules.permits_candidate(
			template, selected, _candidate(&"occupier", &"walker")
		),
		"ordinary occupier should be legal"
	)
	selected.append(_candidate(&"burst", &"charger"))
	selected.append(_candidate(&"ranged", &"shooter"))
	_expect(
		not EncounterCompositionRules.permits_candidate(
			template, selected, _candidate(&"guard", &"shield_guard")
		),
		"third simultaneous high-attention enemy should be rejected"
	)
	_expect(
		not EncounterCompositionRules.permits_candidate(
			template, [], _candidate(&"ranged", &"sentry")
		),
		"room-local archetype exclusion should be enforced"
	)
	var walkers: Array[Dictionary] = [
		_candidate(&"occupier", &"walker"),
		_candidate(&"occupier", &"walker"),
	]
	_expect(
		not EncounterCompositionRules.permits_candidate(
			template, walkers, _candidate(&"occupier", &"walker")
		),
		"same archetype should not be repeated three times"
	)
	_finish()


func _candidate(pressure_role: StringName, archetype_id: StringName) -> Dictionary:
	return {"pressure_role": pressure_role, "archetype_id": archetype_id}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ENCOUNTER_COMPOSITION_RULES_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
