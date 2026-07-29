class_name VehiclePerformanceScenario
extends RefCounted

## Creates deterministic, visible pressure through the production simulation.
## It never changes ordinary runs and does not disable attacks or collisions.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")
const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")

const CURRENT_PRESSURE_TARGET := 280
const CAPACITY_PRESSURE_TARGET := EnemyStore.MAX_LIVE_HOSTILES
const ORDINARY_CAPACITY_LOAD := 280

const VALID_SCENARIOS: Array[StringName] = [
	&"current_pressure", &"capacity_pressure", &"lifecycle_pressure", &"boss_pressure",
]
const MOBILE_ARCHETYPES: Array[StringName] = [
	&"scrap_drone", &"needle_drone", &"chaser", &"shooter", &"controller",
	&"shield_escort", &"artillery_spotter", &"rammer", &"repair_tender",
	&"drone_carrier",
]
const STATIONARY_ARCHETYPES: Array[StringName] = [
	# One-shot mines retire themselves during long samples, so the fixed-count
	# capacity fixture uses non-retiring installations.
	&"turret", &"generator", &"interceptor_tower", &"beam_sentinel",
]

var scenario_id: StringName
var elapsed := 0.0
var lifecycle_cycles := 0
var _shot_serial := 0
var _lifecycle_serial := 0
var _lifecycle_timer := 0.0
var _spawn_points: Array[Vector2] = []


func configure(id: StringName) -> bool:
	if id not in VALID_SCENARIOS:
		return false
	scenario_id = id
	return true


func activate(run: Node) -> void:
	run.call("_start_deployed_run", &"pulse_cannon", RunDifficulty.HARD)
	run.encounter_runtime.stop_spawning()
	run.player_barrier_strength = 1.0e9
	run.player_barrier_timer = 1.0e9
	# Synthetic projectile pressure already owns the exact workload count.
	run.player_passive_cooldown = 1.0e9
	run.call("_clear_enemies")
	run.call("_clear_projectiles")
	run.experience_runtime.clear_shards()
	run.effects.clear()
	run.denied_zones.clear()
	run.damaging_trails.clear()
	_spawn_points = _walkable_ring_points(run, 160)
	if scenario_id == &"lifecycle_pressure":
		_run_lifecycle_cycles(run, 300)
	var enemy_target := (
		CURRENT_PRESSURE_TARGET
		if scenario_id == &"current_pressure"
		else CAPACITY_PRESSURE_TARGET
	)
	if scenario_id == &"boss_pressure":
		enemy_target = 77
	_fill_enemies(run, enemy_target, scenario_id == &"boss_pressure")
	_fill_experience(run, 96 if scenario_id in [&"current_pressure", &"boss_pressure"] else ExperienceRuntime.MAX_SHARDS)
	_fill_effects(run, 48 if scenario_id in [&"current_pressure", &"boss_pressure"] else 96)
	_fill_zones_and_trails(run, 8 if scenario_id in [&"current_pressure", &"boss_pressure"] else 16)
	run.run_build.apply(&"ion_field")
	run.run_build.apply(&"orbit_blades")
	run.call("_sync_cycle_upgrades")
	run.call("_rebuild_enemy_runtime_indexes")
	_fill_projectiles(run, true)


func before_physics(run: Node, delta: float) -> void:
	elapsed += delta
	var center := Rules.player_start(run.current_stage_id)
	var route := Vector2(cos(elapsed * 0.31) * 120.0, sin(elapsed * 0.47) * 80.0)
	run.player_position = center + route
	run.player_hull_direction = Vector2(-sin(elapsed * 0.31), cos(elapsed * 0.47)).normalized()
	run.player_aim_direction = Vector2.RIGHT.rotated(elapsed * 0.73)
	run.player_barrier_strength = maxf(run.player_barrier_strength, 1.0e8)
	run.player_barrier_timer = 1.0e9
	if scenario_id == &"lifecycle_pressure":
		_lifecycle_timer -= delta
		if _lifecycle_timer <= 0.0:
			_lifecycle_timer += 0.25
			_churn_one_enemy(run)
	_maintain_effects(run)


