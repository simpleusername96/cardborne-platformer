class_name VehicleBossDeathRuntime
extends RefCounted

## Owns the two-second, simulation-safe boss cleanup. VehicleRun executes the
## returned receipts because it owns enemies, facilities, effects, and audio.

const TOTAL_SECONDS := 2.0
const EXPLOSION_SPAWN_SECONDS := 0.0
const EXPLOSION_GROW_BEGIN_SECONDS := 0.15
const EXPLOSION_GROW_END_SECONDS := 1.30
const OWNED_CLEANUP_BEGIN_SECONDS := 0.20
const OWNED_CLEANUP_END_SECONDS := 1.10
const FADE_BEGIN_SECONDS := 1.30
const FADE_END_SECONDS := 1.70
const STAGGER_SECONDS := 0.12

enum State { IDLE, ACTIVE, COMPLETE }

var _state := State.IDLE
var _elapsed := 0.0
var _reduced_motion := false
var _explosion_emitted := false
var _safety_emitted := false
var _completion_emitted := false
var _owned_ids: Array[StringName] = []
var _retired_owned: Dictionary = {}

func begin(owned_ids: Array[StringName], reduced_motion: bool = false) -> Dictionary:
	if _state != State.IDLE:
		return {"accepted": false}
	_state = State.ACTIVE
	_elapsed = 0.0
	_reduced_motion = reduced_motion
	_owned_ids = owned_ids.duplicate()
	_retired_owned.clear()
	return {"accepted": true, "safety": _safety_receipt(), "explosion": _explosion_receipt()}


func reset() -> void:
	## A run reuses this bounded receipt owner for each quota-gated boss.
	_state = State.IDLE
	_elapsed = 0.0
	_reduced_motion = false
	_explosion_emitted = false
	_safety_emitted = false
	_completion_emitted = false
	_owned_ids.clear()
	_retired_owned.clear()

func advance(delta: float) -> Array[Dictionary]:
	var receipts: Array[Dictionary] = []
	if _state != State.ACTIVE:
		return receipts
	_elapsed = minf(TOTAL_SECONDS, _elapsed + maxf(0.0, delta))
	if _elapsed >= OWNED_CLEANUP_BEGIN_SECONDS and _elapsed <= OWNED_CLEANUP_END_SECONDS:
		for index in _owned_ids.size():
			var owned_id := _owned_ids[index]
			if _retired_owned.has(owned_id):
				continue
			if _elapsed + 0.0001 >= OWNED_CLEANUP_BEGIN_SECONDS + float(index) * STAGGER_SECONDS:
				_retired_owned[owned_id] = true
				receipts.append({"kind": &"retire_owned", "id": owned_id, "source": &"boss_cleanup", "grant_rewards": false, "fade_seconds": maxf(0.0, OWNED_CLEANUP_END_SECONDS - _elapsed)})
	if _elapsed >= TOTAL_SECONDS and not _completion_emitted:
		for owned_id in _owned_ids:
			if not _retired_owned.has(owned_id):
				_retired_owned[owned_id] = true
				receipts.append({"kind": &"retire_owned", "id": owned_id, "source": &"boss_cleanup", "grant_rewards": false, "fade_seconds": 0.0})
		_completion_emitted = true
		_state = State.COMPLETE
		receipts.append({"kind": &"cleanup_complete", "elapsed": TOTAL_SECONDS})
	return receipts

func presentation() -> Dictionary:
	if _state == State.IDLE:
		return {}
	var explosion_scale := 0.20
	if _reduced_motion:
		explosion_scale = 1.20
	elif _elapsed >= EXPLOSION_GROW_BEGIN_SECONDS:
		var progress := clampf((_elapsed - EXPLOSION_GROW_BEGIN_SECONDS) / (EXPLOSION_GROW_END_SECONDS - EXPLOSION_GROW_BEGIN_SECONDS), 0.0, 1.0)
		explosion_scale = lerpf(0.20, 1.20, 1.0 - pow(1.0 - progress, 3.0))
	var alpha := 1.0
	if _elapsed >= FADE_BEGIN_SECONDS:
		alpha = 1.0 - clampf((_elapsed - FADE_BEGIN_SECONDS) / (FADE_END_SECONDS - FADE_BEGIN_SECONDS), 0.0, 1.0)
	return {"elapsed": _elapsed, "explosion_scale": explosion_scale, "body_alpha": alpha, "explosion_alpha": alpha, "reduced_motion": _reduced_motion}

func active() -> bool:
	return _state == State.ACTIVE

func complete() -> bool:
	return _state == State.COMPLETE

func snapshot() -> Dictionary:
	return {"state": _state, "elapsed": _elapsed, "owned_total": _owned_ids.size(), "owned_retired": _retired_owned.size(), "reduced_motion": _reduced_motion}

func _safety_receipt() -> Dictionary:
	_safety_emitted = true
	return {"kind": &"disable_boss_danger", "disable_ai": true, "disable_collision": true, "disable_intake": true, "disable_spawn": true, "retire_damaging_owned": true, "freeze_facing": true}

func _explosion_receipt() -> Dictionary:
	_explosion_emitted = true
	return {"kind": &"spawn_explosion", "count": 1, "scale": 1.20 if _reduced_motion else 0.20, "audio": &"priority_destruction", "audio_count": 1}
