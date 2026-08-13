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
		enemy.role = &"chaser"
		enemy.threat_kind = &"pursuit"
		enemy.pos = Vector2(2800.0 + float(index % 20) * 8.0, 1700.0)
		enemy.decision_bucket = index % 6
		_expect(store.add(enemy), "schedule fixture adds state %d" % index)
	var rammer_a := store.live[0]
	rammer_a.role = &"rammer"
	rammer_a.phase = &"startup"
	rammer_a.squad_id = "alpha"
	rammer_a.threat_cost = 1.5
	var rammer_b := store.live[1]
	rammer_b.role = &"rammer"
	rammer_b.phase = &"active"
	rammer_b.squad_id = "beta"
	rammer_b.threat_cost = 1.5
	var carrier := store.live[2]
	carrier.role = &"drone_carrier"
	carrier.id = "carrier"
	for index in range(3, 6):
		store.live[index].carrier_id = carrier.id
	var support := store.live[6]
	support.role = &"shield_escort"
	var other_squad := store.live[7]
	other_squad.role = &"rammer"
	other_squad.squad_id = "gamma"
	var stage_boss := store.live[8]
	stage_boss.role = &"stage_boss"
	stage_boss.phase = &"startup"
	var generator := store.live[9]
	generator.role = &"generator"
	generator.phase = &"active"
	var shielded_boss := store.live[10]
	shielded_boss.role = &"stage_boss"
	shielded_boss.phase = &"interrupted_recovery"

	var schedule := Schedule.new()
	schedule.rebuild(store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 0, 0, 0)
	var first := schedule.debug_snapshot()
	_expect(int(first["alive"]) == 320, "schedule retains deterministic alive order")
	_expect(int(first["active"]) == 300, "schedule filters inactive states once")
	_expect(int(first["active_cap_count"]) == 276, "schedule snapshots the active-cap count")
	_expect(int(first["critical"]) == 2, "startup and active ordinary actors stay critical")
	_expect(int(first["committed_rammers"]) == 2, "schedule snapshots committed rammers")
	_expect(
		is_zero_approx(schedule.motion_delta(rammer_a)),
		"critical ordinary actors remain on the independent 60 Hz lane"
	)
	_expect(
		stage_boss not in schedule.critical
		and generator not in schedule.critical
		and shielded_boss not in schedule.critical,
		"special roles stay out of ordinary behavior worklists"
	)
	_expect(schedule.carrier_child_count(carrier.id) == 3, "carrier child count is precomputed")
	_expect(
		not schedule.can_commit(other_squad, 100.0, 100, 100),
		"global rammer cap blocks another commit"
	)
	_expect(
		schedule.supports.size() == 2
		and schedule.supports[0] == support
		and schedule.supports[1] == generator,
		"support worklist preserves store order"
	)

	rammer_b.phase = &"move"
	schedule.rebuild(store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 1, 1, 1)
	_expect(
		not schedule.can_commit(rammer_a, 100.0, 100, 100),
		"same-squad rammer cannot overlap"
	)
	_expect(
		schedule.can_commit(other_squad, 100.0, 100, 100),
		"different squad can use the second global rammer slot"
	)
	var committed_points_before := schedule.committed_points
	schedule.note_commit(other_squad)
	var blocked_rammer := store.live[11]
	blocked_rammer.role = &"rammer"
	blocked_rammer.squad_id = "delta"
	_expect(
		is_equal_approx(
			schedule.committed_points,
			committed_points_before + other_squad.threat_cost
		),
		"local commit update accounts for threat points"
	)
	_expect(
		not schedule.can_commit(blocked_rammer, 100.0, 100, 100),
		"local commit update closes the global rammer cap"
	)
	var ranged_candidate := store.live[12]
	ranged_candidate.role = &"shooter"
	ranged_candidate.threat_kind = &"ranged"
	ranged_candidate.threat_cost = 2.0
	_expect(
		schedule.can_commit(ranged_candidate, 100.0, 1, 100),
		"available ranged budget accepts a candidate"
	)
	schedule.note_commit(ranged_candidate)
	var blocked_ranged := store.live[13]
	blocked_ranged.role = &"shooter"
	blocked_ranged.threat_kind = &"ranged"
	_expect(
		schedule.committed_ranged == 1
		and not schedule.can_commit(blocked_ranged, 100.0, 1, 100),
		"local commit update closes the ranged cap"
	)
	var denial_candidate := store.live[14]
	denial_candidate.role = &"mine"
	denial_candidate.threat_kind = &"denial"
	denial_candidate.threat_cost = 1.0
	_expect(
		schedule.can_commit(denial_candidate, 100.0, 100, 1),
		"available denial budget accepts a candidate"
	)
	schedule.note_commit(denial_candidate)
	var blocked_denial := store.live[15]
	blocked_denial.role = &"mine"
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
		stage_boss not in schedule.ordinary_due
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
		_expect(
			due not in schedule.critical
			and (schedule.motion_due(due) or schedule.decision_due(due)),
			"deferred ordinary work carries an independent due lane without overlap"
		)
	_check_warmed_cadence()
	_check_persistent_lanes()
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


