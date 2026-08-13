class_name VehicleEnemyStore
extends RefCounted

## Owns the bounded enemy pool, stable handles, and migration-era packed hot
## columns. EnemyState remains the compatibility facade until each consumer is
## migrated; callers must use transition APIs when changing store-owned state.

const MAX_LIVE_HOSTILES := 320
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

const FLAG_LIVE := 1
const FLAG_ACTIVE := 2
const FLAG_ELITE := 4
const FLAG_BOSS_ADD := 8
const FLAG_ARMED_MINELET := 16
const FLAG_COMMITTED := 32
const FLAG_ACTIVE_CAP := 64
const LANE_NONE := 0
const LANE_CRITICAL := 1
const LANE_NEAR := 2
const LANE_FAR := 3

var live: Array[EnemyState] = []
var membership_revision := 0
var rejected_spawns := 0
var rejected_capacity := 0
var rejected_invalid := 0

# Fixed hot columns are indexed by the immutable spatial slot, never the
# swap-retired runtime slot. No authored IDs, text, or Dictionaries enter them.
var packed_position := PackedVector2Array()
var packed_previous_position := PackedVector2Array()
var packed_velocity := PackedVector2Array()
var packed_desired_velocity := PackedVector2Array()
var packed_health := PackedFloat32Array()
var packed_max_health := PackedFloat32Array()
var packed_radius := PackedFloat32Array()
var packed_speed := PackedFloat32Array()
var packed_decision_elapsed := PackedFloat32Array()
var packed_motion_elapsed := PackedFloat32Array()
var packed_generation := PackedInt32Array()
var packed_flags := PackedInt32Array()
var packed_phase := PackedInt32Array()
var packed_lane := PackedInt32Array()
var packed_cell := PackedVector2Array()
var packed_role := PackedInt32Array()
var packed_family := PackedInt32Array()
var family_counts := PackedInt32Array()
var packed_threat_family := PackedInt32Array()
var threat_family_counts := PackedInt32Array()

var active_count := 0
var active_cap_count := 0
var elite_count := 0
var boss_add_count := 0
var armed_minelet_count := 0
var committed_count := 0
var carrier_child_count := 0
var status_bearing_count := 0
var status_slots := PackedInt32Array()

var _by_id: Dictionary = {}
var _pending_ids: PackedStringArray = []
var pending_defeated: Array[EnemyState] = []
var _pending_set: Dictionary = {}
var _pool: Array[EnemyState] = []
var _status_slot_index := PackedInt32Array()
var _slot_enemy: Array[EnemyState] = []
var relocated_enemies: Array[EnemyState] = []
var relocated_from_slots := PackedInt32Array()
var relocated_to_slots := PackedInt32Array()


func _init() -> void:
	_resize_columns()
	_slot_enemy.resize(MAX_LIVE_HOSTILES)
	for index in MAX_LIVE_HOSTILES:
		var enemy := EnemyState.new()
		enemy.spatial_slot = index
		_pool.append(enemy)


func clear() -> void:
	while not live.is_empty():
		var enemy: EnemyState = live.pop_back()
		_deactivate_slot(enemy)
		enemy.alive = false
		enemy.active = false
		enemy.runtime_slot = -1
		enemy.reset_runtime_collections()
		_pool.append(enemy)
	_by_id.clear()
	_pending_ids.clear()
	pending_defeated.clear()
	_pending_set.clear()
	clear_relocations()
	_reset_counters()
	membership_revision += 1
	rejected_spawns = 0
	rejected_capacity = 0
	rejected_invalid = 0


func acquire() -> EnemyState:
	if _pool.is_empty():
		rejected_spawns += 1
		rejected_capacity += 1
		return null
	var enemy: EnemyState = _pool.pop_back()
	enemy.runtime_generation += 1
	if enemy.runtime_generation >= 0x7ffffffe:
		enemy.runtime_generation = 1
	packed_generation[enemy.spatial_slot] = enemy.runtime_generation
	return enemy


func add(enemy: EnemyState) -> bool:
	if enemy == null:
		return false
	if live.size() >= MAX_LIVE_HOSTILES:
		rejected_spawns += 1
		rejected_capacity += 1
		release_untracked(enemy)
		return false
	if enemy.id.is_empty() or _by_id.has(enemy.id):
		rejected_spawns += 1
		rejected_invalid += 1
		release_untracked(enemy)
		return false
	enemy.runtime_slot = live.size()
	live.append(enemy)
	_by_id[enemy.id] = enemy
	_slot_enemy[enemy.spatial_slot] = enemy
	_sync_slot(enemy)
	if not enemy.carrier_id.is_empty():
		carrier_child_count += 1
	membership_revision += 1
	return true


