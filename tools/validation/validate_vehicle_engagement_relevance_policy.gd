extends SceneTree

const Policy = preload("res://scripts/enemies/vehicle_engagement_relevance_policy.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_route_excess_release()
	_validate_sustained_divergence_release()
	_validate_recovery_resets_evidence()
	_finish()


func _validate_route_excess_release() -> void:
	var early := Policy.sample(
		Vector2.ZERO, Vector2(100.0, 0.0), Vector2(-401.1, 0.0),
		-1.0, -1.0, 0.0
	)
	_expect(not bool(early["release"]), "route excess keeps the shared 0.8 second gate-age grace")
	var sample := Policy.sample(
		Vector2.ZERO, Vector2(100.0, 0.0), Vector2(-401.1, 0.0),
		-1.0, -1.0, 0.81, 0.0
	)
	_expect(bool(sample["release"]), "a gate adding more than 300 units releases")
	_expect(StringName(sample["reason"]) == &"route_excess", "route excess has a causal release reason")


func _validate_sustained_divergence_release() -> void:
	var first := Policy.sample(
		Vector2.ZERO, Vector2(100.0, 0.0), Vector2(-200.0, 0.0),
		90.0, -1.0, 4.0
	)
	_expect(not bool(first["release"]), "divergence receives the 0.8 second grace")
	var final := Policy.sample(
		Vector2.ZERO, Vector2(120.0, 0.0), Vector2(-200.0, 0.0),
		float(first["player_distance"]), float(first["divergence_started_at"]), 4.81
	)
	_expect(bool(final["release"]), "sustained opposite travel releases after 0.8 seconds")
	_expect(StringName(final["reason"]) == &"diverging", "divergence has a causal release reason")


func _validate_recovery_resets_evidence() -> void:
	var sample := Policy.sample(
		Vector2.ZERO, Vector2(80.0, 0.0), Vector2(-100.0, 0.0),
		100.0, 2.0, 2.5
	)
	_expect(not bool(sample["release"]), "closing on the player does not release")
	_expect(float(sample["divergence_started_at"]) < 0.0, "closing resets stale divergence evidence")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENGAGEMENT_RELEVANCE_POLICY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
