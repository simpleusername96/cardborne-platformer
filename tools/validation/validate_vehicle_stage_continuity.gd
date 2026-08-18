extends SceneTree

const Stages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Flow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const Transition = preload("res://scripts/vehicle/vehicle_stage_transition_runtime.gd")
const DeathRuntime = preload("res://scripts/bosses/vehicle_boss_death_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var completed_cycles := 0
	for cycle_index in Stages.STAGE_IDS.size():
		var flow := Flow.new()
		flow.configure(cycle_index, Stages.QUOTAS[cycle_index], true)
		for defeat_index in Stages.QUOTAS[cycle_index]:
			var receipt := flow.record_countable_defeat()
			if defeat_index < Stages.QUOTAS[cycle_index] - 1:
				_expect(StringName(receipt["command"]) == Flow.COMMAND_NONE, "cycle %d stays ordinary before quota" % (cycle_index + 1))
		_expect(not flow.boss_entry_ready(), "cycle %d waits through the boss warning" % (cycle_index + 1))
		flow.advance(1.5)
		_expect(flow.boss_entry_ready(), "cycle %d boss enters only after quota and warning" % (cycle_index + 1))
		_expect(StringName(flow.record_boss_defeat()["command"]) == Flow.COMMAND_BEGIN_BOSS_CLEANUP, "cycle %d begins cleanup on boss defeat" % (cycle_index + 1))
		var death := DeathRuntime.new()
		death.begin([StringName("cycle_%d_add" % (cycle_index + 1))])
		death.advance(1.99)
		_expect(not death.complete(), "cycle %d cannot transition before 2.00 seconds" % (cycle_index + 1))
		death.advance(0.01)
		_expect(death.complete(), "cycle %d cleanup completes at 2.00 seconds" % (cycle_index + 1))
		var completion := flow.record_boss_cleanup_complete()
		_expect(StringName(completion["command"]) == Flow.COMMAND_COMPLETE_AFTER_BOSS_CLEANUP, "cycle %d unlocks after cleanup" % (cycle_index + 1))
		var transition := Transition.new()
		var began := transition.begin(cycle_index, Stages.STAGE_IDS.size(), Transition.COMPLETION_AFTER_BOSS, cycle_index * 100)
		_expect(bool(began["accepted"]), "cycle %d transition accepts one completion" % (cycle_index + 1))
		var saw_terminal_result := false
		for serial_offset in 8:
			var command := transition.advance(cycle_index * 100 + serial_offset)
			if StringName(command.get("command", &"")) == &"show_final_result":
				saw_terminal_result = true
		_expect(saw_terminal_result == (cycle_index == Stages.STAGE_IDS.size() - 1), "only cycle 12 reaches the terminal result")
		completed_cycles += 1
	_expect(completed_cycles == 12, "deterministic fixture completes exactly twelve cycles")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_STAGE_CONTINUITY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
