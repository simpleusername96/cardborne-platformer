class_name VehicleOutgoingDamagePolicy
extends RefCounted

## Pure, allocation-free conditional damage rules. Callers pass stable combat
## facts; this owner never inspects display strings or mutates run state.

const DAMAGE_DIRECT := 1
const DAMAGE_PERIODIC := 2

const CRITICAL_CHANCES := [0.0, 0.04, 0.07, 0.11, 0.14, 0.18, 0.21]
const DASH_BONUSES := [0.0, 0.08, 0.15, 0.23, 0.31, 0.38, 0.46]
const CRISIS_MAX_BONUSES := [0.0, 0.04, 0.08, 0.13, 0.17, 0.22, 0.26]
const CRITICAL_MULTIPLIER := 2.0
const CONDITIONAL_BONUS_CAP := 1.0
const CRISIS_START_RATIO := 0.60
const CRISIS_FULL_RATIO := 0.25


static func critical_chance(level: int) -> float:
	return float(CRITICAL_CHANCES[clampi(level, 0, CRITICAL_CHANCES.size() - 1)])


static func dash_bonus(level: int) -> float:
	return float(DASH_BONUSES[clampi(level, 0, DASH_BONUSES.size() - 1)])


static func crisis_max_bonus(level: int) -> float:
	return float(CRISIS_MAX_BONUSES[clampi(level, 0, CRISIS_MAX_BONUSES.size() - 1)])


static func crisis_bonus(level: int, hull_ratio: float) -> float:
	var maximum := crisis_max_bonus(level)
	if maximum <= 0.0 or hull_ratio >= CRISIS_START_RATIO:
		return 0.0
	if hull_ratio <= CRISIS_FULL_RATIO:
		return maximum
	var weight := inverse_lerp(CRISIS_START_RATIO, CRISIS_FULL_RATIO, hull_ratio)
	return maximum * clampf(weight, 0.0, 1.0)


static func resolve_damage(
	base_damage: float,
	critical_level: int,
	dash_level: int,
	crisis_level: int,
	hull_ratio: float,
	dash_overdrive_active: bool,
	flags: int,
	run_seed: int,
	attack_serial: int,
	target_hash: int,
	source_hash: int
) -> float:
	if base_damage <= 0.0:
		return 0.0
	var bonus := 0.0
	if dash_overdrive_active:
		bonus += dash_bonus(dash_level)
	bonus += crisis_bonus(crisis_level, hull_ratio)
	var result := base_damage * (1.0 + minf(CONDITIONAL_BONUS_CAP, bonus))
	if (
		(flags & DAMAGE_DIRECT) != 0
		and critical_level > 0
		and deterministic_unit(run_seed, attack_serial, target_hash, source_hash)
			< critical_chance(critical_level)
	):
		result *= CRITICAL_MULTIPLIER
	return result


static func deterministic_unit(
	run_seed: int,
	attack_serial: int,
	target_hash: int,
	source_hash: int
) -> float:
	# Integer-only mixing avoids consuming the shared run RNG and keeps one
	# target receipt stable when unrelated attacks are added elsewhere.
	var mixed := run_seed
	mixed = mixed ^ (attack_serial * 1103515245)
	mixed = mixed ^ (target_hash * 2654435761)
	mixed = mixed ^ (source_hash * 2246822519)
	mixed = mixed ^ (mixed >> 16)
	mixed = mixed * 3266489917
	mixed = mixed ^ (mixed >> 13)
	return float(mixed & 0x7FFFFFFF) / float(0x80000000)
