extends SceneTree

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const Schedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")

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

	var schedule := Schedule.new()
	schedule.rebuild(store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 0, 0, 0)
	var first := schedule.debug_snapshot()
	_expect(int(first["alive"]) == 320, "schedule retains deterministic alive order")
	_expect(int(first["active"]) == 300, "schedule filters inactive states once")
	_expect(int(first["active_cap_count"]) == 276, "schedule snapshots the active-cap count")
	_expect(int(first["critical"]) == 2, "startup and active ordinary actors stay critical")
	_expect(int(first["committed_rammers"]) == 2, "schedule snapshots committed rammers")
	_expect(schedule.carrier_child_count(carrier.id) == 3, "carrier child count is precomputed")
	_expect(not schedule.rammer_can_commit(store.live[7]), "global rammer cap blocks another commit")
	_expect(schedule.supports.size() == 1 and schedule.supports[0] == support, "support worklist preserves store order")

	rammer_b.phase = &"move"
	schedule.rebuild(store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 1, 1, 1)
	_expect(not schedule.rammer_can_commit(rammer_a), "same-squad rammer cannot overlap")
	var other_squad := store.live[7]
	other_squad.role = &"rammer"
	other_squad.squad_id = "gamma"
	_expect(schedule.rammer_can_commit(other_squad), "different squad can use the second global rammer slot")
	schedule.note_commit(other_squad)
	_expect(not schedule.rammer_can_commit(store.live[8]), "local commit update closes the global rammer cap")

	for tick in 12:
		schedule.rebuild(
			store.live, 1.0 / 60.0, Vector2(2800.0, 1700.0), 820.0 * 820.0,
			tick % 6, tick % 2, tick % 3
		)
	var due_snapshot := schedule.debug_snapshot()
	_expect(int(due_snapshot["ordinary_due"]) > 0, "10 Hz decision work becomes due")
	var previous_alive := schedule.alive.duplicate()
	schedule.rebuild(store.live, 0.0, Vector2(2800.0, 1700.0), 820.0 * 820.0, 0, 0, 0)
	_expect(schedule.alive == previous_alive, "zero-delta rebuild preserves deterministic worklist order")
	_finish()


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
