class_name VehicleTerrainRuntime
extends RefCounted

## Owns low-count terrain state for the run-selected field.
##
## The active damage mechanic is a run-fixed, traversable hazard zone.  A
## `field_exposure` record is deliberately kept private: callers submit one
## actor sweep and receive due neutral damage, while snapshots expose only
## stable feature data and aggregate counts.  Transit gates remain the only
## active utility facility in this runtime.

const TerrainDefinition = preload("res://scripts/vehicle/vehicle_terrain_definition.gd")

const GATE_RADIUS := 96.0
const GATE_DWELL := 0.35
const GATE_COOLDOWN := 10.0
const GATE_INVULNERABILITY := 0.45

const FIELD_EXPOSURE_DURATION := 2.5
const FIELD_EXPOSURE_TICK_SECONDS := 0.75
const HAZARD_PLAYER_DAMAGE := 5.0
const HAZARD_ORDINARY_DAMAGE := 8.0
const HAZARD_BOSS_DAMAGE := 3.0
const MAX_HOSTILE_ACTORS := 320
const MAX_TRACKED_ACTORS := MAX_HOSTILE_ACTORS + 1
const MAX_CATCH_UP_TICKS := 8

# Descriptive aliases keep the integration contract readable at call sites.
const HAZARD_EXPOSURE_SECONDS := FIELD_EXPOSURE_DURATION
const HAZARD_TICK_SECONDS := FIELD_EXPOSURE_TICK_SECONDS

var features: Array[VehicleTerrainDefinition] = []

var _hazard_zones: Array[VehicleTerrainDefinition] = []
var _field_exposure: Dictionary = {}
var _gate_cooldowns: Dictionary = {}
var _gate_progress: Dictionary = {}
var _advance_events: Array[Dictionary] = []


func configure(feature_blueprint: Array) -> void:
	## Rebuilds static features and clears all stage-local exposure records.
	features.clear()
	_hazard_zones.clear()
	_field_exposure.clear()
	_gate_cooldowns.clear()
	_gate_progress.clear()
	_advance_events.clear()
	for value in feature_blueprint:
		var feature := TerrainDefinition.from_blueprint(Dictionary(value))
		features.append(feature)
		if feature.kind == &"hazard_zone" and feature.rect.has_area():
			_hazard_zones.append(feature)
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


func hazard_damage_for_actor(
	actor_id: String,
	previous_position: Vector2,
	current_position: Vector2,
	actor_radius: float,
	actor_kind: StringName,
	delta: float
) -> float:
	## Returns all hazard damage due for one actor sweep.
	##
	## A first contact deals one immediate tick.  While the actor remains in a
	## zone, contact refreshes the shared timer but never adds a second stack.
	## Exiting keeps the timer alive, so the same actor can receive linger ticks
	## without another spatial query from the caller.
	if actor_id.is_empty() or _hazard_zones.is_empty():
		return 0.0
	var previous_inside := _point_inside_hazard(previous_position, actor_radius)
	var current_inside := _point_inside_hazard(current_position, actor_radius)
	var crossed := _segment_crosses_hazard(
		previous_position, current_position, actor_radius
	)
	var entered := not previous_inside and crossed
	var touched := current_inside or entered
	var has_exposure := _field_exposure.has(actor_id)
	if not has_exposure:
		if not touched or _field_exposure.size() >= MAX_TRACKED_ACTORS:
			return 0.0
		_field_exposure[actor_id] = {
			"remaining":FIELD_EXPOSURE_DURATION,
			"tick_remaining":FIELD_EXPOSURE_TICK_SECONDS,
			"inside":current_inside,
		}
		return _damage_for_actor_kind(actor_kind)

	var exposure: Dictionary = _field_exposure[actor_id]
	var safe_delta := maxf(0.0, delta)
	var prior_remaining := maxf(0.0, float(exposure.get("remaining", 0.0)))
	# Outside a zone, only the part of this frame that occurs before exposure
	# expiry may advance the damage interval. This preserves a tick that becomes
	# due shortly before the 2.5-second linger ends.
	var active_delta := safe_delta if touched else minf(safe_delta, prior_remaining)
	var remaining := prior_remaining - safe_delta
	var tick_remaining := float(
		exposure.get("tick_remaining", FIELD_EXPOSURE_TICK_SECONDS)
	) - active_delta
	if touched:
		# Re-entry refreshes the same exposure; it does not create a stack or
		# grant another immediate tick while the prior exposure is still alive.
		remaining = FIELD_EXPOSURE_DURATION
		exposure["inside"] = current_inside
	else:
		exposure["inside"] = false

	var damage := 0.0
	var catch_up_ticks := 0
	while (
		tick_remaining <= 0.0001
		and (touched or active_delta > 0.0)
		and catch_up_ticks < MAX_CATCH_UP_TICKS
	):
		damage += _damage_for_actor_kind(actor_kind)
		tick_remaining += FIELD_EXPOSURE_TICK_SECONDS
		catch_up_ticks += 1
	if remaining <= 0.0:
		_field_exposure.erase(actor_id)
		return damage
	exposure["remaining"] = remaining
	exposure["tick_remaining"] = tick_remaining
	_field_exposure[actor_id] = exposure
	return damage


