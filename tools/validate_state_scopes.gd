extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_validate_state_scopes")


func _validate_state_scopes() -> void:
	var profile_state := root.get_node_or_null("ProfileState")
	var run_state := root.get_node_or_null("RunState")
	_expect(profile_state != null, "ProfileState autoload should exist")
	_expect(run_state != null, "RunState autoload should exist")
	if profile_state == null or run_state == null:
		_finish()
		return

	profile_state.reset_to_defaults()
	_expect(profile_state.grant_material("rusted_scrap", 4), "persistent material grant should succeed")
	_expect(run_state.grant_unsettled_material("rusted_scrap", 2), "run material grant should succeed")
	for profile_index in run_state.profiles.size():
		_expect(run_state.start_new_run(profile_index), "valid character build should start a run")
		_expect(
			profile_state.get_material_count("rusted_scrap") == 4,
			"new run must preserve profile materials"
		)
		_expect(run_state.get_unsettled_materials().is_empty(), "new run must clear unsettled materials")
		_expect(run_state.selected_profile != null, "new run must select a character profile")
		_expect(run_state.get_effective_build_snapshot() != null, "new run must resolve a build snapshot")
		if run_state.get_effective_build_snapshot() == null:
			continue
		_expect(run_state.get_effective_build_snapshot().is_valid(), "base character build must be valid")
		_expect(
			run_state.get_effective_build_snapshot().has_stat(&"extra_jumps"),
			"base character build must include the shared double jump stat"
		)
		_expect(
			run_state.get_effective_stat("extra_jumps", 0.0) >= 1.0,
			"every shipped character must retain double jump"
		)

	run_state.set_setting("screen_shake", false)
	_expect(profile_state.get_setting("screen_shake", true) == false, "RunState setting facade must delegate to ProfileState")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("STATE_SCOPE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