func release_untracked(enemy: EnemyState) -> void:
	if enemy == null or enemy.runtime_slot >= 0:
		return
	_deactivate_slot(enemy)
	enemy.alive = false
	enemy.active = false
	enemy.reset_runtime_collections()
	_pool.append(enemy)


func find(enemy_id: String) -> EnemyState:
	return _by_id.get(enemy_id)


func handle_for(enemy: EnemyState) -> Vector2i:
	if enemy == null or not contains(enemy):
		return Vector2i(-1, 0)
	return Vector2i(enemy.spatial_slot, enemy.runtime_generation)


func resolves_handle(slot: int, generation: int) -> bool:
	return (
		slot >= 0 and slot < MAX_LIVE_HOSTILES
		and packed_generation[slot] == generation
		and (packed_flags[slot] & FLAG_LIVE) != 0
	)


func enemy_for_handle(slot: int, generation: int) -> EnemyState:
	if not resolves_handle(slot, generation):
		return null
	return _slot_enemy[slot]


## Status iteration uses immutable spatial slots, not the swap-retired live index.
func enemy_for_status_slot(slot: int) -> EnemyState:
	if slot < 0 or slot >= MAX_LIVE_HOSTILES or _status_slot_index[slot] < 0:
		return null
	return _slot_enemy[slot]


func transition_active(enemy: EnemyState, becomes_active: bool) -> void:
	if not contains(enemy):
		return
	if enemy.active == becomes_active:
		return
	enemy.active = becomes_active
	_sync_slot(enemy)
	membership_revision += 1


func transition_phase(enemy: EnemyState, next_phase: StringName) -> void:
	if not contains(enemy):
		return
	enemy.phase = next_phase
	packed_phase[enemy.spatial_slot] = _phase_code(next_phase)
	packed_lane[enemy.spatial_slot] = _lane_for(enemy)


func transition_commit(enemy: EnemyState, committed: bool) -> void:
	if not contains(enemy):
		return
	var slot := enemy.spatial_slot
	var was_committed := (packed_flags[slot] & FLAG_COMMITTED) != 0
	if was_committed == committed:
		return
	if committed:
		packed_flags[slot] |= FLAG_COMMITTED
		committed_count += 1
	else:
		packed_flags[slot] &= ~FLAG_COMMITTED
		committed_count -= 1


func sync_hot_state(enemy: EnemyState) -> void:
	if contains(enemy):
		_sync_slot(enemy)


func set_status_membership(enemy: EnemyState, has_status: bool) -> void:
	if not contains(enemy):
		return
	var slot := enemy.spatial_slot
	var index := _status_slot_index[slot]
	if has_status and index < 0:
		_status_slot_index[slot] = status_slots.size()
		status_slots.append(slot)
		status_bearing_count += 1
	elif not has_status and index >= 0:
		var last_slot := status_slots[status_slots.size() - 1]
		status_slots[index] = last_slot
		_status_slot_index[last_slot] = index
		status_slots.remove_at(status_slots.size() - 1)
		_status_slot_index[slot] = -1
		status_bearing_count -= 1


func note_carrier_child_delta(delta: int) -> void:
	## Carrier runtime calls this only when a child enters or leaves live state.
	carrier_child_count = maxi(0, carrier_child_count + delta)


func queue_defeat(enemy: EnemyState) -> void:
	if enemy == null or enemy.id.is_empty() or _pending_set.has(enemy.id):
		return
	_pending_set[enemy.id] = true
	_pending_ids.append(enemy.id)
	pending_defeated.append(enemy)


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
			relocated_enemies.append(moved)
			relocated_from_slots.append(last_index)
			relocated_to_slots.append(slot)
			moved.runtime_slot = slot
		live.pop_back()
		_by_id.erase(enemy_id)
		_deactivate_slot(enemy)
		enemy.runtime_slot = -1
		enemy.active = false
		enemy.reset_runtime_collections()
		_pool.append(enemy)
		removed += 1
	_pending_ids.clear()
	pending_defeated.clear()
	_pending_set.clear()
	if removed > 0:
		membership_revision += 1
	return removed


func rebuild_index() -> void:
	_rebuild_index()


func contains(enemy: EnemyState) -> bool:
	return enemy != null and not enemy.id.is_empty() and _by_id.get(enemy.id) == enemy


func live_count() -> int:
	return live.size()


