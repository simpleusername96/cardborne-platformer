class_name AttackDefinition
extends Resource

const HIT_POLICY_ONCE := &"once_per_activation"

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var input_action: StringName = &"attack"
@export var tags: Array[StringName] = []

@export_group("Timing")
@export_range(0.0, 10.0, 0.01) var startup_time: float = 0.1
@export_range(0.0, 10.0, 0.01) var active_time: float = 0.1
@export_range(0.0, 10.0, 0.01) var recovery_time: float = 0.2
@export_range(0.01, 60.0, 0.01) var cooldown: float = 0.4
@export var movement_lock_delay: float = -1.0

@export_group("Hit")
@export_range(0, 999, 1) var base_damage: int = 1
@export_range(0, 999, 1) var stagger: int = 0
@export var knockback: Vector2 = Vector2(160.0, -80.0)
@export var hitbox_size: Vector2 = Vector2(38.0, 30.0)
@export var hitbox_offset: Vector2 = Vector2(30.0, -26.0)
@export var hit_policy: StringName = HIT_POLICY_ONCE
@export var critical_rule: CriticalRule

@export_group("Projectile")
@export_range(0.0, 2000.0, 1.0) var projectile_speed: float = 0.0
@export_range(0.0, 3000.0, 1.0) var projectile_range: float = 0.0
@export_range(1, 16, 1) var projectile_target_cap: int = 1

@export_group("Charge")
@export var charge_time_range: Vector2 = Vector2.ZERO
@export_range(0, 999, 1) var maximum_charge_damage: int = 0
@export var cooldown_from_release: bool = false

@export_group("Sequence")
@export var sequence_step_timings: Array[Vector3] = []
@export var sequence_requires_hold: bool = false

@export_group("Presentation")
@export var motion_style: StringName = &"quick_slash"
@export var visual_color: Color = Color(1.0, 0.86, 0.22, 1.0)


func total_duration() -> float:
	return startup_time + active_time + recovery_time


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty():
		errors.append("Attack ID cannot be blank.")
	if display_name.strip_edges().is_empty():
		errors.append("Attack '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Attack '%s' needs a positive content version." % id)
	if String(input_action).strip_edges().is_empty():
		errors.append("Attack '%s' needs an input action." % id)
	if active_time < 0.0 or cooldown <= 0.0:
		errors.append("Attack '%s' needs non-negative active and positive cooldown timing." % id)
	if is_zero_approx(active_time) and not tags.has(&"instant"):
		errors.append("Attack '%s' needs positive active timing unless tagged instant." % id)
	if cooldown + 0.0001 < total_duration():
		errors.append("Attack '%s' cooldown cannot be shorter than its action cycle." % id)
	if base_damage < 0 or stagger < 0:
		errors.append("Attack '%s' damage and stagger cannot be negative." % id)
	if hitbox_size.x <= 0.0 or hitbox_size.y <= 0.0:
		errors.append("Attack '%s' needs a positive hitbox size." % id)
	if hit_policy != HIT_POLICY_ONCE:
		errors.append("Attack '%s' uses unsupported hit policy '%s'." % [id, hit_policy])
	var has_projectile_contract := projectile_speed > 0.0 or projectile_range > 0.0
	if has_projectile_contract and (projectile_speed <= 0.0 or projectile_range <= 0.0):
		errors.append("Attack '%s' projectile needs positive speed and range." % id)
	if charge_time_range != Vector2.ZERO:
		if (
			charge_time_range.x <= 0.0
			or charge_time_range.y < charge_time_range.x
			or maximum_charge_damage < base_damage
			or not cooldown_from_release
		):
			errors.append("Attack '%s' has an invalid charge contract." % id)
	elif maximum_charge_damage != 0 or cooldown_from_release:
		errors.append("Attack '%s' cannot define charged output without charge timing." % id)
	if not sequence_step_timings.is_empty():
		if sequence_step_timings.size() < 2:
			errors.append("Attack '%s' sequence needs at least two steps." % id)
		var sequence_duration := 0.0
		for timing in sequence_step_timings:
			if timing.x < 0.0 or timing.y <= 0.0 or timing.z < 0.0:
				errors.append("Attack '%s' sequence has invalid phase timing." % id)
				break
			sequence_duration += timing.x + timing.y + timing.z
		if not is_equal_approx(sequence_duration, total_duration()):
			errors.append("Attack '%s' sequence timing must match its total action cycle." % id)
	elif sequence_requires_hold:
		errors.append("Attack '%s' cannot require a held sequence without steps." % id)
	if critical_rule != null:
		for error in critical_rule.validate_definition():
			errors.append("Attack '%s': %s" % [id, error])
	return errors
