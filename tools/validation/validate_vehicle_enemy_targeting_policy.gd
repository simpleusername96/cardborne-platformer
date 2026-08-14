extends SceneTree

const Policy = preload(
	"res://scripts/enemies/vehicle_enemy_targeting_policy.gd"
)
const MovementPolicy = preload(
	"res://scripts/enemies/vehicle_enemy_movement_policy.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	_validate_movement_focus()
	_validate_attack_target()
	_validate_deterministic_focus()
	_finish()


func _validate_movement_focus() -> void:
	var origin := Vector2.ZERO
	var focus := Vector2(600.0, 0.0)
	_expect(
		Policy.movement_focus(
			MovementPolicy.PURSUIT, origin, focus, Vector2.ZERO, 180.0
		) == focus,
		"stationary pressure focus receives no movement lead"
	)
	var pursuit := Policy.movement_focus(
		MovementPolicy.PURSUIT, origin, focus, Vector2(280.0, 0.0), 180.0
	)
	var standoff := Policy.movement_focus(
		MovementPolicy.STANDOFF, origin, focus, Vector2(280.0, 0.0), 180.0
	)
	var support := Policy.movement_focus(
		MovementPolicy.SUPPORT, origin, focus, Vector2(280.0, 0.0), 180.0
	)
	_expect(
		pursuit.x > standoff.x and standoff.x > support.x,
		"movement families receive ordered forward pressure bounds"
	)
	_expect(
		pursuit.distance_to(focus) <= 280.001
			and standoff.distance_to(focus) <= 200.001
			and support.distance_to(focus) <= 140.001,
		"movement prediction remains inside every family distance clamp"
	)
	_expect(
		Policy.movement_focus(
			MovementPolicy.PURSUIT, origin, focus, Vector2(79.0, 0.0), 180.0
		) == focus,
		"slow player movement does not jitter the pressure focus"
	)


func _validate_attack_target() -> void:
	var origin := Vector2.ZERO
	var focus := Vector2(500.0, 0.0)
	var velocity := Vector2(0.0, 220.0)
	var shooter := Policy.attack_target(
		&"shooter", origin, focus, velocity, 0.62, 410.0
	)
	_expect(shooter.y > 0.0, "projectile commitment leads a moving player")
	_expect(
		shooter.distance_to(focus) <= 260.001,
		"direct projectile lead remains capped"
	)
	var artillery := Policy.attack_target(
		&"artillery_spotter", origin, focus, velocity, 1.15, 295.0
	)
	_expect(
		artillery.distance_to(focus) <= 320.001
			and artillery.y >= shooter.y,
		"artillery uses its larger but bounded commitment envelope"
	)
	var beam := Policy.attack_target(
		&"beam_sentinel", origin, focus, velocity, 1.2, 0.0
	)
	_expect(
		beam.distance_to(focus) <= 220.001 and beam.y > 0.0,
		"beam prediction includes startup and remains capped"
	)
	var impossible := Policy.attack_target(
		&"shooter", origin, focus, Vector2(900.0, 0.0), 0.62, 410.0
	)
	_expect(
		impossible.is_finite()
			and impossible.distance_to(focus) <= 260.001,
		"an impossible intercept falls back to a finite bounded lead"
	)


func _validate_deterministic_focus() -> void:
	var focus := Vector2(420.0, 170.0)
	var first := Policy.attack_target(
		&"shooter", Vector2.ZERO, focus, Vector2(120.0, -40.0), 0.62, 410.0
	)
	var replay := Policy.attack_target(
		&"shooter", Vector2.ZERO, focus, Vector2(120.0, -40.0), 0.62, 410.0
	)
	_expect(first == replay, "target prediction is deterministic")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_TARGETING_POLICY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
