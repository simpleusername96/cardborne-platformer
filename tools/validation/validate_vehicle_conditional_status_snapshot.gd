extends SceneTree

const Snapshot = preload("res://scripts/ui/vehicle_conditional_status_snapshot.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var empty := Snapshot.build(0, 0.0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0, 0, 0, 0.0)
	_expect(empty.is_empty(), "inactive and unowned conditions publish no HUD rows")
	var dense := Snapshot.build(1, 20.0, 6.5, 1, 1.4, 1, 3, 2.5, 1, 4, 1, 2, 1, 0.15)
	_expect(dense.size() == 6, "gameplay publishes the complete owned conditional-state set")
	_expect(StringName(dense[0]["id"]) == &"last_stand", "critical Hull state has first priority")
	_expect(dense.any(func(row): return StringName(row["id"]) == &"overflow_barrier"), "temporary barrier publishes its remaining time")
	_expect(dense.any(func(row): return StringName(row["id"]) == &"braced_fire"), "braced fire publishes active segments and time")
	for row in dense:
		_expect(
			Dictionary(row).has_all([
				"id", "phase", "current_stacks", "max_stacks", "bonus_percent",
				"remaining_seconds", "next_hit_bonus_percent",
			]),
			"every conditional state keeps the structured gameplay contract"
		)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_CONDITIONAL_STATUS_SNAPSHOT_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
