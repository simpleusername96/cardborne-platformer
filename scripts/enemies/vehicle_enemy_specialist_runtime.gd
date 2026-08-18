class_name VehicleEnemySpecialistRuntime
extends RefCounted

## Pure coordination helpers and canonical values for specialist, support,
## protective, and mine roles.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

const PULL_CHARGE_STARTUP := 0.9
const PULL_CHARGE_ACTIVE := 0.85
const PULL_CHARGE_RECOVERY := 1.2
const PULL_CHARGE_SPEED := 760.0
const PULL_CHARGE_CONTACT_PADDING := 8.0
const PULL_CHARGE_DAMAGE := 20.0
const REPAIR_RANGE := 360.0
const REPAIR_PER_SECOND := 8.0
const FIXED_SUPPORT_HEAL_PER_TICK := 8.0
const MOBILE_SUPPORT_CHILD_CAP := 3
const MOBILE_SUPPORT_RELEASE_SPACING := 0.65
const MOBILE_SUPPORT_RECOVERY := 8.0
const BEAM_STARTUP := 1.2
const BEAM_ACTIVE := 0.6
const BEAM_RECOVERY := 2.4
const BEAM_RANGE := 920.0
const BEAM_WIDTH := 54.0
const BEAM_COVER_PADDING := 5.0
const BEAM_DAMAGE := 18.0
const SHIELD_SUPPORT_RANGE := 300.0
const FIXED_SUPPORT_RANGE := 390.0
const SHIELDED_RECEIVED_DAMAGE_MULTIPLIER := 0.45
const FIXED_SUPPORT_TICK_SECONDS := 0.75
const GUARD_PLATE_STRUCTURE := 72.0
const MOBILE_MINE_RADIUS := 100.0
const MOBILE_MINE_DAMAGE := 14.0
const STATIC_MINE_RADIUS := 160.0
const STATIC_MINE_DAMAGE := 26.0

# Melee Ordinary Enemy Lv.2 observes nearby valid enemy deaths. VehicleRun owns the
# bounded per-actor stack storage; this module owns eligibility and arithmetic.
const MELEE_GROWTH_RANGE := 360.0
const MELEE_GROWTH_MAX_STACKS := 5
const MELEE_GROWTH_DAMAGE_PER_STACK := 0.12
const MELEE_GROWTH_SPEED_PER_STACK := 0.05
const MELEE_GROWTH_INTERVAL_REDUCTION_PER_STACK := 0.04
const MELEE_GROWTH_EXCLUDED_ROLES: Array[StringName] = [
	&"boss", &"ordinary_fixed_ranged_01", &"ordinary_fixed_area_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01",
	&"ordinary_fixed_support_01", &"ordinary_melee_02",
]


static func repair_target_id(tender: EnemyState, enemies: Array[EnemyState], stage_id: StringName, include_dynamic_cover: bool, extra_cover: Array = []) -> String:
	var best_id := ""
	var best_ratio := 1.0
	var origin := tender.pos
	for target in enemies:
		if target == tender or not target.alive or not target.active:
			continue
		var role := target.role
		if role in [&"ordinary_support_01", &"boss"]:
			continue
		var maximum := target.max_health
		if maximum <= 0.0 or target.health >= maximum:
			continue
		var target_position := target.pos
		if origin.distance_to(target_position) > REPAIR_RANGE:
			continue
		if not Rules.has_line_of_sight_with_extra(origin, target_position, 5.0, include_dynamic_cover, stage_id, extra_cover):
			continue
		var ratio := target.health / maximum
		if ratio < best_ratio:
			best_ratio = ratio
			best_id = target.id
	return best_id


static func is_support_or_installation(role: StringName) -> bool:
	return role in [&"ordinary_fixed_support_01", &"ordinary_support_02", &"ordinary_support_01", &"ordinary_support_03", &"ordinary_fixed_ranged_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01"]


static func ordinary_melee_02_defeat_receipt(
	growth_enemy: EnemyState,
	defeated: EnemyState,
	current_stacks: int
) -> Dictionary:
	var bounded_stacks := clampi(current_stacks, 0, MELEE_GROWTH_MAX_STACKS)
	if not _ordinary_melee_02_can_claim(growth_enemy, defeated):
		return {
			"claimed":false,
			"stacks":bounded_stacks,
			"modifiers":ordinary_melee_02_modifiers(bounded_stacks),
		}
	var next_stacks := mini(MELEE_GROWTH_MAX_STACKS, bounded_stacks + 1)
	return {
		"claimed":next_stacks != bounded_stacks,
		"stacks":next_stacks,
		"modifiers":ordinary_melee_02_modifiers(next_stacks),
	}


static func ordinary_melee_02_modifiers(stacks: int) -> Dictionary:
	var bounded_stacks := clampi(stacks, 0, MELEE_GROWTH_MAX_STACKS)
	return {
		"damage_multiplier":1.0 + MELEE_GROWTH_DAMAGE_PER_STACK * bounded_stacks,
		"speed_multiplier":1.0 + MELEE_GROWTH_SPEED_PER_STACK * bounded_stacks,
		"attack_interval_multiplier":maxf(
			0.0,
			1.0 - MELEE_GROWTH_INTERVAL_REDUCTION_PER_STACK * bounded_stacks
		),
	}


static func _ordinary_melee_02_can_claim(
	growth_enemy: EnemyState,
	defeated: EnemyState
) -> bool:
	return (
		growth_enemy != null
		and defeated != null
		and growth_enemy != defeated
		and growth_enemy.alive
		and growth_enemy.active
		and growth_enemy.archetype == &"ordinary_melee_02"
		and not defeated.summoned
		and defeated.role not in MELEE_GROWTH_EXCLUDED_ROLES
		and growth_enemy.pos.distance_squared_to(defeated.pos)
			<= MELEE_GROWTH_RANGE * MELEE_GROWTH_RANGE
	)
