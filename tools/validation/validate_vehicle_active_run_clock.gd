extends SceneTree

const Run = preload("res://scripts/vehicle/vehicle_run.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var run := Run.new()
	_expect(
		not run._run_clock_active() and not run._simulation_active(),
		"deployment starts with both the run clock and simulation stopped"
	)
	run._advance_active_run_clock(1.0)
	_expect(
		is_zero_approx(run.active_run_elapsed_seconds),
		"deployment time is excluded"
	)

	run.mode = Run.RunMode.PLAYING
	run._advance_active_run_clock(1.25)
	_expect(
		is_equal_approx(run.active_run_elapsed_seconds, 1.25)
			and run._simulation_active(),
		"playing advances both the active-run clock and simulation"
	)

	run.mode = Run.RunMode.UPGRADE
	run._advance_active_run_clock(2.5)
	_expect(
		is_equal_approx(run.active_run_elapsed_seconds, 3.75)
			and run._run_clock_active()
			and not run._simulation_active(),
		"mandatory upgrade time counts while simulation stays stopped"
	)

	for frozen_mode in [
		Run.RunMode.PAUSED,
		Run.RunMode.FAILURE_REPORT,
		Run.RunMode.RESULT,
	]:
		run.mode = frozen_mode
		run._advance_active_run_clock(4.0)
	_expect(
		is_equal_approx(run.active_run_elapsed_seconds, 3.75),
		"explicit pause and terminal modes freeze the final active-run time"
	)

	run.stage_started_at_active_run_seconds = run.active_run_elapsed_seconds
	run.mode = Run.RunMode.PLAYING
	run._advance_active_run_clock(0.25)
	_expect(
		is_equal_approx(run.active_run_elapsed_seconds, 4.0)
			and is_equal_approx(run.stage_started_at_active_run_seconds, 3.75),
		"stage continuation preserves the cumulative clock"
	)
	run._advance_active_run_clock(-10.0)
	_expect(
		is_equal_approx(run.active_run_elapsed_seconds, 4.0),
		"invalid negative deltas cannot move the clock backwards"
	)

	run._reset_active_run_clock()
	_expect(
		is_zero_approx(run.active_run_elapsed_seconds)
			and is_zero_approx(run.stage_started_at_active_run_seconds),
		"a fresh deployment resets both clock anchors"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ACTIVE_RUN_CLOCK_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
