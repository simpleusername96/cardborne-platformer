extends SceneTree

const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var store := EnemyStore.new()
	var initial_revision := store.membership_revision
	var original: Array[EnemyState] = []
	for index in EnemyStore.MAX_LIVE_HOSTILES:
		var enemy := _enemy(store, index)
		original.append(enemy)
		_expect(store.add(enemy), "store accepts live enemy %d" % index)
	_expect(store.membership_revision > initial_revision, "membership revision advances on add")
	_expect(store.rejected_capacity == 0, "store records no rejection before declared capacity")
	_expect(store.acquire() == null, "store rejects enemy beyond capacity")
	_expect(store.rejected_spawns == 1, "rejected spawn is observable")
	_expect(store.rejected_capacity == 1, "capacity rejection has a dedicated counter")
	_expect(store.rejected_invalid == 0, "capacity rejection is not misclassified")
	var first_handle := store.handle_for(original[0])
	_expect(
		store.resolves_handle(first_handle.x, first_handle.y),
		"accepted actor resolves through its stable slot/generation handle"
	)
	_expect(
		store.enemy_for_handle(first_handle.x, first_handle.y) == original[0],
		"stable handles resolve directly without a live-population search"
	)
	store.transition_commit(original[1], true)
	store.set_status_membership(original[1], true)
	store.transition_active(original[2], false)
	store.transition_phase(original[3], &"startup")
	var transition_snapshot := store.debug_snapshot()
	_expect(int(transition_snapshot["committed_count"]) == 1, "commit counter changes in O(1)")
	_expect(int(transition_snapshot["status_bearing_count"]) == 1, "status membership is sparse")
	_expect(int(transition_snapshot["active_count"]) == 319, "active transition updates counter")
	_expect(int(transition_snapshot["active_cap_count"]) == 0, "non-cap actors do not inflate active-cap counter")
	original[4].counts_active_cap = true
	store.sync_hot_state(original[4])
	_expect(int(store.debug_snapshot()["active_cap_count"]) == 1, "active-cap membership is explicit")
	_expect(store.packed_phase[original[3].spatial_slot] == 1, "phase transition updates packed column")
	store.transition_active(original[2], true)
	store.transition_commit(original[1], false)
	store.set_status_membership(original[1], false)

	for index in range(0, original.size(), 2):
		original[index].decision_elapsed = 0.08
		original[index].motion_elapsed = 0.04
		original[index].alive = false
		store.queue_defeat(original[index])
	var removed := store.flush_defeated()
	var retired_count := (original.size() + 1) / 2
	_expect(store.membership_revision > initial_revision + EnemyStore.MAX_LIVE_HOSTILES, "membership revision advances on defeat flush")
	_expect(
		removed == retired_count and store.live_count() == EnemyStore.MAX_LIVE_HOSTILES - retired_count,
		"flush removes all queued dead enemies"
	)
	for index in range(0, original.size(), 2):
		_expect(store.find(original[index].id) == null, "retired ID %d cannot resolve" % index)
	_expect(
		not store.resolves_handle(first_handle.x, first_handle.y),
		"retirement invalidates the old stable handle"
	)
	for slot in store.live.size():
		var enemy := store.live[slot]
		_expect(enemy.alive, "live store contains no dead history")
		_expect(enemy.runtime_slot == slot, "swap removal repairs slot %d" % slot)
		_expect(store.find(enemy.id) == enemy, "live ID resolves after swap removal")

	var reused_old_slot := false
	for index in retired_count:
		var replacement := _enemy(store, 1000 + index)
		if replacement.spatial_slot == first_handle.x:
			_expect(
				replacement.runtime_generation != first_handle.y,
				"pooled slot reuse advances generation without changing its stable slot"
			)
			reused_old_slot = true
		_expect(
			replacement.decision_elapsed == 0.0 and replacement.motion_elapsed == 0.0,
			"reused state %d clears actor-owned cadence" % index
		)
		_expect(store.add(replacement), "freed capacity accepts replacement %d" % index)
	_expect(reused_old_slot, "retired pool eventually reuses the stale-handle slot")
	_expect(store.live_count() == EnemyStore.MAX_LIVE_HOSTILES, "store returns to exact capacity")
	_expect(store.debug_snapshot()["pool"] == 0, "every live slot is backed by one fixed pooled state")
	_expect(
		int(store.debug_snapshot()["capacity"]) == 320,
		"store publishes the locked 320-hostile capacity"
	)
	var reconciled := store.debug_reconcile()
	_expect(
		int(reconciled["active"]) == int(store.debug_snapshot()["active_count"]),
		"debug reconciliation agrees with transition-owned aggregate counters"
	)
	_expect(
		int(reconciled["active_cap"]) == int(store.debug_snapshot()["active_cap_count"]),
		"debug reconciliation agrees with active-cap counter"
	)
	var semantics: EnemyState = store.live[0]
	semantics.active = false
	semantics.elite_trait = &"heavy"
	semantics.archetype = &"spark_minelet"
	semantics.phase = &"mine_armed"
	store.sync_hot_state(semantics)
	_expect(
		int(store.debug_snapshot()["elite_count"]) >= 1
		and int(store.debug_snapshot()["armed_minelet_count"]) == 1,
		"elite and armed-minelet counters use the Run lifecycle predicates"
	)
	semantics.active = true
	semantics.zone = "boss_wave"
	store.sync_hot_state(semantics)
	_expect(int(store.debug_snapshot()["boss_add_count"]) == 1, "boss-owned active counter uses zone ownership")
	store.clear()
	_expect(
		store.live_count() == 0 and int(store.debug_snapshot()["status_bearing_count"]) == 0,
		"clear resets packed membership and sparse counters"
	)
	_finish()


func _enemy(store, index: int) -> EnemyState:
	var enemy: EnemyState = store.acquire()
	enemy.id = "enemy_%d" % index
	enemy.alive = true
	enemy.active = true
	enemy.pos = Vector2(float(index), float(index))
	enemy.radius = 12.0
	return enemy


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_STORE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
