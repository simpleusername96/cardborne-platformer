extends SceneTree

const PATTERN_PATHS: Array[String] = [
	"res://data/bosses/jump_slam.tres",
	"res://data/bosses/body_bump.tres",
	"res://data/bosses/poison_bands.tres",
	"res://data/bosses/small_slime_summon.tres",
]
const EXPECTED_TIMINGS := {
	&"jump_slam": Vector3(0.80, 0.18, 1.00),
	&"body_bump": Vector3(0.55, 0.45, 0.80),
	&"poison_bands": Vector3(0.90, 2.20, 0.80),
	&"small_slime_summon": Vector3(0.70, 0.00, 1.00),
}

var _failures: Array[String] = []
var _patterns: Array[BossPatternDefinition] = []
var _patterns_by_id: Dictionary = {}


func _initialize() -> void:
	_load_patterns()
	_validate_definitions_and_timings()
	_validate_authored_constraints()
	_validate_scheduler_registration()
	_validate_slime_king_state_contract()
	_finish()


func _load_patterns() -> void:
	for path in PATTERN_PATHS:
		var pattern := load(path) as BossPatternDefinition
		_expect(pattern != null, "%s should load as BossPatternDefinition" % path)
		if pattern == null:
			continue
		_patterns.append(pattern)
		_patterns_by_id[pattern.id] = pattern


func _validate_definitions_and_timings() -> void:
	_expect(_patterns.size() == 4, "exactly four Giant Slime King patterns should load")
	_expect(_patterns_by_id.size() == 4, "Giant Slime King pattern IDs should be unique")
	for pattern in _patterns:
		var errors := pattern.validate_definition()
		_expect(errors.is_empty(), "%s should validate: %s" % [pattern.id, "; ".join(errors)])
		_expect(pattern.content_version == 1, "%s should begin at content version 1" % pattern.id)
		_expect(
			pattern.eligible_phases == [1, 2],
			"%s should be eligible in both boss phases" % pattern.id
		)
		_expect(is_zero_approx(pattern.neutral_time), "%s standalone neutral time should be exact" % pattern.id)
		var timing: Vector3 = EXPECTED_TIMINGS.get(pattern.id, Vector3(-1.0, -1.0, -1.0))
		_expect(is_equal_approx(pattern.startup_time, timing.x), "%s startup timing should be exact" % pattern.id)
		_expect(is_equal_approx(pattern.active_time, timing.y), "%s active timing should be exact" % pattern.id)
		_expect(is_equal_approx(pattern.recovery_time, timing.z), "%s recovery timing should be exact" % pattern.id)
		_expect(not pattern.startup_warning.is_empty(), "%s should declare its warning" % pattern.id)
		_expect(not pattern.response_contract.is_empty(), "%s should declare its response" % pattern.id)
		_expect(not pattern.punish_contract.is_empty(), "%s should declare its punish window" % pattern.id)
		_expect(pattern.cleanup_owner == SlimeKing.BOSS_ID, "%s cleanup should remain boss-owned" % pattern.id)


func _validate_authored_constraints() -> void:
	var jump := _pattern(&"jump_slam")
	var bump := _pattern(&"body_bump")
	var poison := _pattern(&"poison_bands")
	var summon := _pattern(&"small_slime_summon")
	if null in [jump, bump, poison, summon]:
		return

	_expect(
		jump.active_semantics == BossPatternDefinition.ACTIVE_TIMED_DAMAGE,
		"Jump Slam should own a timed damage window"
	)
	_expect(
		jump.required_context_tags.has(BossPatternContext.TAG_JUMP_SLAM_LANDING_RESPONSE),
		"Jump Slam should require a landing response"
	)
	_expect(
		jump.blocked_context_tags.has(BossPatternContext.BLOCK_POISON_REMOVES_JUMP_LANDING),
		"Jump Slam should be blocked when poison removes its landing response"
	)
	_expect(
		bump.required_context_tags.has(BossPatternContext.TAG_SIDE_RESPONSE),
		"Body Bump should require an open side response"
	)
	_expect(
		bump.blocked_context_tags.has(BossPatternContext.BLOCK_TWO_ADDS_BLOCK_BOTH_SIDES),
		"Body Bump should be blocked when two adds close both side responses"
	)
	_expect(
		bump.reviewed_phase_two_followup == jump,
		"Body Bump should reference Jump Slam as its reviewed phase-2 followup"
	)
	_expect(
		is_equal_approx(bump.reviewed_followup_neutral_time, 0.50),
		"Body Bump chain neutral timing should be exactly 0.50 seconds"
	)
	_expect(
		poison.active_semantics == BossPatternDefinition.ACTIVE_PERSISTENT_ZONE,
		"Poison Bands should own a persistent zone window"
	)
	_expect(
		is_equal_approx(poison.minimum_safe_floor_fraction, 0.35),
		"Poison Bands should preserve exactly the 35 percent safe-floor minimum"
	)
	_expect(
		poison.reviewed_phase_two_followup == summon,
		"Poison Bands should reference Summon as its reviewed phase-2 followup"
	)
	_expect(
		poison.reviewed_followup_required_context_tags.has(
			BossPatternContext.TAG_POISON_SUMMON_ZONES_NON_OVERLAPPING
		),
		"Poison-to-Summon should require non-overlapping zones"
	)
	_expect(
		summon.active_semantics == BossPatternDefinition.ACTIVE_SUMMON_ACTIVATION,
		"Small Slime Summon active timing should be an activation event"
	)
	_expect(
		summon.maximum_spawned_adds == 2 and summon.active_add_cap == 2,
		"Small Slime Summon should author two markers and a two-add cap"
	)
	_expect(summon.spawn_markers_avoid_player, "Small Slime Summon markers should avoid the player")


