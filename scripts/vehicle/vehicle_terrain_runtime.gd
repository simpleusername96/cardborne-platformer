class_name VehicleTerrainRuntime
extends RefCounted

## Low-count functional terrain state for the run-selected field.

const TerrainDefinition = preload("res://scripts/vehicle/vehicle_terrain_definition.gd")
const ARC_CYCLE := 5.2
const ARC_WARNING := 1.4
const ARC_ACTIVE := 0.8
const GATE_RADIUS := 96.0
const GATE_DWELL := 0.35
const GATE_COOLDOWN := 10.0
const GATE_INVULNERABILITY := 0.45
const REPAIR_RADIUS := 150.0
const REPAIR_DWELL := 0.50
const REPAIR_RATE := 4.0
const REPAIR_BUDGET := 24.0
const REPAIR_HIT_PAUSE := 1.0
const OVERDRIVE_RADIUS := 180.0
const BULKHEAD_HEALTH := 72.0

var features: Array[VehicleTerrainDefinition] = []
var bulkhead_health: Dictionary = {}
var repair_budget := REPAIR_BUDGET
var repair_pause := 0.0
var repair_dwell := 0.0
var overdrive_active := false

var _gate_cooldowns: Dictionary = {}
var _gate_progress: Dictionary = {}
var _arc_hits: Dictionary = {}
var _arc_epochs: Dictionary = {}


func configure(
	feature_blueprint: Array,
	persistent_bulkhead_health: Dictionary,
	preserve_bulkheads: bool
) -> void:
	features.clear()
	for value in feature_blueprint:
		features.append(TerrainDefinition.from_blueprint(Dictionary(value)))
	bulkhead_health = persistent_bulkhead_health
	if not preserve_bulkheads:
		bulkhead_health.clear()
	for feature in features:
		if feature.kind == &"breakable_bulkhead":
			var id := feature.id
			if not bulkhead_health.has(id):
				bulkhead_health[id] = BULKHEAD_HEALTH
	_gate_cooldowns = {&"a":0.0, &"b":0.0}
	_gate_progress = {&"a":0.0, &"b":0.0}
	_arc_hits.clear()
	_arc_epochs.clear()
	repair_budget = REPAIR_BUDGET
	repair_pause = 0.0
	repair_dwell = 0.0
	overdrive_active = false


