extends SceneTree

const PATTERN_PATHS: Array[String] = [
	"res://data/bosses/jump_slam.tres",
	"res://data/bosses/body_bump.tres",
	"res://data/bosses/poison_bands.tres",
	"res://data/bosses/small_slime_summon.tres",
]
const SEED_COUNT := 192
const CHOICES_PER_SEED := 32

var _failures: Array[String] = []
var _patterns: Array[BossPatternDefinition] = []
var _simulated_choices: int


func _initialize() -> void:
	_load_patterns()
	if _patterns.size() != 4:
		_finish()
		return
	var contexts := _simulation_contexts()
	_validate_determinism_and_general_legality(contexts)
	_validate_explicit_context_guards()
	_validate_reviewed_chains()
	_validate_fail_closed_context()
	_expect(_simulated_choices >= 5000, "scheduler validator should simulate thousands of choices")
	_finish()


func _load_patterns() -> void:
	for path in PATTERN_PATHS:
		var pattern := load(path) as BossPatternDefinition
		_expect(pattern != null, "%s should load as BossPatternDefinition" % path)
		if pattern != null:
			_patterns.append(pattern)


func _simulation_contexts() -> Array[BossPatternContext]:
	var contexts: Array[BossPatternContext] = []
	contexts.append(_context(1, 0, 1.0, true, false, true, true, true, false))
	contexts.append(_context(2, 0, 1.0, true, false, true, true, true, false))
	contexts.append(_context(2, 0, 1.0, false, true, true, true, true, false))
	contexts.append(_context(2, 2, 1.0, true, false, false, false, true, false))
	contexts.append(_context(2, 2, 1.0, true, false, true, true, true, false))
	contexts.append(_context(2, 0, 1.0, true, false, true, true, false, false))
	contexts.append(_context(2, 0, 1.0, true, false, true, true, true, true))
	contexts.append(_context(2, 1, 1.0, true, false, true, true, true, false))
	contexts.append(_context(1, 0, 0.34, true, false, true, true, true, false))
	return contexts


func _validate_determinism_and_general_legality(
	contexts: Array[BossPatternContext]
) -> void:
	var seed_signatures: Dictionary = {}
	for seed in SEED_COUNT:
		var first := BossPatternScheduler.new(_patterns, seed)
		var second := BossPatternScheduler.new(_patterns, seed)
		var previous_pattern_id: StringName = &""
		var sequence_rows: Array[String] = []
		for choice_index in CHOICES_PER_SEED:
			var context := contexts[(seed + choice_index) % contexts.size()]
			var first_schedule := first.choose_next(context)
			var second_schedule := second.choose_next(context)
			_simulated_choices += 1
			_expect(
				(first_schedule == null) == (second_schedule == null),
				"seed %d choice %d should reproduce nullability" % [seed, choice_index]
			)
			if first_schedule == null or second_schedule == null:
				continue
			_expect(
				first_schedule.signature() == second_schedule.signature(),
				"seed %d choice %d should reproduce exactly" % [seed, choice_index]
			)
			sequence_rows.append(first_schedule.signature())
			previous_pattern_id = _inspect_schedule(
				first_schedule,
				context,
				previous_pattern_id,
				"seed %d choice %d" % [seed, choice_index]
			)
		_expect(first.get_history() == second.get_history(), "seed %d histories should reproduce" % seed)
		seed_signatures[";".join(sequence_rows)] = true
	_expect(seed_signatures.size() >= 16, "different seeds should produce varied deterministic sequences")


func _validate_explicit_context_guards() -> void:
	_assert_pattern_absent(
		&"jump_slam",
		_context(2, 0, 1.0, false, true, true, true, true, false),
		"poison removing the landing response"
	)
	_assert_pattern_absent(
		&"body_bump",
		_context(2, 2, 1.0, true, false, false, false, true, false),
		"two adds blocking both side responses"
	)
	_assert_pattern_absent(
		&"small_slime_summon",
		_context(2, 2, 1.0, true, false, true, true, true, false),
		"the active-add cap"
	)
	_assert_pattern_absent(
		&"small_slime_summon",
		_context(2, 0, 1.0, true, false, true, true, false, false),
		"unsafe summon spawn zones"
	)
	_assert_pattern_absent(
		&"poison_bands",
		_context(2, 0, 0.34, true, false, true, true, true, false),
		"less than 35 percent safe floor"
	)

	var one_add_context := _context(2, 1, 1.0, true, false, true, true, true, false)
	var summon_seen := false
	for seed in 96:
		var scheduler := BossPatternScheduler.new(_patterns, seed)
		for choice_index in 12:
			var schedule := scheduler.choose_next(one_add_context)
			_simulated_choices += 1
			if schedule == null:
				continue
			for pattern_index in schedule.patterns.size():
				if schedule.patterns[pattern_index].id == &"small_slime_summon":
					summon_seen = true
					_expect(
						schedule.spawned_add_count_for(pattern_index) == 1,
						"one occupied add slot should permit exactly one new add"
					)
	_expect(summon_seen, "one-open-slot simulation should exercise Summon")