func debug_reconcile() -> Dictionary:
	var computed := {"active": 0, "active_cap": 0, "elite": 0, "boss_add": 0, "armed_minelet": 0, "committed": 0, "status": 0}
	for enemy in live:
		var flags := packed_flags[enemy.spatial_slot]
		computed["active"] += 1 if (flags & FLAG_ACTIVE) != 0 else 0
		computed["active_cap"] += 1 if (flags & FLAG_ACTIVE_CAP) != 0 else 0
		computed["elite"] += 1 if (flags & FLAG_ELITE) != 0 else 0
		computed["boss_add"] += 1 if (flags & FLAG_BOSS_ADD) != 0 else 0
		computed["armed_minelet"] += 1 if (flags & FLAG_ARMED_MINELET) != 0 else 0
		computed["committed"] += 1 if (flags & FLAG_COMMITTED) != 0 else 0
		computed["status"] += 1 if _status_slot_index[enemy.spatial_slot] >= 0 else 0
	return computed


func debug_snapshot() -> Dictionary:
	return {
		"live": live.size(), "indexed": _by_id.size(), "pending": _pending_ids.size(),
		"pool": _pool.size(), "rejected_spawns": rejected_spawns,
		"rejected_capacity": rejected_capacity, "rejected_invalid": rejected_invalid,
		"capacity": MAX_LIVE_HOSTILES, "active_count": active_count, "active_cap_count": active_cap_count,
		"elite_count": elite_count, "boss_add_count": boss_add_count,
		"armed_minelet_count": armed_minelet_count, "committed_count": committed_count,
		"carrier_child_count": carrier_child_count, "status_bearing_count": status_bearing_count,
	}


func clear_relocations() -> void:
	relocated_enemies.clear()
	relocated_from_slots.clear()
	relocated_to_slots.clear()


func _resize_columns() -> void:
	packed_position.resize(MAX_LIVE_HOSTILES)
	packed_previous_position.resize(MAX_LIVE_HOSTILES)
	packed_velocity.resize(MAX_LIVE_HOSTILES)
	packed_desired_velocity.resize(MAX_LIVE_HOSTILES)
	packed_cell.resize(MAX_LIVE_HOSTILES)
	packed_health.resize(MAX_LIVE_HOSTILES)
	packed_max_health.resize(MAX_LIVE_HOSTILES)
	packed_radius.resize(MAX_LIVE_HOSTILES)
	packed_speed.resize(MAX_LIVE_HOSTILES)
	packed_decision_elapsed.resize(MAX_LIVE_HOSTILES)
	packed_motion_elapsed.resize(MAX_LIVE_HOSTILES)
	packed_generation.resize(MAX_LIVE_HOSTILES)
	packed_flags.resize(MAX_LIVE_HOSTILES)
	packed_phase.resize(MAX_LIVE_HOSTILES)
	packed_lane.resize(MAX_LIVE_HOSTILES)
	packed_role.resize(MAX_LIVE_HOSTILES)
	packed_family.resize(MAX_LIVE_HOSTILES)
	family_counts.resize(8)
	packed_threat_family.resize(MAX_LIVE_HOSTILES)
	threat_family_counts.resize(8)
	_status_slot_index.resize(MAX_LIVE_HOSTILES)
	_status_slot_index.fill(-1)


func _sync_slot(enemy: EnemyState) -> void:
	var slot := enemy.spatial_slot
	if slot < 0 or slot >= MAX_LIVE_HOSTILES:
		return
	packed_position[slot] = enemy.pos
	packed_previous_position[slot] = enemy.contact_previous_position
	packed_velocity[slot] = enemy.velocity
	packed_desired_velocity[slot] = enemy.desired_velocity
	packed_health[slot] = enemy.health
	packed_max_health[slot] = enemy.max_health
	packed_radius[slot] = enemy.radius
	packed_speed[slot] = enemy.speed
	packed_decision_elapsed[slot] = enemy.decision_elapsed
	packed_motion_elapsed[slot] = enemy.motion_elapsed
	packed_generation[slot] = enemy.runtime_generation
	var old_flags := packed_flags[slot]
	packed_phase[slot] = _phase_code(enemy.phase)
	packed_lane[slot] = _lane_for(enemy)
	packed_role[slot] = _role_code(enemy.role)
	var old_family := packed_family[slot]
	var family := _family_code(enemy.movement_family)
	packed_family[slot] = family
	if (old_flags & FLAG_LIVE) != 0: family_counts[old_family] -= 1
	if enemy.alive: family_counts[family] += 1
	var old_threat_family := packed_threat_family[slot]
	var threat_family := _threat_family_code(enemy.threat_kind)
	packed_threat_family[slot] = threat_family
	if (old_flags & FLAG_ACTIVE) != 0: threat_family_counts[old_threat_family] -= 1
	var flags := FLAG_LIVE if enemy.alive else 0
	if enemy.alive and enemy.active: flags |= FLAG_ACTIVE
	if enemy.alive and enemy.active and enemy.counts_active_cap: flags |= FLAG_ACTIVE_CAP
	if enemy.alive and not enemy.elite_trait.is_empty(): flags |= FLAG_ELITE
	if enemy.active and _is_boss_owned(enemy): flags |= FLAG_BOSS_ADD
	if enemy.alive and enemy.archetype == &"spark_minelet" and enemy.phase == &"mine_armed": flags |= FLAG_ARMED_MINELET
	if (old_flags & FLAG_COMMITTED) != 0: flags |= FLAG_COMMITTED
	packed_flags[slot] = flags
	if (flags & FLAG_ACTIVE) != 0: threat_family_counts[threat_family] += 1
	_apply_counter_delta(old_flags, flags)