func append_tracked_hazard_actor_ids(output: Array[String]) -> void:
	## Appends exposed and lingering actor IDs into caller-owned storage.
	## The dictionary is capped at player + 320 hostile actors.
	for actor_id in _field_exposure:
		output.append(String(actor_id))


func forget_hazard_actor(actor_id: String) -> void:
	_field_exposure.erase(actor_id)


func is_hazard_actor_tracked(actor_id: String) -> bool:
	return _field_exposure.has(actor_id)


func hazard_runtime_snapshot() -> Dictionary:
	## Stable aggregate state; actor IDs and timers remain private.
	return {
		"hazard_zone_count":_hazard_zones.size(),
		"tracked_actor_count":_field_exposure.size(),
		"max_tracked_actor_count":MAX_TRACKED_ACTORS,
	}


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
	return {
		"features":feature_snapshots,
		"hazard":hazard_runtime_snapshot(),
	}


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


func _damage_for_actor_kind(actor_kind: StringName) -> float:
	match actor_kind:
		&"player":
			return HAZARD_PLAYER_DAMAGE
		&"boss", &"stage_boss":
			return HAZARD_BOSS_DAMAGE
		_:
			return HAZARD_ORDINARY_DAMAGE


func _point_inside_hazard(position: Vector2, _actor_radius: float) -> bool:
	# The rendered hazard placement and gameplay share this exact rectangle. Keep the
	# radius parameter for the public sweep contract, but never grow damage past
	# the visible hazard footprint.
	for feature in _hazard_zones:
		if feature.rect.has_point(position):
			return true
	return false


func _segment_crosses_hazard(
	from: Vector2,
	to: Vector2,
	_actor_radius: float
) -> bool:
	for feature in _hazard_zones:
		if _segment_intersects_rect(from, to, feature.rect):
			return true
	return false


func _segment_intersects_rect(
	from: Vector2,
	to: Vector2,
	rectangle: Rect2
) -> bool:
	if rectangle.has_point(from) or rectangle.has_point(to):
		return true
	var direction := to - from
	if direction.is_zero_approx():
		return false
	var minimum := 0.0
	var maximum := 1.0
	for axis in 2:
		var origin := from[axis]
		var delta_axis := direction[axis]
		var lower := rectangle.position[axis]
		var upper := rectangle.end[axis]
		if is_zero_approx(delta_axis):
			if origin < lower or origin > upper:
				return false
			continue
		var first := (lower - origin) / delta_axis
		var second := (upper - origin) / delta_axis
		if first > second:
			var held := first
			first = second
			second = held
		minimum = maxf(minimum, first)
		maximum = minf(maximum, second)
		if minimum > maximum:
			return false
	return maximum >= 0.0 and minimum <= 1.0
