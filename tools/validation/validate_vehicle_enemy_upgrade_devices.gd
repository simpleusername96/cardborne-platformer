extends SceneTree

const DeviceRuntime = preload(
	"res://scripts/vehicle/vehicle_enemy_upgrade_device_runtime.gd"
)
const ObjectiveFieldSet = preload(
	"res://scripts/enemies/vehicle_objective_pursuit_field_set.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const FeatureRun = preload(
	"res://scripts/vehicle/vehicle_run_enemy_upgrade_devices.gd"
)
const FeatureScene = preload("res://scenes/run/VehicleRun.tscn")

var failures: PackedStringArray = []


func _initialize() -> void:
	_validate_feature_scene_integration()
	_validate_continuous_publication_lifecycle()
	_validate_real_enemy_claims_and_capture()
	_validate_objective_field_budget()
	_validate_upgrade_application_and_tier_cap()
	_validate_collision_ordering_and_minimap_markers()
	_validate_counted_bilingual_outcomes()
	if failures.is_empty():
		print("vehicle enemy upgrade device validation passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _validate_feature_scene_integration() -> void:
	var run := FeatureScene.instantiate()
	_expect(run is FeatureRun, "VehicleRun scene must use the enemy-upgrade feature layer.")
	if run != null:
		run.free()


func _validate_continuous_publication_lifecycle() -> void:
	var runtime := DeviceRuntime.new()
	var no_enemies: Array[EnemyState] = []
	runtime.set_context(no_enemies, 0)
	runtime.configure(_selection_blueprint(), 101, &"stage_1")
	var visible_world := Rect2(-640.0, -360.0, 1280.0, 720.0)
	runtime.refresh_publication(visible_world, Vector2.ZERO)
	var active := _active_snapshots(runtime)
	var lifecycle_events: Array[Dictionary] = []
	_expect(
		active.size() == DeviceRuntime.ACTIVE_DEVICE_LIMIT,
		"The first ordinary-combat cycle must immediately publish exactly one device."
	)
	if active.is_empty():
		return
	_expect(
		StringName(active[0]["id"]) == &"test_device_3",
		"Publication must prefer an offscreen socket near the preferred player distance."
	)
	_expect(
		is_equal_approx(float(active[0]["max_health"]), DeviceRuntime.BASE_HEALTH),
		"Device health must use the run-level constant rather than stage scaling."
	)
	var first_id := StringName(active[0]["id"])
	runtime.configure(_selection_blueprint(), 101, &"stage_2")
	active = _active_snapshots(runtime)
	_expect(
		active.size() == 1 and StringName(active[0]["id"]) == first_id,
		"Changing stage context on the same field must not retire or republish the device."
	)
	var publication_count := 1
	for resolution_index in 8:
		active = _active_snapshots(runtime)
		if active.is_empty():
			_expect(false, "Continuous lifecycle requires an active device before resolution.")
			return
		var broken := runtime.receive_damage(
			StringName(active[0]["id"]), 99999.0, &"player", &"projectile"
		)
		_expect(
			bool(broken["broken"]),
			"Player damage must resolve each active device."
		)
		runtime.advance(
			DeviceRuntime.RESPAWN_DELAY_SECONDS - 0.01, lifecycle_events
		)
		runtime.refresh_publication(visible_world, Vector2.ZERO)
		_expect(
			_active_snapshots(runtime).is_empty(),
			"A resolved device must remain absent until the full respawn delay elapses."
		)
		runtime.advance(0.02, lifecycle_events)
		runtime.refresh_publication(visible_world, Vector2.ZERO)
		_expect(
			_active_snapshots(runtime).size() == 1,
			"The device must republish after nine seconds without exhausting six sockets."
		)
		publication_count += 1
	_expect(
		publication_count > DeviceRuntime.MAX_DEVICES,
		"The continuous lifecycle must reuse authored sockets after more than six outcomes."
	)
	runtime.set_publication_enabled(false)
	_expect(
		_active_snapshots(runtime).is_empty(),
		"Boss warning must silently retire the ordinary-combat objective."
	)
	runtime.advance(DeviceRuntime.RESPAWN_DELAY_SECONDS + 5.0, lifecycle_events)
	var paused_snapshot := runtime.snapshot()
	_expect(
		is_equal_approx(
			float(paused_snapshot["respawn_delay"]),
			DeviceRuntime.RESPAWN_DELAY_SECONDS
		),
		"Boss and transition time must not consume the ordinary-combat respawn delay."
	)
	runtime.set_publication_enabled(true)
	runtime.advance(DeviceRuntime.RESPAWN_DELAY_SECONDS + 0.01, lifecycle_events)
	runtime.refresh_publication(visible_world, Vector2.ZERO)
	_expect(
		_active_snapshots(runtime).size() == 1,
		"The paused lifecycle must resume when ordinary combat returns."
	)


func _validate_real_enemy_claims_and_capture() -> void:
	var runtime := DeviceRuntime.new()
	runtime.configure(_spaced_blueprint(), 202, &"stage_2")
	runtime.refresh_publication(Rect2(), Vector2.ZERO)
	var active := _active_snapshots(runtime)
	if active.is_empty():
		_expect(false, "Claim validation requires an active device.")
		return
	var center := Vector2(active[0]["position"])
	var run := FeatureRun.new()
	var spawned: EnemyState = run._make_enemy({
		"id":"real_leashed_enemy",
		"role":&"ordinary_pursuer_t1",
		"pos":center + Vector2(420.0, 0.0),
		"active":true,
		"leash_rect":Rect2(center - Vector2(800.0, 800.0), Vector2(1600.0, 1600.0)),
	})
	_expect(
		spawned != null and spawned.leash_rect.has_area(),
		"The production encounter materializer must retain a non-empty leash."
	)
	if spawned == null:
		run.free()
		return
	var eligible_b := _enemy("eligible_b", center + Vector2(460.0, 40.0))
	var eligible_c := _enemy("eligible_c", center + Vector2(500.0, -40.0))
	var fourth := _enemy("eligible_d", center + Vector2(520.0, 0.0))
	var boss := _enemy("boss", center + Vector2(60.0, 0.0))
	boss.role = &"boss"
	boss.archetype = &"boss_actor"
	var summon := _enemy("summon", center + Vector2(70.0, 0.0))
	summon.summoned = true
	var fixed := _enemy("fixed", center + Vector2(80.0, 0.0))
	fixed.role = &"ordinary_fixed_ranged_01"
	var mine := _enemy("mine", center + Vector2(90.0, 0.0))
	mine.role = &"ordinary_area_01"
	var enemies: Array[EnemyState] = [
		spawned, eligible_b, eligible_c, fourth, boss, summon, fixed, mine,
	]
	runtime.set_context(enemies, 1)
	var events: Array[Dictionary] = []
	runtime.advance(0.01, events)
	for expected in [spawned, eligible_b, eligible_c]:
		_expect(
			runtime.is_enemy_assigned(expected.id),
			"The three nearest eligible mobile enemies must receive stable claims."
		)
	for excluded in [fourth, boss, summon, fixed, mine]:
		_expect(
			not runtime.is_enemy_assigned(excluded.id),
			"Fourth, boss, summon, fixed, and mine candidates must not claim a slot."
		)
	run._enemy_upgrade_runtime = runtime
	run.enemies.assign(enemies)
	run._prepare_enemy_for_upgrade_objective(spawned)
	var intent := run._desired_enemy_velocity(spawned, false)
	_expect(
		intent.dot(center - spawned.pos) > 0.0
			and spawned.movement_reason == &"enemy_upgrade_device",
		"A real leashed enemy must redirect toward its claimed device."
	)
	for participant in [spawned, eligible_b, eligible_c]:
		participant.pos = center + Vector2(float(participant.id.hash() % 40), 0.0)
	runtime.advance(2.0, events)
	eligible_c.pos = center + Vector2(DeviceRuntime.CAPTURE_RADIUS + 24.0, 0.0)
	runtime.advance(0.01, events)
	active = _active_snapshots(runtime)
	_expect(
		runtime.is_enemy_assigned(eligible_c.id)
			and not active.is_empty()
			and is_zero_approx(float(active[0]["capture_elapsed"])),
		"Leaving capture range must reset channel time without discarding a valid claim."
	)
	eligible_c.pos = center + Vector2(20.0, 0.0)
	runtime.advance(DeviceRuntime.CAPTURE_SECONDS + 0.01, events)
	_expect(events.size() == 1, "Three claimed enemies must activate after five seconds.")
	if not events.is_empty():
		_expect(
			Array(events[0]["participant_ids"]).size() == 3,
			"Activation must publish all three participant IDs."
		)
	run.free()


func _validate_objective_field_budget() -> void:
	var fields := ObjectiveFieldSet.new()
	fields.reset(&"stage_2", [Rect2(3450.0, 1200.0, 300.0, 1920.0)])
	var targets := {
		&"field_a":Vector2(900.0, 1080.0),
		&"field_b":Vector2(6300.0, 1080.0),
		&"field_c":Vector2(900.0, 3240.0),
		&"field_d":Vector2(6300.0, 3240.0),
	}
	var ready := false
	for _tick in 80:
		fields.update(targets, true)
		_expect(
			fields.last_processed_cells() <= ObjectiveFieldSet.MAX_COMBINED_CELLS_PER_TICK,
			"The device route field must stay inside the fixed 512-cell per-tick budget."
		)
		var snapshot := fields.debug_snapshot()
		ready = true
		for record_variant in Array(snapshot["fields"]):
			var record := Dictionary(record_variant)
			ready = ready and bool(record["ready"]) and int(record["reachable"]) > 0
		if ready:
			break
	_expect(ready, "The single device route field must converge around authored blockers.")
	_expect(
		fields.path_cost(&"field_a", Vector2(3600.0, 3600.0)) >= 0,
		"The completed route field must retain a reachable path sample."
	)
	var bounded := fields.debug_snapshot()
	_expect(
		int(bounded["target_count"]) == 1
			and int(bounded["target_capacity"]) == 1
			and int(bounded["cell_capacity"]) == ObjectiveFieldSet.CELL_COUNT,
		"Extra target input must not expand the singleton route-field capacity."
	)


func _validate_upgrade_application_and_tier_cap() -> void:
	var run := FeatureRun.new()
	var participant := _enemy("participant", Vector2.ZERO)
	participant.health = 40.0
	participant.max_health = 50.0
	participant.speed = 190.0
	run.enemies.assign([participant])
	run._apply_personal_enemy_upgrade(participant.id)
	run._apply_personal_enemy_upgrade(participant.id)
	_expect(
		is_equal_approx(participant.health, 70.0)
			and is_equal_approx(participant.max_health, 80.0)
			and is_equal_approx(participant.speed, 193.0)
			and is_equal_approx(participant.pack_damage_multiplier, 1.12),
		"Immediate personal augmentation must apply exactly once to a participant."
	)
	var baseline: EnemyState = run._make_enemy({
		"id":"baseline_admission", "role":&"ordinary_pursuer_t1",
		"pos":Vector2.ZERO, "active":true,
	})
	for activation_index in 7:
		run._apply_enemy_upgrade_activation({
			"participant_ids":[] if activation_index > 0 else [participant.id],
		})
	var future: EnemyState = run._make_enemy({
		"id":"future_admission", "role":&"ordinary_pursuer_t1",
		"pos":Vector2.ZERO, "active":true,
	})
	if baseline == null or future == null:
		_expect(false, "Future-admission validation requires production-created enemies.")
	else:
		run._apply_upgrade_damage_multiplier(future)
		_expect(
			run.enemy_upgrade_tier == DeviceRuntime.MAX_RUN_UPGRADE_TIER
				and is_equal_approx(future.max_health - baseline.max_health, 180.0)
				and is_equal_approx(future.speed - baseline.speed, 18.0)
				and is_equal_approx(future.pack_damage_multiplier, 1.72),
			"A seventh activation must preserve the exact six-tier future-admission cap."
		)
	run.free()


func _validate_collision_ordering_and_minimap_markers() -> void:
	var runtime := DeviceRuntime.new()
	var blueprint: Array[Dictionary] = []
	for index in DeviceRuntime.MAX_DEVICES:
		blueprint.append({
			"id":StringName("line_device_%d" % index),
			"pos":Vector2(300.0 + float(index) * 300.0, 1000.0),
		})
	runtime.configure(blueprint, 303, &"stage_2")
	runtime.refresh_publication(Rect2(), Vector2.ZERO)
	var active := _active_snapshots(runtime)
	var expected := active[0]
	for device in active:
		if Vector2(device["position"]).x < Vector2(expected["position"]).x:
			expected = device
	runtime.devices.reverse()
	var hit := {}
	_expect(
		runtime.first_intact_segment_hit(
			Vector2(0.0, 1000.0), Vector2(2400.0, 1000.0), 0.0, hit
		),
		"Player-primary collision must inspect every active device."
	)
	_expect(
		StringName(hit.get("device_id", &"")) == StringName(expected["id"]),
		"Segment collision must choose the nearest geometric hit independent of array order."
	)
	var run := FeatureRun.new()
	run.mystery_device_runtime = runtime
	var expected_device_index := runtime._device_index_by_id(StringName(expected["id"]))
	var health_before := float(runtime.devices[expected_device_index]["health"])
	run._damage_mystery_devices_in_radius(
		Vector2(expected["position"])
			+ Vector2.RIGHT * (DeviceRuntime.COLLISION_RADIUS + 10.1),
		10.0,
		1.0
	)
	_expect(
		is_equal_approx(
			float(runtime.devices[expected_device_index]["health"]), health_before
		),
		"Area damage just outside the device snapshot radius must remain safe."
	)
	var minimap := run._minimap_snapshot(false)
	var marker_count := 0
	for marker_variant in Array(minimap["markers"]):
		if StringName(Dictionary(marker_variant)["kind"]) == &"mystery_device":
			marker_count += 1
	_expect(marker_count == 1, "The one active device must publish one minimap marker.")
	run.free()


func _validate_counted_bilingual_outcomes() -> void:
	var run := FeatureRun.new()
	run._record_enemy_upgrade_outcome(&"activated")
	run._record_enemy_upgrade_outcome(&"destroyed")
	run._record_enemy_upgrade_outcome(&"activated")
	run._record_enemy_upgrade_outcome(&"destroyed")
	var previous_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var english := run._enemy_upgrade_notification_message()
	TranslationServer.set_locale("ko")
	var korean := run._enemy_upgrade_notification_message()
	TranslationServer.set_locale(previous_locale)
	_expect(
		english.contains("activated 2") and english.contains("destroyed 2"),
		"English outcome text must preserve final same-tick activation/destruction counts."
	)
	_expect(
		korean.contains("활성화 2") and korean.contains("파괴 2"),
		"Korean outcome text must preserve final same-tick activation/destruction counts."
	)
	run.free()


func _selection_blueprint() -> Array[Dictionary]:
	return [
		{"id":&"test_device_0", "pos":Vector2(100.0, 0.0)},
		{"id":&"test_device_1", "pos":Vector2(1000.0, 0.0)},
		{"id":&"test_device_2", "pos":Vector2(0.0, 1000.0)},
		{"id":&"test_device_3", "pos":Vector2(1000.0, 1000.0)},
		{"id":&"test_device_4", "pos":Vector2(500.0, 500.0)},
		{"id":&"test_device_5", "pos":Vector2(2000.0, 0.0)},
	]


func _spaced_blueprint() -> Array[Dictionary]:
	return [
		{"id":&"spaced_0", "pos":Vector2(900.0, 1080.0)},
		{"id":&"spaced_1", "pos":Vector2(2700.0, 1080.0)},
		{"id":&"spaced_2", "pos":Vector2(4500.0, 1080.0)},
		{"id":&"spaced_3", "pos":Vector2(6300.0, 1080.0)},
		{"id":&"spaced_4", "pos":Vector2(1800.0, 3240.0)},
		{"id":&"spaced_5", "pos":Vector2(5400.0, 3240.0)},
	]


func _active_snapshots(runtime) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	runtime.fill_device_snapshot(result)
	return result


func _enemy(enemy_id: String, position: Vector2) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = enemy_id
	enemy.role = &"ordinary_edge_01"
	enemy.archetype = &"ordinary_pursuer_t1"
	enemy.pos = position
	enemy.health = 40.0
	enemy.max_health = 40.0
	enemy.speed = 190.0
	enemy.pack_damage_multiplier = 1.0
	enemy.leash_rect = Rect2(position - Vector2(800.0, 800.0), Vector2(1600.0, 1600.0))
	enemy.alive = true
	enemy.active = true
	return enemy


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