func _deactivate_slot(enemy: EnemyState) -> void:
	var slot := enemy.spatial_slot
	if slot < 0 or slot >= MAX_LIVE_HOSTILES:
		return
	var status_index := _status_slot_index[slot]
	if status_index >= 0:
		var last_slot := status_slots[status_slots.size() - 1]
		status_slots[status_index] = last_slot
		_status_slot_index[last_slot] = status_index
		status_slots.remove_at(status_slots.size() - 1)
		_status_slot_index[slot] = -1
		status_bearing_count -= 1
	var old_flags := packed_flags[slot]
	if (old_flags & FLAG_LIVE) != 0 and not enemy.carrier_id.is_empty():
		carrier_child_count = maxi(0, carrier_child_count - 1)
	packed_flags[slot] = 0
	_slot_enemy[slot] = null
	packed_phase[slot] = 0
	packed_lane[slot] = LANE_NONE
	if (old_flags & FLAG_LIVE) != 0: family_counts[packed_family[slot]] -= 1
	if (old_flags & FLAG_ACTIVE) != 0: threat_family_counts[packed_threat_family[slot]] -= 1
	packed_role[slot] = 0
	packed_family[slot] = 0
	packed_threat_family[slot] = 0
	_apply_counter_delta(old_flags, 0)


func _apply_counter_delta(old_flags: int, new_flags: int) -> void:
	active_count += int((new_flags & FLAG_ACTIVE) != 0) - int((old_flags & FLAG_ACTIVE) != 0)
	active_cap_count += int((new_flags & FLAG_ACTIVE_CAP) != 0) - int((old_flags & FLAG_ACTIVE_CAP) != 0)
	elite_count += int((new_flags & FLAG_ELITE) != 0) - int((old_flags & FLAG_ELITE) != 0)
	boss_add_count += int((new_flags & FLAG_BOSS_ADD) != 0) - int((old_flags & FLAG_BOSS_ADD) != 0)
	armed_minelet_count += int((new_flags & FLAG_ARMED_MINELET) != 0) - int((old_flags & FLAG_ARMED_MINELET) != 0)
	committed_count += int((new_flags & FLAG_COMMITTED) != 0) - int((old_flags & FLAG_COMMITTED) != 0)


func _reset_counters() -> void:
	packed_flags.fill(0)
	packed_phase.fill(0)
	packed_lane.fill(LANE_NONE)
	packed_role.fill(0)
	packed_family.fill(0)
	family_counts.fill(0)
	packed_threat_family.fill(0)
	threat_family_counts.fill(0)
	_status_slot_index.fill(-1)
	status_slots.clear()
	active_count = 0
	active_cap_count = 0
	elite_count = 0
	boss_add_count = 0
	armed_minelet_count = 0
	committed_count = 0
	carrier_child_count = 0
	status_bearing_count = 0


func _phase_code(phase: StringName) -> int:
	if phase == &"startup": return 1
	if phase == &"active": return 2
	if phase == &"interrupted_recovery": return 3
	return 4


func _lane_for(enemy: EnemyState) -> int:
	if not enemy.active: return LANE_NONE
	if enemy.phase in [&"startup", &"active", &"interrupted_recovery"]: return LANE_CRITICAL
	return LANE_NEAR


func _role_code(role: StringName) -> int:
	return int(hash(role) & 0x7fffffff)


func _family_code(family: StringName) -> int:
	match family:
		&"pursuit": return 1
		&"standoff": return 2
		&"escort": return 3
		&"support": return 4
		&"stationary": return 5
	return 0


func _threat_family_code(family: StringName) -> int:
	match family:
		&"melee": return 1
		&"ranged": return 2
		&"denial": return 3
		&"support": return 4
		&"boss": return 5
	return 0


func _is_boss_owned(enemy: EnemyState) -> bool:
	return (
		enemy.role == &"stage_boss"
		or enemy.zone in ["boss_wave", "boss_system"]
		or enemy.carrier_id == "stage_boss"
	)


func _rebuild_index() -> void:
	_by_id.clear()
	for slot in live.size():
		var enemy: EnemyState = live[slot]
		enemy.runtime_slot = slot
		if not enemy.id.is_empty():
			_by_id[enemy.id] = enemy