func _validate_reviewed_chains() -> void:
	var safe_phase_two := _context(2, 0, 1.0, true, false, true, true, true, false)
	var body_chain_count := 0
	var poison_chain_count := 0
	for seed in 128:
		var scheduler := BossPatternScheduler.new(_patterns, seed)
		var previous_pattern_id: StringName = &""
		for choice_index in 16:
			var schedule := scheduler.choose_next(safe_phase_two)
			_simulated_choices += 1
			if schedule == null:
				continue
			previous_pattern_id = _inspect_schedule(
				schedule,
				safe_phase_two,
				previous_pattern_id,
				"safe phase-2 seed %d choice %d" % [seed, choice_index]
			)
			if schedule.pattern_ids() == [&"body_bump", &"jump_slam"]:
				body_chain_count += 1
			elif schedule.pattern_ids() == [&"poison_bands", &"small_slime_summon"]:
				poison_chain_count += 1
	_expect(body_chain_count > 0, "safe phase 2 should exercise reviewed Body Bump to Jump Slam chains")
	_expect(poison_chain_count > 0, "safe phase 2 should exercise reviewed Poison to Summon chains")

	_assert_chain_absent(
		[&"poison_bands", &"small_slime_summon"],
		_context(2, 0, 1.0, true, false, true, true, true, true),
		"overlapping poison and summon zones"
	)
	_assert_chain_absent(
		[&"poison_bands", &"small_slime_summon"],
		_context(2, 2, 1.0, true, false, true, true, true, false),
		"the active-add cap"
	)
	_assert_all_schedules_single(
		_context(1, 0, 1.0, true, false, true, true, true, false),
		"phase 1"
	)


func _validate_fail_closed_context() -> void:
	var blocked := _context(2, 2, 0.0, false, true, false, false, false, true)
	var scheduler := BossPatternScheduler.new(_patterns, 99)
	_expect(scheduler.choose_next(blocked) == null, "fully blocked context should return no schedule")
	_expect(scheduler.get_choice_count() == 0, "failed choice should not advance scheduler sequence")
	_expect(scheduler.get_history().is_empty(), "failed choice should not record pattern history")


func _inspect_schedule(
	schedule: BossPatternSchedule,
	context: BossPatternContext,
	previous_pattern_id: StringName,
	label: String
) -> StringName:
	_expect(not schedule.patterns.is_empty(), "%s should contain a pattern" % label)
	_expect(
		schedule.spawned_add_counts.size() == schedule.patterns.size(),
		"%s should report a spawn count for each pattern" % label
	)
	var last_id := previous_pattern_id
	for pattern_index in schedule.patterns.size():
		var pattern := schedule.patterns[pattern_index]
		_expect(pattern.id != last_id, "%s should not immediately repeat '%s'" % [label, pattern.id])
		_expect(pattern.supports_phase(context.phase), "%s should respect phase eligibility" % label)
		_validate_pattern_against_context(pattern, schedule, pattern_index, context, label)
		last_id = pattern.id

	if schedule.is_chain():
		_expect(context.phase == 2, "%s chains should only run in phase 2" % label)
		_expect(schedule.patterns.size() == 2, "%s reviewed chain should contain exactly two patterns" % label)
		var ids := schedule.pattern_ids()
		var is_body_chain := ids == [&"body_bump", &"jump_slam"]
		var is_poison_chain := ids == [&"poison_bands", &"small_slime_summon"]
		_expect(is_body_chain or is_poison_chain, "%s should use only reviewed chain order" % label)
		if is_body_chain:
			_expect(
				is_equal_approx(schedule.neutral_between_patterns, 0.50),
				"%s Body Bump chain should keep exact 0.50 second neutral" % label
			)
		if is_poison_chain:
			_expect(context.summon_spawn_zones_safe, "%s Poison chain should use safe spawn zones" % label)
			_expect(
				not context.summon_spawn_zones_overlap_poison,
				"%s Poison chain zones should not overlap" % label
			)
			_expect(
				is_zero_approx(schedule.neutral_between_patterns),
				"%s Poison chain should begin Summon after authored cleanup" % label
			)
		_expect(
			schedule.neutral_after + 0.0001 >= 0.75,
			"%s chain should end with at least 0.75 seconds neutral" % label
		)
	else:
		_expect(
			is_equal_approx(schedule.neutral_after, schedule.patterns[0].neutral_time),
			"%s standalone schedule should use its authored neutral timing" % label
		)
	return last_id