func after_physics(run: Node) -> void:
	_fill_projectiles(run, false)


func validation_snapshot(run: Node) -> Dictionary:
	var expected_enemies := (
		CURRENT_PRESSURE_TARGET
		if scenario_id == &"current_pressure"
		else CAPACITY_PRESSURE_TARGET
	)
	if scenario_id == &"boss_pressure":
		expected_enemies = 77
	var player_target := 140 if scenario_id in [&"current_pressure", &"boss_pressure"] else ProjectileStore.PLAYER_CAPACITY
	var hostile_target := 72 if scenario_id == &"current_pressure" else ProjectileStore.HOSTILE_CAPACITY
	if scenario_id == &"boss_pressure":
		hostile_target = 100
	var enemy_snapshot: Dictionary = run.enemy_store.debug_snapshot()
	var projectile_snapshot: Dictionary = run.projectile_store.debug_snapshot()
	var renderer_snapshot: Dictionary = run._combat_renderer.debug_snapshot()
	var ordinary_count := 0
	var auxiliary_count := 0
	var boss_count := 0
	for enemy in run.enemies:
		match enemy.role:
			&"stage_boss":
				boss_count += 1
			&"boss_pylon":
				auxiliary_count += 1
			_:
				ordinary_count += 1
	var expected_ordinary := mini(
		ORDINARY_CAPACITY_LOAD,
		expected_enemies - (1 if scenario_id == &"boss_pressure" else 0)
	)
	var expected_auxiliary := expected_enemies - expected_ordinary - (1 if scenario_id == &"boss_pressure" else 0)
	var boss_valid := true
	if scenario_id == &"boss_pressure":
		var boss: EnemyState = run.call("_find_enemy_by_id", "performance_boss")
		boss_valid = boss != null and boss.alive
	var pressure := EncounterRuntime.build_pressure_snapshot(
		ordinary_count,
		run.enemies,
		run.player_position,
		run.call("_visible_world_rect", 0.0),
		run.projectile_store.hostile_count()
	)
	var valid: bool = (
		int(enemy_snapshot["live"]) == expected_enemies
		and ordinary_count == expected_ordinary
		and auxiliary_count == expected_auxiliary
		and boss_count == (1 if scenario_id == &"boss_pressure" else 0)
		and int(projectile_snapshot["player"]) == player_target
		and int(projectile_snapshot["hostile"]) == hostile_target
		and run.projectile_store.validate_counts()
		and run.experience_runtime.shards.size() <= ExperienceRuntime.MAX_SHARDS
		and run.experience_runtime.validate_capacity()
		and run.effects.size() <= 96
		and run.denied_zones.size() + run.damaging_trails.size() <= 16
		and int(renderer_snapshot["batches"]) <= 51
		and int(enemy_snapshot["rejected_capacity"]) == 0
		and int(renderer_snapshot["enemy_capacity"]) == EnemyStore.MAX_LIVE_HOSTILES
		and boss_valid
		and (scenario_id != &"lifecycle_pressure" or lifecycle_cycles >= 300)
	)
	return {
		"valid": valid,
		"expected_enemies": expected_enemies,
		"ordinary_enemies": ordinary_count,
		"auxiliary_enemies": auxiliary_count,
		"boss_enemies": boss_count,
		"expected_player_projectiles": player_target,
		"expected_hostile_projectiles": hostile_target,
		"enemies": enemy_snapshot,
		"projectiles": projectile_snapshot,
		"experience": run.experience_runtime.shards.size(),
		"effects": run.effects.size(),
		"zones_and_trails": run.denied_zones.size() + run.damaging_trails.size(),
		"lifecycle_cycles": lifecycle_cycles,
		"boss_active": boss_valid,
		"pressure": pressure,
	}


