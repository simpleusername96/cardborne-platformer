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
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const PressureFixture = preload("res://scripts/performance/vehicle_pressure_fixture.gd")

const PEAK_HORDE_TARGET := PressureFixture.PEAK_ORDINARY_COUNT
const CAPACITY_PRESSURE_TARGET := EnemyStore.MAX_LIVE_HOSTILES
const ORDINARY_CAPACITY_LOAD := PressureFixture.CAPACITY_ORDINARY_COUNT
const BOSS_PRESSURE_TARGET := PressureFixture.BOSS_ORDINARY_COUNT + 1

const VALID_SCENARIOS: Array[StringName] = [
	&"production_replay", &"peak_horde", &"capacity_pressure",
	&"lifecycle_pressure", &"boss_pressure",
]
const MOBILE_ARCHETYPES: Array[StringName] = [
	&"scrap_drone", &"needle_drone", &"chaser", &"shooter", &"controller",
	&"shield_escort", &"artillery_spotter", &"rammer", &"repair_tender",
	&"drone_carrier",
]
var scenario_id: StringName
var elapsed := 0.0
var lifecycle_cycles := 0
var _shot_serial := 0
var _lifecycle_serial := 0
var _enemy_refill_serial := 0
var _lifecycle_timer := 0.0
var _spawn_points: Array[Vector2] = []
var _production_roles: Array[StringName] = []
var _fixture: Dictionary = {}
var _fixture_qualification: Dictionary = {}
var _route_waypoints: Array[Vector2] = []
var _route_waypoint_index := 0
var _dash_release_pending := false
var _scheduler_spawn_seen := false
var _production_pressure_samples: Array[Dictionary] = []
var _production_next_sample := 0.0
var _production_last_sample_spawned := 0


func configure(id: StringName) -> bool:
	if id not in VALID_SCENARIOS:
		return false
	scenario_id = id
	return true


func activate(run: Node) -> void:
	_prepare_stage_five(run)
	if scenario_id == &"production_replay":
		_activate_production_replay(run)
		return
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
	run.encounter_runtime.current_beat = 4
	_production_roles = _production_pressure_roles(ORDINARY_CAPACITY_LOAD)
	var load_class := _load_class()
	_fixture = PressureFixture.build(
		load_class,
		run.current_stage_id,
		run.player_position,
		run.call("_visible_world_rect", 0.0),
		run._active_tactical_layout.ordinary_spawn_anchors,
		_production_roles
	)
	_spawn_points.clear()
	for descriptor_variant in Array(_fixture["descriptors"]):
		var descriptor := Dictionary(descriptor_variant)
		if StringName(descriptor.get("fixture_kind", &"ordinary")) == &"ordinary":
			_spawn_points.append(Vector2(descriptor["pos"]))
	_fixture_qualification = PressureFixture.qualification(
		Array(_fixture["descriptors"]),
		run.player_position,
		run.call("_visible_world_rect", 0.0)
	)
	if scenario_id == &"lifecycle_pressure":
		_run_lifecycle_cycles(run, 300)
	_fill_enemies(run)
	_fill_experience(run, 96 if scenario_id in [&"peak_horde", &"boss_pressure"] else ExperienceRuntime.MAX_SHARDS)
	_fill_effects(run, 48 if scenario_id in [&"peak_horde", &"boss_pressure"] else 96)
	_fill_zones_and_trails(run, 8 if scenario_id in [&"peak_horde", &"boss_pressure"] else 16)
	run.run_build.apply(&"ion_field")
	run.run_build.apply(&"orbit_blades")
	run.call("_sync_cycle_upgrades")
	run.call("_rebuild_enemy_runtime_indexes")
	_fill_projectiles(run, true)


