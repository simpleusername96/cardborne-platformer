class_name VehicleEnemyUpdateSchedule
extends RefCounted

## Reusable per-tick enemy worklists and coordination counters.
## It schedules existing work but never applies combat, motion, or rendering.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EncounterDirector = preload(
	"res://scripts/encounters/vehicle_encounter_director.gd"
)

const DECISION_INTERVAL := 0.10
const NEAR_MOTION_INTERVAL := 1.0 / 30.0
const FAR_MOTION_INTERVAL := 1.0 / 20.0
const CRITICAL_PHASES: Array[StringName] = [
	&"startup", &"active", &"interrupted_recovery",
]
const SPECIAL_ROLES: Array[StringName] = [
	&"stage_boss", &"generator",
]
const SUPPORT_ROLES: Array[StringName] = [
	&"generator", &"shield_escort",
]

var active: Array[EnemyState] = []
var supports: Array[EnemyState] = []
var critical: Array[EnemyState] = []
var ordinary_due: Array[EnemyState] = []

var active_cap_count := 0
var committed_points := 0.0
var committed_ranged := 0
var committed_denial := 0
var committed_rammers := 0

var _decision_due := PackedByteArray()
var _motion_due := PackedByteArray()
var _critical_due := PackedByteArray()
var _decision_delta := PackedFloat32Array()
var _motion_delta := PackedFloat32Array()
var _motion_starts := PackedVector2Array()
var _due_stamps := PackedInt32Array()
var _schedule_id := 0
var _alive_count := 0
var _carrier_membership_revision := -1
var _rammers_by_squad: Dictionary = {}
var _carrier_children: Dictionary = {}

# Persistent lanes are the integration path for Phase 3. The legacy rebuild()
# above remains a validator oracle while VehicleRun still owns its migration.
var _slot_enemy: Array[EnemyState] = []
var _registered := PackedByteArray()
var _registered_alive := PackedByteArray()
var _classification_signature := PackedInt64Array()
var _persistent_far := PackedByteArray()
var _persistent_decision_rings: Array[Array] = []
var _persistent_near_rings: Array[Array] = []
var _persistent_far_rings: Array[Array] = []
var _persistent_critical: Array[int] = []
var _persistent_time := 0.0
var _last_decision_time := PackedFloat32Array()
var _last_motion_time := PackedFloat32Array()
var _accounted_active := PackedByteArray()
var _accounted_cap := PackedByteArray()
var _accounted_support := PackedByteArray()
var _accounted_commit := PackedByteArray()
var _accounted_ranged := PackedByteArray()
var _accounted_denial := PackedByteArray()
var _accounted_rammer := PackedByteArray()


func _init() -> void:
	_decision_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_motion_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_critical_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_decision_delta.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_motion_delta.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_motion_starts.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_due_stamps.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_due_stamps.fill(0)
	_slot_enemy.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_registered.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_registered_alive.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_classification_signature.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_persistent_far.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_last_decision_time.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_last_motion_time.resize(EnemyStore.MAX_LIVE_HOSTILES)
	for flags in [_accounted_active, _accounted_cap, _accounted_support, _accounted_commit, _accounted_ranged, _accounted_denial, _accounted_rammer]:
		flags.resize(EnemyStore.MAX_LIVE_HOSTILES)
	for index in 6: _persistent_decision_rings.append([])
	for index in 2: _persistent_near_rings.append([])
	for index in 3: _persistent_far_rings.append([])


func reset_persistent() -> void:
	active.clear()
	supports.clear()
	critical.clear()
	ordinary_due.clear()
	_slot_enemy.fill(null)
	_registered.fill(0)
	_registered_alive.fill(0)
	_classification_signature.fill(0)
	_persistent_far.fill(0)
	_persistent_critical.clear()
	for ring in _persistent_decision_rings: ring.clear()
	for ring in _persistent_near_rings: ring.clear()
	for ring in _persistent_far_rings: ring.clear()
	_decision_due.fill(0)
	_motion_due.fill(0)
	_critical_due.fill(0)
	_decision_delta.fill(0.0)
	_motion_delta.fill(0.0)
	_due_stamps.fill(0)
	_schedule_id = 0
	active_cap_count = 0
	committed_points = 0.0
	committed_ranged = 0
	committed_denial = 0
	committed_rammers = 0
	_rammers_by_squad.clear()
	_carrier_children.clear()
	_alive_count = 0
	_persistent_time = 0.0
	_last_decision_time.fill(0.0)
	_last_motion_time.fill(0.0)
	for flags in [_accounted_active, _accounted_cap, _accounted_support, _accounted_commit, _accounted_ranged, _accounted_denial, _accounted_rammer]:
		flags.fill(0)


