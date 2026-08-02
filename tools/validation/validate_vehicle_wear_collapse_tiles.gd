extends SceneTree

const Registry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_authored_fields()
	_validate_crossing_damage_and_persistence()
	_finish()


func _validate_authored_fields() -> void:
	for field_id in Registry.FIELD_IDS:
		var definition := Registry.definition(field_id)
		var tiles: Array[Dictionary] = []
		var walls: Array[Rect2] = []
		for feature_variant in Array(definition["features"]):
			var feature := Dictionary(feature_variant)
			match StringName(feature["kind"]):
				&"wear_collapse_tile":
					tiles.append(feature)
				&"structural_wall":
					walls.append(Rect2(feature["rect"]))
		_expect(tiles.size() == 4, "%s authors exactly four wear tiles" % field_id)
		var runtime := TerrainRuntime.new()
		var persistent := {}
		runtime.configure(definition["features"], {}, false, [], 0, &"stage_1", persistent)
		var snapshots: Array = runtime.snapshot()["features"]
		for tile in tiles:
			var tile_id := StringName(tile["id"])
			var matching := snapshots.filter(
				func(value: Dictionary) -> bool:
					return StringName(value["id"]) == tile_id
			)
			_expect(matching.size() == 1, "%s/%s has one runtime snapshot" % [field_id, tile_id])
			if matching.size() != 1:
				continue
			var snapshot := Dictionary(matching[0])
			_expect(
				Rect2(snapshot["rect"]) == Rect2(tile["rect"])
				and StringName(snapshot["state"]) == &"intact"
				and int(snapshot["wear"]) == 0
				and int(snapshot["threshold"]) == 3,
				"%s/%s publishes exact tile gameplay truth" % [field_id, tile_id]
			)
		_expect(
			runtime.structural_wall_rects() == walls,
			"%s keeps structural-wall rectangles separate from traversable wear tiles" % field_id
		)


func _validate_crossing_damage_and_persistence() -> void:
	var persistent := {}
	var blueprint := [
		{"id":&"wear", "kind":&"wear_collapse_tile", "rect":Rect2(100, 100, 200, 120)},
	]
	var runtime := TerrainRuntime.new()
	runtime.configure(blueprint, {}, false, [], 10, &"stage_1", persistent)

	var damage := runtime.wear_damage_for_actor(
		"player", Vector2(0, 160), Vector2(150, 160), 16.0, 0.10
	)
	_expect(damage == 0.0, "first player entry only cracks the tile")
	_expect(_state(persistent) == &"cracked" and _wear(persistent) == 1, "first entry records cracked/1")
	runtime.wear_damage_for_actor("player", Vector2(150, 160), Vector2(150, 160), 16.0, 1.0)
	_expect(_wear(persistent) == 1, "stationary overlap never repeats wear")
	runtime.wear_damage_for_actor("player", Vector2(150, 160), Vector2(0, 160), 16.0, 0.10)

	damage = runtime.wear_damage_for_actor(
		"ordinary", Vector2(0, 160), Vector2(400, 160), 18.0, 0.10
	)
	_expect(damage == 0.0 and _wear(persistent) == 2, "fast ordinary sweep records one distinct crossing")

	damage = runtime.wear_damage_for_actor(
		"boss", Vector2(400, 160), Vector2(200, 160), 76.0, 0.10
	)
	_expect(
		damage == TerrainRuntime.WEAR_DAMAGE
		and _state(persistent) == &"collapsed"
		and _wear(persistent) == TerrainRuntime.WEAR_THRESHOLD,
		"boss crossing that collapses the tile takes immediate exact damage"
	)
	_expect(
		runtime.wear_damage_for_actor("boss", Vector2(200, 160), Vector2(200, 160), 76.0, 0.74) == 0.0,
		"continuous overlap waits for the 0.75 second deadline"
	)
	_expect(
		runtime.wear_damage_for_actor("boss", Vector2(200, 160), Vector2(200, 160), 76.0, 0.01)
		== TerrainRuntime.WEAR_DAMAGE,
		"continuous boss overlap deals one exact damage tick at 0.75 seconds"
	)
	runtime.wear_damage_for_actor("boss", Vector2(200, 160), Vector2(500, 160), 76.0, 0.10)
	_expect(
		runtime.wear_damage_for_actor("boss", Vector2(500, 160), Vector2(200, 160), 76.0, 0.10)
		== TerrainRuntime.WEAR_DAMAGE,
		"full exit and re-entry deals immediate damage again"
	)
	runtime.forget_wear_actor("boss")
	_expect(
		int(runtime.wear_runtime_snapshot()["occupancy_count"]) == 0,
		"retiring an actor clears stage-local wear occupancy"
	)

	var next_stage := TerrainRuntime.new()
	next_stage.configure(blueprint, {}, true, [], 10, &"stage_2", persistent)
	_expect(
		_state(persistent) == &"collapsed" and _wear(persistent) == 3,
		"state and wear persist across stage configure"
	)
	_expect(
		int(next_stage.wear_runtime_snapshot()["occupancy_count"]) == 0
		and int(next_stage.wear_runtime_snapshot()["damage_deadline_count"]) == 0,
		"stage configure resets occupancy and damage deadlines"
	)
	_expect(
		next_stage.wear_damage_for_actor("player", Vector2(200, 160), Vector2(200, 160), 16.0, 0.10)
		== TerrainRuntime.WEAR_DAMAGE,
		"first overlap with a persisted collapsed tile is a fresh immediate entry"
	)


func _state(persistent: Dictionary) -> StringName:
	return StringName(Dictionary(persistent.get(&"wear", {})).get("state", &""))


func _wear(persistent: Dictionary) -> int:
	return int(Dictionary(persistent.get(&"wear", {})).get("wear", -1))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_WEAR_COLLAPSE_TILES_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
