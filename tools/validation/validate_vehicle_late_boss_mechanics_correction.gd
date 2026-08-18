extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const LateMechanics = preload("res://scripts/bosses/vehicle_late_boss_mechanics.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_sequences := {
		&"stage_9":["compression_single", "compression_shift", "compression_pair", "compression_reverse", "compression_break"],
		&"stage_10":["reflect_lance", "reflect_fan", "reflect_break", "reflect_crossfire", "reflect_reposition"],
		&"stage_11":["resonance_lanes", "resonance_pulse", "resonance_fan", "resonance_cross", "resonance_break"],
		&"stage_12":["overload_rush", "overload_crossfire", "overload_break", "overload_crossfire_shift", "overload_rush_return"],
	}
	for stage_id in expected_sequences:
		var sequence := Patterns.sequence(stage_id)
		_expect(sequence == expected_sequences[stage_id], "%s uses only its dedicated sequence" % stage_id)
		_expect("common_charge" not in sequence and "common_broad_barrage" not in sequence, "%s removes common attacks" % stage_id)

	_expect(LateMechanics.reflection_active(0.0) and not LateMechanics.reflection_active(6.0) and LateMechanics.reflection_active(8.0), "reflection uses a six-on two-off cycle")
	_expect(LateMechanics.hits_reflection_plate(Vector2.RIGHT, Vector2.LEFT, 0.0), "reflection accepts a frontal direct projectile")
	_expect(not LateMechanics.hits_reflection_plate(Vector2.RIGHT, Vector2.UP, 0.0), "reflection leaves the flank open")
	_expect(is_equal_approx(LateMechanics.reflected_damage(100.0), 24.0), "reflection damage is capped at 24")
	_expect(is_equal_approx(LateMechanics.resonance_damage_multiplier(500.0, 0.0), 1.0) and is_equal_approx(LateMechanics.resonance_damage_multiplier(300.0, 0.0), 0.2), "base resonance band applies full and reduced damage")
	_expect(LateMechanics.resonance_band(8.0) == Vector2(520.0, 880.0), "resonance alternates to the shifted band")
	_expect(not LateMechanics.overload_active(11.99) and LateMechanics.overload_active(12.0) and not LateMechanics.overload_active(18.0) and LateMechanics.overload_active(30.0), "overload begins after 12 seconds and repeats every 18 seconds for six seconds")

	for stage_index in range(8, 12):
		var teaching_role: StringName = CombatStages.BOSS_TUTOR_ROLES[stage_index]
		var sequence := CombatStages._role_sequence_for_arc(stage_index, CombatStages.QUOTAS[stage_index])
		_expect(sequence.count(teaching_role) >= 4, "stage %d admits its teaching role at least four times" % (stage_index + 1))

	var stage := StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	var stage_ui = stage.get("_ui")
	stage_ui.call("show_deployment", &"pulse_cannon")
	stage_ui.call("debug_submit_deployment")

	stage.current_stage_index = 9
	var reflect_boss = stage.call("_make_enemy", {"id":"reflect_boss", "role":&"boss_actor", "pos":Vector2.ZERO})
	reflect_boss.presentation_facing = Vector2.RIGHT
	var projectile := ProjectileState.new()
	projectile.configure({"pos":Vector2(100.0, 0.0), "velocity":Vector2.LEFT * 700.0, "radius":6.0, "damage":100.0, "life":1.4, "owner":"player_primary", "affinity":&"kinetic"}, &"player", 1)
	var hostile_before: int = stage.hostile_projectiles.size()
	_expect(bool(stage.call("_try_reflect_direct_projectile", reflect_boss, projectile)), "stage 10 boss reflects a frontal primary projectile")
	_expect(stage.hostile_projectiles.size() == hostile_before + 1, "reflection transfers the shot to hostile storage")
	var reflected = stage.hostile_projectiles[-1]
	_expect(reflected.reflected and is_equal_approx(reflected.damage, 24.0) and is_equal_approx(reflected.life, 1.4) and is_equal_approx(reflected.velocity.length(), 700.0), "reflected projectile preserves speed/life and cannot reflect again")

	stage.current_stage_index = 10
	var resonance_boss = stage.call("_make_enemy", {"id":"resonance_boss", "role":&"boss_actor", "pos":Vector2.ZERO})
	stage.player_position = Vector2(500.0, 0.0)
	var in_band_damage := float(stage.call("_damage_enemy", resonance_boss, 100.0, "validation", &"kinetic", true))
	resonance_boss.health = resonance_boss.max_health
	stage.player_position = Vector2(300.0, 0.0)
	var out_of_band_damage := float(stage.call("_damage_enemy", resonance_boss, 100.0, "validation", &"kinetic", true))
	_expect(is_equal_approx(in_band_damage, 100.0) and is_equal_approx(out_of_band_damage, 20.0), "stage 11 resonance band changes actual received damage")

	stage.current_stage_index = 11
	var overload_boss = stage.call("_make_enemy", {"id":"overload_boss", "role":&"boss_actor", "pos":Vector2.ZERO})
	overload_boss.pattern_timer = 12.0
	var overload_damage := float(stage.call("_damage_enemy", overload_boss, 100.0, "validation", &"kinetic", true))
	_expect(is_equal_approx(overload_damage, 150.0), "stage 12 overload changes actual received damage")

	stage.current_stage_index = 8
	stage.denied_zones.clear()
	stage.call("_append_boss_compression", {"id":"compression_probe", "pattern":"compression_pair", "duration":1.45, "damage":66.0, "affinity":&"kinetic", "commit_mode":&"autonomous"})
	_expect(stage.denied_zones.size() == 4, "compression pair owns two delayed slabs with one gap each")
	for zone in stage.denied_zones:
		_expect(is_equal_approx(float(zone["width"]), 180.0) and is_equal_approx(float(zone["safe_gap"]), 360.0), "compression slab uses exact depth and gap")
	_expect(is_equal_approx(float(stage.denied_zones[2]["warning"]) - float(stage.denied_zones[0]["warning"]), 0.45), "paired slabs enter at least 0.45 seconds apart")

	stage.queue_free()
	_finish()


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
