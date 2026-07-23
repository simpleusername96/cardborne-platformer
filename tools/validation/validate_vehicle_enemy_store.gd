extends SceneTree

const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var store := EnemyStore.new()
	var original: Array[EnemyState] = []
	for index in EnemyStore.MAX_LIVE_HOSTILES:
		var enemy := _enemy(store, index)
		original.append(enemy)
		_expect(store.add(enemy), "store accepts live enemy %d" % index)
	_expect(store.acquire() == null, "store rejects enemy beyond capacity")
	_expect(store.rejected_spawns == 1, "rejected spawn is observable")

	for index in range(0, original.size(), 2):
		original[index].alive = false
		store.queue_defeat(original[index])
	var removed := store.flush_defeated()
	_expect(removed == 64 and store.live_count() == 64, "flush removes all queued dead enemies")
	for index in range(0, original.size(), 2):
		_expect(store.find(original[index].id) == null, "retired ID %d cannot resolve" % index)
	for slot in store.live.size():
		var enemy := store.live[slot]
		_expect(enemy.alive, "live store contains no dead history")
		_expect(enemy.runtime_slot == slot, "swap removal repairs slot %d" % slot)
		_expect(store.find(enemy.id) == enemy, "live ID resolves after swap removal")

	for index in 64:
		_expect(store.add(_enemy(store, 200 + index)), "freed capacity accepts replacement %d" % index)
	_expect(store.live_count() == EnemyStore.MAX_LIVE_HOSTILES, "store returns to exact capacity")
	_expect(store.debug_snapshot()["pool"] == 0, "every live slot is backed by one fixed pooled state")
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
