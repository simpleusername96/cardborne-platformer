class_name VehicleAttackContract
extends RefCounted

## Gameplay-owned attack semantics. Presentation may read these values, but
## colors and meshes never decide damage, collision, or persistent conditions.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

const KINETIC: StringName = &"kinetic"
const THERMAL: StringName = &"thermal"
const TOXIN: StringName = &"toxin"
const CRYO: StringName = &"cryo"
const ARC: StringName = &"arc"
const HYBRID: StringName = &"hybrid"
const SUPPORT: StringName = &"support"

const THREAT_ORDINARY: StringName = &"ordinary"
const THREAT_ELITE: StringName = &"elite"
const THREAT_BOSS: StringName = &"boss"
const THREAT_TIERS: Array[StringName] = [
	THREAT_ORDINARY, THREAT_ELITE, THREAT_BOSS,
]

const AFFINITIES: Array[StringName] = [
	KINETIC, THERMAL, TOXIN, CRYO, ARC, HYBRID, SUPPORT,
]

const CONDITION_BURN := 1
const CONDITION_POISON := 2
const CONDITION_CHILL := 4
const CONDITION_MASK := CONDITION_BURN | CONDITION_POISON | CONDITION_CHILL

const HOSTILE_PROJECTILE_LIFETIME := 2.2
const PROJECTILE_TELEGRAPH_LEAD_SECONDS := 0.36
const LIGHT_DAMAGE_MAX := 10.0
const HEAVY_DAMAGE_MIN := 20.0
const LIGHT_PROJECTILE_RADIUS := 5.0
const STANDARD_PROJECTILE_RADIUS := 6.0
const HEAVY_PROJECTILE_RADIUS := 7.0
const RADIAL_EDGE_DAMAGE_SCALE := 0.45
const ORDINARY_ATTACKS := {
	&"chaser":{
		"kind":&"charge", "affinity":KINETIC, "startup":0.42, "active":0.24,
		"damage":14.0, "speed":570.0, "contact_padding":8.0,
	},
	&"shooter":{
		"kind":&"projectile", "affinity":KINETIC, "startup":0.62,
		"damage":10.0, "speed":500.0, "origin_offset":30.0,
	},
	&"controller":{
		"kind":&"area", "affinity":KINETIC, "startup":0.82,
		"damage":9.0, "radius":112.0,
	},
	&"turret":{
		"kind":&"projectile", "affinity":KINETIC, "startup":0.68,
		"damage":9.0, "speed":590.0, "origin_offset":38.0,
	},
	&"mine":{
		"kind":&"area", "affinity":ARC, "startup":0.62,
		"damage":16.0, "radius":205.0,
	},
	&"artillery_spotter":{
		"kind":&"area", "affinity":KINETIC, "startup":1.15,
		"damage":15.0, "radius":175.0,
	},
	&"interceptor_tower":{
		"kind":&"projectile", "affinity":ARC, "startup":0.78,
		"damage":12.0, "speed":470.0, "origin_offset":40.0,
	},
	&"drone_carrier":{
		"kind":&"support", "affinity":SUPPORT, "startup":0.82,
		"damage":0.0, "radius":86.0,
	},
}


static func normalize_affinity(value: StringName) -> StringName:
	return value if value in AFFINITIES else KINETIC


static func normalize_threat_tier(value: StringName) -> StringName:
	return value if value in THREAT_TIERS else THREAT_ORDINARY


static func threat_tier_for(
	source_role: StringName,
	elite_trait: StringName = &""
) -> StringName:
	if source_role == &"stage_boss":
		return THREAT_BOSS
	return THREAT_ELITE if not elite_trait.is_empty() else THREAT_ORDINARY


static func power_tier(damage: float) -> StringName:
	if damage <= LIGHT_DAMAGE_MAX:
		return &"light"
	if damage < HEAVY_DAMAGE_MIN:
		return &"standard"
	return &"heavy"


static func ordinary_attack(role: StringName) -> Dictionary:
	return Dictionary(ORDINARY_ATTACKS.get(role, {}))


static func hostile_projectile_radius(damage: float) -> float:
	match power_tier(damage):
		&"light":
			return LIGHT_PROJECTILE_RADIUS
		&"standard":
			return STANDARD_PROJECTILE_RADIUS
		_:
			return HEAVY_PROJECTILE_RADIUS


static func projectile_danger_half_width(projectile_radius: float) -> float:
	return Rules.PLAYER_RADIUS + projectile_radius


static func contact_danger_half_width(attacker_radius: float, contact_padding: float) -> float:
	return Rules.PLAYER_RADIUS + attacker_radius + contact_padding


