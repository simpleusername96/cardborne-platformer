extends SceneTree

const Practice = preload("res://scripts/bosses/vehicle_boss_practice_session.gd")
const PracticePanel = preload("res://scripts/ui/vehicle_boss_practice_panel.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_session_contract()
	var panel := PracticePanel.new()
	get_root().add_child(panel)
	await process_frame
	panel.open()
	var contract := panel.debug_contract()
	_expect(
		int(contract["form_rows"]) == 5
			and int(contract["option_controls"]) == 4
			and int(contract["toggle_controls"]) == 1,
		"practice form preserves four options and one invulnerability toggle"
	)
	_expect(
		int(contract["command_count"]) == 2
			and StringName(contract["start_role"]) == &"PrimaryButton"
			and StringName(contract["back_role"]) == &"SecondaryButton",
		"practice keeps shared Start and Back command roles"
	)
	_expect(
		int(contract["row_panel_count"]) == 0
			and int(contract["scroll_region_count"]) == 1
			and float(contract["minimum_target_height"]) >= 44.0,
		"practice uses one scroll-safe unboxed shared form with accessible targets"
	)
	var emitted: Array[Dictionary] = []
	panel.selected.connect(func(request: Dictionary) -> void: emitted.append(request))
	panel.call("_emit_request")
	_expect(
		emitted.size() == 1
			and emitted[0].keys().all(func(key: Variant) -> bool: return key in [
				"stage_id", "field_id", "phase", "pattern", "invulnerable",
			]),
		"practice UI emits one complete request without mutating runtime state"
	)
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		panel.refresh_localized_content()
		var option_texts := panel.debug_option_texts()
		var localized := not option_texts.is_empty()
		for option_text in option_texts:
			localized = localized and not option_text.is_empty() and not option_text.contains("_")
		_expect(
			localized,
			"%s practice patterns use localized presentation" % locale
		)
	var source := FileAccess.get_file_as_string(
		"res://scripts/ui/vehicle_boss_practice_panel.gd"
	)
	_expect(
		not source.contains("PanelContainer.new")
			and not source.contains("SummaryBand")
			and source.contains("func _control_row")
			and source.contains("VBoxContainer.new")
			and source.contains("Factory.label")
			and source.contains("Factory.command_button"),
		"practice UI uses vertical shared label/control rows and commands without legacy chrome"
	)
	panel.queue_free()
	await process_frame
	_finish()


func _validate_session_contract() -> void:
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
	_expect(
		session.is_pattern_loop() and session.health_ratio() == 0.20,
		"phase-three pattern loop uses its fixed health"
	)
	session.stop()
	_expect(not session.active, "practice can return to its selection state after defeat")
	errors = session.configure({
		"stage_id":&"stage_9",
		"field_id":&"missing",
		"phase":4,
		"pattern":"missing",
	})
	_expect(
		errors.size() == 4 and not session.active,
		"malformed practice arguments fail without substitution"
	)
	var run_source := FileAccess.get_file_as_string(
		"res://scripts/vehicle/vehicle_run.gd"
	)
	_expect(
		run_source.contains("boss_practice.stop()")
			and run_source.contains("_ui.show_boss_practice()")
			and not run_source.contains("show_garage"),
		"practice defeat returns to Boss Practice selection without a Garage route"
	)


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
