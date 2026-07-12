class_name EnemyArchetypeDefinition
extends Resource

const NORMAL_DAMAGE := 1
const FLOAT_TOLERANCE := 0.0001

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []

@export_group("Behavior Contract")
@export var behavior_owner: StringName
@export var pressure_roles: Array[StringName] = []
@export_multiline var tell_contract: String
@export_multiline var response_contract: String
@export_multiline var punish_contract: String

@export_group("Reference Combat Values")
@export var reference_health: int = 1
@export var reference_damage: int = NORMAL_DAMAGE
@export var reference_move_speed: float = 0.0
@export var reference_warning_time: float = 0.0
@export var reference_active_time: float = 0.0
@export var reference_recovery_time: float = 0.0
@export var reference_charge_speed: float = 0.0
@export var reference_cadence_time: float = 0.0
@export var reference_projectile_speed: float = 0.0
@export var reference_attack_range: float = 0.0
@export var reference_active_projectile_cap: int = 0
@export var reference_stagger_capacity: int = 1

@export_group("Room Requirements")
@export var minimum_support_width: float = 0.0
@export var minimum_lane_width: float = 0.0
@export var minimum_arc_clearance: float = 0.0
@export var requires_patrol_turn_points: bool = false
@export var requires_escape_route: bool = false
@export var allows_wall_stop_lane: bool = false
@export var room_requirement_tags: Array[StringName] = []

@export_group("Safety Bounds")
@export var minimum_warning_time: float = 0.0
@export var minimum_recovery_time: float = 0.0
@export var minimum_cadence_time: float = 0.0
@export var maximum_active_projectile_cap: int = 0
@export var maximum_damage: int = NORMAL_DAMAGE


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Enemy archetype ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Enemy archetype '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Enemy archetype '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Enemy archetype '%s' tag" % id, tags, true)

	if String(behavior_owner).strip_edges().is_empty():
		errors.append("Enemy archetype '%s' needs a behavior owner." % id)
	ContentId.validate_list(
		errors, "Enemy archetype '%s' pressure role" % id, pressure_roles, true
	)
	if tell_contract.strip_edges().is_empty():
		errors.append("Enemy archetype '%s' needs a tell contract." % id)
	if response_contract.strip_edges().is_empty():
		errors.append("Enemy archetype '%s' needs a response contract." % id)
	if punish_contract.strip_edges().is_empty():
		errors.append("Enemy archetype '%s' needs a punish contract." % id)

	if reference_health <= 0:
		errors.append("Enemy archetype '%s' needs positive reference health." % id)
	if reference_damage != NORMAL_DAMAGE:
		errors.append("Enemy archetype '%s' reference damage must be exactly %d." % [id, NORMAL_DAMAGE])
	if reference_stagger_capacity <= 0:
		errors.append("Enemy archetype '%s' needs positive reference stagger capacity." % id)
	_validate_nonnegative_float(errors, "reference move speed", reference_move_speed)
	_validate_nonnegative_float(errors, "reference warning time", reference_warning_time)
	_validate_nonnegative_float(errors, "reference active time", reference_active_time)
	_validate_nonnegative_float(errors, "reference recovery time", reference_recovery_time)
	_validate_nonnegative_float(errors, "reference charge speed", reference_charge_speed)
	_validate_nonnegative_float(errors, "reference cadence time", reference_cadence_time)
	_validate_nonnegative_float(errors, "reference projectile speed", reference_projectile_speed)
	_validate_nonnegative_float(errors, "reference attack range", reference_attack_range)
	if reference_active_projectile_cap < 0:
		errors.append("Enemy archetype '%s' reference projectile cap cannot be negative." % id)

	_validate_nonnegative_float(errors, "minimum support width", minimum_support_width)
	_validate_nonnegative_float(errors, "minimum lane width", minimum_lane_width)
	_validate_nonnegative_float(errors, "minimum arc clearance", minimum_arc_clearance)
	ContentId.validate_list(
		errors,
		"Enemy archetype '%s' room requirement" % id,
		room_requirement_tags,
		false
	)
	if not _has_room_requirement():
		errors.append("Enemy archetype '%s' needs at least one room requirement." % id)

	_validate_nonnegative_float(errors, "minimum warning time", minimum_warning_time)
	_validate_nonnegative_float(errors, "minimum recovery time", minimum_recovery_time)
	_validate_nonnegative_float(errors, "minimum cadence time", minimum_cadence_time)
	if maximum_active_projectile_cap < 0:
		errors.append("Enemy archetype '%s' projectile cap ceiling cannot be negative." % id)
	if maximum_damage != NORMAL_DAMAGE:
		errors.append("Enemy archetype '%s' maximum damage must be exactly %d." % [id, NORMAL_DAMAGE])
	if reference_damage > maximum_damage:
		errors.append("Enemy archetype '%s' reference damage exceeds its safety ceiling." % id)
	if minimum_warning_time > reference_warning_time + FLOAT_TOLERANCE:
		errors.append("Enemy archetype '%s' reference warning is below its safety floor." % id)
	if minimum_recovery_time > reference_recovery_time + FLOAT_TOLERANCE:
		errors.append("Enemy archetype '%s' reference recovery is below its safety floor." % id)
	if minimum_cadence_time > reference_cadence_time + FLOAT_TOLERANCE:
		errors.append("Enemy archetype '%s' reference cadence is below its safety floor." % id)
	if reference_active_projectile_cap > maximum_active_projectile_cap:
		errors.append("Enemy archetype '%s' reference projectile cap exceeds its ceiling." % id)

	return errors


func reference_stats() -> Dictionary:
	return {
		"health": reference_health,
		"damage": reference_damage,
		"move_speed": reference_move_speed,
		"warning": reference_warning_time,
		"active": reference_active_time,
		"recovery": reference_recovery_time,
		"charge_speed": reference_charge_speed,
		"cadence": reference_cadence_time,
		"projectile_speed": reference_projectile_speed,
		"attack_range": reference_attack_range,
		"active_projectile_cap": reference_active_projectile_cap,
		"stagger_capacity": reference_stagger_capacity,
	}


func room_requirements() -> Dictionary:
	return {
		"minimum_support_width": minimum_support_width,
		"minimum_lane_width": minimum_lane_width,
		"minimum_arc_clearance": minimum_arc_clearance,
		"requires_patrol_turn_points": requires_patrol_turn_points,
		"requires_escape_route": requires_escape_route,
		"allows_wall_stop_lane": allows_wall_stop_lane,
		"tags": room_requirement_tags.duplicate(),
	}


func safety_bounds() -> Dictionary:
	return {
		"minimum_warning_time": minimum_warning_time,
		"minimum_recovery_time": minimum_recovery_time,
		"minimum_cadence_time": minimum_cadence_time,
		"maximum_active_projectile_cap": maximum_active_projectile_cap,
		"maximum_damage": maximum_damage,
	}


func _has_room_requirement() -> bool:
	return (
		minimum_support_width > 0.0
		or minimum_lane_width > 0.0
		or minimum_arc_clearance > 0.0
		or requires_patrol_turn_points
		or requires_escape_route
		or allows_wall_stop_lane
		or not room_requirement_tags.is_empty()
	)


func _validate_nonnegative_float(errors: PackedStringArray, label: String, value: float) -> void:
	if not is_finite(value) or value < 0.0:
		errors.append("Enemy archetype '%s' %s must be finite and non-negative." % [id, label])
