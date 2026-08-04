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
	for slot in store.live.size():
		var enemy := store.live[slot]
		_expect(enemy.alive, "live store contains no dead history")
		_expect(enemy.runtime_slot == slot, "swap removal repairs slot %d" % slot)
		_expect(store.find(enemy.id) == enemy, "live ID resolves after swap removal")

	for index in retired_count:
		var replacement := _enemy(store, 1000 + index)
		_expect(
			replacement.decision_elapsed == 0.0 and replacement.motion_elapsed == 0.0,
			"reused state %d clears actor-owned cadence" % index
		)
		_expect(store.add(replacement), "freed capacity accepts replacement %d" % index)
	_expect(store.live_count() == EnemyStore.MAX_LIVE_HOSTILES, "store returns to exact capacity")
	_expect(store.debug_snapshot()["pool"] == 0, "every live slot is backed by one fixed pooled state")
	_expect(
		int(store.debug_snapshot()["capacity"]) == 320,
		"store publishes the locked 320-hostile capacity"
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
