extends SceneTree

const Run = preload("res://scripts/vehicle/vehicle_run.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const ContactRuntime = preload("res://scripts/enemies/vehicle_enemy_contact_runtime.gd")
const MovementPolicy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var run = Run.new()
	run.player_position = Vector2(600.0, 0.0)
	_validate_ranged_specialists(run)
	_validate_ordinary_sweep_01(run)
	_validate_family_direct_attacks(run)
	_validate_paired_defender_priority(run)
	_validate_pursuit_collective_ownership(run)
	_validate_boss_add_metadata(run)
	_validate_growth_enemy(run)
	_finish()


func _enemy(id: String, role: StringName, position: Vector2) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = id
	enemy.role = role
	enemy.archetype = role
	enemy.pos = position
	enemy.speed = 160.0
	enemy.radius = 20.0
	enemy.alive = true
	enemy.active = true
	enemy.committed_dir = Vector2.RIGHT
	enemy.committed_target = Vector2(600.0, 0.0)
	return enemy


func _validate_ranged_specialists(run) -> void:
	var rail := _enemy("rail", &"ordinary_beam_01", Vector2.ZERO)
	run.call("_begin_enemy_active", rail)
	_expect(run.hostile_projectiles.size() == 1, "Beam Ordinary Enemy Lv.1 creates one committed hostile shot")
	_expect(rail.phase == &"recovery" and rail.reposition_time > 0.0, "Beam Ordinary Enemy Lv.1 enters relocation recovery after firing")

	var orbit := _enemy("orbit", &"ordinary_range_01", Vector2.ZERO)
	run.call("_begin_enemy_active", orbit)
	for _tick in 3:
		run.call("_update_enemy_active", orbit, 0.13)
	_expect(run.hostile_projectiles.size() == 4, "Range Ordinary Enemy Lv.1 creates exactly one three-shot burst")
	_expect(orbit.phase == &"recovery", "Range Ordinary Enemy Lv.1 enters recovery after the burst")


func _validate_ordinary_sweep_01(run) -> void:
	var bomber := _enemy("bomber", &"ordinary_sweep_01", Vector2.ZERO)
	run.call("_begin_enemy_active", bomber)
	_expect(run.denied_zones.size() == 3, "Sweep Ordinary Enemy Lv.1 schedules exactly three delayed ground bursts")
	_expect(run.denied_zones.all(func(zone): return StringName(zone["owner_kind"]) == &"ordinary" and float(zone["warning"]) > 0.0), "bombing ground bursts remain ordinary-owned warning zones")
	var first_zone: Dictionary = run.denied_zones[0]
	var expected_warning := AttackContract.bombardment_warning(0.48)
	_expect(
		is_equal_approx(float(first_zone["warning"]), expected_warning),
		"the first sweep burst exposes the shared 1.23-second warning"
	)
	run.call("_update_denied_zones", expected_warning - 0.01)
	_expect(
		not bool(first_zone.get("hit_committed", false)),
		"the sweep cannot damage during its visible warning"
	)
	run.call("_update_denied_zones", 0.02)
	_expect(
		not bool(first_zone.get("hit_committed", false)),
		"warning expiry activates the sweep without same-frame damage"
	)
	run.call("_update_denied_zones", 0.01)
	_expect(
		bool(first_zone.get("hit_committed", false)),
		"the sweep can commit damage only after the warning has expired"
	)
	run.call("_update_enemy_active", bomber, 0.8)
	_expect(bomber.phase == &"recovery", "Sweep Ordinary Enemy Lv.1 completes its forward pass before recovering")


func _validate_family_direct_attacks(run) -> void:
	var projectile_count: int = run.hostile_projectiles.size()
	var coordinator := _enemy("coordinator", &"ordinary_pulse_01", Vector2.ZERO)
	coordinator.family = &"coordinator"
	run.call("_begin_enemy_active", coordinator)
	_expect(
		run.hostile_projectiles.size() == projectile_count + 1
			and coordinator.phase == &"recovery"
			and is_equal_approx(coordinator.phase_time, 1.50 * 0.90),
		"coordinator commits one visible direct projectile and scaled recovery"
	)

	var defender := _enemy("defender", &"ordinary_shield_01", Vector2.ZERO)
	defender.family = &"defender"
	run.call("_begin_enemy_active", defender)
	run.call("_update_enemy_active", defender, 0.25)
	_expect(
		defender.contact_attack == ContactRuntime.ATTACK_SHIELD_BASH
			and defender.phase == &"recovery"
			and is_equal_approx(defender.phase_time, 1.40 * 0.90),
		"unpaired defender commits the warned shield bash and scaled recovery"
	)

	var zone_count: int = run.denied_zones.size()
	var projectile_count_before_artillery: int = run.hostile_projectiles.size()
	var artillery = run.call("_make_enemy", {
		"id":"artillery", "role":&"ordinary_emitter_t1",
		"family":&"emitter", "family_trait":&"artillery",
		"pos":Vector2.ZERO, "active":true,
	})
	_expect(
		artillery != null
			and artillery.role == &"ordinary_growth_01"
			and artillery.threat_kind == &"denial",
		"artillery is canonically classified into the marked-impact denial lane"
	)
	artillery.committed_target = Vector2(420.0, 0.0)
	run.call("_start_enemy_attack", artillery)
	_expect(
		artillery.phase == &"startup"
			and is_equal_approx(artillery.phase_time, 1.90)
			and artillery.attack_telegraphs.size() == 1
			and StringName(artillery.attack_telegraphs[0]["shape"]) == &"area",
		"artillery publishes its exact footprint for the added warning interval"
	)
	artillery.committed_target = Vector2(420.0, 0.0)
	run.call("_begin_enemy_active", artillery)
	_expect(
		run.denied_zones.size() == zone_count + 1
			and Vector2(run.denied_zones[-1]["pos"]) == artillery.committed_target
			and is_zero_approx(float(run.denied_zones[-1]["warning"]))
			and run.hostile_projectiles.size() == projectile_count_before_artillery,
		"artillery activates its committed ground mark instead of a moving shell"
	)


func _validate_paired_defender_priority(run) -> void:
	run.call("_clear_enemies")
	run.player_position = Vector2(600.0, 0.0)
	var emitter = run.call("_make_enemy", {
		"id":"paired_emitter", "role":&"ordinary_emitter_t1",
		"family":&"emitter", "pos":Vector2(400.0, 0.0), "active":true,
		"squad_id":"paired_squad",
	})
	var defender = run.call("_make_enemy", {
		"id":"paired_defender", "role":&"ordinary_defender_t1",
		"family":&"defender", "pos":Vector2(500.0, 0.0), "active":true,
		"squad_id":"paired_squad", "escort_target_id":"paired_emitter",
	})
	_expect(run.call("_append_enemy", emitter), "paired emitter enters the runtime store")
	_expect(run.call("_append_enemy", defender), "paired defender enters the runtime store")
	var escort_velocity: Vector2 = run.call("_desired_enemy_velocity", defender, false)
	_expect(
		escort_velocity.x < 0.0 and not bool(run.call("_enemy_can_attack", defender)),
		"paired defender returns to the player-facing screen point and does not attack"
	)
	emitter.alive = false
	var pursuit_velocity: Vector2 = run.call("_desired_enemy_velocity", defender, false)
	_expect(
		pursuit_velocity.x > 0.0 and bool(run.call("_enemy_can_attack", defender)),
		"defender pursues and gains bash permission only after its paired emitter is gone"
	)
	run.call("_clear_enemies")


func _validate_pursuit_collective_ownership(run) -> void:
	var pursuer := _enemy("pursuer", &"ordinary_edge_01", Vector2.ZERO)
	pursuer.family = &"pursuer"
	pursuer.movement_family = MovementPolicy.PURSUIT
	pursuer.collective_phase = &"gather"
	pursuer.collective_mode = &"screen"
	_expect(
		not bool(run.call("_update_collective_enemy", pursuer, 0.0)),
		"collective gather cannot preempt pursuer approach"
	)
	pursuer.collective_phase = &"execute"
	pursuer.collective_mode = &"charge"
	_expect(
		bool(run.call("_update_collective_enemy", pursuer, 0.0)),
		"committed collective charge can temporarily own pursuer motion"
	)


func _validate_boss_add_metadata(run) -> void:
	run.call("_clear_enemies")
	run.current_stage_index = 1
	var boss := _enemy("boss", &"boss", Vector2(900.0, 500.0))
	boss.boss_phase = 2
	run.call("_spawn_boss_phase_adds", boss, [
		&"ordinary_emitter_t1", &"ordinary_defender_t1",
	], &"shielded_column")
	var emitter = run.call("_find_enemy_by_id", "boss_wave_p2_00")
	var defender = run.call("_find_enemy_by_id", "boss_wave_p2_01")
	_expect(
		emitter != null and defender != null
			and emitter.family == &"emitter"
			and defender.family == &"defender"
			and defender.escort_target_id == emitter.id,
		"boss adds retain per-enemy family identity and exact emitter escort binding"
	)
	run.call("_clear_enemies")


func _validate_growth_enemy(run) -> void:
	var growth_enemy := _enemy("growth_enemy", &"ordinary_melee_02", Vector2.ZERO)
	var victim := _enemy("victim", &"ordinary_lane_01", Vector2(120.0, 0.0))
	run.enemies.append(growth_enemy)
	for _count in SpecialistRuntime.MELEE_GROWTH_MAX_STACKS + 2:
		run.call("_notify_ordinary_melee_02s_of_defeat", victim)
	_expect(run.call("_ordinary_melee_02_stack_count", growth_enemy) == SpecialistRuntime.MELEE_GROWTH_MAX_STACKS, "Melee Ordinary Enemy Lv.2 claims nearby eligible deaths before retirement and caps at five")
	_expect(is_equal_approx(float(run.call("_ordinary_melee_02_damage_multiplier", growth_enemy)), 1.6), "five wreck stacks apply the configured damage modifier")
	_expect(is_equal_approx(float(run.call("_ordinary_melee_02_speed_multiplier", growth_enemy)), 1.25), "five wreck stacks apply the configured speed modifier")
	_expect(is_equal_approx(float(run.call("_ordinary_melee_02_attack_interval_multiplier", growth_enemy)), 0.8), "five wreck stacks apply the configured cooldown modifier")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SPECIALIST_ENEMY_INTEGRATION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