func before_physics(run: Node, delta: float) -> void:
	elapsed += delta
	if scenario_id == &"production_replay":
		_drive_production_replay(run)
		return
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
	if scenario_id == &"production_replay":
		var scheduler_snapshot: Dictionary = run.encounter_runtime.debug_snapshot()
		_scheduler_spawn_seen = _scheduler_spawn_seen or not Dictionary(
			scheduler_snapshot.get("spawned_by_squad", {})
		).is_empty()
		_record_production_pressure(run, scheduler_snapshot)
		return
	_maintain_enemy_pressure(run)
	_fill_projectiles(run, false)


func validation_snapshot(run: Node) -> Dictionary:
	if scenario_id == &"production_replay":
		return _production_validation_snapshot(run)
	# A projectile can expire in the final physics tick after the fixture has
	# sustained its target for the sample. Refill once so terminal qualification
	# describes the declared workload instead of that one-frame retirement edge.
	_fill_projectiles(run, false)
	var expected_enemies := int(Array(_fixture["descriptors"]).size())
	var player_target := 140 if scenario_id in [&"peak_horde", &"boss_pressure"] else ProjectileStore.PLAYER_CAPACITY
	var hostile_target := 72 if scenario_id == &"peak_horde" else ProjectileStore.HOSTILE_CAPACITY
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
	var peak_valid := (
		true
		if scenario_id != &"peak_horde"
		else (
			PressureFixture.peak_qualification_passes(_fixture_qualification)
			and int(pressure["ranged_commits"]) <= EncounterDirector.MAX_RANGED_COMMITS
			and int(pressure["denial_commits"]) <= EncounterDirector.MAX_DENIAL_COMMITS
		)
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
		and int(renderer_snapshot["batches"]) <= 50
		and int(enemy_snapshot["rejected_capacity"]) == 0
		and int(renderer_snapshot["enemy_capacity"]) == EnemyStore.MAX_LIVE_HOSTILES
		and boss_valid
		and peak_valid
		and (scenario_id != &"lifecycle_pressure" or lifecycle_cycles >= 300)
	)
	return {
		"valid": valid,
		"scenario_origin":&"fixture",
		"load_class":_load_class(),
		"fixture_seed":int(_fixture["seed"]),
		"fixture_fingerprint":int(_fixture["fingerprint"]),
		"fixture_qualification":_fixture_qualification.duplicate(true),
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


func deactivate() -> void:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down", &"dash", &"primary_fire"]:
		if InputMap.has_action(action):
			Input.action_release(action)


func desired_aim_direction(run: Node) -> Vector2:
	if scenario_id != &"production_replay":
		return Vector2.ZERO
	var best_distance := INF
	var best_direction: Vector2 = run.player_aim_direction
	var found_priority := false
	for enemy in run.enemies:
		if enemy == null or not enemy.alive or not enemy.active:
			continue
		var priority: bool = enemy.threat_kind != &"pursuit" or enemy.role == &"stage_boss"
		if found_priority and not priority:
			continue
		var distance_squared: float = enemy.pos.distance_squared_to(run.player_position)
		if priority and not found_priority:
			found_priority = true
			best_distance = INF
		if distance_squared < best_distance:
			best_distance = distance_squared
			best_direction = (enemy.pos - run.player_position).normalized()
	return best_direction


func _fill_enemies(run: Node) -> void:
	_enemy_refill_serial = int(_fixture["ordinary_count"])
	for descriptor_variant in Array(_fixture["descriptors"]):
		var descriptor := Dictionary(descriptor_variant)
		var enemy: EnemyState = run.call("_make_enemy", descriptor)
		if enemy == null:
			break
		enemy.active = true
		enemy.counts_active_cap = bool(descriptor["counts_active_cap"])
		enemy.health = 1000000.0
		enemy.max_health = 1000000.0
		if enemy.role == &"boss_pylon":
			enemy.support_tick = 1000000.0
		elif enemy.role == &"stage_boss":
			enemy.phase = &"boss_read"
			enemy.phase_time = 0.0
		run.call("_append_enemy", enemy)


func _maintain_enemy_pressure(run: Node) -> void:
	var target := int(Array(_fixture["descriptors"]).size())
	var budget := 8
	while run.enemy_store.live_count() < target and budget > 0:
		var mobile_index := 4 + posmod(
			_enemy_refill_serial - 4,
			_production_roles.size() - 4
		)
		var enemy: EnemyState = run.call("_make_enemy", {
			"id":"performance_refill_%06d" % _enemy_refill_serial,
			"role":_production_roles[mobile_index],
			"pos":_spawn_points[_enemy_refill_serial % _spawn_points.size()],
			"active":true,
		})
		_enemy_refill_serial += 1
		budget -= 1
		if enemy == null:
			break
		enemy.active = true
		enemy.counts_active_cap = true
		enemy.health = 1000000.0
		enemy.max_health = 1000000.0
		run.call("_append_enemy", enemy)


func _production_pressure_roles(target: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var stage_id: StringName = StageCatalog.STAGE_IDS[-1]
	var profile := StageCatalog.profile(stage_id)
	for role in Array(profile["stationary_roles"]):
		if result.size() >= target:
			return result
		result.append(StringName(role))
	for packet in StageCatalog.packets(stage_id):
		for squad in Array(packet["squads"]):
			for role in Array(squad):
				if result.size() >= target:
					return result
				result.append(StringName(role))
	return result


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
	var counts_active_cap := retired.counts_active_cap
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
	replacement.counts_active_cap = counts_active_cap
	replacement.health = 1000000.0
	replacement.max_health = 1000000.0
	if run.call("_append_enemy", replacement):
		lifecycle_cycles += 1


func _fill_projectiles(run: Node, initial: bool) -> void:
	var player_target := 140 if scenario_id in [&"peak_horde", &"boss_pressure"] else ProjectileStore.PLAYER_CAPACITY
	var hostile_target := 72 if scenario_id == &"peak_horde" else ProjectileStore.HOSTILE_CAPACITY
	if scenario_id == &"boss_pressure":
		hostile_target = 100
	while run.projectile_store.hostile_count() > hostile_target:
		run.projectile_store.remove_hostile_at_swap(
			run.projectile_store.hostile_count() - 1
		)
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
	var target := 48 if scenario_id in [&"peak_horde", &"boss_pressure"] else 96
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


func _prepare_stage_five(run: Node) -> void:
	run.selected_primary = &"pulse_cannon"
	run.selected_run_difficulty = RunDifficulty.HARD
	run.current_stage_index = StageCatalog.STAGE_IDS.size() - 1
	run.current_stage_id = StageCatalog.STAGE_IDS[-1]
	run.call("_reset_run", false, true)
	run.mode = run.RunMode.PLAYING


func _activate_production_replay(run: Node) -> void:
	_production_pressure_samples.clear()
	_production_next_sample = 0.0
	_production_last_sample_spawned = 0
	run.player_barrier_strength = 1.0e9
	run.player_barrier_timer = 1.0e9
	var center := Rules.player_start(run.current_stage_id)
	_route_waypoints = [
		center + Vector2(640.0, 0.0),
		center + Vector2(0.0, 360.0),
		center + Vector2(-640.0, 0.0),
		center + Vector2(0.0, -360.0),
	]
	_route_waypoint_index = 0
	_set_action(&"primary_fire", true)


func _drive_production_replay(run: Node) -> void:
	if _dash_release_pending:
		_set_action(&"dash", false)
		_dash_release_pending = false
	var target := _route_waypoints[_route_waypoint_index]
	var offset: Vector2 = target - run.player_position
	if offset.length() <= 32.0:
		_route_waypoint_index = (_route_waypoint_index + 1) % _route_waypoints.size()
		target = _route_waypoints[_route_waypoint_index]
		offset = target - run.player_position
		if run.player_dash_cooldown <= 0.0:
			_set_action(&"dash", true)
			_dash_release_pending = true
	var direction: Vector2 = offset.normalized()
	_set_action(&"move_left", false)
	_set_action(&"move_right", false)
	_set_action(&"move_up", false)
	_set_action(&"move_down", false)
	if direction.x < -0.2:
		_set_action(&"move_left", true)
	elif direction.x > 0.2:
		_set_action(&"move_right", true)
	if direction.y < -0.2:
		_set_action(&"move_up", true)
	elif direction.y > 0.2:
		_set_action(&"move_down", true)
	run.player_barrier_strength = maxf(run.player_barrier_strength, 1.0e8)
	run.player_barrier_timer = 1.0e9


func _production_validation_snapshot(run: Node) -> Dictionary:
	var scheduler: Dictionary = run.encounter_runtime.debug_snapshot()
	var enemy_snapshot: Dictionary = run.enemy_store.debug_snapshot()
	var projectile_snapshot: Dictionary = run.projectile_store.debug_snapshot()
	var renderer_snapshot: Dictionary = run._combat_renderer.debug_snapshot()
	var scheduler_spawned := _scheduler_spawn_seen or not Dictionary(
		scheduler.get("spawned_by_squad", {})
	).is_empty()
	var allocation_qualification := _production_allocation_qualification(scheduler)
	var active_cap := int(scheduler.get("active_cap", 0))
	var median_active := _production_sample_median(&"active")
	var maximum_ranged := _production_sample_maximum(&"ranged_commits")
	var maximum_denial := _production_sample_maximum(&"denial_commits")
	var pressure_qualified := (
		_production_pressure_samples.size() >= 10
		and int(scheduler.get("beat", 0)) >= 4
		and median_active >= ceili(float(active_cap) * 0.90)
		and bool(allocation_qualification["valid"])
		and maximum_ranged <= EncounterDirector.MAX_RANGED_COMMITS
		and maximum_denial <= EncounterDirector.MAX_DENIAL_COMMITS
	)
	var valid: bool = (
		StringName(scheduler.get("stage_id", &"")) == StageCatalog.STAGE_IDS[-1]
		and StringName(scheduler.get("difficulty", &"")) == RunDifficulty.HARD
		and bool(scheduler.get("spawning_enabled", false))
		and int(enemy_snapshot.get("rejected_capacity", 0)) == 0
		and run.projectile_store.validate_counts()
		and int(renderer_snapshot["batches"]) <= 50
		and scheduler_spawned
		and pressure_qualified
	)
	return {
		"valid":valid,
		"scenario_origin":&"production_scheduler",
		"load_class":&"production",
		"fixture_seed":0,
		"fixture_fingerprint":0,
		"fixture_qualification":{},
		"expected_enemies":-1,
		"ordinary_enemies":run.call("_active_mobile_count"),
		"auxiliary_enemies":int(enemy_snapshot["live"]) - int(run.call("_active_mobile_count")),
		"boss_enemies":0,
		"expected_player_projectiles":-1,
		"expected_hostile_projectiles":-1,
		"enemies":enemy_snapshot,
		"projectiles":projectile_snapshot,
		"experience":run.experience_runtime.shards.size(),
		"effects":run.effects.size(),
		"zones_and_trails":run.denied_zones.size() + run.damaging_trails.size(),
		"lifecycle_cycles":0,
		"boss_active":false,
		"scheduler_spawn_seen":scheduler_spawned,
		"scheduler":scheduler,
		"pressure":scheduler.get("pressure", {}),
		"production_qualification":{
			"valid":pressure_qualified,
			"sample_count":_production_pressure_samples.size(),
			"sample_interval_seconds":1.0,
			"active_cap":active_cap,
			"median_active":median_active,
			"minimum_active":ceili(float(active_cap) * 0.90),
			"maximum_ranged_commits":maximum_ranged,
			"maximum_denial_commits":maximum_denial,
			"allocations":allocation_qualification,
			"samples":_production_pressure_samples.duplicate(true),
		},
	}


func _record_production_pressure(run: Node, scheduler: Dictionary) -> void:
	var spawned_total := _production_spawned_total(scheduler)
	if int(scheduler.get("beat", 0)) < 4:
		_production_last_sample_spawned = spawned_total
		return
	if elapsed + 0.0001 < _production_next_sample:
		return
	var pressure := Dictionary(scheduler.get("pressure", {}))
	var enemy_snapshot: Dictionary = run.enemy_store.debug_snapshot()
	var projectile_snapshot: Dictionary = run.projectile_store.debug_snapshot()
	_production_pressure_samples.append({
		"time":elapsed,
		"authored_reserve":StageCatalog.packet_enemy_blueprint(
			run.current_stage_id
		).size(),
		"live":int(enemy_snapshot.get("live", 0)),
		"active":int(pressure.get("active", 0)),
		"visible":int(pressure.get("visible", 0)),
		"near_900":int(pressure.get("near_900", 0)),
		"sector_histogram":PackedInt32Array(
			pressure.get("sector_histogram", PackedInt32Array())
		),
		"spawned_last_second":maxi(
			0, spawned_total - _production_last_sample_spawned
		),
		"ranged_commits":int(pressure.get("ranged_commits", 0)),
		"denial_commits":int(pressure.get("denial_commits", 0)),
		"player_projectiles":int(projectile_snapshot.get("player", 0)),
		"hostile_projectiles":int(projectile_snapshot.get("hostile", 0)),
	})
	if _production_pressure_samples.size() > 10:
		_production_pressure_samples.pop_front()
	_production_last_sample_spawned = spawned_total
	_production_next_sample = elapsed + 1.0


func _production_spawned_total(scheduler: Dictionary) -> int:
	var total := 0
	for value in Dictionary(scheduler.get("spawned_by_squad", {})).values():
		total += int(value)
	return total


func _production_sample_median(key: StringName) -> int:
	if _production_pressure_samples.is_empty():
		return 0
	var values := PackedInt32Array()
	for sample in _production_pressure_samples:
		values.append(int(sample.get(key, 0)))
	values.sort()
	return values[values.size() / 2]


func _production_sample_maximum(key: StringName) -> int:
	var result := 0
	for sample in _production_pressure_samples:
		result = maxi(result, int(sample.get(key, 0)))
	return result


func _production_allocation_qualification(scheduler: Dictionary) -> Dictionary:
	var sectors := PackedInt32Array()
	sectors.resize(8)
	for allocation_variant in Array(scheduler.get("allocations", [])):
		var allocation := Dictionary(allocation_variant)
		var sector := int(allocation.get("sector", -1))
		if sector >= 0 and sector < sectors.size():
			sectors[sector] += 1
	var occupied_sectors := 0
	var occupied_quadrants := PackedByteArray()
	occupied_quadrants.resize(4)
	var total := 0
	var maximum := 0
	for sector in sectors.size():
		var count := sectors[sector]
		total += count
		maximum = maxi(maximum, count)
		if count > 0:
			occupied_sectors += 1
			occupied_quadrants[floori(float(sector) / 2.0)] = 1
	var quadrant_count := 0
	for occupied in occupied_quadrants:
		quadrant_count += int(occupied)
	var maximum_share := float(maximum) / float(total) if total > 0 else 1.0
	return {
		"valid":(
			quadrant_count == 4
			and occupied_sectors >= 4
			and maximum_share <= 0.35
		),
		"quadrants":quadrant_count,
		"occupied_sectors":occupied_sectors,
		"maximum_sector_share":maximum_share,
		"sector_histogram":sectors,
	}


func _load_class() -> StringName:
	match scenario_id:
		&"peak_horde":
			return &"peak"
		&"capacity_pressure":
			return &"capacity"
		&"lifecycle_pressure":
			return &"lifecycle"
		&"boss_pressure":
			return &"boss"
	return &"production"


func _set_action(action: StringName, pressed: bool) -> void:
	if not InputMap.has_action(action):
		return
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