func register(enemy: EnemyState, is_far: bool = false) -> void:
	if enemy == null:
		return
	var slot := enemy.runtime_slot
	if slot < 0 or slot >= EnemyStore.MAX_LIVE_HOSTILES:
		return
	if _registered[slot] != 0:
		unregister(enemy)
	_slot_enemy[slot] = enemy
	_registered[slot] = 1
	_registered_alive[slot] = 1 if enemy.alive else 0
	_last_decision_time[slot] = _persistent_time
	_last_motion_time[slot] = _persistent_time
	if enemy.alive:
		_alive_count += 1
	if not enemy.carrier_id.is_empty():
		note_carrier_child(enemy.carrier_id)
	classify(enemy, is_far)


func unregister(enemy: EnemyState) -> void:
	if enemy == null:
		return
	var slot := enemy.runtime_slot
	if slot < 0 or slot >= EnemyStore.MAX_LIVE_HOSTILES or _registered[slot] == 0:
		return
	_remove_membership(enemy, slot)
	if _registered_alive[slot] != 0:
		_alive_count = maxi(0, _alive_count - 1)
	if not enemy.carrier_id.is_empty():
		var children := carrier_child_count(enemy.carrier_id) - 1
		if children > 0: _carrier_children[enemy.carrier_id] = children
		else: _carrier_children.erase(enemy.carrier_id)
	_registered[slot] = 0
	_registered_alive[slot] = 0
	_classification_signature[slot] = 0
	_persistent_far[slot] = 0
	_slot_enemy[slot] = null


func classify(enemy: EnemyState, is_far: bool) -> void:
	## Reclassify only on a caller-observed lifecycle, phase, or distance-band change.
	if enemy == null:
		return
	var slot := enemy.runtime_slot
	if slot < 0 or slot >= EnemyStore.MAX_LIVE_HOSTILES or _registered[slot] == 0:
		return
	var signature := _classification_signature_for(enemy, is_far)
	if _classification_signature[slot] == signature:
		return
	if _registered_alive[slot] != int(enemy.alive):
		_alive_count += 1 if enemy.alive else -1
	_remove_membership(enemy, slot)
	_classification_signature[slot] = signature
	_persistent_far[slot] = 1 if is_far else 0
	_last_decision_time[slot] = _persistent_time
	_last_motion_time[slot] = _persistent_time
	_registered_alive[slot] = 1 if enemy.alive else 0
	_add_accounting(enemy, slot)
	if not enemy.alive or not enemy.active or enemy.role in SPECIAL_ROLES:
		return
	if enemy.phase in CRITICAL_PHASES:
		_insert_slot(_persistent_critical, slot)
		return
	_insert_slot(_persistent_decision_rings[posmod(enemy.decision_bucket, 6)], slot)
	if is_far:
		_insert_slot(_persistent_far_rings[posmod(slot, 3)], slot)
	else:
		_insert_slot(_persistent_near_rings[posmod(slot, 2)], slot)


func consume_persistent(delta: float, decision_bucket: int, near_bucket: int, far_bucket: int) -> void:
	## Consumes exactly the caller's current cadence rings; it never walks all live actors.
	_schedule_id += 1
	if _schedule_id >= 0x7ffffffe:
		_due_stamps.fill(0)
		_schedule_id = 1
	critical.clear()
	ordinary_due.clear()
	_persistent_time += maxf(0.0, delta)
	for slot in _persistent_critical:
		var enemy := _slot_enemy[slot]
		if enemy == null or not enemy.alive or not enemy.active:
			continue
		enemy.decision_elapsed = 0.0
		enemy.motion_elapsed = 0.0
		_motion_starts[slot] = enemy.pos
		_mark_due(enemy, true, false, false, 0.0, 0.0)
		critical.append(enemy)
	for slot in _persistent_decision_rings[posmod(decision_bucket, 6)]:
		var enemy := _slot_enemy[slot]
		if enemy == null or not enemy.alive or not enemy.active:
			continue
		_motion_starts[slot] = enemy.pos
		var decision_delta_value := _persistent_time - _last_decision_time[slot]
		if decision_delta_value + 0.00001 < DECISION_INTERVAL:
			continue
		_last_decision_time[slot] = _persistent_time
		_mark_due(enemy, false, true, false, decision_delta_value, 0.0)
		_insert_due_enemy(enemy)
	_consume_motion_ring(_persistent_near_rings[posmod(near_bucket, 2)])
	_consume_motion_ring(_persistent_far_rings[posmod(far_bucket, 3)])


