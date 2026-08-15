class_name VehicleEnemySpecialistRuntime
extends RefCounted

## Pure coordination helpers and canonical values for specialist, support,
## protective, and mine roles.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

const RAMMER_STARTUP := 0.9
const RAMMER_ACTIVE := 0.85
const RAMMER_RECOVERY := 1.2
const RAMMER_SPEED := 760.0
const RAMMER_CONTACT_PADDING := 8.0
const RAMMER_DAMAGE := 20.0
const REPAIR_RANGE := 360.0
const REPAIR_PER_SECOND := 8.0
const GENERATOR_HEAL_PER_TICK := 8.0
const CARRIER_CHILD_CAP := 3
const CARRIER_RELEASE_SPACING := 0.65
const CARRIER_RECOVERY := 8.0
const BEAM_STARTUP := 1.2
const BEAM_ACTIVE := 0.6
const BEAM_RECOVERY := 2.4
const BEAM_RANGE := 920.0
const BEAM_WIDTH := 54.0
const BEAM_COVER_PADDING := 5.0
const BEAM_DAMAGE := 18.0
const SHIELD_ESCORT_RANGE := 300.0
const GENERATOR_RANGE := 390.0
const SHIELDED_RECEIVED_DAMAGE_MULTIPLIER := 0.45
const GENERATOR_TICK_SECONDS := 0.75
const GUARD_PLATE_STRUCTURE := 72.0
const MOBILE_MINE_RADIUS := 100.0
const MOBILE_MINE_DAMAGE := 14.0
const STATIC_MINE_RADIUS := 160.0
const STATIC_MINE_DAMAGE := 26.0

# Wreck Scavenger observes nearby valid enemy deaths. VehicleRun owns the
# bounded per-actor stack storage; this module owns eligibility and arithmetic.
const WRECK_SCAVENGER_RANGE := 360.0
const WRECK_SCAVENGER_MAX_STACKS := 5
const WRECK_SCAVENGER_DAMAGE_PER_STACK := 0.12
const WRECK_SCAVENGER_SPEED_PER_STACK := 0.05
const WRECK_SCAVENGER_INTERVAL_REDUCTION_PER_STACK := 0.04
const WRECK_SCAVENGER_EXCLUDED_ROLES: Array[StringName] = [
	&"stage_boss", &"turret", &"mine", &"interceptor_tower", &"beam_sentinel",
	&"generator", &"wreck_scavenger",
]


static func repair_target_id(tender: EnemyState, enemies: Array[EnemyState], stage_id: StringName, include_dynamic_cover: bool, extra_cover: Array = []) -> String:
	var best_id := ""
	var best_ratio := 1.0
	var origin := tender.pos
	for target in enemies:
		if target == tender or not target.alive or not target.active:
			continue
		var role := target.role
		if role in [&"repair_tender", &"stage_boss"]:
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
	return role in [&"generator", &"shield_escort", &"repair_tender", &"drone_carrier", &"turret", &"interceptor_tower", &"beam_sentinel"]


static func wreck_scavenger_defeat_receipt(
	scavenger: EnemyState,
	defeated: EnemyState,
	current_stacks: int
) -> Dictionary:
	var bounded_stacks := clampi(current_stacks, 0, WRECK_SCAVENGER_MAX_STACKS)
	if not _wreck_scavenger_can_claim(scavenger, defeated):
		return {
			"claimed":false,
			"stacks":bounded_stacks,
			"modifiers":wreck_scavenger_modifiers(bounded_stacks),
		}
	var next_stacks := mini(WRECK_SCAVENGER_MAX_STACKS, bounded_stacks + 1)
	return {
		"claimed":next_stacks != bounded_stacks,
		"stacks":next_stacks,
		"modifiers":wreck_scavenger_modifiers(next_stacks),
	}


static func wreck_scavenger_modifiers(stacks: int) -> Dictionary:
	var bounded_stacks := clampi(stacks, 0, WRECK_SCAVENGER_MAX_STACKS)
	return {
		"damage_multiplier":1.0 + WRECK_SCAVENGER_DAMAGE_PER_STACK * bounded_stacks,
		"speed_multiplier":1.0 + WRECK_SCAVENGER_SPEED_PER_STACK * bounded_stacks,
		"attack_interval_multiplier":maxf(
			0.0,
			1.0 - WRECK_SCAVENGER_INTERVAL_REDUCTION_PER_STACK * bounded_stacks
		),
	}


static func _wreck_scavenger_can_claim(
	scavenger: EnemyState,
	defeated: EnemyState
) -> bool:
	return (
		scavenger != null
		and defeated != null
		and scavenger != defeated
		and scavenger.alive
		and scavenger.active
		and scavenger.archetype == &"wreck_scavenger"
		and not defeated.summoned
		and defeated.role not in WRECK_SCAVENGER_EXCLUDED_ROLES
		and scavenger.pos.distance_squared_to(defeated.pos)
			<= WRECK_SCAVENGER_RANGE * WRECK_SCAVENGER_RANGE
	)
