extends SceneTree

const RecallReplenishmentRuntime = preload(
	"res://scripts/rewards/vehicle_recall_replenishment_runtime.gd"
)

var failures := PackedStringArray()


func _initialize() -> void:
	_validate_replenishment_timing()
	_validate_active_pickup_bounds()
	if failures.is_empty():
		print("VEHICLE_RECALL_REPLENISHMENT_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _validate_replenishment_timing() -> void:
	var runtime := RecallReplenishmentRuntime.new()
	var pickups := _pickups(1)
	_expect(not runtime.advance(60.0, 44.9, pickups), "recalls do not replenish before 45 seconds")
	_expect(not runtime.advance(14.9, 45.0, pickups), "the first eligible interval remains 15 seconds")
	_expect(runtime.advance(0.1, 45.0, pickups), "one inactive recall replenishes after 15 eligible seconds")
	_expect(_active_recall_count(pickups) == 2, "each interval restores one authored recall")
	_expect(runtime.advance(15.0, 60.0, pickups), "a second eligible interval restores another recall")
	_expect(runtime.advance(15.0, 75.0, pickups), "a third eligible interval restores the four-recall watermark")
	_expect(_active_recall_count(pickups) == 4, "replenishment restores all four authored recalls")


func _validate_active_pickup_bounds() -> void:
	var runtime := RecallReplenishmentRuntime.new()
	var pickups := _pickups(4)
	_expect(not runtime.advance(90.0, 180.0, pickups), "four active recalls suppress replenishment")
	pickups[0]["active"] = false
	_expect(runtime.advance(15.0, 180.0, pickups), "a consumed recall can replenish later")
	_expect(_active_recall_count(pickups) <= RecallReplenishmentRuntime.ACTIVE_CAP, "active recalls stay within the authored cap")
	runtime.elapsed = 18.0
	runtime.reset()
	_expect(is_zero_approx(runtime.elapsed), "reset clears interval progress")


func _pickups(active_recalls: int) -> Array[Dictionary]:
	var pickups: Array[Dictionary] = []
	for index in RecallReplenishmentRuntime.ACTIVE_CAP:
		pickups.append({
			"kind": &"experience_recall",
			"active": index < active_recalls,
		})
	pickups.append({"kind": &"experience_shard", "active": false})
	return pickups


func _active_recall_count(pickups: Array[Dictionary]) -> int:
	return pickups.filter(
		func(pickup: Dictionary) -> bool:
			return bool(pickup["active"]) and StringName(pickup["kind"]) == &"experience_recall"
	).size()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
