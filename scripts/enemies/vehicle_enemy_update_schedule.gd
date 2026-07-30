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
	&"stage_boss", &"generator", &"boss_pylon",
]
const SUPPORT_ROLES: Array[StringName] = [
	&"generator", &"shield_escort",
]

var alive: Array[EnemyState] = []
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
var _critical_due := PackedByteArray()
var _motion_delta := PackedFloat32Array()
var _rammers_by_squad: Dictionary = {}
var _carrier_children: Dictionary = {}


func _init() -> void:
	_decision_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_critical_due.resize(EnemyStore.MAX_LIVE_HOSTILES)
	_motion_delta.resize(EnemyStore.MAX_LIVE_HOSTILES)


func rebuild(
	enemies: Array[EnemyState],
	delta: float,
	player_position: Vector2,
	far_distance_squared: float,
	decision_bucket: int,
	near_motion_bucket: int,
	far_motion_bucket: int
) -> void:
	alive.clear()
	active.clear()
	supports.clear()
	critical.clear()
	ordinary_due.clear()
	_decision_due.fill(0)
	_critical_due.fill(0)
	_motion_delta.fill(0.0)
	_rammers_by_squad.clear()
	_carrier_children.clear()
	active_cap_count = 0
	committed_points = 0.0
	committed_ranged = 0
	committed_denial = 0
	committed_rammers = 0

	for enemy in enemies:
		if enemy == null or not enemy.alive:
			continue
		alive.append(enemy)
		if not enemy.carrier_id.is_empty():
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
		if enemy.role in SPECIAL_ROLES:
			continue
		var slot := enemy.runtime_slot
		if slot < 0 or slot >= EnemyStore.MAX_LIVE_HOSTILES:
			continue
		if enemy.phase in CRITICAL_PHASES:
			enemy.decision_elapsed = 0.0
			enemy.motion_elapsed = 0.0
			_critical_due[slot] = 1
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
		_motion_delta[slot] = enemy.motion_elapsed
		enemy.motion_elapsed = 0.0
		if decision_now:
			_decision_due[slot] = 1
			enemy.decision_elapsed = 0.0
		ordinary_due.append(enemy)


func decision_due(enemy: EnemyState) -> bool:
	var slot := enemy.runtime_slot
	return slot >= 0 and slot < _decision_due.size() and _decision_due[slot] != 0


func is_critical(enemy: EnemyState) -> bool:
	var slot := enemy.runtime_slot
	return slot >= 0 and slot < _critical_due.size() and _critical_due[slot] != 0


func motion_delta(enemy: EnemyState) -> float:
	var slot := enemy.runtime_slot
	return float(_motion_delta[slot]) if slot >= 0 and slot < _motion_delta.size() else 0.0


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
	committed_points += enemy.threat_cost
	match enemy.threat_kind:
		&"ranged":
			committed_ranged += 1
		&"denial":
			committed_denial += 1
	if enemy.role == &"rammer":
		_note_rammer_commit(enemy)


func carrier_child_count(carrier_id: String) -> int:
	return int(_carrier_children.get(carrier_id, 0))


func note_carrier_child(carrier_id: String) -> void:
	_carrier_children[carrier_id] = carrier_child_count(carrier_id) + 1


func debug_snapshot() -> Dictionary:
	return {
		"alive":alive.size(),
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
