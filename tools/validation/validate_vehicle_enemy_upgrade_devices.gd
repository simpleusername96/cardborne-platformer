extends SceneTree

const DeviceRuntime = preload(
	"res://scripts/vehicle/vehicle_enemy_upgrade_device_runtime.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const RecallRuntime = preload(
	"res://scripts/rewards/vehicle_recall_replenishment_runtime.gd"
)
const FeatureRun = preload(
	"res://scripts/vehicle/vehicle_run_enemy_upgrade_devices.gd"
)
const FeatureScene = preload("res://scenes/run/VehicleRun.tscn")

var failures: PackedStringArray = []


func _initialize() -> void:
	_validate_feature_scene_integration()
	_validate_capture_and_activation()
	_validate_player_owned_destruction()
	_validate_objective_intent()
	_validate_stage_health_scaling()
	_validate_recall_frequency()
	if failures.is_empty():
		print("vehicle enemy upgrade device validation passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _validate_feature_scene_integration() -> void:
	var run := FeatureScene.instantiate()
	_expect(run is FeatureRun, "VehicleRun scene must instantiate the enemy-upgrade feature layer.")
	if run != null:
		run.free()


func _validate_capture_and_activation() -> void:
	var runtime := DeviceRuntime.new()
	var no_enemies: Array[EnemyState] = []
	runtime.configure(_blueprint(), 101, &"stage_01")
	runtime.set_context(no_enemies, 0)
	runtime.refresh_publication(
		Rect2(-5000.0, -5000.0, 10000.0, 10000.0),
		Vector2.ZERO
	)
	var snapshot: Array[Dictionary] = []
	runtime.fill_device_snapshot(snapshot)
	_expect(snapshot.size() == 1, "Exactly one upgrade device must be published.")
	if snapshot.is_empty():
		return
	_expect(
		StringName(snapshot[0]["id"]) == &"test_device_5",
		"The first device must use the unresolved socket farthest from the player."
	)
	var center := Vector2(snapshot[0]["position"])
	var enemies: Array[EnemyState] = [
		_enemy("capture_a", center + Vector2(20.0, 0.0)),
		_enemy("capture_b", center + Vector2(-20.0, 0.0)),
		_enemy("capture_c", center + Vector2(0.0, 20.0)),
	]
	var events: Array[Dictionary] = []
	runtime.set_context(enemies, 0)
	runtime.advance(2.0, events)
	enemies[2].pos = center + Vector2(DeviceRuntime.CAPTURE_RADIUS + 1.0, 0.0)
	runtime.advance(0.01, events)
	runtime.fill_device_snapshot(snapshot)
	_expect(
		is_zero_approx(float(snapshot[0]["capture_elapsed"])),
		"Losing one of the three required enemies must reset the channel."
	)
	enemies[2].pos = center + Vector2(0.0, 20.0)
	runtime.advance(DeviceRuntime.CAPTURE_SECONDS + 0.01, events)
	_expect(events.size() == 1, "Three nearby enemies must activate after five seconds.")
	if not events.is_empty():
		_expect(
			StringName(events[0]["kind"]) == &"enemy_upgrade_device_activated",
			"Activation must emit the typed upgrade event."
		)
		_expect(
			is_equal_approx(float(events[0]["health_bonus"]), 30.0),
			"Activation health bonus must be 30."
		)
		_expect(
			is_equal_approx(float(events[0]["damage_multiplier"]), 0.12),
			"Activation damage multiplier must be 0.12."
		)
		_expect(
			is_equal_approx(float(events[0]["speed_bonus"]), 3.0),
			"Activation speed bonus must be 3."
		)


func _validate_player_owned_destruction() -> void:
	var runtime := DeviceRuntime.new()
	var no_enemies: Array[EnemyState] = []
	runtime.configure(_blueprint(), 202, &"stage_01")
	runtime.set_context(no_enemies, 0)
	runtime.refresh_publication(Rect2(), Vector2.ZERO)
	var snapshot: Array[Dictionary] = []
	runtime.fill_device_snapshot(snapshot)
	if snapshot.is_empty():
		_expect(false, "Destruction validation requires an active device.")
		return
	var device_id := StringName(snapshot[0]["id"])
	var center := Vector2(snapshot[0]["position"])
	var segment_hit := {}
	_expect(
		runtime.first_intact_segment_hit(
			center + Vector2(-200.0, 0.0),
			center + Vector2(200.0, 0.0),
			0.0,
			segment_hit
		),
		"Player-primary structure queries must stop at the device."
	)
	_expect(
		float(segment_hit.get("t", INF)) >= 0.0
			and float(segment_hit.get("t", INF)) <= 1.0,
		"Device projectile blocking must publish an ordered segment hit."
	)
	var hostile := runtime.receive_damage(device_id, 9999.0, &"hostile", &"projectile")
	_expect(not bool(hostile["accepted"]), "Hostile attacks must not damage the device.")
	var first_player_hit := runtime.receive_damage(device_id, 1.0, &"player", &"projectile")
	_expect(bool(first_player_hit["accepted"]), "Player projectile damage must be accepted.")
	runtime.fill_device_snapshot(snapshot)
	_expect(
		float(snapshot[0].get("hit_flash_remaining", 0.0)) > 0.0
			and not bool(snapshot[0].get("projectiles_blocked", true))
			and bool(snapshot[0].get("player_primary_projectiles_blocked", false)),
		"Accepted damage must publish hit feedback and player-projectile blocking."
	)
	var player := runtime.receive_damage(device_id, 9999.0, &"player", &"projectile")
	_expect(bool(player["accepted"]), "Player projectile damage must be accepted.")
	_expect(bool(player["broken"]), "Player damage must destroy the device at zero health.")
	runtime.refresh_publication(Rect2(), Vector2.ZERO)
	snapshot.clear()
	runtime.fill_device_snapshot(snapshot)
	_expect(snapshot.is_empty(), "The next device must not publish during the delay.")
	var events: Array[Dictionary] = []
	runtime.advance(DeviceRuntime.RESPAWN_DELAY_SECONDS - 0.01, events)
	runtime.refresh_publication(Rect2(), Vector2.ZERO)
	runtime.fill_device_snapshot(snapshot)
	_expect(snapshot.is_empty(), "The full nine-second publication delay must be preserved.")
	runtime.advance(0.02, events)
	runtime.refresh_publication(Rect2(), Vector2.ZERO)
	runtime.fill_device_snapshot(snapshot)
	_expect(
		snapshot.size() == 1 and StringName(snapshot[0]["id"]) != device_id,
		"A different unresolved device must publish after the delay."
	)


func _validate_objective_intent() -> void:
	var runtime := DeviceRuntime.new()
	runtime.configure(_blueprint(), 505, &"stage_01")
	runtime.refresh_publication(Rect2(), Vector2.ZERO)
	var snapshot: Array[Dictionary] = []
	runtime.fill_device_snapshot(snapshot)
	if snapshot.is_empty():
		_expect(false, "Objective-intent validation requires an active device.")
		return
	var center := Vector2(snapshot[0]["position"])
	var enemies: Array[EnemyState] = [
		_enemy("objective_a", center + Vector2(700.0, 0.0)),
		_enemy("objective_b", center + Vector2(760.0, 80.0)),
		_enemy("objective_c", center + Vector2(820.0, -80.0)),
	]
	runtime.set_context(enemies, 0)
	var events: Array[Dictionary] = []
	runtime.advance(0.01, events)
	for enemy in enemies:
		_expect(
			runtime.is_enemy_assigned(enemy.id),
			"The three nearest mobile enemies must be assigned to the device."
		)
	var run := FeatureRun.new()
	run._enemy_upgrade_runtime = runtime
	run.enemies.assign(enemies)
	run.player_position = center + Vector2(2000.0, 0.0)
	var assigned := enemies[0]
	run._prepare_enemy_for_upgrade_objective(assigned)
	assigned.desired_velocity = run._desired_enemy_velocity(assigned, false)
	var smoothed := run._smoothed_enemy_velocity(assigned, 0.1, false)
	_expect(
		smoothed.dot(center - assigned.pos) > 0.0
			and assigned.movement_reason == &"enemy_upgrade_device",
		"Assigned pursuit enemies must keep moving toward the device even when it is away from the player."
	)
	run.free()


func _validate_stage_health_scaling() -> void:
	var early := DeviceRuntime.new()
	var late := DeviceRuntime.new()
	var no_enemies: Array[EnemyState] = []
	early.configure(_blueprint(), 303, &"stage_01")
	early.set_context(no_enemies, 0)
	early.refresh_publication(Rect2(), Vector2.ZERO)
	late.configure(_blueprint(), 404, &"stage_06")
	late.set_context(no_enemies, 5)
	late.refresh_publication(Rect2(), Vector2.ZERO)
	var early_snapshot: Array[Dictionary] = []
	var late_snapshot: Array[Dictionary] = []
	early.fill_device_snapshot(early_snapshot)
	late.fill_device_snapshot(late_snapshot)
	_expect(
		float(late_snapshot[0]["max_health"]) > float(early_snapshot[0]["max_health"]),
		"Device health must increase with stage index."
	)


func _validate_recall_frequency() -> void:
	_expect(
		is_equal_approx(RecallRuntime.START_SECONDS, 90.0),
		"Recall replenishment must begin at 90 active-run seconds."
	)
	_expect(
		is_equal_approx(RecallRuntime.INTERVAL_SECONDS, 30.0),
		"Recall replenishment interval must be 30 seconds."
	)


func _blueprint() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in DeviceRuntime.MAX_DEVICES:
		result.append({
			"id":StringName("test_device_%d" % index),
			"pos":Vector2(float(index) * 800.0, 0.0),
		})
	return result


func _enemy(enemy_id: String, position: Vector2) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = enemy_id
	enemy.role = &"ordinary_edge_01"
	enemy.archetype = &"ordinary_pursuer_t1"
	enemy.pos = position
	enemy.speed = 180.0
	enemy.alive = true
	enemy.active = true
	return enemy


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
