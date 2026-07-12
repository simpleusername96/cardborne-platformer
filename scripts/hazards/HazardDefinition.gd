class_name HazardDefinition
extends Resource

const KIND_STATIC_DAMAGE := &"static_damage"
const KIND_TIMED_DAMAGE := &"timed_damage"
const KIND_RESET := &"reset"
const KIND_CRUMBLING_PLATFORM := &"crumbling_platform"
const RUNTIME_KINDS: Array[StringName] = [
	KIND_STATIC_DAMAGE,
	KIND_TIMED_DAMAGE,
	KIND_RESET,
	KIND_CRUMBLING_PLATFORM,
]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var scene: PackedScene
@export var budget_cost: int = 0
@export var placement_tags: Array[StringName] = []

@export_group("Runtime Contract")
@export var runtime_kind: StringName
@export var runtime_owner: StringName
@export var damage_amount: int = 0
@export var warning_time: float = 0.0
@export var active_time: float = 0.0
@export var cooldown_time: float = 0.0
@export var tick_interval: float = 0.0
@export var disabled_time: float = 0.0
@export var respawn_time: float = 0.0

@export_group("Runtime Semantics")
@export var is_damaging: bool = false
@export var is_static: bool = true
@export var is_reset: bool = false
@export var active_cap: int = 1

@export_group("Placement Safety")
@export var requires_visible_approach: bool = false
@export var requires_permanent_safe_zone: bool = false
@export var requires_recovery_anchor: bool = false
@export var requires_wait_pads_and_recovery: bool = false


func supports_placement(required_tags: Array[StringName]) -> bool:
	for required_tag in required_tags:
		if required_tag not in placement_tags:
			return false
	return true


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Hazard definition ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Hazard definition '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Hazard definition '%s' needs a positive content version." % id)
	if scene == null or not scene.can_instantiate():
		errors.append("Hazard definition '%s' needs an instantiable scene." % id)
	if budget_cost < 0:
		errors.append("Hazard definition '%s' budget cost cannot be negative." % id)
	ContentId.validate_list(
		errors,
		"Hazard definition '%s' placement tag" % id,
		placement_tags,
		true
	)
	if runtime_kind not in RUNTIME_KINDS:
		errors.append("Hazard definition '%s' has an unsupported runtime kind." % id)
	if String(runtime_owner).strip_edges().is_empty():
		errors.append("Hazard definition '%s' needs a runtime owner." % id)
	if damage_amount < 0 or damage_amount > 1:
		errors.append("Hazard definition '%s' damage must be zero or one." % id)
	if is_damaging != (damage_amount == 1):
		errors.append("Hazard definition '%s' damage semantics do not match its exact damage." % id)
	if is_damaging and is_reset:
		errors.append("Hazard definition '%s' cannot both damage and reset." % id)
	if active_cap <= 0:
		errors.append("Hazard definition '%s' needs a positive active cap." % id)
	_validate_nonnegative_times(errors)
	_validate_runtime_kind(errors)
	return errors


func timing_contract() -> Dictionary:
	return {
		"warning": warning_time,
		"active": active_time,
		"cooldown": cooldown_time,
		"tick_interval": tick_interval,
		"disabled": disabled_time,
		"respawn": respawn_time,
	}


func safety_contract() -> Dictionary:
	return {
		"requires_visible_approach": requires_visible_approach,
		"requires_permanent_safe_zone": requires_permanent_safe_zone,
		"requires_recovery_anchor": requires_recovery_anchor,
		"requires_wait_pads_and_recovery": requires_wait_pads_and_recovery,
	}


func _validate_runtime_kind(errors: PackedStringArray) -> void:
	match runtime_kind:
		KIND_STATIC_DAMAGE:
			if not is_damaging or not is_static or not requires_visible_approach:
				errors.append("Static damage hazard '%s' needs visible, static damage semantics." % id)
		KIND_TIMED_DAMAGE:
			if not is_damaging or is_static or is_reset:
				errors.append("Timed damage hazard '%s' needs dynamic damage semantics." % id)
			if warning_time <= 0.0 or active_time <= 0.0 or cooldown_time <= 0.0:
				errors.append("Timed damage hazard '%s' needs positive warning, active, and cooldown times." % id)
			if tick_interval <= 0.0 or tick_interval > active_time:
				errors.append("Timed damage hazard '%s' has an invalid tick interval." % id)
			if not requires_permanent_safe_zone:
				errors.append("Timed damage hazard '%s' needs a permanent safe-zone contract." % id)
		KIND_RESET:
			if is_damaging or not is_static or not is_reset or not requires_recovery_anchor:
				errors.append("Reset hazard '%s' needs non-damaging recovery semantics." % id)
		KIND_CRUMBLING_PLATFORM:
			if is_damaging or is_static or is_reset:
				errors.append("Crumbling hazard '%s' needs dynamic non-damaging semantics." % id)
			if warning_time <= 0.0 or disabled_time <= 0.0 or respawn_time <= 0.0:
				errors.append("Crumbling hazard '%s' needs positive warning, disabled, and respawn times." % id)
			if not requires_wait_pads_and_recovery:
				errors.append("Crumbling hazard '%s' needs wait-pad and recovery contracts." % id)


func _validate_nonnegative_times(errors: PackedStringArray) -> void:
	for timing in [warning_time, active_time, cooldown_time, tick_interval, disabled_time, respawn_time]:
		if not is_finite(timing) or timing < 0.0:
			errors.append("Hazard definition '%s' has an invalid timing value." % id)
			return
