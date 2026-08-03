class_name VehicleRunDifficulty
extends RefCounted

## Compatibility owner for the fixed Hard run profile. Stage-to-stage growth
## remains owned by VehicleStageDifficulty.

const HARD := &"hard"
const DEFAULT := HARD
const IDS: Array[StringName] = [HARD]

const PROFILES := {
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


static func normalize(_value: Variant) -> StringName:
	# Old callers may still provide a retired identifier; it cannot alter play.
	return HARD


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
