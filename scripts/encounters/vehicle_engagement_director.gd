class_name VehicleEngagementDirector
extends RefCounted

## Bounded, allocation-time engagement reservations. This owner has no actor
## references and never scans the live enemy population.

const CAPACITY := 320
const SECTOR_COUNT := 8
const ETA_BUCKET_COUNT := 32
const ETA_BUCKET_SECONDS := 0.5
const DEBT_MAX := 8
const GATE_COMPLETE_RADIUS := 96.0
const STATE_FREE := 0
const STATE_RESERVED := 1
const STATE_MATERIALIZED := 2
const STATE_RELEASED := 3
const BROAD_CRESCENT: StringName = &"broad_crescent"
const TWO_OFFSET_STREAMS: StringName = &"two_offset_streams"

var _seed := 0
var _next_slot := 0
var _generation := PackedInt32Array()
var _state := PackedByteArray()
var _sector := PackedByteArray()
var _eta_bucket := PackedByteArray()
var _eta_epoch := PackedInt32Array()
var _expected_time := PackedFloat32Array()
var _expiry_time := PackedFloat32Array()
var _anchor_x := PackedFloat32Array()
var _anchor_y := PackedFloat32Array()
var _gate_x := PackedFloat32Array()
var _gate_y := PackedFloat32Array()
var _sector_eta_load := PackedInt32Array()
var _sector_debt := PackedByteArray()


func _init() -> void:
	_generation.resize(CAPACITY)
	_state.resize(CAPACITY)
	_sector.resize(CAPACITY)
	_eta_bucket.resize(CAPACITY)
	_eta_epoch.resize(CAPACITY)
	_expected_time.resize(CAPACITY)
	_expiry_time.resize(CAPACITY)
	_anchor_x.resize(CAPACITY)
	_anchor_y.resize(CAPACITY)
	_gate_x.resize(CAPACITY)
	_gate_y.resize(CAPACITY)
	_sector_eta_load.resize(SECTOR_COUNT * ETA_BUCKET_COUNT)
	_sector_debt.resize(SECTOR_COUNT)


func configure(seed: int) -> void:
	_seed = seed
	reset()


func reset() -> void:
	_next_slot = 0
	_state.fill(STATE_FREE)
	_sector_eta_load.fill(0)
	_sector_debt.fill(0)


func reserve(request: Dictionary) -> Dictionary:
	var slot := _find_free_slot()
	if slot < 0:
		return {}
	var eligible: Array[int] = _eligible_sectors(request)
	if eligible.is_empty():
		return {"fallback":true, "no_gate":true}
	var candidates := _two_candidates(eligible, request)
	var valid_candidates: Array[int] = []
	for sector in candidates:
		if _gate_is_valid(sector, request):
			valid_candidates.append(sector)
	var chosen := _choose_candidate(valid_candidates, request)
	if chosen < 0:
		chosen = _next_valid_candidate(eligible, candidates, request)
	if chosen < 0:
		return {"fallback":true, "no_gate":true}
	var expected := float(request.get("expected_time", 0.0))
	var bucket := posmod(floori(expected / ETA_BUCKET_SECONDS), ETA_BUCKET_COUNT)
	var epoch := floori(expected / (ETA_BUCKET_SECONDS * ETA_BUCKET_COUNT))
	_generation[slot] += 1
	if _generation[slot] <= 0:
		_generation[slot] = 1
	_state[slot] = STATE_RESERVED
	_sector[slot] = chosen
	_eta_bucket[slot] = bucket
	_eta_epoch[slot] = epoch
	_expected_time[slot] = expected
	_expiry_time[slot] = float(request.get("expiry_time", expected + 4.0))
	var anchor := Vector2(request.get("anchor", Vector2.ZERO))
	var gate := _gate_for_sector(chosen, anchor, request)
	_anchor_x[slot] = anchor.x
	_anchor_y[slot] = anchor.y
	_gate_x[slot] = gate.x
	_gate_y[slot] = gate.y
	_add_counter(chosen, bucket, 1)
	for sector in eligible:
		if sector == chosen:
			_sector_debt[sector] = 0
		else:
			_sector_debt[sector] = mini(DEBT_MAX, _sector_debt[sector] + 1)
	_next_slot = (slot + 1) % CAPACITY
	return _handle(slot)


func confirm(handle: Dictionary) -> bool:
	return _transition(handle, STATE_RESERVED, STATE_MATERIALIZED)


func complete(handle: Dictionary) -> bool:
	return _release(handle, STATE_MATERIALIZED)


func expire(handle: Dictionary, now: float) -> bool:
	if not _valid(handle) or now < _expiry_time[int(handle["slot"])]:
		return false
	var slot := int(handle["slot"])
	return _release(handle, _state[slot])


func cancel(handle: Dictionary) -> bool:
	if not _valid(handle):
		return false
	var slot := int(handle["slot"])
	if _state[slot] != STATE_RESERVED:
		return false
	return _release(handle, STATE_RESERVED)


func release(handle: Dictionary) -> bool:
	if not _valid(handle):
		return false
	return _release(handle, _state[int(handle["slot"])])


func reservation(handle: Dictionary) -> Dictionary:
	if not _valid(handle):
		return {}
	var slot := int(handle["slot"])
	return {"sector":int(_sector[slot]), "eta_bucket":int(_eta_bucket[slot]), "eta_epoch":_eta_epoch[slot], "expected_time":_expected_time[slot], "expiry_time":_expiry_time[slot], "anchor":Vector2(_anchor_x[slot], _anchor_y[slot]), "gate":Vector2(_gate_x[slot], _gate_y[slot]), "state":int(_state[slot])}


