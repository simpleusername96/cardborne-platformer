class_name BossBase
extends RefCounted

const STATE_DORMANT := &"dormant"
const STATE_ACTIVE := &"active"
const STATE_STAGGERED := &"staggered"
const STATE_DEFEATED := &"defeated"

var id: StringName
var max_health: int
var health: int
var phase_two_health: int
var phase: int = BossPatternDefinition.PHASE_ONE
var stagger_capacity: int
var stagger_meter: int
var stagger_duration: float
var stagger_time_remaining: float
var state: StringName = STATE_DORMANT
var _configured: bool


func configure(
	p_id: StringName,
	p_max_health: int,
	p_phase_two_health: int,
	p_stagger_capacity: int,
	p_stagger_duration: float
) -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Boss ID", p_id)
	if p_max_health <= 0:
		errors.append("Boss '%s' needs positive maximum health." % p_id)
	if p_phase_two_health <= 0 or p_phase_two_health >= p_max_health:
		errors.append("Boss '%s' phase-two health must be inside its health range." % p_id)
	if p_stagger_capacity <= 0:
		errors.append("Boss '%s' needs a positive stagger capacity." % p_id)
	if not is_finite(p_stagger_duration) or p_stagger_duration <= 0.0:
		errors.append("Boss '%s' needs a positive finite stagger duration." % p_id)
	if not errors.is_empty():
		return errors
	id = p_id
	max_health = p_max_health
	phase_two_health = p_phase_two_health
	stagger_capacity = p_stagger_capacity
	stagger_duration = p_stagger_duration
	_configured = true
	reset()
	return errors


func activate() -> bool:
	if not _configured or state != STATE_DORMANT:
		return false
	state = STATE_ACTIVE
	return true


func apply_hit(damage: int, stagger_damage: int) -> Dictionary:
	var result := _hit_result(false)
	if (
		not _configured
		or state == STATE_DORMANT
		or state == STATE_DEFEATED
		or damage < 0
		or stagger_damage < 0
	):
		return result
	result["accepted"] = true
	health = maxi(health - damage, 0)
	var previous_phase := phase
	if health <= phase_two_health:
		phase = BossPatternDefinition.PHASE_TWO
	result["phase_changed"] = phase != previous_phase

	if health == 0:
		state = STATE_DEFEATED
		stagger_meter = 0
		stagger_time_remaining = 0.0
		result["defeated"] = true
	elif state != STATE_STAGGERED and stagger_damage > 0:
		stagger_meter = mini(stagger_meter + stagger_damage, stagger_capacity)
		if stagger_meter >= stagger_capacity:
			stagger_meter = 0
			stagger_time_remaining = stagger_duration
			state = STATE_STAGGERED
			result["staggered"] = true
			# Pattern execution owns cancellation; the health contract only publishes the fact.
			result["cancel_queued_chain"] = true
	result["health"] = health
	result["phase"] = phase
	result["state"] = state
	return result


func advance_time(delta: float) -> bool:
	if state != STATE_STAGGERED or not is_finite(delta) or delta < 0.0:
		return false
	stagger_time_remaining = maxf(stagger_time_remaining - delta, 0.0)
	if is_zero_approx(stagger_time_remaining):
		stagger_time_remaining = 0.0
		state = STATE_ACTIVE
		return true
	return false


func reset() -> void:
	if not _configured:
		return
	health = max_health
	phase = BossPatternDefinition.PHASE_ONE
	stagger_meter = 0
	stagger_time_remaining = 0.0
	state = STATE_DORMANT


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if not _configured:
		errors.append("Boss contract is not configured.")
		return errors
	ContentId.validate(errors, "Boss ID", id)
	if max_health <= 0 or phase_two_health <= 0 or phase_two_health >= max_health:
		errors.append("Boss '%s' has an invalid health or phase threshold contract." % id)
	if stagger_capacity <= 0 or not is_finite(stagger_duration) or stagger_duration <= 0.0:
		errors.append("Boss '%s' has an invalid stagger contract." % id)
	return errors


func snapshot() -> Dictionary:
	return {
		"id": id,
		"max_health": max_health,
		"health": health,
		"phase_two_health": phase_two_health,
		"phase": phase,
		"stagger_capacity": stagger_capacity,
		"stagger_meter": stagger_meter,
		"stagger_duration": stagger_duration,
		"stagger_time_remaining": stagger_time_remaining,
		"state": state,
	}


func _hit_result(accepted: bool) -> Dictionary:
	return {
		"accepted": accepted,
		"health": health,
		"phase": phase,
		"state": state,
		"phase_changed": false,
		"staggered": false,
		"cancel_queued_chain": false,
		"defeated": false,
	}
