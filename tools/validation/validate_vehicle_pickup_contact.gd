extends SceneTree

const Contact = preload("res://scripts/rewards/vehicle_pickup_contact.gd")

const PLAYER_RADIUS := 24.0
const PICKUP_RADIUS := 42.0
const CONTACT_RADIUS := PLAYER_RADIUS + PICKUP_RADIUS

var failures: Array[String] = []


func _initialize() -> void:
	_expect(
		Contact.should_collect(
			true, Vector2.ZERO, Vector2.ZERO,
			PLAYER_RADIUS, Vector2(CONTACT_RADIUS, 0.0), PICKUP_RADIUS
		),
		"endpoint tangent counts as contact at radius 66"
	)
	_expect(
		Contact.should_collect(
			true, Vector2(-100.0, CONTACT_RADIUS), Vector2(100.0, CONTACT_RADIUS),
			PLAYER_RADIUS, Vector2.ZERO, PICKUP_RADIUS
		),
		"motion tangent counts as contact"
	)
	_expect(
		Contact.should_collect(
			true, Vector2(-100.0, 0.0), Vector2(100.0, 0.0),
			PLAYER_RADIUS, Vector2.ZERO, PICKUP_RADIUS
		),
		"normal pass collects"
	)
	_expect(
		Contact.should_collect(
			true, Vector2(-180.0, 0.0), Vector2(180.0, 0.0),
			PLAYER_RADIUS, Vector2.ZERO, PICKUP_RADIUS
		),
		"full dash pass-through collects"
	)
	_expect(
		not Contact.should_collect(
			true, Vector2(-100.0, CONTACT_RADIUS + 0.1),
			Vector2(100.0, CONTACT_RADIUS + 0.1),
			PLAYER_RADIUS, Vector2.ZERO, PICKUP_RADIUS
		),
		"0.1 outside contact radius misses"
	)
	for kind in [&"repair", &"experience_recall"]:
		_expect(
			not Contact.should_collect(
				false, Vector2(-100.0, 0.0), Vector2(100.0, 0.0),
				PLAYER_RADIUS, Vector2.ZERO, PICKUP_RADIUS
			),
			"inactive %s pickup stays idempotent" % kind
		)
	_validate_endpoint_oracle()
	_finish()


func _validate_endpoint_oracle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xC011EC7
	for index in 120:
		var motion_start := Vector2(
			rng.randf_range(-300.0, 300.0),
			rng.randf_range(-300.0, 300.0)
		)
		var motion_end := Vector2(
			rng.randf_range(-300.0, 300.0),
			rng.randf_range(-300.0, 300.0)
		)
		var pickup_position := Vector2(
			rng.randf_range(-300.0, 300.0),
			rng.randf_range(-300.0, 300.0)
		)
		var swept := Contact.should_collect(
			true,
			motion_start,
			motion_end,
			PLAYER_RADIUS,
			pickup_position,
			PICKUP_RADIUS
		)
		var old_combined := (
			swept
			or Contact.should_collect(
				true,
				motion_end,
				motion_end,
				PLAYER_RADIUS,
				pickup_position,
				PICKUP_RADIUS
			)
		)
		_expect(
			swept == old_combined,
			"random pickup path %d proves swept contact already includes its endpoint"
			% index
		)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PICKUP_CONTACT_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
