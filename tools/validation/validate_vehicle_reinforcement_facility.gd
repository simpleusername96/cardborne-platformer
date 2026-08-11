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
	_expect(facility.state == &"offline", "facility starts outside the enemy runtime as offline")
	_expect(facility.get_script() != EnemyState, "facility is not an EnemyState")
	_expect(not facility.activate_if_ready(6, 20), "facility stays offline below 35 percent")
	_expect(facility.activate_if_ready(7, 20), "facility activates at 35 percent")
	_expect(facility.advance(7.9, 1).is_empty(), "stage one interval is eight seconds")
	var spawn := facility.advance(0.1, 1)
	_expect(
		StringName(spawn.get("role", &"")) == &"chaser"
			and bool(spawn.get("summoned", false))
			and String(spawn.get("carrier_id", "")) == "reinforcement_facility",
		"stage one produces a bounded ordinary reinforcement"
	)
	facility.note_spawn_accepted()
	_expect(
		facility.live_children == 1 and facility.remaining_charges == 1,
		"accepted spawn consumes one finite charge and increments the event counter"
	)
	var second_spawn := facility.advance(8.0, 1)
	_expect(not second_spawn.is_empty(), "the second Stage 1 charge becomes ready after eight seconds")
	facility.note_spawn_accepted()
	_expect(
		facility.advance(8.0, 1).is_empty(),
		"exhausted finite charges block every additional spawn"
	)
	facility.note_child_retired()
	facility.note_child_retired()
	_expect(facility.state == &"spent", "charge exhaustion becomes spent after children retire")
	_expect(
		facility.advance(FacilityRuntime.SPENT_RETIRE_DELAY, 1).is_empty()
			and facility.state == &"retired",
		"spent facility retires after its short visual hold"
	)
	var global_blocked := FacilityRuntime.new()
	global_blocked.configure(0, Vector2.ZERO)
	global_blocked.activate_if_ready(7, 20)
	_expect(
		global_blocked.advance(8.0, 0).is_empty()
			and not global_blocked.advance(0.0, 1).is_empty(),
		"global active capacity preserves a ready spawn without resetting its timer"
	)

	var combat_facility := FacilityRuntime.new()
	combat_facility.configure(0, Vector2(1200.0, 800.0))
	combat_facility.activate_if_ready(7, 20)
	var hit_receipt := {}
	_expect(
		combat_facility.first_active_segment_hit(
			Vector2(900.0, 800.0), Vector2(1500.0, 800.0), 4.0, hit_receipt
		),
		"active facility participates in direct projectile collision"
	)
	_expect(
		not combat_facility.is_position_clear(combat_facility.position, 24.0)
			and combat_facility.is_position_clear(
				combat_facility.position + Vector2(200.0, 0.0), 24.0
			),
		"active facility owns separate solid-body collision"
	)
	var rejected := combat_facility.receive_damage(20.0, &"enemy", &"direct")
	_expect(not bool(rejected["accepted"]), "enemy attacks cannot damage the facility")
	var damaged := combat_facility.receive_damage(100.0, &"player", &"area")
	_expect(
		bool(damaged["accepted"])
			and is_equal_approx(float(damaged["remaining_health"]), 200.0),
		"player direct and area damage use facility-owned health"
	)
	var destroyed := combat_facility.receive_damage(300.0, &"player", &"direct")
	_expect(bool(destroyed["destroyed"]) and combat_facility.state == &"destroyed", "facility destruction stops its lifecycle")
	_expect(combat_facility.snapshot().get("visible", true) == false, "destroyed facility leaves the live presentation")

	facility.configure(4, Vector2(2400.0, 1400.0))
	_expect(facility.activate_if_ready(35, 100), "stage five uses the same clear trigger")
	var stage_five_spawn := facility.advance(4.0, 1)
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
		for charge_index in expected_caps[stage_index]:
			var spawn := facility.advance(expected_intervals[stage_index], 1)
			_expect(
				StringName(spawn.get("role", &"")) == expected_roles[stage_index]
					and String(spawn.get("id", ""))
						== "facility_reinforcement_%d" % charge_index,
				"Stage %d charge %d preserves role and stable serial"
					% [stage_index + 1, charge_index + 1]
			)
			facility.note_spawn_accepted()
		_expect(
			int(facility.snapshot()["live_child_cap"]) == expected_caps[stage_index]
				and int(facility.snapshot()["total_charges"]) == expected_caps[stage_index]
				and facility.advance(expected_intervals[stage_index], 1).is_empty(),
			"Stage %d preserves its exact cap and finite total charge"
				% (stage_index + 1)
		)
		for _child_index in expected_caps[stage_index]:
			facility.note_child_retired()
		_expect(facility.state == &"spent", "Stage %d enters spent state" % (stage_index + 1))

	var retired := FacilityRuntime.new()
	retired.configure(0, Vector2.ZERO)
	retired.activate_if_ready(7, 20)
	retired.retire()
	_expect(
		retired.advance(80.0, 1).is_empty()
			and retired.state == &"retired",
		"retired facility permanently stops spawning"
	)
	var destroyed := FacilityRuntime.new()
	destroyed.configure(0, Vector2.ZERO)
	destroyed.activate_if_ready(7, 20)
	destroyed.receive_damage(1000.0, &"player", &"direct")
	_expect(
		destroyed.advance(80.0, 1).is_empty()
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
			and facility_children[1].carrier_id == "reinforcement_facility"
			and stage.reinforcement_facility_runtime.live_children == 2
			and stage.reinforcement_facility_runtime.remaining_charges == 0
			and stage.debug_reinforcement_facility_count_matches(),
		"Run preserves identity, finite charges, and event-owned child count (children=%d serial=%d state=%s slots=%d)" % [
			facility_children.size(),
			stage.reinforcement_facility_runtime.spawn_serial,
			String(stage.reinforcement_facility_runtime.state),
			stage.encounter_runtime.available_active_slots(stage.call("_active_mobile_count")),
		]
	)
	var serial_before: int = stage.reinforcement_facility_runtime.spawn_serial
	stage.call("_update_reinforcement_facility", 80.0)
	_expect(
		stage.reinforcement_facility_runtime.spawn_serial == serial_before,
		"Run cannot produce a third Stage 1 reinforcement after charge exhaustion"
	)

	# Similar-looking actors do not affect the event counter or debug audit.
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
	_expect(
		stage.debug_reinforcement_facility_count_matches(),
		"debug reconciliation excludes ordinary and other-carrier actors"
	)

	stage.call("_defeat_enemy", facility_children[0], "validator")
	_expect(
		stage.reinforcement_facility_runtime.live_children == 1
			and stage.debug_reinforcement_facility_count_matches(),
		"authoritative defeat decrements one facility child event"
	)
	stage.call("_defeat_enemy", facility_children[1], "validator")
	_expect(
		stage.reinforcement_facility_runtime.live_children == 0
			and stage.reinforcement_facility_runtime.state == &"spent"
			and stage.debug_reinforcement_facility_count_matches(),
		"last child defeat moves the exhausted facility into spent state"
	)
	stage.call(
		"_update_reinforcement_facility", FacilityRuntime.SPENT_RETIRE_DELAY
	)
	_expect(
		stage.reinforcement_facility_runtime.state == &"retired",
		"Run retires spent facility without another enemy scan or spawn"
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
		print("VEHICLE_REINFORCEMENT_FACILITY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
