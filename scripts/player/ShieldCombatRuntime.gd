class_name ShieldCombatRuntime
extends RefCounted

const DefenseResolverValue = preload("res://scripts/player/DefenseResolver.gd")

const PHASE_IDLE := &"idle"
const PHASE_STARTUP := &"startup"
const PHASE_ACTIVE := &"active"
const PHASE_RECOVERY := &"recovery"

var _policy: Dictionary = {}
var _phase: StringName = PHASE_IDLE
var _phase_elapsed: float = 0.0
var _guard_held: bool = false
var _stability: int = 0
var _maximum_stability: int = 0


func configure(policy: Dictionary) -> void:
	_policy = policy.duplicate(true)
	_maximum_stability = maxi(int(_policy.get("stability", 0)), 0)
	reset()


func reset() -> void:
	_phase = PHASE_IDLE
	_phase_elapsed = 0.0
	_guard_held = false
	_stability = _maximum_stability


func update(delta: float, guard_held: bool) -> void:
	var remaining := maxf(delta, 0.0)
	_guard_held = guard_held
	if _phase == PHASE_IDLE and _guard_held:
		_enter_phase(PHASE_STARTUP)

	while remaining > 0.0:
		if _phase == PHASE_IDLE:
			break
		if _phase in [PHASE_STARTUP, PHASE_ACTIVE] and not _guard_held:
			_enter_phase(PHASE_RECOVERY)
			continue
		var duration := _phase_duration(_phase)
		if duration <= 0.0:
			_advance_phase()
			continue
		var step := minf(remaining, duration - _phase_elapsed)
		_phase_elapsed += step
		remaining -= step
		if _phase_elapsed + 0.0001 >= duration:
			_advance_phase()


func resolve_attack(
	attack_snapshot: Dictionary,
	facing: Vector2
) -> DefenseResult:
	var result := DefenseResolverValue.resolve(
		attack_snapshot,
		_current_shield_snapshot(),
		facing,
		{
			"phase": _phase,
			"phase_elapsed": _phase_elapsed,
			"guard_held": _guard_held,
		}
	)
	if _phase != PHASE_ACTIVE:
		return result
	_stability = maxi(_stability - result.stability_cost, 0)
	if result.guard_broken:
		_enter_phase(PHASE_RECOVERY)
	return result


func is_guarding() -> bool:
	return _phase == PHASE_STARTUP or _phase == PHASE_ACTIVE


func blocks_jump() -> bool:
	return is_guarding() and bool(_policy.get("blocks_jump_while_guarding", false))


func movement_speed_multiplier() -> float:
	if not is_guarding():
		return 1.0
	return clampf(float(_policy.get("guard_move_speed_multiplier", 1.0)), 0.0, 1.0)


func get_state_snapshot() -> Dictionary:
	return {
		"phase": _phase,
		"phase_elapsed": _phase_elapsed,
		"guard_held": _guard_held,
		"guarding": is_guarding(),
		"stability": _stability,
		"maximum_stability": _maximum_stability,
		"stability_fraction": (
			float(_stability) / float(_maximum_stability)
			if _maximum_stability > 0
			else 0.0
		),
		"movement_speed_multiplier": movement_speed_multiplier(),
		"blocks_jump": blocks_jump(),
	}


func _current_shield_snapshot() -> Dictionary:
	var snapshot := _policy.duplicate(true)
	snapshot["stability"] = _stability
	return snapshot


func _advance_phase() -> void:
	match _phase:
		PHASE_STARTUP:
			_enter_phase(PHASE_ACTIVE if _guard_held else PHASE_RECOVERY)
		PHASE_ACTIVE:
			# Active guard has no fixed duration; only release or a guard break advances it.
			return
		PHASE_RECOVERY:
			_stability = _maximum_stability
			_enter_phase(PHASE_STARTUP if _guard_held else PHASE_IDLE)
		_:
			_enter_phase(PHASE_IDLE)


func _enter_phase(next_phase: StringName) -> void:
	_phase = next_phase
	_phase_elapsed = 0.0


func _phase_duration(candidate_phase: StringName) -> float:
	match candidate_phase:
		PHASE_STARTUP:
			return maxf(float(_policy.get("startup_time", 0.0)), 0.0)
		PHASE_RECOVERY:
			return maxf(float(_policy.get("recovery_time", 0.0)), 0.0)
		_:
			return INF
