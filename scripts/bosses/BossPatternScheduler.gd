class_name BossPatternScheduler
extends RefCounted

const MINIMUM_NEUTRAL_AFTER_CHAIN := 0.75

var _patterns: Array[BossPatternDefinition] = []
var _rng := RandomNumberGenerator.new()
var _seed: int
var _choice_count: int
var _last_pattern_id: StringName
var _history: Array[StringName] = []
var _configuration_errors := PackedStringArray()


func _init(
	p_patterns: Array[BossPatternDefinition] = [],
	p_seed: int = 0
) -> void:
	configure(p_patterns, p_seed)


func configure(p_patterns: Array[BossPatternDefinition], p_seed: int) -> PackedStringArray:
	_patterns = p_patterns.duplicate()
	_configuration_errors = _validate_configuration()
	reset(p_seed)
	return _configuration_errors.duplicate()


func reset(p_seed: int) -> void:
	_seed = p_seed
	_rng.seed = p_seed
	_choice_count = 0
	_last_pattern_id = &""
	_history.clear()


func choose_next(context: BossPatternContext) -> BossPatternSchedule:
	if context == null or not _configuration_errors.is_empty():
		return null
	if not context.validate_context().is_empty():
		return null
	var available_tags := context.available_tags()
	var active_constraints := context.active_constraint_tags()
	var eligible: Array[BossPatternDefinition] = []
	for pattern in _patterns:
		if pattern.id == _last_pattern_id:
			continue
		if not pattern.is_legal_for_context(
			context.phase,
			available_tags,
			active_constraints,
			context.safe_floor_fraction
		):
			continue
		if _spawn_count_for(pattern, context) < 0:
			continue
		eligible.append(pattern)
	if eligible.is_empty():
		return null

	var selected := eligible[_rng.randi_range(0, eligible.size() - 1)]
	var scheduled_patterns: Array[BossPatternDefinition] = []
	var spawned_add_counts := PackedInt32Array()
	scheduled_patterns.append(selected)
	spawned_add_counts.append(maxi(_spawn_count_for(selected, context), 0))
	var neutral_between := 0.0
	var neutral_after := selected.neutral_time

	if _reviewed_chain_is_legal(selected, context, available_tags, active_constraints):
		var followup := selected.reviewed_phase_two_followup
		scheduled_patterns.append(followup)
		spawned_add_counts.append(maxi(_spawn_count_for(followup, context), 0))
		neutral_between = selected.reviewed_followup_neutral_time
		neutral_after = maxf(MINIMUM_NEUTRAL_AFTER_CHAIN, followup.neutral_time)

	for pattern in scheduled_patterns:
		_history.append(pattern.id)
		_last_pattern_id = pattern.id
	_choice_count += 1
	return BossPatternSchedule.new(
		scheduled_patterns,
		neutral_between,
		neutral_after,
		spawned_add_counts
	)


func build_single(
	pattern_id: StringName,
	context: BossPatternContext,
	requested_spawn_count: int = -1
) -> BossPatternSchedule:
	if context == null or not _configuration_errors.is_empty():
		return null
	if not context.validate_context().is_empty():
		return null
	var pattern := _get_pattern(pattern_id)
	if pattern == null or not pattern.is_legal_for_context(
		context.phase,
		context.available_tags(),
		context.active_constraint_tags(),
		context.safe_floor_fraction
	):
		return null
	var available_spawn_count := _spawn_count_for(pattern, context)
	if available_spawn_count < 0:
		return null
	var spawn_count := 0
	if pattern.active_semantics == BossPatternDefinition.ACTIVE_SUMMON_ACTIVATION:
		spawn_count = available_spawn_count if requested_spawn_count < 0 else requested_spawn_count
		if spawn_count <= 0 or spawn_count > available_spawn_count:
			return null
	elif requested_spawn_count > 0:
		return null
	return BossPatternSchedule.new(
		[pattern],
		0.0,
		0.0,
		PackedInt32Array([spawn_count])
	)


func validate_configuration() -> PackedStringArray:
	return _configuration_errors.duplicate()


func get_history() -> Array[StringName]:
	return _history.duplicate()


func get_last_pattern_id() -> StringName:
	return _last_pattern_id


func get_choice_count() -> int:
	return _choice_count


func get_seed() -> int:
	return _seed


func _get_pattern(pattern_id: StringName) -> BossPatternDefinition:
	for pattern in _patterns:
		if pattern != null and pattern.id == pattern_id:
			return pattern
	return null


func _reviewed_chain_is_legal(
	selected: BossPatternDefinition,
	context: BossPatternContext,
	available_tags: Array[StringName],
	active_constraints: Array[StringName]
) -> bool:
	if not selected.reviewed_followup_is_legal(
		context.phase,
		available_tags,
		active_constraints,
		context.safe_floor_fraction
	):
		return false
	var followup := selected.reviewed_phase_two_followup
	return followup.id != selected.id and _spawn_count_for(followup, context) >= 0


# A negative count means the summon is illegal; zero means this pattern does not spawn adds.
func _spawn_count_for(pattern: BossPatternDefinition, context: BossPatternContext) -> int:
	if pattern.active_semantics != BossPatternDefinition.ACTIVE_SUMMON_ACTIVATION:
		return 0
	var effective_cap := mini(pattern.active_add_cap, context.active_add_cap)
	var available_slots := effective_cap - context.active_add_count
	if available_slots <= 0:
		return -1
	return mini(pattern.maximum_spawned_adds, available_slots)


func _validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if _patterns.is_empty():
		errors.append("Boss pattern scheduler needs at least one pattern.")
		return errors
	var patterns_by_id: Dictionary = {}
	for pattern_index in _patterns.size():
		var pattern := _patterns[pattern_index]
		if pattern == null:
			errors.append("Boss pattern scheduler entry %d is null." % pattern_index)
			continue
		var pattern_id := String(pattern.id)
		if patterns_by_id.has(pattern_id):
			errors.append("Boss pattern scheduler duplicates pattern '%s'." % pattern.id)
		patterns_by_id[pattern_id] = pattern
		for definition_error in pattern.validate_definition():
			errors.append("Boss pattern '%s': %s" % [pattern.id, definition_error])
	for pattern in _patterns:
		if pattern == null or pattern.reviewed_phase_two_followup == null:
			continue
		var followup_id := String(pattern.reviewed_phase_two_followup.id)
		if not patterns_by_id.has(followup_id):
			errors.append(
				"Boss pattern '%s' followup '%s' is not registered with the scheduler."
				% [pattern.id, pattern.reviewed_phase_two_followup.id]
			)
		elif patterns_by_id[followup_id] != pattern.reviewed_phase_two_followup:
			errors.append(
				"Boss pattern '%s' followup '%s' must reference its registered definition."
				% [pattern.id, pattern.reviewed_phase_two_followup.id]
			)
	return errors
