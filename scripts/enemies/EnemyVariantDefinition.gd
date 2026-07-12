class_name EnemyVariantDefinition
extends Resource

const NORMAL_DAMAGE := 1
const MINIMUM_BUDGET_COST := 1
const MAXIMUM_BUDGET_COST := 7

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []

@export_group("Catalog References")
@export var archetype_id: StringName
@export var stage_id: StringName
@export var tuning_profile_id: StringName

@export_group("Exact Combat Values")
@export var health: int = 1
@export var damage: int = NORMAL_DAMAGE
@export var move_speed: float = 0.0
@export var warning_time: float = 0.0
@export var active_time: float = 0.0
@export var recovery_time: float = 0.0
@export var charge_speed: float = 0.0
@export var cadence_time: float = 0.0
@export var projectile_speed: float = 0.0
@export var attack_range: float = 0.0
@export var active_projectile_cap: int = 0
@export var stagger_capacity: int = 1

@export_group("Encounter And Presentation")
@export var presentation_key: StringName
@export_multiline var presentation_description: String
@export var tuning_trait: StringName
@export var budget_cost: int = MINIMUM_BUDGET_COST
@export var drop_source_id: StringName


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Enemy variant ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Enemy variant '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Enemy variant '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Enemy variant '%s' tag" % id, tags, true)

	ContentId.validate(errors, "Enemy variant '%s' archetype ID" % id, archetype_id)
	ContentId.validate(errors, "Enemy variant '%s' stage ID" % id, stage_id)
	ContentId.validate(
		errors, "Enemy variant '%s' tuning profile ID" % id, tuning_profile_id
	)

	if health <= 0:
		errors.append("Enemy variant '%s' needs positive exact health." % id)
	if damage != NORMAL_DAMAGE:
		errors.append("Enemy variant '%s' exact damage must be the integer %d." % [id, NORMAL_DAMAGE])
	if stagger_capacity <= 0:
		errors.append("Enemy variant '%s' needs positive exact stagger capacity." % id)
	_validate_nonnegative_float(errors, "exact move speed", move_speed)
	_validate_nonnegative_float(errors, "exact warning time", warning_time)
	_validate_nonnegative_float(errors, "exact active time", active_time)
	_validate_nonnegative_float(errors, "exact recovery time", recovery_time)
	_validate_nonnegative_float(errors, "exact charge speed", charge_speed)
	_validate_nonnegative_float(errors, "exact cadence time", cadence_time)
	_validate_nonnegative_float(errors, "exact projectile speed", projectile_speed)
	_validate_nonnegative_float(errors, "exact attack range", attack_range)
	if active_projectile_cap < 0:
		errors.append("Enemy variant '%s' projectile cap cannot be negative." % id)

	var presentation := String(presentation_key)
	var presentation_segments := presentation.split(".", true)
	if (
		presentation.strip_edges().is_empty()
		or presentation != presentation.strip_edges()
		or presentation_segments.size() < 3
		or presentation_segments[0] != "enemy"
	):
		errors.append("Enemy variant '%s' needs a namespaced enemy presentation key." % id)
	else:
		for segment in presentation_segments:
			if not ContentId.is_valid(segment):
				errors.append(
					"Enemy variant '%s' presentation key segment '%s' is invalid."
					% [id, segment]
				)
	if presentation_description.strip_edges().is_empty():
		errors.append("Enemy variant '%s' needs a presentation description." % id)
	ContentId.validate(errors, "Enemy variant '%s' tuning trait" % id, tuning_trait)
	if budget_cost < MINIMUM_BUDGET_COST or budget_cost > MAXIMUM_BUDGET_COST:
		errors.append(
			"Enemy variant '%s' budget must be between %d and %d."
			% [id, MINIMUM_BUDGET_COST, MAXIMUM_BUDGET_COST]
		)
	ContentId.validate(errors, "Enemy variant '%s' drop source ID" % id, drop_source_id)

	return errors


func exact_stats() -> Dictionary:
	return {
		"health": health,
		"damage": damage,
		"move_speed": move_speed,
		"warning": warning_time,
		"active": active_time,
		"recovery": recovery_time,
		"charge_speed": charge_speed,
		"cadence": cadence_time,
		"projectile_speed": projectile_speed,
		"attack_range": attack_range,
		"active_projectile_cap": active_projectile_cap,
		"stagger_capacity": stagger_capacity,
	}


func _validate_nonnegative_float(errors: PackedStringArray, label: String, value: float) -> void:
	if not is_finite(value) or value < 0.0:
		errors.append("Enemy variant '%s' %s must be finite and non-negative." % [id, label])