func _validate_scheduler_registration() -> void:
	var scheduler := BossPatternScheduler.new(_patterns, 73102)
	var errors := scheduler.validate_configuration()
	_expect(errors.is_empty(), "authored scheduler configuration should validate: %s" % "; ".join(errors))
	_expect(scheduler.get_seed() == 73102, "scheduler should preserve its seed")
	_expect(scheduler.get_history().is_empty(), "new scheduler history should begin empty")


func _validate_slime_king_state_contract() -> void:
	const FIXTURE_STAGGER_CAPACITY := 100
	var boss := SlimeKing.new(FIXTURE_STAGGER_CAPACITY)
	var boss_value: Variant = boss
	_expect(not boss_value is Node, "SlimeKing state contract should remain scene-tree neutral")
	_expect(boss.validate_slime_king_contract().is_empty(), "SlimeKing state contract should validate")
	_expect(boss.max_health == 80 and boss.health == 80, "SlimeKing health should begin at exactly 80")
	_expect(boss.phase_two_health == 40 and boss.phase == 1, "SlimeKing phase 2 should begin at 50 percent")
	_expect(is_equal_approx(boss.stagger_duration, 1.4), "SlimeKing stagger window should be exactly 1.4 seconds")
	_expect(SlimeKing.CONTACT_DAMAGE == 1, "SlimeKing declared contact damage should be exactly one")
	_expect(boss.activate(), "SlimeKing should activate from dormant state")

	var opening_hit := boss.apply_hit(39, 0)
	_expect(opening_hit["accepted"] and boss.health == 41 and boss.phase == 1, "41 health should remain phase 1")
	var phase_hit := boss.apply_hit(1, 0)
	_expect(phase_hit["phase_changed"] and boss.health == 40 and boss.phase == 2, "40 health should enter phase 2")
	var stagger_hit := boss.apply_hit(0, FIXTURE_STAGGER_CAPACITY)
	_expect(stagger_hit["staggered"], "bounded stagger meter should trigger at its capacity")
	_expect(stagger_hit["cancel_queued_chain"], "stagger should publish queued-chain cancellation")
	_expect(boss.state == BossBase.STATE_STAGGERED, "stagger should enter the staggered state")
	_expect(not boss.advance_time(0.70), "half the stagger window should not recover")
	_expect(boss.advance_time(0.70), "the full stagger window should recover")
	_expect(boss.state == BossBase.STATE_ACTIVE, "stagger recovery should return to active state")
	var defeat_hit := boss.apply_hit(40, 0)
	_expect(defeat_hit["defeated"] and boss.state == BossBase.STATE_DEFEATED, "zero health should defeat once")
	_expect(not boss.apply_hit(1, 1)["accepted"], "defeated boss should reject further hits")

	var copied_snapshot := boss.snapshot()
	copied_snapshot["health"] = 999
	_expect(boss.health == 0, "boss snapshots should not mutate live state")
	boss.reset()
	_expect(boss.health == 80 and boss.phase == 1 and boss.state == BossBase.STATE_DORMANT, "reset should restore authored state")
	_expect(not SlimeKing.new(0).validate_slime_king_contract().is_empty(), "invalid injected stagger capacity should fail closed")


func _pattern(pattern_id: StringName) -> BossPatternDefinition:
	return _patterns_by_id.get(pattern_id) as BossPatternDefinition


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BOSS_PATTERN_CONTRACT_VALIDATION_OK patterns=%d" % _patterns.size())
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
