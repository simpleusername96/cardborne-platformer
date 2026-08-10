extends SceneTree

const FacilityRuntime = preload(
	"res://scripts/vehicle/vehicle_reinforcement_facility_runtime.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const MinimapBuilder = preload("res://scripts/ui/vehicle_minimap_mesh_builder.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_recurring_lifecycle()
	var facility := FacilityRuntime.new()
	facility.configure(0, Vector2(1200.0, 800.0))
	_expect(facility.state == &"dormant", "facility starts outside the enemy runtime as dormant")
	_expect(facility.get_script() != EnemyState, "facility is not an EnemyState")
	_expect(not facility.activate_if_ready(6, 20), "facility stays dormant below 35 percent")
	_expect(facility.activate_if_ready(7, 20), "facility activates at 35 percent")
	_expect(facility.advance(7.9, 0, 1).is_empty(), "stage one interval is eight seconds")
	var spawn := facility.advance(0.1, 0, 1)
	_expect(
		StringName(spawn.get("role", &"")) == &"chaser"
			and bool(spawn.get("summoned", false))
			and String(spawn.get("carrier_id", "")) == "reinforcement_facility",
		"stage one produces a bounded ordinary reinforcement"
	)
	_expect(facility.advance(8.0, 2, 1).is_empty(), "facility child cap blocks additional spawns")
	_expect(facility.advance(0.0, 0, 0).is_empty(), "global active cap blocks additional spawns")

	var hit_receipt := {}
	_expect(
		facility.first_active_segment_hit(
			Vector2(900.0, 800.0), Vector2(1500.0, 800.0), 4.0, hit_receipt
		),
		"active facility participates in direct projectile collision"
	)
	_expect(
		not facility.is_position_clear(facility.position, 24.0)
			and facility.is_position_clear(facility.position + Vector2(200.0, 0.0), 24.0),
		"active facility owns separate solid-body collision"
	)
	var rejected := facility.receive_damage(20.0, &"enemy", &"direct")
	_expect(not bool(rejected["accepted"]), "enemy attacks cannot damage the facility")
	var damaged := facility.receive_damage(100.0, &"player", &"area")
	_expect(
		bool(damaged["accepted"])
			and is_equal_approx(float(damaged["remaining_health"]), 200.0),
		"player direct and area damage use facility-owned health"
	)
	var destroyed := facility.receive_damage(300.0, &"player", &"direct")
	_expect(bool(destroyed["destroyed"]) and facility.state == &"destroyed", "facility destruction stops its lifecycle")
	_expect(facility.snapshot().get("visible", true) == false, "destroyed facility leaves the live presentation")

	facility.configure(4, Vector2(2400.0, 1400.0))
	_expect(facility.activate_if_ready(35, 100), "stage five uses the same clear trigger")
	var stage_five_spawn := facility.advance(4.0, 0, 1)
	_expect(
		StringName(stage_five_spawn.get("role", &"")) == &"splitter_barge"
			and int(facility.snapshot()["live_child_cap"]) == 6,
		"stage five escalates role, interval, and child cap"
	)

	var minimap := MinimapBuilder.build_triangle_channels({
		"cols":1,
		"rows":1,
		"visited":[Vector2i.ZERO],
		"world_size":Vector2(100.0, 100.0),
		"player":Vector2.ZERO,
		"player_facing":Vector2.RIGHT,
		"markers":[{"kind":&"reinforcement_facility", "position":Vector2(50.0, 50.0), "discovered":true}],
	}, Vector2(100.0, 100.0))
	_expect(minimap.has(Art.MUSTARD_DARK.to_rgba32()), "facility owns a distinct two-tone minimap marker")
	await _validate_run_integration()
	_finish()


func _validate_recurring_lifecycle() -> void:
	var expected_intervals := [8.0, 7.0, 6.0, 5.0, 4.0]
	var expected_caps := [2, 3, 4, 5, 6]
	var expected_roles: Array[StringName] = [
		&"chaser", &"shooter", &"rammer", &"bulkhead_guard", &"splitter_barge",
	]
	for stage_index in expected_intervals.size():
		var facility := FacilityRuntime.new()
		facility.configure(stage_index, Vector2(1000.0, 800.0))
		_expect(
			facility.activate_if_ready(35, 100),
			"Stage %d facility activates at the shared threshold" % (stage_index + 1)
		)
		var first := facility.advance(expected_intervals[stage_index], 0, 1)
		var second := facility.advance(expected_intervals[stage_index], 1, 1)
		_expect(
			StringName(first.get("role", &"")) == expected_roles[stage_index]
				and StringName(second.get("role", &"")) == expected_roles[stage_index]
				and String(first.get("id", "")) == "facility_reinforcement_0"
				and String(second.get("id", "")) == "facility_reinforcement_1",
			"Stage %d preserves role and produces two sequential timed reinforcements"
				% (stage_index + 1)
		)
		_expect(
			int(facility.snapshot()["live_child_cap"]) == expected_caps[stage_index],
			"Stage %d preserves its exact live-child cap" % (stage_index + 1)
		)

		# A blocked zero timer stays ready. Freeing either child or global capacity
		# must produce the delayed spawn immediately without a hidden extra interval.
		var child_blocked := FacilityRuntime.new()
		child_blocked.configure(stage_index, Vector2.ZERO)
		child_blocked.activate_if_ready(35, 100)
		_expect(
			child_blocked.advance(
				expected_intervals[stage_index], expected_caps[stage_index], 1
			).is_empty()
				and not child_blocked.advance(
					0.0, expected_caps[stage_index] - 1, 1
				).is_empty(),
			"Stage %d child-cap release consumes the already elapsed interval"
				% (stage_index + 1)
		)
		var global_blocked := FacilityRuntime.new()
		global_blocked.configure(stage_index, Vector2.ZERO)
		global_blocked.activate_if_ready(35, 100)
		_expect(
			global_blocked.advance(
				expected_intervals[stage_index], 0, 0
			).is_empty()
				and not global_blocked.advance(0.0, 0, 1).is_empty(),
			"Stage %d global-cap release consumes the already elapsed interval"
				% (stage_index + 1)
		)

	var retired := FacilityRuntime.new()
	retired.configure(0, Vector2.ZERO)
	retired.activate_if_ready(7, 20)
	retired.retire()
	_expect(
		retired.advance(80.0, 0, 1).is_empty()
			and retired.state == &"retired",
		"retired facility permanently stops spawning"
	)
	var destroyed := FacilityRuntime.new()
	destroyed.configure(0, Vector2.ZERO)
	destroyed.activate_if_ready(7, 20)
	destroyed.receive_damage(1000.0, &"player", &"direct")
	_expect(
		destroyed.advance(80.0, 0, 1).is_empty()
			and destroyed.state == &"destroyed",
		"destroyed facility permanently stops spawning"
	)


func _validate_run_integration() -> void:
	var stage = StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	stage.call("_reset_run", false)
	stage.mode = stage.RunMode.PLAYING
	stage.call("_clear_enemies")
	stage.stage_flow.quota = 20
	stage.stage_flow.defeats = 7
	# The facility activates after ordinary progress has advanced beyond the
	# one-actor tutorial beat used by a freshly configured encounter runtime.
	stage.encounter_runtime.current_beat = 1
	stage.pending_stage_completion = false
	stage.stage_complete = false
	stage.reinforcement_facility_runtime.configure(
		0, stage.player_position + Vector2(500.0, 0.0)
	)

	stage.call("_update_reinforcement_facility", 8.0)
	stage.call("_update_reinforcement_facility", 8.0)
	var facility_children := _living_facility_children(stage.enemies)
	_expect(
		facility_children.size() == 2
			and facility_children[0].summoned
			and facility_children[1].summoned
			and facility_children[0].carrier_id == "reinforcement_facility"
			and facility_children[1].carrier_id == "reinforcement_facility",
		"Run preserves summoned and carrier identity across two facility intervals (children=%d serial=%d state=%s slots=%d)" % [
			facility_children.size(),
			stage.reinforcement_facility_runtime.spawn_serial,
			String(stage.reinforcement_facility_runtime.state),
			stage.encounter_runtime.available_active_slots(stage.call("_active_mobile_count")),
		]
	)

	# Exhaust the next timer at the child cap, then free one exact facility child.
	stage.call("_update_reinforcement_facility", 8.0)
	var serial_before: int = stage.reinforcement_facility_runtime.spawn_serial
	facility_children[0].alive = false
	stage.call("_update_reinforcement_facility", 0.0)
	_expect(
		stage.reinforcement_facility_runtime.spawn_serial == serial_before + 1
			and _living_facility_children(stage.enemies).size() == 2,
		"Run counts only living summoned facility children and fills a released slot (children=%d serial=%d before=%d)" % [
			_living_facility_children(stage.enemies).size(),
			stage.reinforcement_facility_runtime.spawn_serial,
			serial_before,
		]
	)

	# Similar-looking actors must not consume the facility-owned child cap.
	var ordinary: EnemyState = stage.call("_make_enemy", {
		"id":"facility_identity_control",
		"role":&"chaser",
		"pos":stage.player_position + Vector2(700.0, 0.0),
		"active":true,
		"summoned":false,
		"carrier_id":"reinforcement_facility",
	})
	stage.call("_append_enemy", ordinary)
	var other_summon: EnemyState = stage.call("_make_enemy", {
		"id":"other_carrier_control",
		"role":&"chaser",
		"pos":stage.player_position + Vector2(800.0, 0.0),
		"active":true,
		"summoned":true,
		"carrier_id":"splitter:control",
	})
	stage.call("_append_enemy", other_summon)
	for child in _living_facility_children(stage.enemies):
		child.alive = false
	stage.call("_update_reinforcement_facility", 8.0)
	_expect(
		_living_facility_children(stage.enemies).size() == 1,
		"Run excludes ordinary and other-carrier actors from facility child count (children=%d serial=%d)" % [
			_living_facility_children(stage.enemies).size(),
			stage.reinforcement_facility_runtime.spawn_serial,
		]
	)

	# Stage completion owns a hard stop even when the runtime timer is ready.
	stage.call("_update_reinforcement_facility", 8.0)
	for child in _living_facility_children(stage.enemies):
		child.alive = false
	serial_before = stage.reinforcement_facility_runtime.spawn_serial
	stage.stage_complete = true
	stage.call("_update_reinforcement_facility", 0.0)
	_expect(
		stage.reinforcement_facility_runtime.spawn_serial == serial_before,
		"completed stage blocks a ready facility spawn"
	)
	stage.queue_free()
	await process_frame


func _living_facility_children(enemies: Array[EnemyState]) -> Array[EnemyState]:
	var result: Array[EnemyState] = []
	for enemy in enemies:
		if (
			enemy.alive
			and enemy.summoned
			and enemy.carrier_id == "reinforcement_facility"
		):
			result.append(enemy)
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("Vehicle reinforcement facility validation passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
