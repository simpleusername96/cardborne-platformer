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
	var focus := Vector2(600.0, 40.0)
	var fast_velocity := Vector2(280.0, -120.0)
	for movement_family in [
		MovementPolicy.PURSUIT,
		MovementPolicy.STANDOFF,
		MovementPolicy.ESCORT,
		MovementPolicy.SUPPORT,
		MovementPolicy.STATIONARY,
	]:
		_expect(
			Policy.movement_focus(
				movement_family,
				origin,
				focus,
				fast_velocity,
				180.0
			) == focus,
			"%s movement uses the player's current position without lead"
				% movement_family
		)
	_expect(
		Policy.movement_focus(
			MovementPolicy.PURSUIT,
			Vector2(900.0, 300.0),
			focus,
			Vector2(-900.0, 600.0),
			1.0
		) == focus,
		"movement focus is independent from origin, velocity, and movement speed"
	)


func _validate_attack_target() -> void:
	var origin := Vector2.ZERO
	var focus := Vector2(500.0, 0.0)
	var velocity := Vector2(0.0, 220.0)
	var shooter := Policy.attack_target(
		&"ordinary_lane_01",
		origin,
		focus,
		velocity,
		0.62,
		410.0
	)
	_expect(shooter.y > 0.0, "projectile commitment still leads a moving player")
	_expect(
		shooter.distance_to(focus) <= 260.001,
		"direct projectile lead remains capped"
	)
	var artillery := Policy.attack_target(
		&"ordinary_growth_01",
		origin,
		focus,
		velocity,
		1.15,
		295.0
	)
	_expect(
		artillery.distance_to(focus) <= 320.001
			and artillery.y >= shooter.y,
		"artillery keeps its larger bounded commitment envelope"
	)
	var beam := Policy.attack_target(
		&"ordinary_fixed_beam_01",
		origin,
		focus,
		velocity,
		1.2,
		0.0
	)
	_expect(
		beam.distance_to(focus) <= 220.001
			and beam.y > 0.0,
		"beam prediction includes startup and remains capped"
	)
	var impossible := Policy.attack_target(
		&"ordinary_lane_01",
		origin,
		focus,
		Vector2(900.0, 0.0),
		0.62,
		410.0
	)
	_expect(
		impossible.is_finite()
			and impossible.distance_to(focus) <= 260.001,
		"an impossible intercept falls back to a finite bounded lead"
	)
	_expect(
		Policy.attack_target(
			&"ordinary_support_01",
			origin,
			focus,
			velocity,
			1.0,
			300.0
		) == focus,
		"roles without predictive attack ownership keep the current target"
	)


func _validate_deterministic_focus() -> void:
	var focus := Vector2(420.0, 170.0)
	var first := Policy.attack_target(
		&"ordinary_lane_01",
		Vector2.ZERO,
		focus,
		Vector2(120.0, -40.0),
		0.62,
		410.0
	)
	var replay := Policy.attack_target(
		&"ordinary_lane_01",
		Vector2.ZERO,
		focus,
		Vector2(120.0, -40.0),
		0.62,
		410.0
	)
	_expect(first == replay, "attack-target prediction is deterministic")
	_expect(
		Policy.movement_focus(
			MovementPolicy.PURSUIT,
			Vector2.ZERO,
			focus,
			Vector2(120.0, -40.0),
			180.0
		) == focus,
		"movement focus is deterministic and unpredicted"
	)


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
