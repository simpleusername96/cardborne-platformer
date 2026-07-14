class_name DefenseResolver
extends RefCounted

const DefenseResultValue = preload("res://scripts/player/DefenseResult.gd")

const PHASE_IDLE := &"idle"
const PHASE_STARTUP := &"startup"
const PHASE_ACTIVE := &"active"
const PHASE_RECOVERY := &"recovery"

const ATTACK_NORMAL := &"normal"
const ATTACK_HEAVY := &"heavy"
const ATTACK_UNBLOCKABLE := &"unblockable"

const REASON_BLOCKED := &"blocked"
const REASON_PRECISE_BLOCK := &"precise_block"
const REASON_NOT_GUARDING := &"not_guarding"
const REASON_STARTUP := &"guard_startup"
const REASON_RECOVERY := &"guard_recovery"
const REASON_OUTSIDE_ANGLE := &"outside_guard_angle"
const REASON_UNBLOCKABLE := &"unblockable"
const REASON_GUARD_BROKEN := &"guard_broken"

const EPSILON := 0.0001


## Returns costs and tags only; applying condition, stability, or health changes is a caller concern.
static func resolve(
	attack_snapshot: Dictionary,
	shield_snapshot: Dictionary,
	facing: Vector2,
	timing: Dictionary
) -> DefenseResultValue:
	var phase := _resolve_phase(shield_snapshot, timing)
	var attack_kind := _attack_kind(attack_snapshot)
	var tags: Array[StringName] = [&"defense", StringName("defense_%s" % phase)]
	if attack_kind == ATTACK_HEAVY:
		tags.append(&"heavy")
	elif attack_kind == ATTACK_UNBLOCKABLE:
		tags.append(&"unblockable")
	else:
		tags.append(&"normal")

	if phase != PHASE_ACTIVE:
		var phase_reason := REASON_NOT_GUARDING
		if phase == PHASE_STARTUP:
			phase_reason = REASON_STARTUP
		elif phase == PHASE_RECOVERY:
			phase_reason = REASON_RECOVERY
		return DefenseResultValue.new(false, false, phase, 0, 0, false, phase_reason, tags)
	if attack_kind == ATTACK_UNBLOCKABLE:
		return DefenseResultValue.new(
			false, false, phase, 0, 0, false, REASON_UNBLOCKABLE, tags
		)
	if not _is_inside_guard_angle(attack_snapshot, shield_snapshot, facing):
		tags.append(&"outside_guard_angle")
		return DefenseResultValue.new(
			false, false, phase, 0, 0, false, REASON_OUTSIDE_ANGLE, tags
		)

	var condition := maxi(int(shield_snapshot.get("condition", 0)), 0)
	if condition <= 0:
		# Worn equipment stays usable. Its stat penalties belong in the snapshot builder.
		tags.append(&"worn")

	var precise_window := _is_precise_window(shield_snapshot, timing)
	var stability_cost := _stability_cost(attack_snapshot, shield_snapshot, attack_kind)
	var condition_cost := _condition_cost(attack_snapshot, shield_snapshot, attack_kind)
	if precise_window:
		stability_cost = _scaled_cost(
			stability_cost,
			float(shield_snapshot.get("precise_stability_cost_scale", 1.0))
		)
		condition_cost = _scaled_cost(
			condition_cost,
			float(shield_snapshot.get("precise_condition_cost_scale", 0.0))
		)

	var stability := maxi(int(shield_snapshot.get("stability", 0)), 0)
	var breaks_guard := stability <= 0 or (stability_cost > 0 and stability_cost >= stability)
	var applied_stability_cost := mini(stability_cost, stability)
	var applied_condition_cost := mini(condition_cost, condition)
	if breaks_guard:
		tags.append(&"guard_break")
		return DefenseResultValue.new(
			false,
			false,
			phase,
			applied_condition_cost,
			applied_stability_cost,
			true,
			REASON_GUARD_BROKEN,
			tags
		)

	tags.append(&"blocked")
	if precise_window:
		tags.append(&"precise")
	return DefenseResultValue.new(
		true,
		precise_window,
		phase,
		applied_condition_cost,
		applied_stability_cost,
		false,
		REASON_PRECISE_BLOCK if precise_window else REASON_BLOCKED,
		tags
	)


