extends SceneTree

const Supply = preload("res://scripts/rewards/vehicle_viewport_supply_policy.gd")
const Facilities = preload("res://scripts/vehicle/vehicle_mystery_device_runtime.gd")
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var visible := Rect2(0.0, 0.0, 1280.0, 720.0)
	var anchors: Array[Vector2] = [
		Vector2(200.0, 200.0), Vector2(900.0, 300.0),
		Vector2(1800.0, 300.0), Vector2(2400.0, 300.0),
	]
	var pickups: Array[Dictionary] = []
	for index in anchors.size():
		pickups.append({
			"id":"pickup_%d" % index, "kind":&"experience_recall",
			"pos":anchors[index], "active":true, "published":index == 1,
			"published_elapsed":0.0,
		})
	Supply.refresh_pickups(pickups, anchors, visible, Vector2(640.0, 360.0), 1.0)
	_expect(_published_count(pickups) == 1, "a supported viewport publishes at most one direct item")
	_expect(bool(pickups[1]["published"]), "an already visible published item is retained")
	var visible_position := Vector2(pickups[1]["pos"])
	Supply.refresh_pickups(pickups, anchors, visible, Vector2(640.0, 360.0), 61.0)
	_expect(Vector2(pickups[1]["pos"]) == visible_position, "a visible item never moves after sixty seconds")

	for pickup in pickups:
		pickup["active"] = false
	pickups[2]["active"] = true
	pickups[2]["published"] = true
	pickups[2]["published_elapsed"] = 59.5
	var old_offscreen := Vector2(pickups[2]["pos"])
	Supply.refresh_pickups(pickups, anchors, visible, Vector2(640.0, 360.0), 1.0)
	_expect(Vector2(pickups[2]["pos"]) != old_offscreen, "an old published item relocates only while outside the expanded viewport")
	_expect(not visible.grow(Supply.SAFETY_MARGIN).has_point(Vector2(pickups[2]["pos"])), "retirement chooses another off-screen validation anchor")

	var authored_shard := ExperienceShard.new()
	authored_shard.configure(1, Vector2(200.0, 200.0), 5, &"", true)
	pickups[2]["active"] = true
	pickups[2]["published"] = false
	Supply.refresh_direct_items(
		pickups, [authored_shard], anchors, visible, Vector2(200.0, 200.0), 1.0
	)
	_expect(
		_published_count(pickups) + int(authored_shard.published) == 1,
		"authored XP shards and recalls share one direct-item publication slot"
	)

	var runtime := Facilities.new()
	var blueprints: Array[Dictionary] = []
	for index in 6:
		blueprints.append({"id":"facility_%d" % index, "pos":Vector2(160.0 + index * 220.0, 320.0)})
	runtime.configure(blueprints, 42, &"stage_1")
	var original_positions: Array[Vector2] = []
	for device in runtime.devices:
		original_positions.append(Vector2(device["position"]))
	runtime.refresh_publication(visible, Vector2(640.0, 360.0))
	var published_dormant := 0
	for index in runtime.devices.size():
		published_dormant += 1 if bool(runtime.devices[index].get("published", false)) else 0
		_expect(Vector2(runtime.devices[index]["position"]) == original_positions[index], "facility publication never moves anchor %d" % index)
	_expect(published_dormant == 1, "a supported viewport publishes at most one dormant facility")
	_finish()


func _published_count(pickups: Array[Dictionary]) -> int:
	var count := 0
	for pickup in pickups:
		if bool(pickup.get("active", false)) and bool(pickup.get("published", false)):
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_VIEWPORT_SUPPLY_POLICY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
