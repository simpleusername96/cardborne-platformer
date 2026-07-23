class_name VehicleRunDifficulty
extends RefCounted

## Fixed player-selected difficulty for one complete run. Stage-to-stage growth
## remains owned by VehicleStageDifficulty.

const EASY := &"easy"
const NORMAL := &"normal"
const HARD := &"hard"
const DEFAULT := HARD
const IDS: Array[StringName] = [EASY, NORMAL, HARD]

const PROFILES := {
	EASY: {
		"quota": 0.81,
		"active_cap": 0.8836,
		"health": 0.9216,
		"boss_health": 0.81,
		"damage": 0.9216,
		"speed": 0.9604,
	},
	NORMAL: {
		"quota": 0.90,
		"active_cap": 0.94,
		"health": 0.96,
		"boss_health": 0.90,
		"damage": 0.96,
		"speed": 0.98,
	},
	HARD: {
		"quota": 1.0,
		"active_cap": 1.0,
		"health": 1.0,
		"boss_health": 1.0,
		"damage": 1.0,
		"speed": 1.0,
	},
}


static func is_valid(value: Variant) -> bool:
	return IDS.has(StringName(String(value).to_lower()))


static func normalize(value: Variant) -> StringName:
	var difficulty := StringName(String(value).to_lower())
	return difficulty if IDS.has(difficulty) else DEFAULT


static func profile(value: Variant) -> Dictionary:
	return PROFILES[normalize(value)]


static func factor(value: Variant, axis: String) -> float:
	return float(profile(value).get(axis, 1.0))


static func scaled_quota(base_quota: int, value: Variant) -> int:
	return maxi(1, roundi(float(base_quota) * factor(value, "quota")))


static func scaled_active_cap(base_cap: int, value: Variant) -> int:
	return maxi(1, roundi(float(base_cap) * factor(value, "active_cap")))


static func simultaneous_pressure(value: Variant, boss: bool = false) -> float:
	var values := profile(value)
	var health_axis := "boss_health" if boss else "health"
	var count_factor := 1.0 if boss else float(values["active_cap"])
	return (
		count_factor
		* float(values[health_axis])
		* float(values["damage"])
		* float(values["speed"])
	)