func advance(
	delta: float,
	player_position: Vector2,
	player_health: float,
	player_max_health: float
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	repair_pause = maxf(0.0, repair_pause - delta)
	for pair in _gate_cooldowns:
		_gate_cooldowns[pair] = maxf(0.0, float(_gate_cooldowns[pair]) - delta)
	for feature in features:
		if feature.kind != &"arc_surge":
			continue
		var previous_time := feature.time
		var next_time := fposmod(previous_time + delta, ARC_CYCLE)
		feature.time = next_time
		if next_time < previous_time:
			var id := feature.id
			_arc_epochs[id] = int(_arc_epochs.get(id, 0)) + 1
	overdrive_active = _inside_kind(player_position, &"overdrive_field", OVERDRIVE_RADIUS)
	_advance_repair(delta, player_position, player_health, player_max_health, events)
	_advance_transit(delta, player_position, events)
	return events


func flow_vector_at(
	position: Vector2,
	is_boss: bool = false,
	is_stationary: bool = false
) -> Vector2:
	if is_stationary:
		return Vector2.ZERO
	for feature in features:
		if (
			feature.kind == &"flow_channel"
			and feature.rect.has_point(position)
		):
			return feature.vector * (0.5 if is_boss else 1.0)
	return Vector2.ZERO


func surge_damage_for(
	actor_id: String,
	position: Vector2,
	actor_kind: StringName
) -> float:
	for feature in features:
		if feature.kind != &"arc_surge" or not _arc_is_active(feature):
			continue
		if not feature.rect.has_point(position):
			continue
		var feature_id := feature.id
		var epoch := int(_arc_epochs.get(feature_id, 0))
		var hit_key := "%s:%d:%s" % [feature_id, epoch, actor_id]
		if _arc_hits.has(hit_key):
			continue
		_arc_hits[hit_key] = true
		match actor_kind:
			&"player":
				return 10.0
			&"boss":
				return 6.0
			_:
				return 18.0
	return 0.0


func record_player_damage() -> void:
	repair_pause = REPAIR_HIT_PAUSE
	repair_dwell = 0.0


func live_bulkhead_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for feature in features:
		if (
			feature.kind == &"breakable_bulkhead"
			and float(bulkhead_health.get(feature.id, 0.0)) > 0.0
		):
			result.append(feature.rect)
	return result


func bulkhead_id_for_rect(rectangle: Rect2) -> StringName:
	for feature in features:
		if (
			feature.kind == &"breakable_bulkhead"
			and feature.rect == rectangle
			and float(bulkhead_health.get(feature.id, 0.0)) > 0.0
		):
			return feature.id
	return &""


func damage_bulkhead(bulkhead_id: StringName, amount: float) -> bool:
	if bulkhead_id.is_empty() or not bulkhead_health.has(bulkhead_id):
		return false
	var health := float(bulkhead_health[bulkhead_id])
	if health <= 0.0:
		return false
	bulkhead_health[bulkhead_id] = maxf(0.0, health - maxf(0.0, amount))
	return health > 0.0 and float(bulkhead_health[bulkhead_id]) <= 0.0


func snapshot() -> Dictionary:
	var feature_snapshots: Array[Dictionary] = []
	for value in features:
		var feature := value.snapshot()
		var kind := value.kind
		if kind == &"arc_surge":
			feature["readiness"] = _arc_readiness(value)
			feature["active"] = _arc_is_active(value)
		elif kind == &"breakable_bulkhead":
			feature["health"] = float(bulkhead_health.get(value.id, 0.0))
		elif kind == &"transit_gate":
			var pair := value.pair
			feature["progress"] = float(_gate_progress.get(pair, 0.0)) / GATE_DWELL
			feature["cooldown"] = float(_gate_cooldowns.get(pair, 0.0))
		elif kind == &"repair_basin":
			feature["budget"] = repair_budget
			feature["pause"] = repair_pause
		elif kind == &"overdrive_field":
			feature["active"] = overdrive_active
		feature_snapshots.append(feature)
	return {
		"features":feature_snapshots,
		"overdrive_active":overdrive_active,
		"repair_budget":repair_budget,
	}


func _advance_repair(
	delta: float,
	player_position: Vector2,
	player_health: float,
	player_max_health: float,
	events: Array[Dictionary]
) -> void:
	var inside := _inside_kind(player_position, &"repair_basin", REPAIR_RADIUS)
	if not inside:
		repair_dwell = 0.0
		return
	repair_dwell = minf(REPAIR_DWELL, repair_dwell + delta)
	if (
		repair_dwell < REPAIR_DWELL
		or repair_pause > 0.0
		or repair_budget <= 0.0
		or player_health >= player_max_health
	):
		return
	var amount := minf(REPAIR_RATE * delta, minf(repair_budget, player_max_health - player_health))
	if amount > 0.0:
		repair_budget -= amount
		events.append({"kind":&"heal", "amount":amount})


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
	if active_pair.is_empty() or float(_gate_cooldowns.get(active_pair, 0.0)) > 0.0:
		return
	_gate_progress[active_pair] = float(_gate_progress.get(active_pair, 0.0)) + delta
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


func _inside_kind(position: Vector2, kind: StringName, radius: float) -> bool:
	for feature in features:
		if feature.kind != kind:
			continue
		if feature.pos.distance_to(position) <= radius:
			return true
	return false


func _arc_is_active(feature: VehicleTerrainDefinition) -> bool:
	return feature.time >= ARC_CYCLE - ARC_ACTIVE


func _arc_readiness(feature: VehicleTerrainDefinition) -> float:
	var time := feature.time
	var warning_start := ARC_CYCLE - ARC_ACTIVE - ARC_WARNING
	if time < warning_start:
		return 0.0
	if time >= ARC_CYCLE - ARC_ACTIVE:
		return 1.0
	return inverse_lerp(warning_start, ARC_CYCLE - ARC_ACTIVE, time)
