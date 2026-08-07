extends SceneTree

const FacilityRuntime = preload(
	"res://scripts/vehicle/vehicle_reinforcement_facility_runtime.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const MinimapBuilder = preload("res://scripts/ui/vehicle_minimap_mesh_builder.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
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
		"markers":[{"kind":&"facility", "position":Vector2(50.0, 50.0), "discovered":true}],
	}, Vector2(100.0, 100.0))
	_expect(minimap.has(Art.MUSTARD_DARK.to_rgba32()), "facility owns a distinct two-tone minimap marker")
	_finish()


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
