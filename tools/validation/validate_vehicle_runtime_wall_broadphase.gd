extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xC4B04D
	for seed in [0xC4B041, 0xC4B042]:
		var layout = Generator.generate(seed, CombatStages.STAGE_IDS)
		_expect(layout != null, "representative field layout exists")
		if layout == null:
			continue
		for stage_id in CombatStages.STAGE_IDS:
			var tactical = layout.tactical_layout(stage_id)
			var walls: Array[Rect2] = []
			for feature in tactical.geometry_snapshot.terrain_zones:
				if StringName(feature.get("kind", &"")) == &"structural_wall":
					walls.append(Rect2(feature.get("rect", Rect2())))
			for query_index in 160:
				var bounds: Rect2 = tactical.geometry_snapshot.world_rect
				var from := Vector2(
					rng.randf_range(bounds.position.x, bounds.end.x),
					rng.randf_range(bounds.position.y, bounds.end.y)
				)
				var to := from + Vector2.from_angle(rng.randf_range(-PI, PI)) * rng.randf_range(0.0, 1600.0)
				var radius := rng.randf_range(0.0, 96.0)
				var actual: Array[Rect2] = []
				tactical.runtime_walls_near_motion_into(from, to, radius, actual)
				var swept := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
				var expected: Array[Rect2] = []
				for wall in walls:
					if swept.intersects(wall.grow(radius), true):
						expected.append(wall)
				_expect(
					_same_rect_set(actual, expected),
					"%s query %d returns every and only exact wall candidate" % [String(stage_id), query_index]
				)
	_finish()


func _same_rect_set(left: Array[Rect2], right: Array[Rect2]) -> bool:
	if left.size() != right.size():
		return false
	for rectangle in left:
		if rectangle not in right:
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_RUNTIME_WALL_BROADPHASE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
