extends SceneTree

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const Schedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")
const Run = preload("res://scripts/vehicle/vehicle_run.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var store := EnemyStore.new()
	for index in EnemyStore.MAX_LIVE_HOSTILES:
		var enemy: EnemyState = store.acquire()
		enemy.id = "schedule_%03d" % index
		enemy.alive = true
		enemy.active = index < 300
		enemy.counts_active_cap = index < 276
		enemy.role = &"ordinary_edge_01"
		enemy.threat_kind = &"pursuit"
		enemy.pos = Vector2(2800.0 + float(index % 20) * 8.0, 1700.0)
		enemy.decision_bucket = index % 6
		_expect(store.add(enemy), "schedule fixture adds state %d" % index)
	var pull_enemy_a := store.live[0]
	pull_enemy_a.role = &"ordinary_pull_01"
	pull_enemy_a.phase = &"startup"
	pull_enemy_a.squad_id = "alpha"
	pull_enemy_a.threat_cost = 1.5
	var pull_enemy_b := store.live[1]
	pull_enemy_b.role = &"ordinary_pull_01"
	pull_enemy_b.phase = &"active"
	pull_enemy_b.squad_id = "beta"
	pull_enemy_b.threat_cost = 1.5
	var carrier := store.live[2]
	carrier.role = &"ordinary_support_03"
	carrier.id = "carrier"
	for index in range(3, 6):
		store.live[index].carrier_id = carrier.id
	var support := store.live[6]
	support.role = &"ordinary_support_02"
	var other_squad := store.live[7]
	other_squad.role = &"ordinary_pull_01"
	other_squad.squad_id = "gamma"
	var boss_actor := store.live[8]
	boss_actor.role = &"boss"
	boss_actor.phase = &"startup"
	var generator := store.live[9]
	generator.role = &"ordinary_fixed_support_01"
	generator.phase = &"active"
	var shielded_boss := store.live[10]
	shielded_boss.role = &"boss"
	shielded_boss.phase = &"interrupted_recovery"

	var schedule := Schedule.new()
	schedule.rebuild(store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 0, 0, 0)
	var first := schedule.debug_snapshot()
	_expect(int(first["alive"]) == 320, "schedule retains deterministic alive order")
	_expect(int(first["active"]) == 300, "schedule filters inactive states once")
	_expect(int(first["active_cap_count"]) == 276, "schedule snapshots the active-cap count")
	_expect(int(first["critical"]) == 2, "startup and active ordinary actors stay critical")
	_expect(int(first["committed_pull_enemys"]) == 2, "schedule snapshots committed pull_enemys")
	_expect(
		is_zero_approx(schedule.motion_delta(pull_enemy_a)),
		"critical ordinary actors remain on the independent 60 Hz lane"
	)
	_expect(
		boss_actor not in schedule.critical
		and generator not in schedule.critical
		and shielded_boss not in schedule.critical,
		"special roles stay out of ordinary behavior worklists"
	)
	_expect(schedule.carrier_child_count(carrier.id) == 3, "carrier child count is precomputed")
	_expect(
		not schedule.can_commit(other_squad, 100.0, 100, 100),
		"global pull_enemy cap blocks another commit"
	)
	_expect(
		schedule.supports.size() == 2
		and schedule.supports[0] == support
		and schedule.supports[1] == generator,
		"support worklist preserves store order"
	)

	pull_enemy_b.phase = &"move"
	schedule.rebuild(store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 1, 1, 1)
	_expect(
		not schedule.can_commit(pull_enemy_a, 100.0, 100, 100),
		"same-squad pull_enemy cannot overlap"
	)
	_expect(
		schedule.can_commit(other_squad, 100.0, 100, 100),
		"different squad can use the second global pull_enemy slot"
	)
	var committed_points_before := schedule.committed_points
	schedule.note_commit(other_squad)
	var blocked_pull_enemy := store.live[11]
	blocked_pull_enemy.role = &"ordinary_pull_01"
	blocked_pull_enemy.squad_id = "delta"
	_expect(
		is_equal_approx(
			schedule.committed_points,
			committed_points_before + other_squad.threat_cost
		),
		"local commit update accounts for threat points"
	)
	_expect(
		not schedule.can_commit(blocked_pull_enemy, 100.0, 100, 100),
		"local commit update closes the global pull_enemy cap"
	)
	var ranged_candidate := store.live[12]
	ranged_candidate.role = &"ordinary_lane_01"
	ranged_candidate.threat_kind = &"ranged"
	ranged_candidate.threat_cost = 2.0
	_expect(
		schedule.can_commit(ranged_candidate, 100.0, 1, 100),
		"available ranged budget accepts a candidate"
	)
	schedule.note_commit(ranged_candidate)
	var blocked_ranged := store.live[13]
	blocked_ranged.role = &"ordinary_lane_01"
	blocked_ranged.threat_kind = &"ranged"
	_expect(
		schedule.committed_ranged == 1
		and not schedule.can_commit(blocked_ranged, 100.0, 1, 100),
		"local commit update closes the ranged cap"
	)
	var denial_candidate := store.live[14]
	denial_candidate.role = &"ordinary_fixed_area_01"
	denial_candidate.threat_kind = &"denial"
	denial_candidate.threat_cost = 1.0
	_expect(
		schedule.can_commit(denial_candidate, 100.0, 100, 1),
		"available denial budget accepts a candidate"
	)
	schedule.note_commit(denial_candidate)
	var blocked_denial := store.live[15]
	blocked_denial.role = &"ordinary_fixed_area_01"
	blocked_denial.threat_kind = &"denial"
	_expect(
		schedule.committed_denial == 1
		and not schedule.can_commit(blocked_denial, 100.0, 100, 1),
		"local commit update closes the denial cap"
	)

	for tick in 12:
		schedule.rebuild(
			store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0,
			tick % 6, tick % 2, tick % 3
		)
	var due_snapshot := schedule.debug_snapshot()
	_expect(int(due_snapshot["ordinary_due"]) > 0, "10 Hz decision work becomes due")
	_expect(
		boss_actor not in schedule.ordinary_due
		and generator not in schedule.ordinary_due
		and shielded_boss not in schedule.ordinary_due,
		"special roles never enter deferred ordinary behavior work"
	)
	_expect(
		schedule.critical.size() + schedule.ordinary_due.size()
		< schedule.active.size(),
		"ordinary behavior dispatch visits only scheduled worklists"
	)
	for due in schedule.ordinary_due:
		var due_index := schedule.ordinary_due.find(due)
		var flags := int(schedule.ordinary_due_flags[due_index])
		_expect(
			due not in schedule.critical
			and (schedule.motion_due(due) or schedule.decision_due(due))
			and ((flags & Schedule.WORK_DECISION_DUE) != 0) == schedule.decision_due(due)
			and ((flags & Schedule.WORK_MOTION_DUE) != 0) == schedule.motion_due(due)
			and is_equal_approx(
				float(schedule.ordinary_due_decision_deltas[due_index]),
				schedule.decision_delta(due)
			)
			and is_equal_approx(
				float(schedule.ordinary_due_motion_deltas[due_index]),
				schedule.motion_delta(due)
			),
			"deferred ordinary work carries an independent due lane without overlap"
		)
	_check_receipt_capacity_counts()
	_check_receipt_pruning()
	_check_warmed_cadence()
	_check_membership_revision()
	_check_overlap_refresh_mask()
	var previous_active := schedule.active.duplicate()
	schedule.rebuild(store.live, 0.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 0, 0, 0)
	_expect(schedule.active == previous_active, "zero-delta rebuild preserves deterministic worklist order")
	_finish()


func _check_warmed_cadence() -> void:
	var near := EnemyState.new()
	near.id = "cadence_near"
	near.alive = true
	near.active = true
	near.runtime_slot = 0
	near.decision_bucket = 1
	near.pos = Vector2.ZERO
	var far := EnemyState.new()
	far.id = "cadence_far"
	far.alive = true
	far.active = true
	far.runtime_slot = 3
	far.decision_bucket = 1
	far.pos = Vector2(1200.0, 0.0)
	var fixtures: Array[EnemyState] = [near, far]
	var schedule := Schedule.new()
	var near_decisions := 0
	var near_motions := 0
	var near_decision_time := 0.0
	var near_motion_time := 0.0
	var far_decisions := 0
	var far_motions := 0
	var far_decision_time := 0.0
	var far_motion_time := 0.0
	var saw_decision_only := false
	var saw_motion_only := false
	for tick in 120:
		schedule.rebuild(
			fixtures,
			1.0 / 60.0,
			Vector2.ZERO,
			820.0 * 820.0,
			tick % 6,
			tick % 2,
			tick % 3
		)
		if tick < 60:
			continue
		var near_decision_due := schedule.decision_due(near)
		var near_motion_due := schedule.motion_due(near)
		var far_decision_due := schedule.decision_due(far)
		var far_motion_due := schedule.motion_due(far)
		if near_decision_due:
			near_decisions += 1
			near_decision_time += schedule.decision_delta(near)
		if near_motion_due:
			near_motions += 1
			near_motion_time += schedule.motion_delta(near)
		if far_decision_due:
			far_decisions += 1
			far_decision_time += schedule.decision_delta(far)
		if far_motion_due:
			far_motions += 1
			far_motion_time += schedule.motion_delta(far)
		if near_decision_due and not near_motion_due:
			saw_decision_only = true
		if near_motion_due and not near_decision_due:
			saw_motion_only = true
	_expect(near_decisions == 10, "near ordinary decisions remain at 10 Hz")
	_expect(near_motions == 30, "near ordinary motion remains at 30 Hz")
	_expect(far_decisions == 10, "far ordinary decisions remain at 10 Hz")
	_expect(far_motions == 20, "far ordinary motion remains at 20 Hz")
	_expect(is_equal_approx(near_decision_time, 1.0), "near decision delta totals one second")
	_expect(is_equal_approx(near_motion_time, 1.0), "near motion delta totals one second")
	_expect(is_equal_approx(far_decision_time, 1.0), "far decision delta totals one second")
	_expect(is_equal_approx(far_motion_time, 1.0), "far motion delta totals one second")
	_expect(saw_decision_only, "decision-only work does not consume motion time")
	_expect(saw_motion_only, "motion-only work is dispatched without decision work")


func _check_receipt_capacity_counts() -> void:
	for actor_count in [6, 32, 40, 48]:
		var fixtures: Array[EnemyState] = []
		for index in actor_count:
			var enemy := EnemyState.new()
			enemy.id = "receipt_%02d_%02d" % [actor_count, index]
			enemy.alive = true
			enemy.active = true
			enemy.runtime_slot = index
			enemy.decision_bucket = index % 6
			enemy.pos = Vector2(float(index) * 30.0, 0.0)
			fixtures.append(enemy)
		var schedule := Schedule.new()
		for tick in 12:
			schedule.rebuild(
				fixtures,
				1.0 / 60.0,
				Vector2.ZERO,
				820.0 * 820.0,
				tick % 6,
				tick % 2,
				tick % 3
			)
			for due_index in schedule.ordinary_due.size():
				var due := schedule.ordinary_due[due_index]
				var flags := int(schedule.ordinary_due_flags[due_index])
				_expect(
					((flags & Schedule.WORK_DECISION_DUE) != 0)
						== schedule.decision_due(due),
					"%d actors preserve decision receipt at tick %d" % [actor_count, tick]
				)
				_expect(
					((flags & Schedule.WORK_MOTION_DUE) != 0)
						== schedule.motion_due(due),
					"%d actors preserve motion receipt at tick %d" % [actor_count, tick]
				)


func _check_receipt_pruning() -> void:
	var fixtures: Array[EnemyState] = []
	for index in 6:
		var enemy := EnemyState.new()
		enemy.id = "prune_%02d" % index
		enemy.alive = true
		enemy.active = true
		enemy.runtime_slot = index
		enemy.decision_bucket = index
		enemy.decision_elapsed = Schedule.DECISION_INTERVAL
		enemy.motion_elapsed = Schedule.NEAR_MOTION_INTERVAL
		fixtures.append(enemy)
	var schedule := Schedule.new()
	schedule.rebuild(
		fixtures, 0.0, Vector2.ZERO, 820.0 * 820.0, 0, 0, 0
	)
	fixtures[0].active = false
	schedule.prune_inactive()
	for due_index in schedule.ordinary_due.size():
		var due := schedule.ordinary_due[due_index]
		var flags := int(schedule.ordinary_due_flags[due_index])
		_expect(
			due.active
			and ((flags & Schedule.WORK_DECISION_DUE) != 0)
				== schedule.decision_due(due)
			and ((flags & Schedule.WORK_MOTION_DUE) != 0)
				== schedule.motion_due(due),
			"pruning keeps ordinary receipt columns aligned"
		)


func _check_membership_revision() -> void:
	var store := EnemyStore.new()
	var carrier: EnemyState = store.acquire()
	carrier.id = "revision_carrier"
	carrier.alive = true
	carrier.active = true
	carrier.role = &"ordinary_support_03"
	_expect(store.add(carrier), "revision fixture adds carrier")
	var schedule := Schedule.new()
	schedule.rebuild(
		store.live, 0.0, Vector2.ZERO, 820.0 * 820.0, 0, 0, 0,
		store.membership_revision
	)
	_expect(
		schedule.carrier_child_count(carrier.id) == 0,
		"revision fixture starts with no carrier children"
	)
	var child: EnemyState = store.acquire()
	child.id = "revision_child"
	child.alive = true
	child.active = true
	child.carrier_id = carrier.id
	_expect(store.add(child), "revision fixture adds carrier child")
	schedule.rebuild(
		store.live, 0.0, Vector2.ZERO, 820.0 * 820.0, 0, 0, 0,
		store.membership_revision
	)
	_expect(
		schedule.carrier_child_count(carrier.id) == 1,
		"membership revision invalidates cached carrier counts"
	)


func _check_overlap_refresh_mask() -> void:
	var store := EnemyStore.new()
	for index in 24:
		var enemy: EnemyState = store.acquire()
		enemy.id = "refresh_%02d" % index
		enemy.alive = true
		enemy.active = true
		enemy.role = &"ordinary_edge_01"
		enemy.pos = Vector2(400.0 + float(index % 8) * 6.0, 400.0)
		enemy.radius = 20.0
		enemy.projectile_hit_radius = 20.0
		enemy.decision_bucket = index % 6
		_expect(store.add(enemy), "refresh fixture adds state %d" % index)
	store.live[0].phase = &"startup"
	store.live[1].phase = &"active"
	var schedule := Schedule.new()
	var run := Run.new()
	run._enemy_update_schedule = schedule
	run.enemies = store.live
	run.enemy_grid.configure(Rect2(0.0, 0.0, 1200.0, 800.0), 160.0)
	run.enemy_grid.rebuild(store.live)
	var epoch := 0
	for tick in 24:
		var decision_bucket := tick % 6
		if decision_bucket == 0:
			epoch += 1
		schedule.rebuild(
			store.live,
			1.0 / 60.0,
			Vector2(400.0, 400.0),
			820.0 * 820.0,
			decision_bucket,
			tick % 2,
			tick % 3,
			store.membership_revision
		)
		run._enemy_decision_cycle_epoch = epoch
		run._prepare_enemy_local_overlap_cache()
		for enemy in store.live:
			var slot := (
				enemy.spatial_slot
				if enemy.spatial_slot >= 0
				else enemy.runtime_slot
			)
			var expected := (
				(
					enemy in schedule.critical
					or (
						enemy in schedule.ordinary_due
						and schedule.decision_due(enemy)
					)
				)
				and posmod(slot + epoch, 2) == 0
			)
			_expect(
				(run._enemy_overlap_refresh_mask[slot] != 0) == expected,
				"tick %d slot %d refresh mask matches critical/decision parity"
				% [tick, slot]
			)
	_expect(
		int(run.enemy_grid.debug_snapshot()["legacy_nearest_query_calls"]) == 0,
		"twelve-bucket refresh preparation uses no per-owner nearest query"
	)
	run.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_UPDATE_SCHEDULE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
