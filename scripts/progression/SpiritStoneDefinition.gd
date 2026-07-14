class_name SpiritStoneDefinition
extends Resource

const TRIGGER_DIRECT_ATTACK_SEQUENCE := &"direct_attack_sequence"
const TRIGGER_PRECISE_GUARD := &"precise_guard"
const TRIGGERS: Array[StringName] = [
	TRIGGER_DIRECT_ATTACK_SEQUENCE,
	TRIGGER_PRECISE_GUARD,
]
const EFFECT_BURN := &"burn"
const EFFECT_SLOW := &"slow"
const EFFECTS: Array[StringName] = [EFFECT_BURN, EFFECT_SLOW]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var presentation_key: StringName
@export_multiline var passive_description: String
@export_multiline var weakness_description: String
@export var trigger: StringName
@export var effect: StringName
@export var deduplicate_by_event_id: bool = true

@export_group("Direct Attack Sequence")
@export var required_direct_attack_count: int = 0
@export var direct_attack_window_seconds: float = 0.0
@export var burn_damage_per_tick: int = 0
@export var burn_tick_count: int = 0

@export_group("Precise Guard Slow")
@export var slow_fraction: float = 0.0
@export var slow_duration_seconds: float = 0.0


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Spirit Stone ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Spirit Stone '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Spirit Stone '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Spirit Stone '%s' tag" % id, tags, true)
	ContentId.validate(errors, "Spirit Stone '%s' presentation key" % id, presentation_key)
	if not tags.has(&"spirit_stone") or not tags.has(&"passive"):
		errors.append("Spirit Stone '%s' needs spirit_stone and passive tags." % id)
	if passive_description.strip_edges().is_empty() or weakness_description.strip_edges().is_empty():
		errors.append("Spirit Stone '%s' needs a passive description and explicit weakness." % id)
	if trigger not in TRIGGERS:
		errors.append("Spirit Stone '%s' has unsupported trigger '%s'." % [id, trigger])
	if effect not in EFFECTS:
		errors.append("Spirit Stone '%s' has unsupported effect '%s'." % [id, effect])
	if not deduplicate_by_event_id:
		errors.append("Spirit Stone '%s' must deduplicate combat events by event ID." % id)
	for value in [direct_attack_window_seconds, slow_fraction, slow_duration_seconds]:
		if not is_finite(value) or value < 0.0:
			errors.append("Spirit Stone '%s' has a non-finite or negative passive value." % id)
			break

	match trigger:
		TRIGGER_DIRECT_ATTACK_SEQUENCE:
			_validate_direct_attack_passive(errors)
		TRIGGER_PRECISE_GUARD:
			_validate_precise_guard_passive(errors)
	return errors


func _validate_direct_attack_passive(errors: PackedStringArray) -> void:
	if effect != EFFECT_BURN:
		errors.append("Direct-attack Spirit Stone '%s' must use the burn effect." % id)
	if required_direct_attack_count <= 1 or direct_attack_window_seconds <= 0.0:
		errors.append("Direct-attack Spirit Stone '%s' needs a timed multi-hit condition." % id)
	if burn_damage_per_tick <= 0 or burn_tick_count <= 0:
		errors.append("Direct-attack Spirit Stone '%s' needs positive burn damage and ticks." % id)
	if not is_zero_approx(slow_fraction) or not is_zero_approx(slow_duration_seconds):
		errors.append("Direct-attack Spirit Stone '%s' cannot contain slow tuning." % id)


func _validate_precise_guard_passive(errors: PackedStringArray) -> void:
	if effect != EFFECT_SLOW:
		errors.append("Precise-guard Spirit Stone '%s' must use the slow effect." % id)
	if (
		required_direct_attack_count != 0
		or not is_zero_approx(direct_attack_window_seconds)
		or burn_damage_per_tick != 0
		or burn_tick_count != 0
	):
		errors.append("Precise-guard Spirit Stone '%s' cannot contain attack-sequence tuning." % id)
	if slow_fraction <= 0.0 or slow_fraction >= 1.0 or slow_duration_seconds <= 0.0:
		errors.append("Precise-guard Spirit Stone '%s' needs a bounded slow and positive duration." % id)
