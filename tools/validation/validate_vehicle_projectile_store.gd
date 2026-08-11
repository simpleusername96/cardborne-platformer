extends SceneTree

const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var store := ProjectileStore.new()
	for index in ProjectileStore.PLAYER_CAPACITY:
		store.add_player(_projectile(Vector2(index, 0.0)))
	_expect(store.player_count() == ProjectileStore.PLAYER_CAPACITY, "player capacity fills exactly")
	store.add_player(_projectile(Vector2(999.0, 0.0)))
	_expect(store.player_count() == ProjectileStore.PLAYER_CAPACITY, "player overflow retires exactly one projectile")
	_expect(
		not store.player_live.any(func(item) -> bool: return item.pos == Vector2.ZERO)
		and store.player_live.any(func(item) -> bool: return item.pos == Vector2(999.0, 0.0)),
		"player overflow retires the oldest uniform round"
	)

	var ordinary_limit := ProjectileStore.HOSTILE_CAPACITY - ProjectileStore.HOSTILE_BOSS_RESERVE
	for index in ordinary_limit + 8:
		store.add_hostile(_projectile(Vector2(index, 20.0)), false)
	_expect(store.hostile_count() == ordinary_limit, "ordinary hostile fire preserves boss reserve")
	for index in ProjectileStore.HOSTILE_BOSS_RESERVE:
		store.add_hostile(_projectile(Vector2(index, 40.0)), true)
	_expect(store.hostile_count() == ProjectileStore.HOSTILE_CAPACITY, "boss fire can fill the reserved hostile slots")

	var interleaved_store := ProjectileStore.new()
	for index in 12:
		interleaved_store.add_hostile(_projectile(Vector2(index, 60.0)), true)
	for index in ordinary_limit:
		interleaved_store.add_hostile(_projectile(Vector2(index, 80.0)), false)
	_expect(
		interleaved_store.hostile_count() == ordinary_limit + 12,
		"ordinary quota remains available when boss shots are inserted first"
	)
	_expect(interleaved_store.validate_counts(), "mixed insertion order preserves hostile accounting")
	var retired_boss := interleaved_store.retire_boss_hostiles()
	var selective_snapshot := interleaved_store.debug_snapshot()
	_expect(
		retired_boss == 12
			and int(selective_snapshot["boss_hostile"]) == 0
			and int(selective_snapshot["ordinary_hostile"]) == ordinary_limit
			and interleaved_store.validate_counts(),
		"boss retirement preserves every ordinary hostile and pool counter"
	)

	var reuse_store := ProjectileStore.new()
	var elite_projectile := _projectile(Vector2(10.0, 10.0))
	elite_projectile["threat_tier"] = AttackContract.THREAT_ELITE
	reuse_store.add_hostile(elite_projectile)
	_expect(
		reuse_store.hostile_live[0].threat_tier == AttackContract.THREAT_ELITE,
		"hostile projectile retains its configured threat tier"
	)
	reuse_store.remove_hostile_at_swap(0)
	reuse_store.add_hostile(_projectile(Vector2(20.0, 10.0)))
	_expect(
		reuse_store.hostile_live[0].threat_tier == AttackContract.THREAT_ORDINARY,
		"pooled projectile reuse resets a stale threat tier"
	)

	var before_clear := store.hostile_count()
	var cleared := store.clear_hostiles_in_radius(Vector2.ZERO, 25.0)
	_expect(cleared > 0 and store.hostile_count() == before_clear - cleared, "radius clear uses swap retirement and updates counts")
	_expect(store.validate_counts(), "tracked projectile counts match live storage")
	store.retain_player_only()
	_expect(store.hostile_count() == 0 and store.player_count() == ProjectileStore.PLAYER_CAPACITY, "team retention clears all hostile projectiles")
	var retained_snapshot := store.debug_snapshot()
	_expect(
		retained_snapshot["hostile_pool"] == ProjectileStore.HOSTILE_CAPACITY,
		"hostile retirement returns every state to the preallocated pool"
	)
	store.clear()
	var cleared_snapshot := store.debug_snapshot()
	_expect(
		cleared_snapshot["player_pool"] == ProjectileStore.PLAYER_CAPACITY
		and cleared_snapshot["hostile_pool"] == ProjectileStore.HOSTILE_CAPACITY,
		"clear restores both fixed-size pools"
	)
	_expect(
		cleared_snapshot["rejected_player"] == 0
		and cleared_snapshot["rejected_hostile"] == 0,
		"clear resets run-local rejection diagnostics"
	)
	_expect(store.validate_counts(), "empty pools preserve capacity accounting")
	_finish()


func _projectile(position: Vector2) -> Dictionary:
	return {
		"pos": position,
		"velocity": Vector2.RIGHT,
		"radius": 5.0,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PROJECTILE_STORE_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