func _mark_due(
	enemy: EnemyState, critical_due: bool, decision_now: bool, motion_now: bool,
	decision_delta_value: float, motion_delta_value: float
) -> void:
	var slot := enemy.runtime_slot
	var same_tick := _due_stamps[slot] == _schedule_id
	_due_stamps[slot] = _schedule_id
	_critical_due[slot] = 1 if critical_due else 0
	_decision_due[slot] = 1 if decision_now else (_decision_due[slot] if same_tick else 0)
	_motion_due[slot] = 1 if motion_now else (_motion_due[slot] if same_tick else 0)
	if decision_now: _decision_delta[slot] = decision_delta_value
	elif not same_tick: _decision_delta[slot] = 0.0
	if motion_now: _motion_delta[slot] = motion_delta_value
	elif not same_tick: _motion_delta[slot] = 0.0


func _consume_motion_ring(ring: Array) -> void:
	for slot in ring:
		var enemy := _slot_enemy[slot]
		if enemy == null or not enemy.alive or not enemy.active:
			continue
		_motion_starts[slot] = enemy.pos
		var motion_delta_value := _persistent_time - _last_motion_time[slot]
		var interval := FAR_MOTION_INTERVAL if _persistent_far[slot] != 0 else NEAR_MOTION_INTERVAL
		if motion_delta_value + 0.00001 < interval:
			continue
		_last_motion_time[slot] = _persistent_time
		_mark_due(enemy, false, false, true, 0.0, motion_delta_value)
		_insert_due_enemy(enemy)


func _insert_due_enemy(enemy: EnemyState) -> void:
	if enemy in ordinary_due:
		return
	var slot := enemy.runtime_slot
	var index := 0
	while index < ordinary_due.size() and ordinary_due[index].runtime_slot < slot:
		index += 1
	ordinary_due.insert(index, enemy)


func _remove_membership(enemy: EnemyState, slot: int) -> void:
	_remove_slot(_persistent_critical, slot)
	for ring in _persistent_decision_rings: _remove_slot(ring, slot)
	for ring in _persistent_near_rings: _remove_slot(ring, slot)
	for ring in _persistent_far_rings: _remove_slot(ring, slot)
	if _accounted_active[slot] != 0:
		_remove_enemy(active, enemy)
		_accounted_active[slot] = 0
	if _accounted_support[slot] != 0:
		_remove_enemy(supports, enemy)
		_accounted_support[slot] = 0
	if _accounted_cap[slot] != 0:
		active_cap_count -= 1
		_accounted_cap[slot] = 0
	if _accounted_commit[slot] != 0:
		committed_points -= enemy.threat_cost
		if _accounted_ranged[slot] != 0: committed_ranged -= 1
		if _accounted_denial[slot] != 0: committed_denial -= 1
		if _accounted_rammer[slot] != 0:
			committed_rammers -= 1
			var count := int(_rammers_by_squad.get(enemy.squad_id, 0)) - 1
			if count > 0: _rammers_by_squad[enemy.squad_id] = count
			else: _rammers_by_squad.erase(enemy.squad_id)
	_accounted_commit[slot] = 0
	_accounted_ranged[slot] = 0
	_accounted_denial[slot] = 0
	_accounted_rammer[slot] = 0


func _classification_signature_for(enemy: EnemyState, is_far: bool) -> int:
	## Transition-only allocation is acceptable; hot due consumption never hashes.
	return hash([
		enemy.alive, enemy.active, enemy.phase, enemy.role, enemy.threat_kind,
		enemy.threat_cost, enemy.counts_active_cap, enemy.squad_id, enemy.carrier_id,
		enemy.zone, enemy.decision_bucket, is_far,
	])


