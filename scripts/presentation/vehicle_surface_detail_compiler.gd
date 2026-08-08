class_name VehicleSurfaceDetailCompiler
extends RefCounted

## Compiles sparse presentation-only floor details from immutable field geometry.
## It owns no collision, navigation, gameplay state, or per-frame work.

const LAYOUT_SALT := "cardborne-surface-detail-v1"
const EDGE_AND_GEOMETRY_CLEARANCE := 96.0
const PLAYER_START_CLEARANCE := 220.0
const MINIMUM_SEPARATION := 140.0
const MAX_CANDIDATES_PER_FAMILY := 4096
const ROTATIONS := [0.0, PI * 0.5, PI, PI * 1.5]
const SCALES := [0.75, 1.0, 1.25]
const FAMILIES := [
	{
		"family": &"crack",
		"asset_id": &"world/surface_detail_crack",
		"count": 72,
	},
	{
		"family": &"stain",
		"asset_id": &"world/surface_detail_stain",
		"count": 72,
	},
	{
		"family": &"embedded_chip",
		"asset_id": &"world/surface_detail_embedded_chip",
		"count": 48,
	},
]


static func compile(snapshot: Object) -> Dictionary:
	if snapshot == null:
		return _empty_contract()
	var geometry_fingerprint := _geometry_fingerprint(snapshot)
	var placements: Array[Dictionary] = []
	var family_counts := {}
	for family_value in FAMILIES:
		var family := Dictionary(family_value)
		var accepted := 0
		for candidate_index in MAX_CANDIDATES_PER_FAMILY:
			if accepted >= int(family["count"]):
				break
			var position := _candidate_position(
				geometry_fingerprint,
				StringName(family["family"]),
				candidate_index,
				Rect2(snapshot.get("world_rect"))
			)
			if not snapshot.call(
				"is_spawnable_disc",
				position,
				EDGE_AND_GEOMETRY_CLEARANCE
			):
				continue
			if position.distance_to(Vector2(snapshot.get("player_start"))) < PLAYER_START_CLEARANCE:
				continue
			if not _keeps_separation(position, placements):
				continue
			var variant_hash := _hash_value(
				"%s|%s|%d|variant" % [
					geometry_fingerprint,
					String(family["family"]),
					candidate_index,
				]
			)
			placements.append({
				"family": family["family"],
				"asset_id": family["asset_id"],
				"position": position,
				"rotation": ROTATIONS[variant_hash % ROTATIONS.size()],
				"scale": SCALES[floori(
					float(variant_hash) / float(ROTATIONS.size())
				) % SCALES.size()],
			})
			accepted += 1
		family_counts[family["family"]] = accepted

	return {
		"presentation_only": true,
		"collision_nodes": 0,
		"runtime_updates": 0,
		"batch_count": FAMILIES.size(),
		"placement_count": placements.size(),
		"family_counts": family_counts,
		"minimum_separation": MINIMUM_SEPARATION,
		"player_start_clearance": PLAYER_START_CLEARANCE,
		"geometry_clearance": EDGE_AND_GEOMETRY_CLEARANCE,
		"geometry_fingerprint": geometry_fingerprint,
		"placements": placements,
		"fingerprint": var_to_str(placements).sha256_text(),
	}


static func _empty_contract() -> Dictionary:
	return {
		"presentation_only": true,
		"collision_nodes": 0,
		"runtime_updates": 0,
		"batch_count": 0,
		"placement_count": 0,
		"family_counts": {},
		"minimum_separation": MINIMUM_SEPARATION,
		"player_start_clearance": PLAYER_START_CLEARANCE,
		"geometry_clearance": EDGE_AND_GEOMETRY_CLEARANCE,
		"geometry_fingerprint": "",
		"placements": [],
		"fingerprint": var_to_str([]).sha256_text(),
	}


static func _candidate_position(
	geometry_fingerprint: String,
	family: StringName,
	candidate_index: int,
	world_rect: Rect2
) -> Vector2:
	var safe_rect := world_rect.grow(-EDGE_AND_GEOMETRY_CLEARANCE)
	var base := "%s|%s|%s|%d" % [
		LAYOUT_SALT,
		geometry_fingerprint,
		String(family),
		candidate_index,
	]
	return safe_rect.position + Vector2(
		_hash_unit_float(base + "|x") * safe_rect.size.x,
		_hash_unit_float(base + "|y") * safe_rect.size.y
	)


static func _keeps_separation(
	position: Vector2,
	placements: Array[Dictionary]
) -> bool:
	var minimum_squared := MINIMUM_SEPARATION * MINIMUM_SEPARATION
	for placement in placements:
		if position.distance_squared_to(Vector2(placement["position"])) < minimum_squared:
			return false
	return true


static func _geometry_fingerprint(snapshot: Object) -> String:
	return var_to_str([
		StringName(snapshot.get("field_id")),
		Rect2(snapshot.get("world_rect")),
		Array(snapshot.get("walkable_rects")),
		Array(snapshot.get("selected_cover_rects")),
		Array(snapshot.get("void_rects")),
		Array(snapshot.get("terrain_zones")),
	]).sha256_text()


static func _hash_unit_float(source: String) -> float:
	return float(_hash_value(source)) / 281474976710655.0


static func _hash_value(source: String) -> int:
	return source.sha256_text().substr(0, 12).hex_to_int()
