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
	&"boss", &"ordinary_fixed_support_01",
]
const SUPPORT_ROLES: Array[StringName] = [
	&"ordinary_fixed_support_01", &"ordinary_support_02",
]
const WORK_DECISION_DUE := 1
const WORK_MOTION_DUE := 2

var active: Array[EnemyState] = []
var supports: Array[EnemyState] = []
var critical: Array[EnemyState] = []
var ordinary_due: Array[EnemyState] = []
## Parallel, reusable receipts for `ordinary_due`. Consumers iterate by index
## and reuse the scheduler's cadence result instead of querying each actor again.
var ordinary_due_flags := PackedByteArray()
var ordinary_due_decision_deltas := PackedFloat32Array()
var ordinary_due_motion_deltas := PackedFloat32Array()

var active_cap_count := 0
var committed_points := 0.0
var committed_ranged := 0
var committed_denial := 0
var committed_pull_enemys := 0

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
var _pull_enemys_by_squad: Dictionary = {}
var _carrier_children: Dictionary = {}


func _init() -> void:
	_decision_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_motion_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_critical_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_decision_delta.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_motion_delta.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_motion_starts.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_due_stamps.resize(EnemyStore.MAX_LIVE_HOSTILES)
	ordinary_due_flags.resize(EnemyStore.MAX_LIVE_HOSTILES)
	ordinary_due_decision_deltas.resize(EnemyStore.MAX_LIVE_HOSTILES)
	ordinary_due_motion_deltas.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_due_stamps.fill(0)


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
	_pull_enemys_by_squad.clear()
	active_cap_count = 0
	committed_points = 0.0
	committed_ranged = 0
	committed_denial = 0
	committed_pull_enemys = 0
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
			if enemy.role == &"ordinary_pull_01":
				_note_pull_enemy_commit(enemy)
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
		var due_index := ordinary_due.size()
		ordinary_due.append(enemy)
		ordinary_due_flags[due_index] = (
			(WORK_DECISION_DUE if decision_now else 0)
			| (WORK_MOTION_DUE if motion_now else 0)
		)
		ordinary_due_decision_deltas[due_index] = (
			_decision_delta[slot] if decision_now else 0.0
		)
		ordinary_due_motion_deltas[due_index] = (
			_motion_delta[slot] if motion_now else 0.0
		)


func decision_due(enemy: EnemyState) -> bool:
	var slot := enemy.runtime_slot
	return (
		slot >= 0
		and slot < _decision_due.size()
		and _due_stamps[slot] == _schedule_id
		and _decision_due[slot] != 0
	)


func motion_due(enemy: EnemyState) -> bool:
	var slot := enemy.runtime_slot
	return (
		slot >= 0
		and slot < _motion_due.size()
		and _due_stamps[slot] == _schedule_id
		and _motion_due[slot] != 0
	)


func is_critical(enemy: EnemyState) -> bool:
	var slot := enemy.runtime_slot
	return (
		slot >= 0
		and slot < _critical_due.size()
		and _due_stamps[slot] == _schedule_id
		and _critical_due[slot] != 0
	)


func decision_delta(enemy: EnemyState) -> float:
	var slot := enemy.runtime_slot
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
	var slot := enemy.runtime_slot
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
	var slot := enemy.runtime_slot
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
			enemy.role != &"ordinary_pull_01"
			or (
				committed_pull_enemys < 2
				and int(_pull_enemys_by_squad.get(enemy.squad_id, 0)) < 1
			)
		)
	)


func note_commit(enemy: EnemyState) -> void:
	committed_points += enemy.threat_cost
	match enemy.threat_kind:
		&"ranged":
			committed_ranged += 1
		&"denial":
			committed_denial += 1
	if enemy.role == &"ordinary_pull_01":
		_note_pull_enemy_commit(enemy)


func carrier_child_count(carrier_id: String) -> int:
	return int(_carrier_children.get(carrier_id, 0))


func note_carrier_child(carrier_id: String) -> void:
	_carrier_children[carrier_id] = carrier_child_count(carrier_id) + 1


func prune_inactive() -> void:
	## Reconciles a cap decision without rebuilding or discarding due lanes.
	_prune_worklist(active)
	_prune_worklist(supports)
	_prune_worklist(critical)
	_prune_ordinary_due()
	active_cap_count = 0
	committed_points = 0.0
	committed_ranged = 0
	committed_denial = 0
	committed_pull_enemys = 0
	_pull_enemys_by_squad.clear()
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
			if enemy.role == &"ordinary_pull_01":
				_note_pull_enemy_commit(enemy)


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
		"committed_pull_enemys":committed_pull_enemys,
		"carrier_count":_carrier_children.size(),
	}


func _note_pull_enemy_commit(enemy: EnemyState) -> void:
	committed_pull_enemys += 1
	_pull_enemys_by_squad[enemy.squad_id] = int(
		_pull_enemys_by_squad.get(enemy.squad_id, 0)
	) + 1


func _prune_worklist(worklist: Array[EnemyState]) -> void:
	for index in range(worklist.size() - 1, -1, -1):
		var enemy := worklist[index]
		if enemy == null or not enemy.alive or not enemy.active:
			worklist.remove_at(index)


func _prune_ordinary_due() -> void:
	## Compact the actor list and its parallel receipt columns as one unit.
	var write_index := 0
	for read_index in ordinary_due.size():
		var enemy := ordinary_due[read_index]
		if enemy == null or not enemy.alive or not enemy.active:
			continue
		if write_index != read_index:
			ordinary_due[write_index] = enemy
			ordinary_due_flags[write_index] = ordinary_due_flags[read_index]
			ordinary_due_decision_deltas[write_index] = (
				ordinary_due_decision_deltas[read_index]
			)
			ordinary_due_motion_deltas[write_index] = (
				ordinary_due_motion_deltas[read_index]
			)
		write_index += 1
	ordinary_due.resize(write_index)