func _add_accounting(enemy: EnemyState, slot: int) -> void:
	if not enemy.alive or not enemy.active:
		return
	_insert_enemy(active, enemy)
	_accounted_active[slot] = 1
	if enemy.counts_active_cap:
		active_cap_count += 1
		_accounted_cap[slot] = 1
	if enemy.role in SUPPORT_ROLES:
		_insert_enemy(supports, enemy)
		_accounted_support[slot] = 1
	if enemy.phase in [&"startup", &"active"] and enemy.role not in SPECIAL_ROLES:
		committed_points += enemy.threat_cost
		_accounted_commit[slot] = 1
		if enemy.threat_kind == &"ranged": committed_ranged += 1; _accounted_ranged[slot] = 1
		if enemy.threat_kind == &"denial": committed_denial += 1; _accounted_denial[slot] = 1
		if enemy.role == &"rammer": _accounted_rammer[slot] = 1; _note_rammer_commit(enemy)


func _insert_enemy(worklist: Array[EnemyState], enemy: EnemyState) -> void:
	var slot := enemy.runtime_slot
	var index := 0
	while index < worklist.size() and worklist[index].runtime_slot < slot:
		index += 1
	worklist.insert(index, enemy)


func _remove_enemy(worklist: Array[EnemyState], enemy: EnemyState) -> void:
	var index := worklist.find(enemy)
	if index >= 0: worklist.remove_at(index)


func _insert_slot(lane: Array, slot: int) -> void:
	var index := 0
	while index < lane.size() and lane[index] < slot:
		index += 1
	lane.insert(index, slot)


func _remove_slot(lane: Array, slot: int) -> void:
	var index := lane.find(slot)
	if index >= 0:
		lane.remove_at(index)


func _schedule_slot(enemy: EnemyState) -> int:
	if enemy == null:
		return -1
	return enemy.runtime_slot


func classified_far(enemy: EnemyState) -> bool:
	var slot := _schedule_slot(enemy)
	return slot >= 0 and slot < EnemyStore.MAX_LIVE_HOSTILES and _registered[slot] != 0 and _persistent_far[slot] != 0


func relocate(enemy: EnemyState, from_slot: int, to_slot: int) -> void:
	## Call after VehicleEnemyStore swap retirement, before the next consume.
	if enemy == null or from_slot == to_slot or from_slot < 0 or to_slot < 0:
		return
	if from_slot >= EnemyStore.MAX_LIVE_HOSTILES or to_slot >= EnemyStore.MAX_LIVE_HOSTILES:
		return
	if _registered[from_slot] == 0:
		return
	var was_far := _persistent_far[from_slot] != 0
	_unregister_slot_without_accounting(from_slot)
	_move_accounted_flag(_accounted_active, from_slot, to_slot)
	_move_accounted_flag(_accounted_cap, from_slot, to_slot)
	_move_accounted_flag(_accounted_support, from_slot, to_slot)
	_move_accounted_flag(_accounted_commit, from_slot, to_slot)
	_move_accounted_flag(_accounted_ranged, from_slot, to_slot)
	_move_accounted_flag(_accounted_denial, from_slot, to_slot)
	_move_accounted_flag(_accounted_rammer, from_slot, to_slot)
	_slot_enemy[to_slot] = enemy
	_registered[to_slot] = 1
	_registered_alive[to_slot] = _registered_alive[from_slot]
	_last_decision_time[to_slot] = _persistent_time
	_last_motion_time[to_slot] = _persistent_time
	_registered[from_slot] = 0
	_registered_alive[from_slot] = 0
	_slot_enemy[from_slot] = null
	_classification_signature[from_slot] = 0
	classify(enemy, was_far)


func _unregister_slot_without_accounting(slot: int) -> void:
	_remove_slot(_persistent_critical, slot)
	for ring in _persistent_decision_rings: _remove_slot(ring, slot)
	for ring in _persistent_near_rings: _remove_slot(ring, slot)
	for ring in _persistent_far_rings: _remove_slot(ring, slot)


func _move_accounted_flag(column: PackedByteArray, from_slot: int, to_slot: int) -> void:
	column[to_slot] = column[from_slot]
	column[from_slot] = 0


