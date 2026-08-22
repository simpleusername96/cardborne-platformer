class_name VehicleRecallReplenishmentRuntime
extends RefCounted

## Owns the bounded, boss-independent replenishment policy for recall pickups.

const START_SECONDS := 90.0
const INTERVAL_SECONDS := 30.0
const LOW_WATERMARK := 2
const ACTIVE_CAP := 4

var elapsed := 0.0


func reset() -> void:
	elapsed = 0.0


func advance(delta: float, active_run_seconds: float, pickups: Array[Dictionary]) -> bool:
	if active_run_seconds < START_SECONDS:
		return false
	var active_count := 0
	for pickup in pickups:
		if bool(pickup["active"]) and StringName(pickup["kind"]) == &"experience_recall":
			active_count += 1
	if active_count >= LOW_WATERMARK:
		elapsed = 0.0
		return false
	elapsed += maxf(0.0, delta)
	if elapsed < INTERVAL_SECONDS or active_count >= ACTIVE_CAP:
		return false
	elapsed = 0.0
	for pickup in pickups:
		if not bool(pickup["active"]) and StringName(pickup["kind"]) == &"experience_recall":
			pickup["active"] = true
			pickup["published"] = false
			pickup["published_elapsed"] = 0.0
			return true
	return false
