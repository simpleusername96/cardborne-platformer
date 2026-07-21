class_name VehicleEncounterDirector
extends RefCounted

## Deterministic formation expansion and shared dense-combat pressure rules.

const THREAT_BUDGET := 6.5
const MAX_RANGED_COMMITS := 3
const MAX_DENIAL_COMMITS := 2
const ENEMY_SPEED_MULTIPLIER := 1.15
const HOSTILE_PROJECTILE_SPEED_MULTIPLIER := 1.12
const ENEMY_DAMAGE_MULTIPLIER := 1.25
const ENEMY_RECOVERY_RATE := 1.20
const PLAYER_PROJECTILE_CAP := 240
const HOSTILE_PROJECTILE_CAP := 120
const EFFECT_CAP := 96

const TARGET_COUNTS := {
	&"flooded_works": 204,
	&"tidal_archive": 228,
	&"storm_drydock": 252,
}

const ACTIVE_CAPS := {
	&"flooded_works": 48,
	&"tidal_archive": 54,
	&"storm_drydock": 60,
}


static func expand_groups(groups: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group in groups:
		var count := int(group["count"])
		var roles: Array = group["roles"]
		var anchor := Vector2(group["anchor"])
		var angle_offset := float(group.get("angle", 0.0))
		var activation := Rect2(anchor - Vector2(620.0, 430.0), Vector2(1240.0, 860.0))
		var leash := activation.grow(360.0)
		for index in count:
			var ring := index / 10
			var slot := index % 10
			var slots_in_ring := mini(10, count - ring * 10)
			var radius := 48.0 + float(ring) * 36.0
			var angle := angle_offset + TAU * float(slot) / float(maxi(1, slots_in_ring))
			result.append({
				"id": "%s_%02d" % [String(group["id"]), index + 1],
				"role": StringName(roles[index % roles.size()]),
				"pos": anchor + Vector2.RIGHT.rotated(angle) * radius,
				"zone": String(group["zone"]),
				"group_id": String(group["id"]),
				"formation_anchor": anchor,
				"activation_rect": activation,
				"leash_rect": leash,
			})
	return result


static func active_cap(stage_id: StringName) -> int:
	return int(ACTIVE_CAPS.get(stage_id, 24))


static func target_count(stage_id: StringName) -> int:
	return int(TARGET_COUNTS.get(stage_id, 68))


static func can_commit(current_points: float, ranged_count: int, denial_count: int, enemy: Dictionary) -> bool:
	var cost := float(enemy.get("threat_cost", 1.0))
	var kind := StringName(enemy.get("threat_kind", &"melee"))
	if current_points + cost > THREAT_BUDGET + 0.001:
		return false
	if kind == &"ranged" and ranged_count >= MAX_RANGED_COMMITS:
		return false
	if kind == &"denial" and denial_count >= MAX_DENIAL_COMMITS:
		return false
	return true


static func tuning_contract() -> Dictionary:
	return {
		"threat_budget": THREAT_BUDGET,
		"max_ranged": MAX_RANGED_COMMITS,
		"max_denial": MAX_DENIAL_COMMITS,
		"enemy_speed_multiplier": ENEMY_SPEED_MULTIPLIER,
		"projectile_speed_multiplier": HOSTILE_PROJECTILE_SPEED_MULTIPLIER,
		"enemy_damage_multiplier": ENEMY_DAMAGE_MULTIPLIER,
		"enemy_recovery_rate": ENEMY_RECOVERY_RATE,
	}