func _fill_enemies(run: Node, target: int, include_boss: bool) -> void:
	var boss_slots := 1 if include_boss else 0
	var ordinary_target := mini(ORDINARY_CAPACITY_LOAD, target - boss_slots)
	for index in ordinary_target:
		var archetype := (
			STATIONARY_ARCHETYPES[index % STATIONARY_ARCHETYPES.size()]
			if index < 4
			else MOBILE_ARCHETYPES[index % MOBILE_ARCHETYPES.size()]
		)
		var enemy: EnemyState = run.call("_make_enemy", {
			"id": "performance_enemy_%03d" % index,
			"role": archetype,
			"pos": _spawn_points[index % _spawn_points.size()],
			"active": true,
		})
		if enemy == null:
			break
		enemy.active = true
		enemy.counts_active_cap = false
		enemy.health = 1000000.0
		enemy.max_health = 1000000.0
		run.call("_append_enemy", enemy)
	var auxiliary_target := target - ordinary_target - boss_slots
	for index in auxiliary_target:
		var auxiliary: EnemyState = run.call("_make_enemy", {
			"id": "performance_auxiliary_%03d" % index,
			"role": &"boss_pylon",
			"pos": _spawn_points[(ordinary_target + index) % _spawn_points.size()],
			"active": true,
		})
		if auxiliary == null:
			break
		auxiliary.active = true
		auxiliary.counts_active_cap = false
		auxiliary.health = 1000000.0
		auxiliary.max_health = 1000000.0
		auxiliary.support_tick = 1000000.0
		run.call("_append_enemy", auxiliary)
	if include_boss:
		var boss: EnemyState = run.call("_make_enemy", {
			"id": "performance_boss",
			"role": &"stage_boss",
			"pos": _spawn_points[ordinary_target % _spawn_points.size()],
			"active": true,
		})
		if boss == null:
			return
		boss.active = true
		boss.health = 1000000.0
		boss.max_health = 1000000.0
		boss.phase = &"boss_read"
		boss.phase_time = 0.0
		run.call("_append_enemy", boss)


func _run_lifecycle_cycles(run: Node, count: int) -> void:
	for index in count:
		var enemy: EnemyState = run.call("_make_enemy", {
			"id": "performance_retired_%03d" % index,
			"role": MOBILE_ARCHETYPES[index % MOBILE_ARCHETYPES.size()],
			"pos": _spawn_points[index % _spawn_points.size()],
			"active": true,
		})
		if enemy == null:
			break
		enemy.active = true
		if run.call("_append_enemy", enemy):
			enemy.alive = false
			run.enemy_store.queue_defeat(enemy)
			run.enemy_store.flush_defeated()
			lifecycle_cycles += 1


func _churn_one_enemy(run: Node) -> void:
	var retired: EnemyState
	for enemy in run.enemies:
		if enemy.role != &"boss_pylon":
			retired = enemy
			break
	if retired == null:
		return
	var role := retired.role
	var position := retired.pos
	retired.alive = false
	run.enemy_store.queue_defeat(retired)
	if run.enemy_store.flush_defeated() != 1:
		return
	var replacement: EnemyState = run.call("_make_enemy", {
		"id": "performance_churn_%06d" % _lifecycle_serial,
		"role": role,
		"pos": position,
		"active": true,
	})
	if replacement == null:
		return
	_lifecycle_serial += 1
	replacement.active = true
	replacement.counts_active_cap = false
	replacement.health = 1000000.0
	replacement.max_health = 1000000.0
	if run.call("_append_enemy", replacement):
		lifecycle_cycles += 1


