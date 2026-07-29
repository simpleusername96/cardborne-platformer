class_name VehicleEnemySpecialistRuntime
extends RefCounted

## Pure coordination helpers for the four advanced target-priority roles.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

const RAMMER_STARTUP := 0.9
const RAMMER_ACTIVE := 0.85
const RAMMER_RECOVERY := 1.2
const RAMMER_SPEED := 760.0
const RAMMER_CONTACT_PADDING := 8.0
const RAMMER_DAMAGE := 20.0
const REPAIR_RANGE := 360.0
const REPAIR_PER_SECOND := 4.0
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


static func repair_target_id(tender: EnemyState, enemies: Array[EnemyState], stage_id: StringName, include_dynamic_cover: bool, extra_cover: Array = []) -> String:
	var best_id := ""
	var best_ratio := 1.0
	var origin := tender.pos
	for target in enemies:
		if target == tender or not target.alive or not target.active:
			continue
		var role := target.role
		if role in [&"repair_tender", &"stage_boss", &"boss_pylon"]:
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