func rebuild(
	enemies: Array[EnemyState],
	delta: float,
	player_position: Vector2,
	far_distance_squared: float,
	decision_bucket: int,
	near_motion_bucket: int,
	far_motion_bucket: int,
	membership_revision: int = -1
) -> void:
	active.clear()
	supports.clear()
	critical.clear()
	ordinary_due.clear()
	_schedule_id += 1
	if _schedule_id >= 0x7ffffffe:
		_due_stamps.fill(0)
		_schedule_id = 1
	_rammers_by_squad.clear()
	active_cap_count = 0
	committed_points = 0.0
	committed_ranged = 0
	committed_denial = 0
	committed_rammers = 0
	_alive_count = 0
	var rebuild_carrier_counts := (
		membership_revision < 0
		or membership_revision != _carrier_membership_revision
	)
	if rebuild_carrier_counts:
		_carrier_children.clear()
		_carrier_membership_revision = membership_revision

	for enemy in enemies:
		if enemy == null or not enemy.alive:
			continue
		_alive_count += 1
		if rebuild_carrier_counts and not enemy.carrier_id.is_empty():
			_carrier_children[enemy.carrier_id] = carrier_child_count(enemy.carrier_id) + 1
		if not enemy.active:
			continue
		active.append(enemy)
		if enemy.counts_active_cap:
			active_cap_count += 1
		if enemy.role in SUPPORT_ROLES:
			supports.append(enemy)
		if (
			enemy.phase in [&"startup", &"active"]
			and enemy.role not in SPECIAL_ROLES
		):
			committed_points += enemy.threat_cost
			match enemy.threat_kind:
				&"ranged":
					committed_ranged += 1
				&"denial":
					committed_denial += 1
			if enemy.role == &"rammer":
				_note_rammer_commit(enemy)
		var slot := enemy.runtime_slot
		if slot >= 0 and slot < EnemyStore.MAX_LIVE_HOSTILES:
			_motion_starts[slot] = enemy.pos
		if enemy.role in SPECIAL_ROLES:
			continue
		if slot < 0 or slot >= EnemyStore.MAX_LIVE_HOSTILES:
			continue
		if enemy.phase in CRITICAL_PHASES:
			enemy.decision_elapsed = 0.0
			enemy.motion_elapsed = 0.0
			_due_stamps[slot] = _schedule_id
			_critical_due[slot] = 1
			_decision_due[slot] = 0
			_motion_due[slot] = 0
			_decision_delta[slot] = 0.0
			_motion_delta[slot] = 0.0
			critical.append(enemy)
			continue
		enemy.decision_elapsed += maxf(0.0, delta)
		enemy.motion_elapsed += maxf(0.0, delta)
		var far_motion := (
			player_position.distance_squared_to(enemy.pos) > far_distance_squared
		)
		var motion_interval := FAR_MOTION_INTERVAL if far_motion else NEAR_MOTION_INTERVAL
		var motion_bucket_due := (
			enemy.runtime_slot % 3 == far_motion_bucket
			if far_motion
			else enemy.runtime_slot % 2 == near_motion_bucket
		)
		var decision_now := (
			enemy.decision_bucket == decision_bucket
			and enemy.decision_elapsed + 0.00001 >= DECISION_INTERVAL
		)
		var motion_now := (
			motion_bucket_due
			and enemy.motion_elapsed + 0.00001 >= motion_interval
		)
		if not motion_now and not decision_now:
			continue
		_due_stamps[slot] = _schedule_id
		_critical_due[slot] = 0
		_decision_due[slot] = 1 if decision_now else 0
		_motion_due[slot] = 1 if motion_now else 0
		_decision_delta[slot] = enemy.decision_elapsed if decision_now else 0.0
		_motion_delta[slot] = enemy.motion_elapsed if motion_now else 0.0
		if decision_now:
			enemy.decision_elapsed = 0.0
		if motion_now:
			enemy.motion_elapsed = 0.0
		ordinary_due.append(enemy)


func decision_due(enemy: EnemyState) -> bool:
	var slot := _schedule_slot(enemy)
	return (
		slot >= 0
		and slot < _decision_due.size()
		and _due_stamps[slot] == _schedule_id
		and _decision_due[slot] != 0
	)


func motion_due(enemy: EnemyState) -> bool:
	var slot := _schedule_slot(enemy)
	return (
		slot >= 0
		and slot < _motion_due.size()
		and _due_stamps[slot] == _schedule_id
		and _motion_due[slot] != 0
	)


func is_critical(enemy: EnemyState) -> bool:
	var slot := _schedule_slot(enemy)
	return (
		slot >= 0
		and slot < _critical_due.size()
		and _due_stamps[slot] == _schedule_id
		and _critical_due[slot] != 0
	)


