extends SceneTree

## Stable terrain entrypoint retained for broad validation suites. The focused
## hazard validator carries exhaustive cadence/capacity coverage.

const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var runtime := TerrainRuntime.new()
	runtime.configure([
		{
			"id":&"bog", "kind":&"hazard_zone",
			"variant":&"toxic_bog", "rect":Rect2(100, 100, 400, 300),
		},
		{
			"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a",
			"pos":Vector2.ZERO,
		},
		{
			"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a",
			"pos":Vector2(1600.0, 0.0),
		},
	])
	_expect(
		runtime.hazard_damage_for_actor(
			"player", Vector2.ZERO, Vector2(200, 200), 24.0, &"player", 0.0
		) == TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"hazard entry deals the authored player tick"
	)
	var events: Array[Dictionary] = []
	for _step in 4:
		events.append_array(
			runtime.advance(0.1, Vector2.ZERO)
		)
	_expect(
		events.size() == 1
		and StringName(events[0]["kind"]) == &"transit",
		"transit remains the terrain utility mechanic"
	)
	var snapshot := runtime.snapshot()
	_expect(
		not snapshot.has("support_fields")
		and not snapshot.has("overdrive_active"),
		"retired support and damage-zone systems do not return"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_TERRAIN_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
