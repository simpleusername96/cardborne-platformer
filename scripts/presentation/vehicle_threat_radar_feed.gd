class_name VehicleThreatRadarFeed
extends RefCounted

## Owns coherent five-hertz threat samples. The inactive fixed frame is filled
## and then swapped once so presentation never observes a mixed sample origin.

const CombatCuePolicy = preload(
	"res://scripts/presentation/components/vehicle_combat_cue_policy.gd"
)

const SECTOR_COUNT := 12
const FRAME_COUNT := 2

var _frames: Array[Dictionary] = []
var _active_index := -1
var _write_index := 0
var _generation := 0
var _sample_origin := Vector2.ZERO
var _maximum_distance := 1200.0


func _init(maximum_distance: float = 1200.0) -> void:
	_maximum_distance = maxf(1.0, maximum_distance)
	for _frame_index in FRAME_COUNT:
		var sectors: Array[Dictionary] = []
		for _sector_index in SECTOR_COUNT:
			sectors.append(_new_sector())
		_frames.append({
			"generation":0,
			"sample_origin":Vector2.ZERO,
			"max_distance":_maximum_distance,
			"sectors":sectors,
		})


func begin_sample(origin: Vector2) -> void:
	_write_index = 0 if _active_index != 0 else 1
	_sample_origin = origin
	var sectors: Array = _frames[_write_index]["sectors"]
	for sector_variant in sectors:
		_reset_sector(sector_variant as Dictionary)


func append_offset(
	offset: Vector2,
	kind: StringName,
	readiness: float
) -> void:
	var distance := offset.length()
	if distance <= 0.001 or distance > _maximum_distance:
		return
	var angle := offset.angle()
	var sector_index := posmod(
		floori((angle + PI) / TAU * float(SECTOR_COUNT)),
		SECTOR_COUNT
	)
	var sectors: Array = _frames[_write_index]["sectors"]
	var sector: Dictionary = sectors[sector_index]
	var clamped_readiness := clampf(readiness, 0.0, 1.0)
	var world_position := _sample_origin + offset
	if not bool(sector["active"]):
		sector["active"] = true
		sector["count"] = 1
		sector["world_position"] = world_position
		sector["distance"] = distance
		sector["proximity_distance"] = distance
		sector["kind"] = kind
		sector["readiness"] = clamped_readiness
		return
	sector["count"] = int(sector["count"]) + 1
	sector["proximity_distance"] = minf(
		float(sector["proximity_distance"]), distance
	)
	var existing_kind := StringName(sector["kind"])
	var priority := CombatCuePolicy.contact_priority(kind)
	var existing_priority := CombatCuePolicy.contact_priority(existing_kind)
	if priority > existing_priority:
		sector["kind"] = kind
		sector["readiness"] = clamped_readiness
		sector["world_position"] = world_position
		sector["distance"] = distance
	elif priority == existing_priority:
		sector["readiness"] = maxf(
			float(sector["readiness"]), clamped_readiness
		)
		if distance < float(sector["distance"]):
			sector["world_position"] = world_position
			sector["distance"] = distance


func commit_sample() -> void:
	_generation += 1
	var frame := _frames[_write_index]
	frame["generation"] = _generation
	frame["sample_origin"] = _sample_origin
	frame["max_distance"] = _maximum_distance
	_active_index = _write_index


func snapshot() -> Dictionary:
	if _active_index < 0:
		return _frames[0]
	return _frames[_active_index]


func generation() -> int:
	return _generation


func debug_contract() -> Dictionary:
	return {
		"frame_count":FRAME_COUNT,
		"sector_count":SECTOR_COUNT,
		"generation":_generation,
		"active_index":_active_index,
		"maximum_distance":_maximum_distance,
	}


func _new_sector() -> Dictionary:
	return {
		"active":false,
		"count":0,
		"world_position":Vector2.ZERO,
		"distance":0.0,
		"proximity_distance":0.0,
		"kind":CombatCuePolicy.CONTACT_NEARBY_ENEMY,
		"readiness":0.0,
	}


func _reset_sector(sector: Dictionary) -> void:
	sector["active"] = false
	sector["count"] = 0
	sector["world_position"] = Vector2.ZERO
	sector["distance"] = 0.0
	sector["proximity_distance"] = 0.0
	sector["kind"] = CombatCuePolicy.CONTACT_NEARBY_ENEMY
	sector["readiness"] = 0.0
