class_name VehicleTerrainRuntime
extends RefCounted

## Owns low-count transit-gate state for the run-selected field.

const TerrainDefinition = preload("res://scripts/vehicle/vehicle_terrain_definition.gd")

const GATE_RADIUS := 96.0
const GATE_DWELL := 0.35
const GATE_COOLDOWN := 10.0
const GATE_INVULNERABILITY := 0.45

var features: Array[VehicleTerrainDefinition] = []

var _gate_cooldowns: Dictionary = {}
var _gate_progress: Dictionary = {}
var _advance_events: Array[Dictionary] = []


func configure(feature_blueprint: Array) -> void:
	## Rebuilds static features and clears all stage-local gate state.
	features.clear()
	_gate_cooldowns.clear()
	_gate_progress.clear()
	_advance_events.clear()
	for value in feature_blueprint:
		var feature := TerrainDefinition.from_blueprint(Dictionary(value))
		features.append(feature)
		if feature.kind == &"transit_gate" and not feature.pair.is_empty():
			if not _gate_cooldowns.has(feature.pair):
				_gate_cooldowns[feature.pair] = 0.0
				_gate_progress[feature.pair] = 0.0


func advance(
	delta: float,
	player_position: Vector2
) -> Array[Dictionary]:
	## Advances only transit state and returns the caller-owned event receipt.
	_advance_events.clear()
	var safe_delta := maxf(0.0, delta)
	for pair in _gate_cooldowns:
		_gate_cooldowns[pair] = maxf(
			0.0, float(_gate_cooldowns[pair]) - safe_delta
		)
	_advance_transit(safe_delta, player_position, _advance_events)
	return _advance_events


func snapshot() -> Dictionary:
	var feature_snapshots: Array[Dictionary] = []
	for value in features:
		var feature := value.snapshot()
		if value.kind == &"transit_gate":
			feature["progress"] = float(
				_gate_progress.get(value.pair, 0.0)
			) / GATE_DWELL
			feature["cooldown"] = float(_gate_cooldowns.get(value.pair, 0.0))
		feature_snapshots.append(feature)
	return {"features":feature_snapshots}


func structural_wall_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for feature in features:
		if feature.kind == &"structural_wall" and feature.rect.has_area():
			result.append(feature.rect)
	return result


func _advance_transit(
	delta: float,
	player_position: Vector2,
	events: Array[Dictionary]
) -> void:
	var active_pair: StringName = &""
	var active_feature: VehicleTerrainDefinition
	for feature in features:
		if (
			feature.kind == &"transit_gate"
			and feature.pos.distance_to(player_position) <= GATE_RADIUS
		):
			active_pair = feature.pair
			active_feature = feature
			break
	for pair in _gate_progress:
		if pair != active_pair:
			_gate_progress[pair] = 0.0
	if (
		active_pair.is_empty()
		or float(_gate_cooldowns.get(active_pair, 0.0)) > 0.0
	):
		return
	_gate_progress[active_pair] = float(
		_gate_progress.get(active_pair, 0.0)
	) + delta
	if float(_gate_progress[active_pair]) < GATE_DWELL:
		return
	for feature in features:
		if (
			feature.kind == &"transit_gate"
			and feature.pair == active_pair
			and feature.id != active_feature.id
		):
			events.append({
				"kind":&"transit",
				"pair":active_pair,
				"destination":feature.pos,
				"invulnerability":GATE_INVULNERABILITY,
			})
			_gate_cooldowns[active_pair] = GATE_COOLDOWN
			_gate_progress[active_pair] = 0.0
			return
