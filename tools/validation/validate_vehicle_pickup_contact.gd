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
	_finish()


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
