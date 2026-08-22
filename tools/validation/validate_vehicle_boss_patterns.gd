extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_common_progression()
	_validate_pattern_contracts()
	_validate_signature_ownership()
	_validate_absolute_profiles()
	_finish()


func _validate_common_progression() -> void:
	var expected_stage_one := [
		"common_charge",
		"common_lane_volley",
		"common_broad_barrage",
		"common_radial_bombardment",
	]
	var expected_complete := [
		"common_charge",
		"common_lane_volley",
		"common_broad_barrage",
		"common_radial_bombardment",
		"common_parallel_beam",
		"common_x_beam",
	]
	_expect(
		Patterns.common_sequence(&"stage_1") == expected_stage_one,
		"Stage 1 teaches the first four committed common attacks"
	)
	_expect(
		Patterns.common_sequence(&"stage_2") == expected_complete,
		"Stage 2 retains Stage 1 and adds parallel and X beams"
	)
	_expect(
		Patterns.common_sequence(&"stage_3") == expected_complete,
		"Stage 3 retains the complete direct common attack language"
	)
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		if not Catalog.has_boss(stage_id):
			_expect(
				Patterns.sequence(stage_id).is_empty()
					and Patterns.autonomous_sequence(stage_id).is_empty(),
				"%s fails closed without boss patterns" % stage_id
			)
			continue
		var common := Patterns.common_sequence(stage_id)
		var signatures := Patterns.signature_sequence(stage_id)
		var selected := Patterns.sequence(stage_id)
		var expected_common := expected_stage_one if stage_index == 0 else expected_complete
		_expect(
			common == expected_common,
			"%s resolves its cumulative common attack set" % stage_id
		)
		_expect(
			selected == common + signatures,
			"%s keeps common and signature selections queryable and ordered" % stage_id
		)
		for pattern in common:
			_expect(Patterns.is_common(pattern), "%s is classified as common" % pattern)
			_expect(
				not Patterns.is_signature(stage_id, pattern),
				"%s is not misclassified as a %s signature" % [pattern, stage_id]
			)
		for pattern in signatures:
			_expect(
				Patterns.is_signature(stage_id, pattern),
				"%s is classified as a %s signature" % [pattern, stage_id]
			)
	_expect(
		Patterns.is_common("common_squad_call")
			and Patterns.kind("common_squad_call") == &"squad"
			and Patterns.commit_mode("common_squad_call") == &"periodic",
		"the ten-second squad call is an explicit periodic common family"
	)


func _validate_pattern_contracts() -> void:
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		if not Catalog.has_boss(stage_id):
			continue
		for pattern in Patterns.sequence(stage_id):
			_expect(
				Patterns.kind(pattern) in [
					&"lanes", &"fan", &"cross", &"broad_barrage",
					&"crossing_weave", &"compression", &"radial_volley",
					&"charge", &"beam", &"switch_sweep", &"area",
					&"pylons", &"summon", &"long_banks",
				],
				"%s resolves a supported direct shape" % pattern
			)
			_expect(
				Patterns.commit_mode(pattern) in [&"committed", &"autonomous"],
				"%s declares direct execution ownership" % pattern
			)
			_expect(
				Patterns.affinity(pattern) in AttackContract.AFFINITIES,
				"%s declares a supported affinity" % pattern
			)
			_expect(
				not Patterns.behavior_family(pattern).is_empty(),
				"%s resolves a behavior family" % pattern
			)
		for pattern in Patterns.autonomous_sequence(stage_id):
			_expect(
				Patterns.kind(String(pattern)) in [
					&"area", &"lanes", &"beam", &"summon", &"long_banks",
					&"crossing_weave", &"radial_volley", &"compression",
				],
				"%s resolves a supported autonomous shape" % pattern
			)
			_expect(
				Patterns.is_signature(stage_id, String(pattern)),
				"%s autonomous system remains stage-signature content" % pattern
			)
	_expect(
		is_equal_approx(Patterns.startup_seconds("common_lane_volley", 11), 0.18)
			and is_equal_approx(Patterns.startup_seconds("common_broad_barrage", 11), 0.22)
			and is_equal_approx(Patterns.startup_seconds("common_charge", 11), 0.28)
			and is_equal_approx(Patterns.startup_seconds("long_bank_barrage", 5), 0.30),
		"projectile volleys, barrages, charges, and Stage 6 ordnance use brief commitment reads"
	)
	_expect(
		is_equal_approx(Patterns.startup_seconds("common_parallel_beam", 11), 0.45)
			and is_equal_approx(Patterns.startup_seconds("common_x_beam", 11), 0.45)
			and Patterns.startup_seconds("crossing_weave_a", 6) >= 1.0
			and Patterns.startup_seconds("compression_single", 8) >= 0.65,
		"beams and placed walls retain their longer readable warnings"
	)
	_expect(
		Patterns.beam_topology("common_parallel_beam") == AttackContract.BEAM_TOPOLOGY_PARALLEL
			and Patterns.beam_topology("common_x_beam") == AttackContract.BEAM_TOPOLOGY_X,
		"the two shared beam exams own fixed, distinct topologies"
	)


