class_name VehicleEnemySpecialistRuntime
extends RefCounted

## Pure coordination helpers for the four advanced target-priority roles.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

const RAMMER_STARTUP := 0.9
const RAMMER_RECOVERY := 1.2
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


static func rammer_can_commit(rammer: Dictionary, enemies: Array[Dictionary]) -> bool:
	var global_committed := 0
	var squad_committed := 0
	for enemy in enemies:
		if not bool(enemy.get("alive", false)) or StringName(enemy.get("role", &"")) != &"rammer":
			continue
		if String(enemy.get("phase", "move")) not in ["startup", "active"]:
			continue
		global_committed += 1
		if String(enemy.get("squad_id", "")) == String(rammer.get("squad_id", "")):
			squad_committed += 1
	return global_committed < 2 and squad_committed < 1


static func repair_target_id(tender: Dictionary, enemies: Array[Dictionary], stage_id: StringName, include_dynamic_cover: bool, extra_cover: Array = []) -> String:
	var best_id := ""
	var best_ratio := 1.0
	var origin := Vector2(tender["pos"])
	for target in enemies:
		if target == tender or not bool(target.get("alive", false)) or not bool(target.get("active", false)):
			continue
		var role := StringName(target.get("role", &""))
		if role in [&"repair_tender", &"stage_boss", &"boss_pylon"]:
			continue
		var maximum := float(target.get("max_health", 0.0))
		if maximum <= 0.0 or float(target.get("health", maximum)) >= maximum:
			continue
		var target_position := Vector2(target["pos"])
		if origin.distance_to(target_position) > REPAIR_RANGE:
			continue
		if not Rules.has_line_of_sight_with_extra(origin, target_position, 5.0, include_dynamic_cover, stage_id, extra_cover):
			continue
		var ratio := float(target["health"]) / maximum
		if ratio < best_ratio:
			best_ratio = ratio
			best_id = String(target["id"])
	return best_id


static func living_children(carrier_id: String, enemies: Array[Dictionary]) -> int:
	var count := 0
	for enemy in enemies:
		if bool(enemy.get("alive", false)) and String(enemy.get("carrier_id", "")) == carrier_id:
			count += 1
	return count


static func beam_end(origin: Vector2, direction: Vector2, stage_id: StringName, include_dynamic_cover: bool, extra_cover: Array = []) -> Vector2:
	var desired := origin + direction.normalized() * BEAM_RANGE
	var hit := Rules.first_cover_hit_with_extra(origin, desired, 5.0, include_dynamic_cover, stage_id, extra_cover)
	return Vector2(hit["point"]) if bool(hit.get("hit", false)) else desired


static func is_support_or_installation(role: StringName) -> bool:
	return role in [&"generator", &"shield_escort", &"repair_tender", &"drone_carrier", &"turret", &"interceptor_tower", &"beam_sentinel"]