func _check_persistent_lanes() -> void:
	var near := EnemyState.new()
	near.id = "persistent_near"
	near.alive = true
	near.active = true
	near.spatial_slot = 8
	near.runtime_slot = 0
	var far := EnemyState.new()
	far.id = "persistent_far"
	far.alive = true
	far.active = true
	far.spatial_slot = 3
	far.runtime_slot = 1
	var support := EnemyState.new()
	support.id = "persistent_support"
	support.alive = true
	support.active = true
	support.spatial_slot = 10
	support.runtime_slot = 2
	support.role = &"shield_escort"
	support.counts_active_cap = true
	support.phase = &"startup"
	support.threat_cost = 2.0
	var schedule := Schedule.new()
	schedule.register(near, false)
	schedule.register(far, true)
	schedule.register(support, false)
	_expect(
		schedule.active.size() == 3 and schedule.supports == [support]
		and schedule.active_cap_count == 1 and is_equal_approx(schedule.committed_points, 2.0),
		"persistent registration maintains active, support, cap, and commit aggregates"
	)
	var membership_before := schedule.active.size()
	schedule.classify(far, true)
	_expect(schedule.active.size() == membership_before, "unchanged band classification is an O(1) no-op")
	far.threat_cost = 1.25
	schedule.classify(far, true)
	schedule.note_commit(far)
	var committed_after_note := schedule.committed_points
	schedule.note_commit(far)
	schedule.classify(far, true)
	_expect(
		is_equal_approx(schedule.committed_points, committed_after_note),
		"persistent commit accounting remains idempotent after reclassification"
	)
	var near_motion := 0
	var far_motion := 0
	var decisions := 0
	for tick in 120:
		schedule.consume_persistent(1.0 / 60.0, tick % 6, tick % 2, tick % 3)
		if tick < 60:
			continue
		if schedule.motion_due(near): near_motion += 1
		if schedule.motion_due(far): far_motion += 1
		if schedule.decision_due(near): decisions += 1
		if schedule.ordinary_due.size() > 1:
			_expect(
				schedule.ordinary_due[0].spatial_slot < schedule.ordinary_due[1].spatial_slot,
				"persistent due consumption preserves ascending stable-slot order"
			)
	_expect(near_motion == 30 and far_motion == 20, "persistent lanes preserve 30/20 Hz motion")
	_expect(decisions == 10, "persistent lanes preserve 10 Hz decisions")
	near.phase = &"startup"
	schedule.classify(near, false)
	schedule.consume_persistent(1.0 / 60.0, 0, 0, 0)
	_expect(schedule.is_critical(near), "phase reclassification enters the 60 Hz critical lane")
	near.active = false
	schedule.classify(near, false)
	schedule.consume_persistent(1.0 / 60.0, 1, 1, 1)
	_expect(not schedule.is_critical(near), "deactivation removes persistent lane membership")
	support.active = false
	schedule.classify(support, false)
	_expect(
		schedule.supports.is_empty() and schedule.active_cap_count == 0
		and is_equal_approx(schedule.committed_points, far.threat_cost),
		"persistent deactivation removes aggregate contributions"
	)
	far.alive = false
	schedule.unregister(far)
	_expect(int(schedule.debug_snapshot()["alive"]) == 2, "retirement after alive=false removes registered alive contribution")
	_expect(
		schedule._persistent_decision_rings[0].is_empty()
		and schedule._persistent_decision_rings[1].is_empty(),
		"retirement unregisters persistent decision membership"
	)
	schedule.reset_persistent()
	_expect(schedule.debug_snapshot()["ordinary_due"] == 0, "persistent reset clears due state")


func _check_membership_revision() -> void:
	var store := EnemyStore.new()
	var carrier: EnemyState = store.acquire()
	carrier.id = "revision_carrier"
	carrier.alive = true
	carrier.active = true
	carrier.role = &"drone_carrier"
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
		enemy.role = &"chaser"
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
