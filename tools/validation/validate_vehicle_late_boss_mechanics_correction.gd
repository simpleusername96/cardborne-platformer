extends SceneTree

const LateMechanics = preload("res://scripts/bosses/vehicle_late_boss_mechanics.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const PhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const ShieldRuntime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_late_pattern_composition()
	_validate_shared_defense_schedule()
	_validate_wall_scales()
	_validate_state_mechanics()
	await _validate_world_execution()
	_finish()


func _validate_late_pattern_composition() -> void:
	for stage_id in [&"stage_9", &"stage_10", &"stage_11", &"stage_12"]:
		var common := Patterns.common_sequence(stage_id)
		_expect(
			common.size() == 5
				and "common_charge" in common
				and "common_broad_barrage" in common
				and "common_parallel_beam" in common
				and "common_x_beam" in common,
			"%s retains the complete common attack language" % stage_id
		)
	_expect(
		Patterns.signature_sequence(&"stage_9") == [
			"compression_single", "compression_shift", "compression_pair", "compression_reverse",
		],
		"Stage 9 layers one compression mechanic with four authored variants"
	)
	_expect(
		Patterns.signature_sequence(&"stage_10").is_empty()
			and PhaseCatalog.defense_effect(&"stage_10") == &"reflect",
		"Stage 10 uses segmented reflection as its signature state"
	)
	_expect(
		Patterns.signature_sequence(&"stage_11").is_empty()
			and Patterns.signature_sequence(&"stage_12").is_empty(),
		"Stages 11 and 12 keep resonance and overload as state mechanics beside common attacks"
	)


func _validate_shared_defense_schedule() -> void:
	var shield := ShieldRuntime.new()
	shield.configure(&"stage_10")
	shield.begin_phase(1)
	_expect(shield.state() == &"shield_down", "Stage 10 begins fully exposed")
	shield.advance(13.99)
	_expect(shield.state() == &"shield_down", "Stage 10 remains fully down before its final cue second")
	shield.advance(0.01)
	_expect(shield.state() == &"shield_cue", "Stage 10 cues for the final exposed second")
	shield.advance(1.0)
	_expect(shield.state() == &"shield_up", "Stage 10 activates segmented reflection after fifteen exposed seconds")
	shield.advance(4.99)
	_expect(shield.state() == &"shield_up", "Stage 10 reflection remains active for five seconds")
	shield.advance(0.01)
	_expect(shield.state() == &"shield_down", "Stage 10 returns to its full down window at twenty seconds")
	_expect(is_equal_approx(LateMechanics.reflected_damage(100.0), 24.0), "reflection damage remains capped at 24")


func _validate_wall_scales() -> void:
	_expect(
		is_equal_approx(LateMechanics.crossing_wall_speed(), 224.0)
			and is_equal_approx(LateMechanics.crossing_wall_damage(100.0), 70.0),
		"Stage 7 wall speed and damage are exactly seventy percent of baseline"
	)
	_expect(
		is_equal_approx(LateMechanics.compression_wall_speed(), 434.0)
			and is_equal_approx(LateMechanics.compression_wall_damage(100.0), 70.0),
		"Stage 9 wall speed and damage are exactly seventy percent of baseline"
	)


func _validate_state_mechanics() -> void:
	_expect(
		is_equal_approx(LateMechanics.resonance_damage_multiplier(500.0, 0.0), 1.0)
			and is_equal_approx(LateMechanics.resonance_damage_multiplier(300.0, 0.0), 0.2),
		"base resonance band applies full and reduced damage"
	)
	_expect(LateMechanics.resonance_band(8.0) == Vector2(520.0, 880.0), "resonance alternates to the shifted band")
	_expect(
		not LateMechanics.overload_active(11.99)
			and LateMechanics.overload_active(12.0)
			and not LateMechanics.overload_active(18.0)
			and LateMechanics.overload_active(30.0),
		"overload begins after 12 seconds and repeats every 18 seconds for six seconds"
	)


func _validate_world_execution() -> void:
	var stage := StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	var stage_ui = stage.get("_ui")
	stage_ui.call("show_deployment", &"pulse_cannon")
	stage_ui.call("debug_submit_deployment")

	stage.current_stage_index = 9
	stage.current_stage_id = &"stage_10"
	stage.boss_shield_runtime.configure(&"stage_10")
	stage.boss_shield_runtime.begin_phase(1)
	stage.boss_shield_runtime.advance(15.0)
	var reflect_boss = stage.call("_make_enemy", {
		"id":"reflect_boss", "role":&"boss_actor", "pos":Vector2.ZERO,
	})
	var defense: Dictionary = stage.boss_shield_runtime.presentation_snapshot()
	var source_angle := (
		float(defense["rotation"])
		+ float(defense["gap_arc"])
		+ float(defense["segment_arc"]) * 0.5
	)
	var source_direction := Vector2.from_angle(source_angle)
	var projectile := ProjectileState.new()
	projectile.configure({
		"pos":source_direction * 100.0,
		"velocity":-source_direction * 700.0,
		"radius":6.0,
		"damage":100.0,
		"life":1.4,
		"owner":"player_primary",
		"affinity":&"kinetic",
	}, &"player", 1)
	var hostile_before: int = stage.hostile_projectiles.size()
	_expect(
		bool(stage.call("_try_reflect_direct_projectile", reflect_boss, projectile)),
		"Stage 10 reflects a primary projectile that hits a live segment"
	)
	_expect(stage.hostile_projectiles.size() == hostile_before + 1, "reflection transfers the shot to hostile storage")
	var reflected = stage.hostile_projectiles[-1]
	_expect(
		reflected.reflected
			and is_equal_approx(reflected.damage, 24.0)
			and is_equal_approx(reflected.life, 1.4)
			and is_equal_approx(reflected.velocity.length(), 700.0),
		"reflected projectile preserves speed and life and cannot reflect again"
	)
	var gap_direction := Vector2.from_angle(
		float(defense["rotation"]) + float(defense["gap_arc"]) * 0.5
	)
	var gap_projectile := ProjectileState.new()
	gap_projectile.configure({
		"pos":gap_direction * 100.0,
		"velocity":-gap_direction * 700.0,
		"radius":6.0,
		"damage":100.0,
		"life":1.4,
		"owner":"player_primary",
		"affinity":&"kinetic",
	}, &"player", 2)
	_expect(
		not bool(stage.call("_try_reflect_direct_projectile", reflect_boss, gap_projectile)),
		"Stage 10 reflection gaps remain valid direct attack routes"
	)

	stage.current_stage_index = 10
	var resonance_boss = stage.call("_make_enemy", {
		"id":"resonance_boss", "role":&"boss_actor", "pos":Vector2.ZERO,
	})
	stage.player_position = Vector2(500.0, 0.0)
	var in_band_damage := float(stage.call("_damage_enemy", resonance_boss, 100.0, "validation", &"kinetic", true))
	resonance_boss.health = resonance_boss.max_health
	stage.player_position = Vector2(300.0, 0.0)
	var out_of_band_damage := float(stage.call("_damage_enemy", resonance_boss, 100.0, "validation", &"kinetic", true))
	_expect(
		is_equal_approx(in_band_damage, 100.0)
			and is_equal_approx(out_of_band_damage, 20.0),
		"Stage 11 resonance band changes actual received damage"
	)

	stage.current_stage_index = 11
	var overload_boss = stage.call("_make_enemy", {
		"id":"overload_boss", "role":&"boss_actor", "pos":Vector2.ZERO,
	})
	overload_boss.pattern_timer = 12.0
	var overload_damage := float(stage.call("_damage_enemy", overload_boss, 100.0, "validation", &"kinetic", true))
	_expect(is_equal_approx(overload_damage, 150.0), "Stage 12 overload changes actual received damage")

	stage.current_stage_index = 8
	stage.denied_zones.clear()
	stage.call("_append_boss_compression", {
		"id":"compression_probe",
		"pattern":"compression_pair",
		"duration":1.45,
		"damage":66.0,
		"affinity":&"kinetic",
		"commit_mode":&"autonomous",
	})
	_expect(stage.denied_zones.size() == 4, "compression pair owns two delayed slabs with one gap each")
	for zone in stage.denied_zones:
		_expect(
			is_equal_approx(float(zone["width"]), 180.0)
				and is_equal_approx(float(zone["safe_gap"]), 360.0)
				and is_equal_approx(Vector2(zone["motion"]).length(), 434.0)
				and is_equal_approx(float(zone["damage"]), 46.2),
			"Stage 9 compression keeps geometry while speed and damage use the 0.70 scale"
		)
	_expect(
		is_equal_approx(
			float(stage.denied_zones[2]["warning"])
				- float(stage.denied_zones[0]["warning"]),
			0.45
		),
		"paired compression slabs remain at least 0.45 seconds apart"
	)

	stage.current_stage_index = 6
	stage.denied_zones.clear()
	stage.call("_append_boss_crossing_weave", {
		"id":"weave_probe",
		"pattern":"crossing_weave_a",
		"origin":Vector2.ZERO,
		"target":Vector2.RIGHT * 400.0,
		"startup":1.30,
		"duration":1.55,
		"damage":68.0,
		"affinity":&"arc",
		"commit_mode":&"autonomous",
	})
	_expect(stage.denied_zones.size() == 8, "Stage 7 crossing weave retains both wall passes and their gaps")
	for zone in stage.denied_zones:
		_expect(
			is_equal_approx(Vector2(zone["motion"]).length(), 224.0)
				and is_equal_approx(float(zone["damage"]), 47.6),
			"Stage 7 wall speed and damage use the exact 0.70 scale"
		)

	stage.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_LATE_BOSS_MECHANICS_CORRECTION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
