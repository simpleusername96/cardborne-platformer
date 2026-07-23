class_name VehicleEnemyStore
extends RefCounted

## Owns a bounded, preallocated live-enemy pool. Swap retirement keeps both
## removal and identity lookup constant-time without retaining dead history.

const MAX_LIVE_HOSTILES := 128
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var live: Array[EnemyState] = []
var rejected_spawns := 0

var _by_id: Dictionary = {}
var _pending_ids: PackedStringArray = []
var _pending_set: Dictionary = {}
var _pool: Array[EnemyState] = []


func _init() -> void:
	for _index in MAX_LIVE_HOSTILES:
		_pool.append(EnemyState.new())


func clear() -> void:
	while not live.is_empty():
		var enemy: EnemyState = live.pop_back()
		enemy.alive = false
		enemy.active = false
		enemy.runtime_slot = -1
		enemy.reset_runtime_collections()
		_pool.append(enemy)
	_by_id.clear()
	_pending_ids.clear()
	_pending_set.clear()
	rejected_spawns = 0


func acquire() -> EnemyState:
	if _pool.is_empty():
		rejected_spawns += 1
		return null
	return _pool.pop_back()


func add(enemy: EnemyState) -> bool:
	if enemy == null:
		return false
	if live.size() >= MAX_LIVE_HOSTILES or enemy.id.is_empty() or _by_id.has(enemy.id):
		rejected_spawns += 1
		release_untracked(enemy)
		return false
	enemy.runtime_slot = live.size()
	live.append(enemy)
	_by_id[enemy.id] = enemy
	return true


func release_untracked(enemy: EnemyState) -> void:
	if enemy == null or enemy.runtime_slot >= 0:
		return
	enemy.alive = false
	enemy.active = false
	enemy.reset_runtime_collections()
	_pool.append(enemy)


func find(enemy_id: String) -> EnemyState:
	return _by_id.get(enemy_id)


func queue_defeat(enemy: EnemyState) -> void:
	if enemy == null or enemy.id.is_empty() or _pending_set.has(enemy.id):
		return
	_pending_set[enemy.id] = true
	_pending_ids.append(enemy.id)


func flush_defeated() -> int:
	var removed := 0
	for enemy_id in _pending_ids:
		var enemy: EnemyState = _by_id.get(enemy_id)
		if enemy == null or enemy.alive:
			continue
		var slot := enemy.runtime_slot
		if slot < 0 or slot >= live.size() or live[slot] != enemy:
			_rebuild_index()
			slot = enemy.runtime_slot
		if slot < 0 or slot >= live.size():
			continue
		var last_index := live.size() - 1
		if slot != last_index:
			var moved: EnemyState = live[last_index]
			live[slot] = moved
			moved.runtime_slot = slot
		live.pop_back()
		_by_id.erase(enemy_id)
		enemy.runtime_slot = -1
		enemy.active = false
		enemy.reset_runtime_collections()
		_pool.append(enemy)
		removed += 1
	_pending_ids.clear()
	_pending_set.clear()
	return removed


func rebuild_index() -> void:
	_rebuild_index()


func contains(enemy: EnemyState) -> bool:
	return enemy != null and not enemy.id.is_empty() and _by_id.get(enemy.id) == enemy


func live_count() -> int:
	return live.size()


func debug_snapshot() -> Dictionary:
	return {
		"live": live.size(),
		"indexed": _by_id.size(),
		"pending": _pending_ids.size(),
		"pool": _pool.size(),
		"rejected_spawns": rejected_spawns,
	}


func _rebuild_index() -> void:
	_by_id.clear()
	for slot in live.size():
		var enemy: EnemyState = live[slot]
		enemy.runtime_slot = slot
		if not enemy.id.is_empty():
			_by_id[enemy.id] = enemy