func _validate_pattern_against_context(
	pattern: BossPatternDefinition,
	schedule: BossPatternSchedule,
	pattern_index: int,
	context: BossPatternContext,
	label: String
) -> void:
	match pattern.id:
		&"jump_slam":
			_expect(
				context.jump_slam_landing_response_available,
				"%s Jump Slam should retain a landing response" % label
			)
			_expect(
				not (context.poison_bands_active and not context.jump_slam_landing_response_available),
				"%s Jump Slam should not overlap response-removing poison" % label
			)
		&"body_bump":
			_expect(
				context.left_side_response_available or context.right_side_response_available,
				"%s Body Bump should retain a side response" % label
			)
			_expect(
				not (
					context.active_add_count >= 2
					and not context.left_side_response_available
					and not context.right_side_response_available
				),
				"%s Body Bump should not start behind two body-blocking adds" % label
			)
		&"poison_bands":
			_expect(
				context.safe_floor_fraction + 0.0001 >= 0.35,
				"%s Poison Bands should retain 35 percent safe floor" % label
			)
		&"small_slime_summon":
			var spawn_count := schedule.spawned_add_count_for(pattern_index)
			var effective_cap := mini(context.active_add_cap, pattern.active_add_cap)
			_expect(context.summon_spawn_zones_safe, "%s Summon zones should be safe" % label)
			_expect(context.active_add_count < effective_cap, "%s Summon should skip at add cap" % label)
			_expect(spawn_count > 0, "%s Summon should activate at least one add" % label)
			_expect(
				context.active_add_count + spawn_count <= effective_cap,
				"%s Summon should never exceed the active-add cap" % label
			)
		_:
			_expect(false, "%s scheduled unknown pattern '%s'" % [label, pattern.id])
	if pattern.id != &"small_slime_summon":
		_expect(schedule.spawned_add_count_for(pattern_index) == 0, "%s non-summon should spawn no adds" % label)


func _assert_pattern_absent(
	pattern_id: StringName,
	context: BossPatternContext,
	reason: String
) -> void:
	for seed in 96:
		var scheduler := BossPatternScheduler.new(_patterns, seed)
		for choice_index in 12:
			var schedule := scheduler.choose_next(context)
			_simulated_choices += 1
			if schedule != null:
				_expect(
					not schedule.pattern_ids().has(pattern_id),
					"%s should be absent during %s" % [pattern_id, reason]
				)


func _assert_chain_absent(
	chain_ids: Array[StringName],
	context: BossPatternContext,
	reason: String
) -> void:
	for seed in 96:
		var scheduler := BossPatternScheduler.new(_patterns, seed)
		for choice_index in 12:
			var schedule := scheduler.choose_next(context)
			_simulated_choices += 1
			if schedule != null:
				_expect(schedule.pattern_ids() != chain_ids, "chain %s should be absent during %s" % [chain_ids, reason])


func _assert_all_schedules_single(context: BossPatternContext, label: String) -> void:
	for seed in 64:
		var scheduler := BossPatternScheduler.new(_patterns, seed)
		for choice_index in 8:
			var schedule := scheduler.choose_next(context)
			_simulated_choices += 1
			if schedule != null:
				_expect(not schedule.is_chain(), "%s should not schedule a reviewed chain" % label)


func _context(
	phase: int,
	active_add_count: int,
	safe_floor_fraction: float,
	jump_landing_response: bool,
	poison_active: bool,
	left_side_response: bool,
	right_side_response: bool,
	summon_zones_safe: bool,
	summon_zones_overlap_poison: bool
) -> BossPatternContext:
	return BossPatternContext.new(
		phase,
		active_add_count,
		2,
		safe_floor_fraction,
		jump_landing_response,
		poison_active,
		left_side_response,
		right_side_response,
		summon_zones_safe,
		summon_zones_overlap_poison
	)


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 80:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BOSS_SCHEDULER_VALIDATION_OK simulated_choices=%d" % _simulated_choices)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
