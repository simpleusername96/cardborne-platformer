class_name VehicleBossExamRuntime
extends RefCounted

## Owns sequential boss health floors and actionable objective-module state.
## The run supplies spawning, collision and damage services; this runtime never
## scans the complete enemy array.

const Catalog = preload("res://scripts/bosses/vehicle_boss_exam_catalog.gd")

var stage_id: StringName = &"stage_1"
var phase := 1
var objective_locked := true
var vulnerability_remaining := 0.0

var _definition: Dictionary = {}
var _module_ids := PackedStringArray()
var _destroyed_modules: Dictionary = {}
var _active_index := -1
var _phase_history := PackedInt32Array()
var _phase_skip_count := 0
var _objective_successes := 0
var _vulnerability_windows := 0
var _locked_time := 0.0
var _open_time := 0.0
var _adds_spawned := 0
var _maximum_live_adds := 0


func configure(next_stage_id: StringName, starting_phase: int = 1) -> void:
	stage_id = next_stage_id
	_definition = Catalog.exam(stage_id)
	phase = clampi(starting_phase, 1, 3)
	objective_locked = true
	vulnerability_remaining = 0.0
	_module_ids.clear()
	_destroyed_modules.clear()
	_active_index = -1
	_phase_history = PackedInt32Array([phase])
	_phase_skip_count = 0
	_objective_successes = 0
	_vulnerability_windows = 0
	_locked_time = 0.0
	_open_time = 0.0
	_adds_spawned = 0
	_maximum_live_adds = 0


func begin_phase(boss_max_health: float, requested_phase: int = -1) -> Dictionary:
	if requested_phase >= 1:
		if requested_phase > phase + 1:
			_phase_skip_count += 1
		phase = clampi(requested_phase, 1, 3)
		if _phase_history.is_empty() or _phase_history[-1] != phase:
			_phase_history.append(phase)
	objective_locked = true
	vulnerability_remaining = 0.0
	_destroyed_modules.clear()
	_module_ids.clear()
	var module_kinds := Array(_definition.get("module_kinds", []))
	var module_offsets := Array(_definition.get("module_offsets", []))
	var modules: Array[Dictionary] = []
	for index in mini(module_kinds.size(), module_offsets.size()):
		var module_id := "boss_objective_p%d_m%d" % [phase, index]
		_module_ids.append(module_id)
		modules.append({
			"id":module_id,
			"kind":StringName(module_kinds[index]),
			"index":index,
			"offset":Vector2(module_offsets[index]),
			"health":maxf(1.0, boss_max_health * Catalog.MODULE_HEALTH_RATIO),
		})
	_active_index = _initial_active_index()
	return {
		"phase":phase,
		"modules":modules,
		"add_roles":Catalog.add_roles(stage_id, phase),
		"tactic_id":Catalog.tactic_id(stage_id, phase),
		"cue_key":cue_key(),
	}


func advance(delta: float) -> void:
	var bounded_delta := maxf(0.0, delta)
	if objective_locked:
		_locked_time += bounded_delta
	else:
		_open_time += bounded_delta
	vulnerability_remaining = maxf(
		0.0,
		vulnerability_remaining - bounded_delta
	)


func damage_allowance(health: float, max_health: float) -> float:
	if objective_locked:
		return 0.0
	var floor_health := max_health * Catalog.phase_floor(phase)
	return maxf(0.0, health - floor_health)


func boss_damage_multiplier() -> float:
	return 1.55 if vulnerability_remaining > 0.0 else 1.0


func try_advance_phase(health: float, max_health: float) -> Dictionary:
	if phase >= 3 or objective_locked:
		return {}
	var floor_health := max_health * Catalog.phase_floor(phase)
	if health > floor_health + 0.001:
		return {}
	var previous := phase
	phase += 1
	if phase != previous + 1:
		_phase_skip_count += 1
	_phase_history.append(phase)
	return {
		"from":previous,
		"phase":phase,
		"cue_key":Catalog.cue_key(stage_id, phase),
	}


func can_damage_module(module_id: String) -> bool:
	if not objective_locked or module_id not in _module_ids:
		return false
	if bool(_destroyed_modules.get(module_id, false)):
		return false
	var mode := StringName(_definition.get("resolution_mode", &"parallel"))
	if mode == &"parallel":
		return true
	return _module_ids.find(module_id) == _active_index


func register_module_defeat(module_id: String) -> Dictionary:
	if not can_damage_module(module_id):
		return {}
	_destroyed_modules[module_id] = true
	var remaining := 0
	for id in _module_ids:
		remaining += 0 if bool(_destroyed_modules.get(id, false)) else 1
	if remaining <= 0:
		objective_locked = false
		vulnerability_remaining = Catalog.VULNERABILITY_SECONDS
		_objective_successes += 1
		_vulnerability_windows += 1
		_active_index = -1
		return {
			"resolved":true,
			"vulnerability":vulnerability_remaining,
		"cue_key":"BOSS_EXAM_CORE_OPEN",
		}
	_active_index = _next_unresolved_index()
	return {
		"resolved":false,
		"active_module_id":(
			_module_ids[_active_index]
			if _active_index >= 0
			else ""
		),
		"cue_key":cue_key(),
	}


func module_state(module_id: String) -> StringName:
	if bool(_destroyed_modules.get(module_id, false)):
		return &"resolved"
	return &"active" if can_damage_module(module_id) else &"locked"


func active_module_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for module_id in _module_ids:
		if can_damage_module(module_id):
			result.append(module_id)
	return result


func route_collision_target() -> String:
	if (
		StringName(_definition.get("objective", &"")) != &"route_switch"
		or _module_ids.size() < 2
		or not bool(_destroyed_modules.get(_module_ids[0], false))
		or bool(_destroyed_modules.get(_module_ids[1], false))
	):
		return ""
	return _module_ids[1]


func cue_key() -> String:
	return Catalog.cue_key(stage_id, phase)


func objective_id() -> StringName:
	return StringName(_definition.get("objective", &""))


func variant() -> StringName:
	return StringName(_definition.get("variant", &"colossus"))


func note_adds_spawned(count: int, live_count: int) -> void:
	_adds_spawned += maxi(0, count)
	_maximum_live_adds = maxi(_maximum_live_adds, maxi(0, live_count))


func snapshot() -> Dictionary:
	return {
		"stage_id":stage_id,
		"variant":variant(),
		"phase":phase,
		"phase_history":Array(_phase_history),
		"phase_skip_count":_phase_skip_count,
		"objective_id":objective_id(),
		"objective_locked":objective_locked,
		"module_count":_module_ids.size(),
		"active_module_ids":Array(active_module_ids()),
		"vulnerability_remaining":vulnerability_remaining,
		"objective_successes":_objective_successes,
		"vulnerability_windows":_vulnerability_windows,
		"locked_time":_locked_time,
		"open_time":_open_time,
		"adds_spawned":_adds_spawned,
		"maximum_live_adds":_maximum_live_adds,
	}


func _initial_active_index() -> int:
	var mode := StringName(_definition.get("resolution_mode", &"parallel"))
	if mode == &"parallel":
		return -1
	if mode == &"polarity":
		return (phase - 1) % maxi(1, _module_ids.size())
	return 0


func _next_unresolved_index() -> int:
	for offset in _module_ids.size():
		var index := (
			_active_index + 1 + offset
		) % maxi(1, _module_ids.size())
		if not bool(_destroyed_modules.get(_module_ids[index], false)):
			return index
	return -1
