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
	var final_gallery := template.duplicate() as RoomTemplateData
	final_gallery.variant_group = &"flooded_final_gallery"
	_expect(
		EncounterCompositionRules.permits_candidate(
			final_gallery, selected, _candidate(&"vertical", &"leaper")
		),
		"reviewed final gallery should admit one three-threat combine/test"
	)
	var gallery_selected: Array[Dictionary] = selected.duplicate()
	gallery_selected.append(_candidate(&"vertical", &"leaper"))
	_expect(
		not EncounterCompositionRules.permits_candidate(
			final_gallery, gallery_selected, _candidate(&"guard", &"shield_guard")
		),
		"final gallery should still reject a fourth high-attention threat"
	)
	var fractured_gallery := template.duplicate() as RoomTemplateData
	fractured_gallery.variant_group = &"sanctum_fractured_gallery"
	_expect(
		EncounterCompositionRules.permits_candidate(
			fractured_gallery, selected, _candidate(&"vertical", &"leaper")
		),
		"reviewed Sanctum gallery should admit its three terrain-bound threat roles"
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