static func pattern_sectors(pattern: StringName, heading_sector: int, unit_round: int = 0) -> PackedInt32Array:
	var offsets: Array = []
	if pattern == BROAD_CRESCENT:
		offsets = [-2, -1, 0, 1, 2]
	elif pattern == TWO_OFFSET_STREAMS:
		# Alternating streams preserve forward center and the rear three-sector arc.
		offsets = ([-2, -1] if unit_round % 2 == 0 else [1, 2])
	else:
		return PackedInt32Array()
	var result := PackedInt32Array()
	for offset in offsets:
		result.append(posmod(heading_sector + offset, SECTOR_COUNT))
	return result


static func gate_radius(movement_family: StringName, distance_band: Vector2 = Vector2.ZERO) -> float:
	if movement_family == &"pursuit":
		return 520.0
	if distance_band != Vector2.ZERO:
		return clampf((distance_band.x + distance_band.y) * 0.5, 430.0, 600.0)
	return 0.0


static func expiry_time(birth_time: float, transit_eta: float) -> float:
	return birth_time + clampf(transit_eta + 2.0, 4.0, 18.0)


func fill_debug(into: Dictionary) -> void:
	into["capacity"] = CAPACITY
	into["reserved_load"] = _sector_eta_load.duplicate()
	into["sector_debt"] = _sector_debt.duplicate()
	into["live_count"] = _live_count()


func _eligible_sectors(request: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for value in Array(request.get("eligible_sectors", [])):
		var sector := posmod(int(value), SECTOR_COUNT)
		if sector not in result:
			result.append(sector)
	return result


func _two_candidates(eligible: Array[int], request: Dictionary) -> Array[int]:
	var ordered := eligible.duplicate()
	ordered.sort()
	var identity := "%d:%s:%d" % [_seed, String(request.get("id", "")), int(request.get("ordinal", 0))]
	var first := posmod(hash(identity + ":a"), ordered.size())
	var second := first if ordered.size() == 1 else posmod(first + 1 + posmod(hash(identity + ":b"), ordered.size() - 1), ordered.size())
	return [ordered[first], ordered[second]]


func _choose_candidate(candidates: Array[int], request: Dictionary) -> int:
	var expected := float(request.get("expected_time", 0.0))
	var bucket := posmod(floori(expected / ETA_BUCKET_SECONDS), ETA_BUCKET_COUNT)
	var heading_sector := posmod(int(request.get("heading_sector", 0)), SECTOR_COUNT)
	var best := -1
	var best_score := INF
	for sector in candidates:
		var angular := mini(posmod(sector - heading_sector, SECTOR_COUNT), posmod(heading_sector - sector, SECTOR_COUNT))
		var tie := float(posmod(hash("%d:%s:%d" % [_seed, String(request.get("id", "")), sector]), 10000)) / 10000.0
		var score := float(_sector_eta_load[sector * ETA_BUCKET_COUNT + bucket]) * 16.0 + float(_sector_debt[sector]) + float(angular) + tie
		if score < best_score:
			best_score = score
			best = sector
	return best


func _next_valid_candidate(eligible: Array[int], sampled: Array[int], request: Dictionary) -> int:
	var remaining: Array[int] = []
	for sector in eligible:
		if sector not in sampled:
			remaining.append(sector)
	while not remaining.is_empty():
		var pair: Array[int] = []
		pair.append(remaining.pop_front())
		if not remaining.is_empty():
			pair.append(remaining.pop_front())
		var valid_pair: Array[int] = []
		for sector in pair:
			if _gate_is_valid(sector, request):
				valid_pair.append(sector)
		var chosen := _choose_candidate(valid_pair, request)
		if chosen >= 0:
			return chosen
	return -1


func _gate_is_valid(sector: int, request: Dictionary) -> bool:
	var validity: Dictionary = request.get("gate_valid_by_sector", {})
	return bool(validity.get(sector, true))


func _gate_for_sector(sector: int, anchor: Vector2, request: Dictionary) -> Vector2:
	var gates: Dictionary = request.get("gate_by_sector", {})
	if gates.has(sector):
		return Vector2(gates[sector])
	var radius := maxf(0.0, float(request.get("gate_radius", 0.0)))
	if radius > 0.0:
		return anchor + Vector2.RIGHT.rotated(
			float(sector - 4) * TAU / float(SECTOR_COUNT)
		) * radius
	return Vector2(request.get("gate", anchor))


func _find_free_slot() -> int:
	for offset in CAPACITY:
		var slot := (_next_slot + offset) % CAPACITY
		if _state[slot] == STATE_FREE:
			return slot
	return -1


func _transition(handle: Dictionary, before: int, after: int) -> bool:
	if not _valid(handle):
		return false
	var slot := int(handle["slot"])
	if _state[slot] != before:
		return false
	_state[slot] = after
	return true


func _release(handle: Dictionary, before: int) -> bool:
	if before != STATE_RESERVED and before != STATE_MATERIALIZED:
		return false
	var slot := int(handle["slot"])
	_add_counter(_sector[slot], _eta_bucket[slot], -1)
	_state[slot] = STATE_FREE
	return true


func _valid(handle: Dictionary) -> bool:
	var slot := int(handle.get("slot", -1))
	return slot >= 0 and slot < CAPACITY and _state[slot] != STATE_FREE and _generation[slot] == int(handle.get("generation", -1))


func _handle(slot: int) -> Dictionary:
	return {"slot":slot, "generation":_generation[slot]}


func _add_counter(sector: int, bucket: int, delta: int) -> void:
	var index := sector * ETA_BUCKET_COUNT + bucket
	_sector_eta_load[index] = maxi(0, _sector_eta_load[index] + delta)


func _live_count() -> int:
	var count := 0
	for value in _state:
		if value == STATE_RESERVED or value == STATE_MATERIALIZED:
			count += 1
	return count