static func _resolve_phase(shield: Dictionary, timing: Dictionary) -> StringName:
	if timing.has("phase"):
		var explicit_phase := StringName(str(timing.get("phase", PHASE_IDLE)))
		if explicit_phase in [PHASE_IDLE, PHASE_STARTUP, PHASE_ACTIVE, PHASE_RECOVERY]:
			return explicit_phase
	var guard_held := bool(timing.get("guard_held", false))
	if guard_held:
		var guard_elapsed := maxf(
			float(timing.get("guard_elapsed", timing.get("held_elapsed", 0.0))), 0.0
		)
		var startup_time := maxf(float(shield.get("startup_time", 0.0)), 0.0)
		return PHASE_ACTIVE if guard_elapsed + EPSILON >= startup_time else PHASE_STARTUP
	var recovery_time := maxf(float(shield.get("recovery_time", 0.0)), 0.0)
	var release_elapsed := float(timing.get("release_elapsed", INF))
	if bool(timing.get("recovering", false)) or (
		release_elapsed >= 0.0 and release_elapsed < recovery_time - EPSILON
	):
		return PHASE_RECOVERY
	return PHASE_IDLE


static func _is_precise_window(shield: Dictionary, timing: Dictionary) -> bool:
	var precise_window := maxf(float(shield.get("precise_window", 0.0)), 0.0)
	if precise_window <= 0.0:
		return false
	var active_elapsed: float
	if timing.has("phase_elapsed") and StringName(str(timing.get("phase", &""))) == PHASE_ACTIVE:
		active_elapsed = maxf(float(timing.get("phase_elapsed", 0.0)), 0.0)
	else:
		var guard_elapsed := maxf(
			float(timing.get("guard_elapsed", timing.get("held_elapsed", 0.0))), 0.0
		)
		active_elapsed = guard_elapsed - maxf(float(shield.get("startup_time", 0.0)), 0.0)
	return active_elapsed >= -EPSILON and active_elapsed <= precise_window + EPSILON


static func _is_inside_guard_angle(
	attack: Dictionary,
	shield: Dictionary,
	facing: Vector2
) -> bool:
	var source_direction := _source_direction(attack)
	if source_direction.is_zero_approx():
		return false
	var guard_facing := facing.normalized() if not facing.is_zero_approx() else Vector2.RIGHT
	var angle_degrees := clampf(float(shield.get("guard_angle_degrees", 0.0)), 0.0, 360.0)
	if angle_degrees >= 360.0 - EPSILON:
		return true
	var threshold := cos(deg_to_rad(angle_degrees * 0.5))
	return guard_facing.dot(source_direction.normalized()) >= threshold - EPSILON


static func _source_direction(attack: Dictionary) -> Vector2:
	var explicit: Variant = attack.get("source_direction", null)
	if explicit is Vector2:
		return explicit
	var source: Variant = attack.get("source_position", null)
	var defender: Variant = attack.get("defender_position", null)
	if source is Vector2 and defender is Vector2:
		return (source as Vector2) - (defender as Vector2)
	var travel_direction: Variant = attack.get("direction", null)
	if travel_direction is Vector2:
		return -(travel_direction as Vector2)
	return Vector2.ZERO


static func _attack_kind(attack: Dictionary) -> StringName:
	if not bool(attack.get("blockable", true)) or bool(attack.get("unblockable", false)):
		return ATTACK_UNBLOCKABLE
	var tags: Variant = attack.get("tags", [])
	if tags is Array or tags is PackedStringArray:
		for tag in tags:
			if StringName(str(tag)) == ATTACK_UNBLOCKABLE:
				return ATTACK_UNBLOCKABLE
			if StringName(str(tag)) == ATTACK_HEAVY:
				return ATTACK_HEAVY
	var declared := StringName(str(attack.get("attack_type", attack.get("kind", ATTACK_NORMAL))))
	if declared == ATTACK_UNBLOCKABLE:
		return ATTACK_UNBLOCKABLE
	if declared == ATTACK_HEAVY:
		return ATTACK_HEAVY
	return ATTACK_NORMAL


static func _stability_cost(
	attack: Dictionary,
	shield: Dictionary,
	attack_kind: StringName
) -> int:
	if attack.has("stability_cost"):
		return maxi(int(attack.get("stability_cost", 0)), 0)
	if attack.has("posture_cost"):
		return maxi(int(attack.get("posture_cost", 0)), 0)
	var key := "heavy_stability_cost" if attack_kind == ATTACK_HEAVY else "normal_stability_cost"
	return maxi(int(shield.get(key, 0)), 0)


static func _condition_cost(
	attack: Dictionary,
	shield: Dictionary,
	attack_kind: StringName
) -> int:
	if attack.has("condition_cost"):
		return maxi(int(attack.get("condition_cost", 0)), 0)
	var key := "heavy_condition_cost" if attack_kind == ATTACK_HEAVY else "normal_condition_cost"
	return maxi(int(shield.get(key, 0)), 0)


static func _scaled_cost(cost: int, scale: float) -> int:
	if not is_finite(scale) or scale < 0.0:
		return cost
	return maxi(int(ceil(float(cost) * scale - EPSILON)), 0)
