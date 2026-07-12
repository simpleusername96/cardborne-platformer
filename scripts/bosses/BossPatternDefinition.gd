class_name BossPatternDefinition
extends Resource

const PHASE_ONE := 1
const PHASE_TWO := 2
const SUPPORTED_PHASES: Array[int] = [PHASE_ONE, PHASE_TWO]
const ACTIVE_TIMED_DAMAGE := &"timed_damage_window"
const ACTIVE_PERSISTENT_ZONE := &"persistent_zone_window"
const ACTIVE_SUMMON_ACTIVATION := &"summon_activation"
const ACTIVE_SEMANTICS: Array[StringName] = [
	ACTIVE_TIMED_DAMAGE,
	ACTIVE_PERSISTENT_ZONE,
	ACTIVE_SUMMON_ACTIVATION,
]
const FLOAT_TOLERANCE := 0.0001

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var presentation_key: StringName
@export var eligible_phases: Array[int] = [PHASE_ONE, PHASE_TWO]

@export_group("Timing")
@export_range(0.0, 10.0, 0.01) var startup_time: float = 0.0
@export_range(0.0, 10.0, 0.01) var active_time: float = 0.0
@export_range(0.0, 10.0, 0.01) var recovery_time: float = 0.0
@export_range(0.0, 10.0, 0.01) var neutral_time: float = 0.0
@export var active_semantics: StringName = ACTIVE_TIMED_DAMAGE

@export_group("Counterplay")
@export_multiline var startup_warning: String
@export_multiline var response_contract: String
@export_multiline var punish_contract: String
@export var counterplay_tags: Array[StringName] = []

@export_group("Legality")
@export var legality_tags: Array[StringName] = []
@export var required_context_tags: Array[StringName] = []
@export var blocked_context_tags: Array[StringName] = []
@export_range(0.0, 1.0, 0.01) var minimum_safe_floor_fraction: float = 0.0
@export_range(0, 8, 1) var maximum_spawned_adds: int = 0
@export_range(0, 8, 1) var active_add_cap: int = 0
@export var spawn_markers_avoid_player: bool = false
@export var cleanup_owner: StringName

@export_group("Reviewed Phase 2 Followup")
@export var reviewed_phase_two_followup: BossPatternDefinition
@export_range(0.0, 10.0, 0.01) var reviewed_followup_neutral_time: float = 0.0
@export var reviewed_followup_required_context_tags: Array[StringName] = []
@export var reviewed_followup_blocked_context_tags: Array[StringName] = []


func supports_phase(phase: int) -> bool:
	return eligible_phases.has(phase)


func action_duration() -> float:
	return startup_time + active_time + recovery_time


func total_cycle_duration() -> float:
	return action_duration() + neutral_time


func is_legal_for_context(
	phase: int,
	available_context_tags: Array[StringName],
	active_constraint_tags: Array[StringName],
	safe_floor_fraction: float
) -> bool:
	if not supports_phase(phase):
		return false
	if safe_floor_fraction + FLOAT_TOLERANCE < minimum_safe_floor_fraction:
		return false
	for required_tag in required_context_tags:
		if not available_context_tags.has(required_tag):
			return false
	for blocked_tag in blocked_context_tags:
		if active_constraint_tags.has(blocked_tag):
			return false
	return true


func reviewed_followup_is_legal(
	phase: int,
	available_context_tags: Array[StringName],
	active_constraint_tags: Array[StringName],
	safe_floor_fraction: float
) -> bool:
	if phase != PHASE_TWO or reviewed_phase_two_followup == null:
		return false
	if not reviewed_phase_two_followup.is_legal_for_context(
		phase,
		available_context_tags,
		active_constraint_tags,
		safe_floor_fraction
	):
		return false
	for required_tag in reviewed_followup_required_context_tags:
		if not available_context_tags.has(required_tag):
			return false
	for blocked_tag in reviewed_followup_blocked_context_tags:
		if active_constraint_tags.has(blocked_tag):
			return false
	return true


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Boss pattern ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Boss pattern '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Boss pattern '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Boss pattern '%s' tag" % id, tags, true)
	ContentId.validate(errors, "Boss pattern '%s' presentation key" % id, presentation_key)
	_validate_phases(errors)
	_validate_timing(errors)
	_validate_counterplay(errors)
	_validate_legality(errors)
	_validate_followup(errors)
	return errors


func _validate_phases(errors: PackedStringArray) -> void:
	if eligible_phases.is_empty():
		errors.append("Boss pattern '%s' needs at least one eligible phase." % id)
		return
	var seen: Dictionary = {}
	for phase in eligible_phases:
		if not SUPPORTED_PHASES.has(phase):
			errors.append("Boss pattern '%s' has unsupported phase %d." % [id, phase])
		elif seen.has(phase):
			errors.append("Boss pattern '%s' duplicates phase %d." % [id, phase])
		seen[phase] = true