func decision_delta(enemy: EnemyState) -> float:
	var slot := _schedule_slot(enemy)
	return (
		float(_decision_delta[slot])
		if (
			slot >= 0
			and slot < _decision_delta.size()
			and _due_stamps[slot] == _schedule_id
		)
		else 0.0
	)


func motion_delta(enemy: EnemyState) -> float:
	var slot := _schedule_slot(enemy)
	return (
		float(_motion_delta[slot])
		if (
			slot >= 0
			and slot < _motion_delta.size()
			and _due_stamps[slot] == _schedule_id
		)
		else 0.0
	)


func motion_start(enemy: EnemyState) -> Vector2:
	var slot := _schedule_slot(enemy)
	return (
		_motion_starts[slot]
		if slot >= 0 and slot < _motion_starts.size()
		else enemy.pos
	)


func can_commit(
	enemy: EnemyState,
	threat_budget: float,
	ranged_cap: int,
	denial_cap: int
) -> bool:
	return (
		EncounterDirector.can_commit(
			committed_points,
			committed_ranged,
			committed_denial,
			enemy,
			threat_budget,
			ranged_cap,
			denial_cap
		)
		and (
			enemy.role != &"rammer"
			or (
				committed_rammers < 2
				and int(_rammers_by_squad.get(enemy.squad_id, 0)) < 1
			)
		)
	)


func note_commit(enemy: EnemyState) -> void:
	var slot := _schedule_slot(enemy)
	if slot >= 0 and slot < EnemyStore.MAX_LIVE_HOSTILES and _registered[slot] != 0:
		if _accounted_commit[slot] != 0:
			return
		_accounted_commit[slot] = 1
	committed_points += enemy.threat_cost
	match enemy.threat_kind:
		&"ranged":
			committed_ranged += 1
			if slot >= 0 and _registered[slot] != 0: _accounted_ranged[slot] = 1
		&"denial":
			committed_denial += 1
			if slot >= 0 and _registered[slot] != 0: _accounted_denial[slot] = 1
	if enemy.role == &"rammer":
		if slot >= 0 and _registered[slot] != 0: _accounted_rammer[slot] = 1
		_note_rammer_commit(enemy)


func carrier_child_count(carrier_id: String) -> int:
	return int(_carrier_children.get(carrier_id, 0))


func note_carrier_child(carrier_id: String) -> void:
	_carrier_children[carrier_id] = carrier_child_count(carrier_id) + 1


func prune_inactive() -> void:
	## Reconciles a cap decision without rebuilding or discarding due lanes.
	_prune_worklist(active)
	_prune_worklist(supports)
	_prune_worklist(critical)
	_prune_worklist(ordinary_due)
	active_cap_count = 0
	committed_points = 0.0
	committed_ranged = 0
	committed_denial = 0
	committed_rammers = 0
	_rammers_by_squad.clear()
	for enemy in active:
		if enemy.counts_active_cap:
			active_cap_count += 1
		if enemy.phase in [&"startup", &"active"] and enemy.role not in SPECIAL_ROLES:
			committed_points += enemy.threat_cost
			match enemy.threat_kind:
				&"ranged":
					committed_ranged += 1
				&"denial":
					committed_denial += 1
			if enemy.role == &"rammer":
				_note_rammer_commit(enemy)


func debug_snapshot() -> Dictionary:
	return {
		"alive":_alive_count,
		"active":active.size(),
		"supports":supports.size(),
		"critical":critical.size(),
		"ordinary_due":ordinary_due.size(),
		"active_cap_count":active_cap_count,
		"committed_points":committed_points,
		"committed_ranged":committed_ranged,
		"committed_denial":committed_denial,
		"committed_rammers":committed_rammers,
		"carrier_count":_carrier_children.size(),
	}


func _note_rammer_commit(enemy: EnemyState) -> void:
	committed_rammers += 1
	_rammers_by_squad[enemy.squad_id] = int(
		_rammers_by_squad.get(enemy.squad_id, 0)
	) + 1


func _prune_worklist(worklist: Array[EnemyState]) -> void:
	for index in range(worklist.size() - 1, -1, -1):
		var enemy := worklist[index]
		if enemy == null or not enemy.alive or not enemy.active:
			worklist.remove_at(index)