func _fill_projectiles(run: Node, initial: bool) -> void:
	var player_target := 140 if scenario_id in [&"current_pressure", &"boss_pressure"] else ProjectileStore.PLAYER_CAPACITY
	var hostile_target := 72 if scenario_id == &"current_pressure" else ProjectileStore.HOSTILE_CAPACITY
	if scenario_id == &"boss_pressure":
		hostile_target = 100
	var player_budget := player_target if initial else 48
	while run.projectile_store.player_count() < player_target and player_budget > 0:
		var direction := Vector2.RIGHT.rotated(float(_shot_serial % 72) * TAU / 72.0)
		var origin := _performance_projectile_origin(_shot_serial)
		run.call("_spawn_player_projectile", origin, direction, 0.01, 4.0, 0, 3.0, 0.01, 0.0, false, 100000.0, null)
		_shot_serial += 1
		player_budget -= 1
	var hostile_budget := hostile_target if initial else 8
	while run.projectile_store.hostile_count() < hostile_target and hostile_budget > 0:
		var origin := _spawn_points[_shot_serial % _spawn_points.size()]
		var direction: Vector2 = (run.player_position - origin).normalized()
		var uses_reserve: bool = run.projectile_store.hostile_count() >= ProjectileStore.HOSTILE_CAPACITY - ProjectileStore.HOSTILE_BOSS_RESERVE
		run.call(
			"_spawn_hostile_projectile",
			origin,
			direction,
			1.0,
			420.0,
			"performance_volley",
			AttackContract.KINETIC,
			uses_reserve
		)
		_shot_serial += 1
		hostile_budget -= 1


func _performance_projectile_origin(index: int) -> Vector2:
	var anchors: Array[Vector2] = [
		Vector2(430.0, 430.0), Vector2(5170.0, 430.0),
		Vector2(430.0, 2970.0), Vector2(5170.0, 2970.0),
	]
	var local_index := index % 60
	var offset := Vector2(float(local_index % 10) - 4.5, float(local_index / 10) - 2.5) * 18.0
	return anchors[(index / 60) % anchors.size()] + offset


func _fill_experience(run: Node, target: int) -> void:
	for index in target:
		run.experience_runtime.spawn_shard(_spawn_points[index % _spawn_points.size()], 1 + index % 7)


func _fill_effects(run: Node, target: int) -> void:
	for index in target:
		run.call(
			"_add_effect",
			"shock" if index % 3 else "impact",
			_spawn_points[index % _spawn_points.size()],
			Art.MUSTARD if index % 2 else Art.MINT,
			2.0 + float(index % 5) * 0.2,
			18.0 + float(index % 4) * 6.0
		)


func _maintain_effects(run: Node) -> void:
	var target := 48 if scenario_id in [&"current_pressure", &"boss_pressure"] else 96
	var budget := 4
	while run.effects.size() < target and budget > 0:
		var index := _shot_serial % _spawn_points.size()
		run.call("_add_effect", "shock", _spawn_points[index], Art.MINT, 2.0, 24.0)
		_shot_serial += 1
		budget -= 1


func _fill_zones_and_trails(run: Node, target: int) -> void:
	for index in target:
		var position := _spawn_points[index % _spawn_points.size()]
		if index % 2 == 0:
			run.denied_zones.append({
				"pos": position, "radius": 46.0, "warning": 0.0,
				"duration": 100000.0, "tick": 0.2, "damage": 0.1,
				"source": "performance_zone",
				"color": Art.CORAL,
			})
		else:
			run.damaging_trails.append({
				"pos": position, "radius": 42.0,
				"time": 100000.0, "duration": 100000.0, "hit_ids": {},
			})


func _walkable_ring_points(run: Node, target: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var center := Rules.player_start(run.current_stage_id)
	var radius := 340.0
	while result.size() < target and radius < 2100.0:
		for index in 48:
			var angle := TAU * float(index) / 48.0 + radius * 0.0007
			var candidate := center + Vector2.RIGHT.rotated(angle) * radius
			if Rules.is_position_walkable(candidate, 38.0, run.current_stage_id):
				result.append(candidate)
				if result.size() >= target:
					break
		radius += 115.0
	if result.is_empty():
		result.append(center + Vector2(500.0, 0.0))
	return result
