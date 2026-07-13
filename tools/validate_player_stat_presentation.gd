extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_expect(
		PlayerStatPresentation.format_value(&"jump_velocity", -435.0) == "435",
		"jump strength should hide engine coordinate direction"
	)
	_expect(
		PlayerStatPresentation.format_value(&"dash_cooldown", 0.5) == "0.5s",
		"cooldowns should include seconds"
	)
	_expect(
		PlayerStatPresentation.format_value(&"direct_damage_multiplier", 1.1) == "x1.10",
		"multipliers should preserve comparison precision"
	)
	_expect(
		PlayerStatPresentation.format_transition(&"dash_cooldown", 0.5, 0.47)
		== "Dash cooldown 0.5s -> 0.47s",
		"stat transitions should remain player-readable"
	)
	_expect(
		PlayerStatPresentation.format_effect({
			"stat_id": &"jump_velocity",
			"operation": EffectDefinition.OPERATION_ADD,
			"value": -35.0,
		}) == "Jump strength +35",
		"negative vertical velocity bonuses should read as positive jump strength"
	)
	_expect(
		PlayerStatPresentation.format_effect({
			"stat_id": &"direct_damage_multiplier",
			"operation": EffectDefinition.OPERATION_MULTIPLY,
			"value": 1.1,
		}) == "Direct damage x1.10",
		"effect rows should hide internal operation names"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PLAYER_STAT_PRESENTATION_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
