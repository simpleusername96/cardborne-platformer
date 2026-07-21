class_name VehicleEncounterDirector
extends RefCounted

## Deterministic formation expansion and shared dense-combat pressure rules.

const THREAT_BUDGET := 4.0
const PLAYER_PROJECTILE_CAP := 240
const HOSTILE_PROJECTILE_CAP := 120
const EFFECT_CAP := 96

const TARGET_COUNTS := {
	&"flooded_works": 68,
	&"tidal_archive": 76,
	&"storm_drydock": 84,
}

const ACTIVE_CAPS := {
	&"flooded_works": 24,
	&"tidal_archive": 26,
	&"storm_drydock": 28,
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
			var ring := index / 8
			var slot := index % 8
			var slots_in_ring := mini(8, count - ring * 8)
			var radius := 62.0 + float(ring) * 54.0
			var angle := angle_offset + TAU * float(slot) / float(maxi(1, slots_in_ring))
			result.append({
				"id": "%s_%02d" % [String(group["id"]), index + 1],
				"role": StringName(roles[index % roles.size()]),
				"pos": anchor + Vector2.RIGHT.rotated(angle) * radius,
				"zone": String(group["zone"]),
				"group_id": String(group["id"]),
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
	if kind == &"ranged" and ranged_count >= 2:
		return false
	if kind == &"denial" and denial_count >= 1:
		return false
	return true