func _validate_timing(errors: PackedStringArray) -> void:
	for timing in [startup_time, active_time, recovery_time, neutral_time]:
		if not is_finite(timing) or timing < 0.0:
			errors.append("Boss pattern '%s' has an invalid timing value." % id)
			return
	if startup_time <= 0.0 or recovery_time <= 0.0:
		errors.append("Boss pattern '%s' needs positive startup and recovery timing." % id)
	if not ACTIVE_SEMANTICS.has(active_semantics):
		errors.append("Boss pattern '%s' has unsupported active semantics '%s'." % [id, active_semantics])
	elif active_semantics == ACTIVE_SUMMON_ACTIVATION:
		if not is_zero_approx(active_time):
			errors.append("Summon pattern '%s' active timing must be an instantaneous activation." % id)
	elif active_time <= 0.0:
		errors.append("Boss pattern '%s' needs positive active timing." % id)


func _validate_counterplay(errors: PackedStringArray) -> void:
	if startup_warning.strip_edges().is_empty():
		errors.append("Boss pattern '%s' needs a startup warning contract." % id)
	if response_contract.strip_edges().is_empty():
		errors.append("Boss pattern '%s' needs a response contract." % id)
	if punish_contract.strip_edges().is_empty():
		errors.append("Boss pattern '%s' needs a punish contract." % id)
	ContentId.validate_list(
		errors,
		"Boss pattern '%s' counterplay tag" % id,
		counterplay_tags,
		true
	)


func _validate_legality(errors: PackedStringArray) -> void:
	ContentId.validate_list(errors, "Boss pattern '%s' legality tag" % id, legality_tags, true)
	ContentId.validate_list(
		errors,
		"Boss pattern '%s' required context tag" % id,
		required_context_tags,
		false
	)
	ContentId.validate_list(
		errors,
		"Boss pattern '%s' blocked context tag" % id,
		blocked_context_tags,
		false
	)
	for required_tag in required_context_tags:
		if blocked_context_tags.has(required_tag):
			errors.append("Boss pattern '%s' both requires and blocks context '%s'." % [id, required_tag])
	if (
		not is_finite(minimum_safe_floor_fraction)
		or minimum_safe_floor_fraction < 0.0
		or minimum_safe_floor_fraction > 1.0
	):
		errors.append("Boss pattern '%s' safe-floor fraction must be between zero and one." % id)
	ContentId.validate(errors, "Boss pattern '%s' cleanup owner" % id, cleanup_owner)
	if active_semantics == ACTIVE_SUMMON_ACTIVATION:
		if maximum_spawned_adds <= 0 or active_add_cap <= 0:
			errors.append("Summon pattern '%s' needs positive spawn and active-add caps." % id)
		elif maximum_spawned_adds > active_add_cap:
			errors.append("Summon pattern '%s' cannot spawn more adds than its active cap." % id)
		if not spawn_markers_avoid_player:
			errors.append("Summon pattern '%s' markers must avoid the player." % id)
	elif maximum_spawned_adds != 0 or active_add_cap != 0 or spawn_markers_avoid_player:
		errors.append("Non-summon pattern '%s' cannot define add-spawn semantics." % id)


func _validate_followup(errors: PackedStringArray) -> void:
	ContentId.validate_list(
		errors,
		"Boss pattern '%s' followup required context tag" % id,
		reviewed_followup_required_context_tags,
		false
	)
	ContentId.validate_list(
		errors,
		"Boss pattern '%s' followup blocked context tag" % id,
		reviewed_followup_blocked_context_tags,
		false
	)
	if not is_finite(reviewed_followup_neutral_time) or reviewed_followup_neutral_time < 0.0:
		errors.append("Boss pattern '%s' has invalid followup neutral timing." % id)
	if reviewed_phase_two_followup == null:
		if (
			not is_zero_approx(reviewed_followup_neutral_time)
			or not reviewed_followup_required_context_tags.is_empty()
			or not reviewed_followup_blocked_context_tags.is_empty()
		):
			errors.append("Boss pattern '%s' has followup metadata without a followup." % id)
		return
	if not eligible_phases.has(PHASE_TWO):
		errors.append("Boss pattern '%s' needs phase 2 eligibility for its reviewed followup." % id)
	if reviewed_phase_two_followup == self or reviewed_phase_two_followup.id == id:
		errors.append("Boss pattern '%s' cannot follow itself." % id)
	elif not reviewed_phase_two_followup.supports_phase(PHASE_TWO):
		errors.append("Boss pattern '%s' followup must be phase 2 eligible." % id)
	for required_tag in reviewed_followup_required_context_tags:
		if reviewed_followup_blocked_context_tags.has(required_tag):
			errors.append("Boss pattern '%s' followup both requires and blocks '%s'." % [id, required_tag])
