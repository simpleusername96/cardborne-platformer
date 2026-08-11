class_name VehiclePlayerRecoveryPolicy
extends RefCounted

## Splits one accepted recovery receipt into Hull first and temporary barrier
## second. Vector3 results are (hull gain, barrier gain, consumed gross heal).

const CONVERSION_RATES := [0.0, 0.50, 0.75, 1.00]
const BARRIER_CAP_RATIOS := [0.0, 0.15, 0.25, 0.35]
const BARRIER_DURATION := 8.0


static func conversion_rate(level: int) -> float:
	return float(CONVERSION_RATES[clampi(level, 0, 3)])


static func barrier_cap(level: int, max_hull: float) -> float:
	return maxf(0.0, max_hull) * float(BARRIER_CAP_RATIOS[clampi(level, 0, 3)])


static func gross_capacity(
	level: int,
	current_hull: float,
	max_hull: float,
	current_barrier: float
) -> float:
	var missing_hull := maxf(0.0, max_hull - current_hull)
	var conversion := conversion_rate(level)
	if conversion <= 0.0:
		return missing_hull
	var missing_barrier := maxf(0.0, barrier_cap(level, max_hull) - current_barrier)
	return missing_hull + missing_barrier / conversion


static func split(
	gross_recovery: float,
	level: int,
	current_hull: float,
	max_hull: float,
	current_barrier: float
) -> Vector3:
	var accepted_gross := minf(
		maxf(0.0, gross_recovery),
		gross_capacity(level, current_hull, max_hull, current_barrier)
	)
	var hull_gain := minf(accepted_gross, maxf(0.0, max_hull - current_hull))
	var overflow := maxf(0.0, accepted_gross - hull_gain)
	var barrier_gain := minf(
		overflow * conversion_rate(level),
		maxf(0.0, barrier_cap(level, max_hull) - current_barrier)
	)
	return Vector3(hull_gain, barrier_gain, accepted_gross)
