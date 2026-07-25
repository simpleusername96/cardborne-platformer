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
const SUPPORT_RELOCATION_GAP := 3.0
const SUPPORT_PLAYER_CLEARANCE := 420.0
const SUPPORT_PAIR_CLEARANCE := 96.0

var features: Array[VehicleTerrainDefinition] = []
var support_fields: Array[Dictionary] = []
var bulkhead_health: Dictionary = {}
var repair_budget := REPAIR_BUDGET
var repair_pause := 0.0
var repair_dwell := 0.0
var overdrive_active := false

var _gate_cooldowns: Dictionary = {}
var _gate_progress: Dictionary = {}
var _arc_hits: Dictionary = {}
var _arc_epochs: Dictionary = {}
var _support_sockets: Array[Vector2] = []
var _layout_seed := 0
var _stage_id: StringName = &""
var _relocation_cooldown := 0.0


func configure(
	feature_blueprint: Array,
	persistent_bulkhead_health: Dictionary,
	preserve_bulkheads: bool,
	support_sockets: Array[Vector2] = [],
	layout_seed: int = 0,
	stage_id: StringName = &""
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
	_support_sockets = support_sockets.duplicate()
	_layout_seed = layout_seed
	_stage_id = stage_id
	_relocation_cooldown = 0.0
	_configure_support_fields()


func advance(
	delta: float,
	player_position: Vector2,
	player_health: float,
	player_max_health: float
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	repair_pause = maxf(0.0, repair_pause - delta)
	_relocation_cooldown = maxf(0.0, _relocation_cooldown - delta)
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
	_advance_support_fields(delta, player_position)
	overdrive_active = _inside_active_support(
		player_position, &"overdrive"
	)
	_advance_repair(delta, player_position, player_health, player_max_health, events)
	_advance_transit(delta, player_position, events)
	return events


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
		feature_snapshots.append(feature)
	var support_snapshots: Array[Dictionary] = []
	for slot in support_fields:
		support_snapshots.append(_support_snapshot(slot))
	return {
		"features":feature_snapshots,
		"support_fields":support_snapshots,
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
	var inside := _inside_active_support(player_position, &"repair")
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


func _inside_active_support(position: Vector2, kind: StringName) -> bool:
	for slot in support_fields:
		if StringName(slot["kind"]) != kind or StringName(slot["state"]) != &"active":
			continue
		if Vector2(slot["position"]).distance_to(position) <= float(slot["radius"]):
			return true
	return false


func _configure_support_fields() -> void:
	support_fields.clear()
	if _support_sockets.size() < 4:
		return
	var schedule := TerrainDefinition.support_schedule()
	for index in schedule.size():
		var definition := Dictionary(schedule[index])
		var initial := float(definition["initial"])
		support_fields.append({
			"slot_id":StringName(definition["slot_id"]),
			"kind":StringName(definition["kind"]),
			"radius":float(definition["radius"]),
			"warning_duration":float(definition["warning"]),
			"active_duration":float(definition["active"]),
			"dormant_duration":float(definition["dormant"]),
			"initial_duration":initial,
			"state":&"warning" if initial <= 0.0 else &"initial_delay",
			"time_remaining":float(definition["warning"]) if initial <= 0.0 else initial,
			"position":_support_sockets[index],
			"relocation_index":0,
			"history":[_support_sockets[index]],
		})


func _advance_support_fields(delta: float, player_position: Vector2) -> void:
	for slot in support_fields:
		var state := StringName(slot["state"])
		if state in [&"relocation_pending", &"depleted"]:
			continue
		slot["time_remaining"] = maxf(0.0, float(slot["time_remaining"]) - delta)
		if float(slot["time_remaining"]) > 0.0:
			continue
		match state:
			&"initial_delay":
				_set_support_state(slot, &"warning")
			&"warning":
				_set_support_state(slot, &"active")
			&"active":
				_set_support_state(slot, &"dormant_marker")
			&"dormant_marker":
				slot["state"] = &"relocation_pending"
				slot["time_remaining"] = 0.0
	if repair_budget <= 0.0:
		for slot in support_fields:
			if StringName(slot["kind"]) == &"repair":
				slot["state"] = &"depleted"
				slot["time_remaining"] = 0.0
	if _relocation_cooldown > 0.0:
		return
	for slot in support_fields:
		if StringName(slot["state"]) != &"relocation_pending":
			continue
		var next_position := _choose_support_socket(slot, player_position)
		if next_position == Vector2.INF:
			continue
		slot["position"] = next_position
		slot["relocation_index"] = int(slot["relocation_index"]) + 1
		var history: Array = slot["history"]
		history.append(next_position)
		while history.size() > 3:
			history.pop_front()
		_set_support_state(slot, &"warning")
		_relocation_cooldown = SUPPORT_RELOCATION_GAP
		break


func _set_support_state(slot: Dictionary, state: StringName) -> void:
	slot["state"] = state
	match state:
		&"warning":
			slot["time_remaining"] = float(slot["warning_duration"])
		&"active":
			slot["time_remaining"] = float(slot["active_duration"])
		&"dormant_marker":
			slot["time_remaining"] = float(slot["dormant_duration"])
		_:
			slot["time_remaining"] = 0.0


func _choose_support_socket(slot: Dictionary, player_position: Vector2) -> Vector2:
	var candidates := _support_sockets.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s:%s:%d:support-v2" % [
		_layout_seed,
		String(_stage_id),
		String(slot["slot_id"]),
		int(slot["relocation_index"]) + 1,
	])
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held: Vector2 = candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = held
	for candidate in candidates:
		if _support_socket_available(Vector2(candidate), slot, player_position):
			return Vector2(candidate)
	return Vector2.INF


func _support_socket_available(
	candidate: Vector2,
	slot: Dictionary,
	player_position: Vector2
) -> bool:
	if candidate.distance_to(player_position) < SUPPORT_PLAYER_CLEARANCE:
		return false
	for previous in Array(slot["history"]):
		if candidate.is_equal_approx(Vector2(previous)):
			return false
	for other in support_fields:
		if other == slot or StringName(other["state"]) == &"depleted":
			continue
		if (
			candidate.distance_to(Vector2(other["position"]))
			< float(slot["radius"]) + float(other["radius"]) + SUPPORT_PAIR_CLEARANCE
		):
			return false
	return true


func _support_snapshot(slot: Dictionary) -> Dictionary:
	var state := StringName(slot["state"])
	var duration := 0.0
	match state:
		&"initial_delay":
			duration = float(slot["initial_duration"])
		&"warning":
			duration = float(slot["warning_duration"])
		&"active":
			duration = float(slot["active_duration"])
		&"dormant_marker":
			duration = float(slot["dormant_duration"])
	var remaining := float(slot["time_remaining"])
	return {
		"slot_id":StringName(slot["slot_id"]),
		"kind":StringName(slot["kind"]),
		"state":state,
		"position":Vector2(slot["position"]),
		"radius":float(slot["radius"]),
		"phase_progress":clampf(1.0 - remaining / maxf(duration, 0.001), 0.0, 1.0),
		"remaining_seconds":remaining,
		"effect_active":state == &"active",
		"relocation_index":int(slot["relocation_index"]),
		"repair_budget":repair_budget if StringName(slot["kind"]) == &"repair" else 0.0,
	}


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