func _validate_signature_ownership() -> void:
	_expect(Patterns.signature_sequence(&"stage_1").is_empty(), "Stage 1 remains a pure common-language tutorial")
	_expect(Patterns.signature_sequence(&"stage_2").is_empty(), "Stage 2 remains a cumulative common-language tutorial")
	_expect(Patterns.signature_sequence(&"stage_3") == ["shield_counterburst"], "Stage 3 adds its shield-fed counterattack")
	_expect(Patterns.signature_sequence(&"stage_4") == ["switch_sweep"], "Stage 4 retains its sequential sweep")
	_expect(Patterns.signature_sequence(&"stage_5") == ["carrier_wave"], "Stage 5 retains its carrier summon")
	_expect(
		Patterns.signature_sequence(&"stage_6") == ["long_bank_barrage"]
			and Patterns.autonomous_sequence(&"stage_6").is_empty(),
		"Stage 6 distance-growth ordnance has one scheduler owner"
	)
	_expect(
		Patterns.signature_sequence(&"stage_7") == ["crossing_weave_a", "crossing_weave_b"],
		"Stage 7 keeps the crossing-wall signature variants"
	)
	_expect(
		Patterns.signature_sequence(&"stage_8") == ["radial_volley_a", "radial_volley_b"],
		"Stage 8 keeps the two radial projectile variants"
	)
	_expect(
		Patterns.signature_sequence(&"stage_9").size() == 4
			and "compression_single" in Patterns.signature_sequence(&"stage_9"),
		"Stage 9 layers its compression variants over the common pool"
	)
	for stage_id in [&"stage_10", &"stage_11", &"stage_12"]:
		_expect(
			Patterns.common_sequence(stage_id).size() == 6,
			"%s keeps the complete direct common pool beside its state mechanic" % stage_id
		)
	_expect(
		Patterns.behavior_family("reflect_fan") == &"fan_volley"
			and Patterns.behavior_family("resonance_fan") == &"fan_volley"
			and Patterns.is_shared_behavior("reflect_fan"),
		"differently named projectile aliases still resolve to shared behavior"
	)
	_expect(
		Patterns.behavior_family("switch_sweep") == &"sequential_beam_sweep"
			and not Patterns.is_shared_behavior("switch_sweep"),
		"the Stage 4 sequential sweep remains a real signature behavior"
	)


func _validate_absolute_profiles() -> void:
	_expect(BossProfiles.PROFILES.size() == 12, "boss catalog exposes twelve independent profiles")
	for stage_index in 11:
		_expect(
			BossProfiles.health(stage_index + 1) > BossProfiles.health(stage_index)
				and BossProfiles.move_speed(stage_index + 1) > BossProfiles.move_speed(stage_index),
			"Stage %d to %d retains stronger independently authored core stats"
				% [stage_index + 1, stage_index + 2]
		)
	for stage_index in Catalog.STAGE_IDS.size():
		_expect(
			is_equal_approx(Difficulty.boss_health(stage_index), BossProfiles.health(stage_index)),
			"Stage %d retains its independently authored health" % (stage_index + 1)
		)
	_expect(
		is_equal_approx(Patterns.damage("thermal_gates", 0), 22.0)
			and is_equal_approx(Patterns.damage("reflect_lance", 9), 55.08)
			and is_equal_approx(Patterns.damage("overload_rush_return", 11), 74.76),
		"unrelated authored signature damage remains unchanged"
	)
	_expect(
		Patterns.damage("common_lane_volley", 11) > Patterns.damage("common_lane_volley", 0)
			and Patterns.damage("common_x_beam", 11) > Patterns.damage("common_x_beam", 0),
		"later bosses strengthen newly shared common attacks without a global boss-stat rewrite"
	)
	_expect(
		is_equal_approx(EncounterDirector.effective_hostile_projectile_speed(500.0), 410.0),
		"boss prediction and projectile motion retain the hostile speed contract"
	)
	_expect(Patterns.AREA_TARGET_MAX_LEAD == 96.0, "boss radial attacks keep bounded target lead")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_PATTERNS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
