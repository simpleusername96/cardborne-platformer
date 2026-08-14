class_name VehicleEliteTraitCatalog
extends RefCounted

## Deterministic one-trait elite replacements. Traits modify an existing
## authored unit and never create another quota or active-cap entry.

const TRAITS: Array[StringName] = [&"armored", &"overclocked", &"heavy"]
const ELIGIBLE: Array[StringName] = [
	&"chaser", &"shooter", &"controller", &"shield_escort",
	&"artillery_spotter", &"rammer",
]
const THRESHOLDS := [
	[0.55],
	[0.55],
	[0.42, 0.72],
	[0.42, 0.72],
	[0.35, 0.60, 0.82],
	[0.35, 0.60, 0.82],
	[0.30, 0.48, 0.66, 0.84],
	[0.30, 0.48, 0.66, 0.84],
	[0.24, 0.39, 0.54, 0.69, 0.84],
	[0.24, 0.39, 0.54, 0.69, 0.84],
]
const ARMORED_SHELL := 72.0


static func thresholds(stage_index: int) -> Array:
	return Array(THRESHOLDS[stage_index]).duplicate() if stage_index >= 0 and stage_index < THRESHOLDS.size() else []


static func eligible(archetype: StringName) -> bool:
	return archetype in ELIGIBLE


static func trait_for(stage_index: int, ordinal: int, seed: int) -> StringName:
	if stage_index == 0 and ordinal == 0:
		return &"armored"
	var offset := absi(hash("elite:v1:%d:%d" % [seed, stage_index])) % TRAITS.size()
	return TRAITS[(offset + ordinal) % TRAITS.size()]


static func apply(enemy: VehicleEnemyState, elite_kind: StringName) -> void:
	enemy.elite_trait = elite_kind if elite_kind in TRAITS else &""
	match enemy.elite_trait:
		&"armored":
			enemy.armor_structure = ARMORED_SHELL
		&"overclocked":
			enemy.speed *= 1.15
			enemy.attack_cooldown *= 0.85
		&"heavy":
			enemy.health *= 1.35
			enemy.max_health = enemy.health
			enemy.radius *= 1.15
			enemy.projectile_hit_radius *= 1.15
			enemy.visual_radius *= 1.15
			enemy.speed *= 0.90