static func beam_danger_half_width(beam_width: float) -> float:
	return Rules.PLAYER_RADIUS + beam_width * 0.5


static func warning_readiness(remaining: float, total: float) -> float:
	if total <= 0.0:
		return 1.0
	return 1.0 - clampf(remaining / total, 0.0, 1.0)


static func radial_damage(base_damage: float, distance: float, radius: float) -> float:
	if base_damage <= 0.0 or radius <= 0.0 or distance > radius:
		return 0.0
	var normalized_distance := clampf(distance / radius, 0.0, 1.0)
	return base_damage * lerpf(1.0, RADIAL_EDGE_DAMAGE_SCALE, normalized_distance)


static func segment_circle_first_t(
	from: Vector2,
	to: Vector2,
	center: Vector2,
	radius: float
) -> float:
	var motion := to - from
	var motion_length_squared := motion.length_squared()
	var from_center := from - center
	var safe_radius := maxf(0.0, radius)
	if motion_length_squared <= 0.001:
		return 0.0 if from_center.length_squared() <= safe_radius * safe_radius else INF
	var c := from_center.length_squared() - safe_radius * safe_radius
	if c <= 0.0:
		return 0.0
	var b := 2.0 * from_center.dot(motion)
	var discriminant := b * b - 4.0 * motion_length_squared * c
	if discriminant < 0.0:
		return INF
	var first_t := (-b - sqrt(discriminant)) / (2.0 * motion_length_squared)
	return first_t if first_t >= 0.0 and first_t <= 1.0 else INF


static func condition_mask_for_profile(profile: Variant) -> int:
	if profile == null:
		return 0
	var result := 0
	if bool(profile.burn_enabled):
		result |= CONDITION_BURN
	if bool(profile.poison_enabled):
		result |= CONDITION_POISON
	if bool(profile.chill_enabled):
		result |= CONDITION_CHILL
	return result


static func affinity_for_condition_mask(mask: int) -> StringName:
	var normalized := mask & CONDITION_MASK
	if normalized == CONDITION_BURN:
		return THERMAL
	if normalized == CONDITION_POISON:
		return TOXIN
	if normalized == CONDITION_CHILL:
		return CRYO
	if normalized != 0:
		return HYBRID
	return KINETIC


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if AFFINITIES.duplicate().any(func(value): return AFFINITIES.count(value) != 1):
		errors.append("attack affinities must be unique")
	if THREAT_TIERS.duplicate().any(func(value): return THREAT_TIERS.count(value) != 1):
		errors.append("attack threat tiers must be unique")
	if not (
		LIGHT_PROJECTILE_RADIUS
		< STANDARD_PROJECTILE_RADIUS
		and STANDARD_PROJECTILE_RADIUS
		< HEAVY_PROJECTILE_RADIUS
	):
		errors.append("hostile projectile radii must increase with power tier")
	if not is_equal_approx(
		projectile_danger_half_width(STANDARD_PROJECTILE_RADIUS),
		Rules.PLAYER_RADIUS + STANDARD_PROJECTILE_RADIUS
	):
		errors.append("projectile warning must expose the player-center hit footprint")
	if affinity_for_condition_mask(CONDITION_BURN | CONDITION_POISON) != HYBRID:
		errors.append("multi-condition projectiles must use the hybrid affinity")
	if (
		PROJECTILE_TELEGRAPH_LEAD_SECONDS <= 0.0
		or PROJECTILE_TELEGRAPH_LEAD_SECONDS > 0.4
		or PROJECTILE_TELEGRAPH_LEAD_SECONDS >= HOSTILE_PROJECTILE_LIFETIME
	):
		errors.append("projectile telegraph lead must be positive, at most 0.4 seconds, and shorter than projectile lifetime")
	if not (
		is_equal_approx(radial_damage(20.0, 0.0, 100.0), 20.0)
		and is_equal_approx(
			radial_damage(20.0, 100.0, 100.0),
			20.0 * RADIAL_EDGE_DAMAGE_SCALE
		)
		and is_zero_approx(radial_damage(20.0, 100.1, 100.0))
	):
		errors.append("radial damage must fall from full center damage to its bounded edge")
	for role in ORDINARY_ATTACKS:
		var attack: Dictionary = ORDINARY_ATTACKS[role]
		if normalize_affinity(StringName(attack.get("affinity", &""))) != attack.get("affinity"):
			errors.append("ordinary attack has an unknown affinity: %s" % role)
		if float(attack.get("startup", 0.0)) < 0.4:
			errors.append("ordinary attack lacks readable startup: %s" % role)
	return errors
