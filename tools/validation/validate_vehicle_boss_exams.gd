extends SceneTree

const Catalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const Runtime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_catalog()
	_validate_defense_owners()
	_validate_stage_three_guard()
	_validate_stage_ten_reflection()
	_validate_source_boundaries()
	_finish()


func _validate_catalog() -> void:
	_expect(Catalog.validate_contract().is_empty(), "twelve boss phase definitions satisfy the authored contract")
	var variants := {}
	for stage_id in CombatStages.STAGE_IDS:
		var variant := Catalog.variant(stage_id)
		_expect(not variant.is_empty(), "%s owns a boss variant" % stage_id)
		_expect(not variants.has(variant), "%s boss variant is unique" % stage_id)
		variants[variant] = true
		for phase in [1, 2, 3]:
			var roles := Catalog.squad_roles(stage_id, phase)
			_expect(
				not roles.is_empty() and roles.size() <= Catalog.MAX_LIVE_ADDS,
				"%s phase %d periodic squad stays bounded" % [stage_id, phase]
			)
	_expect(variants.size() == 12, "all twelve cycles own distinct boss identities")
	_expect(
		Catalog.BOSS_ENTRY_SLOT_RESERVE == 1 + Catalog.MAX_LIVE_ADDS,
		"boss entry reserves only the boss body and bounded add budget"
	)


func _validate_defense_owners() -> void:
	var owners := CombatStages.STAGE_IDS.filter(func(stage_id): return Catalog.uses_shield(stage_id))
	_expect(owners == [&"stage_3", &"stage_10"], "only Stage 3 guard and Stage 10 reflection own boss defenses")
	for stage_id in CombatStages.STAGE_IDS:
		var runtime := Runtime.new()
		runtime.configure(stage_id)
		runtime.begin_phase(1)
		if stage_id == &"stage_3":
			_expect(runtime.state() == &"shield_up", "Stage 3 begins with its segmented guard active")
		elif stage_id == &"stage_10":
			_expect(runtime.state() == &"shield_down", "Stage 10 begins with its complete reflection down window")
		else:
			_expect(
				runtime.state() == &"none"
					and is_equal_approx(runtime.boss_damage_multiplier(), 1.0),
				"%s has no implicit defense" % stage_id
			)


func _validate_stage_three_guard() -> void:
	var runtime := Runtime.new()
	runtime.configure(&"stage_3")
	runtime.begin_phase(1)
	var gap_direction := Vector2.RIGHT.rotated(Runtime.SHIELD_GAP_ARC * 0.5)
	var segment_direction := Vector2.RIGHT.rotated(
		Runtime.SHIELD_GAP_ARC + Runtime.SHIELD_SEGMENT_ARC * 0.5
	)
	_expect(
		is_equal_approx(runtime.boss_damage_multiplier(gap_direction, Vector2.LEFT, 100.0), 1.0),
		"Stage 3 gap shots deal normal damage regardless of boss facing"
	)
	_expect(
		is_equal_approx(
			runtime.boss_damage_multiplier(segment_direction, Vector2.LEFT, 100.0),
			Runtime.BLOCKED_DAMAGE_MULTIPLIER
		),
		"Stage 3 segment hits deal fifteen-percent damage"
	)
	runtime.advance(Runtime.SHIELD_UP_SECONDS)
	_expect(
		runtime.state() == &"shield_down"
			and is_equal_approx(runtime.boss_damage_multiplier(segment_direction, Vector2.RIGHT, 10.0), 1.0),
		"Stage 3 becomes fully exposed after eight protected seconds"
	)
	runtime.advance(Runtime.SHIELD_DOWN_SECONDS)
	_expect(runtime.state() == &"shield_up", "Stage 3 restores its segmented guard after two exposed seconds")
	_expect(runtime.consume_counterburst_multiplier() > 1.0, "blocked guard damage charges the Stage 3 counterburst")
	var presentation := runtime.presentation_snapshot()
	_expect(
		StringName(presentation["shield_kind"]) == &"segmented_guard"
			and StringName(presentation["effect"]) == &"guard"
			and int(presentation["segment_count"]) == 3,
		"Stage 3 publishes its exact collision-owned segmented guard"
	)


func _validate_stage_ten_reflection() -> void:
	var runtime := Runtime.new()
	runtime.configure(&"stage_10")
	runtime.begin_phase(1)
	var profile := Catalog.defense_profile(&"stage_10")
	var gap_direction := Vector2.RIGHT.rotated(float(profile["gap_arc"]) * 0.5)
	var segment_direction := Vector2.RIGHT.rotated(
		float(profile["gap_arc"]) + float(profile["segment_arc"]) * 0.5
	)
	_expect(
		not runtime.reflects_projectile(-segment_direction),
		"Stage 10 reflects nothing during its initial down window"
	)
	runtime.advance(14.0)
	_expect(runtime.state() == &"shield_cue", "the final exposed second is an inactive segmented activation cue")
	_expect(
		not runtime.reflects_projectile(-segment_direction),
		"the activation cue remains fully damageable"
	)
	runtime.advance(1.0)
	_expect(runtime.state() == &"shield_up", "Stage 10 reflection activates after fifteen exposed seconds")
	_expect(
		runtime.reflects_projectile(-segment_direction)
			and not runtime.reflects_projectile(-gap_direction),
		"active Stage 10 segments reflect while their real gaps remain attackable"
	)
	_expect(
		is_equal_approx(runtime.boss_damage_multiplier(segment_direction, Vector2.RIGHT, 100.0), 1.0),
		"reflection never converts non-reflected damage into guard reduction"
	)
	runtime.advance(5.0)
	_expect(runtime.state() == &"shield_down", "Stage 10 returns to a complete fifteen-second down window")
	var presentation := runtime.presentation_snapshot()
	_expect(
		StringName(presentation["shield_kind"]) == &"segmented_reflection"
			and StringName(presentation["effect"]) == &"reflect"
			and is_equal_approx(float(presentation["down_seconds"]), 15.0),
		"Stage 10 publishes segmented reflection and its complete down duration"
	)


func _validate_source_boundaries() -> void:
	var runtime_source := FileAccess.get_file_as_string("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
	_expect(not runtime_source.contains("for enemy in enemies"), "boss defense runtime never scans the enemy store")
	var run_source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	_expect(
		run_source.contains("boss_shield_runtime.boss_damage_multiplier")
			and run_source.contains("boss_shield_runtime.reflects_projectile")
			and run_source.contains("boss_runtime.advance_squad")
			and not run_source.contains("var payload := boss_shield_runtime.begin_phase")
			and not run_source.contains("boss_pylon")
			and not run_source.contains("boss_objective"),
		"production flow consumes one body-attached defense and periodic squads without phase-spawn objectives"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_SHIELDS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
